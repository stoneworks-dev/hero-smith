import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'damage_resistance_service.dart';
import 'hero_config_service.dart';

/// Normalizes hero_entries to ensure correct metadata and completeness.
///
/// This class is responsible for:
/// 1. Migrating legacy data from hero_values to hero_entries/hero_config
/// 2. Cleaning up invalid or duplicate entries
/// 3. Recomputing aggregate values (like resistances.damage)
/// 4. Ensuring idempotent operation (safe to run multiple times)
class HeroEntryNormalizer {
  HeroEntryNormalizer(this._db)
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _resistanceService = DamageResistanceService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final DamageResistanceService _resistanceService;

  static const Set<String> _bannedConfigKeys = HeroConfigKeys.bannedKeys;
  static const Set<String> _bannedEntryTypes = HeroEntryTypes.bannedTypes;

  /// Main normalization entry point.
  /// Runs all migration and cleanup steps in a single transaction.
  /// This method is IDEMPOTENT - safe to run multiple times.
  Future<void> normalize(String heroId) async {
    await _db.transaction(() async {
      await _dedupeConfig(heroId);

      // === PHASE 1: Migrate legacy data to hero_entries/hero_config ===
      await _migrateBasicsToEntries(heroId);
      await _migrateFaithToEntries(heroId);
      await _migrateLegacyAncestryData(heroId);
      await _migrateLegacyComplicationData(heroId);
      await _normalizeLegacyComplicationAncestryTraitEntries(heroId);
      await _migrateLegacyClassFeatureGrants(heroId);
      await _migrateLegacyKitGrants(heroId);
      await _migrateLegacyEquipmentSelections(heroId);
      await _migrateLegacyEquipmentBonuses(heroId);
      await _migrateLegacyFeatureStatBonuses(heroId);
      await _migrateLegacyPerkAbilityGrants(heroId);
      await _migrateLegacyPerkGrants(heroId);
      await _migrateClassFeatureSelections(heroId);
      await _migrateSubclassKeyToEntries(heroId);

      // === PHASE 2: Remove banned legacy keys from hero_values ===
      await _removeBannedValues(heroId);

      // === PHASE 3: Remove banned legacy keys from hero_config ===
      await _removeBannedConfigKeys(heroId);
      await _dedupeConfig(heroId);

      // === PHASE 4: Ensure hero_entries from hero_config selections ===
      await _ensureAncestrySelections(heroId);
      await _ensureCultureSelections(heroId);
      await _ensureCareerSelections(heroId);
      await _ensureStrifeSelections(heroId);
      await _ensureEquipment(heroId);

      // === PHASE 5: Cleanup and validation ===
      await _removeInvalidEntries(heroId);
      await _removeBannedEntryTypes(heroId);
      await _dedupe(heroId);
      await _dedupeConfig(heroId);

      // === PHASE 6: Recompute aggregate values ===
      await _recomputeResistances(heroId);
    });
  }

  // ===========================================================================
  // PHASE 1: LEGACY DATA MIGRATION
  // ===========================================================================

  /// Migrate basics.* identifiers from hero_values to hero_entries.
  /// These are content choices, not numeric state.
  Future<void> _migrateBasicsToEntries(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    String? text(String key) =>
        rows.firstWhereOrNull((v) => v.key == key)?.textValue;

    // Class → hero_entry (entry_type="class", source_type="manual_choice")
    final classId = text('basics.className');
    if (classId != null && classId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'class',
        entryId: classId,
        sourceType: 'manual_choice',
        sourceId: classId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'basics.className');
    }

