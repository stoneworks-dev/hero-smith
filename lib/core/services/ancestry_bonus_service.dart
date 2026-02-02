import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart' as db;
import '../db/providers.dart';
import '../models/ancestry_bonus_models.dart';
import '../models/damage_resistance_model.dart';
import '../models/stat_modification_model.dart';
import '../repositories/hero_entry_repository.dart';
import 'damage_resistance_service.dart';

/// Service for managing ancestry trait bonuses.
/// Handles parsing traits, applying bonuses to heroes, and removing them when traits change.
class AncestryBonusService {
  AncestryBonusService(this._db) : _resistanceService = DamageResistanceService(_db);

  final db.AppDatabase _db;
  late final HeroEntryRepository _entries = HeroEntryRepository(_db);
  final DamageResistanceService _resistanceService;

  /// Parse all bonuses from an ancestry's signature and selected traits.
  Future<AppliedAncestryBonuses> parseAncestryBonuses({
    required String? ancestryId,
    required List<String> selectedTraitIds,
    Map<String, String> traitChoices = const {},
  }) async {
    if (ancestryId == null || ancestryId.isEmpty) {
      return AppliedAncestryBonuses.empty;
    }

    final allComponents = await _db.getAllComponents();
    
    // Find the ancestry_trait component for this ancestry
    final traitsComp = allComponents.firstWhereOrNull((c) {
      if (c.type != 'ancestry_trait') return false;
      try {
        final data = jsonDecode(c.dataJson) as Map<String, dynamic>;
        return data['ancestry_id'] == ancestryId;
      } catch (_) {
        return false;
      }
    });

    if (traitsComp == null) {
      return AppliedAncestryBonuses(ancestryId: ancestryId, bonuses: []);
    }

    final traitsData = jsonDecode(traitsComp.dataJson) as Map<String, dynamic>;
    final bonuses = <AncestryBonus>[];

    // Parse signature bonuses
    final signature = traitsData['signature'];
    if (signature != null) {
      if (signature is Map) {
        bonuses.addAll(_parseBonusesFromMap(
          signature.cast<String, dynamic>(),
          'signature',
          signature['name']?.toString() ?? 'Signature',
          traitChoices,
        ));
      } else if (signature is List) {
        // Some ancestries have multiple signature traits (e.g., Revenant)
        for (final sig in signature) {
          if (sig is Map) {
            bonuses.addAll(_parseBonusesFromMap(
              sig.cast<String, dynamic>(),
              'signature_${sig['name'] ?? 'unknown'}',
              sig['name']?.toString() ?? 'Signature',
              traitChoices,
            ));
          }
        }
      }
    }

    // Parse selected trait bonuses
    final traits = traitsData['traits'] as List?;
    if (traits != null) {
      for (final trait in traits) {
        if (trait is! Map) continue;
        final traitMap = trait.cast<String, dynamic>();
        final traitId = (traitMap['id'] ?? traitMap['name']).toString();
        
        // Only include if this trait is selected
        if (!selectedTraitIds.contains(traitId)) continue;

        final traitName = traitMap['name']?.toString() ?? traitId;
        final traitBonuses = _parseBonusesFromMap(traitMap, traitId, traitName, traitChoices);
        bonuses.addAll(traitBonuses);
      }
    }

    return AppliedAncestryBonuses(ancestryId: ancestryId, bonuses: bonuses);
  }

  List<AncestryBonus> _parseBonusesFromMap(
    Map<String, dynamic> data,
    String id,
    String name,
    Map<String, String> traitChoices,
  ) {
    return AncestryBonus.parseFromTraitData(data, id, name, traitChoices);
  }

