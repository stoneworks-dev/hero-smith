class SheetStoryPerksTabText {
  SheetStoryPerksTabText._();

  static const String headerTitle = 'Perks';
  static const String headerSubtitle =
      'Special abilities and bonuses from your career and titles';
  static const String emptyState =
      'No perks selected. Tap "Add Perk" to get started.';

  // Error messages & counts
  static String failedToLoadData(Object e) => 'Failed to load data: $e';
  static String perksSelected(int count) => '$count perks selected';

  // Dialog
  static const String addPerk = 'Add Perk';
  static const String searchPerks = 'Search perks';
  static const String noPerksFound = 'No perks found';
}
