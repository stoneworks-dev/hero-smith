class LevelDetailPageText {
  static const String subclassFeatures = 'Subclass Features';
  static const String maneuvers = 'Maneuvers';
  static const String magicalAbilities = 'Magical Abilities';
  static const String passiveFeatures = 'Passive Features';
  static const String coreFeatures = 'Core Features';

  static String appBarTitle(int level) => 'Level $level Features';
  static String featuresAvailable(int count) => '$count Features Available';
  static String classLevelTitle(String className, int level) =>
      '$className - Level $level';
}
