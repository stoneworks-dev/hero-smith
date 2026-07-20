import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../db/app_database.dart' as db;
import '../models/characteristics_models.dart';
import '../models/class_data.dart';
import '../models/hero_mutation_model.dart';
import '../models/subclass_models.dart';
import '../repositories/hero_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'class_feature_grants_service.dart';
import 'hero_mutation_service.dart';
import 'kit_bonus_service.dart';
import 'kit_grants_service.dart';
import 'perk_grants_service.dart';
import 'starting_characteristics_service.dart';

/// Everything the Strife tab knows when the user presses Save. A faithful
/// mirror of the page's selection state so [StrifeCreatorService.saveStrife]
/// can run without reading anything back from widgets.
class StrifeCreatorSavePayload {
  const StrifeCreatorSavePayload({
    required this.heroId,
    required this.classData,
    required this.previousClassId,
    required this.level,
    this.selectedArray,
    required this.assignedCharacteristics,
    required this.levelChoiceSelections,
    required this.selectedAbilities,
    required this.selectedSkills,
    required this.selectedPerks,
    this.selectedSubclass,
    required this.selectedKitIds,
    required this.previousPerkIds,
    this.skillIdLookup = const <String, String>{},
  });

  final String heroId;
  final ClassData classData;

  /// The class id last persisted for this hero, used to detect a class
  /// change (which triggers a full Strife data cleanup before writing).
  final String? previousClassId;
  final int level;
  final CharacteristicArray? selectedArray;
  final Map<String, int> assignedCharacteristics;
  final Map<String, String?> levelChoiceSelections;
  final Map<String, String?> selectedAbilities;
  final Map<String, String?> selectedSkills;
  final Map<String, String?> selectedPerks;
  final SubclassSelectionResult? selectedSubclass;
  final List<String?> selectedKitIds;

  /// The perk ids whose grants were applied the last time this hero was
  /// saved (or reloaded), so grant sync can diff against them.
  final Set<String> previousPerkIds;

  /// Resolves a skill name/id typed by legacy data into a canonical skill id.
  final Map<String, String> skillIdLookup;
}

class StrifeCreatorSaveResult {
  const StrifeCreatorSaveResult({required this.strifePerkIds});

  /// The perk ids written by this save, for the caller's own bookkeeping
  /// (e.g. seeding the next save's `previousPerkIds`).
  final Set<String> strifePerkIds;
}

/// Owns the Strife tab's transactional write path. Extracted from
/// `StrifeCreatorPage._handleSave` so the transaction can be reused by the
/// hero-builder commit service without depending on the widget tree.
class StrifeCreatorService {
  StrifeCreatorService(this._db)
      : _heroRepository = HeroRepository(_db),
        _mutations = HeroMutationService(_db),
        _perkGrants = PerkGrantsService(_db),
        _kitGrants = KitGrantsService(_db);

  final db.AppDatabase _db;
  final HeroRepository _heroRepository;
  final HeroMutationService _mutations;
  final PerkGrantsService _perkGrants;
  final KitGrantsService _kitGrants;

