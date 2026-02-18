class SheetStoryComplicationSectionText {
  static const String sectionTitle = 'Complication';
  static const String errorLoadingComplicationPrefix =
      'Error loading complication: ';
  static const String complicationNotFound = 'Complication not found';
  static const String effectsTitle = 'Effects';
  static const String effectBenefitLabel = 'Benefit';
  static const String effectDrawbackLabel = 'Drawback';
  static const String effectMixedLabel = 'Mixed Effect';
  static const String grantsTitle = 'Grants';
  static const String abilityPrefix = 'Ability: ';
  static const String skillPrefix = 'Skill: ';
  static const String skillLoading = 'Skill: Loading...';
  static const String skillErrorLoading = 'Skill: Error loading';
  static const String chooseASkill = 'Choose a skill';
  static const String chooseOneOption = 'Choose one option';
  static const String ancestryTraitsLoading = 'Ancestry Traits: Loading...';
  static const String ancestryTraitsSelectedSuffix = ' selected';
  static const String languageLoadingSuffix = ': Loading...';
  static const String languageErrorLoadingSuffix = ': Error loading';
  static const String notFound = 'Not found';
  static const String ofYourChoice = 'of your choice';
  static String tokenSuffix(int count) => count == 1 ? 'token' : 'tokens';
  static String abilityGrant(String ability) => 'Ability: $ability';
  static String skillGrant(String skill) => 'Skill: $skill';
  static String loadingLabel(String label) => '${label}s: Loading...';
  static String errorLoadingLabel(String label) => '${label}s: Error loading';
  static String chooseLabel(int count, String label) =>
      'Choose $count $label${count == 1 ? '' : 's'}';
  static String chooseTraitPoints(int points, String ancestry) =>
      'Choose $points $ancestry ancestry trait point${points == 1 ? '' : 's'}';
  static String ancestryTraitsSelected(int count) =>
      'Ancestry Traits: $count selected';
  static String ancestryTraits(String ancestry) => '$ancestry Traits';
}
