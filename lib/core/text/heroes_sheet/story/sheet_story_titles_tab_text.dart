class SheetStoryTitlesTabText {
  SheetStoryTitlesTabText._();

  static const String titlesTitle = 'Titles';
  static const String addTitle = 'Add Title';
  static const String addTitleDialogTitle = 'Add Title';
  static const String titleAlreadyAdded = 'Title already added';
  static const String noTitlesSelected = 'No titles selected';
  static const String unknown = 'Unknown';

  static const String removeTitleTooltip = 'Remove Title';

  static const String changeBenefit = 'Change Benefit';
  static const String searchTitlesLabel = 'Search titles';
  static const String allFilter = 'All';
  static const String noTitlesFound = 'No titles found';

  // Error messages
  static String failedToLoadTitles(Object e) =>
      'Failed to load titles: $e';
  static String failedToAddTitle(Object e) => 'Failed to add title: $e';
  static String failedToRemoveTitle(Object e) =>
      'Failed to remove title: $e';

  // Counts & labels
  static String titlesEarned(int count) => '$count titles earned';
  static String echelonLabel(dynamic echelon) => 'Echelon $echelon';
  static String prerequisite(String value) => 'Prerequisite: $value';
  static const String selectedBenefit = 'Selected Benefit:';
  static String special(String value) => 'Special: $value';
  static String grantsLabel(String formatted) => 'Grants: $formatted';
  static String plusRenown(dynamic value) => '+$value Renown';
  static String plusWealth(dynamic value) => '+$value Wealth';
  static String plusFollowersCap(dynamic value) =>
      '+$value Followers Cap';
  static String chooseSkill(dynamic value) => 'Choose $value Skill';
  static String language(dynamic value) => 'Language: $value';
  static String grantFallback(String type, dynamic value) =>
      '$type: $value';
  static String abilityLabel(String name) => 'Ability: $name';
  static String loadingAbility(String name) => 'Loading $name...';
  static String benefitLabel(int index) => 'Benefit ${index + 1}';
  static String selectBenefitFor(String name) =>
      'Select Benefit for $name';
  static String echelonWithBenefits(
          dynamic echelon, dynamic benefitCount) =>
      'Echelon $echelon \u2022 $benefitCount benefits';

  // Ancestry points grants
  static const String selectAncestryTraits = 'Select Ancestry Traits';
  static String ancestryTraitsTitle(String ancestry) =>
      ancestry.isEmpty ? 'Ancestry Traits' : '${ancestry[0].toUpperCase()}${ancestry.substring(1)} Traits';
  static String pointsBudget(int points) => '$points pts to spend';
  static String pointsRemaining(int remaining) => '$remaining remaining';
  static const String notEnoughPoints = 'Not enough points';
  static const String traitsSaved = 'Traits saved';
  static const String noTraitsSelected = 'Tap to select traits';
  static String traitsSelected(int count) => '$count trait(s) selected';

  // Skill choice grants
  static const String chooseSkillHint = 'Choose skill…';
  static String chooseSkillFromGroup(String group) =>
      'Choose ${group[0].toUpperCase()}${group.substring(1)} skill';
  static const String chooseAnySkill = 'Choose any skill';

  // Language choice grants
  static const String chooseLanguageHint = 'Choose language…';
  static String chooseLanguages(int count) => 'Choose $count language(s)';

  // Heroic ability choice grants
  static const String chooseHeroicAbility = 'Choose heroic ability';
  static const String chooseHeroicAbilityHint = 'Search abilities…';
  static const String heroicAbilityLabel = 'Heroic Ability';

  // Item prerequisite
  static String itemPrerequisite(String category, String tag) =>
      'Prerequisite met: $tag $category';

  // Damage immunity grants
  static const String damageImmunityTitle = 'Damage Immunity';
  static const String chooseDamageType = 'Choose damage type';
  static const String chooseDamageTypeHint = 'Tap to choose damage type';
  static String damageImmunityLevel(String type) =>
      '$type immunity = hero level';
  static String damageImmunityHighestChar(String type) =>
      '$type immunity = highest characteristic';
  static String damageImmunityStatic(String type, dynamic value) =>
      '$type immunity $value';

  // Condition immunity grants
  static String conditionImmunity(String condition) =>
      'Immune to $condition';
}
