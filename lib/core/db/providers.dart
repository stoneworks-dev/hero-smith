import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart' as db;
import '../seed/asset_seeder.dart';
import '../repositories/component_drift_repository.dart';
import '../repositories/hero_repository.dart';
import '../repositories/hero_entry_repository.dart';
import '../repositories/downtime_repository.dart';
import '../models/component.dart' as model;
import '../services/perk_grants_service.dart';
import '../services/title_grants_service.dart';
import '../services/class_feature_grants_service.dart';
import '../services/kit_grants_service.dart';
import '../services/ability_resolver_service.dart';
import '../services/damage_resistance_service.dart';
import '../services/hero_config_service.dart';
import '../services/hero_duplicate_guard_service.dart';
import '../services/hero_mutation_service.dart';
import '../services/hero_assembly_service.dart';
import '../services/treasure_bonus_service.dart';
import '../services/treasure_grants_service.dart';
import '../services/items_catalog_service.dart';
import '../services/retainer_advancement_service.dart';
import '../repositories/retainer_repository.dart';
import '../models/retainer.dart';
import '../models/retainer_instance.dart';
import '../repositories/companion_repository.dart';
import '../models/companion.dart';
import '../models/companion_instance.dart';
import '../services/companion_advancement_service.dart';
import '../repositories/minion_repository.dart';
import '../models/minion.dart';
import '../models/minion_squad_instance.dart';
import '../models/hero_assembled_model.dart';
import '../../features/hero_builder/domain/hero_claim.dart';
import '../../features/hero_builder/domain/hero_conflict_index.dart';

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

final heroDuplicateGuardServiceProvider =
    Provider<HeroDuplicateGuardService>((ref) {
  return const HeroDuplicateGuardService();
});

final heroMutationServiceProvider = Provider<HeroMutationService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroMutationService(db);
});

final heroAssemblyServiceProvider = Provider<HeroAssemblyService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HeroAssemblyService(db);
});

final treasureBonusServiceProvider = Provider<TreasureBonusService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return TreasureBonusService(db);
});

final treasureGrantsServiceProvider = Provider<TreasureGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  final mutations = ref.read(heroMutationServiceProvider);
  return TreasureGrantsService(db, mutations: mutations);
});

final perkGrantsServiceProvider = Provider<PerkGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return PerkGrantsService(db);
});

final classFeatureGrantsServiceProvider =
    Provider<ClassFeatureGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  final mutations = ref.read(heroMutationServiceProvider);
  return ClassFeatureGrantsService(db, mutations: mutations);
});

final kitGrantsServiceProvider = Provider<KitGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  final mutations = ref.read(heroMutationServiceProvider);
  return KitGrantsService(db, mutations: mutations);
});

final titleGrantsServiceProvider = Provider<TitleGrantsService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return TitleGrantsService(db);
});

final abilityResolverServiceProvider = Provider<AbilityResolverService>((ref) {
  final db = ref.read(appDatabaseProvider);
  return AbilityResolverService(db);
});

final damageResistanceServiceProvider =
    Provider<DamageResistanceService>((ref) {
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

final itemsCatalogServiceProvider = Provider<ItemsCatalogService>((ref) {
  final db = ref.read(appDatabaseProvider);
  final repo = ref.read(componentRepositoryProvider);
  return ItemsCatalogService(db, repo);
});

// Toggle for auto-seeding on startup. Tests can override this to false.
final autoSeedEnabledProvider = Provider<bool>((ref) => true);

// Synchronize bundled content when data/content_manifest.json is newer.
final seedOnStartupProvider = FutureProvider<void>((ref) async {
  final enabled = ref.read(autoSeedEnabledProvider);
  if (!enabled) return;
  final db = ref.read(appDatabaseProvider);
  await AssetSeeder.seedBundledContentIfNeeded(db);
});

// Data streams
final allComponentsProvider = StreamProvider<List<model.Component>>((ref) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchAll();
});

final componentsByTypeProvider =
    StreamProvider.family<List<model.Component>, String>((ref, type) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchByType(type);
});

/// IDs whose retired rows may remain visible while editing an existing hero.
///
/// The hero creator overrides this with the current draft and persisted IDs.
/// Outside that scope, selectable providers hide every retired component.
final retiredContentVisibleIdsProvider =
    Provider<Set<String>>((ref) => const <String>{});

/// Component stream for choice controls. Retired content is excluded unless
/// the current hero already has that exact ID selected.
final selectableComponentsByTypeProvider =
    StreamProvider.family<List<model.Component>, String>(
  (ref, type) {
    final visibleRetiredIds = ref.watch(retiredContentVisibleIdsProvider);
    final repo = ref.read(componentRepositoryProvider);
    return repo.watchByType(type).map(
          (components) => components
              .where(
                (component) =>
                    !component.isRetired ||
                    visibleRetiredIds.contains(component.id),
              )
              .toList(growable: false),
        );
  },
  dependencies: [retiredContentVisibleIdsProvider],
);

