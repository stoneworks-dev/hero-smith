import 'hero_export_service.dart';

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
