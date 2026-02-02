/// Preview information for a hero import.
class HeroImportPreview {
  const HeroImportPreview({
    required this.name,
    required this.formatVersion,
    required this.isCompatible,
    this.className,
    this.ancestryName,
    this.level,
    this.exportTier,
  });

  final String name;
  final int formatVersion;
  final bool isCompatible;
  final String? className;
  final String? ancestryName;
  final int? level;

  /// The tier level used when this hero was exported (1-3)
  final int? exportTier;

  /// Human-readable description of what's included in this export
  String get tierDescription {
    switch (exportTier) {
      case 1:
        return 'Core build only';
      case 2:
        return 'Build + downtime data';
      case 3:
        return 'Full export (includes notes)';
      default:
        return 'Unknown tier';
    }
  }
}
