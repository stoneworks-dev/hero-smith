import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart' as db;
import '../models/dynamic_modifier_model.dart';
import '../models/hero_model.dart';
import '../models/hero_mod_keys.dart';
import '../models/stat_modification_model.dart';
import '../services/treasure_bonus_service.dart';
import 'hero_entry_repository.dart';

/// All valid sizes in order: 1T, 1S, 1M, 1L, 2, 3, 4, 5
/// Each step is +1/-1 from the previous
const List<String> _sizeProgression = ['1T', '1S', '1M', '1L', '2', '3', '4', '5'];

/// Represents the parsed components of a size string (e.g., "1M" -> number: 1, category: "M")
class SizeParts {
  final int number;
  final String category; // T, S, M, L, or empty for sizes >= 2
  
  const SizeParts(this.number, this.category);
  
  @override
  String toString() => number >= 2 ? number.toString() : '$number$category';
  
  /// Get the index in the size progression (0-7)
  int get progressionIndex {
    final sizeStr = toString();
    final idx = _sizeProgression.indexOf(sizeStr);
    return idx >= 0 ? idx : 2; // Default to 1M (index 2) if not found
  }
  
  /// Create SizeParts from a progression index
  static SizeParts fromIndex(int index) {
    final clampedIndex = index.clamp(0, _sizeProgression.length - 1);
    return _parseSize(_sizeProgression[clampedIndex]);
  }
  
  /// Parse a size string into SizeParts
  static SizeParts _parseSize(String size) {
    if (size.isEmpty) return const SizeParts(1, 'M');
    
    final lastChar = size[size.length - 1].toUpperCase();
    if ('TSML'.contains(lastChar)) {
      final numPart = size.substring(0, size.length - 1);
      return SizeParts(int.tryParse(numPart) ?? 1, lastChar);
    }
    
    // No category letter, just a number (e.g., "2", "3")
    return SizeParts(int.tryParse(size) ?? 2, '');
  }
}

class HeroSummary {
  final String id;
  final String name;
  final String? className;
  final String? subclassName;
  final int level;
  final String? ancestryName;
  final String? careerName;
  final String? complicationName;
  final String? heroicResourceName;

  const HeroSummary({
    required this.id,
    required this.name,
    required this.className,
    this.subclassName,
    required this.level,
    required this.ancestryName,
    required this.careerName,
    required this.complicationName,
    required this.heroicResourceName,
  });
}

class HeroMainStats {
  final int victories;
  final int exp;
  final int level;

  final int wealthBase;
  final int renownBase;

  final int mightBase;
  final int agilityBase;
  final int reasonBase;
  final int intuitionBase;
  final int presenceBase;

  final String sizeBase;
  final int speedBase;
  final int disengageBase;
  final int stabilityBase;

  final int staminaCurrent;
  final int staminaMaxBase;
  final int staminaTemp;

  final int recoveriesCurrent;
  final int recoveriesMaxBase;
  final int recoveryValueBonus; // Legacy static bonus (for backward compatibility)

  final int surgesCurrent;

  final int heroTokensCurrent;

  final String? classId;
  final String? heroicResourceName;
  final int heroicResourceCurrent;

  final Map<String, int> modifications;
  final Map<String, int> userModifications;
  final Map<String, int> choiceModifications;
  final Map<String, int> equipmentBonuses;
  
  /// All bonuses from equipped treasures (stamina, stability, speed, immunities).
  final EquippedTreasureBonuses treasureBonuses;
  
  /// Dynamic modifiers that recalculate based on current stats
  final DynamicModifierList dynamicModifiers;

  const HeroMainStats({
    required this.victories,
    required this.exp,
    required this.level,
    required this.wealthBase,
    required this.renownBase,
    required this.mightBase,
    required this.agilityBase,
    required this.reasonBase,
    required this.intuitionBase,
    required this.presenceBase,
    required this.sizeBase,
    required this.speedBase,
    required this.disengageBase,
    required this.stabilityBase,
    required this.staminaCurrent,
    required this.staminaMaxBase,
    required this.staminaTemp,
    required this.recoveriesCurrent,
    required this.recoveriesMaxBase,
    this.recoveryValueBonus = 0,
    required this.surgesCurrent,
    this.heroTokensCurrent = 0,
    required this.classId,
    required this.heroicResourceName,
    required this.heroicResourceCurrent,
    required this.modifications,
    this.userModifications = const {},
    this.choiceModifications = const {},
    this.equipmentBonuses = const {},
    this.treasureBonuses = const EquippedTreasureBonuses(
      stamina: 0,
      highestNonStackingStamina: 0,
      stackingStamina: 0,
      stability: 0,
      speed: 0,
      immunities: {},
    ),
    this.dynamicModifiers = const DynamicModifierList([]),
  });

  int modValue(String key) => modifications[key] ?? 0;
  int userModValue(String key) => userModifications[key] ?? 0;
  int choiceModValue(String key) => choiceModifications[key] ?? 0;
  int equipmentBonusFor(String key) {
    return switch (key) {
      HeroModKeys.speed => equipmentBonuses['speed'] ?? 0,
      HeroModKeys.disengage => equipmentBonuses['disengage'] ?? 0,
      HeroModKeys.stability => equipmentBonuses['stability'] ?? 0,
      HeroModKeys.staminaMax => equipmentBonuses['stamina'] ?? 0,
      _ => 0,
    };
  }

  int get wealthTotal => wealthBase + modValue(HeroModKeys.wealth);
  int get renownTotal => renownBase + modValue(HeroModKeys.renown);

  int get mightTotal => mightBase + modValue(HeroModKeys.might);
  int get agilityTotal => agilityBase + modValue(HeroModKeys.agility);
  int get reasonTotal => reasonBase + modValue(HeroModKeys.reason);
  int get intuitionTotal => intuitionBase + modValue(HeroModKeys.intuition);
  int get presenceTotal => presenceBase + modValue(HeroModKeys.presence);

  /// Returns the size as a formatted string (e.g., "1M", "2", "1L")
  /// Size modifications move along the progression: 1T → 1S → 1M → 1L → 2 → 3 → 4 → 5
  String get sizeTotal {
    final mod = modValue(HeroModKeys.size);
    if (mod == 0) return sizeBase;
    
    // Parse the base size and get its index in the progression
    final parsed = parseSize(sizeBase);
    final baseIndex = parsed.progressionIndex;
    final newIndex = (baseIndex + mod).clamp(0, _sizeProgression.length - 1);
    
    return _sizeProgression[newIndex];
  }
  
  /// Parse a size string into its numeric and category components
  static SizeParts parseSize(String size) {
    return SizeParts._parseSize(size);
  }
  
  /// Get the progression index for a size string (0 = 1T, 7 = 5)
  static int sizeToIndex(String size) {
    final idx = _sizeProgression.indexOf(size.toUpperCase());
    return idx >= 0 ? idx : 2; // Default to 1M (index 2)
  }
  
  /// Get size string from progression index
  static String indexToSize(int index) {
    return _sizeProgression[index.clamp(0, _sizeProgression.length - 1)];
  }
  
  /// Get the progression index of the total size (for calculations)
  int get sizeIndex => sizeToIndex(sizeTotal);
  
  /// Feature bonuses (from class features, ancestry traits, perks, titles, etc.)
  /// These are calculated from dynamic modifiers and shown separately in UI.
  int get speedFeatureBonus => dynamicBonusFor('speed');
  int get disengageFeatureBonus => dynamicBonusFor('disengage');
  int get stabilityFeatureBonus => dynamicBonusFor('stability');
  int get staminaFeatureBonus => dynamicBonusFor('stamina');
  int get recoveriesFeatureBonus => dynamicBonusFor('recoveries');
  
  /// Treasure bonuses for speed, stability
  int get treasureSpeedBonus => treasureBonuses.speed;
  int get treasureStabilityBonus => treasureBonuses.stability;
  int get treasureStaminaBonus => treasureBonuses.stamina;
  
  /// Treasure immunities (damage type -> immunity value)
  Map<String, int> get treasureImmunities => treasureBonuses.immunities;

  int get speedTotal => speedBase + modValue(HeroModKeys.speed) + speedFeatureBonus + treasureSpeedBonus;
  int get disengageTotal => disengageBase + modValue(HeroModKeys.disengage) + disengageFeatureBonus;
  int get stabilityTotal => stabilityBase + modValue(HeroModKeys.stability) + stabilityFeatureBonus + treasureStabilityBonus;

  /// Total stamina max including all bonuses:
  /// - Base stamina
  /// - Modifications (from choices, ancestry, etc.)
  /// - Feature bonuses (from class features, etc.)
  /// - Treasure bonuses (armor imbuements + equipped treasures with stacking rules)
  int get staminaMaxEffective =>
      staminaMaxBase + modValue(HeroModKeys.staminaMax) + staminaFeatureBonus + treasureStaminaBonus;
  int get recoveriesMaxEffective =>
      recoveriesMaxBase + modValue(HeroModKeys.recoveriesMax) + recoveriesFeatureBonus;
  int get surgesTotal => surgesCurrent + modValue(HeroModKeys.surges);