    // Subclass → hero_entry
    final subclassId = text('basics.subclass');
    if (subclassId != null && subclassId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'subclass',
        entryId: subclassId,
        sourceType: 'manual_choice',
        sourceId: subclassId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'basics.subclass');
    }

    // Ancestry → hero_entry
    final ancestryId = text('basics.ancestry');
    if (ancestryId != null && ancestryId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'ancestry',
        entryId: ancestryId,
        sourceType: 'manual_choice',
        sourceId: ancestryId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'basics.ancestry');
    }

    // Career → hero_entry
    final careerId = text('basics.career');
    if (careerId != null && careerId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'career',
        entryId: careerId,
        sourceType: 'manual_choice',
        sourceId: careerId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'basics.career');
    }

    // Kit → hero_entry
    final kitId = text('basics.kit');
    if (kitId != null && kitId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'kit',
        entryId: kitId,
        sourceType: 'manual_choice',
        sourceId: kitId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'basics.kit');
    }
  }

  /// Migrate faith.* (deity/domain) from hero_values to hero_entries.
  Future<void> _migrateFaithToEntries(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    String? text(String key) =>
        rows.firstWhereOrNull((v) => v.key == key)?.textValue;

    final deityId = text('faith.deity');
    if (deityId != null && deityId.isNotEmpty) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'deity',
        entryId: deityId,
        sourceType: 'manual_choice',
        sourceId: deityId,
        gainedBy: 'choice',
      );
      await _db.deleteHeroValue(heroId: heroId, key: 'faith.deity');
    }

    final domainStr = text('faith.domain');
    if (domainStr != null && domainStr.isNotEmpty) {
      final domains = domainStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      for (final domain in domains) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'domain',
          entryId: domain,
          sourceType: 'deity',
          sourceId: deityId ?? 'domain_choice',
          gainedBy: 'choice',
        );
      }
      await _db.deleteHeroValue(heroId: heroId, key: 'faith.domain');
    }
  }

  /// Migrate legacy ancestry data (selected_traits, stat_mods, resistances).
  Future<void> _migrateLegacyAncestryData(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    // Migrate ancestry.applied_bonuses snapshot to hero_config.
    final appliedBonusesRow = rows.firstWhereOrNull(
      (v) => v.key == HeroConfigKeys.ancestryAppliedBonuses,
    );
    if (appliedBonusesRow != null) {
      final appliedBonuses = _parseJsonMap(appliedBonusesRow);
      if (appliedBonuses.isNotEmpty) {
        await _config.setConfigValue(
          heroId: heroId,
          key: HeroConfigKeys.ancestryAppliedBonuses,
          value: appliedBonuses,
        );
      }
      await _db.deleteHeroValue(
        heroId: heroId,
        key: HeroConfigKeys.ancestryAppliedBonuses,
      );
    }

    // Migrate ancestry.selected_traits to hero_entries
    final traitValue =
        rows.firstWhereOrNull((v) => v.key == 'ancestry.selected_traits');
    if (traitValue != null) {
      final traits = _parseJsonList(traitValue);
      for (final traitId in traits) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ancestry_trait',
          entryId: traitId,
          sourceType: 'ancestry',
          sourceId: 'ancestry_trait_choice',
          gainedBy: 'choice',
        );
      }
      await _db.deleteHeroValue(
          heroId: heroId, key: 'ancestry.selected_traits');
    }

    // Migrate ancestry.granted_abilities
    final abilitiesRow =
        rows.firstWhereOrNull((v) => v.key == 'ancestry.granted_abilities');
    if (abilitiesRow != null) {
      final abilities = _parseJsonList(abilitiesRow);
      for (final ability in abilities) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ability',
          entryId: ability,
          sourceType: 'ancestry',
          sourceId: 'ancestry_grant',
          gainedBy: 'grant',
        );
      }
      await _db.deleteHeroValue(
          heroId: heroId, key: 'ancestry.granted_abilities');
    }

    // Migrate ancestry.stat_mods
    final statModsRow =
        rows.firstWhereOrNull((v) => v.key == 'ancestry.stat_mods');
    if (statModsRow != null) {
      final mods = _parseJsonMap(statModsRow);
      if (mods.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: HeroEntryTypes.statMod,
          entryId: 'ancestry_stat_mods',
          sourceType: HeroEntrySourceTypes.ancestry,
          sourceId: 'ancestry_grant',
          gainedBy: HeroEntryGainedBy.grant,
          payload: {'mods': mods},
        );
      }
      await _db.deleteHeroValue(heroId: heroId, key: 'ancestry.stat_mods');
    }

    // Migrate ancestry.condition_immunities as resistance entries
    final immunitiesRow =
        rows.firstWhereOrNull((v) => v.key == 'ancestry.condition_immunities');
    if (immunitiesRow != null) {
      final immunities = _parseJsonList(immunitiesRow);
      for (final conditionType in immunities) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'condition_immunity',
          entryId: conditionType,
          sourceType: 'ancestry',
          sourceId: 'ancestry_grant',
          gainedBy: 'grant',
        );
      }
      await _db.deleteHeroValue(
          heroId: heroId, key: 'ancestry.condition_immunities');
    }
  }

  /// Migrate legacy complication data blobs out of hero_values.
  Future<void> _migrateLegacyComplicationData(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    Future<void> migrateConfigMap(String valueKey, String configKey) async {
      final row = rows.firstWhereOrNull((v) => v.key == valueKey);
      if (row == null) return;

      final value = _parseJsonMap(row);
      if (value.isNotEmpty) {
        await _config.setConfigValue(
          heroId: heroId,
          key: configKey,
          value: value,
        );
      }
      await _db.deleteHeroValue(heroId: heroId, key: valueKey);
    }

    await migrateConfigMap(
      HeroConfigKeys.complicationAppliedGrants,
      HeroConfigKeys.complicationAppliedGrants,
    );
    await migrateConfigMap(
      HeroConfigKeys.complicationTokens,
      HeroConfigKeys.complicationTokens,
    );
    await migrateConfigMap(
      HeroConfigKeys.complicationOriginalBaseStats,
      HeroConfigKeys.complicationOriginalBaseStats,
    );

    final statModsRow =
        rows.firstWhereOrNull((v) => v.key == 'complication.stat_mods');
    if (statModsRow != null) {
      final mods = _parseJsonMap(statModsRow);
      if (mods.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: HeroEntryTypes.statMod,
          entryId: 'complication_stat_mods',
          sourceType: HeroEntrySourceTypes.complication,
          sourceId: 'complication_grant',
          gainedBy: HeroEntryGainedBy.grant,
          payload: {'mods': mods},
        );
      }
      await _db.deleteHeroValue(heroId: heroId, key: 'complication.stat_mods');
    }

    final contentKeys = <String, String>{
      'complication.abilities': HeroEntryTypes.ability,
      'complication.skills': HeroEntryTypes.skill,
      'complication.features': HeroEntryTypes.feature,
      'complication.treasures': HeroEntryTypes.treasure,
      'complication.languages': HeroEntryTypes.language,
    };
    for (final entry in contentKeys.entries) {
      final row = rows.firstWhereOrNull((v) => v.key == entry.key);
      if (row == null) continue;

      final ids = _parseLegacyList(row);
      for (final id in ids) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: entry.value,
          entryId: id,
          sourceType: HeroEntrySourceTypes.complication,
          sourceId: 'complication',
          gainedBy: HeroEntryGainedBy.grant,
        );
      }
      await _db.deleteHeroValue(heroId: heroId, key: entry.key);
    }
  }

  Future<void> _normalizeLegacyComplicationAncestryTraitEntries(
    String heroId,
  ) async {
    await (_db.update(_db.heroEntries)
          ..where((entry) =>
              entry.heroId.equals(heroId) &
              entry.gainedBy.equals('ancestry_trait_grant')))
        .write(
      const db.HeroEntriesCompanion(
        sourceType: Value(HeroEntrySourceTypes.complicationAncestryTrait),
        gainedBy: Value(HeroEntryGainedBy.grant),
      ),
    );
  }

  /// Migrate legacy perk_grant.* keys to hero_config as perk.<perkId>.selections.
  Future<void> _migrateLegacyPerkGrants(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    // Group all perk_grant.* keys by perkId
    final perkGrants = <String, Map<String, dynamic>>{};
    final keysToDelete = <String>[];

    for (final row in rows) {
      if (!row.key.startsWith('perk_grant.')) continue;
      keysToDelete.add(row.key);

      // Parse: perk_grant.<perkId>.<grantType>
      final parts = row.key.split('.');
      if (parts.length < 3) continue;

      final perkId = parts[1];
      final grantType = parts.sublist(2).join('.');

      perkGrants.putIfAbsent(perkId, () => {});

      final value = row.jsonValue ?? row.textValue;
      if (value != null && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map && decoded['list'] is List) {
            perkGrants[perkId]![grantType] = decoded['list'];
          } else {
            perkGrants[perkId]![grantType] = decoded;
          }
        } catch (_) {
          perkGrants[perkId]![grantType] = value;
        }
      }
    }

    // Write each perk's selections to hero_config
    for (final entry in perkGrants.entries) {
      final perkId = entry.key;
      final selections = entry.value;

      if (selections.isNotEmpty) {
        await _config.setConfigValue(
          heroId: heroId,
          key: HeroConfigKeys.perkSelections(perkId),
          value: selections,
        );
      }
    }

    // Delete legacy keys
    for (final key in keysToDelete) {
      await _db.deleteHeroValue(heroId: heroId, key: key);
    }
  }

  /// Migrate legacy perk_abilities.* keys to source-scoped ability entries.
  Future<void> _migrateLegacyPerkAbilityGrants(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    for (final row in rows) {
      if (!row.key.startsWith(HeroValueKeys.legacyPerkAbilitiesPrefix)) {
        continue;
      }

      final perkId = row.key.substring(
        HeroValueKeys.legacyPerkAbilitiesPrefix.length,
      );
      if (perkId.isEmpty) {
        await _db.deleteHeroValue(heroId: heroId, key: row.key);
        continue;
      }

      final legacyAbilityIds = _parseLegacyList(row);
      if (legacyAbilityIds.isNotEmpty) {
        final existingAbilityIds = (await _entries.listEntriesByType(
          heroId,
          'ability',
        ))
            .where((entry) =>
                entry.sourceType == 'perk' && entry.sourceId == perkId)
            .map((entry) => entry.entryId);
        final abilityIds = <String>{
          ...existingAbilityIds,
          ...legacyAbilityIds,
        };

        await _entries.addEntriesFromSource(
          heroId: heroId,
          sourceType: 'perk',
          sourceId: perkId,
          entryType: 'ability',
          entryIds: abilityIds,
          gainedBy: 'grant',
        );
      }

      await _db.deleteHeroValue(heroId: heroId, key: row.key);
    }
  }

  /// Migrate legacy class feature grants from hero_values to hero_entries.
  Future<void> _migrateLegacyClassFeatureGrants(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    // Migrate class_feature_abilities
    final abilitiesRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'class_feature_abilities' ||
          v.key.startsWith('class_feature.abilities'),
    );
    if (abilitiesRow != null) {
      final abilities = _parseJsonList(abilitiesRow);
      for (final ability in abilities) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ability',
          entryId: ability,
          sourceType: 'class_feature',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
        );
      }
    }

    // Migrate class_feature_skills
    final skillsRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'class_feature_skills' ||
          v.key.startsWith('class_feature.skills'),
    );
    if (skillsRow != null) {
      final skills = _parseJsonList(skillsRow);
      for (final skill in skills) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'skill',
          entryId: skill,
          sourceType: 'class_feature',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
        );
      }
    }

    // Migrate class_feature_stat_mods
    final statModsRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'class_feature_stat_mods' ||
          v.key.startsWith('class_feature.stat_mods'),
    );
    if (statModsRow != null) {
      final mods = _parseJsonMap(statModsRow);
      if (mods.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'stat_mod',
          entryId: 'legacy_class_feature_stat_mods',
          sourceType: 'class_feature',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
          payload: {'mods': mods},
        );
      }
    }

    // Migrate class_feature_resistances
    final resistancesRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'class_feature_resistances' ||
          v.key.startsWith('class_feature.resistances'),
    );
    if (resistancesRow != null) {
      final resistances = _parseJsonMap(resistancesRow);
      final immunities = resistances['immunities'];
      if (immunities != null) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'immunity',
          entryId: 'legacy_class_feature_immunities',
          sourceType: 'class_feature',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
          payload: {'immunities': _normalizeToList(immunities)},
        );
      }
      final weaknesses = resistances['weaknesses'];
      if (weaknesses != null) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'weakness',
          entryId: 'legacy_class_feature_weaknesses',
          sourceType: 'class_feature',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
          payload: {'weaknesses': _normalizeToList(weaknesses)},
        );
      }
    }
  }

  /// Migrate legacy kit grants from hero_values to hero_entries.
  Future<void> _migrateLegacyKitGrants(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    // Migrate kit.abilities or kit_grants.abilities
    final kitAbilitiesRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'kit.abilities' || v.key.startsWith('kit_grants.abilities'),
    );
    if (kitAbilitiesRow != null) {
      final abilities = _parseJsonList(kitAbilitiesRow);
      for (final ability in abilities) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ability',
          entryId: ability,
          sourceType: 'kit',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
        );
      }
    }

    // Migrate kit.equipment
    final kitEquipmentRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'kit.equipment' || v.key.startsWith('kit_grants.equipment'),
    );
    if (kitEquipmentRow != null) {
      final equipment = _parseJsonList(kitEquipmentRow);
      for (final item in equipment) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'equipment',
          entryId: item,
          sourceType: 'kit',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
        );
      }
    }

    // Migrate kit.signature_ability
    final signatureRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'kit.signature_ability' ||
          v.key.startsWith('kit_grants.signature'),
    );
    if (signatureRow != null) {
      final signatureAbility = signatureRow.textValue;
      if (signatureAbility != null && signatureAbility.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ability',
          entryId: signatureAbility,
          sourceType: 'kit',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
          payload: {'source': 'kit_signature'},
        );
      }
    }

    // Migrate kit.stat_bonuses
    final kitStatBonusesRow = rows.firstWhereOrNull(
      (v) =>
          v.key == 'kit.stat_bonuses' ||
          v.key.startsWith('kit_grants.stat_bonuses'),
    );
    if (kitStatBonusesRow != null) {
      final bonuses = _parseJsonMap(kitStatBonusesRow);
      if (bonuses.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'kit_stat_bonus',
          entryId: 'legacy_kit_stat_bonuses',
          sourceType: 'kit',
          sourceId: 'legacy_migration',
          gainedBy: 'grant',
          payload: bonuses,
        );
      }
    }
  }

  /// Migrate legacy equipment selection value rows into equipment config/entries.
  Future<void> _migrateLegacyEquipmentSelections(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    final legacyKeys = {
      HeroValueKeys.basicsEquipment,
      HeroValueKeys.legacyStrifeEquipmentIds,
    };

    for (final row in rows.where((value) => legacyKeys.contains(value.key))) {
      final ids = _parseLegacyNullableList(row);
      final compactIds = ids.whereType<String>().where((id) => id.isNotEmpty);

      if (ids.isNotEmpty) {
        await _config.setConfigValue(
          heroId: heroId,
          key: HeroConfigKeys.equipmentSlots,
          value: {'ids': ids},
        );
      }

      if (compactIds.isNotEmpty) {
        await _entries.addEntriesFromSource(
          heroId: heroId,
          sourceType: HeroEntrySourceTypes.equipment,
          sourceId: 'equipment_slots',
          entryType: HeroEntryTypes.equipment,
          entryIds: compactIds,
          gainedBy: HeroEntryGainedBy.choice,
        );
      }

      await _db.deleteHeroValue(heroId: heroId, key: row.key);
    }
  }

  /// Migrate legacy equipment bonuses from hero_values to hero_entries.
  /// This is a one-time migration for heroes created before the storage consolidation.
  Future<void> _migrateLegacyEquipmentBonuses(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    final legacyRow = rows.firstWhereOrNull(
      (v) => v.key == HeroValueKeys.legacyEquipmentBonuses,
    );
    if (legacyRow == null) return;

    // Check if we already have equipment_bonuses in hero_entries
    final existingEntries =
        await _entries.listEntriesByType(heroId, 'equipment_bonuses');
    if (existingEntries.isNotEmpty) {
      // Already migrated - just delete the legacy value
      await _db.deleteHeroValue(
        heroId: heroId,
        key: HeroValueKeys.legacyEquipmentBonuses,
      );
      return;
    }

    // Migrate the data from hero_values to hero_entries
    final raw = legacyRow.jsonValue ?? legacyRow.textValue;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: HeroEntryTypes.equipmentBonuses,
            entryId: 'combined_equipment_bonuses',
            sourceType: HeroEntrySourceTypes.kit,
            sourceId: 'combined',
            gainedBy: HeroEntryGainedBy.calculated,
            payload: {
              'stamina': _toIntOrZero(decoded['stamina']),
              'speed': _toIntOrZero(decoded['speed']),
              'stability': _toIntOrZero(decoded['stability']),
              'disengage': _toIntOrZero(decoded['disengage']),
              'melee_damage': _toIntOrZero(decoded['melee_damage']),
              'ranged_damage': _toIntOrZero(decoded['ranged_damage']),
              'melee_distance': _toIntOrZero(decoded['melee_distance']),
              'ranged_distance': _toIntOrZero(decoded['ranged_distance']),
            },
          );
        }
      } catch (_) {}
    }

    // Delete the legacy value after migration
    await _db.deleteHeroValue(
      heroId: heroId,
      key: HeroValueKeys.legacyEquipmentBonuses,
    );
  }

  /// Migrate legacy class feature stat bonuses from hero_values to hero_entries.
  Future<void> _migrateLegacyFeatureStatBonuses(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    final legacyRow = rows.firstWhereOrNull(
      (v) => v.key == HeroValueKeys.legacyFeatureStatBonuses,
    );
    if (legacyRow == null) return;

    final existingEntries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.featureStatBonus,
    );
    final existingSourceIds = existingEntries
        .where((entry) => entry.sourceType == HeroEntrySourceTypes.classFeature)
        .map((entry) => entry.sourceId)
        .toSet();

    final raw = legacyRow.jsonValue ?? legacyRow.textValue;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final featureEntry in decoded.entries) {
            final featureId = featureEntry.key.toString().trim();
            final payload = featureEntry.value;
            if (featureId.isEmpty || payload is! Map) continue;
            if (existingSourceIds.contains(featureId)) continue;

            await _entries.addEntry(
              heroId: heroId,
              entryType: HeroEntryTypes.featureStatBonus,
              entryId: '${featureId}_stat_bonus',
              sourceType: HeroEntrySourceTypes.classFeature,
              sourceId: featureId,
              gainedBy: HeroEntryGainedBy.grant,
              payload: {
                for (final entry in payload.entries)
                  entry.key.toString(): entry.value,
              },
            );
          }
        }
      } catch (_) {}
    }

    await _db.deleteHeroValue(
      heroId: heroId,
      key: HeroValueKeys.legacyFeatureStatBonuses,
    );
  }

  int _toIntOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Migrate class feature selections from hero_values to hero_config.
  Future<void> _migrateClassFeatureSelections(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    // Check for legacy class feature selections in hero_values
    final selectionsRow = rows.firstWhereOrNull(
      (v) => v.key == 'strife.class_feature_selections',
    );
    if (selectionsRow != null) {
      final raw = selectionsRow.jsonValue ?? selectionsRow.textValue;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            // Already stored in hero_config via normal flow, but ensure
            // we migrate to the new config key if needed
            await _config.setConfigValue(
              heroId: heroId,
              key: 'class_feature.selections',
              value: Map<String, dynamic>.from(decoded),
            );
          }
        } catch (_) {
          // Ignore parse errors
        }
      }
    }
  }

  /// Migrate subclass_key from hero_config to hero_entries.
  /// These keys belong in hero_entries as entry_type='subclass', not config.
  Future<void> _migrateSubclassKeyToEntries(String heroId) async {
    // Check for subclass keys in config that should be in entries
    final configKeys = [
      'class_feature.subclass_key',
      'strife.class_feature.subclass_key',
      'strife.subclass_key',
    ];

    for (final configKey in configKeys) {
      final config = await _config.getConfigValue(heroId, configKey);
      if (config == null) continue;

      final subclassKey = config['key']?.toString();
      if (subclassKey == null || subclassKey.isEmpty) continue;

      // Check if we already have a subclass entry
      final existingSubclass =
          await _db.getSingleHeroEntryId(heroId, 'subclass');
      if (existingSubclass == null) {
        // Migrate to hero_entries
        await _db.upsertHeroEntry(
          heroId: heroId,
          entryType: 'subclass',
          entryId: subclassKey,
          sourceType: 'manual_choice',
          sourceId: '',
          gainedBy: 'choice',
        );
      }

      // Note: We don't delete strife.subclass_key here as it's still valid for the strife creator
      // Only class_feature.* and strife.class_feature.* are banned
    }
  }

  // ===========================================================================
  // PHASE 3: CLEANUP BANNED CONFIG KEYS
  // ===========================================================================

  /// Remove legacy config keys that should not exist in hero_config.
  Future<void> _removeBannedConfigKeys(String heroId) async {
    for (final key in _bannedConfigKeys) {
      await _config.removeConfigKey(heroId, key);
    }
  }

  // ===========================================================================
  // PHASE 5: CLEANUP BANNED ENTRY TYPES
  // ===========================================================================

  /// Remove entry types that should not exist in hero_entries (computed values).
  Future<void> _removeBannedEntryTypes(String heroId) async {
    for (final entryType in _bannedEntryTypes) {
      await (_db.delete(_db.heroEntries)
            ..where(
                (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
          .go();
    }
  }

  List<String> _parseJsonList(db.HeroValue row) {
    final raw = row.jsonValue ?? row.textValue;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (decoded is Map && decoded['list'] is List) {
        return (decoded['list'] as List)
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  List<String> _parseLegacyList(db.HeroValue row) {
    final raw = row.jsonValue ?? row.textValue;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['list'] is List) {
        return _normalizeToList(decoded['list']);
      }
      if (decoded is Map && decoded['ids'] is List) {
        return _normalizeToList(decoded['ids']);
      }
      return _normalizeToList(decoded);
    } catch (_) {
      return [raw].where((value) => value.isNotEmpty).toList();
    }
  }

  List<String?> _parseLegacyNullableList(db.HeroValue row) {
    final raw = row.jsonValue ?? row.textValue;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['ids'] is List) {
        return (decoded['ids'] as List)
            .map((value) => value?.toString())
            .toList();
      }
      if (decoded is List) {
        return decoded.map((value) => value?.toString()).toList();
      }
    } catch (_) {
      return [raw];
    }
    return const [];
  }

  Map<String, dynamic> _parseJsonMap(db.HeroValue row) {
    final raw = row.jsonValue ?? row.textValue;
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return const {};
  }

  List<String> _normalizeToList(dynamic value) {
    if (value == null) return const [];
    if (value is String) return [value];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<void> _removeBannedValues(String heroId) async {
    final rows = await _db.getHeroValues(heroId);

    final toDelete = rows
        .where((v) => HeroValueKeys.isBanned(v.key))
        .map((v) => v.id)
        .toList();
    if (toDelete.isNotEmpty) {
      await (_db.delete(_db.heroValues)..where((t) => t.id.isIn(toDelete)))
          .go();
    }
  }

  // _ensureBasics is now handled by _migrateBasicsToEntries and _migrateFaithToEntries

  Future<void> _ensureAncestrySelections(String heroId) async {
    // Selected traits (legacy hero_values)
    final values = await _db.getHeroValues(heroId);
    final traitValue =
        values.firstWhereOrNull((v) => v.key == 'ancestry.selected_traits');
    final selectedTraits = <String>[];
    if (traitValue != null) {
      final raw = traitValue.jsonValue ?? traitValue.textValue;
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            selectedTraits.addAll(decoded.map((e) => e.toString()));
          } else if (decoded is Map && decoded['list'] is List) {
            selectedTraits
                .addAll((decoded['list'] as List).map((e) => e.toString()));
          }
        } catch (_) {}
      }
    }
    if (selectedTraits.isNotEmpty) {
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'ancestry',
        sourceId: 'ancestry',
        entryType: 'ancestry_trait',
        entryIds: selectedTraits,
        gainedBy: 'choice',
      );
    }
  }

  Future<void> _ensureCultureSelections(String heroId) async {
    final config = await _config.getConfigMap(heroId);
    Future<void> reconcileSelection({
      required String configKey,
      required String entryType,
      required String sourceId,
    }) async {
      // Absence preserves legacy rows. Once the current-format key exists,
      // including with a null selection, it is the sole authority for this
      // exact editor-owned source.
      if (!config.containsKey(configKey)) return;
      final value = config[configKey];
      final selected = value?['selection']?.toString().trim();
      await _entries.addEntriesFromSource(
        heroId: heroId,
        entryType: entryType,
        entryIds: selected == null || selected.isEmpty ? const [] : [selected],
        sourceType: HeroEntrySourceTypes.culture,
        sourceId: sourceId,
        gainedBy: HeroEntryGainedBy.choice,
      );
    }

    await reconcileSelection(
      configKey: HeroConfigKeys.cultureLanguageSelection,
      entryType: HeroEntryTypes.language,
      sourceId: HeroEntrySourceIds.cultureLanguages,
    );
    await reconcileSelection(
      configKey: HeroConfigKeys.cultureEnvironmentSkill,
      entryType: HeroEntryTypes.skill,
      sourceId: HeroEntrySourceIds.cultureEnvironment,
    );
    await reconcileSelection(
      configKey: HeroConfigKeys.cultureOrganisationSkill,
      entryType: HeroEntryTypes.skill,
      sourceId: HeroEntrySourceIds.cultureOrganisation,
    );
    await reconcileSelection(
      configKey: HeroConfigKeys.cultureUpbringingSkill,
      entryType: HeroEntryTypes.skill,
      sourceId: HeroEntrySourceIds.cultureUpbringing,
    );
  }

  Future<void> _ensureCareerSelections(String heroId) async {
    final config = await _config.getConfigMap(heroId);
    Future<void> reconcileList(String configKey, String entryType) async {
      if (!config.containsKey(configKey)) return;
      final value = config[configKey];
      final rawIds = value?['list'];
      final ids = rawIds is List
          ? rawIds
              .map((value) => value?.toString().trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
          : const <String>[];
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: HeroEntrySourceTypes.career,
        sourceId: HeroEntrySourceIds.careerChoice,
        entryType: entryType,
        entryIds: ids,
        gainedBy: HeroEntryGainedBy.choice,
      );
    }

    await reconcileList(
      HeroConfigKeys.careerChosenSkills,
      HeroEntryTypes.skill,
    );
    await reconcileList(
      HeroConfigKeys.careerChosenPerks,
      HeroEntryTypes.perk,
    );
    await reconcileList(
      HeroConfigKeys.careerChosenLanguages,
      HeroEntryTypes.language,
    );
  }

  Future<void> _ensureStrifeSelections(String heroId) async {
    final config = await _config.getConfigMap(heroId);
    Future<void> addSelections(
      String key,
      String entryType,
    ) async {
      final map = config[key];
      // Absent config: this editor never wrote its slots, so leave existing
      // rows alone and let the legacy fallback handle them.
      if (map == null) return;
      final ids = map.values
          .map((v) => v?.toString())
          .nonNulls
          .where((e) => e.isNotEmpty)
          .toList();
      // A present config is authoritative for this editor's slots, including an
      // explicit clear. Do not skip when empty: reconcile the source to exactly
      // `ids` so a cleared selection is not resurrected. `addEntriesFromSource`
      // replaces the source, so empty ids clear it.

      // Remove legacy rows written with mismatched source metadata to avoid duplicates
      await _entries.removeEntriesFromSource(
        heroId: heroId,
        sourceType: 'class',
        sourceId: 'strife_creator',
        entryType: entryType,
      );

      // Rebuild strife selections using the same source metadata as the creator save path
      await _entries.addEntriesFromSource(
        heroId: heroId,
        sourceType: 'manual_choice',
        sourceId: entryType,
        entryType: entryType,
        entryIds: ids,
        gainedBy: 'choice',
      );
    }

    await addSelections('strife.ability_selections', 'ability');
    await addSelections('strife.skill_selections', 'skill');
    await addSelections('strife.perk_selections', 'perk');
  }

  Future<void> _ensureEquipment(String heroId) async {
    final config = await _config.getConfigMap(heroId);
    if (!config.containsKey(HeroConfigKeys.equipmentSlots)) return;
    final value = config[HeroConfigKeys.equipmentSlots];
    final slots = value?['ids'];
    final ids = slots is List
        ? slots
            .map((value) => value?.toString().trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
        : const <String>[];
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.equipment,
      sourceId: HeroEntrySourceIds.equipmentSlots,
      entryType: HeroEntryTypes.equipment,
      entryIds: ids,
      gainedBy: HeroEntryGainedBy.choice,
    );
  }

  Future<void> _dedupe(String heroId) async {
    final rows = await _entries.listAllEntriesForHero(heroId);
    final seen = <String>{};
    final dupIds = <int>[];
    for (final r in rows) {
      final key =
          '${r.entryType}|${r.entryId}|${r.sourceType}|${r.sourceId}|${r.gainedBy}';
      if (!seen.add(key)) dupIds.add(r.id);
    }
    if (dupIds.isNotEmpty) {
      await (_db.delete(_db.heroEntries)..where((t) => t.id.isIn(dupIds))).go();
    }
  }

  // ===========================================================================
  // PHASE 4: VALIDATION AND CLEANUP
  // ===========================================================================

  /// Remove invalid hero_entries that have missing or invalid data.
  /// An entry is invalid if:
  /// - entry_type is null or empty
  /// - entry_id is null or empty
  Future<void> _removeInvalidEntries(String heroId) async {
    final rows = await _entries.listAllEntriesForHero(heroId);
    final invalidIds = <int>[];

    for (final entry in rows) {
      // Check for missing entry_type
      if (entry.entryType.isEmpty) {
        invalidIds.add(entry.id);
        continue;
      }

      // Check for missing entry_id
      if (entry.entryId.isEmpty) {
        invalidIds.add(entry.id);
        continue;
      }

      // Check for obviously invalid IDs (just whitespace, special chars only)
      final trimmedId = entry.entryId.trim();
      if (trimmedId.isEmpty ||
          trimmedId == 'null' ||
          trimmedId == 'undefined') {
        invalidIds.add(entry.id);
        continue;
      }
    }

    if (invalidIds.isNotEmpty) {
      await (_db.delete(_db.heroEntries)..where((t) => t.id.isIn(invalidIds)))
          .go();
    }
  }

  /// Deduplicate hero_config rows - ensure only one row per config_key.
  /// Keeps the most recently updated row when duplicates exist.
  Future<void> _dedupeConfig(String heroId) async {
    final rows = await (_db.select(_db.heroConfig)
          ..where((t) => t.heroId.equals(heroId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    final seen = <String>{};
    final dupIds = <int>[];

    for (final row in rows) {
      if (!seen.add(row.configKey)) {
        // This is a duplicate - mark for deletion
        dupIds.add(row.id);
      }
    }

    if (dupIds.isNotEmpty) {
      await (_db.delete(_db.heroConfig)..where((t) => t.id.isIn(dupIds))).go();
    }
  }

  // ===========================================================================
  // PHASE 5: AGGREGATE RECOMPUTATION
  // ===========================================================================

  /// Recompute resistances.damage aggregate from hero_entries.
  ///
  /// Collects all resistance entries (immunity/weakness) from hero_entries
  /// and writes the aggregate to hero_values as resistances.damage.
  ///
  /// Delegates to DamageResistanceService for centralized logic.
  ///
  /// This is the SOURCE OF TRUTH for damage resistances:
  /// - hero_entries stores individual grants with source metadata
  /// - hero_values stores the computed aggregate for runtime use
  Future<void> _recomputeResistances(String heroId) async {
    await _resistanceService.recomputeAggregateResistances(heroId);
  }
}
