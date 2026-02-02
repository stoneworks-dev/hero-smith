import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart' as db;
import '../db/providers.dart';
import '../models/ancestry_bonus_models.dart';
import '../models/complication_grant_models.dart';
import '../models/damage_resistance_model.dart';
import '../models/dynamic_modifier_model.dart';
import '../models/stat_modification_model.dart';
import 'ability_resolver_service.dart';
import 'damage_resistance_service.dart';
import 'dynamic_modifiers_service.dart';
import '../repositories/hero_entry_repository.dart';

/// Service for managing complication grants.
/// Handles parsing complications, applying grants to heroes, and removing them when complications change.
class ComplicationGrantsService {
  ComplicationGrantsService(this._db)
      : _dynamicModifiers = DynamicModifiersService(_db),
        _entries = HeroEntryRepository(_db),
        _abilityResolver = AbilityResolverService(_db),
        _resistanceService = DamageResistanceService(_db);

  final db.AppDatabase _db;
  final DynamicModifiersService _dynamicModifiers;
  final HeroEntryRepository _entries;
  final AbilityResolverService _abilityResolver;
  final DamageResistanceService _resistanceService;

  /// Parse all grants from a complication's data.
  Future<AppliedComplicationGrants> parseComplicationGrants({
    required String? complicationId,
    Map<String, String> choices = const {},
  }) async {
    if (complicationId == null || complicationId.isEmpty) {
      return AppliedComplicationGrants.empty;
    }

    final allComponents = await _db.getAllComponents();

    // Find the complication component
    final complicationComp = allComponents.firstWhereOrNull((c) {
      if (c.type != 'complication') return false;
      return c.id == complicationId;
    });

    if (complicationComp == null) {
      return AppliedComplicationGrants.empty;
    }

    final compData = jsonDecode(complicationComp.dataJson) as Map<String, dynamic>;
    final compName = (compData['name'] as String?) ?? complicationComp.name;
    
    // Get the grants section
    final grantsData = compData['grants'] as Map<String, dynamic>?;
    if (grantsData == null || grantsData.isEmpty) {
      return AppliedComplicationGrants(
        complicationId: complicationId,
        complicationName: compName,
        grants: [],
      );
    }

    final grants = ComplicationGrant.parseFromGrantsData(
      grantsData,
      complicationId,
      compName,
      choices,
    );

    return AppliedComplicationGrants(
      complicationId: complicationId,
      complicationName: compName,
      grants: grants,
    );
  }

  /// Apply complication grants to a hero.
  /// This updates the hero's stats, skills, abilities, etc.
  Future<void> applyGrants({
    required String heroId,
    required AppliedComplicationGrants grants,
    required int heroLevel,
  }) async {
    // Store the raw grants for later removal
    await _saveGrants(heroId, grants);

    // Apply stat modifications
    await _applyStatGrants(heroId, grants, heroLevel);

    // Apply damage resistances (immunity/weakness)
    await _applyDamageResistanceGrants(heroId, grants, heroLevel);

    // Apply token grants
    await _applyTokenGrants(heroId, grants);

    // Apply granted abilities
    await _applyAbilityGrants(heroId, grants);

    // Apply granted skills
    await _applySkillGrants(heroId, grants);

    // Apply recovery bonuses
    await _applyRecoveryGrants(heroId, grants);

    // Apply treasure grants
    await _applyTreasureGrants(heroId, grants);

    // Apply language grants
    await _applyLanguageGrants(heroId, grants);

    // Apply feature grants (mounts, retainers, etc.)
    await _applyFeatureGrants(heroId, grants);

    // Apply ancestry trait grants (e.g., Dragon Dreams complication)
    await _applyAncestryTraitGrants(heroId, grants, heroLevel);
  }

  /// Remove all complication grants from a hero.
  /// 
  /// This clears all entries with sourceType='complication' from hero_entries,
  /// regardless of whether the grants config exists. This ensures orphaned
  /// entries are always cleaned up.
  Future<void> removeGrants(String heroId) async {
    final currentGrants = await loadGrants(heroId);

    // Restore original base stats that were modified by complication
    await _restoreOriginalBaseStats(heroId);

    // Clear stat modifications from complication
    await _clearComplicationStatMods(heroId);

    // Clear damage resistance grants
    await _clearDamageResistanceGrants(heroId);

    // Clear token grants
    await _clearTokenGrants(heroId);

    // Clear ability grants - always clear even if config is null
    await _clearAbilityGrants(heroId);

    // Clear skill grants - always clear even if config is null
    await _clearSkillGrants(heroId);

    // Clear recovery grants (legacy static storage)
    await _clearRecoveryGrants(heroId);

    // Clear dynamic modifiers from this complication (only if we know the ID)
    if (currentGrants != null) {
      await _dynamicModifiers.removeModifiersFromSource(
        heroId,
        'complication_${currentGrants.complicationId}',
      );
    }

    // Clear treasure grants - always clear even if config is null
    await _clearTreasureGrants(heroId);

    // Clear language grants - always clear even if config is null
    await _clearLanguageGrants(heroId);

    // Clear feature grants - always clear even if config is null
    await _clearFeatureGrants(heroId);

    // Clear ancestry trait grants (e.g., Dragon Dreams complication)
    await _clearAncestryTraitGrants(heroId);

    // Clear stored grants config
    await _db.deleteHeroConfig(heroId, _kComplicationGrants);
  }