  /// Create a context for dynamic modifier calculations
  HeroStatsContext get _statsContext => HeroStatsContext(
        level: level,
        might: mightTotal,
        agility: agilityTotal,
        reason: reasonTotal,
        intuition: intuitionTotal,
        presence: presenceTotal,
      );

  /// Calculate recovery value: (staminaMax / 3) + dynamic bonuses
  int get recoveryValueEffective {
    final max = staminaMaxEffective;
    if (max <= 0) return 0;
    final base = max ~/ 3;
    if (base <= 0) return 0;
    
    // Calculate dynamic bonus from formulas
    final dynamicBonus = dynamicModifiers.calculateTotal(
      'recovery_value',
      _statsContext,
    );
    
    // Also include legacy static bonus for backward compatibility
    return base + dynamicBonus + recoveryValueBonus;
  }

  /// Calculate dynamic bonus for any stat
  int dynamicBonusFor(String stat) {
    return dynamicModifiers.calculateTotal(stat, _statsContext);
  }

  /// Calculate dynamic bonus for typed stats (immunity, weakness)
  int dynamicTypedBonusFor(String stat, String type) {
    return dynamicModifiers.calculateTypedTotal(stat, type, _statsContext);
  }
}

class HeroRepository {
  HeroRepository(this._db) : _entries = HeroEntryRepository(_db);
  final db.AppDatabase _db;
  final HeroEntryRepository _entries;

  // Keys mapping for HeroValues
  static const _k = _HeroKeys._();

  Future<String> createHero({required String name}) async {
    final id = await _db.createHero(name: name);
    // Initialize saveEnds with default value of 6
    await _db.upsertHeroValue(heroId: id, key: _k.saveEnds, value: 6);
    // Initialize default base stats for a new hero
    await _db.upsertHeroValue(heroId: id, key: _k.wealth, value: 1);
    await _db.upsertHeroValue(heroId: id, key: _k.disengage, value: 1);
    await _db.upsertHeroValue(heroId: id, key: _k.speed, value: 5);
    await _db.upsertHeroValue(heroId: id, key: _k.stability, value: 0);
    await _db.upsertHeroValue(heroId: id, key: _k.size, textValue: '1M'); // 1M (Medium)
    return id;
  }

  Stream<List<db.Heroe>> watchAllHeroes() => _db.watchAllHeroes();
  Future<List<db.Heroe>> getAllHeroes() => _db.getAllHeroes();

  Future<void> deleteHero(String heroId) => _db.deleteHero(heroId);

  /// Get the current level of a hero.
  Future<int> getHeroLevel(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final levelValue = values.firstWhereOrNull((v) => v.key == _k.level);
    return levelValue?.value ?? 1;
  }

  Stream<HeroMainStats> watchMainStats(String heroId) async* {
    yield await fetchMainStats(heroId);
    yield* _db.watchHeroValues(heroId).map(_mapValuesToMainStats);
  }

  Future<HeroMainStats> fetchMainStats(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    return _mapValuesToMainStats(values);
  }

  Future<void> updateMainStats(
    String heroId, {
    int? victories,
    int? exp,
    int? level,
    int? wealth,
    int? renown,
  }) async {
    Future<void> setInt(String key, int? value) async {
      if (value == null) return;
      await _db.upsertHeroValue(heroId: heroId, key: key, value: value);
    }

    await Future.wait([
      setInt(_k.victories, victories),
      setInt(_k.exp, exp),
      setInt(_k.level, level),
      setInt(_k.wealth, wealth),
      setInt(_k.renown, renown),
    ]);
  }

