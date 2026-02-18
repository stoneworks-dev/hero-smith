class TreasurePageText {
  static const String appBarTitle = 'Treasures';
  static const String consumablesTab = 'Consumables';
  static const String trinketsTab = 'Trinkets';
  static const String leveledTab = 'Leveled';
  static const String artifactsTab = 'Artifacts';
  static const String armorShieldsTitle = 'Armor & Shields';
  static const String armorTab = 'Armor';
  static const String shieldsTab = 'Shields';
  static const String armorAndShieldsNavTitle = 'Armor & Shields';
  static const String armorAndShieldsNavSubtitle =
      'Protective equipment and defensive gear';
  static const String implementsNavTitle = 'Implements';
  static const String implementsNavSubtitle = 'Magical focuses and casting tools';
  static const String weaponsNavTitle = 'Weapons';
  static const String weaponsNavSubtitle = 'Combat weapons and martial equipment';
  static const String otherNavTitle = 'Other';
  static const String otherNavSubtitle = 'Rings, cloaks, boots, and other wearables';
  static const String noTreasuresForType = 'No treasures available for this type';
  static const String noneAvailable = 'None available';

  static String errorMessage(Object e) => 'Error: $e';
  static String echelonTitle(int echelon, String displayName) =>
      '${_ordinal(echelon)} Echelon $displayName';
  static String echelonSubtitle(int echelon, String displayName) {
    return switch (echelon) {
      1 => 'Basic $displayName for starting adventurers',
      2 => 'Intermediate $displayName for experienced heroes',
      3 => 'Advanced $displayName for seasoned adventurers',
      4 => 'Master-level $displayName for legendary heroes',
      _ => '$displayName for echelon $echelon',
    };
  }

  static String _ordinal(int n) => switch (n) {
        1 => '1st',
        2 => '2nd',
        3 => '3rd',
        _ => '${n}th',
      };
}