/// All components suitable for a creator choice control.
final selectableAllComponentsProvider = StreamProvider<List<model.Component>>(
  (ref) {
    final visibleRetiredIds = ref.watch(retiredContentVisibleIdsProvider);
    final repo = ref.read(componentRepositoryProvider);
    return repo.watchAll().map(
          (components) => components
              .where(
                (component) =>
                    !component.isRetired ||
                    visibleRetiredIds.contains(component.id),
              )
              .toList(growable: false),
        );
  },
  dependencies: [retiredContentVisibleIdsProvider],
);

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

/// Hero-wide persisted ownership for every guarded component type.
///
/// Creator drafts project their own mutation scopes on top of these claims.
/// Hero-sheet manual-add pickers consume this index directly because they add
/// a new source and therefore must conflict with every existing owner.
final heroPersistedConflictIndexProvider =
    Provider.family<HeroConflictIndex, String>((ref, heroId) {
  final guard = ref.watch(heroDuplicateGuardServiceProvider);
  final entries = ref.watch(heroEntriesProvider(heroId)).valueOrNull;
  if (entries == null) return HeroConflictIndex.empty;

  return HeroConflictIndex.projected(
    persistedClaims: entries
        .where(
          (entry) => guard.guardsEntryType(entry.entryType),
        )
        .map(
          (entry) => HeroEntryClaim(
            key: HeroEntryKey(
              entryType: entry.entryType,
              canonicalEntryId: entry.entryId,
            ),
            owner: HeroClaimOwner.persisted(
              source: HeroClaimSource(
                sourceType: entry.sourceType,
                sourceId: entry.sourceId,
              ),
              displayLabel: entry.sourceId.trim().isEmpty
                  ? entry.sourceType
                  : '${entry.sourceType}:${entry.sourceId}',
            ),
          ),
        ),
  );
});

/// Hero-wide claimed IDs for a guarded entry type. Titles intentionally return
/// an empty set until their dedicated rule is defined.
final heroClaimedEntryIdsProvider =
    Provider.family<Set<String>, ({String heroId, String entryType})>(
  (ref, args) {
    final guard = ref.watch(heroDuplicateGuardServiceProvider);
    if (!guard.guardsEntryType(args.entryType)) return const <String>{};
    return ref
        .watch(heroPersistedConflictIndexProvider(args.heroId))
        .claimedEntryIds(args.entryType);
  },
);

