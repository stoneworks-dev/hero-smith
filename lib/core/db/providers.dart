import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart' as db;
import 'database_maintenance.dart';
import '../seed/asset_seeder.dart';
import '../repositories/component_drift_repository.dart';
import '../repositories/hero_repository.dart';
import '../repositories/hero_entry_repository.dart';
import '../repositories/downtime_repository.dart';
import '../models/component.dart' as model;
import '../services/perk_grants_service.dart';
import '../services/title_grants_service.dart';
import '../services/ability_resolver_service.dart';
import '../services/damage_resistance_service.dart';
import '../services/hero_config_service.dart';
import '../services/hero_assembly_service.dart';
import '../services/treasure_bonus_service.dart';
import '../models/hero_assembled_model.dart';

// Core singletons
final appDatabaseProvider =
    Provider<db.AppDatabase>((ref) => db.AppDatabase.instance);
final componentRepositoryProvider = Provider<ComponentDriftRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return ComponentDriftRepository(db);
});

final heroEntryRepositoryProvider = Provider<HeroEntryRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroEntryRepository(db);
});

final heroConfigServiceProvider = Provider<HeroConfigService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroConfigService(db);
});

final heroAssemblyServiceProvider = Provider<HeroAssemblyService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroAssemblyService(db);
});

final treasureBonusServiceProvider = Provider<TreasureBonusService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return TreasureBonusService(db);
});

final perkGrantsServiceProvider = Provider<PerkGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return PerkGrantsService(db);
});

final titleGrantsServiceProvider = Provider<TitleGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return TitleGrantsService(db);
});

final abilityResolverServiceProvider = Provider<AbilityResolverService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return AbilityResolverService(db);
});

final damageResistanceServiceProvider = Provider<DamageResistanceService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return DamageResistanceService(db);
});

final heroRepositoryProvider = Provider<HeroRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroRepository(db);
});

final downtimeRepositoryProvider = Provider<DowntimeRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return DowntimeRepository(db);
});

// Toggle for auto-seeding on startup. Tests can override this to false.
final autoSeedEnabledProvider = Provider<bool>((ref) => true);

// Seed once on startup if DB is empty. Safe to call repeatedly.
final seedOnStartupProvider = FutureProvider<void>((ref) async {
  final enabled = ref.read(autoSeedEnabledProvider);
  if (!enabled) return;
  final db = ref.read(appDatabaseProvider);
  await AssetSeeder.seedFromManifestIfEmpty(db);
  // Always reseed perks to ensure all perks are available
  // This fixes cases where perks.json was updated after initial DB creation
  await DatabaseMaintenance.reseedPerks(db);
});

// Data streams
final allComponentsProvider = StreamProvider<List<model.Component>>((ref) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchAll();
});

final componentsByTypeProvider = StreamProvider.family<List<model.Component>, String>((ref, type) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchByType(type);
});

// Heroes data streams
final allHeroesProvider = StreamProvider((ref) {
  final repo = ref.read(heroRepositoryProvider);
  return repo.watchAllHeroes();
});

// Enriched hero summaries for the list page
final heroSummariesProvider = StreamProvider<List<HeroSummary>>((ref) {
  final repo = ref.read(heroRepositoryProvider);
  return repo.watchSummaries();
});

// Hero entries/config/value watchers
final heroEntriesProvider =
    StreamProvider.family<List<db.HeroEntry>, String>((ref, heroId) {
  final repo = ref.read(heroEntryRepositoryProvider);
  return repo.watchEntries(heroId);
});

/// Provider to get entry IDs of a specific type for a hero.
/// Useful for pickers to exclude already-saved entries.
/// Args: (heroId: String, entryType: String)
final heroEntryIdsByTypeProvider = Provider.family<Set<String>,
    ({String heroId, String entryType})>((ref, args) {
  final entriesAsync = ref.watch(heroEntriesProvider(args.heroId));
  // Use valueOrNull to prevent flicker - return empty set only on error or initial load
  final entries = entriesAsync.valueOrNull;
  if (entries == null) return const <String>{};
  return entries
      .where((e) => e.entryType == args.entryType)
      .map((e) => e.entryId)
      .toSet();
});

final heroConfigProvider =
    StreamProvider.family<List<db.HeroConfigData>, String>((ref, heroId) {
  final service = ref.read(heroConfigServiceProvider);
  return service.watchConfig(heroId);
});

final heroValuesProvider =
    StreamProvider.family<List<db.HeroValue>, String>((ref, heroId) {
  final dbInstance = ref.read(appDatabaseProvider);
  return dbInstance.watchHeroValues(heroId);
});

final heroRowProvider =
    StreamProvider.family<db.Heroe?, String>((ref, heroId) {
  final dbInstance = ref.read(appDatabaseProvider);
  return (dbInstance.select(dbInstance.heroes)
        ..where((t) => t.id.equals(heroId)))
      .watchSingleOrNull();
});

