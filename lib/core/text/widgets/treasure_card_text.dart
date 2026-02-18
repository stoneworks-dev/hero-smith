class TreasureCardText {
  TreasureCardText._();

  // Section titles (shared across treasure cards)
  static const String effect = 'EFFECT';
  static const String artifactPowers = 'ARTIFACT POWERS';
  static const String baseEffect = 'BASE EFFECT';
  static const String levelVariants = 'LEVEL VARIANTS';
  static const String crafting = 'CRAFTING';
  static const String leveled = 'LEVELED';

  // Equip state
  static const String equipped = 'EQUIPPED';
  static const String equip = 'EQUIP';

  // Crafting row labels
  static const String prerequisite = 'Prerequisite';
  static const String source = 'Source';
  static const String roll = 'Roll';
  static const String goal = 'Goal';

  // Level labels
  static String levelLabel(int level) => 'LEVEL $level';
}
