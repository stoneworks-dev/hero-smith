import 'package:flutter/material.dart';

import 'navigation_theme.dart';
import 'form_theme.dart';

/// Design tokens and utilities for Hero Creator pages.
/// Provides consistent dark theme styling across all creator sections.
class CreatorTheme {
  CreatorTheme._();

  // ============================================================
  // SECTION ACCENT COLORS
  // ============================================================
  
  /// Name/Identity section
  static const Color nameAccent = Color(0xFF42A5F5);       // Blue
  
  /// Ancestry section
  static const Color ancestryAccent = Color(0xFF66BB6A);   // Green
  
  /// Culture section  
  static const Color cultureAccent = Color(0xFF26C6DA);    // Cyan
  
  /// Career section
  static const Color careerAccent = Color(0xFFFFB74D);     // Orange/Amber
  
  /// Complication section
  static const Color complicationAccent = Color(0xFFEF5350); // Red
  
  // ============================================================
  // STRIFE TAB ACCENT COLORS (thematic variety)
  // ============================================================
  
  /// Class/Level/Subclass - Crimson (combat class identity)
  static const Color classAccent = Color(0xFFE53935);      // Crimson Red
  
  /// Characteristics - Amber (core attributes)
  static const Color characteristicsAccent = Color(0xFFFFB300); // Amber
  
  /// Skills - Teal (learned expertise)
  static const Color skillsAccent = Color(0xFF26A69A);     // Teal
  
  /// Perks - Gold (special advantages)
  static const Color perksAccent = Color(0xFFFFD54F);      // Gold
  
  /// Abilities - Purple (magical powers)
  static const Color abilitiesAccent = Color(0xFFAB47BC);  // Purple
  
  /// Equipment - Emerald (gear/items)
  static const Color equipmentAccent = Color(0xFF43A047);  // Emerald Green
  
  /// Kit section
  static const Color kitAccent = Color(0xFF5C6BC0);        // Indigo

  // ============================================================
  // STRENGTH TAB ACCENT COLORS
  // ============================================================
  
  /// Strength tab primary accent - Deep Blue (power/features)
  static const Color strengthAccent = Color(0xFF5C6BC0);   // Deep Indigo
  
  // ============================================================
  // STATUS COLORS
  // ============================================================
  
  /// Error/critical state color
  static const Color errorColor = Color(0xFFEF5350);       // Red
  
  /// Warning/caution state color
  static const Color warningColor = Color(0xFFFFB74D);     // Orange/Amber
  
  /// Success/positive state color
  static const Color successColor = Color(0xFF66BB6A);     // Green
  
  // ============================================================
  // BACKGROUND & TEXT COLORS
  // ============================================================
  
  /// Card/surface background color
  static const Color cardBackground = Color(0xFF1E1E1E);
  
  /// Primary text color
  static const Color textPrimary = Color(0xFFF5F5F5);
  
  /// Secondary/muted text color
  static const Color textSecondary = Color(0xFFB0B0B0);

  // ============================================================
  // DIMENSIONS
  // ============================================================
  
  static const double sectionBorderRadius = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double inputBorderRadius = 10.0;
  static const double chipBorderRadius = 20.0;
  
  static const EdgeInsets sectionMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets sectionPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
  
  static const double sectionElevation = 4.0;
  
  // ============================================================
  // SECTION CARD DECORATION
  // ============================================================
  
  /// Main section card decoration with dark background
  static BoxDecoration sectionDecoration(Color accent) => BoxDecoration(
    borderRadius: BorderRadius.circular(sectionBorderRadius),
    color: NavigationTheme.cardBackgroundDark,
    border: Border.all(
      color: accent.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ============================================================
  // SECTION HEADER
  // ============================================================
  
  /// Builds a styled section header with icon, title, and subtitle
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    required Color accent,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(sectionBorderRadius),
        ),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.2),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.3), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withValues(alpha: 0.2),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ============================================================
  // SUB-SECTION CARD
  // ============================================================
  
  /// Card for sub-sections within a main section
  static BoxDecoration subSectionDecoration(Color accent) => BoxDecoration(
    borderRadius: BorderRadius.circular(cardBorderRadius),
    color: FormTheme.surfaceDark,
    border: Border.all(
      color: accent.withValues(alpha: 0.25),
      width: 1,
    ),
  );
  
  /// Sub-section header (smaller than main section)
  static Widget subSectionHeader({
    required String title,
    IconData? icon,
    required Color accent,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(cardBorderRadius),
        ),
        color: accent.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATIONS
  // ============================================================
  
  /// Styled input decoration for text fields
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
    Color? accent,
  }) {
    final color = accent ?? Colors.grey.shade400;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: Colors.grey.shade500)
          : null,
      suffix: suffix,
      filled: true,
      fillColor: FormTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  
  /// Styled decoration for dropdown selectors
  static InputDecoration dropdownDecoration({
    required String label,
    Color? accent,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: FormTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: accent ?? Colors.grey.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // ============================================================
  // CHIPS
  // ============================================================
  
  /// Styled action chip
  static Widget actionChip({
    required String label,
    required VoidCallback onPressed,
    Color? accent,
    IconData? icon,
  }) {
    final color = accent ?? Colors.grey.shade400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(chipBorderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(chipBorderRadius),
            color: color.withValues(alpha: 0.12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Selection chip (can be selected/deselected)
  static Widget selectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accent,
    IconData? icon,
  }) {
    final color = accent ?? Colors.grey.shade400;
    final bgColor = isSelected 
        ? color.withValues(alpha: 0.2)
        : Colors.transparent;
    final borderColor = isSelected 
        ? color.withValues(alpha: 0.6)
        : Colors.grey.shade600;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(chipBorderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(chipBorderRadius),
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  size: 16, 
                  color: isSelected ? color : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
              ],
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================
  
  /// Primary action button style
  static ButtonStyle primaryButtonStyle(Color accent) => FilledButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );
  
  /// Secondary/outline button style
  static ButtonStyle secondaryButtonStyle(Color accent) => OutlinedButton.styleFrom(
    foregroundColor: accent,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: BorderSide(color: accent),
  );

  // ============================================================
  // HELPER WIDGETS
  // ============================================================
  
  /// Info text style
  static TextStyle get infoTextStyle => TextStyle(
    color: Colors.grey.shade500,
    fontSize: 12,
    fontStyle: FontStyle.italic,
  );
  
  /// Label text style
  static TextStyle get labelTextStyle => TextStyle(
    color: Colors.grey.shade300,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  /// Body text style
  static TextStyle get bodyTextStyle => TextStyle(
    color: Colors.grey.shade300,
    fontSize: 14,
  );
  
  /// Builds a styled divider
  static Widget divider({Color? color}) => Divider(
    color: color?.withValues(alpha: 0.2) ?? Colors.grey.shade700,
    height: 24,
    thickness: 1,
  );
  
  /// Loading indicator with accent color
  static Widget loadingIndicator(Color accent) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: CircularProgressIndicator(
        color: accent,
        strokeWidth: 3,
      ),
    ),
  );
  
  /// Error message widget
  static Widget errorMessage(String message, {VoidCallback? onRetry, Color? accent}) {
    final color = accent ?? Colors.red.shade400;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: color, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: color),
              label: Text('Retry', style: TextStyle(color: color)),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG STYLING
  // ============================================================
  
  /// Dialog decoration
  static ShapeDecoration get dialogDecoration => ShapeDecoration(
    color: NavigationTheme.cardBackgroundDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  /// Builds a styled dialog title
  static Widget dialogTitle(String title, {IconData? icon, Color? accent}) {
    final color = accent ?? Colors.grey.shade300;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
