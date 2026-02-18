class SheetStoryStoryTabText {
  SheetStoryStoryTabText._();

  static const String noStoryDataAvailable = 'No story data available';

  static const String heroSectionTitle = 'Hero';
  static const String nameLabel = 'Name';
  static const String levelLabel = 'Level';
  static const String classLabel = 'Class';
  static const String subclassLabel = 'Subclass';
  static const String unknown = 'Unknown';

  // Dynamic labels
  static String heroLevel(int level) => 'Level \$level';
  static String error(Object e) => 'Error: \$e';
}
