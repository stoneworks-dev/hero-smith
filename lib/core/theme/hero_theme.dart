import 'package:flutter/material.dart';

import 'navigation_theme.dart';

/// Hero-specific design tokens and theme utilities
class HeroTheme {
  HeroTheme._();

  // Hero status colors
  static const Color activeHero = Color(0xFF4CAF50);      // Green - active/ready
  static const Color draftHero = Color(0xFFFF9800);       // Orange - in progress
  static const Color completeHero = Color(0xFF2196F3);    // Blue - finished
  static const Color archivedHero = Color(0xFF9E9E9E);    // Grey - archived

  // Hero creation step colors
  static const Color identityStep = Color(0xFF6A1B9A);     // Purple - identity/name
  static const Color ancestryStep = Color(0xFF8BC34A);     // Light Green - origins
  static const Color cultureStep = Color(0xFF03A9F4);     // Light Blue - environment
  static const Color careerStep = Color(0xFFFF9800);      // Orange - profession
  static const Color completionStep = Color(0xFF9C27B0);  // Purple - finalization

  // Section colors for hero creator
  static const Color primarySection = Color(0xFF1976D2);   // Blue - main sections
  static const Color secondarySection = Color(0xFF7B1FA2); // Purple - sub-sections
  static const Color accentSection = Color(0xFFFF5722);   // Deep Orange - highlights
  
  // Culture subsection colors for better differentiation
  static const Color environmentColor = Color(0xFF4CAF50);  // Green - nature/environment
  static const Color organizationColor = Color(0xFF2196F3); // Blue - structure/organization
  static const Color upbringingColor = Color(0xFFFF9800);   // Orange - personal/upbringing

  // Card elevation and styling
  static const double cardElevation = 2.0;
  static const double heroCardElevation = 4.0;
  static const double sectionCardElevation = 1.0;
  
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius heroCardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius sectionRadius = BorderRadius.all(Radius.circular(8));

  /// Get color for hero creation step
  static Color getStepColor(String step) {
    switch (step.toLowerCase()) {
      case 'identity':
        return identityStep;
      case 'ancestry':
        return ancestryStep;
      case 'culture':
        return cultureStep;
      case 'career':
        return careerStep;
      case 'completion':
        return completionStep;
      default:
        return primarySection;
    }
  }

  /// Get color for culture subsections
  static Color getCultureSubsectionColor(String subsection) {
    switch (subsection.toLowerCase()) {
      case 'environment':
        return environmentColor;
      case 'organization':
      case 'organisation':
        return organizationColor;
      case 'upbringing':
        return upbringingColor;
      default:
        return cultureStep;
    }
  }

  /// Get light variant of step color for backgrounds
  static Color getStepColorLight(String step) {
    return getStepColor(step).withValues(alpha: 0.1);
  }

  /// Get hero status color
  static Color getHeroStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return activeHero;
      case 'draft':
        return draftHero;
      case 'complete':
        return completeHero;
      case 'archived':
        return archivedHero;
      default:
        return draftHero;
    }
  }

  /// Hero card theme
  static CardTheme heroCardTheme(BuildContext context) {
    return CardTheme(
      elevation: heroCardElevation,
      shape: const RoundedRectangleBorder(borderRadius: heroCardRadius),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Section card theme
  static BoxDecoration sectionDecoration(BuildContext context, {Color? accentColor}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      borderRadius: sectionRadius,
      color: theme.colorScheme.surface,
      border: Border.all(
        color: (accentColor ?? primarySection).withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Hero list tile theme
  static ListTileThemeData heroListTileTheme(BuildContext context) {
    final theme = Theme.of(context);
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Header gradient for hero pages
  static LinearGradient headerGradient(BuildContext context, {Color? primaryColor}) {
    final color = primaryColor ?? primarySection;
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Action button theme for hero creation
  static ButtonStyle primaryActionButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    );
  }

  /// Secondary action button theme
  static ButtonStyle secondaryActionButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: theme.colorScheme.outline),
    );
  }

  /// Chip theme for selections
  static ChipThemeData heroChipTheme(BuildContext context) {
    final theme = Theme.of(context);
    return ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: primarySection.withValues(alpha: 0.2),
      checkmarkColor: primarySection,
      labelStyle: theme.textTheme.bodyMedium,
    );
  }

  /// Progress indicator theme
  static Widget buildProgressIndicator(BuildContext context, double progress, {Color? color}) {
    final theme = Theme.of(context);
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: theme.colorScheme.surfaceContainer,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: color ?? primarySection,
          ),
        ),
      ),
    );
  }

  /// Empty state widget
  static Widget buildEmptyState(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.grey.shade300,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Section header widget
  static Widget buildSectionHeader(BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    Color? color,
    Widget? trailing,
  }) {
    final accentColor = color ?? primarySection;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: accentColor.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: NavigationTheme.cardIconDecoration(accentColor),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: accentColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
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
}
