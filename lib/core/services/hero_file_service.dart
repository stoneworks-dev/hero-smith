import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';
import 'forge_steel_hero_export_service.dart';
import 'hero_export_models.dart';
import 'hero_export_service.dart';
import 'hero_export_workflow.dart';

/// Service for exporting/importing hero data as `.hero` files.
///
/// Uses [HeroExportService] for the actual encoding/decoding, then wraps
/// the result in file I/O with system dialogs (no permissions needed).
class HeroFileService {
  HeroFileService(this._db);
  final AppDatabase _db;

  // ===========================================================================
  // SINGLE HERO EXPORT
  // ===========================================================================

  /// Export a single hero to a `.hero` file.
  ///
  /// On mobile, opens the share sheet. On desktop, opens a save dialog.
  /// Returns `true` if the file was saved/shared successfully.
  Future<bool> exportHeroToFile(
    String heroId, {
    required String heroName,
    ExportOptions options = ExportOptions.full,
  }) async {
    final artifact = await buildNativeArtifact(heroId, options: options);
    return saveArtifactToFile(artifact, heroName: heroName);
  }

  /// Export a single hero to a Codex-compatible Forge Steel `.ds-hero` file.
  Future<bool> exportHeroToCodexFile(
    String heroId, {
    required String heroName,
  }) async {
    final artifact = await buildCodexArtifact(heroId);
    return saveArtifactToFile(artifact, heroName: heroName);
  }

  Future<ExportArtifact> buildNativeArtifact(
    String heroId, {
    ExportOptions options = ExportOptions.full,
  }) =>
      HeroExportService(_db).exportHeroToArtifact(heroId, options: options);

  Future<ExportArtifact> buildCodexArtifact(String heroId) =>
      ForgeSteelHeroExportService(_db).buildArtifact(heroId);

  /// Saves or shares an already reviewed artifact without rebuilding it.
  Future<bool> saveArtifactToFile(
    ExportArtifact artifact, {
    required String heroName,
    bool allowWarnings = false,
  }) async {
    final decision = HeroExportWorkflow.decisionFor(artifact.report);
    if (decision == ExportProceedDecision.blocked) {
      throw StateError('Export is blocked by report errors.');
    }
    if (decision == ExportProceedDecision.confirmationRequired &&
        !allowWarnings) {
      throw StateError('Export warnings require user confirmation.');
    }
    final fileName = _sanitizeFileName(heroName);
    final fileNameWithExtension = '$fileName.${artifact.suggestedExtension}';

    if (_isMobile) {
      return _shareFile(artifact.content, fileNameWithExtension);
    } else {
      return _saveFileWithPicker(artifact.content, fileNameWithExtension);
    }
  }

  // ===========================================================================
  // ALL HEROES EXPORT
  // ===========================================================================

  /// Export all heroes to individual `.hero` files.
  ///
  /// On mobile, shares them all via the share sheet.
  /// On desktop, asks for a folder and saves each file there.
  /// Returns the number of heroes successfully exported.
  Future<HeroBatchExportResult> exportAllHeroesToFiles({
    ExportOptions options = ExportOptions.full,
  }) async {
    final heroes = await _db.select(_db.heroes).get();
    if (heroes.isEmpty) {
      return const HeroBatchExportResult(entries: [], savedCount: 0);
    }

    final exportService = HeroExportService(_db);
    final exportedFiles = <MapEntry<String, String>>[]; // fileName → code

    final entries = <HeroBatchExportEntry>[];
    for (final hero in heroes) {
      try {
        final artifact =
            await exportService.exportHeroToArtifact(hero.id, options: options);
        if (HeroExportWorkflow.decisionFor(artifact.report) !=
            ExportProceedDecision.allowed) {
          entries.add(HeroBatchExportEntry(
            heroId: hero.id,
            heroName: hero.name,
            artifact: artifact,
            decision: HeroExportWorkflow.decisionFor(artifact.report),
          ));
          throw StateError('Batch export requires review for ${hero.name}.');
        }
        final fileName = _sanitizeFileName(hero.name);
        exportedFiles.add(
          MapEntry('$fileName.${artifact.suggestedExtension}', artifact.content),
        );
        entries.add(HeroBatchExportEntry(
          heroId: hero.id,
          heroName: hero.name,
          artifact: artifact,
          decision: ExportProceedDecision.allowed,
        ));
      } catch (e) {
        if (!entries.any((entry) => entry.heroId == hero.id)) {
          entries.add(HeroBatchExportEntry(
            heroId: hero.id,
            heroName: hero.name,
            error: e,
            decision: ExportProceedDecision.blocked,
          ));
        }
        if (kDebugMode) debugPrint('Failed to export hero ${hero.name}: $e');
      }
    }

    if (exportedFiles.isEmpty) {
      return HeroBatchExportResult(entries: entries, savedCount: 0);
    }

    final savedCount = _isMobile
        ? await _shareMultipleFiles(exportedFiles)
        : await _saveMultipleFilesWithPicker(exportedFiles);
    return HeroBatchExportResult(entries: entries, savedCount: savedCount);
  }

