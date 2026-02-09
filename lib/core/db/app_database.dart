import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kReleaseMode;
import 'package:path_provider/path_provider.dart';

import '../services/hero_entry_normalizer.dart';
part 'app_database.g.dart';

class Components extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get dataJson => text().withDefault(const Constant('{}'))();
  // source of data: 'seed' | 'user' | 'import'
  TextColumn get source => text().withDefault(const Constant('seed'))();
  TextColumn get parentId => text().nullable().references(Components, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Heroes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get classComponentId =>
      text().nullable().references(Components, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

/// Unified table for all hero-owned content (skills, perks, languages, titles,
/// traits, abilities, equipment, ancestry/class/career picks, etc.).
class HeroEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get entryType => text()(); // e.g. skill, perk, language, class
  TextColumn get entryId => text()(); // component id
  TextColumn get sourceType =>
      text().withDefault(const Constant('legacy'))(); // e.g. class, ancestry
  TextColumn get sourceId =>
      text().withDefault(const Constant(''))(); // component id of source
  TextColumn get gainedBy =>
      text().withDefault(const Constant('grant'))(); // grant | choice
  TextColumn get payload => text().nullable()(); // JSON metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stores configuration/choice metadata that is not itself a content entry.
class HeroConfig extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get configKey => text()(); // e.g. ancestry.trait_choices
  TextColumn get valueJson => text()(); // JSON-encoded value
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// HeroComponents table removed - all data now stored in HeroValues

class HeroValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get key => text()();
  IntColumn get value => integer().nullable()();
  IntColumn get maxValue => integer().nullable()();
  RealColumn get doubleValue => real().nullable()();
  TextColumn get textValue => text().nullable()();
  TextColumn get jsonValue => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class MetaEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

// Downtime tracking tables
class HeroDowntimeProjects extends Table {
  TextColumn get id => text()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get templateProjectId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get projectGoal => integer()();
  IntColumn get currentPoints => integer().withDefault(const Constant(0))();
  TextColumn get prerequisitesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get projectSource => text().nullable()();
  TextColumn get sourceLanguage => text().nullable()();
  TextColumn get guidesJson => text().withDefault(const Constant('[]'))();
  TextColumn get rollCharacteristicsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get eventsJson => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class HeroFollowers extends Table {
  TextColumn get id => text()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get name => text()();
  TextColumn get followerType => text()();
  IntColumn get might => integer().withDefault(const Constant(0))();
  IntColumn get agility => integer().withDefault(const Constant(0))();
  IntColumn get reason => integer().withDefault(const Constant(0))();
  IntColumn get intuition => integer().withDefault(const Constant(0))();
  IntColumn get presence => integer().withDefault(const Constant(0))();
  TextColumn get skillsJson => text().withDefault(const Constant('[]'))();
  TextColumn get languagesJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class HeroProjectSources extends Table {
  TextColumn get id => text()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'source', 'item', 'guide'
  TextColumn get language => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

// Hero notes for character journals, session notes, etc.
class HeroNotes extends Table {
  TextColumn get id => text()();
  TextColumn get heroId => text().references(Heroes, #id)();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  // folderId: null = root level, or references another HeroNote with isFolder=true
  TextColumn get folderId => text().nullable()();
  BoolColumn get isFolder => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Components,
  Heroes,
  HeroValues,
  MetaEntries,
  HeroDowntimeProjects,
  HeroFollowers,
  HeroProjectSources,
  HeroNotes,
  HeroEntries,
  HeroConfig,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  /// Creates an AppDatabase backed by the provided Drift [QueryExecutor].
  ///
  /// Intended for tests to supply an in-memory database (e.g.
  /// `NativeDatabase.memory()`) without relying on platform directories.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);
  static final AppDatabase instance = AppDatabase._internal();
  // Indicates whether the database file existed before this process opened it.
  // This is set during database path resolution and read by the seeder to
  // avoid reseeding when the DB file already exists (even if it's empty).
  static bool databasePreexisted = false;

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_hero_entries_hero_id ON hero_entries(hero_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_hero_entries_type ON hero_entries(hero_id, entry_type)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_hero_config_hero_id ON hero_config(hero_id)');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Migration from schema version 1 to 2
            // Move data from HeroComponents to HeroValues
            await _migrateHeroComponentsToValues();
          }
          if (from < 3) {
            // Migration from schema version 2 to 3
            // Add downtime tracking tables
            await m.createTable(heroDowntimeProjects);
            await m.createTable(heroFollowers);
            await m.createTable(heroProjectSources);
          }
          if (from < 4) {
            // Migration from schema version 3 to 4
            // Add hero notes table
            await m.createTable(heroNotes);
          }
          if (from < 5) {
            // Migration from schema version 4 to 5
            // Add notes column to hero_downtime_projects
            await customStatement(
              "ALTER TABLE hero_downtime_projects ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
            );
          }
          if (from < 6) {
            // Migration from schema version 5 to 6
            await m.createTable(heroEntries);
            await m.createTable(heroConfig);
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_hero_entries_hero_id ON hero_entries(hero_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_hero_entries_type ON hero_entries(hero_id, entry_type)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_hero_config_hero_id ON hero_config(hero_id)');
            await _migrateHeroValuesToEntriesAndConfig();
          }
          if (from < 7) {
            // Normalization pass to ensure correct metadata and cleanup legacy fields
            final heroesList = await select(heroes).get();
            final normalizer = HeroEntryNormalizer(this);
            for (final h in heroesList) {
              await normalizer.normalize(h.id);
            }
          }
          if (from < 8) {
            // Ensure hero_config uniqueness and cleanup duplicates
            // MUST dedupe BEFORE creating unique index to avoid constraint failures
            final heroesList = await select(heroes).get();
            final normalizer = HeroEntryNormalizer(this);
            for (final h in heroesList) {
              await normalizer.normalize(h.id);
            }
            // Now safe to create unique index
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS idx_hero_config_unique ON hero_config(hero_id, config_key)');
          }
          if (from < 9) {
            // v9: Fix for users who migrated to v8 but still have duplicate config rows
            // The unique index creation with IF NOT EXISTS doesn't enforce on existing data
            // so we must: 1) drop index, 2) dedupe, 3) recreate index
            await customStatement(
                'DROP INDEX IF EXISTS idx_hero_config_unique');
            final heroesList = await select(heroes).get();
            final normalizer = HeroEntryNormalizer(this);
            for (final h in heroesList) {
              await normalizer.normalize(h.id);
            }
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS idx_hero_config_unique ON hero_config(hero_id, config_key)');
          }
          if (from < 10) {
            // v10: Force cleanup of duplicates created by buggy setHeroConfig
            // Now that setHeroConfig properly deletes before insert, this is a one-time cleanup
            await customStatement(
                'DROP INDEX IF EXISTS idx_hero_config_unique');
            final heroesList = await select(heroes).get();
            final normalizer = HeroEntryNormalizer(this);
            for (final h in heroesList) {
              await normalizer.normalize(h.id);
            }
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS idx_hero_config_unique ON hero_config(hero_id, config_key)');
          }
        },
      );

  /// Migrate hero components data to hero values (schema v1 -> v2)
  Future<void> _migrateHeroComponentsToValues() async {
    try {
      // Check if heroComponents table exists
      final result = await customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hero_components'",
      ).getSingleOrNull();

      if (result != null) {
        // Fetch all hero components
        final components = await customSelect(
          'SELECT hero_id, component_id, category FROM hero_components',
        ).get();

        // Group by heroId and category
        final Map<String, Map<String, List<String>>> grouped = {};
        for (final row in components) {
          final heroId = row.read<String>('hero_id');
          final componentId = row.read<String>('component_id');
          final category = row.read<String>('category');

          grouped.putIfAbsent(heroId, () => {});
          grouped[heroId]!.putIfAbsent(category, () => []);
          grouped[heroId]![category]!.add(componentId);
        }

        // Insert into HeroValues
        for (final heroId in grouped.keys) {
          for (final category in grouped[heroId]!.keys) {
            final componentIds = grouped[heroId]![category]!;

            // For single-item categories, store as textValue
            // For multi-item categories, store as JSON array
            if (componentIds.length == 1 &&
                (category == 'culture_environment' ||
                    category == 'culture_organisation' ||
                    category == 'culture_upbringing' ||
                    category == 'ancestry' ||
                    category == 'career' ||
                    category == 'complication')) {
              await upsertHeroValue(
                heroId: heroId,
                key: 'component.$category',
                textValue: componentIds.first,
              );
            } else {
              // Store as JSON array for languages, skills, etc.
              await upsertHeroValue(
                heroId: heroId,
                key: 'component.$category',
                jsonMap: {'ids': componentIds},
              );
            }
          }
        }

        // Drop the old table
        await customStatement('DROP TABLE IF EXISTS hero_components');
      }
    } catch (e) {
      // If migration fails, log it but don't crash
      debugPrint('Migration warning: $e');
    }
  }

  /// Migration helper: move non-numeric content/configuration out of hero_values
  /// into hero_entries / hero_config to keep hero_values numeric/state only.
  ///
  /// Mapping reference:
  /// - component.*                     => hero_entries(entry_type = suffix)
  /// - basics.{className,subclass,...} => hero_entries (class/subclass/ancestry/career/kit)
  /// - faith.{deity,domain}            => hero_entries (deity/domain rows)
  /// - ancestry.selected_traits        => hero_entries(ancestry_trait); choices/signature -> hero_config
  /// - culture.*.skill                 => hero_config (selection metadata)
  /// - career.* selections             => hero_config (skills/perks/incident)
  /// - strife.* selections/layout      => hero_config; equipment ids -> hero_entries(equipment)
  /// - perk_grant.*                    => hero_config
  /// - perk_abilities.*                => hero_entries(ability, source=perk)
  /// - complication.{skills,abilities,languages,features,treasures} => hero_entries (source=complication)
  /// - complication.choices            => hero_config
  /// - gear.favorite_kits / inventory  => hero_config
  Future<void> _migrateHeroValuesToEntriesAndConfig() async {
    final allValues = await select(heroValues).get();
    final now = DateTime.now();
    const bannedPrefixes = [
      'ancestry.granted_abilities',
      'ancestry.applied_bonuses',
      'ancestry.condition_immunities',
      'ancestry.stat_mods',
      'perk_abilities.',
      'complication.applied_grants',
      'complication.abilities',
      'complication.skills',
      'complication.features',
      'complication.treasures',
      'complication.languages',
      'complication.damage_resistances',
      // 'strife.equipment_bonuses', // Now used as source of truth by heroEquipmentBonusesProvider
    ];

    Future<void> addEntry({
      required String heroId,
      required String entryType,
      required String entryId,
      String sourceType = 'legacy',
      String sourceId = '',
      String gainedBy = 'grant',
      Map<String, dynamic>? payload,
    }) async {
      await into(heroEntries).insert(
        HeroEntriesCompanion.insert(
          heroId: heroId,
          entryType: entryType,
          entryId: entryId,
          sourceType: Value(sourceType),
          sourceId: Value(sourceId),
          gainedBy: Value(gainedBy),
          payload: Value(payload == null ? null : jsonEncode(payload)),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    Future<void> setConfig({
      required String heroId,
      required String key,
      required String valueJson,
      String? metadata,
    }) async {
      await into(heroConfig).insert(
        HeroConfigCompanion.insert(
          heroId: heroId,
          configKey: key,
          valueJson: valueJson,
          metadata: Value(metadata),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }

    // Track hero_values rows to delete after migration.
    final idsToDelete = <int>{};

    for (final v in allValues) {
      if (bannedPrefixes.any((p) => v.key.startsWith(p))) {
        idsToDelete.add(v.id);
        continue;
      }
      final key = v.key;
      final heroId = v.heroId;

      // --- Component.* legacy buckets -> hero_entries
      if (key.startsWith('component.')) {
        final entryType = key.substring('component.'.length);
        final ids = <String>[];
        if (v.textValue != null && v.textValue!.isNotEmpty) {
          ids.add(v.textValue!);
        }
        if (v.jsonValue != null) {
          try {
            final decoded = jsonDecode(v.jsonValue!);
            if (decoded is Map && decoded['ids'] is List) {
              ids.addAll(
                  (decoded['ids'] as List).map((e) => e.toString()).toList());
            } else if (decoded is List) {
              ids.addAll(decoded.map((e) => e.toString()));
            }
          } catch (_) {}
        }
        for (final id in ids) {
          await addEntry(
            heroId: heroId,
            entryType: entryType,
            entryId: id,
            sourceType: 'legacy_component',
            sourceId: entryType,
            gainedBy: 'grant',
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // --- Top-level picks -> hero_entries (class/ancestry/career/etc.)
      switch (key) {
        case 'basics.className':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'class',
              entryId: v.textValue!,
              sourceType: 'class',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'basics.subclass':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'subclass',
              entryId: v.textValue!,
              sourceType: 'class',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'basics.ancestry':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'ancestry',
              entryId: v.textValue!,
              sourceType: 'ancestry',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'basics.career':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'career',
              entryId: v.textValue!,
              sourceType: 'career',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'basics.kit':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'kit',
              entryId: v.textValue!,
              sourceType: 'kit',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'faith.deity':
          if ((v.textValue ?? '').isNotEmpty) {
            await addEntry(
              heroId: heroId,
              entryType: 'deity',
              entryId: v.textValue!,
              sourceType: 'deity',
              gainedBy: 'choice',
            );
          }
          idsToDelete.add(v.id);
          continue;
        case 'faith.domain':
          if ((v.textValue ?? '').isNotEmpty) {
            final parts = v.textValue!
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty);
            for (final domain in parts) {
              await addEntry(
                heroId: heroId,
                entryType: 'domain',
                entryId: domain,
                sourceType: 'domain',
                gainedBy: 'choice',
              );
            }
          }
          idsToDelete.add(v.id);
          continue;
        default:
          break;
      }

      // --- Ancestry trait picks -> hero_entries + config
      if (key == 'ancestry.selected_traits') {
        if (v.jsonValue != null || v.textValue != null) {
          try {
            final raw = v.jsonValue ?? v.textValue;
            final decoded = jsonDecode(raw!);
            final ids = decoded is List
                ? decoded.map((e) => e.toString()).toList()
                : decoded is Map && decoded['list'] is List
                    ? (decoded['list'] as List)
                        .map((e) => e.toString())
                        .toList()
                    : <String>[];
            for (final id in ids) {
              await addEntry(
                heroId: heroId,
                entryType: 'ancestry_trait',
                entryId: id,
                sourceType: 'ancestry',
                sourceId: 'ancestry',
                gainedBy: 'choice',
              );
            }
          } catch (_) {}
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Ancestry signature / trait choices are configuration
      if (key == 'ancestry.signature_name') {
        final raw = v.textValue ?? v.jsonValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: 'ancestry.signature_name',
            valueJson: jsonEncode({'name': raw}),
          );
        }
        idsToDelete.add(v.id);
        continue;
      }
      if (key == 'ancestry.trait_choices') {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: 'ancestry.trait_choices',
            valueJson: raw,
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Culture skill choices are configuration metadata
      if (key == 'culture.environment.skill' ||
          key == 'culture.organisation.skill' ||
          key == 'culture.upbringing.skill') {
        final raw = v.textValue ?? v.jsonValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: jsonEncode({'selection': raw}),
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Career choice metadata (lists are duplicated in hero_entries already)
      if (key == 'career.chosen_skills' ||
          key == 'career.chosen_perks' ||
          key == 'career.inciting_incident') {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: raw,
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Strife creator selections (all config)
      if (key.startsWith('strife.')) {
        // Content lists will be rehydrated into hero_entries separately
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: raw,
          );
        }
        // Special case: equipment ids are content entries
        if (key == 'strife.equipment_ids' || key == 'basics.equipment') {
          try {
            final decoded = raw != null ? jsonDecode(raw) : null;
            final ids = <String?>[];
            if (decoded is Map && decoded['ids'] is List) {
              ids.addAll((decoded['ids'] as List).map((e) => e?.toString()));
            } else if (decoded is List) {
              ids.addAll(decoded.map((e) => e?.toString()));
            }
            for (var i = 0; i < ids.length; i++) {
              final id = ids[i];
              if (id == null || id.isEmpty) continue;
              await addEntry(
                heroId: heroId,
                entryType: 'equipment',
                entryId: id,
                sourceType: 'equipment',
                sourceId: 'strife',
                gainedBy: 'choice',
                payload: {'slot_index': i},
              );
            }
          } catch (_) {}
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Perk ability grants (ability content) -> hero_entries
      if (key.startsWith('perk_abilities.')) {
        final perkId = key.substring('perk_abilities.'.length);
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            final list = decoded is Map && decoded['list'] is List
                ? (decoded['list'] as List)
                : decoded is List
                    ? decoded
                    : const [];
            for (final abilityId in list) {
              await addEntry(
                heroId: heroId,
                entryType: 'ability',
                entryId: abilityId.toString(),
                sourceType: 'perk',
                sourceId: perkId,
                gainedBy: 'grant',
              );
            }
          } catch (_) {}
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Perk grant choices -> hero_config
      if (key.startsWith('perk_grant.')) {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: raw,
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Complication content lists -> hero_entries; choices -> hero_config
      if (key == 'complication.skills' ||
          key == 'complication.languages' ||
          key == 'complication.features' ||
          key == 'complication.treasures' ||
          key == 'complication.abilities') {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            Iterable list;
            if (decoded is Map && decoded['list'] is List) {
              list = decoded['list'] as List;
            } else if (decoded is Map &&
                decoded.values.every((e) => e != null)) {
              list = decoded.values;
            } else if (decoded is List) {
              list = decoded;
            } else {
              list = const <dynamic>[];
            }
            final entryType = key.split('.').last.replaceAll('_', '');
            for (final id in list) {
              await addEntry(
                heroId: heroId,
                entryType: entryType,
                entryId: id.toString(),
                sourceType: 'complication',
                sourceId: 'complication',
                gainedBy: 'grant',
              );
            }
          } catch (_) {}
        }
        idsToDelete.add(v.id);
        continue;
      }
      if (key == 'complication.choices') {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: raw,
          );
        }
        idsToDelete.add(v.id);
        continue;
      }

      // Gear preferences -> hero_config
      if (key == 'gear.favorite_kits' || key == 'gear.inventory_containers') {
        final raw = v.jsonValue ?? v.textValue;
        if (raw != null) {
          await setConfig(
            heroId: heroId,
            key: key,
            valueJson: raw,
          );
        }
        idsToDelete.add(v.id);
        continue;
      }
    }

    // Remove migrated rows from hero_values.
    if (idsToDelete.isNotEmpty) {
      await (delete(heroValues)..where((t) => t.id.isIn(idsToDelete.toList())))
          .go();
    }
  }

  // CRUD helpers for components
  Future<void> upsertComponentModel({
    required String id,
    required String type,
    required String name,
    required Map<String, dynamic> dataMap,
    String source = 'seed',
    String? parentId,
    DateTime? createdAtOverride,
  }) async {
    final existing = await (select(components)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    final now = DateTime.now();
    await into(components).insert(
      ComponentsCompanion.insert(
        id: id,
        type: type,
        name: name,
        dataJson: Value(jsonEncode(dataMap)),
        source: Value(existing?.source ?? source),
        parentId: Value(parentId),
        createdAt: Value(existing?.createdAt ?? createdAtOverride ?? now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<Component>> getAllComponents() => select(components).get();

  /// Get all components by type (e.g., 'skill', 'language', 'title', 'ability')
  Future<List<Component>> getComponentsByType(String type) =>
      (select(components)..where((c) => c.type.equals(type))).get();

  /// Get a single component by ID
  Future<Component?> getComponentById(String id) async {
    return (select(components)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a component into the database from raw values
  Future<void> insertComponentRaw({
    required String id,
    required String type,
    required String name,
    required Map<String, dynamic> data,
    String source = 'perk_ability',
    String? parentId,
  }) async {
    final now = DateTime.now();
    await into(components).insert(
      ComponentsCompanion.insert(
        id: id,
        type: type,
        name: name,
        dataJson: Value(jsonEncode(data)),
        source: Value(source),
        parentId: Value(parentId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<Component>> watchAllComponents() => select(components).watch();
  Stream<List<Component>> watchComponentsByType(String type) =>
      (select(components)..where((c) => c.type.equals(type))).watch();

  Future<bool> deleteComponent(String id) async {
    final count =
        await (delete(components)..where((c) => c.id.equals(id))).go();
    return count > 0;
  }

  // --- Meta helpers (simple key-value store) ---
  Future<String?> getMeta(String key) async {
    final row = await (select(metaEntries)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) async {
    final existing = await (select(metaEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await into(metaEntries)
          .insert(MetaEntriesCompanion.insert(key: key, value: value));
    } else {
      await (update(metaEntries)..where((t) => t.key.equals(key)))
          .write(MetaEntriesCompanion(value: Value(value)));
    }
  }

  /// Atomically increment a numeric meta counter and return the new value.
  Future<int> nextSequence(String seqKey) async {
    return transaction(() async {
      final currentStr = await getMeta(seqKey);
      final current = int.tryParse(currentStr ?? '') ?? 0;
      final next = current + 1;
      await setMeta(seqKey, next.toString());
      return next;
    });
  }

  // --- Heroes CRUD helpers ---
  /// Create a hero with an incremental id. The id format is H0001, H0002, ...
  Future<String> createHero({required String name}) async {
    final n = await nextSequence('hero_id_seq');
    final id = 'H${n.toString().padLeft(4, '0')}';
    final now = DateTime.now();
    await into(heroes).insert(
      HeroesCompanion.insert(
        id: id,
        name: name,
        classComponentId: const Value(null),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrAbort,
    );
    return id;
  }

  Future<void> renameHero(String heroId, String newName) async {
    await (update(heroes)..where((t) => t.id.equals(heroId))).write(
      HeroesCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Heroe>> getAllHeroes() => select(heroes).get();
  Stream<List<Heroe>> watchAllHeroes() => select(heroes).watch();

  Future<void> upsertHeroValue({
    required String heroId,
    required String key,
    int? value,
    int? maxValue,
    double? doubleValue,
    String? textValue,
    Map<String, dynamic>? jsonMap,
  }) async {
    final existing = await (select(heroValues)
          ..where((t) => t.heroId.equals(heroId) & t.key.equals(key)))
        .getSingleOrNull();
    final now = DateTime.now();
    final jsonStr = jsonMap == null ? null : jsonEncode(jsonMap);
    if (existing == null) {
      await into(heroValues).insert(
        HeroValuesCompanion.insert(
          heroId: heroId,
          key: key,
          value: Value(value),
          maxValue: Value(maxValue),
          doubleValue: Value(doubleValue),
          textValue: Value(textValue),
          jsonValue: Value(jsonStr),
          updatedAt: Value(now),
        ),
      );
    } else {
      await (update(heroValues)..where((t) => t.id.equals(existing.id))).write(
        HeroValuesCompanion(
          value: Value(value),
          maxValue: Value(maxValue),
          doubleValue: Value(doubleValue),
          textValue: Value(textValue),
          jsonValue: Value(jsonStr),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<List<HeroValue>> getHeroValues(String heroId) {
    return (select(heroValues)..where((t) => t.heroId.equals(heroId))).get();
  }

  /// Delete a specific hero value by key
  Future<void> deleteHeroValue({
    required String heroId,
    required String key,
  }) async {
    await (delete(heroValues)
          ..where((t) => t.heroId.equals(heroId) & t.key.equals(key)))
        .go();
  }

  Stream<List<HeroValue>> watchHeroValues(String heroId) {
    return (select(heroValues)..where((t) => t.heroId.equals(heroId))).watch();
  }

  /// Watch all hero values across all heroes (for summary updates)
  Stream<List<HeroValue>> watchAllHeroValues() {
    return select(heroValues).watch();
  }

  // --- Hero entries helpers -------------------------------------------------

  /// Insert (or replace existing) hero content entry.
  ///
  /// Entries are unique per (heroId, entryType, entryId, sourceType, sourceId).
  /// This allows the same skill/ability/etc to be granted from multiple sources
  /// (e.g., culture and complication can both grant the same skill).
  Future<void> upsertHeroEntry({
    required String heroId,
    required String entryType,
    required String entryId,
    String sourceType = 'manual_choice',
    String sourceId = '',
    String gainedBy = 'grant',
    Map<String, dynamic>? payload,
  }) async {
    // Optional debug logging. Keep disabled by default to avoid massive
    // slowdowns when many entries are written (e.g., on seed/migrations).
    const debugLogAbilityUpserts = false;
    assert(() {
      if (debugLogAbilityUpserts && entryType == 'ability') {
        // ignore: avoid_print
        print(
          '[AppDatabase] upsertHeroEntry(ability): heroId=$heroId, entryId=$entryId, sourceType=$sourceType, sourceId=$sourceId',
        );
        if (sourceType == 'manual_choice') {
          // ignore: avoid_print
          print('[AppDatabase] STACK TRACE for manual_choice ability:');
          // ignore: avoid_print
          print(StackTrace.current);
        }
      }
      return true;
    }());
    final now = DateTime.now();
    // Remove duplicates for same hero/type/id/source combo.
    // This preserves entries from other sources for the same entryId.
    await (delete(heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals(entryType) &
              t.entryId.equals(entryId) &
              t.sourceType.equals(sourceType) &
              t.sourceId.equals(sourceId)))
        .go();
    await into(heroEntries).insert(
      HeroEntriesCompanion.insert(
        heroId: heroId,
        entryType: entryType,
        entryId: entryId,
        sourceType: Value(sourceType),
        sourceId: Value(sourceId),
        gainedBy: Value(gainedBy),
        payload: Value(payload == null ? null : jsonEncode(payload)),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setHeroEntryIds({
    required String heroId,
    required String entryType,
    required List<String> entryIds,
    String sourceType = 'manual_choice',
    String sourceId = '',
    String gainedBy = 'choice',
  }) async {
    await transaction(() async {
      // Only delete entries matching BOTH entryType AND sourceType+sourceId
      // This preserves entries from other sources (e.g., ancestry, complication)
      await (delete(heroEntries)
            ..where((t) =>
                t.heroId.equals(heroId) &
                t.entryType.equals(entryType) &
                t.sourceType.equals(sourceType) &
                t.sourceId.equals(sourceId)))
          .go();
      for (final id in entryIds.where((e) => e.isNotEmpty)) {
        await upsertHeroEntry(
          heroId: heroId,
          entryType: entryType,
          entryId: id,
          sourceType: sourceType,
          sourceId: sourceId,
          gainedBy: gainedBy,
        );
      }
    });
  }

  Future<String?> getSingleHeroEntryId(String heroId, String entryType) async {
    final rows = await (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .get();
    return rows.isEmpty ? null : rows.first.entryId;
  }

  Future<void> setSingleHeroEntry({
    required String heroId,
    required String entryType,
    required String entryId,
    String sourceType = 'manual_choice',
    String sourceId = '',
    String gainedBy = 'choice',
  }) async {
    await setHeroEntryIds(
      heroId: heroId,
      entryType: entryType,
      entryIds: [entryId],
      sourceType: sourceType,
      sourceId: sourceId,
      gainedBy: gainedBy,
    );
  }

  Future<List<String>> getHeroEntryIds(String heroId, String entryType) async {
    final rows = await (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .get();
    // Return unique entry IDs (same entry might be granted from multiple sources)
    return rows.map((e) => e.entryId).toSet().toList();
  }

  Stream<List<String>> watchHeroEntryIds(String heroId, String entryType) {
    return (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .watch()
        // Return unique entry IDs (same entry might be granted from multiple sources)
        .map((rows) => rows.map((e) => e.entryId).toSet().toList());
  }

  /// Watch hero entries with their payloads for a specific category.
  /// Returns a stream of maps: {entryId: payload} where payload contains quantity etc.
  Stream<Map<String, Map<String, dynamic>>> watchHeroEntriesWithPayload(
      String heroId, String entryType) {
    return (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .watch()
        .map((rows) {
      final result = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        Map<String, dynamic> payload = {};
        if (row.payload != null) {
          try {
            payload = jsonDecode(row.payload!) as Map<String, dynamic>;
          } catch (_) {}
        }
        // If same entry exists multiple times, merge quantities
        if (result.containsKey(row.entryId)) {
          final existing = result[row.entryId]!;
          final existingQty = existing['quantity'] as int? ?? 1;
          final newQty = payload['quantity'] as int? ?? 1;
          existing['quantity'] = existingQty + newQty;
        } else {
          // Default quantity to 1 if not specified
          payload['quantity'] ??= 1;
          result[row.entryId] = payload;
        }
      }
      return result;
    });
  }

  /// Get hero entries with their payloads for a specific category (non-stream).
  /// Returns a map: {entryId: payload} where payload contains quantity, equipped, etc.
  Future<Map<String, Map<String, dynamic>>> getHeroEntriesWithPayload(
      String heroId, String entryType) async {
    final rows = await (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .get();

    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      Map<String, dynamic> payload = {};
      if (row.payload != null) {
        try {
          payload = jsonDecode(row.payload!) as Map<String, dynamic>;
        } catch (_) {}
      }
      // If same entry exists multiple times, merge quantities
      if (result.containsKey(row.entryId)) {
        final existing = result[row.entryId]!;
        final existingQty = existing['quantity'] as int? ?? 1;
        final newQty = payload['quantity'] as int? ?? 1;
        existing['quantity'] = existingQty + newQty;
      } else {
        // Default quantity to 1 if not specified
        payload['quantity'] ??= 1;
        result[row.entryId] = payload;
      }
    }
    return result;
  }

  /// Update the payload for a specific hero entry.
  Future<void> updateHeroEntryPayload({
    required String heroId,
    required String entryType,
    required String entryId,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await (update(heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals(entryType) &
              t.entryId.equals(entryId)))
        .write(HeroEntriesCompanion(
      payload: Value(jsonEncode(payload)),
      updatedAt: Value(now),
    ));
  }

  /// Add a hero entry with a specific payload (for treasures with quantity).
  Future<void> addHeroEntryWithPayload({
    required String heroId,
    required String entryType,
    required String entryId,
    required Map<String, dynamic> payload,
    String sourceType = 'manual_choice',
    String sourceId = '',
    String gainedBy = 'choice',
  }) async {
    await upsertHeroEntry(
      heroId: heroId,
      entryType: entryType,
      entryId: entryId,
      sourceType: sourceType,
      sourceId: sourceId,
      gainedBy: gainedBy,
      payload: payload,
    );
  }

  Future<void> clearHeroEntryType(String heroId, String entryType) async {
    await (delete(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .go();
  }

  // --- Hero config helpers --------------------------------------------------

  Future<void> setHeroConfig({
    required String heroId,
    required String configKey,
    required Map<String, dynamic> value,
    String? metadata,
  }) async {
    final now = DateTime.now();
    final valueJsonEncoded = jsonEncode(value);
    const deepEq = DeepCollectionEquality();

    // Check if existing row has the same value - skip update if unchanged
    final existing = await getHeroConfigValue(heroId, configKey);
    if (existing != null && deepEq.equals(existing, value)) {
      // No change, skip save
      return;
    }

    // Delete existing rows for this hero+key, then insert new one
    // This ensures no duplicates regardless of index state
    await (delete(heroConfig)
          ..where(
              (t) => t.heroId.equals(heroId) & t.configKey.equals(configKey)))
        .go();

    await into(heroConfig).insert(
      HeroConfigCompanion.insert(
        heroId: heroId,
        configKey: configKey,
        valueJson: valueJsonEncoded,
        metadata: Value(metadata),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<Map<String, dynamic>?> getHeroConfigValue(
      String heroId, String configKey) async {
    // Use .get() instead of .getSingleOrNull() to handle potential duplicates gracefully
    final rows = await (select(heroConfig)
          ..where(
              (t) => t.heroId.equals(heroId) & t.configKey.equals(configKey))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first.valueJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteHeroConfig(String heroId, String configKey) async {
    await (delete(heroConfig)
          ..where(
              (t) => t.heroId.equals(heroId) & t.configKey.equals(configKey)))
        .go();
  }

  Stream<Map<String, dynamic>?> watchHeroConfigValue(
      String heroId, String configKey) {
    // Use .watch() instead of .watchSingleOrNull() to handle potential duplicates gracefully
    return (select(heroConfig)
          ..where(
              (t) => t.heroId.equals(heroId) & t.configKey.equals(configKey))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .watch()
        .map((rows) {
      if (rows.isEmpty) return null;
      try {
        return jsonDecode(rows.first.valueJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    });
  }

  /// Get component IDs for a specific category (replaces getHeroComponents)
  Future<List<String>> getHeroComponentIds(
      String heroId, String category) async {
    final entryIds = await getHeroEntryIds(heroId, category);
    if (entryIds.isNotEmpty) return entryIds;

    // Backward compatibility: read legacy hero_values if present
    final key = 'component.$category';
    final row = await (select(heroValues)
          ..where((t) => t.heroId.equals(heroId) & t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return [];
    if (row.textValue != null && row.textValue!.isNotEmpty) {
      return [row.textValue!];
    }
    if (row.jsonValue != null) {
      try {
        final decoded = jsonDecode(row.jsonValue!);
        if (decoded is Map && decoded['ids'] is List) {
          return (decoded['ids'] as List).map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  /// Watch component IDs for a specific category (stream for real-time updates)
  Stream<List<String>> watchHeroComponentIds(String heroId, String category) {
    final legacyKey = 'component.$category';
    return (select(heroEntries)
          ..where(
              (t) => t.heroId.equals(heroId) & t.entryType.equals(category)))
        .watch()
        .asyncMap((rows) async {
      if (rows.isNotEmpty) {
        return rows.map((e) => e.entryId).toList();
      }
      final legacyRow = await (select(heroValues)
            ..where((t) => t.heroId.equals(heroId) & t.key.equals(legacyKey)))
          .getSingleOrNull();
      if (legacyRow == null) return <String>[];
      if (legacyRow.textValue != null && legacyRow.textValue!.isNotEmpty) {
        return [legacyRow.textValue!];
      }
      if (legacyRow.jsonValue != null) {
        try {
          final decoded = jsonDecode(legacyRow.jsonValue!);
          if (decoded is Map && decoded['ids'] is List) {
            return (decoded['ids'] as List).map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return <String>[];
    });
  }

  /// Set component IDs for a specific category (replaces setHeroComponents)
  Future<void> setHeroComponentIds({
    required String heroId,
    required String category,
    required List<String> componentIds,
  }) async {
    await setHeroEntryIds(
      heroId: heroId,
      entryType: category,
      entryIds: componentIds,
      sourceType: 'manual_choice',
      sourceId: category,
      gainedBy: 'choice',
    );
  }

  /// Add a single component ID to a category (replaces addHeroComponent)
  Future<void> addHeroComponentId({
    required String heroId,
    required String componentId,
    required String category,
  }) async {
    final existing = await getHeroComponentIds(heroId, category);
    if (!existing.contains(componentId)) {
      await setHeroComponentIds(
        heroId: heroId,
        category: category,
        componentIds: [...existing, componentId],
      );
    }
  }

  Future<void> deleteHero(String heroId) async {
    await transaction(() async {
      // Delete all per-hero data (order matters: children first, then parent)
      await (delete(heroNotes)..where((t) => t.heroId.equals(heroId))).go();
      await (delete(heroDowntimeProjects)
            ..where((t) => t.heroId.equals(heroId)))
          .go();
      await (delete(heroFollowers)..where((t) => t.heroId.equals(heroId))).go();
      await (delete(heroProjectSources)..where((t) => t.heroId.equals(heroId)))
          .go();
      await (delete(heroEntries)..where((t) => t.heroId.equals(heroId))).go();
      await (delete(heroConfig)..where((t) => t.heroId.equals(heroId))).go();
      await (delete(heroValues)..where((t) => t.heroId.equals(heroId))).go();
      await (delete(heroes)..where((t) => t.id.equals(heroId))).go();
    });
  }

  // Deprecated methods - kept for backwards compatibility during transition
  @Deprecated('Use getHeroComponentIds instead')
  Future<List<Map<String, String>>> getHeroComponents(String heroId) async {
    final entries = await (select(heroEntries)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    return entries
        .map((e) => {
              'componentId': e.entryId,
              'category': e.entryType,
            })
        .toList();
  }

  @Deprecated('Use setHeroComponentIds instead')
  Future<void> setHeroComponents({
    required String heroId,
    required String category,
    required List<String> componentIds,
  }) async {
    await setHeroComponentIds(
      heroId: heroId,
      category: category,
      componentIds: componentIds,
    );
  }

  @Deprecated('Use addHeroComponentId instead')
  Future<void> addHeroComponent({
    required String heroId,
    required String componentId,
    required String category,
  }) async {
    await addHeroComponentId(
      heroId: heroId,
      componentId: componentId,
      category: category,
    );
  }

  // Note: seeding logic has been extracted to core/seed/asset_seeder.dart

  // // Ensure abilities are present even if the DB already has other components.
  // Future<void> seedAbilitiesIncremental() async {
  //   final all = await AppDatabase.discoverDataJsonAssets();
  //   final abilityAssets = all.where((p) => p.startsWith('data/abilities/')).toList();
  //   if (abilityAssets.isEmpty) return;
  //   await upsertComponentsFromAssets(abilityAssets);
  // }

  // Expose the full path to the database file for diagnostics.
  static Future<String> databasePath() async {
    final file = await _getDatabaseFile();
    return file.path;
  }
}

// Open connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await _getDatabaseFile();
    final fileDb = NativeDatabase.createInBackground(file);
    return fileDb;
  });
}

// Determine the DB file location inside the application support directory
// (an app-specific folder not visible to end users in Documents).
Future<File> _getDatabaseFile() async {
  // In Windows debug/profile builds, prefer writing the DB inside the project folder
  // so it's easy to find under version-controlled sources. We attempt to locate
  // the repo root by walking up to a directory containing pubspec.yaml.
  if (Platform.isWindows && !kReleaseMode) {
    final root = _findProjectRoot();
    if (root != null) {
      final dbDir = Directory('${root.path}/lib/core/db');
      if (await dbDir.exists()) {
        final file = File('${dbDir.path}/hero_smith.db');
        await dbDir.create(recursive: true);
        AppDatabase.databasePreexisted = await file.exists();
        return file;
      }
    }
  }

  // Default: Use application support dir to keep files inside the app container.
  final supportDir = await getApplicationSupportDirectory();
  await supportDir.create(recursive: true);
  final file = File('${supportDir.path}/hero_smith.db');
  // Set the preexistence flag before the database is created/opened.
  AppDatabase.databasePreexisted = await file.exists();
  return file;
}

// Attempt to locate the Flutter project root by walking upward from the
// current working directory until a pubspec.yaml is found.
Directory? _findProjectRoot() {
  var dir = Directory.current.absolute;
  // Walk up to 15 levels to be safe.
  for (var i = 0; i < 15; i++) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
