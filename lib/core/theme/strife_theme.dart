import 'package:flutter/material.dart';

/// Design tokens for Strife-related flows (class, abilities, strife creator).
class StrifeTheme {
  StrifeTheme._();

  // Shared layout metrics
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(vertical: 16, horizontal: 20);
  static const double cardElevation = 2.0;

  // Strife flow accent colors
  static const Color levelAccent = Color(0xFF4FC3F7);
  static const Color classAccent = Color(0xFF9575CD);
  static const Color resourceAccent = Color(0xFFFFB74D);
  static const Color potencyAccent = Color(0xFF81C784);
  static const Color skillsAccent = Color(0xFFFF8A65);
  static const Color abilitiesAccent = Color(0xFFE65100);   // Deep orange (matches NavigationTheme)
  static const Color featuresAccent = Color(0xFF6A1B9A);    // Deep purple (matches NavigationTheme)

  /// Lightweight gradient background for section headers.
  static LinearGradient headerGradient(Color color) => LinearGradient(
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Card decoration used across Strife creator sections.
  static BoxDecoration cardDecoration(BuildContext context, {Color? accent}) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return BoxDecoration(
      borderRadius: cardRadius,
      color: theme.colorScheme.surface,
      border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Section header widget for Strife flows.
  static Widget sectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    Color? accent,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: headerGradient(color),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.25), width: 1.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  /// Helper chip style for Strife data highlights.
  static ChipThemeData chipTheme(BuildContext context) {
    final theme = Theme.of(context);
    return ChipThemeData(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
      labelStyle: theme.textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
