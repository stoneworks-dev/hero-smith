import 'package:flutter/material.dart';

/// Central color definitions for the Draw Steel Hero Smith app.
///
/// This file contains:
/// - Brand/palette colors
/// - Characteristic colors (M/A/R/I/P)
/// - Potency colors
/// - Foundational UI tokens (borders, states, overlays, text hierarchy)
///
/// For ability-related colors (actions, keywords, heroic resources, damage types),
/// use [AbilityColors] directly or through semantic tokens in [semantic_tokens.dart].
class AppColors {
  AppColors._();

  // ── Brand / Palette ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2C6E49);
  static const Color secondary = Color(0xFF4C956C);
  static const Color accent = Color(0xFFFFA500);

  // ── Surface & Background ─────────────────────────────────────────────
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF7F7F7);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ── Text Hierarchy ───────────────────────────────────────────────────
  /// Primary text color for dark themes / on dark surfaces
  static const Color textOnDark = Color(0xFFE5E7EB);
  /// Secondary text color for dark themes / on dark surfaces
  static const Color textOnDarkSecondary = Color(0xFFD1D5DB);
  /// Primary text color for light themes / on light surfaces
  static const Color textOnLight = Color(0xFF1F2937);
  /// Secondary text color for light themes / on light surfaces
  static const Color textOnLightSecondary = Color(0xFF6B7280);
  /// Hint / placeholder text
  static const Color hintText = Color(0xFF9CA3AF);

  // ── Backward-compatible aliases ──────────────────────────────────────
  /// @Deprecated: Use [textOnDark] instead
  static const Color textPrimary = textOnDark;
  /// @Deprecated: Use [textOnDarkSecondary] instead
  static const Color textSecondary = textOnDarkSecondary;

  // ── Borders & Dividers ───────────────────────────────────────────────
  static const Color border = Color(0xFFD1D5DB);        // grey.shade300 equivalent
  static const Color borderLight = Color(0xFFE5E7EB);   // grey.shade200 equivalent
  static const Color borderDark = Color(0xFF9CA3AF);     // grey.shade400 equivalent
  static const Color divider = Color(0xFFE5E7EB);

  // ── Semantic State Colors ────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFBBDEFB);

  // ── Snackbar Colors ──────────────────────────────────────────────────
  static const Color snackbarSuccess = Color(0xFF2E7D32);
  static const Color snackbarError = Color(0xFFC62828);
  static const Color snackbarWarning = Color(0xFFE65100);
  static const Color snackbarInfo = Color(0xFF1565C0);

  // ── Overlays & Barriers ──────────────────────────────────────────────
  static const Color barrierColor = Colors.black54;
  static const Color overlayLight = Color(0x33000000); // black ~20%
  static const Color overlayDark = Color(0x8A000000);  // black ~54%

  // ── Characteristic Colors ────────────────────────────────────────────
  static const Color mightColor = Color(0xFFD32F2F);    // Red
  static const Color agilityColor = Color(0xFF388E3C);   // Green
  static const Color reasonColor = Color(0xFF1976D2);    // Blue
  static const Color intuitionColor = Color(0xFF7B1FA2); // Purple
  static const Color presenceColor = Color(0xFFF57C00);  // Orange

  // ── Potency Strength Colors ──────────────────────────────────────────
  static const Color weakPotencyColor = Color(0xFF81C784);    // Light Green
  static const Color averagePotencyColor = Color(0xFFFFB74D); // Light Orange
  static const Color strongPotencyColor = Color(0xFFE57373);  // Light Red
  static const Color potencyFallback = Color(0xFF5D4037);     // Brown

  // ── UI Element Fallbacks ─────────────────────────────────────────────
  static const Color rangeTargetColor = Color(0xFF546E7A); // Blue Grey
}