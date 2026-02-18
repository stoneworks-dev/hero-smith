class AncestriesPageText {
  static const String appBarTitle = 'Ancestries';
  static const String noAncestriesAvailable = 'No Ancestries Available';
  static const String ancestryDataWillAppear =
      'Ancestry data will appear here when loaded.';

  static String failedToLoadTraits(Object error) =>
      'Failed to load ancestry traits: $error';
  static String failedToLoadAncestries(Object error) =>
      'Failed to load ancestries: $error';
  static String countAvailable(int count) => '$count Available Ancestries';
}
