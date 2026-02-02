import 'package:flutter/material.dart';
import '../../core/theme/navigation_theme.dart';

/// A styled navigation card with customizable accent color for main page navigation.
/// 
/// Features a left accent stripe, colored icon container, and clean design.
/// Visually appealing without being overwhelming.
class NavCard extends StatelessWidget {
  /// The icon to display in the card's leading position
  final IconData icon;
  
  /// The main title text
  final String title;
  
  /// The subtitle/description text
  final String subtitle;
  
  /// Callback when the card is tapped
  final VoidCallback onTap;
  
  /// Optional accent color for the card. If not provided, uses the theme's primary color.
  final Color? accentColor;

  const NavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accentColor ?? scheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? NavigationTheme.cardBackgroundDark
                : scheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                height: 76,
                decoration: BoxDecoration(
                  gradient: NavigationTheme.accentStripeGradient(color),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Icon container
              Container(
                width: NavigationTheme.cardIconContainerSize,
                height: NavigationTheme.cardIconContainerSize,
                decoration: NavigationTheme.cardIconDecoration(color, isDark: isDark),
                child: Icon(
                  icon,
                  color: color,
                  size: NavigationTheme.cardIconSize,
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: NavigationTheme.cardTitleStyle(color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: NavigationTheme.cardSubtitleStyle(
                          scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: NavigationTheme.cardIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
