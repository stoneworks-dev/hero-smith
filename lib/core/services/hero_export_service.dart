import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'hero_config_service.dart';
import 'hero_entry_normalizer.dart';
import 'hero_export_models.dart';
import 'hero_export_source.dart';
import 'native_snapshot_migrator.dart';
import 'native_snapshot_exceptions.dart';

/// Version of the export format. Increment when making breaking changes.
const int kExportVersion = 2;

/// Magic prefix for database snapshot exports
const String kExportMagic = 'HS2:';

/// Internal import lifecycle seam used to verify transaction rollback.
typedef NativeImportStageHook = FutureOr<void> Function(String stage);

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
    if (includeDowntime && includeTitles && includeNotes && includeRetainers) {
      return 'Full Export';
    }
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
  HeroExportService(this._db, {NativeImportStageHook? onImportStage})
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _normalizer = HeroEntryNormalizer(_db),
        _sourceLoader = HeroExportSourceLoader(_db),
        _onImportStage = onImportStage;

  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final HeroEntryNormalizer _normalizer;
  final HeroExportSourceLoader _sourceLoader;
  final NativeImportStageHook? _onImportStage;

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
  }) async =>
      (await exportHeroToArtifact(heroId, options: options)).content;

  /// Builds the native backup and its deterministic inclusion report together.
  /// The legacy string API delegates here to keep the `.hero` wire format
  /// unchanged while callers migrate to the report-aware workflow.
  Future<ExportArtifact> exportHeroToArtifact(
    String heroId, {
    ExportOptions options = ExportOptions.full,
  }) async {
    // Legacy migration is still needed to produce the current snapshot shape,
    // but export must never repair the live hero. Build from the normalized
    // transaction view and roll those temporary writes back afterwards.
    final source = await _buildReadOnlySource(heroId);
    final snapshot = _buildSnapshot(source, options);

    // Convert to JSON, compress with gzip, encode as base64
    final jsonStr = jsonEncode(snapshot);
    final jsonBytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(jsonBytes);
    final base64Str = base64Url.encode(compressed);

    final issues = <ExportIssue>[
      if (!options.includeDowntime)
        const ExportIssue(
          code: 'native.section_excluded',
          severity: ExportIssueSeverity.info,
          origin: ExportIssueOrigin.heroSmith,
          fieldPath: 'downtime',
          message: 'Downtime data was not included in this backup.',
        ),
      if (!options.includeTitles)
        const ExportIssue(
          code: 'native.section_excluded',
          severity: ExportIssueSeverity.info,
          origin: ExportIssueOrigin.heroSmith,
          fieldPath: 'titles',
          message: 'Title progress was not included in this backup.',
        ),
      if (!options.includeNotes)
        const ExportIssue(
          code: 'native.section_excluded',
          severity: ExportIssueSeverity.info,
          origin: ExportIssueOrigin.heroSmith,
          fieldPath: 'notes',
          message: 'Notes were not included in this backup.',
        ),
      if (!options.includeRetainers)
        const ExportIssue(
          code: 'native.section_excluded',
          severity: ExportIssueSeverity.info,
          origin: ExportIssueOrigin.heroSmith,
          fieldPath: 'retainers',
          message: 'Retainers were not included in this backup.',
        ),
    ];
    const sections = [
      'entries',
      'config',
      'values',
      'projects',
      'followers',
      'sources',
      'notes',
      'retainers',
    ];
    final sourceCounts = <String, int>{
      'entries': source.entries.length,
      'config': source.config.length,
      'values': source.values.length,
      'projects': source.projects.length,
      'followers': source.followers.length,
      'sources': source.sources.length,
      'notes': source.notes.length,
      'retainers': source.retainers.length,
    };
    final coverage = sections
        .map((section) {
          final emittedCount = (snapshot[section] as List?)?.length ?? 0;
          return ExportSectionCoverage(
            section: section,
            inputCount: sourceCounts[section] ?? 0,
            emittedCount: emittedCount,
          );
        })
        .toList(growable: false);

    return ExportArtifact(
      content: '$kExportMagic$base64Str',
      suggestedExtension: 'hero',
      report: ExportReport(
        target: HeroExportTarget.nativeBackup,
        heroId: heroId,
        formatVersion: kExportVersion,
        coverage: coverage,
        issues: issues,
      ),
    );
  }

  Future<HeroExportSource> _buildReadOnlySource(String heroId) async {
    late HeroExportSource source;
    try {
      await _db.transaction(() async {
        await _normalizer.normalize(heroId);
        source = await _sourceLoader.load(heroId) ??
            (throw ArgumentError('Hero not found: $heroId'));
        throw const _ReadOnlyExportComplete();
      });
    } on _ReadOnlyExportComplete {
      return source;
    }
    throw StateError('Native export completed without a snapshot.');
  }

  /// Build a complete snapshot of all hero data based on options
  Map<String, dynamic> _buildSnapshot(
    HeroExportSource source,
    ExportOptions options,
  ) {
    final snapshot = <String, dynamic>{
      'v': kExportVersion,
      'flags': options.flags,
      'ts': DateTime.now().toIso8601String(),
    };

    // Hero row (minimal fields needed to recreate)
    snapshot['hero'] = {
      'name': source.hero.name,
      'classComponentId': source.hero.classComponentId,
    };

    // Hero entries
    final entries = source.entries;
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
    final configs = source.config;
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

    // Hero values: export only numeric/current-state rows from the storage contract.
    final values = source.values
        .where((value) => HeroValueKeys.isAllowed(value.key))
        .toList();
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
      final projects = source.projects;
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
      final followers = source.followers;
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
      final sources = source.sources;
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
      final notes = source.notes;
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
      final retainers = source.retainers;
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
                  if (r.currentStamina != null) 'cs': r.currentStamina,
                  if (r.tempStamina != 0) 'ts': r.tempStamina,
                  if (r.currentRecoveries != null && r.currentRecoveries != 6)
                    'rr': r.currentRecoveries,
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
      throw const NativeSnapshotException(
        code: 'native.snapshot_decode_failed',
        fieldPath: r'$',
        message: 'Invalid hero code format',
      );
    }

    final migratedSnapshot = NativeSnapshotMigrator.migrateToCurrent(
      snapshot,
      currentVersion: kExportVersion,
    );

    _validateCurrentSnapshot(migratedSnapshot);

    return await _importSnapshot(
      NativeHeroSnapshotV2.fromValidatedMap(migratedSnapshot),
    );
  }

  /// Validates the current wire schema before an import transaction can create
  /// a root hero. Older schemas will move through a migrator here once native
  /// version migrations are introduced; malformed current data is never
  /// repaired by guessing defaults.
  void _validateCurrentSnapshot(Map<String, dynamic> snapshot) {
    final hero = snapshot['hero'];
    if (hero is! Map) {
      throw const NativeSnapshotValidationException(
        code: 'native.snapshot_invalid',
        fieldPath: 'hero',
        message: 'Invalid native snapshot: missing hero data',
      );
    }
    final name = hero['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const NativeSnapshotValidationException(
        code: 'native.snapshot_invalid',
        fieldPath: 'hero.name',
        message: 'Invalid native snapshot: hero name is required',
      );
    }

    _validateRows(
      snapshot['entries'],
      section: 'entries',
      requiredFields: const ['et', 'ei'],
    );
    _validateRows(
      snapshot['config'],
      section: 'config',
      requiredFields: const ['k', 'v'],
    );
    _validateRows(
      snapshot['values'],
      section: 'values',
      requiredFields: const ['k'],
    );
    for (final section in const [
      'projects',
      'followers',
      'sources',
      'notes',
      'retainers',
    ]) {
      _validateRows(snapshot[section], section: section);
    }
  }

  void _validateRows(
    dynamic value, {
    required String section,
    List<String> requiredFields = const [],
  }) {
    if (value == null) return;
    if (value is! List) {
      throw NativeSnapshotValidationException(
        code: 'native.snapshot_invalid',
        fieldPath: section,
        message: 'Invalid native snapshot: $section must be a list',
      );
    }
    for (var index = 0; index < value.length; index++) {
      final row = value[index];
      if (row is! Map) {
        throw NativeSnapshotValidationException(
          code: 'native.snapshot_invalid',
          fieldPath: '$section[$index]',
          message: 'Invalid native snapshot: $section[$index] must be an object',
        );
      }
      for (final field in requiredFields) {
        final fieldValue = row[field];
        if (fieldValue is! String || fieldValue.trim().isEmpty) {
          throw NativeSnapshotValidationException(
            code: 'native.snapshot_invalid',
            fieldPath: '$section[$index].$field',
            message:
                'Invalid native snapshot: $section[$index].$field is required',
          );
        }
      }
    }
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
  Future<String> _importSnapshot(NativeHeroSnapshotV2 snapshot) async {
    final heroName = snapshot.hero['name']!.toString();
    final classComponentId = snapshot.hero['classComponentId']?.toString();

    // Map old IDs to new IDs for cross-references (notes, projects, etc.)
    final idMap = <String, String>{};
    late String heroId;

    try {
      await _db.transaction(() async {
      // Root creation must be in the same transaction as every dependent row.
      heroId = await _db.createHero(name: heroName);
      await _onImportStage?.call('root-created');

      if (classComponentId != null && classComponentId.isNotEmpty) {
        await (_db.update(_db.heroes)..where((t) => t.id.equals(heroId))).write(
          HeroesCompanion(
            classComponentId: Value(classComponentId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      // Import entries
      if (snapshot.entries.isNotEmpty) {
        for (final map in snapshot.entries) {
          await _entries.addEntry(
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
      await _onImportStage?.call('entries-written');

      // Import config
      if (snapshot.config.isNotEmpty) {
        for (final map in snapshot.config) {
          final key = map['k']?.toString() ?? '';
          final valueJson = map['v']?.toString() ?? '{}';
          if (key.isEmpty) continue;

          await _config.setConfigValue(
            heroId: heroId,
            key: key,
            value: _tryParseJson(valueJson) ?? {},
            metadata: map['m']?.toString(),
          );
        }
      }
      await _onImportStage?.call('config-written');

      // Import values
      if (snapshot.values.isNotEmpty) {
        for (final map in snapshot.values) {
          final key = map['k']?.toString() ?? '';
          if (key.isEmpty) continue;

          await _db.upsertHeroValue(
            heroId: heroId,
            key: key,
            value: _toIntOrNull(map['i']),
            maxValue: _toIntOrNull(map['mx']),
            doubleValue: _toDoubleOrNull(map['d']),
            textValue: map['t']?.toString(),
            rawJsonValue: map['j']?.toString(),
          );
        }
      }
      await _onImportStage?.call('values-written');

      // Import notes (with ID mapping for folder references)
      if (snapshot.notes.isNotEmpty) {
        // First pass: create ID mappings
        for (final map in snapshot.notes) {
          final oldId = map['id']?.toString();
          if (oldId != null && oldId.isNotEmpty) {
            idMap[oldId] = _generateId();
          }
        }

        // Second pass: insert with mapped folder IDs
        for (final map in snapshot.notes) {
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
      if (snapshot.projects.isNotEmpty) {
        for (final map in snapshot.projects) {
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
      if (snapshot.followers.isNotEmpty) {
        for (final map in snapshot.followers) {
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
      if (snapshot.sources.isNotEmpty) {
        for (final map in snapshot.sources) {
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
      if (snapshot.retainers.isNotEmpty) {
        for (final map in snapshot.retainers) {
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
                  advancementChoicesJson: Value(map['ac']?.toString() ?? '{}'),
                  characteristicChoicesJson:
                      Value(map['cc']?.toString() ?? '{}'),
                  currentStamina: Value(_toIntOrNull(map['cs'])),
                  tempStamina: Value(_toIntOrNull(map['ts']) ?? 0),
                  currentRecoveries: Value(_toIntOrNull(map['rr']) ?? 6),
                  isActive: Value(map['ia'] != false),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }
      // Normalization can create dependent rows too, so it belongs to the
      // import transaction rather than being allowed to leave a partial hero.
        await _normalizer.normalize(heroId);
      });
    } on NativeSnapshotException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        NativeSnapshotImportException(
          code: 'native.import_rollback',
          fieldPath: r'$',
          message: 'Native import failed and was rolled back.',
          cause: error,
        ),
        stackTrace,
      );
    }

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

  int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Ends a transaction after its export snapshot has been captured. Drift rolls
/// the transaction back, leaving the hero exactly as it was before export.
class _ReadOnlyExportComplete implements Exception {
  const _ReadOnlyExportComplete();
}