  /// Load currently applied grants for a hero.
  Future<AppliedComplicationGrants?> loadGrants(String heroId) async {
    final config = await _db.getHeroConfigValue(heroId, _kComplicationGrants);
    if (config == null) return null;
    try {
      return AppliedComplicationGrants.fromJsonString(jsonEncode(config));
    } catch (_) {
      return null;
    }
  }

  /// Save complication choices (user selections for skills, treasures, etc.)
  Future<void> saveComplicationChoices({
    required String heroId,
    required Map<String, String> choices,
  }) async {
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: _kComplicationChoices,
      value: choices,
    );
  }

  /// Load complication choices for a hero.
  Future<Map<String, String>> loadComplicationChoices(String heroId) async {
    final config = await _db.getHeroConfigValue(heroId, _kComplicationChoices);
    if (config == null) return {};
    return config.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Load tokens granted by complication.
  Future<Map<String, int>> loadTokenGrants(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kComplicationTokens);
    if (value?.textValue == null && value?.jsonValue == null) {
      return {};
    }
    try {
      final json = jsonDecode(value!.jsonValue ?? value.textValue!);
      if (json is Map) {
        return json.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  /// Load abilities granted by complication.
  Future<Map<String, String>> loadAbilityGrants(String heroId) async {
    final entries =
        await _entries.listEntriesByType(heroId, 'ability');
    final map = <String, String>{};
    for (final e in entries.where((e) => e.sourceType == 'complication')) {
      map[e.entryId] = e.sourceId;
    }
    return map;
  }

  /// Load skills granted by complication.
  Future<List<String>> loadSkillGrants(String heroId) async {
    final entries =
        await _entries.listEntriesByType(heroId, 'skill');
    return entries
        .where((e) => e.sourceType == 'complication')
        .map((e) => e.entryId)
        .toList();
  }

  /// Ensure that any previously granted skills are synced into the hero's skill list.
  Future<void> syncSkillGrants(String heroId) async {
    final storedValues = await loadSkillGrants(heroId);
    if (storedValues.isEmpty) return;

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: 'complication_sync',
      entryType: 'skill',
      entryIds: storedValues,
      gainedBy: 'grant',
    );
  }

  /// Load complication stat modifications.
  Future<HeroStatModifications> loadComplicationStatMods(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final modsValue = values.firstWhereOrNull((v) => v.key == _kComplicationStatMods);
    
    if (modsValue?.jsonValue == null && modsValue?.textValue == null) {
      return const HeroStatModifications.empty();
    }
    
    try {
      final jsonStr = modsValue!.jsonValue ?? modsValue.textValue!;
      return HeroStatModifications.fromJsonString(jsonStr);
    } catch (_) {
      return const HeroStatModifications.empty();
    }
  }

  /// Watch complication stat modifications - automatically updates when values change.
  Stream<HeroStatModifications> watchComplicationStatMods(String heroId) {
    return _db.watchHeroValues(heroId).map((values) {
      final modsValue = values.firstWhereOrNull((v) => v.key == _kComplicationStatMods);
      if (modsValue?.jsonValue == null && modsValue?.textValue == null) {
        return const HeroStatModifications.empty();
      }
      try {
        final jsonStr = modsValue!.jsonValue ?? modsValue.textValue!;
        return HeroStatModifications.fromJsonString(jsonStr);
      } catch (_) {
        return const HeroStatModifications.empty();
      }
    });
  }

  /// Load recovery bonus from complication.
  Future<int> loadRecoveryBonus(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kComplicationRecoveryBonus);
    return value?.value ?? 0;
  }

  /// Load damage resistances for a hero.
  /// Delegates to DamageResistanceService for centralized management.
  Future<HeroDamageResistances> loadDamageResistances(String heroId) async {
    return _resistanceService.loadDamageResistances(heroId);
  }

  /// Save damage resistances for a hero.
  /// Delegates to DamageResistanceService for centralized management.
  Future<void> saveDamageResistances(
    String heroId,
    HeroDamageResistances resistances,
  ) async {
    await _resistanceService.saveDamageResistances(heroId, resistances);
  }

  // Private implementation methods

  Future<void> _saveGrants(String heroId, AppliedComplicationGrants grants) async {
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: _kComplicationGrants,
      value: grants.toJson(),
    );
  }

  Future<void> _applyStatGrants(
    String heroId,
    AppliedComplicationGrants grants,
    int heroLevel,
  ) async {
    // Track stat modifications with their sources and dynamic properties
    final statMods = <String, List<StatModification>>{};

    void addMod(String stat, StatModification mod) {
      final key = stat.toLowerCase();
      statMods.putIfAbsent(key, () => []);
      statMods[key]!.add(mod);
    }

    final values = await _db.getHeroValues(heroId);
    
    // Track original base stats before any changes
    final originalBaseStats = <String, int>{};

    for (final grant in grants.grants) {
      switch (grant) {
        case SetBaseStatIfNotLowerGrant():
          // Handle setting base stat if not already lower
          final currentValue = _getStatValue(values, grant.stat);
          if (currentValue > grant.value) {
            // Store the original value before changing it
            final statKey = grant.stat.toLowerCase();
            originalBaseStats[statKey] = currentValue;
            await _setBaseStat(heroId, grant.stat, grant.value);
          }

        case IncreaseTotalGrant():
          // Skip immunity/weakness - handled by _applyDamageResistanceGrants
          final stat = grant.stat.toLowerCase();
          if (stat == 'immunity' || stat == 'weakness') continue;
          // Create appropriate StatModification subtype based on grant properties
          final StatModification mod;
          if (grant.dynamicValue == 'level') {
            mod = LevelScaledStatModification(source: grant.sourceComplicationName);
          } else {
            mod = StaticStatModification(
              value: grant.value,
              source: grant.sourceComplicationName,
            );
          }
          addMod(grant.stat, mod);

        case IncreaseTotalPerEchelonGrant():
          // Skip immunity/weakness - handled by _applyDamageResistanceGrants
          final stat = grant.stat.toLowerCase();
          if (stat == 'immunity' || stat == 'weakness') continue;
          // Store with per-echelon metadata for dynamic calculation
          addMod(grant.stat, EchelonScaledStatModification(
            valuePerEchelon: grant.valuePerEchelon,
            source: grant.sourceComplicationName,
          ));

        case DecreaseTotalGrant():
          addMod(grant.stat, StaticStatModification(
            value: -grant.value,
            source: grant.sourceComplicationName,
          ));

        default:
          // Other grant types handled elsewhere
          break;
      }
    }

    // Save original base stats for later restoration when removing grants
    if (originalBaseStats.isNotEmpty) {
      await _saveOriginalBaseStats(heroId, originalBaseStats);
    }

    // Apply stat modifications with sources
    await _setComplicationStatMods(heroId, statMods);
  }

  Future<void> _applyTokenGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final tokens = <String, int>{};

    for (final grant in grants.grants) {
      if (grant is TokenGrant) {
        tokens[grant.tokenType] = (tokens[grant.tokenType] ?? 0) + grant.count;
      }
    }

    if (tokens.isEmpty) return;

    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationTokens,
      textValue: jsonEncode(tokens),
    );
  }

  Future<void> _applyAbilityGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final abilityNames = <String>[];

    for (final grant in grants.grants) {
      if (grant is AbilityGrant) {
        abilityNames.add(grant.abilityName);
      }
    }

    if (abilityNames.isEmpty) return;

    final abilityIds = await _abilityResolver.resolveAbilityIds(
      abilityNames,
      sourceType: 'complication',
    );

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'ability',
      entryIds: abilityIds,
      gainedBy: 'grant',
    );
  }

  Future<void> _applySkillGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final lookup = await _loadSkillLookup();
    final collectedSkillIds = <String>[];

    for (final grant in grants.grants) {
      switch (grant) {
        case SkillGrant():
          final skillId = lookup.nameToId[grant.skillName.toLowerCase()];
          if (skillId != null) {
            collectedSkillIds.add(skillId);
          }
        case SkillFromGroupGrant():
          collectedSkillIds.addAll(grant.selectedSkillIds);
        case SkillFromOptionsGrant():
          if (grant.selectedSkillId != null) {
            collectedSkillIds.add(grant.selectedSkillId!);
          }
        default:
          break;
      }
    }

    final skillIds = _dedupeSkillIds(collectedSkillIds);
    if (skillIds.isEmpty) return;

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'skill',
      entryIds: skillIds,
      gainedBy: 'grant',
    );
  }

  Future<void> _applyRecoveryGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final dynamicMods = <DynamicModifier>[];

    for (final grant in grants.grants) {
      if (grant is IncreaseRecoveryGrant) {
        final formula = _parseFormulaType(grant.value);
        dynamicMods.add(DynamicModifier(
          stat: DynamicModifierStats.recoveryValue,
          formulaType: formula.type,
          formulaParam: formula.param,
          operation: ModifierOperation.add,
          source: 'complication_${grants.complicationId}',
        ));
      }
    }

    if (dynamicMods.isEmpty) return;

    // Store as dynamic modifiers for automatic recalculation
    await _dynamicModifiers.addModifiers(
      heroId,
      'complication_${grants.complicationId}',
      dynamicMods,
    );
  }

  /// Parse a value string into a FormulaType
  ({FormulaType type, String? param}) _parseFormulaType(String value) {
    switch (value.toLowerCase()) {
      case 'highest_characteristic':
        return (type: FormulaType.highestCharacteristic, param: null);
      case 'level':
        return (type: FormulaType.level, param: null);
      case 'half_level':
        return (type: FormulaType.halfLevel, param: null);
      case 'might':
      case 'agility':
      case 'reason':
      case 'intuition':
      case 'presence':
        return (type: FormulaType.characteristic, param: value.toLowerCase());
      default:
        // Assume it's a fixed number
        return (type: FormulaType.fixed, param: value);
    }
  }

  /// Save the original base stat values before complication modifies them.
  Future<void> _saveOriginalBaseStats(String heroId, Map<String, int> stats) async {
    if (stats.isEmpty) return;
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationOriginalBaseStats,
      textValue: jsonEncode(stats),
    );
  }

  /// Load the original base stat values that were saved before complication modified them.
  Future<Map<String, int>> _loadOriginalBaseStats(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final entry = values.firstWhereOrNull((v) => v.key == _kComplicationOriginalBaseStats);
    if (entry?.jsonValue == null && entry?.textValue == null) return {};
    try {
      final raw = entry!.jsonValue ?? entry.textValue!;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  /// Restore original base stats when removing complication grants.
  Future<void> _restoreOriginalBaseStats(String heroId) async {
    final originalStats = await _loadOriginalBaseStats(heroId);
    for (final entry in originalStats.entries) {
      await _setBaseStat(heroId, entry.key, entry.value);
    }
    // Clear the stored original stats
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationOriginalBaseStats,
      textValue: null,
    );
  }

  Future<void> _clearComplicationStatMods(String heroId) async {
    // Clear from hero_entries (new storage)
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('stat_mod') &
              t.sourceType.equals('complication')))
        .go();
    
    // Also clear legacy hero_values for backwards compatibility
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationStatMods,
      textValue: null,
    );
  }

  Future<void> _clearTokenGrants(String heroId) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationTokens,
      textValue: null,
    );
  }

  Future<void> _clearAbilityGrants(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('ability') &
              t.sourceType.equals('complication')))
        .go();
  }

  Future<void> _clearSkillGrants(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('skill') &
              t.sourceType.equals('complication')))
        .go();
  }

  Future<void> _clearRecoveryGrants(String heroId) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationRecoveryBonus,
      value: null,
    );
  }

  Future<void> _applyDamageResistanceGrants(
    String heroId,
    AppliedComplicationGrants grants,
    int heroLevel,
  ) async {
    // Clear old complication resistance entries first
    await _clearDamageResistanceGrants(heroId);

    // Collect resistance data for batch processing
    final resistanceData = <String, ({
      int immunity,
      int weakness,
      String? dynamicImmunity,
      String? dynamicWeakness,
      int immunityPerEchelon,
      int weaknessPerEchelon,
    })>{};

    void addResistance({
      required String stat, 
      required String damageType, 
      required int value, 
      required String sourceName,
      String? dynamicValue,
      bool perEchelon = false,
      int valuePerEchelon = 0,
    }) {
      // Normalize "all damage" to "damage" for consistency
      var normalizedType = damageType.toLowerCase();
      if (normalizedType == 'all damage') {
        normalizedType = 'damage';
      }
      
      // Get or create entry
      final existing = resistanceData[normalizedType] ?? (
        immunity: 0,
        weakness: 0,
        dynamicImmunity: null,
        dynamicWeakness: null,
        immunityPerEchelon: 0,
        weaknessPerEchelon: 0,
      );
      
      if (stat == 'immunity') {
        resistanceData[normalizedType] = (
          immunity: existing.immunity + value,
          weakness: existing.weakness,
          dynamicImmunity: dynamicValue ?? existing.dynamicImmunity,
          dynamicWeakness: existing.dynamicWeakness,
          immunityPerEchelon: existing.immunityPerEchelon + (perEchelon ? valuePerEchelon : 0),
          weaknessPerEchelon: existing.weaknessPerEchelon,
        );
      } else {
        resistanceData[normalizedType] = (
          immunity: existing.immunity,
          weakness: existing.weakness + value,
          dynamicImmunity: existing.dynamicImmunity,
          dynamicWeakness: dynamicValue ?? existing.dynamicWeakness,
          immunityPerEchelon: existing.immunityPerEchelon,
          weaknessPerEchelon: existing.weaknessPerEchelon + (perEchelon ? valuePerEchelon : 0),
        );
      }
    }

    for (final grant in grants.grants) {
      if (grant is IncreaseTotalGrant) {
        final stat = grant.stat.toLowerCase();
        if (stat == 'immunity' || stat == 'weakness') {
          final damageType = grant.damageType ?? 'untyped';
          addResistance(
            stat: stat, 
            damageType: damageType, 
            value: grant.value, 
            sourceName: grant.sourceComplicationName,
            dynamicValue: grant.dynamicValue,
          );
        }
      } else if (grant is IncreaseTotalPerEchelonGrant) {
        final stat = grant.stat.toLowerCase();
        if (stat == 'immunity' || stat == 'weakness') {
          final damageType = grant.damageType ?? 'untyped';
          addResistance(
            stat: stat, 
            damageType: damageType, 
            value: 0, 
            sourceName: grant.sourceComplicationName,
            perEchelon: true,
            valuePerEchelon: grant.valuePerEchelon,
          );
        }
      }
    }

    // Store each resistance entry using DamageResistanceService
    for (final entry in resistanceData.entries) {
      final type = entry.key;
      final data = entry.value;
      await _resistanceService.addResistanceEntry(
        heroId: heroId,
        damageType: type,
        sourceType: 'complication',
        sourceId: grants.complicationId,
        immunity: data.immunity,
        weakness: data.weakness,
        dynamicImmunity: data.dynamicImmunity,
        dynamicWeakness: data.dynamicWeakness,
        immunityPerEchelon: data.immunityPerEchelon,
        weaknessPerEchelon: data.weaknessPerEchelon,
      );
    }

    // Recompute aggregate resistances
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  Future<void> _clearDamageResistanceGrants(String heroId) async {
    await _resistanceService.removeResistanceEntriesBySourceType(
      heroId: heroId,
      sourceType: 'complication',
    );
    // Recompute aggregate resistances after clearing
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  Future<void> _applyLanguageGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final languageIds = <String>[];

    for (final grant in grants.grants) {
      if (grant is LanguageGrant) {
        languageIds.addAll(grant.selectedLanguageIds);
      } else if (grant is DeadLanguageGrant) {
        languageIds.addAll(grant.selectedLanguageIds);
      }
    }

    if (languageIds.isEmpty) return;

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'language',
      entryIds: languageIds,
      gainedBy: 'grant',
    );
  }

  /// Rebuild damage resistances - now a no-op since bonuses are calculated at runtime.
  /// 
  /// Previously this method would:
  Future<void> _clearLanguageGrants(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('language') &
              t.sourceType.equals('complication')))
        .go();
  }

  // ignore: unused_element
  Future<void> _ensureHeroHasSkillComponents(
    String heroId,
    List<String> skillIds,
  ) async {
    if (skillIds.isEmpty) return;

    final currentSkills = await _db.getHeroComponentIds(heroId, 'skill');
    final missing = skillIds.where((id) => !currentSkills.contains(id)).toList();
    if (missing.isEmpty) return;

    final updatedSkills = {...currentSkills, ...skillIds}.toList();
    await _db.setHeroComponentIds(
      heroId: heroId,
      category: 'skill',
      componentIds: updatedSkills,
    );
  }

  Future<_SkillLookup> _loadSkillLookup() async {
    final allComponents = await _db.getAllComponents();
    final skillComponents = allComponents.where((c) => c.type == 'skill');

    final skillIds = <String>{};
    final nameToId = <String, String>{};

    for (final skill in skillComponents) {
      skillIds.add(skill.id);

      try {
        final data = jsonDecode(skill.dataJson) as Map<String, dynamic>;
        final name = (data['name'] as String?) ?? skill.name;
        if (name.isNotEmpty) {
          nameToId[name.toLowerCase()] = skill.id;
        }
      } catch (_) {
        if (skill.name.isNotEmpty) {
          nameToId[skill.name.toLowerCase()] = skill.id;
        }
      }
    }

    return _SkillLookup(skillIds: skillIds, nameToId: nameToId);
  }

  // ignore: unused_element
  List<String> _resolveSkillIdentifiers(
    Iterable<String> rawIdentifiers,
    _SkillLookup lookup,
  ) {
    final seen = <String>{};
    final resolved = <String>[];

    for (final raw in rawIdentifiers) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      String? id;
      if (lookup.skillIds.contains(trimmed)) {
        id = trimmed;
      } else {
        id = lookup.nameToId[trimmed.toLowerCase()];
      }

      if (id != null && seen.add(id)) {
        resolved.add(id);
      }
    }

    return resolved;
  }

  List<String> _dedupeSkillIds(Iterable<String> skillIds) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in skillIds) {
      if (id.isEmpty) continue;
      if (seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }
  /// Load languages granted by complication.
  Future<List<String>> loadLanguageGrants(String heroId) async {
    final entries =
        await _entries.listEntriesByType(heroId, 'language');
    return entries
        .where((e) => e.sourceType == 'complication')
        .map((e) => e.entryId)
        .toList();
  }

  Future<void> _applyFeatureGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final features = <Map<String, dynamic>>[];

    for (final grant in grants.grants) {
      if (grant is FeatureGrant) {
        features.add({
          'name': grant.featureName,
          'type': grant.featureType,
          'source': grant.sourceComplicationName,
        });
      }
    }

    if (features.isEmpty) return;

    final comps = await _db.getAllComponents();
    final nameToId = {
      for (final c in comps) c.name.toLowerCase(): c.id,
    };
    final ids = features
        .map((f) => nameToId[f['name']!.toString().toLowerCase()] ??
            f['name']!.toString())
        .toList();

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'feature',
      entryIds: ids,
      gainedBy: 'grant',
    );
  }

  Future<void> _clearFeatureGrants(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('feature') &
              t.sourceType.equals('complication')))
        .go();
  }

  /// Apply ancestry trait grants from complications (e.g., Dragon Dreams).
  /// This parses the selected traits and applies their bonuses (abilities, 
  /// condition immunities, stat mods, etc.) to the hero.
  Future<void> _applyAncestryTraitGrants(
    String heroId,
    AppliedComplicationGrants grants,
    int heroLevel,
  ) async {
    // Find AncestryTraitsGrant in the grants
    final ancestryTraitGrant = grants.grants.whereType<AncestryTraitsGrant>().firstOrNull;
    if (ancestryTraitGrant == null) return;

    // Load the complication choices to get selected trait IDs
    final choices = await loadComplicationChoices(heroId);
    final choiceKey = '${grants.complicationId}_ancestry_traits';
    final selectedIdsStr = choices[choiceKey] ?? '';
    if (selectedIdsStr.isEmpty) return;
    final selectedTraitIds = selectedIdsStr.split(',').toSet();

    // Load the trait data from components
    final allComponents = await _db.getAllComponents();
    final targetAncestryId = 'ancestry_${ancestryTraitGrant.ancestry}';
    final traitsComp = allComponents.firstWhereOrNull((c) {
      if (c.type != 'ancestry_trait') return false;
      try {
        final data = jsonDecode(c.dataJson) as Map<String, dynamic>;
        return data['ancestry_id'] == targetAncestryId;
      } catch (_) {
        return false;
      }
    });

    if (traitsComp == null) return;

    final traitsData = jsonDecode(traitsComp.dataJson) as Map<String, dynamic>;
    final traitsList = (traitsData['traits'] as List?) ?? [];
    
    // Get trait-specific choices (like immunity picks)
    final traitChoices = <String, String>{};
    for (final entry in choices.entries) {
      if (entry.key.startsWith('${grants.complicationId}_trait_')) {
        // Extract the trait ID from the key
        final traitId = entry.key.replaceFirst('${grants.complicationId}_trait_', '');
        traitChoices[traitId] = entry.value;
      }
    }

    // Parse bonuses from selected traits
    final bonuses = <AncestryBonus>[];
    for (final trait in traitsList) {
      if (trait is! Map) continue;
      final traitMap = trait.cast<String, dynamic>();
      final traitId = (traitMap['id'] ?? traitMap['name']).toString();
      
      if (!selectedTraitIds.contains(traitId)) continue;

      final traitName = traitMap['name']?.toString() ?? traitId;
      final traitBonuses = AncestryBonus.parseFromTraitData(traitMap, traitId, traitName, traitChoices);
      bonuses.addAll(traitBonuses);
    }

    // Apply the bonuses with source type 'complication' instead of 'ancestry'
    // 1. Apply granted abilities
    await _applyAncestryTraitAbilities(heroId, grants.complicationId, bonuses);

    // 2. Apply condition immunities
    await _applyAncestryTraitConditionImmunities(heroId, grants.complicationId, bonuses);

    // 3. Apply stat modifications
    await _applyAncestryTraitStatMods(heroId, grants.complicationId, bonuses, heroLevel);

    // 4. Apply damage resistances
    await _applyAncestryTraitDamageResistances(heroId, grants.complicationId, bonuses, heroLevel);

    // Store the selected trait IDs in hero_entries for display purposes
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'ancestry_trait',
      entryIds: selectedTraitIds.toList(),
      gainedBy: 'grant',
    );
  }

  Future<void> _applyAncestryTraitAbilities(
    String heroId,
    String complicationId,
    List<AncestryBonus> bonuses,
  ) async {
    final abilities = <String, String>{}; // name -> source trait

    for (final bonus in bonuses) {
      if (bonus is GrantsAbilityBonus) {
        for (final name in bonus.abilityNames) {
          abilities[name] = bonus.sourceTraitName;
        }
      }
    }

    if (abilities.isEmpty) return;

    final allComponents = await _db.getAllComponents();
    final nameToId = {
      for (final c in allComponents.where((c) => c.type == 'ability'))
        c.name.toLowerCase(): c.id
    };
    final abilityIds = <String>[];
    abilities.forEach((name, _) {
      final id = nameToId[name.toLowerCase()] ?? name;
      abilityIds.add(id);
    });

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: complicationId,
      entryType: 'ability',
      entryIds: abilityIds,
      gainedBy: 'ancestry_trait_grant',
    );
  }

  Future<void> _applyAncestryTraitConditionImmunities(
    String heroId,
    String complicationId,
    List<AncestryBonus> bonuses,
  ) async {
    final immunities = <String>[];

    for (final bonus in bonuses) {
      if (bonus is ConditionImmunityBonus) {
        immunities.add(bonus.conditionName);
      }
    }

    if (immunities.isEmpty) return;

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: complicationId,
      entryType: 'condition_immunity',
      entryIds: immunities,
      gainedBy: 'ancestry_trait_grant',
    );
  }

  Future<void> _applyAncestryTraitStatMods(
    String heroId,
    String complicationId,
    List<AncestryBonus> bonuses,
    int heroLevel,
  ) async {
    // Group stat mods by stat name
    final statMods = <String, List<Map<String, dynamic>>>{};

    for (final bonus in bonuses) {
      if (bonus is IncreaseTotalBonus) {
        final stat = bonus.stat.toLowerCase();
        // Skip immunity/weakness - handled in damage resistances
        if (stat == 'immunity' || stat == 'weakness') continue;
        
        final value = bonus.calculateValue(heroLevel);
        statMods.putIfAbsent(stat, () => []);
        statMods[stat]!.add({
          'value': value,
          'source': '${bonus.sourceTraitName} (complication)',
        });
      } else if (bonus is IncreaseTotalPerEchelonBonus) {
        final stat = bonus.stat.toLowerCase();
        final echelon = ((heroLevel - 1) ~/ 3) + 1;
        final value = bonus.valuePerEchelon * echelon;
        statMods.putIfAbsent(stat, () => []);
        statMods[stat]!.add({
          'value': value,
          'source': '${bonus.sourceTraitName} (complication)',
        });
      } else if (bonus is DecreaseTotalBonus) {
        final stat = bonus.stat.toLowerCase();
        statMods.putIfAbsent(stat, () => []);
        statMods[stat]!.add({
          'value': -bonus.value,
          'source': '${bonus.sourceTraitName} (complication)',
        });
      } else if (bonus is SetBaseStatBonus) {
        // For set base stat, we add it as a stat_mod entry with special handling
        final stat = bonus.stat.toLowerCase();
        statMods.putIfAbsent(stat, () => []);
        statMods[stat]!.add({
          'value': bonus.value,
          'source': '${bonus.sourceTraitName} (complication base)',
          'type': 'set_base_if_higher',
        });
      }
    }

    if (statMods.isEmpty) return;

    // Store each stat mod in hero_entries
    for (final entry in statMods.entries) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'stat_mod',
        entryId: entry.key,
        sourceType: 'complication_ancestry_trait',
        sourceId: complicationId,
        gainedBy: 'ancestry_trait_grant',
        payload: {'mods': entry.value},
      );
    }
  }

  Future<void> _applyAncestryTraitDamageResistances(
    String heroId,
    String complicationId,
    List<AncestryBonus> bonuses,
    int heroLevel,
  ) async {
    final resistanceBonuses = <String, ({int immunity, int weakness, List<String> sources})>{};

    for (final bonus in bonuses) {
      if (bonus is IncreaseTotalBonus) {
        final stat = bonus.stat.toLowerCase();
        if (stat != 'immunity' && stat != 'weakness') continue;
        
        final types = bonus.damageTypes ?? [];
        final value = bonus.calculateValue(heroLevel);
        
        for (final type in types) {
          final key = type.toLowerCase();
          final existing = resistanceBonuses[key] ?? (immunity: 0, weakness: 0, sources: <String>[]);
          
          if (stat == 'immunity') {
            resistanceBonuses[key] = (
              immunity: existing.immunity + value,
              weakness: existing.weakness,
              sources: [...existing.sources, bonus.sourceTraitName],
            );
          } else {
            resistanceBonuses[key] = (
              immunity: existing.immunity,
              weakness: existing.weakness + value,
              sources: [...existing.sources, bonus.sourceTraitName],
            );
          }
        }
      }
    }

    if (resistanceBonuses.isEmpty) return;

    // Store each resistance using DamageResistanceService
    for (final entry in resistanceBonuses.entries) {
      final data = entry.value;
      await _resistanceService.addResistanceEntry(
        heroId: heroId,
        damageType: entry.key,
        sourceType: 'complication',
        sourceId: complicationId,
        immunity: data.immunity,
        weakness: data.weakness,
      );
    }

    // Recompute aggregate resistances
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  Future<void> _clearAncestryTraitGrants(String heroId) async {
    // Clear ancestry_trait entries from complication source
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('ancestry_trait') &
              t.sourceType.equals('complication')))
        .go();
    
    // Clear abilities granted via ancestry traits from complication
    // (these have gainedBy='ancestry_trait_grant')
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('ability') &
              t.gainedBy.equals('ancestry_trait_grant')))
        .go();
    
    // Clear condition immunities granted via ancestry traits from complication
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('condition_immunity') &
              t.gainedBy.equals('ancestry_trait_grant')))
        .go();
    
    // Clear stat mods from complication_ancestry_trait source
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('stat_mod') &
              t.sourceType.equals('complication_ancestry_trait')))
        .go();
    
    // Clear resistances granted via ancestry traits from complication
    // (these have gainedBy='ancestry_trait_grant')
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('resistance') &
              t.gainedBy.equals('ancestry_trait_grant')))
        .go();
  }

  /// Load features granted by complication.
  Future<List<Map<String, dynamic>>> loadFeatureGrants(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kComplicationFeatures);
    if (value?.textValue == null && value?.jsonValue == null) {
      return [];
    }
    try {
      final json = jsonDecode(value!.jsonValue ?? value.textValue!);
      if (json is List) {
        return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _applyTreasureGrants(
    String heroId,
    AppliedComplicationGrants grants,
  ) async {
    final treasureIds = <String>[];

    for (final grant in grants.grants) {
      if (grant is TreasureGrant && grant.selectedTreasureId != null) {
        treasureIds.add(grant.selectedTreasureId!);
      } else if (grant is LeveledTreasureGrant && grant.selectedTreasureId != null) {
        treasureIds.add(grant.selectedTreasureId!);
      }
    }

    if (treasureIds.isEmpty) return;

    // Store the complication-granted treasure IDs
    if (treasureIds.isEmpty) return;

    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'complication',
      sourceId: grants.complicationId,
      entryType: 'treasure',
      entryIds: treasureIds,
      gainedBy: 'grant',
    );
  }

  Future<void> _clearTreasureGrants(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('treasure') &
              t.sourceType.equals('complication')))
        .go();
  }

  /// Load treasures granted by complication.
  Future<List<String>> loadTreasureGrants(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'treasure');
    return entries
        .where((e) => e.sourceType == 'complication')
        .map((e) => e.entryId)
        .toList();
  }

  Future<void> _setComplicationStatMods(
    String heroId,
    Map<String, List<StatModification>> statMods,
  ) async {
    if (statMods.isEmpty) return;

    // Store each stat as a separate hero_entry with entryType='stat_mod'
    // Format: entryId = stat name, payload = { "mods": [{ "value": X, "source": "...", ...dynamic fields }] }
    for (final entry in statMods.entries) {
      final stat = entry.key.toLowerCase();
      final mods = entry.value;
      
      if (mods.isEmpty) continue;
      
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'stat_mod',
        entryId: stat,
        sourceType: 'complication',
        sourceId: 'complication_grant',
        gainedBy: 'grant',
        payload: {
          'mods': mods.map((m) => m.toJson()).toList(),
        },
      );
    }
  }

  Future<void> _setBaseStat(String heroId, String stat, int value) async {
    final key = _statToKey(stat);
    if (key == null) return;

    await _db.upsertHeroValue(
      heroId: heroId,
      key: key,
      value: value,
    );
  }

  int _getStatValue(List<db.HeroValue> values, String stat) {
    final key = _statToKey(stat);
    if (key == null) return 0;

    final value = values.firstWhereOrNull((v) => v.key == key);
    return value?.value ?? 0;
  }

  String? _statToKey(String stat) {
    final normalized = stat.toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'might' => 'stats.might',
      'agility' => 'stats.agility',
      'reason' => 'stats.reason',
      'intuition' => 'stats.intuition',
      'presence' => 'stats.presence',
      'size' => 'stats.size',
      'speed' => 'stats.speed',
      'disengage' => 'stats.disengage',
      'stability' => 'stats.stability',
      'stamina' => 'stamina.max',
      'recoveries' => 'recoveries.max',
      'renown' => 'score.renown',
      'wealth' => 'score.wealth',
      'project_points' => 'stats.project_points',
      'saving_throw' || 'save' => 'conditions.save_ends',
      _ => null,
    };
  }

  // ============================================================
  // Token Tracking (current values during play)
  // ============================================================

  /// Load current token values (how many the hero currently has).
  /// These can be different from max values (grant values) during play.
  Future<Map<String, int>> loadCurrentTokenValues(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kComplicationTokensCurrent);
    if (value?.textValue == null && value?.jsonValue == null) {
      // If no current values saved, return the max values (grant values)
      return loadTokenGrants(heroId);
    }
    try {
      final json = jsonDecode(value!.jsonValue ?? value.textValue!);
      if (json is Map) {
        return json.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return loadTokenGrants(heroId);
  }

  /// Save current token values.
  Future<void> saveCurrentTokenValues(String heroId, Map<String, int> tokens) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kComplicationTokensCurrent,
      textValue: jsonEncode(tokens),
    );
  }

  /// Update a single token's current value.
  Future<void> updateTokenValue(String heroId, String tokenType, int newValue) async {
    final current = await loadCurrentTokenValues(heroId);
    current[tokenType] = newValue;
    await saveCurrentTokenValues(heroId, current);
  }

  /// Reset all tokens to their max values.
  Future<void> resetTokensToMax(String heroId) async {
    final maxValues = await loadTokenGrants(heroId);
    await saveCurrentTokenValues(heroId, maxValues);
  }

  // Storage keys
  static const _kComplicationGrants = 'complication.applied_grants';
  static const _kComplicationChoices = 'complication.choices';
  static const _kComplicationStatMods = 'complication.stat_mods';
  static const _kComplicationTokens = 'complication.tokens';
  static const _kComplicationTokensCurrent = 'complication.tokens_current';
  // ignore: unused_field
  static const _kComplicationAbilities = 'complication.abilities';
  // ignore: unused_field
  static const _kComplicationSkills = 'complication.skills';
  static const _kComplicationRecoveryBonus = 'complication.recovery_bonus';
  // ignore: unused_field
  static const _kComplicationTreasures = 'complication.treasures';
  // ignore: unused_field
  static const _kComplicationDamageResistances = 'complication.damage_resistances';
  // ignore: unused_field
  static const _kComplicationLanguages = 'complication.languages';
  static const _kComplicationFeatures = 'complication.features';
  static const _kComplicationOriginalBaseStats = 'complication.original_base_stats';
}

class _SkillLookup {
  const _SkillLookup({
    required this.skillIds,
    required this.nameToId,
  });

  final Set<String> skillIds;
  final Map<String, String> nameToId;
}

/// Provider for the complication grants service.
final complicationGrantsServiceProvider = Provider<ComplicationGrantsService>((ref) {
  final database = ref.read(appDatabaseProvider);
  return ComplicationGrantsService(database);
});