  Future<void> setModification(
    String heroId, {
    required String key,
    required int value,
  }) async {
    final values = await _db.getHeroValues(heroId);
    final current = Map<String, int>.from(_extractUserModifications(values));
    if (value == 0) {
      current.remove(key);
    } else {
      current[key] = value;
    }
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _k.modifications,
      jsonMap: current,
    );
  }

  /// Save coin purse data to the database
  Future<void> saveCoinPurse(
    String heroId,
    Map<String, dynamic> coinPurseJson,
  ) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _k.coinPurse,
      jsonMap: coinPurseJson,
    );
  }

  /// Get coin purse data from the database
  Future<Map<String, dynamic>?> getCoinPurse(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _k.coinPurse);
    if (value?.jsonValue == null) return null;
    return jsonDecode(value!.jsonValue!) as Map<String, dynamic>;
  }

  Future<void> updateVitals(
    String heroId, {
    int? staminaCurrent,
    int? staminaMax,
    int? staminaTemp,
    int? windedValue,
    int? dyingValue,
    int? recoveriesCurrent,
    int? recoveriesMax,
    int? surgesCurrent,
    int? heroicResourceCurrent,
    int? heroTokensCurrent,
  }) async {
    Future<void> setInt(String key, int? value) async {
      if (value == null) return;
      await _db.upsertHeroValue(heroId: heroId, key: key, value: value);
    }

    await Future.wait([
      setInt(_k.staminaCurrent, staminaCurrent),
      setInt(_k.staminaMax, staminaMax),
      setInt(_k.staminaTemp, staminaTemp),
      setInt(_k.windedValue, windedValue),
      setInt(_k.dyingValue, dyingValue),
      setInt(_k.recoveriesCurrent, recoveriesCurrent),
      setInt(_k.recoveriesMax, recoveriesMax),
      setInt(_k.surgesCurrent, surgesCurrent),
      setInt(_k.heroicResourceCurrent, heroicResourceCurrent),
      setInt(_k.heroTokensCurrent, heroTokensCurrent),
    ]);
  }

  /// Clamp current stamina to not exceed the max stamina.
  /// Returns true if the value was clamped and updated, false otherwise.
  Future<bool> clampCurrentStaminaToMax(
    String heroId, {
    required int currentStamina,
    required int maxStamina,
  }) async {
    if (currentStamina > maxStamina) {
      await _db.upsertHeroValue(
        heroId: heroId,
        key: _k.staminaCurrent,
        value: maxStamina,
      );
      return true;
    }
    return false;
  }

  Future<void> updateHeroicResourceName(String heroId, String? name) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _k.heroicResource,
      textValue: name,
    );
  }

  Future<void> updateClassName(String heroId, String? classId) async {
    if (classId == null || classId.isEmpty) {
      await _db.clearHeroEntryType(heroId, 'class');
      return;
    }
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'class',
      sourceId: classId,
      entryType: 'class',
      entryIds: [classId],
      gainedBy: 'choice',
    );
  }

  Future<void> updateSubclass(String heroId, String? subclass) async {
    // Always clear existing subclass entries first to avoid duplicates
    await _db.clearHeroEntryType(heroId, 'subclass');
    
    if (subclass == null || subclass.isEmpty) {
      // Also clear legacy hero_values
      await _db.upsertHeroValue(heroId: heroId, key: _k.subclass, textValue: '');
      return;
    }
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'class',
      sourceId: subclass,
      entryType: 'subclass',
      entryIds: [subclass],
      gainedBy: 'choice',
    );
    // Also save to legacy hero_values
    await _db.upsertHeroValue(heroId: heroId, key: _k.subclass, textValue: subclass);
  }

  /// Save the subclass key (used for matching the subclass option in the UI)
  Future<void> saveSubclassKey(String heroId, String? subclassKey) async {
    if (subclassKey == null) {
      await _db.deleteHeroConfig(heroId, 'strife.subclass_key');
      return;
    }
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'strife.subclass_key',
      value: {'key': subclassKey},
    );
  }

  /// Load the subclass key
  Future<String?> getSubclassKey(String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'strife.subclass_key');
    return config?['key']?.toString();
  }

  /// Save the skill granted by the subclass.
  /// When the subclass changes, this replaces the old skill with the new one.
  Future<void> saveSubclassSkill(String heroId, String? skillId) async {
    // Always call addEntriesFromSource - it will remove old entries first
    // If skillId is null/empty, this effectively removes the subclass skill
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'subclass',
      sourceId: 'subclass_skill',
      entryType: 'skill',
      entryIds: skillId != null && skillId.isNotEmpty ? [skillId] : [],
      gainedBy: 'grant',
    );
  }

  Future<void> updateDeity(String heroId, String? deityId) async {
    if (deityId == null || deityId.isEmpty) {
      await _db.clearHeroEntryType(heroId, 'deity');
      return;
    }
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'deity',
      sourceId: deityId,
      entryType: 'deity',
      entryIds: [deityId],
      gainedBy: 'choice',
    );
  }

  Future<void> updateDomain(String heroId, String? domainId) async {
    if (domainId == null || domainId.isEmpty) {
      await _db.clearHeroEntryType(heroId, 'domain');
      return;
    }
    final parts = domainId
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'domain',
      sourceId: 'domain_choice',
      entryType: 'domain',
      entryIds: parts,
      gainedBy: 'choice',
    );
  }

  Future<void> updateKit(String heroId, String? kitId) async {
    if (kitId == null || kitId.isEmpty) {
      await _db.clearHeroEntryType(heroId, 'kit');
      return;
    }
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'kit',
      sourceId: kitId,
      entryType: 'kit',
      entryIds: [kitId],
      gainedBy: 'choice',
    );
  }

  /// Save all equipment IDs (kits, augmentations, prayers, etc.)
  Future<void> saveEquipmentIds(
    String heroId,
    List<String?> equipmentIds,
  ) async {
    final ids = equipmentIds.whereType<String>().where((id) => id.isNotEmpty);
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'equipment',
      sourceId: 'equipment_slots',
      entryType: 'equipment',
      entryIds: ids,
      gainedBy: 'choice',
    );
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'equipment.slots',
      value: {'ids': equipmentIds},
    );

    // Also update legacy kit field for backwards compatibility
    final primaryKit = equipmentIds.firstWhereOrNull(
      (id) => id != null && id.isNotEmpty,
    );
    await updateKit(heroId, primaryKit);
  }

  /// Load equipment IDs
  Future<List<String?>> getEquipmentIds(String heroId) async {
    final slotConfig = await _db.getHeroConfigValue(heroId, 'equipment.slots');
    if (slotConfig != null && slotConfig['ids'] is List) {
      return (slotConfig['ids'] as List)
          .map((e) => e == null ? null : e.toString())
          .toList();
    }
    // Fall back to entries without slot ordering
    final entryIds = await _db.getHeroEntryIds(heroId, 'equipment');
    if (entryIds.isNotEmpty) return entryIds;

    final kitEntry = await _db.getSingleHeroEntryId(heroId, 'kit');
    if (kitEntry != null) return [kitEntry];
    return [];
  }

  /// Get all skill entries for a hero.
  Future<List<db.HeroEntry>> getSkillEntries(String heroId) async {
    return _entries.listEntriesByType(heroId, 'skill');
  }

  /// Save equipment bonuses that have been applied to the hero.
  /// Stores in hero_values as the source of truth. Legacy hero_entries are cleared.
  Future<void> saveEquipmentBonuses(
    String heroId, {
    required int staminaBonus,
    required int speedBonus,
    required int stabilityBonus,
    required int disengageBonus,
    required int meleeDamageBonus,
    required int rangedDamageBonus,
    required int meleeDistanceBonus,
    required int rangedDistanceBonus,
  }) async {
    // Clear legacy hero_entries to avoid double application
    await _db.clearHeroEntryType(heroId, 'equipment_bonuses');

    // Persist to hero_values (source of truth)
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'strife.equipment_bonuses',
      jsonMap: {
        'stamina': staminaBonus,
        'speed': speedBonus,
        'stability': stabilityBonus,
        'disengage': disengageBonus,
        'melee_damage': meleeDamageBonus,
        'ranged_damage': rangedDamageBonus,
        'melee_distance': meleeDistanceBonus,
        'ranged_distance': rangedDistanceBonus,
      },
    );
  }

  /// Load equipment bonuses from hero_entries (preferred) or legacy hero_values.
  Future<Map<String, int>> getEquipmentBonuses(String heroId) async {
    // Source of truth: hero_entries (new pattern)
    final entries = await _entries.listEntriesByType(heroId, 'equipment_bonuses');
    final bonusEntry = entries.firstWhereOrNull(
      (e) => e.entryId == 'combined_equipment_bonuses' && e.sourceType == 'kit',
    );
    if (bonusEntry?.payload != null) {
      try {
        final payload = jsonDecode(bonusEntry!.payload!);
        if (payload is Map) {
          return {
            'stamina': _toIntOrZero(payload['stamina']),
            'speed': _toIntOrZero(payload['speed']),
            'stability': _toIntOrZero(payload['stability']),
            'disengage': _toIntOrZero(payload['disengage']),
            'melee_damage': _toIntOrZero(payload['melee_damage']),
            'ranged_damage': _toIntOrZero(payload['ranged_damage']),
            'melee_distance': _toIntOrZero(payload['melee_distance']),
            'ranged_distance': _toIntOrZero(payload['ranged_distance']),
          };
        }
      } catch (_) {}
    }

    // Legacy fallback: hero_values (will be removed after migration)
    final values = await _db.getHeroValues(heroId);
    final parsed = _parseEquipmentBonuses(values);
    if (parsed.isNotEmpty) return parsed;
    
    return const {};
  }

  /// Load feature stat bonuses from hero_entries.
  /// Returns aggregated bonuses from all feature_stat_bonus entries.
  Future<Map<String, int>> getFeatureStatBonuses(String heroId) async {
    final bonuses = <String, int>{};

    // Source of truth: hero_values stored under strife.feature_stat_bonuses
    final values = await _db.getHeroValues(heroId);
    final hvRow = values.firstWhereOrNull((v) => v.key == 'strife.feature_stat_bonuses');
    final hvRaw = hvRow?.jsonValue ?? hvRow?.textValue;
    if (hvRaw != null && hvRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(hvRaw);
        if (decoded is Map) {
          for (final featureEntry in decoded.entries) {
            final payload = featureEntry.value;
            if (payload is! Map) continue;
            for (final bonusEntry in payload.entries) {
              final key = bonusEntry.key.toString();
              final value = bonusEntry.value;

              final statKey = switch (key) {
                'speed_bonus' => 'speed',
                'disengage_bonus' => 'disengage',
                'stability_bonus' => 'stability',
                'stamina_increase' => 'stamina',
                'recoveries_bonus' => 'recoveries',
                _ => key,
              };

              if (value is int) {
                bonuses[statKey] = (bonuses[statKey] ?? 0) + value;
              } else if (value is num) {
                bonuses[statKey] = (bonuses[statKey] ?? 0) + value.toInt();
              }
            }
          }
        }
      } catch (_) {}
    }

    if (bonuses.isNotEmpty) return bonuses;

    // Fallback to legacy hero_entries
    final entries = await _entries.listEntriesByType(heroId, 'feature_stat_bonus');
    for (final entry in entries) {
      if (entry.payload == null) continue;
      try {
        final payload = jsonDecode(entry.payload!);
        if (payload is! Map) continue;

        for (final bonusEntry in payload.entries) {
          final key = bonusEntry.key.toString();
          final value = bonusEntry.value;

          final statKey = switch (key) {
            'speed_bonus' => 'speed',
            'disengage_bonus' => 'disengage',
            'stability_bonus' => 'stability',
            'stamina_increase' => 'stamina',
            'recoveries_bonus' => 'recoveries',
            _ => key,
          };

          if (value is int) {
            bonuses[statKey] = (bonuses[statKey] ?? 0) + value;
          } else if (value is num) {
            bonuses[statKey] = (bonuses[statKey] ?? 0) + value.toInt();
          }
        }
      } catch (_) {}
    }

    return bonuses;
  }

  int _toIntOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ===========================================================================
  // CLEAR STRIFE DATA (for class change)
  // ===========================================================================

  /// Clears all strife-related data when changing to a different class.
  /// This removes class, subclass, deity, domain, equipment, abilities (from strife),
  /// skills (from strife), perks (from strife), and all strife config values.
  /// Story-sourced data (ancestry, career, complication) is preserved.
  Future<void> clearStrifeData(String heroId) async {
    // Clear hero_entries for strife-related entry types
    await _db.clearHeroEntryType(heroId, 'class');
    await _db.clearHeroEntryType(heroId, 'subclass');
    await _db.clearHeroEntryType(heroId, 'deity');
    await _db.clearHeroEntryType(heroId, 'domain');
    await _db.clearHeroEntryType(heroId, 'kit');
    await _db.clearHeroEntryType(heroId, 'equipment');
    await _db.clearHeroEntryType(heroId, 'equipment_bonuses');

    // Clear abilities - these are managed by strife only
    await _db.clearHeroEntryType(heroId, 'ability');

    // Clear skills and perks from strife source only (preserve story-sourced ones)
    // We need to clear by source_type to preserve story-granted entries
    await _clearEntriesBySource(heroId, 'skill', 'manual_choice');
    await _clearEntriesBySource(heroId, 'skill', 'subclass');
    await _clearEntriesBySource(heroId, 'skill', 'class');
    await _clearEntriesBySource(heroId, 'perk', 'manual_choice');
    await _clearEntriesBySource(heroId, 'perk', 'class');

    // Clear all strife config keys
    await _db.deleteHeroConfig(heroId, 'strife.characteristic_array');
    await _db.deleteHeroConfig(heroId, 'strife.characteristic_assignments');
    await _db.deleteHeroConfig(heroId, 'strife.level_choice_selections');
    await _db.deleteHeroConfig(heroId, 'strife.class_feature_selections');
    await _db.deleteHeroConfig(heroId, 'strife.subclass_key');
    await _db.deleteHeroConfig(heroId, 'strife.subclass_skill_id');
    await _db.deleteHeroConfig(heroId, 'strife.ability_selections');
    await _db.deleteHeroConfig(heroId, 'strife.skill_selections');
    await _db.deleteHeroConfig(heroId, 'strife.perk_selections');

    // Clear equipment config
    await _db.deleteHeroConfig(heroId, 'equipment.slots');
    await _db.deleteHeroConfig(heroId, 'class_feature.selections');

    // Clear legacy hero_values for subclass
    await _db.upsertHeroValue(heroId: heroId, key: _k.subclass, textValue: '');
  }

  /// Helper to clear entries by source type (preserves entries from other sources)
  Future<void> _clearEntriesBySource(
    String heroId,
    String entryType,
    String sourceType,
  ) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      entryType: entryType,
      sourceType: sourceType,
    );
  }

  // ===========================================================================
  // FAVORITE KITS
  // ===========================================================================

  /// Save favorite kit IDs for quick swapping
  Future<void> saveFavoriteKitIds(String heroId, List<String> kitIds) async {
    final nonEmpty = kitIds.where((id) => id.isNotEmpty).toList();
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'gear.favorite_kits',
      value: {'ids': nonEmpty},
    );
  }

  /// Load favorite kit IDs
  Future<List<String>> getFavoriteKitIds(String heroId) async {
    final config = await _db.getHeroConfigValue(heroId, 'gear.favorite_kits');
    if (config == null) return [];
    final ids = config['ids'];
    if (ids is List) return ids.map((e) => e.toString()).toList();
    return [];
  }

  // ===========================================================================
  // INVENTORY CONTAINERS
  // ===========================================================================

  /// Save inventory containers (folders with items)
  Future<void> saveInventoryContainers(
    String heroId,
    List<Map<String, dynamic>> containers,
  ) async {
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'gear.inventory_containers',
      value: {'containers': containers},
    );
  }

  /// Load inventory containers
  Future<List<Map<String, dynamic>>> getInventoryContainers(
      String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'gear.inventory_containers');
    if (config == null) return [];
    final containers = config['containers'];
    if (containers is List) {
      return containers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> updateCharacteristicArray(
    String heroId, {
    String? arrayName,
    List<int>? arrayValues,
  }) async {
    final payload = <String, dynamic>{};
    if (arrayName != null) payload['name'] = arrayName;
    if (arrayValues != null) payload['values'] = arrayValues;
    if (payload.isEmpty) return;
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'strife.characteristic_array',
      value: payload,
    );
  }

  Future<List<int>> getCharacteristicArrayValues(String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'strife.characteristic_array');
    final list = config?['values'];
    if (list is List) {
      return list.whereType<num>().map((e) => e.toInt()).toList();
    }
    return const [];
  }

  /// Save the user's characteristic assignment choices (which stat gets which value)
  Future<void> saveCharacteristicAssignments(
    String heroId,
    Map<String, int> assignments,
  ) async {
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'strife.characteristic_assignments',
      value: {'assignments': assignments},
    );
  }

  /// Load the user's characteristic assignment choices
  Future<Map<String, int>> getCharacteristicAssignments(String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'strife.characteristic_assignments');
    final map = config?['assignments'];
    if (map is Map) {
      return map.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {};
  }

  /// Save the user's level choice selections (which characteristic to boost at each level)
  Future<void> saveLevelChoiceSelections(
    String heroId,
    Map<String, String?> selections,
  ) async {
    // Filter out null values for cleaner storage
    final nonNullSelections = <String, String>{};
    selections.forEach((key, value) {
      if (value != null) {
        nonNullSelections[key] = value;
      }
    });
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'strife.level_choice_selections',
      value: nonNullSelections,
    );
  }

  /// Load the user's level choice selections
  Future<Map<String, String?>> getLevelChoiceSelections(String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'strife.level_choice_selections');
    if (config == null) return {};
    return config.map((k, v) => MapEntry(k.toString(), v?.toString()));
  }

  /// Save class feature selections to hero_config.
  /// This stores selections in both the legacy key and new key for compatibility.
  Future<void> saveFeatureSelections(
    String heroId,
    Map<String, Set<String>> selections,
  ) async {
    final jsonMap = <String, dynamic>{
      for (final entry in selections.entries)
        entry.key: entry.value.toList(),
    };
    // Save to both legacy key and new key for compatibility
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'strife.class_feature_selections',
      value: jsonMap,
    );
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'class_feature.selections',
      value: jsonMap,
    );
  }

  /// Load class feature selections from hero_config.
  /// Checks both the new and legacy keys.
  Future<Map<String, Set<String>>> getFeatureSelections(String heroId) async {
    // Try new key first, fall back to legacy key
    var config = await _db.getHeroConfigValue(heroId, 'class_feature.selections');
    config ??= await _db.getHeroConfigValue(heroId, 'strife.class_feature_selections');
    if (config == null) return const {};
    final result = <String, Set<String>>{};
    config.forEach((key, value) {
      final normalizedKey = key.toString().trim();
      if (normalizedKey.isEmpty) return;
      if (value is List) {
        final set = value
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
        if (set.isNotEmpty) result[normalizedKey] = set;
      } else if (value is String && value.trim().isNotEmpty) {
        result[normalizedKey] = {value.trim()};
      }
    });
    return result;
  }

  Future<void> updateCoreStats(
    String heroId, {
    int? speed,
    int? stability,
    int? disengage,
    String? size,
  }) async {
    Future<void> setInt(String key, int? value) async {
      if (value == null) return;
      await _db.upsertHeroValue(heroId: heroId, key: key, value: value);
    }

    await Future.wait([
      setInt(_k.speed, speed),
      setInt(_k.stability, stability),
      setInt(_k.disengage, disengage),
      if (size != null)
        _db.upsertHeroValue(heroId: heroId, key: _k.size, textValue: size),
    ]);
  }

  Future<void> updateRecoveryValue(String heroId, int value) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _k.recoveriesValue,
      value: value,
    );
  }

  Future<void> updateSaveEnds(String heroId, int value) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _k.saveEnds,
      value: value,
    );
  }

  Future<void> updatePotencies(
    String heroId, {
    String? strong,
    String? average,
    String? weak,
  }) async {
    Future<void> setText(String key, String? value) async {
      if (value == null) return;
      await _db.upsertHeroValue(heroId: heroId, key: key, textValue: value);
    }

    await Future.wait([
      setText(_k.potencyStrong, strong),
      setText(_k.potencyAverage, average),
      setText(_k.potencyWeak, weak),
    ]);
  }

  Future<void> setCharacteristicBase(
    String heroId, {
    required String characteristic,
    required int value,
  }) async {
    String key;
    switch (characteristic.toLowerCase()) {
      case 'might':
        key = _k.might;
        break;
      case 'agility':
        key = _k.agility;
        break;
      case 'reason':
        key = _k.reason;
        break;
      case 'intuition':
        key = _k.intuition;
        break;
      case 'presence':
        key = _k.presence;
        break;
      default:
        throw ArgumentError('Unknown characteristic: $characteristic');
    }

    await _db.upsertHeroValue(
      heroId: heroId,
      key: key,
      value: value,
    );
  }

  HeroMainStats _mapValuesToMainStats(List<db.HeroValue> values) {
    int readInt(String key, {int defaultValue = 0}) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v == null) return defaultValue;
      return v.value ?? int.tryParse(v.textValue ?? '') ?? defaultValue;
    }

    String? readText(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      return v?.textValue;
    }

    final equipmentBonuses = _parseEquipmentBonuses(values);
    final userModifications = _extractUserModifications(values);
    final choiceModifications =
        _extractChoiceModifications(values, equipmentBonuses);
    final modifications =
        _combineModificationMaps(choiceModifications, userModifications);

    final classId = readText(_k.className);

    return HeroMainStats(
      victories: readInt(_k.victories),
      exp: readInt(_k.exp),
      level: readInt(_k.level, defaultValue: 1),
      wealthBase: readInt(_k.wealth),
      renownBase: readInt(_k.renown),
      mightBase: readInt(_k.might),
      agilityBase: readInt(_k.agility),
      reasonBase: readInt(_k.reason),
      intuitionBase: readInt(_k.intuition),
      presenceBase: readInt(_k.presence),
      sizeBase: readText(_k.size) ?? '1M',
      speedBase: readInt(_k.speed),
      disengageBase: readInt(_k.disengage),
      stabilityBase: readInt(_k.stability),
      staminaCurrent: readInt(_k.staminaCurrent),
      staminaMaxBase: readInt(_k.staminaMax),
      staminaTemp: readInt(_k.staminaTemp),
      recoveriesCurrent: readInt(_k.recoveriesCurrent),
      recoveriesMaxBase: readInt(_k.recoveriesMax),
      recoveryValueBonus: readInt('complication.recovery_bonus'),
      surgesCurrent: readInt(_k.surgesCurrent),
      classId: classId,
      heroicResourceName: readText(_k.heroicResource),
      heroicResourceCurrent: readInt(_k.heroicResourceCurrent),
      modifications: modifications,
      userModifications: userModifications,
      choiceModifications: choiceModifications,
      equipmentBonuses: equipmentBonuses,
      dynamicModifiers: DynamicModifierList.fromJsonString(
        readText('dynamic_modifiers'),
      ),
    );
  }

  Map<String, int> _extractUserModifications(List<db.HeroValue> values) {
    final map = <String, int>{};

    // Read from regular modifications (mods.map)
    final modsEntry = values.firstWhereOrNull((e) => e.key == _k.modifications);
    if (modsEntry != null) {
      final raw = modsEntry.jsonValue ?? modsEntry.textValue;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            decoded.forEach((key, value) {
              final parsed = _toInt(value) ?? 0;
              if (parsed != 0) {
                map[key.toString()] = parsed;
              }
            });
          }
        } catch (_) {}
      }
    }
    return map.isEmpty ? const {} : Map.unmodifiable(map);
  }

  Map<String, int> _extractChoiceModifications(
    List<db.HeroValue> values,
    Map<String, int> equipmentBonuses,
  ) {
    final map = <String, int>{};

    void merge(Map<String, int> source) {
      source.forEach((key, value) {
        if (value == 0) return;
        map[key] = (map[key] ?? 0) + value;
      });
    }

    // Merge ancestry and complication stat mods (with sources)
    final ancestryModsEntry =
        values.firstWhereOrNull((e) => e.key == 'ancestry.stat_mods');
    final complicationModsEntry =
        values.firstWhereOrNull((e) => e.key == 'complication.stat_mods');

    merge(_parseStatModifications(ancestryModsEntry));
    merge(_parseStatModifications(complicationModsEntry));

    // Merge equipment bonuses as choice mods
    if (equipmentBonuses.isNotEmpty) {
      merge(_equipmentModsFromBonuses(equipmentBonuses));
    }

    return map.isEmpty ? const {} : Map.unmodifiable(map);
  }

  Map<String, int> _parseStatModifications(db.HeroValue? entry) {
    if (entry == null) return const {};
    final raw = entry.jsonValue ?? entry.textValue;
    if (raw == null || raw.isEmpty) return const {};

    try {
      final mods = HeroStatModifications.fromJsonString(raw);
      final totals = <String, int>{};
      for (final entry in mods.modifications.entries) {
        final modKey = _ancestryStatToModKey(entry.key);
        if (modKey == null) continue;
        final total = entry.value.fold<int>(0, (sum, mod) => sum + mod.baseValue);
        if (total != 0) {
          totals[modKey] = (totals[modKey] ?? 0) + total;
        }
      }
      return totals;
    } catch (_) {
      return const {};
    }
  }

  Map<String, int> _equipmentModsFromBonuses(Map<String, int> bonuses) {
    final map = <String, int>{};
    void add(String key, int? value) {
      if (value == null || value == 0) return;
      map[key] = value;
    }

    add(HeroModKeys.staminaMax, bonuses['stamina']);
    add(HeroModKeys.speed, bonuses['speed']);
    add(HeroModKeys.stability, bonuses['stability']);
    add(HeroModKeys.disengage, bonuses['disengage']);

    return map;
  }

  Map<String, int> _combineModificationMaps(
    Map<String, int> choiceMods,
    Map<String, int> userMods,
  ) {
    if (choiceMods.isEmpty && userMods.isEmpty) return const {};
    final result = <String, int>{};
    void merge(Map<String, int> source) {
      source.forEach((key, value) {
        if (value == 0) return;
        result[key] = (result[key] ?? 0) + value;
      });
    }

    merge(choiceMods);
    merge(userMods);
    return Map.unmodifiable(result);
  }

  Map<String, int> _parseEquipmentBonuses(List<db.HeroValue> values) {
    final row =
        values.firstWhereOrNull((v) => v.key == 'strife.equipment_bonuses');
    final raw = row?.jsonValue ?? row?.textValue;
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return const {};
    }
  }

  /// Maps ancestry stat names to HeroModKeys.
  String? _ancestryStatToModKey(String stat) {
    final normalized = stat.toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'might' => HeroModKeys.might,
      'agility' => HeroModKeys.agility,
      'reason' => HeroModKeys.reason,
      'intuition' => HeroModKeys.intuition,
      'presence' => HeroModKeys.presence,
      'size' => HeroModKeys.size,
      'speed' => HeroModKeys.speed,
      'disengage' => HeroModKeys.disengage,
      'stability' => HeroModKeys.stability,
      'stamina' => HeroModKeys.staminaMax,
      'recoveries' => HeroModKeys.recoveriesMax,
      'surges' => HeroModKeys.surges,
      'wealth' => HeroModKeys.wealth,
      'renown' => HeroModKeys.renown,
      _ => null,
    };
  }

  int? _toInt(dynamic value) {
    return switch (value) {
      int v => v,
      double d => d.round(),
      String s => int.tryParse(s),
      _ => null,
    };
  }

  // Lightweight projection for list screens
  // Watches both heroes table and hero_values table for changes
  Stream<List<HeroSummary>> watchSummaries() {
    // Create a combined stream that triggers on either heroes or hero_values changes
    final controller = StreamController<List<HeroSummary>>();
    
    StreamSubscription<List<db.Heroe>>? heroesSubscription;
    StreamSubscription<List<db.HeroValue>>? valuesSubscription;
    StreamSubscription<List<db.HeroEntry>>? entriesSubscription;

    // Prevent overlapping rebuilds when the DB is emitting many change events.
    var buildInFlight = false;
    var buildPending = false;

    const summaryEntryTypes = <String>[
      'class',
      'subclass',
      'ancestry',
      'career',
      'complication',
    ];

    Future<void> buildSummaries() async {
      if (buildInFlight) {
        buildPending = true;
        return;
      }
      buildInFlight = true;
      try {
        final heroes = await _db.getAllHeroes();
        if (heroes.isEmpty) {
          if (!controller.isClosed) {
            controller.add(const <HeroSummary>[]);
          }
          return;
        }

        // Fetch only the values needed for summaries.
        final values = await (_db.select(_db.heroValues)
              ..where((t) => t.key.isIn([_k.level, _k.heroicResource])))
            .get();

        // Fetch only the entry types needed for summaries.
        final entries = await (_db.select(_db.heroEntries)
              ..where((t) => t.entryType.isIn(summaryEntryTypes)))
            .get();

        // Build lookup maps for fast in-memory access.
        final valuesByHero = <String, Map<String, db.HeroValue>>{};
        for (final v in values) {
          final perHero = valuesByHero.putIfAbsent(v.heroId, () => {});
          final existing = perHero[v.key];
          if (existing == null || v.updatedAt.isAfter(existing.updatedAt)) {
            perHero[v.key] = v;
          }
        }

        final entriesByHeroType = <String, Map<String, db.HeroEntry>>{};
        final componentIds = <String>{};
        for (final e in entries) {
          componentIds.add(e.entryId);
          final perHero = entriesByHeroType.putIfAbsent(e.heroId, () => {});
          final existing = perHero[e.entryType];
          if (existing == null || e.updatedAt.isAfter(existing.updatedAt)) {
            perHero[e.entryType] = e;
          }
        }

        final components = componentIds.isEmpty
            ? const <db.Component>[]
            : await (_db.select(_db.components)
                  ..where((c) => c.id.isIn(componentIds.toList())))
                .get();

        final componentNameById = <String, String>{
          for (final c in components) c.id: c.name,
        };

        String? nameForComponentId(String? id) {
          if (id == null || id.isEmpty) return null;
          return componentNameById[id] ?? id;
        }

        final summaries = <HeroSummary>[];
        for (final h in heroes) {
          final heroValues = valuesByHero[h.id];
          final heroEntries = entriesByHeroType[h.id];

          final level = heroValues?[_k.level]?.value ?? 1;
          final heroicResource = heroValues?[_k.heroicResource]?.textValue;

          final classId = heroEntries?['class']?.entryId;
          final subclassId = heroEntries?['subclass']?.entryId;
          final ancestryId = heroEntries?['ancestry']?.entryId;
          final careerId = heroEntries?['career']?.entryId;
          final complicationId = heroEntries?['complication']?.entryId;

          summaries.add(HeroSummary(
            id: h.id,
            name: h.name,
            className: nameForComponentId(classId),
            subclassName: nameForComponentId(subclassId),
            level: level,
            ancestryName: nameForComponentId(ancestryId),
            careerName: nameForComponentId(careerId),
            complicationName: nameForComponentId(complicationId),
            heroicResourceName: heroicResource,
          ));
        }

        if (!controller.isClosed) {
          controller.add(summaries);
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      } finally {
        buildInFlight = false;
        if (buildPending) {
          buildPending = false;
          unawaited(buildSummaries());
        }
      }
    }

    controller.onListen = () {
      // Watch heroes table
      heroesSubscription = _db.watchAllHeroes().listen((_) {
        buildSummaries();
      });
      
      // Watch only the subset of hero_values used by the summaries.
      valuesSubscription = (_db.select(_db.heroValues)
            ..where((t) => t.key.isIn([_k.level, _k.heroicResource])))
          .watch()
          .listen((_) {
        buildSummaries();
      });

      // Watch only the entry categories used by the summaries.
      entriesSubscription = (_db.select(_db.heroEntries)
            ..where((t) => t.entryType.isIn(summaryEntryTypes)))
          .watch()
          .listen((_) {
        buildSummaries();
      });
      
      // Build initial summaries
      buildSummaries();
    };

    controller.onCancel = () {
      heroesSubscription?.cancel();
      valuesSubscription?.cancel();
      entriesSubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // --- Ancestry selections (traits) ---
  Future<void> saveAncestryTraits({
    required String heroId,
    required String? ancestryId,
    required List<String> selectedTraitIds,
  }) async {
    // Clear all previous ancestry entries (ancestry and traits) regardless of sourceId
    // This ensures we don't keep entries from the previous ancestry selection
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'ancestry',
    );

    if (ancestryId != null && ancestryId.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'ancestry',
        sourceId: ancestryId,
        entryType: 'ancestry',
        entryIds: [ancestryId],
        gainedBy: 'choice',
      );
    } else {
      await _db.clearHeroEntryType(heroId, 'ancestry');
    }
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'ancestry',
      sourceId: ancestryId ?? 'ancestry',
      entryType: 'ancestry_trait',
      entryIds: selectedTraitIds,
      gainedBy: 'choice',
    );
    // Persist signature trait name for convenience (redundant but requested)
    String? signatureName;
    if (ancestryId != null) {
      final all = await _db.getAllComponents();
      final traitsComp = all.firstWhereOrNull((c) {
        if (c.type != 'ancestry_trait') return false;
        try {
          final map = jsonDecode(c.dataJson) as Map<String, dynamic>;
          return map['ancestry_id'] == ancestryId;
        } catch (_) {
          return false;
        }
      });
      if (traitsComp != null) {
        try {
          final map = jsonDecode(traitsComp.dataJson) as Map<String, dynamic>;
          final sig = map['signature'];
          if (sig is Map && sig['name'] is String)
            signatureName = sig['name'] as String;
        } catch (_) {}
      }
    }
    if (signatureName != null) {
      await _db.setHeroConfig(
        heroId: heroId,
        configKey: 'ancestry.signature_name',
        value: {'name': signatureName},
      );
    } else {
      await _db.deleteHeroConfig(heroId, 'ancestry.signature_name');
    }
  }

  Future<List<String>> getSelectedAncestryTraits(String heroId) async {
    return _db.getHeroComponentIds(heroId, 'ancestry_trait');
  }

  /// Get the choices the hero has made for ancestry traits that require picking
  /// (e.g., immunity type for Wyrmplate, ability for Psionic Gift)
  Future<Map<String, String>> getAncestryTraitChoices(String heroId) async {
    final config =
        await _db.getHeroConfigValue(heroId, 'ancestry.trait_choices');
    if (config == null) return <String, String>{};
    return config.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Save the choices the hero has made for ancestry traits that require picking
  Future<void> saveAncestryTraitChoices(
    String heroId,
    Map<String, String> choices,
  ) async {
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: 'ancestry.trait_choices',
      value: choices,
    );
  }

  // --- Culture selections (environment, organisation, upbringing, languages) ---
  Future<void> saveCultureSelection({
    required String heroId,
    String? environmentId,
    String? organisationId,
    String? upbringingId,
    List<String> languageIds = const <String>[],
    String? environmentSkillId,
    String? organisationSkillId,
    String? upbringingSkillId,
  }) async {
    // Clear all previous culture entries before adding new ones
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'culture',
    );

    if (environmentId != null && environmentId.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'culture',
        sourceId: 'culture_environment',
        entryType: 'culture_environment',
        entryIds: [environmentId],
        gainedBy: 'choice',
      );
    }
    if (organisationId != null && organisationId.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'culture',
        sourceId: 'culture_organisation',
        entryType: 'culture_organisation',
        entryIds: [organisationId],
        gainedBy: 'choice',
      );
    }
    if (upbringingId != null && upbringingId.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'culture',
        sourceId: 'culture_upbringing',
        entryType: 'culture_upbringing',
        entryIds: [upbringingId],
        gainedBy: 'choice',
      );
    }
    // Languages
    if (languageIds.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'culture',
        sourceId: 'culture_languages',
        entryType: 'language',
        entryIds: languageIds,
        gainedBy: 'choice',
      );
    }

    // Persist chosen skill ids as HeroValues for traceability
    if (environmentSkillId != null) {
      await _db.setHeroConfig(
        heroId: heroId,
        configKey: _k.cultureEnvironmentSkill,
        value: {'selection': environmentSkillId},
      );
    }
    if (organisationSkillId != null) {
      await _db.setHeroConfig(
        heroId: heroId,
        configKey: _k.cultureOrganisationSkill,
        value: {'selection': organisationSkillId},
      );
    }
    if (upbringingSkillId != null) {
      await _db.setHeroConfig(
        heroId: heroId,
        configKey: _k.cultureUpbringingSkill,
        value: {'selection': upbringingSkillId},
      );
    }

    // Ensure selected skills are present among HeroComponents('skill') without removing others
    if (environmentSkillId != null && environmentSkillId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'skill',
        entryId: environmentSkillId,
        sourceType: 'culture',
        sourceId: 'culture_environment',
        gainedBy: 'choice',
      );
    }
    if (organisationSkillId != null && organisationSkillId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'skill',
        entryId: organisationSkillId,
        sourceType: 'culture',
        sourceId: 'culture_organisation',
        gainedBy: 'choice',
      );
    }
    if (upbringingSkillId != null && upbringingSkillId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'skill',
        entryId: upbringingSkillId,
        sourceType: 'culture',
        sourceId: 'culture_upbringing',
        gainedBy: 'choice',
      );
    }
  }

  Future<CultureSelection> loadCultureSelection(String heroId) async {
    final comps = await _db.getHeroComponents(heroId);
    String? idFor(String category) => comps
        .firstWhereOrNull((c) => c['category'] == category)?['componentId'];
    final envSkill =
        await _db.getHeroConfigValue(heroId, _k.cultureEnvironmentSkill);
    final orgSkill =
        await _db.getHeroConfigValue(heroId, _k.cultureOrganisationSkill);
    final upSkill =
        await _db.getHeroConfigValue(heroId, _k.cultureUpbringingSkill);
    return CultureSelection(
      environmentId: idFor('culture_environment'),
      organisationId: idFor('culture_organisation'),
      upbringingId: idFor('culture_upbringing'),
      environmentSkillId: envSkill?['selection']?.toString(),
      organisationSkillId: orgSkill?['selection']?.toString(),
      upbringingSkillId: upSkill?['selection']?.toString(),
    );
  }

  // --- Complication selection ---
  Future<void> saveComplication({
    required String heroId,
    String? complicationId,
  }) async {
    if (complicationId == null || complicationId.trim().isEmpty) {
      // Clear complication
      await _db.setHeroComponents(
        heroId: heroId,
        category: 'complication',
        componentIds: const <String>[],
      );
      return;
    }

    await _db.setHeroComponents(
      heroId: heroId,
      category: 'complication',
      componentIds: [complicationId],
    );
  }

  Future<String?> loadComplication(String heroId) async {
    final comps = await _db.getHeroComponents(heroId);
    return comps
        .firstWhereOrNull((c) => c['category'] == 'complication')?['componentId'];
  }

  // --- Career selections (career id, chosen skills/perks, incident) ---
  Future<void> saveCareerSelection({
    required String heroId,
    required String? careerId,
    List<String> chosenSkillIds = const <String>[],
    List<String> chosenPerkIds = const <String>[],
    String? incitingIncidentName,
  }) async {
    // Detect previous career to apply numeric grants only on change
    final previousCareerId =
        await _db.getSingleHeroEntryId(heroId, 'career');

    // Clear all previous career entries (career and granted skills) regardless of sourceId
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'career',
    );

    if (careerId != null && careerId.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'career',
        sourceId: careerId,
        entryType: 'career',
        entryIds: [careerId],
        gainedBy: 'choice',
      );
    } else {
      await _db.clearHeroEntryType(heroId, 'career');
    }

    final allComps = await _db.getAllComponents();
    // Resolve granted skills from career definition by name
    final careerComp = allComps.firstWhereOrNull((c) => c.id == careerId);
    final grantedSkillNames = <String>{};
    int renownGrant = 0, wealthGrant = 0, ppGrant = 0;
    if (careerComp != null) {
      try {
        final data = jsonDecode(careerComp.dataJson) as Map<String, dynamic>;
        for (final s
            in (data['granted_skills'] as List?) ?? const <dynamic>[]) {
          grantedSkillNames.add(s.toString());
        }
        renownGrant = (data['renown'] as int?) ?? 0;
        wealthGrant = (data['wealth'] as int?) ?? 0;
        ppGrant = (data['project_points'] as int?) ?? 0;
      } catch (_) {}
    }
    final grantedSkillIds = allComps
        .where((c) =>
            c.type == 'skill' &&
            (grantedSkillNames.contains(c.name) ||
                grantedSkillNames.contains(c.id)))
        .map((c) => c.id)
        .toSet();

    // Merge skills and perks into HeroComponents, preserving existing
    final currentComps = await _db.getHeroComponents(heroId);
    // ignore: unused_local_variable
    final existingSkillIds = currentComps
        .where((c) => c['category'] == 'skill')
        .map((c) => c['componentId']!)
        .toSet();
    // ignore: unused_local_variable
    final existingPerkIds = currentComps
        .where((c) => c['category'] == 'perk')
        .map((c) => c['componentId']!)
        .toSet();
    // Grants vs choices
    if (grantedSkillIds.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'career',
        sourceId: careerId ?? 'career',
        entryType: 'skill',
        entryIds: grantedSkillIds,
        gainedBy: 'grant',
      );
    }

    if (chosenSkillIds.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'career',
        sourceId: 'career_choice',
        entryType: 'skill',
        entryIds: chosenSkillIds,
        gainedBy: 'choice',
      );
    }

    if (chosenPerkIds.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'career',
        sourceId: 'career_choice',
        entryType: 'perk',
        entryIds: chosenPerkIds,
        gainedBy: 'choice',
      );
    }

    // Persist chosen lists for preloading UI
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: _k.careerChosenSkills,
      value: {'list': chosenSkillIds},
    );
    await _db.setHeroConfig(
      heroId: heroId,
      configKey: _k.careerChosenPerks,
      value: {'list': chosenPerkIds},
    );
    if (incitingIncidentName != null) {
      await _db.setHeroConfig(
        heroId: heroId,
        configKey: _k.careerIncitingIncident,
        value: {'name': incitingIncidentName},
      );
    } else {
      await _db.deleteHeroConfig(heroId, _k.careerIncitingIncident);
    }

    // Apply numeric grants only when career changed
    if (careerId != null &&
        careerId.isNotEmpty &&
        previousCareerId != careerId) {
      final values = await _db.getHeroValues(heroId);
      int getInt(String key) =>
          values.firstWhereOrNull((v) => v.key == key)?.value ?? 0;
      final newRenown = getInt(_k.renown) + renownGrant;
      final newWealth = getInt(_k.wealth) + wealthGrant;
      final newPP = getInt(_k.projectPoints) + ppGrant;
      await _db.upsertHeroValue(
          heroId: heroId, key: _k.renown, value: newRenown);
      await _db.upsertHeroValue(
          heroId: heroId, key: _k.wealth, value: newWealth);
      await _db.upsertHeroValue(
          heroId: heroId, key: _k.projectPoints, value: newPP);
    }
  }

  Future<CareerSelection> loadCareerSelection(String heroId) async {
    final comps = await _db.getHeroComponents(heroId);
    final chosenSkills =
        await _db.getHeroConfigValue(heroId, _k.careerChosenSkills);
    final chosenPerks =
        await _db.getHeroConfigValue(heroId, _k.careerChosenPerks);
    final incident =
        await _db.getHeroConfigValue(heroId, _k.careerIncitingIncident);

    String? idForCategory(String category) => comps
        .firstWhereOrNull((e) => e['category'] == category)?['componentId'];

    return CareerSelection(
      careerId: idForCategory('career'),
      chosenSkillIds: (chosenSkills?['list'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      chosenPerkIds: (chosenPerks?['list'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      incitingIncidentName: incident?['name']?.toString(),
    );
  }

  /// Load a HeroModel by id from DB aggregating values and components.
  Future<HeroModel?> load(String heroId) async {
    final row = await (_db.select(_db.heroes)
          ..where((t) => t.id.equals(heroId)))
        .getSingleOrNull();
    if (row == null) return null;
    final values = await _db.getHeroValues(heroId);
    final comps = await _db.getHeroComponents(heroId);
    final classId = await _db.getSingleHeroEntryId(heroId, 'class');
    final subclassId = await _db.getSingleHeroEntryId(heroId, 'subclass');
    final ancestryId = await _db.getSingleHeroEntryId(heroId, 'ancestry');
    final careerId = await _db.getSingleHeroEntryId(heroId, 'career');
    final deityId = await _db.getSingleHeroEntryId(heroId, 'deity');
    final domains = await _db.getHeroEntryIds(heroId, 'domain');

    int getInt(String key, int def) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v == null) return def;
      return v.value ?? int.tryParse(v.textValue ?? '') ?? def;
    }

    String? getString(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      return v?.textValue;
    }

    List<String> jsonList(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v?.jsonValue == null && v?.textValue == null) return <String>[];
      try {
        final raw = v!.jsonValue ?? v.textValue!;
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map && decoded['list'] is List) {
          return (decoded['list'] as List).map((e) => e.toString()).toList();
        }
        return <String>[];
      } catch (_) {
        return <String>[];
      }
    }

    Map<String, int> jsonMapInt(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v?.jsonValue == null) return <String, int>{};
      try {
        final map = jsonDecode(v!.jsonValue!) as Map<String, dynamic>;
        return map.map((k, v) =>
            MapEntry(k, (v is int) ? v : int.tryParse(v.toString()) ?? 0));
      } catch (_) {
        return <String, int>{};
      }
    }

    // Collect components by category
    List<String> compsBy(String category) => comps
        .where((e) => e['category'] == category)
        .map((e) => e['componentId']!)
        .toList();

    return HeroModel(
      id: row.id,
      name: row.name,
      className: classId,
      subclass: subclassId,
      level: getInt(_k.level, 1),
      ancestry: ancestryId,
      career: careerId,
      deityId: deityId,
      domain: domains.join(','),
      victories: getInt(_k.victories, 0),
      exp: getInt(_k.exp, 0),
      wealth: getInt(_k.wealth, 0),
      renown: getInt(_k.renown, 0),
      might: getInt(_k.might, 0),
      agility: getInt(_k.agility, 0),
      reason: getInt(_k.reason, 0),
      intuition: getInt(_k.intuition, 0),
      presence: getInt(_k.presence, 0),
      size: getInt(_k.size, 0),
      speed: getInt(_k.speed, 0),
      disengage: getInt(_k.disengage, 0),
      stability: getInt(_k.stability, 0),
      staminaCurrent: getInt(_k.staminaCurrent, 0),
      staminaMax: getInt(_k.staminaMax, 0),
      staminaTemp: getInt(_k.staminaTemp, 0),
      windedValue: getInt(_k.windedValue, 0),
      dyingValue: getInt(_k.dyingValue, 0),
      recoveriesCurrent: getInt(_k.recoveriesCurrent, 0),
      recoveriesValue: getInt(_k.recoveriesValue, 0),
      recoveriesMax: getInt(_k.recoveriesMax, 0),
      heroicResource: getString(_k.heroicResource),
      heroicResourceCurrent: getInt(_k.heroicResourceCurrent, 0),
      surgesCurrent: getInt(_k.surgesCurrent, 0),
      immunities: jsonList(_k.immunities),
      weaknesses: jsonList(_k.weaknesses),
      potencyStrong: getString(_k.potencyStrong),
      potencyAverage: getString(_k.potencyAverage),
      potencyWeak: getString(_k.potencyWeak),
      conditions: jsonList(_k.conditions),
      classFeatures: compsBy('class_feature'),
      ancestryTraits: compsBy('ancestry_trait'),
      languages: compsBy('language'),
      skills: compsBy('skill'),
      perks: compsBy('perk'),
      projects: compsBy('project'),
      projectPoints: getInt(_k.projectPoints, 0),
      titles: compsBy('title'),
      abilities: compsBy('ability'),
      modifications: jsonMapInt(_k.modifications),
    );
  }

  /// Persist editable properties of a HeroModel back to DB.
  Future<void> save(HeroModel hero) async {
    await _db.renameHero(hero.id, hero.name);

    // Values (simple keys)
    Future<void> setInt(String key, int value) =>
        _db.upsertHeroValue(heroId: hero.id, key: key, value: value);
    Future<void> setText(String key, String? value) async {
      if (key == _k.className) {
        await updateClassName(hero.id, value);
        return;
      }
      if (key == _k.subclass) {
        await updateSubclass(hero.id, value);
        return;
      }
      if (key == _k.ancestry) {
        if (value == null || value.isEmpty) {
          await _db.clearHeroEntryType(hero.id, 'ancestry');
        } else {
          await _db.setSingleHeroEntry(
            heroId: hero.id,
            entryType: 'ancestry',
            entryId: value,
            sourceType: 'manual_choice',
            gainedBy: 'choice',
          );
        }
        return;
      }
      if (key == _k.career) {
        if (value == null || value.isEmpty) {
          await _db.clearHeroEntryType(hero.id, 'career');
        } else {
          await _db.setSingleHeroEntry(
            heroId: hero.id,
            entryType: 'career',
            entryId: value,
            sourceType: 'manual_choice',
            gainedBy: 'choice',
          );
        }
        return;
      }
      if (key == _k.kit) {
        await updateKit(hero.id, value);
        return;
      }
      if (key == _k.deity) {
        await updateDeity(hero.id, value);
        return;
      }
      if (key == _k.domain) {
        await updateDomain(hero.id, value);
        return;
      }
      await _db.upsertHeroValue(heroId: hero.id, key: key, textValue: value);
    }
    Future<void> setJsonMap(String key, Map<String, dynamic>? map) =>
        _db.upsertHeroValue(heroId: hero.id, key: key, jsonMap: map);

    await Future.wait([
      // basics
      setText(_k.className, hero.className),
      setText(_k.subclass, hero.subclass),
      setInt(_k.level, hero.level),
      setText(_k.ancestry, hero.ancestry),
      setText(_k.career, hero.career),
      setText(_k.deity, hero.deityId),
      setText(_k.domain, hero.domain),
      // victories & exp
      setInt(_k.victories, hero.victories),
      setInt(_k.exp, hero.exp),
      setInt(_k.wealth, hero.wealth),
      setInt(_k.renown, hero.renown),
      // stats
      setInt(_k.might, hero.might),
      setInt(_k.agility, hero.agility),
      setInt(_k.reason, hero.reason),
      setInt(_k.intuition, hero.intuition),
      setInt(_k.presence, hero.presence),
      setInt(_k.size, hero.size),
      setInt(_k.speed, hero.speed),
      setInt(_k.disengage, hero.disengage),
      setInt(_k.stability, hero.stability),
      // stamina
      setInt(_k.staminaCurrent, hero.staminaCurrent),
      setInt(_k.staminaMax, hero.staminaMax),
      setInt(_k.staminaTemp, hero.staminaTemp),
      setInt(_k.windedValue, hero.windedValue),
      setInt(_k.dyingValue, hero.dyingValue),
      setInt(_k.recoveriesCurrent, hero.recoveriesCurrent),
      setInt(_k.recoveriesValue, hero.recoveriesValue),
      setInt(_k.recoveriesMax, hero.recoveriesMax),
      // hero resource
      setText(_k.heroicResource, hero.heroicResource),
      setInt(_k.heroicResourceCurrent, hero.heroicResourceCurrent),
      // surges
      setInt(_k.surgesCurrent, hero.surgesCurrent),
      // arrays
      setJsonMap(_k.immunities, {'list': hero.immunities}),
      setJsonMap(_k.weaknesses, {'list': hero.weaknesses}),
      setJsonMap(_k.conditions, {'list': hero.conditions}),
      // potencies
      setText(_k.potencyStrong, hero.potencyStrong),
      setText(_k.potencyAverage, hero.potencyAverage),
      setText(_k.potencyWeak, hero.potencyWeak),
      // projects meta
      setInt(_k.projectPoints, hero.projectPoints),
      // modifications map
      setJsonMap(
          _k.modifications, hero.modifications.map((k, v) => MapEntry(k, v))),
    ]);

    // NOTE: Components (abilities, skills, languages, perks, ancestry_traits,
    // class_features, titles) are NOT saved here because they are managed by
    // specific grant services and creators:
    // - abilities: complication_grants, ancestry_bonus, class_feature_grants,
    //              kit_grants, strife_creator
    // - skills: complication_grants, subclass, career, culture, strife_creator
    // - languages: complication_grants, ancestry, culture
    // - perks: complication_grants, strife_creator
    // - ancestry_traits: story_creator via saveAncestryTraits()
    // - class_features: strife_creator
    // - titles: title grants service
    //
    // Saving them here would cause stale data from the HeroModel to overwrite
    // properly sourced entries with incorrect 'manual_choice' source.
    //
    // Only 'project' is saved here as it's purely user-managed.
    await _db.setHeroComponents(
        heroId: hero.id, category: 'project', componentIds: hero.projects);
  }

  /// Export a hero aggregate to a portable JSON string.
  Future<String?> exportHero(String heroId) async {
    final model = await load(heroId);
    if (model == null) return null;
    return model.toExportString();
  }

  /// Import a hero from export JSON, creating a new hero id.
  Future<String> importHero(String exportJsonString) async {
    final map = jsonDecode(exportJsonString) as Map<String, dynamic>;
    final model = HeroModel.fromExportJson(map);
    final newId = await createHero(
        name: model.name.isEmpty ? 'Imported Hero' : model.name);
    final toSave = model..name = model.name; // keep same name
    // rebind id
    final rebound = HeroModel(
      id: newId,
      name: toSave.name,
      className: toSave.className,
      subclass: toSave.subclass,
      level: toSave.level,
      ancestry: toSave.ancestry,
      career: toSave.career,
      deityId: toSave.deityId,
      domain: toSave.domain,
      victories: toSave.victories,
      exp: toSave.exp,
      wealth: toSave.wealth,
      renown: toSave.renown,
      might: toSave.might,
      agility: toSave.agility,
      reason: toSave.reason,
      intuition: toSave.intuition,
      presence: toSave.presence,
      size: toSave.size,
      speed: toSave.speed,
      disengage: toSave.disengage,
      stability: toSave.stability,
      staminaCurrent: toSave.staminaCurrent,
      staminaMax: toSave.staminaMax,
      staminaTemp: toSave.staminaTemp,
      windedValue: toSave.windedValue,
      dyingValue: toSave.dyingValue,
      recoveriesCurrent: toSave.recoveriesCurrent,
      recoveriesValue: toSave.recoveriesValue,
      recoveriesMax: toSave.recoveriesMax,
      heroicResource: toSave.heroicResource,
      heroicResourceCurrent: toSave.heroicResourceCurrent,
      surgesCurrent: toSave.surgesCurrent,
      immunities: List.of(toSave.immunities),
      weaknesses: List.of(toSave.weaknesses),
      potencyStrong: toSave.potencyStrong,
      potencyAverage: toSave.potencyAverage,
      potencyWeak: toSave.potencyWeak,
      conditions: List.of(toSave.conditions),
      classFeatures: List.of(toSave.classFeatures),
      ancestryTraits: List.of(toSave.ancestryTraits),
      languages: List.of(toSave.languages),
      skills: List.of(toSave.skills),
      perks: List.of(toSave.perks),
      projects: List.of(toSave.projects),
      projectPoints: toSave.projectPoints,
      titles: List.of(toSave.titles),
      abilities: List.of(toSave.abilities),
      modifications: Map.of(toSave.modifications),
    );
    await save(rebound);
    return newId;
  }
}

