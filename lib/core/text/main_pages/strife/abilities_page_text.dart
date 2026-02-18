class AbilitiesPageText {
  static const String appBarTitle = 'Abilities Compendium';
  static const String searchHint = 'Search abilities by name...';
  static const String filtersLabel = 'Filters';
  static const String resourceFilter = 'Resource';
  static const String costFilter = 'Cost';
  static const String actionFilter = 'Action';
  static const String distanceFilter = 'Distance';
  static const String targetsFilter = 'Targets';
  static const String activeFiltersLabel = 'Active Filters';
  static const String clearAll = 'Clear All';
  static const String clearFilters = 'Clear Filters';
  static const String noAbilitiesMatchFilters = 'No abilities match your filters';
  static const String abilityLibraryTitle = 'Ability Library';
  static const String totalAbilities = 'Total abilities';
  static const String signatureNoCost = 'Signature (no cost)';
  static const String costedAbilities = 'Costed abilities';
  static const String resourceTypes = 'Resource types';
  static const String highestCost = 'Highest cost';
  static const String noAbilitiesFound = 'No abilities found';
  static const String checkDataSeed = 'Check your data seed or try syncing again.';
  static const String noAbilitiesBody =
      'We couldn\'t find any abilities in the database. '
      'Verify that the compendium has been seeded and then refresh this page.';
  static const String loadingAbilities = 'Loading abilities...';
  static const String unableToLoad = 'Unable to load abilities';
  static const String tryAgain = 'Please try again in a moment.';

  static String browseAbilities(int total) =>
      'Browse $total abilities by resource and cost.';
  static String allFilterLabel(String label) => 'All $label';
  static String nameFilter(String query) => 'Name: "$query"';
  static String resourceFilterChip(String filter) => 'Resource: $filter';
  static String costSignature = 'Cost: Signature';
  static String costFilterChip(String cost) => 'Cost: $cost';
  static String actionFilterChip(String filter) => 'Action: $filter';
  static String distanceFilterChip(String filter) => 'Distance: $filter';
  static String targetsFilterChip(String filter) => 'Targets: $filter';
}
