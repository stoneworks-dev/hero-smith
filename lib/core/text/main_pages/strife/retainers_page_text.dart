class RetainersPageText {
  static const String appBarTitle = 'Retainers Compendium';
  static const String noRetainersFound = 'No retainers found';
  static String errorMessage(Object e) => 'Error loading retainers: $e';
  static String roleGroup(String role) =>
      '${role[0].toUpperCase()}${role.substring(1)}s';
  static const String otherRetainers = 'Other';
}
