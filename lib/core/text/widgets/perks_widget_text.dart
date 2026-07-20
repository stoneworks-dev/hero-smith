import '../common/common_text.dart';

class PerksWidgetText {
  PerksWidgetText._();

  // perks_selection_widget.dart
  static String failedToLoadPerks(Object e) => 'Failed to load perks: $e';
  static const String addPerk = 'Add Perk';
  static const String removePerk = 'Remove Perk';
  static const String cancel = CommonText.cancel;
  static const String remove = CommonText.remove;
  static const String perkAlreadyAdded = 'Perk already added';
  static const String perkOwnedElsewhere =
      'This perk is granted by another source and cannot be removed here.';
  static const String selectPerk = 'Select Perk';
  static const String choosePerk = 'Choose perk';
  static const String selectLanguage = 'Select Language';
  static String selectSkill(String group) => 'Select $group Skill';
  static const String chooseLanguage = 'Choose language';
  static const String chooseSkill = 'Choose skill';
  static const String searchHint = 'Search...';
  static const String noDescriptionAvailable = 'No description available';

  // perk_card.dart
  static String loadingAbility(String name) => 'Loading $name...';
  static String chosenSkill(String group) => 'Chosen $group Skill';
  static const String loading = CommonText.loading;
}
