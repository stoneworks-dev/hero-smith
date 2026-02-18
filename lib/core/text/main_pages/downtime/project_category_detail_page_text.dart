class ProjectCategoryDetailPageText {
  ProjectCategoryDetailPageText._();

  // Header
  static String projectCount(int count) => '$count projects in this category';

  // Project details
  static const String projectDetails = 'Project Details';
  static const String goal = 'Goal';
  static String goalPoints(dynamic goal) => '$goal points';
  static const String rollCharacteristics = 'Roll Characteristics:';

  // Prerequisites
  static const String prerequisites = 'Prerequisites';
  static String bulletItem(String name) => '• $name';
  static String labelPrefix(String label) => '$label: ';

  // Prerequisite labels
  static const String requiredItems = 'Required Items';
  static const String knowledgeSource = 'Knowledge Source';
  static const String locationRequired = 'Location Required';
  static const String skillRequired = 'Skill Required';
  static const String levelRequired = 'Level Required';
  static const String classRequired = 'Class Required';
  static const String featureRequired = 'Feature Required';
}
