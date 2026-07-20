import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart' as db;
import '../models/canonical_grant_model.dart';
import '../models/component.dart' as model;
import '../models/hero_mutation_model.dart';
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'ability_resolver_service.dart';
import 'hero_config_service.dart';
import 'hero_mutation_service.dart';
import 'kit_bonus_service.dart';

/// Service for applying kit grants to a hero.
///
/// Kits may grant equipment, traits/features, stat bonuses, and abilities.
/// All grants are written to hero_entries with source_type='kit' and
/// source_id=<kitId>.
class KitGrantsService {
  KitGrantsService(this._db, {HeroMutationService? mutations})
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _mutations = mutations ?? HeroMutationService(_db),
        _bonusService = const KitBonusService(),
        _abilityResolver = AbilityResolverService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final HeroMutationService _mutations;
  final KitBonusService _bonusService;
  final AbilityResolverService _abilityResolver;

  /// Config key for kit selections/options.
  static const _kKitSelections = HeroConfigKeys.kitSelections;

  /// Config key for equipment slot assignments.
  static const _kEquipmentSlots = HeroConfigKeys.equipmentSlots;

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
      await _mutations.saveConfigChoice(
        heroId: heroId,
        key: _kKitSelections,
        value: kitSelections,
      );
    }

    // Store equipment slot IDs in config
    final nonNullIds =
        equipmentIds.whereType<String>().where((id) => id.isNotEmpty).toList();
    await _mutations.saveConfigChoice(
      heroId: heroId,
      key: _kEquipmentSlots,
      value: {'ids': nonNullIds},
    );

    await _mutations.replaceContentEntries(
      heroId: heroId,
      source: const HeroSource(
        sourceType: HeroEntrySourceTypes.equipment,
        sourceId: HeroEntrySourceIds.equipmentSlots,
        gainedBy: HeroEntryGainedBy.choice,
      ),
      entryType: HeroEntryTypes.equipment,
      entryIds: nonNullIds,
    );

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

    // Apply grants from each selected equipment component. The equipment
    // selection itself is owned once by equipment:equipment_slots above;
    // kit:<id> owns only what that component grants.
    for (final kit in kitComponents) {
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
    const equipmentSource = HeroSource(
      sourceType: HeroEntrySourceTypes.equipment,
      sourceId: HeroEntrySourceIds.equipmentSlots,
      gainedBy: HeroEntryGainedBy.choice,
    );
    await _mutations.removeSource(
      heroId: heroId,
      source: equipmentSource,
      entryType: HeroEntryTypes.equipment,
      recomputeAggregates: false,
    );
    await _mutations.removeSource(
      heroId: heroId,
      source: equipmentSource,
      entryType: HeroEntryTypes.kit,
      recomputeAggregates: false,
    );
    await _mutations.removeConfigChoice(heroId: heroId, key: _kKitSelections);
    await _mutations.removeConfigChoice(heroId: heroId, key: _kEquipmentSlots);
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
      return ids
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Get all abilities granted by kits.
  Future<List<String>> getGrantedAbilities(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.ability,
    );
    return entries
        .where((e) => e.sourceType == HeroEntrySourceTypes.kit)
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all equipment entries for a hero.
  Future<List<db.HeroEntry>> getEquipmentEntries(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.equipment,
    );
    return entries.where((entry) {
      final isCurrentSelection =
          entry.sourceType == HeroEntrySourceTypes.equipment &&
              entry.sourceId == HeroEntrySourceIds.equipmentSlots;
      final isLegacyKitSelection = entry.sourceType == HeroEntrySourceTypes.kit;
      return isCurrentSelection || isLegacyKitSelection;
    }).toList();
  }

  /// Get stat bonuses from kits.
  Future<Map<String, int>> getStatBonuses(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.kitStatBonus,
    );
    final bonuses = <String, int>{};
    for (final entry
        in entries.where((e) => e.sourceType == HeroEntrySourceTypes.kit)) {
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
    const grantEntryTypes = [
      HeroEntryTypes.ability,
      HeroEntryTypes.equipment,
      HeroEntryTypes.equipmentBonuses,
      HeroEntryTypes.kitFeature,
      HeroEntryTypes.kitStatBonus,
      HeroEntryTypes.statMod,
    ];

    for (final entryType in grantEntryTypes) {
      await _mutations.removeSourceType(
        heroId: heroId,
        sourceType: HeroEntrySourceTypes.kit,
        entryType: entryType,
        recomputeAggregates: false,
      );
    }
  }

  HeroSource _kitSource(
    String sourceId, {
    String gainedBy = HeroEntryGainedBy.grant,
  }) {
    return HeroSource(
      sourceType: HeroEntrySourceTypes.kit,
      sourceId: sourceId,
      gainedBy: gainedBy,
    );
  }

  Future<void> _addKitEntry({
    required String heroId,
    required String sourceId,
    required String entryType,
    required String entryId,
    String gainedBy = HeroEntryGainedBy.grant,
    Map<String, dynamic>? payload,
  }) async {
    final normalizedEntryId = entryId.trim();
    if (normalizedEntryId.isEmpty) return;

    await _mutations.addContentEntry(
      heroId: heroId,
      source: _kitSource(sourceId, gainedBy: gainedBy),
      grant: ResolvedGrant(
        entryType: entryType,
        entryId: normalizedEntryId,
        payload: payload,
      ),
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
      await _addKitEntry(
        heroId: heroId,
        sourceId: kit.id,
        entryType: HeroEntryTypes.ability,
        entryId: abilityId,
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
          await _addKitEntry(
            heroId: heroId,
            sourceId: kit.id,
            entryType: HeroEntryTypes.ability,
            entryId: abilityId,
          );
        }
      }
    }

    // Grant traits/features
    final traits = data['traits'] ?? data['features'];
    if (traits is List) {
      for (final trait in traits) {
        if (trait is String && trait.isNotEmpty) {
          await _addKitEntry(
            heroId: heroId,
            sourceId: kit.id,
            entryType: HeroEntryTypes.kitFeature,
            entryId: _slugify(trait),
            payload: {'name': trait},
          );
        } else if (trait is Map) {
          final traitName = trait['name']?.toString() ?? 'unknown';
          await _addKitEntry(
            heroId: heroId,
            sourceId: kit.id,
            entryType: HeroEntryTypes.kitFeature,
            entryId: _slugify(traitName),
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
          return name != null &&
              _slugify(name) == _slugify(selectedOption ?? '');
        }
        return false;
      });
      if (option is Map) {
        await _applyKitOptionGrants(heroId, kit.id, option);
      }
    }

    // Store stat bonuses as hero_entries
    await _storeKitStatBonuses(heroId, kit, heroLevel);

    // Process canonical grants during data conversion.
    await _processCanonicalGrants(heroId, kit, heroLevel);

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
      await _addKitEntry(
        heroId: heroId,
        sourceId: kitId,
        entryType: HeroEntryTypes.ability,
        entryId: abilityId,
        gainedBy: HeroEntryGainedBy.choice,
      );
    }

    // Grant feature from option
    final feature = option['feature']?.toString();
    if (feature != null && feature.isNotEmpty) {
      await _addKitEntry(
        heroId: heroId,
        sourceId: kitId,
        entryType: HeroEntryTypes.kitFeature,
        entryId: _slugify(feature),
        gainedBy: HeroEntryGainedBy.choice,
        payload: {'name': feature},
      );
    }
  }

  Future<void> _storeKitStatBonuses(
    String heroId,
    model.Component kit,
    int heroLevel,
  ) async {
    final data = _bonusService.extractBonusData(kit.data);

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
      'ranged_distance':
          _getEchelonValue(data['ranged_distance_bonus'], echelon),
    };

    // Only store if there are non-zero bonuses
    final hasBonus = bonuses.values.any((v) => v != 0);
    if (!hasBonus) return;
    await _addKitEntry(
      heroId: heroId,
      sourceId: kit.id,
      entryType: HeroEntryTypes.kitStatBonus,
      entryId: '${kit.id}_stat_bonus',
      payload: bonuses,
    );
  }

  Future<void> _storeEquipmentBonuses(
    String heroId,
    EquipmentBonuses bonuses,
  ) async {
    // Save to hero_entries as the single source of truth
    await _addKitEntry(
      heroId: heroId,
      sourceId: 'combined',
      entryType: HeroEntryTypes.equipmentBonuses,
      entryId: 'combined_equipment_bonuses',
      gainedBy: HeroEntryGainedBy.calculated,
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
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.kit,
      entryType: HeroEntryTypes.equipmentBonuses,
      recomputeAggregates: false,
    );
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.kit,
      entryType: HeroEntryTypes.kitStatBonus,
      recomputeAggregates: false,
    );
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.kit,
      entryType: HeroEntryTypes.statMod,
      recomputeAggregates: false,
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
        await _addKitEntry(
          heroId: heroId,
          sourceId: kit.id,
          entryType: HeroEntryTypes.statMod,
          entryId: '${kit.id}_decrease_$normalizedStat',
          payload: {
            normalizedStat: -value, // Negative because it decreases the total
          },
        );
      }
    }
  }

  Future<void> _processCanonicalGrants(
    String heroId,
    model.Component kit,
    int heroLevel,
  ) async {
    final grants = kit.data['grants'];
    if (!_looksLikeCanonicalGrants(grants)) return;

    final parsedGrants = CanonicalGrant.parseList(
      grants,
      defaultSource: 'kit:${kit.id}',
    );

    for (final grant in parsedGrants) {
      switch (grant) {
        case CanonicalStatModGrant():
          await _processCanonicalStatModGrant(
            heroId: heroId,
            kitId: kit.id,
            grant: grant,
            heroLevel: heroLevel,
          );
        default:
          break;
      }
    }
  }

  Future<void> _processCanonicalStatModGrant({
    required String heroId,
    required String kitId,
    required CanonicalStatModGrant grant,
    required int heroLevel,
  }) async {
    final normalizedStat = _normalizeStat(grant.stat);
    final value = grant.modifications.fold<int>(
      0,
      (sum, modification) => sum + modification.getActualValue(heroLevel),
    );
    if (normalizedStat.isEmpty || value == 0) return;

    await _addKitEntry(
      heroId: heroId,
      sourceId: kitId,
      entryType: HeroEntryTypes.statMod,
      entryId: grant.entryId ?? '${kitId}_stat_mod_$normalizedStat',
      payload: {normalizedStat: value},
    );
  }

  bool _looksLikeCanonicalGrants(Object? grants) {
    if (grants is Map) {
      if (grants['schema'] == canonicalGrantSchemaId) return true;
      if (grants.containsKey('kind')) return true;
      return _looksLikeCanonicalGrants(grants['grants']);
    }
    if (grants is List) {
      return grants.any((grant) => grant is Map && grant.containsKey('kind'));
    }
    return false;
  }

  String _normalizeStat(String stat) =>
      stat.trim().toLowerCase().replaceAll(' ', '_');

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

  String _slugify(String value) => AbilityResolverService.slugify(value);
}
