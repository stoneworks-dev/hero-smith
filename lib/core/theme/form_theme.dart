import 'package:flutter/material.dart';

/// Shared dark form surfaces used across dialogs, pickers, and editors.
class FormTheme {
  FormTheme._();

  /// Primary dark surface (common fillColor/background).
  static const Color surface = Color(0xFF2A2A2A);

  /// Darker surface for panels/rows that need stronger contrast.
  static const Color surfaceDark = Color(0xFF252525);

  /// Muted surface for dividers/secondary containers.
  static const Color surfaceMuted = Color(0xFF3A3A3A);
}
