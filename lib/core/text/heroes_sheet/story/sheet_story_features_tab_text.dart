class SheetStoryFeaturesTabText {
  static const String noClassAssignedToHero = 'No class assigned to this hero';
  static const String noFeaturesAvailable = 'No features available';

  static String failedToLoadFeatures(Object error) =>
      'Failed to load features: $error';

  static String failedToSaveFeatureSelections(Object error) =>
      'Failed to save feature selections: $error';

  static String failedToSaveSkillSelection(Object error) =>
      'Failed to save skill selection: $error';
}