  String? _resolveSkillId(
    String? value,
    Map<String, String> skillIdLookup,
  ) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    return skillIdLookup[lower] ?? skillIdLookup[trimmed] ?? trimmed;
  }

  void _applyCharacteristicPayload(
    String stat,
    AdjustmentPayload payload,
    Map<String, int> characteristics,
  ) {
    var value = characteristics[stat] ?? 0;

    final increase = payload.increaseBy;
    if (increase != null) {
      value += increase;
    }

    final setTo = payload.setTo;
    if (setTo != null && value < setTo) {
      value = setTo;
    }

    final maxValue = payload.max;
    if (maxValue != null && value > maxValue) {
      value = maxValue;
    }

    characteristics[stat] = value;
  }

  /// EXACT copy of the Kits tab flow: persists the equipment slot ids, then
  /// applies every kit grant (abilities, bonuses, stat mods) for them. This
  /// is the only thing that writes kit-owned `hero_entries` rows.
  Future<EquipmentBonuses> _applyEquipmentSelectionAndBonuses({
    required String heroId,
    required List<String?> equipmentSlotIds,
    required int level,
  }) async {
    await _heroRepository.saveEquipmentIds(heroId, equipmentSlotIds);
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'basics.equipment',
      jsonMap: {'ids': equipmentSlotIds},
    );

    return _kitGrants.applyKitGrants(
      heroId: heroId,
      equipmentIds: equipmentSlotIds,
      heroLevel: level,
    );
  }

  Future<void> _syncStrifePerkGrants({
    required String heroId,
    required Set<String> previousPerkIds,
    required Set<String> currentPerkIds,
  }) async {
    for (final perkId in previousPerkIds.difference(currentPerkIds)) {
      await _perkGrants.removePerkGrants(
        heroId: heroId,
        perkId: perkId,
        removePerkEntry: false,
      );
    }

    for (final perkId in currentPerkIds) {
      final component = await _db.getComponentById(perkId);
      if (component == null || component.dataJson.isEmpty) continue;
      try {
        final data = jsonDecode(component.dataJson) as Map<String, dynamic>;
        await _perkGrants.applyPerkGrants(
          heroId: heroId,
          perkId: perkId,
          grantsJson: data['grants'],
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Failed to apply grants for perk $perkId: $error');
        }
      }
    }
  }

  /// Writes the entire Strife selection in one transaction: class-change
  /// cleanup (if the class changed), level/class/subclass/deity/domain, kit
  /// grants and bonuses, characteristic base values, vitals, potencies, and
  /// the ability/skill/perk source replacements. A mid-save failure cannot
  /// leave the hero with, e.g., a new class but stale abilities.
  Future<StrifeCreatorSaveResult> saveStrife(
    StrifeCreatorSavePayload payload,
  ) async {
    final heroId = payload.heroId;
    final classData = payload.classData;
    final startingChars = classData.startingCharacteristics;

    var strifePerkIds = <String>{};

    await _db.transaction(() async {
      final classChanged = payload.previousClassId != null &&
          payload.previousClassId != classData.classId;
      if (classChanged) {
        await _heroRepository.clearStrifeData(heroId);
      }

      final updates = <Future>[];

      // 1. Save level
      await _heroRepository.updateMainStats(heroId, level: payload.level);

      // 2. Save class name
      await _heroRepository.updateClassName(heroId, classData.classId);

      // 3. Save subclass
      final selectedSubclass = payload.selectedSubclass;
      if (selectedSubclass != null) {
        await _heroRepository.updateSubclass(
          heroId,
          selectedSubclass.subclassName,
        );

        if (selectedSubclass.subclassKey != null) {
          await _heroRepository.saveSubclassKey(
            heroId,
            selectedSubclass.subclassKey,
          );
        }

        if (selectedSubclass.deityId != null) {
          await _heroRepository.updateDeity(heroId, selectedSubclass.deityId);
        }

        if (selectedSubclass.domainNames.isNotEmpty) {
          await _heroRepository.updateDomain(
            heroId,
            selectedSubclass.domainNames.join(', '),
          );
        }
      }

      // 3.5. Apply kit grants (bonuses, abilities, stat mods like
      // decrease_total) from selected equipment, then auto-favorite it.
      final slotOrderedEquipmentIds =
          List<String?>.from(payload.selectedKitIds);
      final equipmentBonuses = await _applyEquipmentSelectionAndBonuses(
        heroId: heroId,
        equipmentSlotIds: slotOrderedEquipmentIds,
        level: payload.level,
      );

      final equipmentIdsToFavorite =
          slotOrderedEquipmentIds.whereType<String>().toList();
      if (equipmentIdsToFavorite.isNotEmpty) {
        final existingFavorites =
            await _heroRepository.getFavoriteKitIds(heroId);
        final mergedFavorites = <String>{
          ...existingFavorites,
          ...equipmentIdsToFavorite,
        }.toList();
        await _heroRepository.saveFavoriteKitIds(heroId, mergedFavorites);
      }

      // 4. Save selected characteristic array name
      final selectedArray = payload.selectedArray;
      if (selectedArray != null) {
        updates.add(_heroRepository.updateCharacteristicArray(
          heroId,
          arrayName: selectedArray.description,
          arrayValues: selectedArray.values,
        ));
      }

      // 4.5. Save characteristic assignments (the mapping of stat to value)
      if (payload.assignedCharacteristics.isNotEmpty) {
        updates.add(_heroRepository.saveCharacteristicAssignments(
          heroId,
          payload.assignedCharacteristics,
        ));
      }

      // 4.6. Save level choice selections (which characteristic to boost at
      // each level)
      if (payload.levelChoiceSelections.isNotEmpty) {
        updates.add(_heroRepository.saveLevelChoiceSelections(
          heroId,
          payload.levelChoiceSelections,
        ));
      }

      // 5. Calculate and save characteristics (base values = fixed + array +
      // level improvements)
      const charService = StartingCharacteristicsService();
      final adjustmentEntries = charService.collectAdjustmentEntries(
        classData: classData,
        selectedLevel: payload.level,
      );

      final baseCharacteristics = <String, int>{
        for (final stat in CharacteristicUtils.characteristicOrder) stat: 0,
      };

      startingChars.fixedStartingCharacteristics.forEach((key, value) {
        final normalizedKey = CharacteristicUtils.normalizeKey(key);
        if (normalizedKey != null) {
          baseCharacteristics[normalizedKey] = value;
        }
      });

      payload.assignedCharacteristics.forEach((characteristic, value) {
        final charLower = characteristic.toLowerCase();
        if (baseCharacteristics.containsKey(charLower)) {
          baseCharacteristics[charLower] =
              (baseCharacteristics[charLower] ?? 0) + value;
        }
      });

      for (final entry in adjustmentEntries) {
        final adjustmentPayload = entry.payload;
        if (entry.target == 'all') {
          for (final stat in CharacteristicUtils.characteristicOrder) {
            _applyCharacteristicPayload(
                stat, adjustmentPayload, baseCharacteristics);
          }
        } else if (entry.target == 'any') {
          final choiceId = entry.choiceId;
          if (choiceId != null) {
            final chosenStat = payload.levelChoiceSelections[choiceId];
            if (chosenStat != null) {
              _applyCharacteristicPayload(
                  chosenStat, adjustmentPayload, baseCharacteristics);
            }
          }
        } else if (CharacteristicUtils.characteristicOrder
            .contains(entry.target)) {
          _applyCharacteristicPayload(
              entry.target, adjustmentPayload, baseCharacteristics);
        }
      }

      for (final entry in baseCharacteristics.entries) {
        updates.add(
          _heroRepository.setCharacteristicBase(heroId,
              characteristic: entry.key, value: entry.value),
        );
      }

      // 5.5. Load feature stat bonuses (from class features like
      // "stamina_increase: 21"). Speed/disengage bonuses may be
      // characteristic-based, so they're computed at runtime, not here.
      final featureStatBonuses =
          await _heroRepository.getFeatureStatBonuses(heroId);
      final featureStaminaBonus = featureStatBonuses['stamina'] ?? 0;

      // 6. Calculate and save Stamina (class base + level scaling +
      // equipment bonus + feature bonus)
      final baseMaxStamina = startingChars.baseStamina +
          (startingChars.staminaPerLevel * (payload.level - 1));
      final effectiveMaxStamina = baseMaxStamina +
          equipmentBonuses.staminaBonus +
          featureStaminaBonus;
      updates.add(_heroRepository.updateVitals(
        heroId,
        staminaMax: baseMaxStamina,
        staminaCurrent: effectiveMaxStamina,
      ));

      // 7. Calculate winded and dying values (based on effective max
      // stamina)
      final windedValue = effectiveMaxStamina ~/ 2;
      final dyingValue = -(effectiveMaxStamina ~/ 2);
      updates.add(_heroRepository.updateVitals(
        heroId,
        windedValue: windedValue,
        dyingValue: dyingValue,
      ));

      // 8. Save Recoveries
      final recoveriesMax = startingChars.baseRecoveries;
      final recoveryValue = (effectiveMaxStamina / 3).ceil();
      updates.add(_heroRepository.updateVitals(
        heroId,
        recoveriesMax: recoveriesMax,
        recoveriesCurrent: recoveriesMax,
      ));
      updates.add(_heroRepository.updateRecoveryValue(heroId, recoveryValue));

      // 9. Save stats from class (equipment bonuses are stored separately)
      updates.add(_heroRepository.updateCoreStats(
        heroId,
        speed: startingChars.baseSpeed,
        stability: startingChars.baseStability,
        disengage: startingChars.baseDisengage,
      ));

      // 10. Save Heroic Resource name
      updates.add(_heroRepository.updateHeroicResourceName(
        heroId,
        startingChars.heroicResourceName,
      ));

      // 11. Calculate and save potencies based on class progression
      final potencyChar = startingChars.potencyProgression.characteristic;
      final potencyModifiers = startingChars.potencyProgression.modifiers;
      final potencyCharValue = payload.assignedCharacteristics[potencyChar] ??
          startingChars.fixedStartingCharacteristics[
                  potencyChar.toLowerCase()] ??
          0;
      final strongPotency =
          potencyCharValue + (potencyModifiers['strong'] ?? 0);
      final averagePotency =
          potencyCharValue + (potencyModifiers['average'] ?? 0);
      final weakPotency = potencyCharValue + (potencyModifiers['weak'] ?? 0);
      updates.add(_heroRepository.updatePotencies(
        heroId,
        strong: '$strongPotency',
        average: '$averagePotency',
        weak: '$weakPotency',
      ));

      // 12. Save selected abilities. Replace only the Strife manual-choice
      // source; grants from perks, kits, ancestry, the hero sheet, and other
      // sources remain untouched.
      final selectedAbilityIds = payload.selectedAbilities.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      updates.add(
        _mutations.replaceContentEntries(
          heroId: heroId,
          source: const HeroSource.manualChoice(
            sourceId: HeroEntrySourceIds.strifeAbilityChoice,
          ),
          entryType: HeroEntryTypes.ability,
          entryIds: selectedAbilityIds,
        ),
      );
      updates.add(_db.setHeroConfig(
        heroId: heroId,
        configKey: 'strife.ability_selections',
        value: payload.selectedAbilities.map((k, v) => MapEntry(k, v)),
      ));
      updates.add(_db.deleteHeroConfig(heroId, 'strife.import_ability_ids'));

      // 13. Save subclass skill via hero_entries (properly tracks source for
      // removal on change)
      final subclassSkillId = _resolveSkillId(
        selectedSubclass?.skill,
        payload.skillIdLookup,
      );
      updates.add(_heroRepository.saveSubclassSkill(heroId, subclassSkillId));
      if (subclassSkillId != null && subclassSkillId.isNotEmpty) {
        updates.add(_db.setHeroConfig(
          heroId: heroId,
          configKey: 'strife.subclass_skill_id',
          value: {'id': subclassSkillId},
        ));
      } else {
        updates.add(_db.deleteHeroConfig(heroId, 'strife.subclass_skill_id'));
      }

      // 14. Save selected skills. After clearStrifeData, only story-sourced
      // skills remain; add new strife selections (not the subclass skill,
      // which is tracked separately via entries).
      final strifeSkillIds = payload.selectedSkills.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      updates.add(
        _mutations.replaceContentEntries(
          heroId: heroId,
          source: const HeroSource.manualChoice(
            sourceId: HeroEntrySourceIds.strifeSkillChoice,
          ),
          entryType: HeroEntryTypes.skill,
          entryIds: strifeSkillIds,
        ),
      );
      updates.add(_db.setHeroConfig(
        heroId: heroId,
        configKey: 'strife.skill_selections',
        value: payload.selectedSkills.map((k, v) => MapEntry(k, v)),
      ));

      // 15. Save selected perks. After clearStrifeData, only story-sourced
      // perks remain.
      strifePerkIds = payload.selectedPerks.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      updates.add(
        _mutations.replaceContentEntries(
          heroId: heroId,
          source: const HeroSource.manualChoice(
            sourceId: HeroEntrySourceIds.strifePerkChoice,
          ),
          entryType: HeroEntryTypes.perk,
          entryIds: strifePerkIds,
        ),
      );
      updates.add(_db.setHeroConfig(
        heroId: heroId,
        configKey: 'strife.perk_selections',
        value: payload.selectedPerks.map((k, v) => MapEntry(k, v)),
      ));

      await Future.wait(updates);

      await _syncStrifePerkGrants(
        heroId: heroId,
        previousPerkIds: payload.previousPerkIds,
        currentPerkIds: strifePerkIds,
      );
    });

    // Apply class feature grants so bonuses apply even without visiting the
    // Strength page. Best-effort: non-critical for the main save.
    try {
      final savedFeatureSelections =
          await _heroRepository.getFeatureSelections(heroId);
      final grantService = ClassFeatureGrantsService(_db);
      await grantService.applyClassFeatureSelections(
        heroId: heroId,
        classData: classData,
        level: payload.level,
        selections: savedFeatureSelections,
        subclassSelection: payload.selectedSubclass,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to apply class feature grants: $e');
    }

    return StrifeCreatorSaveResult(strifePerkIds: strifePerkIds);
  }
}
