import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart' as db;
import '../models/damage_resistance_model.dart';
import '../models/hero_assembled_model.dart';
import '../models/stat_modification_model.dart';
import '../repositories/hero_entry_repository.dart';
import 'hero_config_service.dart';

/// Assembles a unified hero view from the three storage layers:
/// - hero_values → numeric state (stats, stamina, recoveries, conditions, etc.)
/// - hero_entries → all content (abilities, skills, perks, equipment, etc.)
/// - hero_config → selections/choices metadata
/// 
/// This service is IDEMPOTENT - calling assemble() multiple times
/// produces identical results.
class HeroAssemblyService {
  HeroAssemblyService(this._db)
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;

  /// Keys that should remain in hero_values (numeric/state).
  /// All other keys should be removed by migration.
  static const _allowedValuePrefixes = <String>[
    'stats.',
    'stamina.',
    'recoveries.',
    'resistances.',
    'conditions.',
    'potency.',
    'score.',
    'projects.',
    'heroic.',
    'surges.',
    'mods.',
    'dynamic_modifiers',
    'complication.tokens',
    'complication.tokens_current',
    'complication.recovery_bonus',
    'downtime.story_project_points',
  ];

  /// Build a HeroAssembly model from the database.
  /// 
  /// This method:
  /// 1. Loads hero_values for numeric/state data
  /// 2. Loads hero_entries for all content
  /// 3. Loads hero_config for selection metadata
  /// 4. Merges stat_mods from all sources
  /// 5. Builds resistance aggregates
  /// 6. Groups entries by source and type
  Future<HeroAssembly?> assemble(String heroId) async {
    final heroRow = await (_db.select(_db.heroes)
          ..where((t) => t.id.equals(heroId)))
        .getSingleOrNull();
    if (heroRow == null) return null;

    final values = await _db.getHeroValues(heroId);
    final entries = await _entries.listAllEntriesForHero(heroId);
    final config = await _config.getConfigMap(heroId);

    // === VALUE HELPERS ===
    int intVal(String key, [int def = 0]) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v == null) return def;
      if (v.value != null) return v.value!;
      if (v.textValue != null) return int.tryParse(v.textValue!) ?? def;
      return def;
    }

    List<String> listVal(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      if (v == null) return const [];
      final raw = v.jsonValue ?? v.textValue;
      if (raw == null) return const [];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map && decoded['list'] is List) {
          return (decoded['list'] as List).map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return const [];
    }

    Map<String, int> mapIntVal(String key) {
      final v = values.firstWhereOrNull((e) => e.key == key);
      final raw = v?.jsonValue ?? v?.textValue;
      if (raw == null) return const {};
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((k, v) =>
              MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
        }
      } catch (_) {}
      return const {};
    }

    // === GROUP ENTRIES BY TYPE ===
    final byType = groupBy(entries, (e) => e.entryType);

    // === EXTRACT IDENTITY FROM ENTRIES ===
    String? extractSingleId(String entryType) {
      final list = byType[entryType];
      if (list == null || list.isEmpty) return null;
      return list.first.entryId;
    }

    List<String> extractIds(String entryType) {
      final list = byType[entryType];
      if (list == null || list.isEmpty) return const [];
      return list.map((e) => e.entryId).toList();
    }

    final classId = extractSingleId('class');
    final subclassId = extractSingleId('subclass');
    final ancestryId = extractSingleId('ancestry');
    final careerId = extractSingleId('career');
    final kitId = extractSingleId('kit');
    final deityId = extractSingleId('deity');
    final domainIds = extractIds('domain');

    // === GROUP ENTRIES BY SOURCE ===
    Map<String, List<db.HeroEntry>> groupBySource(List<db.HeroEntry> list) {
      return groupBy(list, (e) => '${e.sourceType}:${e.sourceId}'.trim());
    }

    final allEntriesBySource = groupBySource(entries);
    
    // === CONTENT LISTS ===
    final skills = byType['skill'] ?? const [];
    final perks = byType['perk'] ?? const [];
    final languages = byType['language'] ?? const [];
    final abilities = byType['ability'] ?? const [];
    final titles = byType['title'] ?? const [];
    final equipment = byType['equipment'] ?? const [];
    final traits = byType['ancestry_trait'] ?? const [];
    final classFeatures = byType['class_feature'] ?? const [];
    final conditionImmunities = byType['condition_immunity'] ?? const [];
    final featureStatBonuses = byType['feature_stat_bonus'] ?? const [];

    // === GROUPED BY SOURCE ===
    final abilitiesBySource = groupBySource(abilities);
    final skillsBySource = groupBySource(skills);
    final perksBySource = groupBySource(perks);
    final featuresBySource = groupBySource(classFeatures);
    final languagesBySource = groupBySource(languages);
    final equipmentBySource = groupBySource(equipment);

    // === STAT MODIFICATIONS (merged from all sources) ===
    final statModEntries = byType['stat_mod'] ?? const [];
    final statMods = _mergeStatMods(statModEntries);
    final statModsBySource = groupBySource(statModEntries);

    // === RESISTANCES ===
    final resistanceEntries = <db.HeroEntry>[
      ...byType['resistance'] ?? const <db.HeroEntry>[],
      ...byType['immunity'] ?? const <db.HeroEntry>[],
      ...byType['weakness'] ?? const <db.HeroEntry>[],
    ];
    final resistancesBySource = groupBySource(resistanceEntries);
    final heroLevel = intVal('basics.level', 1);
    final resistances = _loadResistances(values, resistanceEntries, heroLevel);

    return HeroAssembly(
      heroId: heroRow.id,
      name: heroRow.name,
      // Identity
      classId: classId,
      subclassId: subclassId,
      ancestryId: ancestryId,
      careerId: careerId,
      kitId: kitId,
      deityId: deityId,
      domainIds: domainIds,
      // Numeric/state
      stats: {
        'might': intVal('stats.might'),
        'agility': intVal('stats.agility'),
        'reason': intVal('stats.reason'),
        'intuition': intVal('stats.intuition'),
        'presence': intVal('stats.presence'),
        'size': intVal('stats.size'),
        'speed': intVal('stats.speed'),
        'disengage': intVal('stats.disengage'),
        'stability': intVal('stats.stability'),
      },
      stamina: {
        'current': intVal('stamina.current'),
        'max': intVal('stamina.max'),
        'temp': intVal('stamina.temp'),
        'winded': intVal('stamina.winded'),
        'dying': intVal('stamina.dying'),
      },
      recoveries: {
        'current': intVal('recoveries.current'),
        'value': intVal('recoveries.value'),
        'max': intVal('recoveries.max'),
      },
      conditions: listVal('conditions.list'),
      potency: {
        'strong': intVal('potency.strong'),
        'average': intVal('potency.average'),
        'weak': intVal('potency.weak'),
      },
      counters: {
        'wealth': intVal('score.wealth'),
        'renown': intVal('score.renown'),
        'victories': intVal('score.victories'),
        'exp': intVal('score.exp'),
        'surges': intVal('surges.current'),
        'project_points': intVal('projects.points'),
        'heroic_current': intVal('heroic.current'),
      },
      userMods: mapIntVal('mods.map'),
      level: intVal('basics.level', 1),
      // Resistances
      resistances: resistances,
      resistanceEntries: resistanceEntries,
      // Stat mods
      statMods: statMods,
      statModsBySource: statModsBySource,
      // Content entries
      skills: skills,
      perks: perks,
      languages: languages,
      abilities: abilities,
      titles: titles,
      equipment: equipment,
      traits: traits,
      classFeatures: classFeatures,
      conditionImmunities: conditionImmunities,
      featureStatBonuses: featureStatBonuses,
      // Grouped by source
      abilitiesBySource: abilitiesBySource,
      skillsBySource: skillsBySource,
      perksBySource: perksBySource,
      featuresBySource: featuresBySource,
      languagesBySource: languagesBySource,
      equipmentBySource: equipmentBySource,
      resistancesBySource: resistancesBySource,
      // Raw data
      config: config,
      entriesBySource: allEntriesBySource,
      entriesByType: byType,
    );
  }

  /// Merge stat modifications from all hero_entries with entry_type='stat_mod'.
  /// 
  /// Supports two formats:
  /// 1. Batch format: { "mods": { "speed": 1, "stability": -2 } }
  /// 2. Individual format (entryId = stat name): { "mods": [{ "value": 1, "source": "..." }] }
  HeroStatModifications _mergeStatMods(List<db.HeroEntry> entries) {
    final mods = <String, List<StatModification>>{};

    for (final entry in entries) {
      final defaultSource = '${entry.sourceType}:${entry.sourceId}';
      
      if (entry.payload == null) continue;
      
      try {
        final payload = jsonDecode(entry.payload!);
        if (payload is! Map) continue;

        final modsData = payload['mods'];
        
        // Format 2: Individual entry where entryId is the stat name
        // Payload: { "mods": [{ "value": 1, "source": "...", "dynamicValue": "level", "perEchelon": true, ... }] }
        if (modsData is List) {
          final stat = entry.entryId.toLowerCase();
          for (final modItem in modsData) {
            if (modItem is! Map) continue;
            // Use fromJson to parse all fields including dynamic ones
            final mod = StatModification.fromJson(
              Map<String, dynamic>.from(modItem),
              defaultSource: defaultSource,
            );
            // Skip mods with no base value and no dynamic properties
            if (mod.baseValue == 0 && !mod.isDynamic) continue;
            mods.putIfAbsent(stat, () => []);
            mods[stat]!.add(mod);
          }
          continue;
        }

        // Format 1: Batch format { "mods": { "speed": 1, ... } } or just { "speed": 1, ... }
        final modsMap = modsData ?? payload;
        if (modsMap is! Map) continue;

        for (final statEntry in modsMap.entries) {
          final stat = statEntry.key.toString().toLowerCase();
          final value = (statEntry.value is num) 
              ? (statEntry.value as num).toInt() 
              : int.tryParse(statEntry.value.toString()) ?? 0;
          
          if (value == 0) continue;
          
          mods.putIfAbsent(stat, () => []);
          mods[stat]!.add(StaticStatModification(value: value, source: defaultSource));
        }
      } catch (_) {
        // Skip malformed entries
      }
    }

    return HeroStatModifications(modifications: mods);
  }

  /// Load resistances aggregate from hero_values.
  /// Load resistances from hero_values.
  /// 
  /// The resistances now store dynamic metadata (dynamicImmunity, immunityPerEchelon, etc.)
  /// which is calculated at display time using DamageResistance.netValueAtLevel(heroLevel).
  HeroDamageResistances _loadResistances(
    List<db.HeroValue> values,
    List<db.HeroEntry> resistanceEntries,
    int heroLevel,
  ) {
    // Load resistances from hero_values - they already contain dynamic metadata
    final baseValue = values.firstWhereOrNull((v) => v.key == 'resistances.damage');
    if (baseValue?.jsonValue == null && baseValue?.textValue == null) {
      return HeroDamageResistances.empty;
    }
    try {
      final jsonStr = baseValue!.jsonValue ?? baseValue.textValue!;
      return HeroDamageResistances.fromJsonString(jsonStr);
    } catch (_) {
      return HeroDamageResistances.empty;
    }
  }

  /// Delete legacy hero_values rows that no longer belong after migration.
  Future<int> cleanLegacyHeroValues(String heroId) async {
    final rows = await _db.getHeroValues(heroId);
    final idsToDelete = <int>[];
    for (final row in rows) {
      final key = row.key;
      final allowed = _allowedValuePrefixes
          .any((prefix) => key.startsWith(prefix));
      if (!allowed) {
        idsToDelete.add(row.id);
      }
    }
    if (idsToDelete.isEmpty) return 0;
    return (_db.delete(_db.heroValues)
          ..where((t) => t.id.isIn(idsToDelete)))
        .go();
  }

  // ===========================================================================
  // COMPONENT RESOLVER
  // ===========================================================================

  /// Resolve entry_ids to component data from the components table.
  /// Returns a map of entry_id -> Component.
  Future<Map<String, db.Component>> resolveComponents(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return const {};
    
    final components = await (_db.select(_db.components)
          ..where((t) => t.id.isIn(entryIds)))
        .get();
    
    return {for (final c in components) c.id: c};
  }

  /// Resolve a single entry_id to component data.
  Future<db.Component?> resolveComponent(String entryId) async {
    return (_db.select(_db.components)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
  }

  /// Resolve all abilities in an assembly to component data.
  Future<Map<String, db.Component>> resolveAbilities(HeroAssembly assembly) {
    return resolveComponents(assembly.abilityIds);
  }

  /// Resolve all skills in an assembly to component data.
  Future<Map<String, db.Component>> resolveSkills(HeroAssembly assembly) {
    return resolveComponents(assembly.skillIds);
  }

  /// Resolve all perks in an assembly to component data.
  Future<Map<String, db.Component>> resolvePerks(HeroAssembly assembly) {
    return resolveComponents(assembly.perkIds);
  }

  /// Resolve all equipment in an assembly to component data.
  Future<Map<String, db.Component>> resolveEquipment(HeroAssembly assembly) {
    return resolveComponents(assembly.equipmentIds);
  }
}
