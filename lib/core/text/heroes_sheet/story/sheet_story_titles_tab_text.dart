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
}
