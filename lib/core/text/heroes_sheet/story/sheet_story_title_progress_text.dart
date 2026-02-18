class SheetStoryTitleProgressText {
  SheetStoryTitleProgressText._();

  // Page
  static const String pageTitle = 'Title Progress';
  static const String searchTitlesHint = 'Search titles...';
  static const String allFilter = 'All';
  static const String availableFilter = 'Available';
  static const String inProgressFilter = 'In Progress';
  static const String completedFilter = 'Completed';

  // Header
  static const String trackYourProgress = 'Track your journey towards earning titles';
  static String progressSummary(int completed, int total) =>
      '$completed / $total completed';

  // Echelon
  static String echelonLabel(int echelon) => 'Echelon $echelon';

  // Cards
  static const String prerequisiteLabel = 'Prerequisite';
  static const String requiresTitleLabel = 'Requires Title';
  static const String stepsLabel = 'Steps';
  static const String progressLabel = 'Progress';
  static const String markComplete = 'Mark Complete';
  static const String markIncomplete = 'Mark Incomplete';
  static const String addTitle = 'Add Title';
  static const String titleAdded = 'Title added!';
  static const String titleAlreadyEarned = 'Title already earned';
  static const String stepOf = 'Step';

  // Multi-step
  static String stepProgress(int done, int total) => '$done / $total';
  static String stepLabel(int index, int total) => 'Step ${index + 1} of $total';

  // Status
  static const String statusNotStarted = 'Not Started';
  static const String statusInProgress = 'In Progress';
  static const String statusComplete = 'Complete';

  // Errors
  static String failedToLoad(Object e) => 'Failed to load titles: $e';
  static const String retry = 'Retry';

  // Empty state
  static const String noTitlesMatch = 'No titles match your search';

  // Tooltips
  static const String resetProgress = 'Reset progress';
}
