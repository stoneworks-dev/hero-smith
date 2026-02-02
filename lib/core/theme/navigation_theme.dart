import 'package:flutter/material.dart';

/// Centralized navigation theming for the app.
/// 
/// Contains colors, styles, and configurations for:
/// - Bottom navigation bar
/// - Top tab bars
/// - Navigation cards on main pages
class NavigationTheme {
  NavigationTheme._();

  // ============================================================
  // COLORS - Navigation Section Colors
  // ============================================================

  /// Bottom nav / main section colors
  static const Color heroesColor = Color(0xFF4CAF50);      // Green
  static const Color strifeColor = Color(0xFFE65100);      // Deep orange
  static const Color storyColor = Color(0xFF2196F3);       // Blue  
  static const Color gearColor = Color(0xFF7B1FA2);        // Purple
  static const Color downtimeColor = Color(0xFF00838F);    // Teal

  /// Strife page nav card colors
  static const Color abilitiesColor = Color(0xFFE65100);   // Deep orange
  static const Color featuresColor = Color(0xFF6A1B9A);    // Deep purple
  static const Color conditionsColor = Color(0xFFC62828);  // Dark red

  /// Story page nav card colors
  static const Color ancestriesColor = Color(0xFF2E7D32);  // Green
  static const Color culturesColor = Color(0xFF0277BD);    // Light blue
  static const Color careersColor = Color(0xFF6D4C41);     // Brown
  static const Color complicationsColor = Color(0xFFAD1457); // Deep pink
  static const Color languagesColor = Color(0xFF00838F);   // Cyan
  static const Color skillsColor = Color(0xFF283593);      // Indigo
  static const Color titlesColor = Color(0xFFF9A825);      // Amber
  static const Color perksColor = Color(0xFF558B2F);       // Light green
  static const Color deitiesColor = Color(0xFFFF8F00);     // Orange

  /// Gear page nav card colors
  static const Color kitsColor = Color(0xFF1565C0);        // Blue
  static const Color itemsColor = Color(0xFF5D4037);       // Brown
  static const Color treasureColor = Color(0xFF7B1FA2);    // Purple

  /// Treasure page colors
  static const Color consumablesColor = Color(0xFF00897B); // Teal
  static const Color trinketsColor = Color(0xFF8E24AA);    // Purple
  static const Color leveledColor = Color(0xFFD84315);     // Deep orange
  static const Color artifactsColor = Color(0xFFFFC107);   // Amber/Gold
  
  /// Treasure echelon colors
  static const Color echelon1Color = Color(0xFF43A047);    // Green
  static const Color echelon2Color = Color(0xFF1E88E5);    // Blue
  static const Color echelon3Color =   Color(0xFF8E24AA);  // Purple
  static const Color echelon4Color =   Color(0xFFFB8C00);  // Orange
  
  /// Leveled treasure type colors
  static const Color armorColor = Color(0xFF6D4C41);       // Brown
  static const Color shieldColor = Color(0xFF546E7A);      // Blue grey
  static const Color implementColor = Color(0xFF5E35B1);   // Deep purple
  static const Color weaponColor = Color(0xFFC62828);      // Red

  /// Downtime tab colors
  static const Color projectsTabColor = Color(0xFF00695C); // Teal
  static const Color imbuementsTabColor = Color(0xFF6A1B9A); // Deep purple
  static const Color treasuresTabColor = Color(0xFFF9A825); // Amber
  static const Color eventsTabColor = Color(0xFF1565C0);   // Blue

  /// RPG tier progression colors (gray -> green -> blue -> purple -> orange)
  static const Color tierCommonColor = Color(0xFF9E9E9E);      // Gray (common)
  static const Color tierUncommonColor = Color(0xFF66BB6A);    // Green (uncommon)
  static const Color tierRareColor = Color(0xFF42A5F5);        // Blue (rare)
  static const Color tierEpicColor = Color(0xFFAB47BC);        // Purple (epic)
  static const Color tierLegendaryColor = Color(0xFFFFB74D);   // Orange/Yellow (legendary)

  // ============================================================
  // BACKGROUND COLORS
  // ============================================================
  
  /// Dark background for navigation bars
  static const Color navBarBackground = Color(0xFF1A1A1A);
  
  /// Dark background for cards
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);
  
  /// Unselected/inactive color
  static Color get inactiveColor => Colors.grey.shade600;

  // ============================================================
  // DIMENSIONS
  // ============================================================
  
  static const double navBarIconSize = 24.0;
  static const double navBarLabelSize = 11.0;
  static const double tabIconSize = 20.0;
  static const double tabLabelSize = 12.0;
  
  static const double cardBorderRadius = 14.0;
  static const double cardAccentStripeWidth = 5.0;
  static const double cardIconContainerSize = 48.0;
  static const double cardIconSize = 24.0;

  // ============================================================
  // DECORATIONS
  // ============================================================
  
  /// Box shadow for elevated navigation elements
  static List<BoxShadow> get navBarShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];
  
  /// Creates a pill-shaped background for selected nav items
  static BoxDecoration selectedNavItemDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(12),
  );

  /// Creates icon container decoration for nav cards
  static BoxDecoration cardIconDecoration(Color color, {bool isDark = true}) => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
    border: Border.all(
      color: color.withValues(alpha: 0.4),
      width: 1.5,
    ),
  );

  /// Creates the left accent stripe gradient
  static LinearGradient accentStripeGradient(Color color) => LinearGradient(
    colors: [
      color,
      color.withValues(alpha: 0.7),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================
  // TEXT STYLES
  // ============================================================
  
  static TextStyle navLabelStyle({
    required Color color,
    required bool isSelected,
  }) => TextStyle(
    color: color,
    fontSize: navBarLabelSize,
    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
  );

  static TextStyle tabLabelStyle({
    required Color color,
    required bool isSelected,
  }) => TextStyle(
    color: color,
    fontSize: tabLabelSize,
    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
  );

  static TextStyle cardTitleStyle(Color color) => TextStyle(
    fontWeight: FontWeight.w700,
    color: color,
    fontSize: 16,
    letterSpacing: 0.1,
  );

  static TextStyle cardSubtitleStyle(Color color) => TextStyle(
    color: color,
    fontSize: 13,
    height: 1.25,
  );

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get RPG tier color based on progress (0.0 to 1.0)
  /// gray -> green -> blue -> purple -> orange/yellow
  static Color getTierColor(double progress) {
    if (progress < 0.2) return tierCommonColor;
    if (progress < 0.4) return tierUncommonColor;
    if (progress < 0.6) return tierRareColor;
    if (progress < 0.8) return tierEpicColor;
    return tierLegendaryColor;
  }

  /// Get RPG tier color based on index in a list
  static Color getTierColorByIndex(int index, int total) {
    if (total <= 1) return tierCommonColor;
    final progress = index / (total - 1);
    return getTierColor(progress);
  }
}

/// Extension to easily get tab colors by index
extension DowntimeTabColors on int {
  Color get downtimeTabColor {
    switch (this) {
      case 0: return NavigationTheme.projectsTabColor;
      case 1: return NavigationTheme.imbuementsTabColor;
      case 2: return NavigationTheme.treasuresTabColor;
      case 3: return NavigationTheme.eventsTabColor;
      default: return NavigationTheme.inactiveColor;
    }
  }
}
