import '../../common/common_text.dart';

class LanguagesPageText {
  static const String appBarTitle = 'Languages';
  static const String noLanguagesFound = 'No languages found.';
  static const String humanLanguages = 'Human Languages';
  static const String ancestralLanguages = 'Ancestral Languages';
  static const String deadLanguages = 'Dead Languages';
  static const String otherLanguages = 'Other Languages';
  static const String cancel = CommonText.cancel;
  static const String delete = CommonText.delete;

  static String errorMessage(Object e) => 'Error: $e';
  static String languageGroupTitle(String type) =>
      '${type[0].toUpperCase()}${type.substring(1)} Languages';
  static String deleteCustomTitle(String type) => 'Delete Custom $type';
  static String removeConfirmation(String name) =>
      'Remove "$name"? This cannot be undone.';
}