class CultureSelection {
  final String? environmentId;
  final String? organisationId;
  final String? upbringingId;
  final String? environmentSkillId;
  final String? organisationSkillId;
  final String? upbringingSkillId;
  const CultureSelection({
    this.environmentId,
    this.organisationId,
    this.upbringingId,
    this.environmentSkillId,
    this.organisationSkillId,
    this.upbringingSkillId,
  });
}

class CareerSelection {
  final String? careerId;
  final List<String> chosenSkillIds;
  final List<String> chosenPerkIds;
  final String? incitingIncidentName;
  const CareerSelection({
    this.careerId,
    this.chosenSkillIds = const <String>[],
    this.chosenPerkIds = const <String>[],
    this.incitingIncidentName,
  });
}

/// Centralized list of keys used in HeroValues
class _HeroKeys {
  const _HeroKeys._();
  final String className = 'basics.className';
  final String subclass = 'basics.subclass';
  final String level = 'basics.level';
  final String ancestry = 'basics.ancestry';
  final String career = 'basics.career';
  final String kit = 'basics.kit';
  final String deity = 'faith.deity';
  final String domain = 'faith.domain';
  // ancestry extras
  final String ancestrySelectedTraits = 'ancestry.selected_traits';
  final String ancestrySignature = 'ancestry.signature_name';
  final String ancestryTraitChoices = 'ancestry.trait_choices';
  // ancestry bonuses (managed by AncestryBonusService)
  final String ancestryAppliedBonuses = 'ancestry.applied_bonuses';
  final String ancestryStatMods = 'ancestry.stat_mods';
  final String ancestryConditionImmunities = 'ancestry.condition_immunities';
  final String ancestryGrantedAbilities = 'ancestry.granted_abilities';
  // damage resistances
  final String damageResistances = 'resistances.damage';