  // ===========================================================================
  // IMPORT
  // ===========================================================================

  /// Import a hero from a `.hero` file selected by the user.
  ///
  /// Opens a file picker, reads the file content, then imports via
  /// [HeroExportService.importHeroFromCode].
  ///
  /// Returns the new hero ID, or `null` if cancelled/failed.
  Future<String?> importHeroFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    String? content;

    // Try to read from bytes first (works on all platforms).
    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    }

    if (content == null || content.trim().isEmpty) return null;

    final exportService = HeroExportService(_db);
    return exportService.importHeroFromCode(content.trim());
  }

  /// Import multiple heroes from `.hero` files selected by the user.
  ///
  /// Returns a list of (heroId, heroName) pairs for successfully imported heroes.
  Future<List<MapEntry<String, String>>> importMultipleHeroesFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final exportService = HeroExportService(_db);
    final imported = <MapEntry<String, String>>[];

    for (final file in result.files) {
      try {
        String? content;
        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        }

        if (content == null || content.trim().isEmpty) continue;

        final preview = exportService.validateCode(content.trim());
        if (preview == null || !preview.isCompatible) continue;

        final heroId = await exportService.importHeroFromCode(content.trim());
        imported.add(MapEntry(heroId, preview.name));
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to import file ${file.name}: $e');
      }
    }

    return imported;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Validate a file's content without importing.
  HeroImportPreview? validateFileContent(String content) {
    final exportService = HeroExportService(_db);
    return exportService.validateCode(content.trim());
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Save a single file using the system save dialog (desktop).
  Future<bool> _saveFileWithPicker(String content, String fileName) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Hero File',
      fileName: fileName,
      type: FileType.any,
    );

    if (outputPath == null) return false;

    final file = File(outputPath);
    await file.writeAsString(content);
    return true;
  }

  /// Share a single file via the system share sheet (mobile).
  Future<bool> _shareFile(String content, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);

    final result = await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Hero Smith - Hero Export',
    );

    return result.status == ShareResultStatus.success;
  }

  /// Save multiple files to a user-selected folder (desktop).
  Future<int> _saveMultipleFilesWithPicker(
    List<MapEntry<String, String>> files,
  ) async {
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder to save hero files',
    );

    if (outputDir == null) return 0;

    var count = 0;
    for (final entry in files) {
      try {
        final file = File('$outputDir/${entry.key}');
        await file.writeAsString(entry.value);
        count++;
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to save ${entry.key}: $e');
      }
    }
    return count;
  }

  /// Share multiple files via the system share sheet (mobile).
  Future<int> _shareMultipleFiles(
    List<MapEntry<String, String>> files,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final xFiles = <XFile>[];

    for (final entry in files) {
      final file = File('${tempDir.path}/${entry.key}');
      await file.writeAsString(entry.value);
      xFiles.add(XFile(file.path));
    }

    final result = await Share.shareXFiles(
      xFiles,
      subject: 'Hero Smith - Heroes Export',
    );

    return result.status == ShareResultStatus.success ? files.length : 0;
  }

  /// Sanitize a hero name for use as a filename.
  String _sanitizeFileName(String name) {
    if (name.isEmpty) return 'unnamed_hero';
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }
}

/// One hero's outcome from a batch export attempt.
class HeroBatchExportEntry {
  const HeroBatchExportEntry({
    required this.heroId,
    required this.heroName,
    required this.decision,
    this.artifact,
    this.error,
  });

  final String heroId;
  final String heroName;
  final ExportProceedDecision decision;
  final ExportArtifact? artifact;
  final Object? error;

  ExportReport? get report => artifact?.report;
  bool get isReady => artifact != null && decision == ExportProceedDecision.allowed;
}

/// Aggregate batch result that retains non-exported heroes and their reports.
class HeroBatchExportResult {
  const HeroBatchExportResult({
    required this.entries,
    required this.savedCount,
  });

  final List<HeroBatchExportEntry> entries;
  final int savedCount;

  int get readyCount => entries.where((entry) => entry.isReady).length;
  int get notReadyCount => entries.length - readyCount;
}
