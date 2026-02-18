import '../../common/common_text.dart';

class ConditionsPageText {
  static const String appBarTitle = 'Conditions';
  static const String deleteConditionTitle = 'Delete Condition';
  static const String cancel = CommonText.cancel;
  static const String delete = CommonText.delete;
  static const String noConditionsAvailable = 'No conditions available';

  static String deleteConfirmation(String name) =>
      'Are you sure you want to delete "$name"? This action cannot be undone.';
  static String conditionDeleted(String name) =>
      'Condition "$name" deleted';
  static String errorDeletingCondition(Object e) =>
      'Error deleting condition: $e';
  static String countAvailable(int count) =>
      '$count conditions available';
  static String errorLoading(Object error) =>
      'Error loading conditions: $error';
}
