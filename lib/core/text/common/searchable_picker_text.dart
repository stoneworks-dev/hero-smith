/// Copy for the reusable searchable picker dialog.
class SearchablePickerText {
  SearchablePickerText._();

  static const searchHint = 'Search...';
  static const noMatchesFound = 'No matches found';
  static const unavailable = 'Unavailable';

  static const grantedByFeature = 'Granted by a feature (cannot be changed)';
  static const alreadyOwned = 'Already owned by this hero';
  static const alreadySelectedOnPage = 'Already selected on this page';

  static String duplicateDetected(String itemType, {required bool multiple}) =>
      'Duplicate $itemType${multiple ? 's' : ''} detected';

  static String duplicateDescription(String itemType) =>
      'Multiple features grant the same $itemType. Discuss with your Director to choose an alternative.';
}
