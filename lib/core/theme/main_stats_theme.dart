import 'package:flutter/material.dart';

/// Theming tokens for hero main stats (stamina, temp HP, coins).
class MainStatsTheme {
  MainStatsTheme._();

  /// Stamina zone colors (dark/light aware)
  static Color deadColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFE53935) : const Color(0xFFC62828);

  static Color dyingColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFF5722) : const Color(0xFFE64A19);

  static Color windedColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFFB300) : const Color(0xFFF57C00);

  static Color healthyColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);

  static Color tempHpColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF4DD0E1) : const Color(0xFF00ACC1);

  /// Coin palette used by CoinPurseWidget
  static const List<int> coinColors = [
    0xFFFFD54F, // Amber (Gold)
    0xFFB0BEC5, // Blue Grey (Silver)
    0xFFFF8A65, // Deep Orange (Copper)
    0xFFE57373, // Red (Ruby)
    0xFF4DD0E1, // Cyan (Diamond)
    0xFFFFFFFF, // White (Platinum)
  ];

  /// Hero token light fill
  static const Color heroTokenLight = Color(0xFFEDE9FE);
}
