class EchelonTreasureDetailPageText {
  static const String noTreasuresForEchelon =
      'No treasures available for this echelon';

  static String errorMessage(Object e) => 'Error: $e';

  static String echelonName(int echelon) => switch (echelon) {
        1 => '1st Echelon',
        2 => '2nd Echelon',
        3 => '3rd Echelon',
        4 => '4th Echelon',
        _ => '${echelon}th Echelon',
      };
}
