import 'dart:convert';

import 'hero_export_service.dart';

/// The consumer for an export artifact.
enum HeroExportTarget { nativeBackup, codexForge }

/// How seriously an export diagnostic affects the save workflow.
enum ExportIssueSeverity { info, warning, error }

/// The system responsible for an export diagnostic.
enum ExportIssueOrigin { heroData, heroSmith, codexUpstream }

/// A stable, user-presentable diagnostic emitted while building an export.
class ExportIssue {
  const ExportIssue({
    required this.code,
    required this.severity,
    required this.origin,
    required this.fieldPath,
    required this.message,
    this.entryType,
    this.entryId,
    this.sourceType,
    this.sourceId,
    this.suggestedAction,
  });

  final String code;
  final ExportIssueSeverity severity;
  final ExportIssueOrigin origin;
  final String fieldPath;
  final String message;
  final String? entryType;
  final String? entryId;
  final String? sourceType;
  final String? sourceId;
  final String? suggestedAction;

  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity.name,
        'origin': origin.name,
        'fieldPath': fieldPath,
        'message': message,
        if (entryType != null) 'entryType': entryType,
        if (entryId != null) 'entryId': entryId,
        if (sourceType != null) 'sourceType': sourceType,
        if (sourceId != null) 'sourceId': sourceId,
        if (suggestedAction != null) 'suggestedAction': suggestedAction,
      };
}

/// Counts what a target received from one canonical storage section.
class ExportSectionCoverage {
  const ExportSectionCoverage({
    required this.section,
    required this.inputCount,
    required this.emittedCount,
    this.unsupportedCount = 0,
    this.unresolvedCount = 0,
  });

  final String section;
  final int inputCount;
  final int emittedCount;
  final int unsupportedCount;
  final int unresolvedCount;

  Map<String, dynamic> toJson() => {
        'section': section,
        'inputCount': inputCount,
        'emittedCount': emittedCount,
        'unsupportedCount': unsupportedCount,
        'unresolvedCount': unresolvedCount,
      };
}

/// Diagnostics for an export. The report is deliberately kept out of files
/// consumed by third-party importers.
class ExportReport {
  const ExportReport({
    required this.target,
    required this.heroId,
    required this.formatVersion,
    this.importerRevision,
    this.coverage = const [],
    this.issues = const [],
  });

  final HeroExportTarget target;
  final String heroId;
  final int formatVersion;
  final String? importerRevision;
  final List<ExportSectionCoverage> coverage;
  final List<ExportIssue> issues;

  bool get hasErrors =>
      issues.any((issue) => issue.severity == ExportIssueSeverity.error);
  bool get hasWarnings =>
      issues.any((issue) => issue.severity == ExportIssueSeverity.warning);

  Map<String, dynamic> toJson() => {
        'target': target.name,
        'heroId': heroId,
        'formatVersion': formatVersion,
        if (importerRevision != null) 'importerRevision': importerRevision,
        'coverage': coverage.map((item) => item.toJson()).toList(),
        'issues': issues.map((item) => item.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// The immutable content and diagnostics produced from one export operation.
class ExportArtifact {
  const ExportArtifact({
    required this.content,
    required this.suggestedExtension,
    required this.report,
  });

  final String content;
  final String suggestedExtension;
  final ExportReport report;
}

/// Typed boundary between decoded HS2 JSON and native import writes.
///
/// The codec validates the wire shape before constructing this DTO. Individual
/// row fields remain map-backed for v2 compatibility, but callers no longer
/// pass an unchecked root JSON map into the import transaction.
class NativeHeroSnapshotV2 {
  const NativeHeroSnapshotV2({
    required this.hero,
    this.entries = const [],
    this.config = const [],
    this.values = const [],
    this.projects = const [],
    this.followers = const [],
    this.sources = const [],
    this.notes = const [],
    this.retainers = const [],
  });

  factory NativeHeroSnapshotV2.fromValidatedMap(Map<String, dynamic> map) =>
      NativeHeroSnapshotV2(
        hero: Map<String, dynamic>.from(map['hero'] as Map),
        entries: _rows(map['entries']),
        config: _rows(map['config']),
        values: _rows(map['values']),
        projects: _rows(map['projects']),
        followers: _rows(map['followers']),
        sources: _rows(map['sources']),
        notes: _rows(map['notes']),
        retainers: _rows(map['retainers']),
      );

  final Map<String, dynamic> hero;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> config;
  final List<Map<String, dynamic>> values;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> followers;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> retainers;

  static List<Map<String, dynamic>> _rows(dynamic value) {
    if (value == null) return const [];
    return (value as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}

/// Preview information for a hero import.
class HeroImportPreview {
  const HeroImportPreview({
    required this.name,
    required this.formatVersion,
    required this.isCompatible,
    this.className,
    this.ancestryName,
    this.level,
    this.exportOptions,
  });

  final String name;
  final int formatVersion;
  final bool isCompatible;
  final String? className;
  final String? ancestryName;
  final int? level;

  /// The export options used when this hero was exported.
  final ExportOptions? exportOptions;

  /// Human-readable description of what's included in this export.
  String get tierDescription => exportOptions?.label ?? 'Unknown';
}
