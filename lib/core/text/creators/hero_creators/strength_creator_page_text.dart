class StrengthCreatorPageText {
  static const String heroDataNotFoundMessage = 'Hero data could not be found.';
  static const String failedToLoadStrengthDataPrefix =
      'Failed to load strength data: ';
  static const String failedToRefreshFeaturesPrefix =
      'Failed to refresh features: ';
  static const String failedToSaveFeatureSelectionsPrefix =
      'Failed to save feature selections: ';
  static const String failedToSaveSkillSelectionPrefix =
      'Failed to save skill selection: ';
  static const String noticeTitleSomethingWentWrong = 'Something went wrong';
  static const String noticeActionRetryLabel = 'Retry';
  static const String noticeTitleClassRequired = 'Class required';
  static const String noticeMessageClassRequired =
      'Select a class on the Strife tab to load class features. A class is required before features can be shown.';
  static const String noticeTitleSubclassMissing = 'Subclass missing';
  static const String noticeMessageSubclassMissing =
      'Subclass features cannot be loaded until a subclass is chosen on the Strife tab.';
  static const String greenFormSectionTitle = 'Green Elementalist Forms';
  static const String chooseClassFirstMessage =
      'Choose a class first to load features.';
  static const String pendingChoicesSingular = '1 choice pending';
  static String pendingChoicesPlural(int count) => '$count choices pending';
  static const String pendingChoicesHint = 'Scroll down to find features requiring selections';
}
