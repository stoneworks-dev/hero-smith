class CraftableTreasureTypeDetailPageText {
  static const String leveledTreasuresTitle = 'Leveled Treasures';
  static const String effectLabel = 'EFFECT';
  static const String levelVariantsLabel = 'LEVEL VARIANTS';
  static const String craftingProjectLabel = 'CRAFTING PROJECT';
  static const String projectGoalLabel = 'Project Goal';
  static const String goalNoteLabel = 'Goal Note';
  static const String rollCharacteristicsLabel = 'Roll Characteristics';
  static const String prerequisitesLabel = 'Prerequisites';
  static const String sourceLabel = 'Source';
  static const String armorType = 'Armor';
  static const String weaponsType = 'Weapons';
  static const String implementsType = 'Implements';
  static const String shieldsType = 'Shields';

  static String projectGoalValue(int goal) => '$goal points';
  static String levelLabel(int level) => 'LEVEL $level';
  static String summaryText(int total, int groups, {bool isLeveled = false}) =>
      '$total craftable items across $groups ${isLeveled ? 'equipment types' : 'echelons'}';
  static String imbuementsAcrossCategories(int total, int categories) =>
      '$total imbuements across $categories categories';
}
