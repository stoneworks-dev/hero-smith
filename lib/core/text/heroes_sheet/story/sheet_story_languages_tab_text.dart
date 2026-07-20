import '../../common/common_text.dart';

class SheetStoryLanguagesTabText {
  SheetStoryLanguagesTabText._();

  static const String languagesTitle = 'Languages';
  static const String addLanguage = 'Add Language';
  static const String addLanguageDialogTitle = 'Add Language';
  static const String searchLanguagesLabel = 'Search languages';
  static const String noLanguagesFound = 'No languages found';

  static const String otherGroup = 'Other';

  static const String languageAlreadyAdded = 'Language already added';
  static const String languageOwnedElsewhere =
      'This language is granted by another source and cannot be removed here.';
  static const String removeLanguageTooltip = 'Remove language';

  static const String emptyState =
      'No languages selected. Tap "Add Language" to get started.';

  // Error messages
  static String failedToLoadLanguages(Object e) =>
      'Failed to load languages: $e';
  static String failedToAddLanguage(Object e) => 'Failed to add language: $e';
  static String failedToRemoveLanguage(Object e) =>
      'Failed to remove language: $e';

  // Counts & labels
  static String languagesKnown(int count) => '$count languages known';
  static String region(String region) => 'Region: $region';
  static String ancestry(String ancestry) => 'Ancestry: $ancestry';
  static const String pickFromList = 'Pick from list';

  // Custom language creation
  static const String createCustomLanguage = 'Create Custom Language';
  static const String createCustomLanguageTitle = 'Create Custom Language';
  static const String languageNameLabel = 'Language Name';
  static const String languageNameHint = 'Enter language name';
  static const String languageNameRequired = 'Language name is required';
  static const String languageTypeLabel = 'Language Type';
  static const String languageTypeHint = 'Select a language type';
  static const String regionLabel = 'Region';
  static const String regionHint = 'Enter region (optional)';
  static const String ancestryLabel = 'Ancestry';
  static const String ancestryHint = 'Enter ancestry (optional)';
  static const String commonTopicsLabel = 'Common Topics';
  static const String commonTopicsHint =
      'Enter common topics, comma-separated (optional)';
  static const String relatedLanguagesLabel = 'Related Languages';
  static const String relatedLanguagesHint =
      'Enter related languages, comma-separated (optional)';
  static const String createButton = CommonText.create;
  static const String cancelButton = CommonText.cancel;
  static const String customType = 'custom';
}