  /// Apply ancestry bonuses to a hero.
  /// This updates the hero's stats, abilities, condition immunities, and damage resistances.
  Future<void> applyBonuses({
    required String heroId,
    required AppliedAncestryBonuses bonuses,
    required int heroLevel,
  }) async {
    // Store the raw bonuses for later removal
    await _saveBonuses(heroId, bonuses);

    // Get current hero values
    final values = await _db.getHeroValues(heroId);
    
    // Calculate and apply damage resistances
    await _applyDamageResistances(heroId, bonuses, heroLevel, values);

    // Apply stat modifications
    await _applyStatBonuses(heroId, bonuses, heroLevel, values);

    // Apply condition immunities
    await _applyConditionImmunities(heroId, bonuses);

    // Apply granted abilities
    await _applyGrantedAbilities(heroId, bonuses);
  }

  /// Remove all ancestry bonuses from a hero.
  /// 
  /// This clears all entries with sourceType='ancestry' from hero_entries,
  /// regardless of whether the bonuses config exists. This ensures orphaned
  /// entries are always cleaned up.
  Future<void> removeBonuses(String heroId) async {
    // Remove condition immunities - always clear even if config is null
    await _clearConditionImmunities(heroId);

    // Remove granted abilities - always clear even if config is null
    await _clearGrantedAbilities(heroId);

    // Clear stat modifications from ancestry
    await _clearAncestryStatMods(heroId);

    // Clear damage resistance bonuses (but keep base values)
    await _clearDamageResistanceBonuses(heroId);

    // Clear stored bonuses config
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kAncestryBonuses,
      textValue: null,
    );
  }

  /// Clear all condition immunities from ancestry source.
  Future<void> _clearConditionImmunities(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('condition_immunity') &
              t.sourceType.equals('ancestry')))
        .go();
  }

  /// Clear all granted abilities from ancestry source.
  Future<void> _clearGrantedAbilities(String heroId) async {
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('ability') &
              t.sourceType.equals('ancestry')))
        .go();
  }

  /// Load currently applied bonuses for a hero.
  Future<AppliedAncestryBonuses?> loadBonuses(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final bonusValue = values.firstWhereOrNull((v) => v.key == _kAncestryBonuses);
    if (bonusValue?.jsonValue == null && bonusValue?.textValue == null) {
      return null;
    }
    try {
      final jsonStr = bonusValue!.jsonValue ?? bonusValue.textValue!;
      return AppliedAncestryBonuses.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  /// Load damage resistances for a hero.
  /// Delegates to DamageResistanceService for centralized management.
  Future<HeroDamageResistances> loadDamageResistances(String heroId) async {
    return _resistanceService.loadDamageResistances(heroId);
  }

  /// Watch damage resistances - automatically updates when values change.
  /// Delegates to DamageResistanceService for centralized management.
  Stream<HeroDamageResistances> watchDamageResistances(String heroId) {
    return _resistanceService.watchDamageResistances(heroId);
  }

  /// Watch resistance bonuses from hero_entries (ancestry + complication sources).
  /// Delegates to DamageResistanceService for centralized management.
  Stream<Map<String, DamageResistanceBonus>> watchResistanceBonusEntries(String heroId) {
    return _resistanceService.watchResistanceBonusEntries(heroId);
  }

  /// Save damage resistances for a hero (base values only).
  /// Bonus values are stripped before saving - they are calculated at runtime
  /// from hero_entries and equipped treasures.
  Future<void> saveDamageResistances(
    String heroId,
    HeroDamageResistances resistances,
  ) async {
    // Only save base values - bonus values are calculated at runtime
    await _resistanceService.saveDamageResistances(heroId, resistances.baseOnly);
  }

  /// Update base resistance values (user-editable)
  Future<void> updateBaseResistance({
    required String heroId,
    required String damageType,
    required int baseImmunity,
    required int baseWeakness,
  }) async {
    final current = await loadDamageResistances(heroId);
    final existing = current.forType(damageType);
    
    final updated = current.upsertResistance(DamageResistance(
      damageType: damageType,
      baseImmunity: baseImmunity,
      baseWeakness: baseWeakness,
      bonusImmunity: existing?.bonusImmunity ?? 0,
      bonusWeakness: existing?.bonusWeakness ?? 0,
      sources: existing?.sources ?? const [],
    ));

    await saveDamageResistances(heroId, updated);
  }

  /// Add a new damage type to track
  Future<void> addDamageType(String heroId, String damageType) async {
    final current = await loadDamageResistances(heroId);
    if (current.forType(damageType) != null) return;
    
    final updated = current.upsertResistance(DamageResistance(
      damageType: damageType,
    ));
    
    await saveDamageResistances(heroId, updated);
  }

  /// Remove a damage type from tracking
  Future<void> removeDamageType(String heroId, String damageType) async {
    final current = await loadDamageResistances(heroId);
    final updated = current.removeResistance(damageType);
    await saveDamageResistances(heroId, updated);
  }

  // Private implementation methods

  Future<void> _saveBonuses(String heroId, AppliedAncestryBonuses bonuses) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kAncestryBonuses,
      textValue: bonuses.toJsonString(),
    );
  }

  Future<void> _applyDamageResistances(
    String heroId,
    AppliedAncestryBonuses bonuses,
    int heroLevel,
    List<db.HeroValue> values,
  ) async {
    // Clear old ancestry resistance entries first
    await _resistanceService.removeResistanceEntriesBySourceType(
      heroId: heroId,
      sourceType: 'ancestry',
    );
    
    // Collect all resistance bonuses
    final resistanceBonuses = <String, DamageResistanceBonus>{};

    for (final bonus in bonuses.bonuses) {
      if (bonus is IncreaseTotalBonus) {
        final stat = bonus.stat.toLowerCase();
        if (stat == 'immunity' || stat == 'weakness') {
          final types = bonus.damageTypes ?? [];
          final value = bonus.calculateValue(heroLevel);
          
          for (final type in types) {
            final key = type.toLowerCase();
            resistanceBonuses[key] ??= DamageResistanceBonus(damageType: type);
            if (stat == 'immunity') {
              resistanceBonuses[key]!.addImmunity(value, bonus.sourceTraitName);
            } else {
              resistanceBonuses[key]!.addWeakness(value, bonus.sourceTraitName);
            }
          }
        }
      }
    }

    // Store each resistance bonus via the centralized service
    for (final entry in resistanceBonuses.entries) {
      final type = entry.key;
      final bonus = entry.value;
      await _resistanceService.addResistanceEntry(
        heroId: heroId,
        damageType: type,
        sourceType: 'ancestry',
        sourceId: bonuses.ancestryId,
        immunity: bonus.immunity,
        weakness: bonus.weakness,
      );
    }

    // Rebuild the combined resistances from all sources
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  Future<void> _applyStatBonuses(
    String heroId,
    AppliedAncestryBonuses bonuses,
    int heroLevel,
    List<db.HeroValue> values,
  ) async {
    // Track stat modifications with their sources
    final statMods = <String, List<StatModification>>{};

    void addMod(String stat, int value, String source) {
      final key = stat.toLowerCase();
      statMods.putIfAbsent(key, () => []);
      statMods[key]!.add(StaticStatModification(value: value, source: source));
    }

    for (final bonus in bonuses.bonuses) {
      switch (bonus) {
        case SetBaseStatBonus():
          // Handle setting base stat if not higher
          final stat = bonus.stat.toLowerCase();
          if (stat == 'size') {
            // Size is stored as a string (e.g., "1M", "1L", "2")
            await _setBaseSizeIfNotHigher(heroId, bonus.value, values);
          } else {
            final currentValue = _getStatValue(values, bonus.stat);
            final newValue = _parseStatValue(bonus.value);
            if (newValue > currentValue) {
              await _setBaseStat(heroId, bonus.stat, newValue);
            }
          }
          
        case IncreaseTotalBonus():
          // Skip immunity/weakness - handled separately
          final stat = bonus.stat.toLowerCase();
          if (stat == 'immunity' || stat == 'weakness') continue;
          
          final value = bonus.calculateValue(heroLevel);
          addMod(stat, value, bonus.sourceTraitName);
          
        case IncreaseTotalPerEchelonBonus():
          final value = bonus.calculateBonus(heroLevel);
          addMod(bonus.stat.toLowerCase(), value, bonus.sourceTraitName);
          
        case DecreaseTotalBonus():
          addMod(bonus.stat.toLowerCase(), -bonus.value, bonus.sourceTraitName);
          
        default:
          // Other bonus types handled elsewhere
          break;
      }
    }

    // Apply stat modifications with sources
    await _setAncestryStatMods(heroId, statMods);
  }

  Future<void> _applyConditionImmunities(
    String heroId,
    AppliedAncestryBonuses bonuses,
  ) async {
    // Collect all condition immunities granted by ancestry traits
    final immunities = <String>[];
    for (final bonus in bonuses.bonuses) {
      if (bonus is ConditionImmunityBonus) {
        immunities.add(bonus.conditionName);
      }
    }

    if (immunities.isEmpty) return;

    // Replace ancestry-sourced condition immunities in hero_entries
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'ancestry',
      sourceId: bonuses.ancestryId,
      entryType: 'condition_immunity',
      entryIds: immunities,
      gainedBy: 'grant',
    );
  }

  Future<void> _applyGrantedAbilities(
    String heroId,
    AppliedAncestryBonuses bonuses,
  ) async {
    final abilities = <String, String>{}; // name -> source trait

    for (final bonus in bonuses.bonuses) {
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
      sourceType: 'ancestry',
      sourceId: bonuses.ancestryId,
      entryType: 'ability',
      entryIds: abilityIds,
      gainedBy: 'grant',
    );
  }

  Future<void> _clearAncestryStatMods(String heroId) async {
    // Clear from hero_entries (new storage)
    await (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals('stat_mod') &
              t.sourceType.equals('ancestry')))
        .go();
    
    // Also clear legacy hero_values for backwards compatibility
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kAncestryStatMods,
      textValue: null,
    );
  }

  Future<void> _clearDamageResistanceBonuses(String heroId) async {
    // Clear ancestry resistance entries via centralized service
    await _resistanceService.removeResistanceEntriesBySourceType(
      heroId: heroId,
      sourceType: 'ancestry',
    );
    // Rebuild from remaining entries (e.g., complication)
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  Future<void> _setAncestryStatMods(
    String heroId,
    Map<String, List<StatModification>> statMods,
  ) async {
    if (statMods.isEmpty) return;

    // Store each stat as a separate hero_entry with entryType='stat_mod'
    // Format: entryId = stat name, payload = { "mods": [{ "value": X, "source": "..." }] }
    for (final entry in statMods.entries) {
      final stat = entry.key.toLowerCase();
      final mods = entry.value;
      
      if (mods.isEmpty) continue;
      
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'stat_mod',
        entryId: stat,
        sourceType: 'ancestry',
        sourceId: 'ancestry_grant',
        gainedBy: 'grant',
        payload: {
          'mods': mods.map((m) => m.toJson()).toList(),
        },
      );
    }
  }

  /// Load ancestry stat modifications with sources for a hero.
  Future<HeroStatModifications> loadAncestryStatMods(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final modsValue = values.firstWhereOrNull((v) => v.key == _kAncestryStatMods);
    
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

  /// Watch ancestry stat modifications - automatically updates when values change.
  Stream<HeroStatModifications> watchAncestryStatMods(String heroId) {
    return _db.watchHeroValues(heroId).map((values) {
      final modsValue = values.firstWhereOrNull((v) => v.key == _kAncestryStatMods);
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

  Future<void> _setBaseStat(String heroId, String stat, int value) async {
    final key = _statToKey(stat);
    if (key == null) return;
    
    await _db.upsertHeroValue(
      heroId: heroId,
      key: key,
      value: value,
    );
  }

  /// Sets the base size from ancestry if not already higher.
  /// Size is stored as a string (e.g., "1M", "1L", "2").
  Future<void> _setBaseSizeIfNotHigher(
    String heroId,
    String newSize,
    List<db.HeroValue> values,
  ) async {
    final sizeValue = values.firstWhereOrNull((v) => v.key == 'stats.size');
    final currentSize = sizeValue?.textValue ?? '1M';
    
    // Parse both sizes to compare numeric portions
    final currentParsed = _parseSizeString(currentSize);
    final newParsed = _parseSizeString(newSize);
    
    // Compare: larger number wins; if equal, category order is T < S < M < L
    final shouldUpdate = _compareSizes(newParsed, currentParsed) > 0;
    
    if (shouldUpdate) {
      await _db.upsertHeroValue(
        heroId: heroId,
        key: 'stats.size',
        textValue: newSize,
      );
    }
  }

  /// Parse a size string (e.g., "1M", "2") into number and category.
  ({int number, String category}) _parseSizeString(String size) {
    if (size.isEmpty) return (number: 1, category: 'M');
    
    final lastChar = size[size.length - 1].toUpperCase();
    if ('TSML'.contains(lastChar)) {
      final numPart = size.substring(0, size.length - 1);
      return (number: int.tryParse(numPart) ?? 1, category: lastChar);
    }
    
    return (number: int.tryParse(size) ?? 1, category: '');
  }

  /// Compare two sizes. Returns >0 if a > b, <0 if a < b, 0 if equal.
  int _compareSizes(
    ({int number, String category}) a,
    ({int number, String category}) b,
  ) {
    if (a.number != b.number) return a.number - b.number;
    
    // Category order: T < S < M < L < '' (empty means size >= 2)
    const order = ['T', 'S', 'M', 'L', ''];
    final aIdx = order.indexOf(a.category);
    final bIdx = order.indexOf(b.category);
    return aIdx - bIdx;
  }

  int _getStatValue(List<db.HeroValue> values, String stat) {
    final key = _statToKey(stat);
    if (key == null) return 0;
    
    final value = values.firstWhereOrNull((v) => v.key == key);
    return value?.value ?? 0;
  }

  int _parseStatValue(String value) {
    // Handle special size values like "1L"
    if (value.toLowerCase().endsWith('l')) {
      // 1L = size 1 large, treat as 1 for now
      return int.tryParse(value.substring(0, value.length - 1)) ?? 0;
    }
    return int.tryParse(value) ?? 0;
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
      'saving_throw' || 'save' => 'conditions.save_ends',
      _ => null,
    };
  }

  // Storage keys
  static const _kAncestryBonuses = 'ancestry.applied_bonuses';
  static const _kAncestryStatMods = 'ancestry.stat_mods';
  static const _kConditionImmunities = 'ancestry.condition_immunities';
  static const _kGrantedAbilities = 'ancestry.granted_abilities';
}

/// Load condition immunities from ancestry
Future<List<String>> loadConditionImmunities(db.AppDatabase db, String heroId) async {
  final values = await db.getHeroValues(heroId);
  final value = values.firstWhereOrNull(
    (v) => v.key == AncestryBonusService._kConditionImmunities,
  );
  if (value?.textValue == null && value?.jsonValue == null) {
    return [];
  }
  try {
    final json = jsonDecode(value!.jsonValue ?? value.textValue!);
    if (json is List) {
      return json.map((e) => e.toString()).toList();
    }
  } catch (_) {}
  return [];
}

/// Load granted abilities from ancestry
Future<Map<String, String>> loadGrantedAbilities(db.AppDatabase db, String heroId) async {
  final values = await db.getHeroValues(heroId);
  final value = values.firstWhereOrNull(
    (v) => v.key == AncestryBonusService._kGrantedAbilities,
  );
  if (value?.textValue == null && value?.jsonValue == null) {
    return {};
  }
  try {
    final json = jsonDecode(value!.jsonValue ?? value.textValue!);
    if (json is Map) {
      return json.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  } catch (_) {}
  return {};
}

/// Load ancestry stat modifications
Future<Map<String, int>> loadAncestryStatMods(db.AppDatabase db, String heroId) async {
  final values = await db.getHeroValues(heroId);
  final value = values.firstWhereOrNull(
    (v) => v.key == AncestryBonusService._kAncestryStatMods,
  );
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

final ancestryBonusServiceProvider = Provider<AncestryBonusService>((ref) {
  final database = ref.read(appDatabaseProvider);
  return AncestryBonusService(database);
});
