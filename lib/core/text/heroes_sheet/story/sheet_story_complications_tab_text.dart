class SheetStoryComplicationsTabText {
  SheetStoryComplicationsTabText._();

  static const String headerTitle = 'Complications';
  static const String addComplication = 'Add Complication';
  static const String removeComplication = 'Remove Complication';
  static const String emptyState =
      'No complications selected. Tap "Add Complication" to get started.';
  static const String noComplicationsAvailable =
      'No more complications are available to add.';

  static String complicationsSelected(int count) {
    return count == 1
        ? '1 complication selected'
        : '$count complications selected';
  }

  static String failedToLoad(Object e) => 'Failed to load complications: $e';
  static String failedToSave(Object e) => 'Failed to save complication: $e';
}