/// Provider to get entry IDs of a specific type for a hero.
/// Useful for pickers to exclude already-saved entries.
/// Args: (heroId: String, entryType: String)
final heroEntryIdsByTypeProvider =
    Provider.family<Set<String>, ({String heroId, String entryType})>(
        (ref, args) {
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

final heroRowProvider = StreamProvider.family<db.Heroe?, String>((ref, heroId) {
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
final abilityByNameProvider =
    FutureProvider.family<model.Component?, String>((ref, rawName) async {
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
  'data/abilities/kits_abilities.json',
  'data/abilities/treasure_abilities.json',
  'data/abilities/item_imbuement_abilities.json',
  'data/abilities/stormwight_abilities.json',
  'data/abilities/retainer_abilities.json',
  'data/abilities/minion_abilities.json',
  'data/retainers/role_advancement_abilities.json',
];

// ---------------------------------------------------------------------------
// Retainer providers
// ---------------------------------------------------------------------------

final retainerRepositoryProvider = Provider<RetainerRepository>((ref) {
  final database = ref.read(appDatabaseProvider);
  return RetainerRepository(database);
});

final retainerAdvancementServiceProvider =
    Provider<RetainerAdvancementService>((ref) {
  return const RetainerAdvancementService();
});

/// Watch the active retainer instance for a hero.
final heroRetainerProvider =
    StreamProvider.family<RetainerInstance?, String>((ref, heroId) {
  final repo = ref.read(retainerRepositoryProvider);
  return repo.watchRetainerForHero(heroId);
});

/// Watch the retainer template (base stat block) for a hero's active retainer.
final heroRetainerTemplateProvider =
    FutureProvider.family<Retainer?, String>((ref, heroId) async {
  final instance = ref.watch(heroRetainerProvider(heroId)).valueOrNull;
  if (instance == null) return null;
  final database = ref.read(appDatabaseProvider);
  final row = await (database.select(database.components)
        ..where((c) => c.id.equals(instance.retainerComponentId)))
      .getSingleOrNull();
  if (row == null) return null;
  return Retainer.fromComponent(model.Component.fromJson({
    'id': row.id,
    'type': row.type,
    'name': row.name,
    ...row.dataJson.isNotEmpty
        ? (jsonDecode(row.dataJson) as Map<String, dynamic>)
        : <String, dynamic>{},
  }));
});

/// Computed retainer stats at the retainer's own tracked level.
/// Combines the base template + player choices + advancement rules.
///
/// Retainers level up independently of their hero (see
/// [RetainerRepository.levelUp]) rather than always mirroring the hero's
/// level — [heroRetainerLevelUpAvailableProvider] tells the UI when the hero
/// has out-leveled the retainer so it can prompt for a level-up.
final heroRetainerStatsProvider =
    FutureProvider.family<RetainerStats?, String>((ref, heroId) async {
  final instance = ref.watch(heroRetainerProvider(heroId)).valueOrNull;
  if (instance == null) return null;
  final template = await ref.watch(heroRetainerTemplateProvider(heroId).future);
  if (template == null) return null;

  final svc = ref.read(retainerAdvancementServiceProvider);
  return svc.computeStats(
    template: template,
    mentorLevel: instance.level,
    instance: instance,
  );
});

/// Whether the hero has out-leveled their retainer, i.e. the retainer can be
/// leveled up. Returns null when there's no active retainer.
final heroRetainerLevelUpAvailableProvider =
    FutureProvider.family<bool?, String>((ref, heroId) async {
  final instance = ref.watch(heroRetainerProvider(heroId)).valueOrNull;
  if (instance == null) return null;
  final assembly = await ref.watch(heroAssemblyProvider(heroId).future);
  final heroLevel = assembly?.level ?? 1;
  return heroLevel > instance.level && instance.level < 10;
});

/// All seeded retainer templates (for the "Add Retainer" picker).
final allRetainerTemplatesProvider = StreamProvider<List<Retainer>>((ref) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchByType('retainer').map(
        (components) =>
            components.map((c) => Retainer.fromComponent(c)).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

// ---------------------------------------------------------------------------
// Companion providers
// ---------------------------------------------------------------------------

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  final database = ref.read(appDatabaseProvider);
  return CompanionRepository(database);
});

final companionAdvancementServiceProvider =
    Provider<CompanionAdvancementService>((ref) {
  return const CompanionAdvancementService();
});

/// Watch the active companion instance for a hero.
final heroCompanionProvider =
    StreamProvider.family<CompanionInstance?, String>((ref, heroId) {
  final repo = ref.read(companionRepositoryProvider);
  return repo.watchCompanionForHero(heroId);
});

/// Watch the companion template (base stat block) for a hero's active companion.
final heroCompanionTemplateProvider =
    FutureProvider.family<Companion?, String>((ref, heroId) async {
  final instance = ref.watch(heroCompanionProvider(heroId)).valueOrNull;
  if (instance == null) return null;
  final database = ref.read(appDatabaseProvider);
  final row = await (database.select(database.components)
        ..where((c) => c.id.equals(instance.companionComponentId)))
      .getSingleOrNull();
  if (row == null) return null;
  return Companion.fromComponent(model.Component.fromJson({
    'id': row.id,
    'type': row.type,
    'name': row.name,
    ...row.dataJson.isNotEmpty
        ? (jsonDecode(row.dataJson) as Map<String, dynamic>)
        : <String, dynamic>{},
  }));
});

/// Computed companion advancement state at the hero's current level.
/// Combines the base template with the hero's (mentor's) level.
final heroCompanionStatsProvider =
    FutureProvider.family<CompanionAdvancementState?, String>(
        (ref, heroId) async {
  final template =
      await ref.watch(heroCompanionTemplateProvider(heroId).future);
  if (template == null) return null;

  final assembly = await ref.watch(heroAssemblyProvider(heroId).future);
  final heroLevel = assembly?.level ?? 1;

  final svc = ref.read(companionAdvancementServiceProvider);
  return svc.computeStats(template: template, mentorLevel: heroLevel);
});

/// All seeded companion templates (for the "Add Companion" picker).
final allCompanionTemplatesProvider = StreamProvider<List<Companion>>((ref) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchByType('companion').map(
        (components) =>
            components.map((c) => Companion.fromComponent(c)).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

// ---------------------------------------------------------------------------
// Minion providers
// ---------------------------------------------------------------------------

final minionRepositoryProvider = Provider<MinionRepository>((ref) {
  final database = ref.read(appDatabaseProvider);
  return MinionRepository(database);
});

/// Watch all active minion squads for a hero (0-2).
final heroMinionSquadsProvider =
    StreamProvider.family<List<MinionSquadInstance>, String>((ref, heroId) {
  final repo = ref.read(minionRepositoryProvider);
  return repo.watchSquadsForHero(heroId);
});

/// All seeded minion templates (for the "Add Squad" picker).
final allMinionTemplatesProvider = StreamProvider<List<Minion>>((ref) {
  final repo = ref.read(componentRepositoryProvider);
  return repo.watchByType('minion').map(
        (components) => components.map((c) => Minion.fromComponent(c)).toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

/// Watch the minion template (base stat block) for a given component ID.
final minionTemplateProvider =
    FutureProvider.family<Minion?, String>((ref, minionComponentId) async {
  final database = ref.read(appDatabaseProvider);
  final row = await (database.select(database.components)
        ..where((c) => c.id.equals(minionComponentId)))
      .getSingleOrNull();
  if (row == null) return null;
  return Minion.fromComponent(model.Component.fromJson({
    'id': row.id,
    'type': row.type,
    'name': row.name,
    ...row.dataJson.isNotEmpty
        ? (jsonDecode(row.dataJson) as Map<String, dynamic>)
        : <String, dynamic>{},
  }));
});

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
      .replaceAll(RegExp(r"[''']"), '') // Remove apostrophes
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
