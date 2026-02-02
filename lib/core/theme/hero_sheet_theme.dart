import 'package:flutter/material.dart';

/// Accent tokens for hero sheet sections and related widgets.
class HeroSheetTheme {
  HeroSheetTheme._();

  // Section/tab accents
  static const Color mainAccent = Color(0xFF4CAF50); // Green
  static const Color abilitiesAccent = Color(0xFFFF9800); // Orange
  static const Color gearAccent = Color(0xFF7B1FA2); // Purple
  static const Color storyAccent = Color(0xFF2196F3); // Blue
  static const Color notesAccent =
      Color(0xFFD4A574); // Warm parchment/old book color

  // Followers (downtime tab) accent
  static const Color followersAccent = Color(0xFF7E57C2); // Purple

  /// Ordered list for TabBar usage
  static const List<Color> orderedSectionAccents = [
    mainAccent,
    abilitiesAccent,
    gearAccent,
    storyAccent,
    notesAccent,
  ];
}
