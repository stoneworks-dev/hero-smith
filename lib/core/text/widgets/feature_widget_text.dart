class FeatureWidgetText {
  FeatureWidgetText._();

  static String searchFeatures(String className) =>
      'Search $className features...';
  static String levelLabel(int level) => 'Level $level';
  static String levelLabelDynamic(dynamic level) => 'Level $level';
}
