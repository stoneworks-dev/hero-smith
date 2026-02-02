import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart' as db;
import '../models/component.dart' as model;
import '../repositories/hero_entry_repository.dart';
import 'ability_resolver_service.dart';
import 'hero_config_service.dart';
import 'kit_bonus_service.dart';

/// Service for applying kit grants to a hero.
/// 
/// Kits may grant equipment, traits/features, stat bonuses, and abilities.
/// All grants are written to hero_entries with source_type='kit' and
/// source_id=<kitId>.
class KitGrantsService {
  KitGrantsService(this._db)
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _bonusService = const KitBonusService(),
        _abilityResolver = AbilityResolverService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final KitBonusService _bonusService;
  final AbilityResolverService _abilityResolver;

  /// Config key for kit selections/options.
  static const _kKitSelections = 'kit.selections';

  /// Config key for equipment slot assignments.
  static const _kEquipmentSlots = 'equipment.slots';

  /// Apply kit grants to a hero.
  /// 
  /// This processes a list of equipment IDs (kits), extracts their grants,
  /// and stores them in hero_entries.
  /// 
  /// Returns the calculated [EquipmentBonuses] so callers can use them
  /// without re-loading components.
  Future<EquipmentBonuses> applyKitGrants({
    required String heroId,
    required List<String?> equipmentIds,
    required int heroLevel,
    Map<String, String>? kitSelections,
  }) async {
    // Clear existing kit grants
    await _clearAllKitGrants(heroId);

    // Store kit selections in config
    if (kitSelections != null && kitSelections.isNotEmpty) {
      await _config.setConfigValue(
        heroId: heroId,
        key: _kKitSelections,
        value: kitSelections,
      );
    }

    // Store equipment slot IDs in config
    final nonNullIds = equipmentIds.where((id) => id != null && id.isNotEmpty).toList();
    if (nonNullIds.isNotEmpty) {
      await _config.setConfigValue(
        heroId: heroId,
        key: _kEquipmentSlots,
        value: {'ids': nonNullIds},
      );
    }

    // Load kit components and process grants
    final dbComponents = await _db.getAllComponents();
    final kitComponents = <model.Component>[];
    
    for (final kitId in nonNullIds) {
      final dbComp = dbComponents.firstWhereOrNull((c) => c.id == kitId);
      if (dbComp != null) {
        // Convert db.Component to model.Component
        kitComponents.add(_convertDbComponent(dbComp));
      }
    }

    // Add kit entries
    for (final kit in kitComponents) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'equipment',
        entryId: kit.id,
        sourceType: 'kit',
        sourceId: kit.id,
        gainedBy: 'choice',
        payload: {
          'name': kit.name,
          'type': kit.type,
        },
      );

