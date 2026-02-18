import '../common/common_text.dart';

class HeroesPageText {
  HeroesPageText._();

  // Header
  static const String aboutHeroSmith = 'About Hero Smith';
  static const String yourHeroes = 'Your Heroes';
  static const String heroesSubtitle = 'Create and manage your Draw Steel heroes';

  // Actions
  static const String createNewHero = 'Create New Hero';
  static const String importExportTooltip = 'Import & Export';
  static const String importFromCode = 'Import from Code';
  static const String importFromFile = 'Import from File';
  static const String exportAllHeroes = 'Export All Heroes';
  static const String exportCode = 'Export Code';
  static const String exportFile = 'Export File';
  static const String editHeroTooltip = 'Edit Hero';
  static const String delete = CommonText.delete;
  static String heroLevel(int level) => 'Lvl $level';

  // Empty state
  static const String about = 'About';
  static const String noHeroesYet = 'No Heroes Yet';
  static const String emptySubtitle = 'Create your first hero to begin your Draw Steel adventure';
  static const String createFirstHero = 'Create First Hero';
  static const String importCode = 'Import Code';
  static const String importFile = 'Import File';

  // Error state
  static const String failedToLoadHeroes = 'Failed to Load Heroes';
  static const String retry = 'Retry';

  // Loading state
  static const String loadingHeroes = 'Loading heroes...';

  // Delete dialog
  static const String deleteHero = 'Delete Hero';
  static String deleteConfirmation(String name) =>
      'Are you sure you want to delete "$name"? This cannot be undone.';
  static const String cancel = CommonText.cancel;
  static String deletedHero(String name) => 'Deleted $name';

  // Export code dialog
  static String exportName(String name) => 'Export $name';
  static const String exportShareMessage =
      'Share this code with a friend so they can import your hero build.';
  static String codeInfo(int length, String tierDescription) =>
      '$length characters \u2022 $tierDescription';
  static const String close = CommonText.close;
  static const String codeCopied = 'Code copied to clipboard!';
  static const String copyCode = 'Copy Code';
  static String failedToExportHero(Object e) => 'Failed to export hero: $e';

  // Import dialog
  static const String importHero = 'Import Hero';
  static const String importPasteMessage =
      'Paste a hero code from a friend to add their build to your heroes.';
  static const String importHintText = 'HS2:...';
  static const String pasteFromClipboard = 'Paste from clipboard';
  static String characterCount(int count) => '$count characters';
  static const String import_ = 'Import';
  static const String invalidHeroCodeFormat = 'Invalid hero code format';
  static String incompatibleVersion(int version) =>
      'Incompatible version (v$version). Please ask for an updated code.';
  static String importedSuccessfully(String name, String tierInfo) =>
      'Imported "$name"$tierInfo successfully!';
  static String failedToImport(Object e) => 'Failed to import: $e';

  // Export file
  static String exportedToFile(String name) => 'Exported "$name" to file';
  static String failedToExportFile(Object e) => 'Failed to export file: $e';

  // Import file
  static const String heroImportedSuccessfully = 'Hero imported successfully!';
  static String failedToImportFile(Object e) => 'Failed to import file: $e';

  // Export all
  static String exportedHeroesToFiles(int count) =>
      'Exported $count hero(es) to files';
  static const String noHeroesToExport = 'No heroes to export';
  static String failedToExportHeroes(Object e) =>
      'Failed to export heroes: $e';

  // Export options dialog
  static const String chooseExportContent =
      'Choose what to include in the export:';
  static const String export_ = 'Export';

  // Data values
  static const String allHeroes = 'All Heroes';
}
