import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'hero_export_models.dart';

/// Version of the export format. Increment when making breaking changes.
const int kExportVersion = 2;

/// Magic prefix for database snapshot exports
const String kExportMagic = 'HS2:';

/// Options controlling what data is included in an export.
///
/// Core build data (hero_config, hero_entries, hero_values) is always included.
/// Additional sections can be toggled on/off independently.
class ExportOptions {
  /// Include downtime data (projects, followers, sources).
  final bool includeDowntime;

  /// Include title progress tracking data.
  final bool includeTitles;

  /// Include personal notes.
  final bool includeNotes;

  /// Include retainer data (retainer instances, choices).
  final bool includeRetainers;

  const ExportOptions({
    this.includeDowntime = false,
    this.includeTitles = false,
    this.includeNotes = false,
    this.includeRetainers = false,
  });

  /// All optional sections enabled.
  static const full = ExportOptions(
    includeDowntime: true,
    includeTitles: true,
    includeNotes: true,
    includeRetainers: true,
  );

  /// Core build only (no optional sections).
  static const core = ExportOptions();

  /// Numeric flags bitmask stored in the export for import decoding.
  /// Bit 0 = downtime, Bit 1 = titles, Bit 2 = notes, Bit 3 = retainers.
  int get flags =>
      (includeDowntime ? 1 : 0) |
      (includeTitles ? 2 : 0) |
      (includeNotes ? 4 : 0) |
      (includeRetainers ? 8 : 0);

  /// Reconstruct from flags bitmask.
  factory ExportOptions.fromFlags(int flags) => ExportOptions(
        includeDowntime: (flags & 1) != 0,
        includeTitles: (flags & 2) != 0,
        includeNotes: (flags & 4) != 0,
        includeRetainers: (flags & 8) != 0,
      );

  /// Human-readable label for what's included.
  String get label {
    if (includeDowntime && includeTitles && includeNotes && includeRetainers) return 'Full Export';
    final parts = <String>['Core Build'];
    if (includeDowntime) parts.add('Downtime');
    if (includeTitles) parts.add('Titles');
    if (includeNotes) parts.add('Notes');
    if (includeRetainers) parts.add('Retainers');
    return parts.join(' + ');
  }

  /// Short description of what's included.
  String get description {
    final extras = <String>[];
    if (includeDowntime) extras.add('downtime projects');
    if (includeTitles) extras.add('title progress');
    if (includeNotes) extras.add('personal notes');
    if (includeRetainers) extras.add('retainers');
    if (extras.isEmpty) return 'Hero build data only';
    return 'Includes ${extras.join(', ')}';
  }
}

/// Service for exporting and importing heroes as compressed database snapshots.
///
/// This exports a complete database image of hero-related tables based on tier,
/// compresses it with gzip, and encodes as base64 for easy copy/paste sharing.
///
/// Tier 1: hero_config, hero_entries, hero_values
/// Tier 2: + downtime_projects, hero_followers, hero_project_sources
/// Tier 3: + hero_notes
///
/// Format: HS2:<base64-gzip-json>
class HeroExportService {
  HeroExportService(this._db);
  final AppDatabase _db;

  // ===========================================================================
  // EXPORT
  // ===========================================================================

  /// Export a hero to a compressed database snapshot string.
  ///
  /// [options] controls what data is included (default: full export)
  /// Returns a string starting with "HS2:" followed by base64-encoded gzip data.
  Future<String> exportHeroToCode(
    String heroId, {
    ExportOptions options = ExportOptions.full,
  }) async {
    // Fetch hero row
    final heroRow = await (_db.select(_db.heroes)
          ..where((t) => t.id.equals(heroId)))
        .getSingleOrNull();
    if (heroRow == null) {
      throw ArgumentError('Hero not found: $heroId');
    }

    // Build the snapshot data
    final snapshot = await _buildSnapshot(heroId, heroRow, options);

    // Convert to JSON, compress with gzip, encode as base64
    final jsonStr = jsonEncode(snapshot);
    final jsonBytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(jsonBytes);
    final base64Str = base64Url.encode(compressed);

    return '$kExportMagic$base64Str';
  }

