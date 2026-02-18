import '../../common/common_text.dart';

class SkillsPageText {
  static const String appBarTitle = 'Skills';
  static const String noSkillsFound = 'No skills found.';
  static const String cancel = CommonText.cancel;
  static const String delete = CommonText.delete;
  static const String craftingGroup = 'Crafting';
  static const String explorationGroup = 'Exploration';
  static const String interpersonalGroup = 'Interpersonal';
  static const String intrigueGroup = 'Intrigue';
  static const String loreGroup = 'Lore';
  static const String otherGroup = 'Other';

  static String errorMessage(Object e) => 'Error: $e';
  static String deleteCustomTitle(String type) => 'Delete Custom $type';
  static String removeConfirmation(String name) =>
      'Remove "$name"? This cannot be undone.';
}