/// Derived hero assembly that reacts to entries/config/values changes.
final heroAssemblyProvider =
    FutureProvider.family<HeroAssembly?, String>((ref, heroId) async {
  // Invalidate on upstream changes
  ref.watch(heroEntriesProvider(heroId));
  ref.watch(heroConfigProvider(heroId));
  ref.watch(heroValuesProvider(heroId));
  ref.watch(heroRowProvider(heroId));
  final svc = ref.read(heroAssemblyServiceProvider);
  return svc.assemble(heroId);
});

/// Provider to watch the highest stamina bonus from armor imbuements.
/// Uses "take highest" logic - only the highest bonus applies.
/// Now includes equipped treasure stamina bonuses with proper stacking.
final heroTreasureHighestBonusStaminaProvider =
    StreamProvider.family<int, String>((ref, heroId) {
  final svc = ref.read(treasureBonusServiceProvider);
  return svc.watchCombinedTreasureStamina(heroId);
});

/// Provider to watch all equipped treasure bonuses (stamina, stability, speed, immunities).
/// Returns full EquippedTreasureBonuses for integrating into HeroMainStats.
final heroEquippedTreasureBonusesProvider =
    StreamProvider.family<EquippedTreasureBonuses, String>((ref, heroId) {
  final svc = ref.read(treasureBonusServiceProvider);
  return svc.watchEquippedTreasureBonuses(heroId);
});

/// Provider to fetch an ability by name (used for perk grants lookup)
final abilityByNameProvider = FutureProvider.family<model.Component?, String>((ref, rawName) async {
  final name = rawName.trim();
  if (name.isEmpty) return null;

  final abilities = await ref.read(componentsByTypeProvider('ability').future);

  // Try exact name match first
  final exactMatch = _findAbility(abilities, (c) => c.name == name);
  if (exactMatch != null && exactMatch.id.isNotEmpty) {
    return exactMatch;
  }

  // Try normalized (case/punctuation-insensitive) name match
  final normalizedTarget = _normalizeAbilityName(name);
  final normalizedMatch = _findAbility(
    abilities,
    (c) => _normalizeAbilityName(c.name) == normalizedTarget,
  );
  if (normalizedMatch != null && normalizedMatch.id.isNotEmpty) {
    return normalizedMatch;
  }
  
  // Try ID match (slugified name) - perk/title abilities use ID like "arcane_trick"
  final slugId = _slugifyForId(name);
  final idMatch = _findAbility(abilities, (c) => c.id == slugId);
  if (idMatch != null) {
    return idMatch;
  }

  // Fallback: load from supplemental ability JSON files
  final jsonFallback = await _loadAbilityFromJsonFiles(name);
  if (jsonFallback != null) {
    return jsonFallback;
  }

  return null;
});

/// Supplemental ability JSON files to search when ability not in DB
const _supplementalAbilityJsonFiles = [
  'data/abilities/perk_abilities.json',
  'data/abilities/titles_abilities.json',
  'data/abilities/complication_abilities.json',
  'data/abilities/ancestry_abilities.json',
  'data/abilities/kit_abilities.json',
];

/// Cache for loaded supplemental abilities - keyed by both name and id
Map<String, model.Component>? _supplementalAbilitiesCache;

/// Load an ability by name or id from JSON files (fallback when not in DB)
Future<model.Component?> _loadAbilityFromJsonFiles(String nameOrId) async {
  // Build cache if not already built
  _supplementalAbilitiesCache ??= await _buildSupplementalAbilitiesCache();
  
  final cache = _supplementalAbilitiesCache!;
  
  // Try exact match (works for both name and id keys)
  if (cache.containsKey(nameOrId)) {
    return cache[nameOrId];
  }
  
  // Try normalized name match
  final normalized = _normalizeAbilityName(nameOrId);
  for (final entry in cache.entries) {
    if (_normalizeAbilityName(entry.key) == normalized) {
      return entry.value;
    }
  }
  
  // Try slugified id match
  final slugified = _slugifyForId(nameOrId);
  if (cache.containsKey(slugified)) {
    return cache[slugified];
  }
  
  return null;
}

Future<Map<String, model.Component>> _buildSupplementalAbilitiesCache() async {
  final cache = <String, model.Component>{};
  
  for (final filePath in _supplementalAbilityJsonFiles) {
    try {
      final raw = await rootBundle.loadString(filePath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;
      
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['id']?.toString() ?? '';
        final name = map['name']?.toString() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        
        // Remove id, name, type from data - they go in Component fields
        final data = Map<String, dynamic>.from(map);
        data.remove('id');
        data.remove('name');
        data.remove('type');
        
        final component = model.Component(
          id: id,
          type: 'ability',
          name: name,
          data: data,
          source: 'json_fallback',
        );
        
        // Store by both name and id for flexible lookup
        cache[name] = component;
        cache[id] = component;
      }
    } catch (_) {
      // Ignore errors for individual files
    }
  }
  
  return cache;
}

String _slugifyForId(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[''']"), '')  // Remove apostrophes
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

model.Component? _findAbility(
  List<model.Component> abilities,
  bool Function(model.Component ability) predicate,
) {
  for (final ability in abilities) {
    if (predicate(ability)) {
      return ability;
    }
  }
  return null;
}

String _normalizeAbilityName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('\u2019', "'")
      .replaceAll('\u2018', "'")
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"');
}
