import '../../common/common_text.dart';

class ProjectsListTabText {
  static const String activeProjectsHeader = 'Active Projects';
  static const String completedProjectsHeader = 'Completed Projects';
  static const String createProjectButtonLabel = 'Create Project';
  static const String browseProjectsButtonLabel = 'Browse Projects';
  static const String emptyTitle = 'No Projects Yet';
  static const String emptySubtitle =
      'Create a project or browse templates using the buttons above';
  static const String errorTitle = 'Failed to load projects';
  static const String retryButtonLabel = 'Retry';
  static const String deleteDialogTitle = 'Remove Project';
  static const String deleteDialogCancel = CommonText.cancel;
  static const String deleteDialogConfirm = CommonText.remove;
  static const String addPointsDialogTitle = 'Add Points';
  static const String addPointsFieldLabel = 'Points to Add';
  static const String addPointsFieldHint = 'Enter amount';
  static const String addPointsDialogCancel = CommonText.cancel;
  static const String addPointsDialogConfirm = CommonText.add;
  static String removeConfirmation(String name) =>
      'Are you sure you want to remove "$name"? This action cannot be undone.';
  static String removedProject(String name) => 'Removed "$name"';
  static String addPointsTo(String name) => 'Add points to: $name';
  static String currentPoints(int current, int goal) =>
      'Current: $current / $goal';
  static String addedPoints(int result, String name) =>
      'Added $result points to $name';
  static String treasureAlreadyInGear(String name) =>
      '"$name" is already in your gear!';
  static String treasureAdded(String name) => 'Added "$name" to your gear!';
  static String failedToAddTreasure(Object e) => 'Failed to add treasure: $e';
  static String imbuementAlreadyInGear(String name) =>
      '"$name" is already in your gear!';
  static String imbuementAdded(String name) => 'Added "$name" to your gear!';
  static String failedToAddImbuement(Object e) =>
      'Failed to add imbuement: $e';
}