  /// Build a complete snapshot of all hero data based on options
  Future<Map<String, dynamic>> _buildSnapshot(
    String heroId,
    dynamic heroRow,
    ExportOptions options,
  ) async {
    final snapshot = <String, dynamic>{
      'v': kExportVersion,
      'flags': options.flags,
      'ts': DateTime.now().toIso8601String(),
    };

    // Hero row (minimal fields needed to recreate)
    snapshot['hero'] = {
      'name': heroRow.name,
      'classComponentId': heroRow.classComponentId,
    };

    // Hero entries
    final entries = await (_db.select(_db.heroEntries)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    if (entries.isNotEmpty) {
      snapshot['entries'] = entries
          .map((e) => {
                'et': e.entryType,
                'ei': e.entryId,
                'st': e.sourceType,
                'si': e.sourceId,
                'gb': e.gainedBy,
                if (e.payload != null) 'pl': e.payload,
              })
          .toList();
    }

    // Hero config (filter out title_progress unless titles included)
    final configs = await (_db.select(_db.heroConfig)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    if (configs.isNotEmpty) {
      final filteredConfigs = options.includeTitles
          ? configs
          : configs.where((c) => c.configKey != 'title_progress').toList();
      if (filteredConfigs.isNotEmpty) {
        snapshot['config'] = filteredConfigs
            .map((c) => {
                  'k': c.configKey,
                  'v': c.valueJson,
                  if (c.metadata != null) 'm': c.metadata,
                })
            .toList();
      }
    }

    // Hero values
    final values = await _db.getHeroValues(heroId);
    if (values.isNotEmpty) {
      snapshot['values'] = values
          .map((v) => {
                'k': v.key,
                if (v.value != null) 'i': v.value,
                if (v.maxValue != null) 'mx': v.maxValue,
                if (v.doubleValue != null) 'd': v.doubleValue,
                if (v.textValue != null) 't': v.textValue,
                if (v.jsonValue != null) 'j': v.jsonValue,
              })
          .toList();
    }

    // =========================================================================
    // OPTIONAL: Downtime data
    // =========================================================================
    if (options.includeDowntime) {
      // Downtime projects
      final projects = await (_db.select(_db.heroDowntimeProjects)
            ..where((t) => t.heroId.equals(heroId)))
          .get();
      if (projects.isNotEmpty) {
        snapshot['projects'] = projects
            .map((p) => {
                  'id': p.id,
                  if (p.templateProjectId != null) 'tp': p.templateProjectId,
                  'na': p.name,
                  'de': p.description,
                  'pg': p.projectGoal,
                  'cp': p.currentPoints,
                  'pq': p.prerequisitesJson,
                  if (p.projectSource != null) 'ps': p.projectSource,
                  if (p.sourceLanguage != null) 'sl': p.sourceLanguage,
                  'gu': p.guidesJson,
                  'rc': p.rollCharacteristicsJson,
                  'ev': p.eventsJson,
                  'no': p.notes,
                  'ic': p.isCustom,
                  'cm': p.isCompleted,
                })
            .toList();
      }

      // Followers
      final followers = await (_db.select(_db.heroFollowers)
            ..where((t) => t.heroId.equals(heroId)))
          .get();
      if (followers.isNotEmpty) {
        snapshot['followers'] = followers
            .map((f) => {
                  'id': f.id,
                  'na': f.name,
                  'ft': f.followerType,
                  'm': f.might,
                  'a': f.agility,
                  'r': f.reason,
                  'i': f.intuition,
                  'p': f.presence,
                  'sk': f.skillsJson,
                  'la': f.languagesJson,
                })
            .toList();
      }

      // Project sources
      final sources = await (_db.select(_db.heroProjectSources)
            ..where((t) => t.heroId.equals(heroId)))
          .get();
      if (sources.isNotEmpty) {
        snapshot['sources'] = sources
            .map((s) => {
                  'id': s.id,
                  'na': s.name,
                  'ty': s.type,
                  if (s.language != null) 'la': s.language,
                  if (s.description != null) 'de': s.description,
                })
            .toList();
      }
    }

    // =========================================================================
    // OPTIONAL: Notes
    // =========================================================================
    if (options.includeNotes) {
      // Hero notes
      final notes = await (_db.select(_db.heroNotes)
            ..where((t) => t.heroId.equals(heroId)))
          .get();
      if (notes.isNotEmpty) {
        snapshot['notes'] = notes
            .map((n) => {
                  'id': n.id,
                  'ti': n.title,
                  'co': n.content,
                  if (n.folderId != null) 'fi': n.folderId,
                  'if': n.isFolder,
                  'so': n.sortOrder,
                })
            .toList();
      }
    }

    // =========================================================================
    // OPTIONAL: Retainers
    // =========================================================================
    if (options.includeRetainers) {
      final retainers = await (_db.select(_db.heroRetainers)
            ..where((t) => t.heroId.equals(heroId)))
          .get();
      if (retainers.isNotEmpty) {
        snapshot['retainers'] = retainers
            .map((r) => {
                  'rc': r.retainerComponentId,
                  'na': r.name,
                  'ro': r.role,
                  'ic': r.isCustom,
                  if (r.customDataJson != null) 'cd': r.customDataJson,
                  'ac': r.advancementChoicesJson,
                  'cc': r.characteristicChoicesJson,
                  'ia': r.isActive,
                })
            .toList();
      }
    }

    return snapshot;
  }

  // ===========================================================================
  // IMPORT
  // ===========================================================================

  /// Validate a hero code without importing.
  /// Returns preview info if valid, null if invalid.
  HeroImportPreview? validateCode(String code) {
    if (!code.startsWith(kExportMagic)) return null;

    try {
      final snapshot = _decodeSnapshot(code);
      if (snapshot == null) return null;

      final version = snapshot['v'] as int? ?? 0;
      final heroData = snapshot['hero'] as Map<String, dynamic>?;
      final name = heroData?['name']?.toString() ?? 'Unknown';

      // Extract class and ancestry from entries for preview
      String? className;
      String? ancestryName;
      int? level;

      final entries = snapshot['entries'] as List?;
      if (entries != null) {
        for (final e in entries) {
          final map = e as Map<String, dynamic>;
          if (map['et'] == 'class') {
            className = map['ei']?.toString();
          } else if (map['et'] == 'ancestry') {
            ancestryName = map['ei']?.toString();
          }
        }
      }

      // Try to get level from values
      final values = snapshot['values'] as List?;
      if (values != null) {
        for (final v in values) {
          final map = v as Map<String, dynamic>;
          if (map['k'] == 'basics.level') {
            level = map['i'] as int?;
            break;
          }
        }
      }

      // Extract export flags (backwards compatible with old tier field)
      final flags = snapshot['flags'] as int?;
      final legacyTier = snapshot['tier'] as int?;
      final exportOptions = flags != null
          ? ExportOptions.fromFlags(flags)
          : legacyTier != null
              ? ExportOptions(
                  includeDowntime: legacyTier >= 2,
                  includeTitles: legacyTier >= 1,
                  includeNotes: legacyTier >= 3,
                )
              : ExportOptions.full;

      return HeroImportPreview(
        name: name,
        formatVersion: version,
        isCompatible: version == kExportVersion,
        className: className,
        ancestryName: ancestryName,
        level: level,
        exportOptions: exportOptions,
      );
    } catch (_) {
      return null;
    }
  }

  /// Import a hero from a compressed snapshot string.
  /// Returns the new hero's ID on success.
  Future<String> importHeroFromCode(String code) async {
    final snapshot = _decodeSnapshot(code);
    if (snapshot == null) {
      throw const FormatException('Invalid hero code format');
    }

    final version = snapshot['v'] as int? ?? 0;
    if (version != kExportVersion) {
      throw FormatException(
        'Incompatible export version: $version (expected $kExportVersion)',
      );
    }

    return await _importSnapshot(snapshot);
  }

  /// Decode and decompress a snapshot from an export code
  Map<String, dynamic>? _decodeSnapshot(String code) {
    if (!code.startsWith(kExportMagic)) return null;

    try {
      final base64Str = code.substring(kExportMagic.length);
      final compressed = base64Url.decode(base64Str);
      final jsonBytes = gzip.decode(compressed);
      final jsonStr = utf8.decode(jsonBytes);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Import a snapshot into the database
  Future<String> _importSnapshot(Map<String, dynamic> snapshot) async {
    final heroData = snapshot['hero'] as Map<String, dynamic>?;
    final heroName = heroData?['name']?.toString() ?? 'Imported Hero';
    final classComponentId = heroData?['classComponentId']?.toString();

    // Create new hero with fresh ID
    final heroId = await _db.createHero(name: heroName);

    // Update class component ID if present
    if (classComponentId != null && classComponentId.isNotEmpty) {
      await (_db.update(_db.heroes)..where((t) => t.id.equals(heroId))).write(
        HeroesCompanion(
          classComponentId: Value(classComponentId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    // Map old IDs to new IDs for cross-references (notes, projects, etc.)
    final idMap = <String, String>{};

    await _db.transaction(() async {
      // Import entries
      final entries = snapshot['entries'] as List?;
      if (entries != null) {
        for (final e in entries) {
          final map = e as Map<String, dynamic>;
          await _db.upsertHeroEntry(
            heroId: heroId,
            entryType: map['et']?.toString() ?? '',
            entryId: map['ei']?.toString() ?? '',
            sourceType: map['st']?.toString() ?? 'import',
            sourceId: map['si']?.toString() ?? '',
            gainedBy: map['gb']?.toString() ?? 'grant',
            payload:
                map['pl'] != null ? _tryParseJson(map['pl'].toString()) : null,
          );
        }
      }

      // Import config
      final configs = snapshot['config'] as List?;
      if (configs != null) {
        for (final c in configs) {
          final map = c as Map<String, dynamic>;
          final key = map['k']?.toString() ?? '';
          final valueJson = map['v']?.toString() ?? '{}';
          if (key.isEmpty) continue;

          await _db.setHeroConfig(
            heroId: heroId,
            configKey: key,
            value: _tryParseJson(valueJson) ?? {},
          );
        }
      }

      // Import values
      final values = snapshot['values'] as List?;
      if (values != null) {
        for (final v in values) {
          final map = v as Map<String, dynamic>;
          final key = map['k']?.toString() ?? '';
          if (key.isEmpty) continue;

          await _db.into(_db.heroValues).insert(
                HeroValuesCompanion.insert(
                  heroId: heroId,
                  key: key,
                  value: Value(map['i'] as int?),
                  maxValue: Value(map['mx'] as int?),
                  doubleValue: Value(map['d'] as double?),
                  textValue: Value(map['t']?.toString()),
                  jsonValue: Value(map['j']?.toString()),
                ),
                mode: InsertMode.insertOrReplace,
              );
        }
      }

      // Import notes (with ID mapping for folder references)
      final notes = snapshot['notes'] as List?;
      if (notes != null) {
        // First pass: create ID mappings
        for (final n in notes) {
          final map = n as Map<String, dynamic>;
          final oldId = map['id']?.toString();
          if (oldId != null && oldId.isNotEmpty) {
            idMap[oldId] = _generateId();
          }
        }

        // Second pass: insert with mapped folder IDs
        for (final n in notes) {
          final map = n as Map<String, dynamic>;
          final oldId = map['id']?.toString() ?? '';
          final newId = idMap[oldId] ?? _generateId();
          final oldFolderId = map['fi']?.toString();
          final newFolderId = oldFolderId != null ? idMap[oldFolderId] : null;

          await _db.into(_db.heroNotes).insert(
                HeroNotesCompanion.insert(
                  id: newId,
                  heroId: heroId,
                  title: map['ti']?.toString() ?? '',
                  content: Value(map['co']?.toString() ?? ''),
                  folderId: Value(newFolderId),
                  isFolder: Value(map['if'] == true),
                  sortOrder: Value((map['so'] as num?)?.toInt() ?? 0),
                ),
              );
        }
      }

      // Import projects
      final projects = snapshot['projects'] as List?;
      if (projects != null) {
        for (final p in projects) {
          final map = p as Map<String, dynamic>;
          final newId = _generateId();

          await _db.into(_db.heroDowntimeProjects).insert(
                HeroDowntimeProjectsCompanion.insert(
                  id: newId,
                  heroId: heroId,
                  name: map['na']?.toString() ?? '',
                  projectGoal: (map['pg'] as num?)?.toInt() ?? 0,
                  templateProjectId: Value(map['tp']?.toString()),
                  description: Value(map['de']?.toString() ?? ''),
                  currentPoints: Value((map['cp'] as num?)?.toInt() ?? 0),
                  prerequisitesJson: Value(map['pq']?.toString() ?? '[]'),
                  projectSource: Value(map['ps']?.toString()),
                  sourceLanguage: Value(map['sl']?.toString()),
                  guidesJson: Value(map['gu']?.toString() ?? '[]'),
                  rollCharacteristicsJson: Value(map['rc']?.toString() ?? '[]'),
                  eventsJson: Value(map['ev']?.toString() ?? '[]'),
                  notes: Value(map['no']?.toString() ?? ''),
                  isCustom: Value(map['ic'] == true),
                  isCompleted: Value(map['cm'] == true),
                ),
              );
        }
      }

      // Import followers
      final followers = snapshot['followers'] as List?;
      if (followers != null) {
        for (final f in followers) {
          final map = f as Map<String, dynamic>;
          final newId = _generateId();

          await _db.into(_db.heroFollowers).insert(
                HeroFollowersCompanion.insert(
                  id: newId,
                  heroId: heroId,
                  name: map['na']?.toString() ?? '',
                  followerType: map['ft']?.toString() ?? '',
                  might: Value((map['m'] as num?)?.toInt() ?? 0),
                  agility: Value((map['a'] as num?)?.toInt() ?? 0),
                  reason: Value((map['r'] as num?)?.toInt() ?? 0),
                  intuition: Value((map['i'] as num?)?.toInt() ?? 0),
                  presence: Value((map['p'] as num?)?.toInt() ?? 0),
                  skillsJson: Value(map['sk']?.toString() ?? '[]'),
                  languagesJson: Value(map['la']?.toString() ?? '[]'),
                ),
              );
        }
      }

      // Import project sources
      final sources = snapshot['sources'] as List?;
      if (sources != null) {
        for (final s in sources) {
          final map = s as Map<String, dynamic>;
          final newId = _generateId();

          await _db.into(_db.heroProjectSources).insert(
                HeroProjectSourcesCompanion.insert(
                  id: newId,
                  heroId: heroId,
                  name: map['na']?.toString() ?? '',
                  type: map['ty']?.toString() ?? '',
                  language: Value(map['la']?.toString()),
                  description: Value(map['de']?.toString()),
                ),
              );
        }
      }

      // Import retainers
      final retainers = snapshot['retainers'] as List?;
      if (retainers != null) {
        for (final r in retainers) {
          final map = r as Map<String, dynamic>;
          final newId = _generateId();
          final now = DateTime.now();

          await _db.into(_db.heroRetainers).insert(
                HeroRetainersCompanion.insert(
                  id: newId,
                  heroId: heroId,
                  retainerComponentId: map['rc']?.toString() ?? '',
                  name: map['na']?.toString() ?? '',
                  role: map['ro']?.toString() ?? '',
                  isCustom: Value(map['ic'] == true),
                  customDataJson: Value(map['cd']?.toString()),
                  advancementChoicesJson:
                      Value(map['ac']?.toString() ?? '{}'),
                  characteristicChoicesJson:
                      Value(map['cc']?.toString() ?? '{}'),
                  isActive: Value(map['ia'] != false),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }
    });

    return heroId;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  int _idCounter = 0;

  /// Generate a unique ID for imported entities
  String _generateId() {
    _idCounter = (_idCounter + 1) % 1000000;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  /// Try to parse a JSON string, return null if invalid
  Map<String, dynamic>? _tryParseJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
      return null;
    } catch (_) {
      return null;
    }
  }
}
