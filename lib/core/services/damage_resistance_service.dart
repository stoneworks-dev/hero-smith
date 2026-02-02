import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart';
import '../models/damage_resistance_model.dart';
import '../repositories/hero_entry_repository.dart';

/// Centralized service for managing hero damage resistances.
///
/// This service consolidates the resistance read/write logic that was
/// previously duplicated across ComplicationGrantsService, AncestryBonusService,
/// and ClassFeatureGrantsService.
///
/// Storage model:
/// - Aggregate resistance values stored in HeroValues (key: 'resistances.damage')
/// - Individual resistance entries stored in HeroEntries (entryType: 'resistance')
///   with sourceType tracking the origin (ancestry, complication, class_feature, etc.)
class DamageResistanceService {
  DamageResistanceService(this._db) : _entries = HeroEntryRepository(_db);

  final AppDatabase _db;
  final HeroEntryRepository _entries;

  /// Key for storing aggregate damage resistances in HeroValues
  static const _kDamageResistances = 'resistances.damage';

  // ---- Load/Save Aggregate Resistances ----

  /// Load damage resistances for a hero from HeroValues.
  Future<HeroDamageResistances> loadDamageResistances(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kDamageResistances);
    if (value?.jsonValue == null && value?.textValue == null) {
      return HeroDamageResistances.empty;
    }
    try {
      final jsonStr = value!.jsonValue ?? value.textValue!;
      return HeroDamageResistances.fromJsonString(jsonStr);
    } catch (_) {
      return HeroDamageResistances.empty;
    }
  }

  /// Watch damage resistances - automatically updates when values change.
  Stream<HeroDamageResistances> watchDamageResistances(String heroId) {
    return _db.watchHeroValues(heroId).map((values) {
      final value = values.firstWhereOrNull((v) => v.key == _kDamageResistances);
      if (value?.jsonValue == null && value?.textValue == null) {
        return HeroDamageResistances.empty;
      }
      try {
        final jsonStr = value!.jsonValue ?? value.textValue!;
        return HeroDamageResistances.fromJsonString(jsonStr);
      } catch (_) {
        return HeroDamageResistances.empty;
      }
    });
  }

  /// Save damage resistances for a hero to HeroValues.
  Future<void> saveDamageResistances(
    String heroId,
    HeroDamageResistances resistances,
  ) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kDamageResistances,
      textValue: resistances.toJsonString(),
    );
  }

  // ---- Resistance Entry Management ----

  /// Watch resistance bonuses from hero_entries (all sources).
  /// Returns a map of damage type -> DamageResistanceBonus.
  Stream<Map<String, DamageResistanceBonus>> watchResistanceBonusEntries(
    String heroId,
  ) {
    return _entries.watchEntriesByType(heroId, 'resistance').map((entries) {
      return _parseResistanceEntries(entries);
    });
  }

  /// Load resistance bonuses from hero_entries (all sources).
  Future<Map<String, DamageResistanceBonus>> loadResistanceBonusEntries(
    String heroId,
  ) async {
    final entries = await _entries.listEntriesByType(heroId, 'resistance');
    return _parseResistanceEntries(entries);
  }

  /// Add a resistance entry from a specific source.
  Future<void> addResistanceEntry({
    required String heroId,
    required String damageType,
    required String sourceType,
    required String sourceId,
    int immunity = 0,
    int weakness = 0,
    String? dynamicImmunity,
    String? dynamicWeakness,
    int immunityPerEchelon = 0,
    int weaknessPerEchelon = 0,
  }) async {
    final payload = <String, dynamic>{};

    if (immunity != 0 ||
        dynamicImmunity != null ||
        immunityPerEchelon != 0) {
      payload['immunityMods'] = [
        {
          'value': immunity,
          'source': sourceId,
          if (dynamicImmunity != null) 'dynamicValue': dynamicImmunity,
          if (immunityPerEchelon != 0) 'perEchelon': true,
          if (immunityPerEchelon != 0) 'valuePerEchelon': immunityPerEchelon,
        }
      ];
    }

    if (weakness != 0 ||
        dynamicWeakness != null ||
        weaknessPerEchelon != 0) {
      payload['weaknessMods'] = [
        {
          'value': weakness,
          'source': sourceId,
          if (dynamicWeakness != null) 'dynamicValue': dynamicWeakness,
          if (weaknessPerEchelon != 0) 'perEchelon': true,
          if (weaknessPerEchelon != 0) 'valuePerEchelon': weaknessPerEchelon,
        }
      ];
    }

    await _entries.addEntry(
      heroId: heroId,
      entryType: 'resistance',
      entryId: damageType,
      sourceType: sourceType,
      sourceId: sourceId,
      gainedBy: 'grant',
      payload: payload.isEmpty ? null : payload,
    );
  }

  /// Remove all resistance entries from a specific source.
  Future<void> removeResistanceEntriesFromSource({
    required String heroId,
    required String sourceType,
    required String sourceId,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: sourceType,
      sourceId: sourceId,
      entryType: 'resistance',
    );
  }

  /// Remove all resistance entries of a specific source type.
  Future<void> removeResistanceEntriesBySourceType({
    required String heroId,
    required String sourceType,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: sourceType,
      entryType: 'resistance',
    );
  }

  // ---- Aggregate Computation ----

  /// Recompute aggregate resistances from all entries.
  /// 
  /// This handles multiple entry types for compatibility:
  /// - `resistance`: The canonical format (damageType in entryId, mods in payload)
  /// - `damage_resistance`: Legacy class feature format
  /// - `immunity`/`weakness`: Legacy list-based format
  /// 
  /// This should be called after modifying resistance entries to update
  /// the aggregate HeroValues.
  Future<void> recomputeAggregateResistances(String heroId) async {
    // Get all entries for this hero
    final allEntries = await _entries.listAllEntriesForHero(heroId);
    
    // Aggregate resistances by damage type
    final resistanceMap = <String, DamageResistanceBonus>{};
    
    for (final entry in allEntries) {
      // Handle canonical 'resistance' entry type
      if (entry.entryType == 'resistance') {
        final damageType = entry.entryId.toLowerCase();
        resistanceMap.putIfAbsent(damageType, () => DamageResistanceBonus(damageType: damageType));
        _parseResistancePayload(entry, resistanceMap[damageType]!);
      }
      
      // Handle 'damage_resistance' entry type (from class feature grants)
      if (entry.entryType == 'damage_resistance') {
        _parseDamageResistanceEntry(entry, resistanceMap);
      }
      
      // Handle legacy 'immunity' entry type
      if (entry.entryType == 'immunity') {
        _parseLegacyImmunityEntry(entry, resistanceMap);
      }
      
      // Handle legacy 'weakness' entry type
      if (entry.entryType == 'weakness') {
        _parseLegacyWeaknessEntry(entry, resistanceMap);
      }
    }
    
    // Load current resistances to preserve base values (user-editable)
    final currentResistances = await loadDamageResistances(heroId);
    
    // Build the final resistance list
    final finalResistances = <DamageResistance>[];
    
    // Process all damage types (from both current and computed)
    final allDamageTypes = <String>{
      ...resistanceMap.keys,
      ...currentResistances.resistances.map((r) => r.damageType.toLowerCase()),
    };
    
    for (final damageType in allDamageTypes) {
      final current = currentResistances.forType(damageType);
      final bonus = resistanceMap[damageType];
      
      finalResistances.add(DamageResistance(
        damageType: damageType,
        baseImmunity: current?.baseImmunity ?? 0,
        baseWeakness: current?.baseWeakness ?? 0,
        bonusImmunity: bonus?.immunity ?? 0,
        bonusWeakness: bonus?.weakness ?? 0,
        sources: bonus?.sources ?? const [],
        dynamicImmunity: bonus?.dynamicImmunity,
        dynamicWeakness: bonus?.dynamicWeakness,
        immunityPerEchelon: bonus?.immunityPerEchelon ?? 0,
        weaknessPerEchelon: bonus?.weaknessPerEchelon ?? 0,
      ));
    }
    
    final resistances = HeroDamageResistances(resistances: finalResistances);
    await saveDamageResistances(heroId, resistances);
  }
  
  /// Parse a 'damage_resistance' entry (class feature format).
  void _parseDamageResistanceEntry(
    HeroEntry entry,
    Map<String, DamageResistanceBonus> resistanceMap,
  ) {
    if (entry.payload == null) return;
    try {
      final payload = jsonDecode(entry.payload!);
      if (payload is! Map) return;
      
      final stat = (payload['stat'] as String?)?.toLowerCase();
      final damageType = (payload['type'] as String?)?.toLowerCase();
      final value = payload['value'];
      final source = '${entry.sourceType}:${entry.sourceId}';
      
      if (damageType == null || damageType.isEmpty) return;
      
      resistanceMap.putIfAbsent(damageType, () => DamageResistanceBonus(damageType: damageType));
      final bonus = resistanceMap[damageType]!;
      
      if (value is int) {
        if (stat == 'immunity') {
          bonus.addImmunity(value, source);
        } else if (stat == 'weakness') {
          bonus.addWeakness(value, source);
        }
      } else if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'level') {
          if (stat == 'immunity') {
            bonus.setDynamicImmunity('level', source);
          } else if (stat == 'weakness') {
            bonus.setDynamicWeakness('level', source);
          }
        }
      }
    } catch (_) {}
  }
  
  /// Parse a legacy 'immunity' entry.
  void _parseLegacyImmunityEntry(
    HeroEntry entry,
    Map<String, DamageResistanceBonus> resistanceMap,
  ) {
    if (entry.payload == null) return;
    try {
      final payload = jsonDecode(entry.payload!);
      final immunities = payload['immunities'];
      if (immunities is! List) return;
      
      final source = '${entry.sourceType}:${entry.sourceId}';
      for (final type in immunities) {
        final damageType = type.toString().toLowerCase();
        resistanceMap.putIfAbsent(damageType, () => DamageResistanceBonus(damageType: damageType));
        resistanceMap[damageType]!.addImmunity(1, source);
      }
    } catch (_) {}
  }
  
  /// Parse a legacy 'weakness' entry.
  void _parseLegacyWeaknessEntry(
    HeroEntry entry,
    Map<String, DamageResistanceBonus> resistanceMap,
  ) {
    if (entry.payload == null) return;
    try {
      final payload = jsonDecode(entry.payload!);
      final weaknesses = payload['weaknesses'];
      if (weaknesses is! List) return;
      
      final source = '${entry.sourceType}:${entry.sourceId}';
      for (final type in weaknesses) {
        final damageType = type.toString().toLowerCase();
        resistanceMap.putIfAbsent(damageType, () => DamageResistanceBonus(damageType: damageType));
        resistanceMap[damageType]!.addWeakness(1, source);
      }
    } catch (_) {}
  }

  // ---- Private Helpers ----

  /// Parse resistance payload into a DamageResistanceBonus.
  void _parseResistancePayload(HeroEntry entry, DamageResistanceBonus bonus) {
    if (entry.payload == null) return;
    try {
      final decoded = jsonDecode(entry.payload!);
      if (decoded is! Map) return;

      // Parse immunityMods
      final immunityMods = decoded['immunityMods'];
      if (immunityMods is List) {
        for (final modData in immunityMods) {
          if (modData is Map) {
            final value = (modData['value'] as num?)?.toInt() ?? 0;
            final source = modData['source'] as String? ?? entry.sourceId;
            final dynValue = modData['dynamicValue'] as String?;
            final perEchelon = modData['perEchelon'] as bool? ?? false;
            final valPerEchelon =
                (modData['valuePerEchelon'] as num?)?.toInt() ?? 0;

            if (value != 0) bonus.addImmunity(value, source);
            if (dynValue != null) bonus.setDynamicImmunity(dynValue, source);
            if (perEchelon && valPerEchelon != 0) {
              bonus.addImmunityPerEchelon(valPerEchelon, source);
            }
          }
        }
      }

      // Parse weaknessMods
      final weaknessMods = decoded['weaknessMods'];
      if (weaknessMods is List) {
        for (final modData in weaknessMods) {
          if (modData is Map) {
            final value = (modData['value'] as num?)?.toInt() ?? 0;
            final source = modData['source'] as String? ?? entry.sourceId;
            final dynValue = modData['dynamicValue'] as String?;
            final perEchelon = modData['perEchelon'] as bool? ?? false;
            final valPerEchelon =
                (modData['valuePerEchelon'] as num?)?.toInt() ?? 0;

            if (value != 0) bonus.addWeakness(value, source);
            if (dynValue != null) bonus.setDynamicWeakness(dynValue, source);
            if (perEchelon && valPerEchelon != 0) {
              bonus.addWeaknessPerEchelon(valPerEchelon, source);
            }
          }
        }
      }

      // Legacy format fallback
      if (bonus.immunity == 0 && bonus.weakness == 0) {
        final immunity = (decoded['immunity'] as num?)?.toInt() ?? 0;
        final weakness = (decoded['weakness'] as num?)?.toInt() ?? 0;
        final legacySource = decoded['source'] as String? ?? entry.sourceId;
        if (immunity != 0) bonus.addImmunity(immunity, legacySource);
        if (weakness != 0) bonus.addWeakness(weakness, legacySource);
      }
    } catch (_) {
      // Ignore malformed payload
    }
  }

  Map<String, DamageResistanceBonus> _parseResistanceEntries(
    List<HeroEntry> entries,
  ) {
    final combinedBonuses = <String, DamageResistanceBonus>{};

    for (final e in entries) {
      final key = e.entryId;
      combinedBonuses[key] ??= DamageResistanceBonus(damageType: e.entryId);
      _parseResistancePayload(e, combinedBonuses[key]!);
    }

    return combinedBonuses;
  }
}
