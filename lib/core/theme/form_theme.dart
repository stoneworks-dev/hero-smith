import 'package:flutter/material.dart';

/// Shared dark-surface tokens used across dialogs, pickers, editors,
/// and any widget that renders on a dark background.
///
/// **Surfaces:**  [surface] → [surfaceDark] → Card bg ([cardBackground])
/// **Text:**      [textBright] → [textPrimary] → [textSecondary] → [textMuted] → [textHint]
/// **Borders:**   [border] (default), [borderLight], [borderDim]
class FormTheme {
  FormTheme._();

  // ── Surfaces ─────────────────────────────────────────────────────────
  /// Primary dark surface (common fillColor / background).
  static const Color surface = Color(0xFF2A2A2A);

  /// Darker surface for panels/rows that need stronger contrast.
  static const Color surfaceDark = Color(0xFF252525);

  /// Slightly lighter surface for secondary containers / section rows.
  static const Color surfaceMuted = Color(0xFF3A3A3A);

  /// Dark card background (matches NavigationTheme.cardBackgroundDark).
  static const Color cardBackground = Color(0xFF1E1E1E);

  // ── Text Hierarchy (on dark surfaces) ────────────────────────────────
  /// Brightest text — pure white, for titles / emphasis.
  static const Color textBright = Colors.white;

  /// High-contrast body text on dark surfaces.
  static const Color textPrimary = Color(0xFFF5F5F5);     // ~grey.shade100

  /// Medium body text — labels, secondary info.
  static const Color textSecondary = Color(0xFFBDBDBD);    // ~grey.shade400

  /// Muted text — captions, helper text.
  static const Color textMuted = Color(0xFF9E9E9E);       // ~grey.shade500

  /// Placeholder / hint text inside inputs.
  static const Color textHint = Color(0xFF757575);         // ~grey.shade600

  /// Disabled / very faint text.
  static const Color textDisabled = Color(0xFF616161);     // ~grey.shade700

  // ── Borders (on dark surfaces) ───────────────────────────────────────
  /// Default border color for inputs, cards, dividers.
  static const Color border = Color(0xFF616161);           // ~grey.shade700

  /// Lighter border — subtle separators.
  static const Color borderLight = Color(0xFF757575);      // ~grey.shade600

  /// Dimmest border — faint lines, disabled inputs.
  static const Color borderDim = Color(0xFF424242);        // ~grey.shade800

  // ── Icons (on dark surfaces) ─────────────────────────────────────────
  /// Default icon color on dark backgrounds.
  static const Color icon = Color(0xFFBDBDBD);             // ~grey.shade400

  /// Muted / secondary icon color.
  static const Color iconMuted = Color(0xFF9E9E9E);        // ~grey.shade500

  // ── Dividers ─────────────────────────────────────────────────────────
  /// Standard divider on dark surfaces.
  static const Color divider = Color(0xFF616161);          // ~grey.shade700

  /// Subtle divider — lighter separation.
  static const Color dividerLight = Color(0xFF424242);     // ~grey.shade800
}
