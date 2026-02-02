import 'package:flutter/material.dart';

/// Centralized colors for story tabs/sections to avoid inline hex values.
class StoryTheme {
  StoryTheme._();

  // Accent colors per story sub-tab
  static const Color storyAccent = Color(0xFF8E24AA); // Purple
  static const Color skillsAccent = Color(0xFF43A047); // Green
  static const Color languagesAccent = Color(0xFF1E88E5); // Blue
  static const Color perksAccent = Color(0xFFFF7043); // Orange
  static const Color titlesAccent = Color(0xFFFFB300); // Gold

  // Shared dark surfaces used across story cards/dialogs
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color cardBackgroundDark = Color(0xFF252525);
}