      // Process kit-specific grants
      await _processKitGrants(
        heroId: heroId,
        kit: kit,
        heroLevel: heroLevel,
        selections: kitSelections ?? const {},
      );
    }

    // Calculate and store equipment bonuses
    if (kitComponents.isNotEmpty) {
      final bonuses = _bonusService.calculateBonuses(
        equipment: kitComponents,
        heroLevel: heroLevel,
      );
      await _storeEquipmentBonuses(heroId, bonuses);
      return bonuses;
    }
    
    // No kit components - store empty bonuses to clear any previous values
    await _storeEquipmentBonuses(heroId, EquipmentBonuses.empty);
    return EquipmentBonuses.empty;
  }

  /// Remove all kit grants for a hero.
  Future<void> removeKitGrants(String heroId) async {
    await _clearAllKitGrants(heroId);
    await _config.removeConfigKey(heroId, _kKitSelections);
    await _config.removeConfigKey(heroId, _kEquipmentSlots);
    await _clearEquipmentBonuses(heroId);
  }

  /// Load kit selections from hero_config.
  Future<Map<String, String>> loadKitSelections(String heroId) async {
    final config = await _config.getConfigValue(heroId, _kKitSelections);
    if (config == null) return const {};
    return config.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  /// Load equipment slot IDs from hero_config.
  Future<List<String>> loadEquipmentSlotIds(String heroId) async {
    final config = await _config.getConfigValue(heroId, _kEquipmentSlots);
    if (config == null) return const [];
    final ids = config['ids'];
    if (ids is List) {
      return ids.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  /// Get all abilities granted by kits.
  Future<List<String>> getGrantedAbilities(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'ability');
    return entries
        .where((e) => e.sourceType == 'kit')
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all equipment entries for a hero.
  Future<List<db.HeroEntry>> getEquipmentEntries(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'equipment');
    return entries.where((e) => e.sourceType == 'kit').toList();
  }

  /// Get stat bonuses from kits.
  Future<Map<String, int>> getStatBonuses(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'kit_stat_bonus');
    final bonuses = <String, int>{};
    for (final entry in entries.where((e) => e.sourceType == 'kit')) {
      if (entry.payload == null) continue;
      try {
        final payload = jsonDecode(entry.payload!);
        if (payload is Map) {
          for (final key in ['stamina', 'speed', 'stability', 'disengage']) {
            final value = payload[key];
            if (value is num && value != 0) {
              bonuses[key] = (bonuses[key] ?? 0) + value.toInt();
            }
          }
        }
      } catch (_) {}
    }
    return bonuses;
  }

  // Private implementation

  Future<void> _clearAllKitGrants(String heroId) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'kit',
    );
  }

  /// Convert db.Component to model.Component
  model.Component _convertDbComponent(db.Component dbComp) {
    Map<String, dynamic> data = const {};
    if (dbComp.dataJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(dbComp.dataJson);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}
    }
    return model.Component(
      id: dbComp.id,
      type: dbComp.type,
      name: dbComp.name,
      data: data,
      source: dbComp.source,
      parentId: dbComp.parentId,
    );
  }

  Future<void> _processKitGrants({
    required String heroId,
    required model.Component kit,
    required int heroLevel,
    required Map<String, String> selections,
  }) async {
    final data = kit.data;

    // Grant signature ability
    final signatureAbility = data['signature_ability']?.toString();
    if (signatureAbility != null && signatureAbility.isNotEmpty) {
      final abilityId = await _abilityResolver.resolveAbilityId(
        signatureAbility,
        sourceType: 'kit',
      );
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'ability',
        entryId: abilityId,
        sourceType: 'kit',
        sourceId: kit.id,
        gainedBy: 'grant',
        payload: {'name': signatureAbility, 'source': 'kit_signature'},
      );
    }

    // Grant any additional abilities
    final abilities = data['abilities'] ?? data['granted_abilities'];
    if (abilities is List) {
      for (final ab in abilities) {
        final abilityName = ab?.toString();
        if (abilityName != null && abilityName.isNotEmpty) {
          final abilityId = await _abilityResolver.resolveAbilityId(
            abilityName,
            sourceType: 'kit',
          );
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'ability',
            entryId: abilityId,
            sourceType: 'kit',
            sourceId: kit.id,
            gainedBy: 'grant',
          );
        }
      }
    }

    // Grant traits/features
    final traits = data['traits'] ?? data['features'];
    if (traits is List) {
      for (final trait in traits) {
        if (trait is String && trait.isNotEmpty) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'kit_feature',
            entryId: _slugify(trait),
            sourceType: 'kit',
            sourceId: kit.id,
            gainedBy: 'grant',
            payload: {'name': trait},
          );
        } else if (trait is Map) {
          final traitName = trait['name']?.toString() ?? 'unknown';
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'kit_feature',
            entryId: _slugify(traitName),
            sourceType: 'kit',
            sourceId: kit.id,
            gainedBy: 'grant',
            payload: Map<String, dynamic>.from(trait),
          );
        }
      }
    }

    // Process kit options if any
    final options = data['options'];
    if (options is List && selections.containsKey(kit.id)) {
      final selectedOption = selections[kit.id];
      final option = options.firstWhereOrNull((o) {
        if (o is Map) {
          final name = o['name']?.toString();
          return name != null && _slugify(name) == _slugify(selectedOption ?? '');
        }
        return false;
      });
      if (option is Map) {
        await _applyKitOptionGrants(heroId, kit.id, option);
      }
    }

    // Store stat bonuses as hero_entries
    await _storeKitStatBonuses(heroId, kit, heroLevel);

    // Process decrease_total (e.g., for wards that reduce saving throw value)
    await _processDecreaseTotalBonus(heroId, kit);
  }

  Future<void> _applyKitOptionGrants(
    String heroId,
    String kitId,
    Map<dynamic, dynamic> option,
  ) async {
    // Grant ability from option
    final ability = option['ability']?.toString();
    if (ability != null && ability.isNotEmpty) {
      final abilityId = await _abilityResolver.resolveAbilityId(
        ability,
        sourceType: 'kit',
      );
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'ability',
        entryId: abilityId,
        sourceType: 'kit',
        sourceId: kitId,
        gainedBy: 'choice',
      );
    }

    // Grant feature from option
    final feature = option['feature']?.toString();
    if (feature != null && feature.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'kit_feature',
        entryId: _slugify(feature),
        sourceType: 'kit',
        sourceId: kitId,
        gainedBy: 'choice',
        payload: {'name': feature},
      );
    }
  }

  Future<void> _storeKitStatBonuses(
    String heroId,
    model.Component kit,
    int heroLevel,
  ) async {
    final data = kit.data;
    
    final tier = KitBonusService.tierForLevel(heroLevel);
    final echelon = KitBonusService.echelonForLevel(heroLevel);

    // Calculate stamina bonus with level scaling
    int staminaBonus = 0;
    final baseStamina = _parseIntOrNull(data['stamina_bonus']);
    if (baseStamina != null && baseStamina > 0) {
      // Scaling: multiply by echelon tier
      final multiplier = ((heroLevel - 1) ~/ 3) + 1;
      staminaBonus = baseStamina * multiplier;
    }

    final bonuses = {
      'stamina': staminaBonus,
      'speed': _parseIntOrNull(data['speed_bonus']) ?? 0,
      'stability': _parseIntOrNull(data['stability_bonus']) ?? 0,
      'disengage': _parseIntOrNull(data['disengage_bonus']) ?? 0,
      'melee_damage': _getTieredValue(data['melee_damage_bonus'], tier),
      'ranged_damage': _getTieredValue(data['ranged_damage_bonus'], tier),
      'melee_distance': _getEchelonValue(data['melee_distance_bonus'], echelon),
      'ranged_distance': _getEchelonValue(data['ranged_distance_bonus'], echelon),
    };

    // Only store if there are non-zero bonuses
    final hasBonus = bonuses.values.any((v) => v != 0);
    if (!hasBonus) return;
    await _entries.addEntry(
      heroId: heroId,
      entryType: 'kit_stat_bonus',
      entryId: '${kit.id}_stat_bonus',
      sourceType: 'kit',
      sourceId: kit.id,
      gainedBy: 'grant',
      payload: bonuses,
    );
  }

  Future<void> _storeEquipmentBonuses(
    String heroId,
    EquipmentBonuses bonuses,
  ) async {
    // Save to hero_entries as the single source of truth
    await _entries.addEntry(
      heroId: heroId,
      entryType: 'equipment_bonuses',
      entryId: 'combined_equipment_bonuses',
      sourceType: 'kit',
      sourceId: 'combined',
      gainedBy: 'calculated',
      payload: {
        'stamina': bonuses.staminaBonus,
        'speed': bonuses.speedBonus,
        'stability': bonuses.stabilityBonus,
        'disengage': bonuses.disengageBonus,
        'melee_damage': bonuses.meleeDamageBonus,
        'ranged_damage': bonuses.rangedDamageBonus,
        'melee_distance': bonuses.meleeDistanceBonus,
        'ranged_distance': bonuses.rangedDistanceBonus,
        'equipment_ids': bonuses.equipmentIds,
      },
    );
    
  }

  Future<void> _clearEquipmentBonuses(String heroId) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'kit',
      entryType: 'equipment_bonuses',
    );
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'kit',
      entryType: 'kit_stat_bonus',
    );
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'kit',
      entryType: 'stat_mod',
    );
  }

  /// Process decrease_total bonus from equipment (e.g., wards that reduce saving throw)
  Future<void> _processDecreaseTotalBonus(
    String heroId,
    model.Component kit,
  ) async {
    final data = kit.data;
    final decreaseTotal = data['decrease_total'];
    
    if (decreaseTotal == null) return;
    
    if (decreaseTotal is Map) {
      final stat = (decreaseTotal['stat'] as String?)?.toLowerCase() ?? '';
      final value = _parseIntOrNull(decreaseTotal['value']) ?? 0;
      
      if (stat.isNotEmpty && value != 0) {
        // Normalize stat name for storage (e.g., "saving throw" -> "saving_throw")
        final normalizedStat = stat.replaceAll(' ', '_');
        
        // Store as a stat mod entry with negative value (decrease)
        // Use the format expected by _mergeStatMods: { "stat_name": value }
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'stat_mod',
          entryId: '${kit.id}_decrease_$normalizedStat',
          sourceType: 'kit',
          sourceId: kit.id,
          gainedBy: 'grant',
          payload: {
            normalizedStat: -value, // Negative because it decreases the total
          },
        );
      }
    }
  }

  int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _getTieredValue(dynamic tierData, int tier) {
    if (tierData == null) return 0;
    if (tierData is! Map) return 0;
    final key = switch (tier) {
      1 => '1st_tier',
      2 => '2nd_tier',
      3 => '3rd_tier',
      _ => '1st_tier',
    };
    return _parseIntOrNull(tierData[key]) ?? 0;
  }

  int _getEchelonValue(dynamic echelonData, int echelon) {
    if (echelonData == null) return 0;
    if (echelonData is! Map) return 0;
    final key = switch (echelon) {
      1 => '1st_echelon',
      2 => '2nd_echelon',
      3 => '3rd_echelon',
      _ => '1st_echelon',
    };
    return _parseIntOrNull(echelonData[key]) ?? 0;
  }

  String _slugify(String value) =>
      AbilityResolverService.slugify(value);
}
