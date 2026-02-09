class HeroStatInsightsText {
  static const String wealthNonePrimary = 'No notable wealth recorded yet.';
  static const String wealthNoneSecondary =
      'Increase wealth to unlock lifestyle perks.';
  static const String wealthSurpassedAll =
      'You have surpassed all recorded wealth tiers.';

  static String wealthScoreLine(int score, String description) {
    return 'Score $score: $description';
  }

  static String wealthNextTierLine(int score, String description) {
    return 'Next tier at $score: $description';
  }

  static const String renownNoFollowers =
      'Followers: none yet - grow your renown to attract allies.';
  static const String impressionUnknown =
      'Impression: your deeds are still largely unknown.';
  static const String followerSingular = 'supporter';
  static const String followerPlural = 'supporters';

  static String renownFollowersLine(int followers) {
    return 'Followers: $followers loyal ${followers == 1 ? followerSingular : followerPlural}.';
  }

  static String impressionTierLine(int value, String description) {
    return 'Impression $value: $description';
  }

  static String xpLevelMinPlusLine(int level, int minXp) {
    return 'Level $level: $minXp+ XP';
  }

  static String xpLevelRangeLine(int level, int minXp, int maxXp) {
    return 'Level $level: $minXp-$maxXp XP';
  }

  static String xpNextLevelNeededLine({
    required int totalXp,
    required int levelMaxXp,
    required int remainingToNextLevel,
  }) {
    return 'XP: $totalXp/$levelMaxXp ($remainingToNextLevel more needed)';
  }

  static String xpReadyToLevelUpLine({
    required int totalXp,
    required int nextLevelAtXp,
  }) {
    return 'Ready to level up! ($totalXp XP, next at $nextLevelAtXp)';
  }

  static const String maxLevelReached = 'Maximum level reached!';
}