  final String victories = 'score.victories';
  final String exp = 'score.exp';
  final String wealth = 'score.wealth';
  final String renown = 'score.renown';
  final String coinPurse = 'score.coin_purse';

  final String might = 'stats.might';
  final String agility = 'stats.agility';
  final String reason = 'stats.reason';
  final String intuition = 'stats.intuition';
  final String presence = 'stats.presence';
  final String size = 'stats.size';
  final String speed = 'stats.speed';
  final String disengage = 'stats.disengage';
  final String stability = 'stats.stability';

  final String staminaCurrent = 'stamina.current';
  final String staminaMax = 'stamina.max';
  final String staminaTemp = 'stamina.temp';
  final String windedValue = 'stamina.winded';
  final String dyingValue = 'stamina.dying';
  final String recoveriesCurrent = 'recoveries.current';
  final String recoveriesValue = 'recoveries.value';
  final String recoveriesMax = 'recoveries.max';

  final String heroicResource = 'heroic.resource';
  final String heroicResourceCurrent = 'heroic.current';

  final String surgesCurrent = 'surges.current';

  final String heroTokensCurrent = 'heroTokens.current';

  final String immunities = 'resistances.immunities';
  final String weaknesses = 'resistances.weaknesses';

  final String potencyStrong = 'potency.strong';
  final String potencyAverage = 'potency.average';
  final String potencyWeak = 'potency.weak';

  final String conditions = 'conditions.list';
  final String saveEnds = 'conditions.save_ends';

  final String projectPoints = 'projects.points';

  final String modifications = 'mods.map';

  // culture-chosen skill keys
  final String cultureEnvironmentSkill = 'culture.environment.skill';
  final String cultureOrganisationSkill = 'culture.organisation.skill';
  final String cultureUpbringingSkill = 'culture.upbringing.skill';

  // career selections
  final String careerChosenSkills = 'career.chosen_skills';
  final String careerChosenPerks = 'career.chosen_perks';
  final String careerIncitingIncident = 'career.inciting_incident';
}
