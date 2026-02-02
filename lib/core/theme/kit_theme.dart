import 'package:flutter/material.dart';
import 'app_text_styles.dart';

/// Kit-specific theming constants for colors, emojis, and component styling
class KitTheme {
  
  // Kit type emojis
  static const Map<String, String> kitTypeEmojis = {
    'kit': '🎒',
    'ward': '🛡️',
    'stormwight': '🌩️',
    'modifier': '✦',
    'augmentation': '✦',
    'enchantment': '✦',
    'prayer': '✦',
  };

  // Bonus type emojis
  static const Map<String, String> bonusEmojis = {
    'stamina': '💪',
    'speed': '💨',
    'disengage': '🏃',
    'damage': '⚔️',
    'bonus_damage': '⚔️',
    'ranged_distance': '🏹',
    'melee_distance': '⚔️',
    'stability': '🛡️',
    'characteristic': '📊',
    'lightning': '⚡',
    'storm': '🌩️',
    'keywords': '🏷️',
    'generic': '✨',
  };

  // Kit type color schemes
  static const Map<String, KitColorScheme> kitColorSchemes = {
    'kit': KitColorScheme(
      primary: Colors.cyan,
      badgeBackground: Color(0xFF00838F), // cyan.shade700
      borderColor: Color(0xFF26C6DA), // cyan.shade400
    ),
    'ward': KitColorScheme(
      primary: Colors.purple,
      badgeBackground: Color.fromARGB(255, 93, 23, 123), // purple.shade500
      borderColor: Color(0xFFAB47BC), // purple.shade400
    ),
    'stormwight': KitColorScheme(
      primary: Colors.indigo,
      badgeBackground: Color(0xFF3F51B5), // indigo.shade500
      borderColor: Color(0xFF5C6BC0), // indigo.shade400
    ),
    'stormwight_kit': KitColorScheme(
      primary: Colors.indigo,
      badgeBackground: Color(0xFF3F51B5), // indigo.shade500
      borderColor: Color(0xFF5C6BC0), // indigo.shade400
    ),
    'modifier': KitColorScheme(
      primary: Colors.amber,
      badgeBackground: Color(0xFFFF8F00), // amber.shade800
      borderColor: Color(0xFFFFCA28), // amber.shade400
    ),
    'enchantment': KitColorScheme(
      primary: Colors.amber,
      badgeBackground: Color(0xFFFF8F00), // amber.shade800
      borderColor: Color(0xFFFFCA28), // amber.shade400
    ),
    'psionic_augmentation': KitColorScheme(
      primary: Colors.deepPurple,
      badgeBackground: Color(0xFF512DA8), // deepPurple.shade700
      borderColor: Color(0xFF7E57C2), // deepPurple.shade400
    ),
    'prayer': KitColorScheme(
      primary: Colors.orange,
      badgeBackground: Color.fromARGB(255, 148, 104, 39), // orange.shade500
      borderColor: Color(0xFFFFB74D), // orange.shade400
    ),
  };

  // Text styles for kit components (derived from AppTextStyles)
  static final TextStyle badgeTextStyle = AppTextStyles.caption.copyWith(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle chipTextStyle = AppTextStyles.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle chipBoldTextStyle = AppTextStyles.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle sectionHeaderStyle = AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0.5,
  );

  static final TextStyle echelonLabelStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle echelonValueStyle = AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  // Helper methods for theme-aware colors
  static Color getChipBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.3)
        : primaryColor.shade50;
  }

  static Color getChipTextColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade200
        : primaryColor.shade700;
  }

  static Color getChipBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600
        : primaryColor.shade300;
  }

  static Color getSectionHeaderBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.3)
        : primaryColor.shade100;
  }

  static Color getSectionHeaderTextColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade200
        : primaryColor.shade800;
  }

  static Color getSectionHeaderBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade400
        : primaryColor.shade500;
  }

  static Color getTableBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.2)
        : primaryColor.shade50;
  }

  static Color getTableBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600
        : primaryColor.shade300;
  }

  static Color getTableLabelColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade300
        : primaryColor.shade700;
  }

  static Color getTableValueColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade300
        : Colors.grey.shade800;
  }

  // Enhanced chip row colors
  static Color getChipRowBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.4)
        : primaryColor.shade100;
  }

  static Color getChipRowTextColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade200
        : primaryColor.shade800;
  }

  static Color getChipRowBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade500
        : primaryColor.shade400;
  }

  // Echelon box colors for the new tab-style display
  static Color getEchelonBoxBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.2)
        : primaryColor.shade50.withOpacity(0.8);
  }

  static Color getEchelonBoxBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600.withOpacity(0.6)
        : primaryColor.shade300.withOpacity(0.8);
  }

  static Color getEchelonLabelColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade400.withOpacity(0.7)
        : primaryColor.shade500.withOpacity(0.7);
  }

  static Color getEchelonValueColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade200
        : primaryColor.shade700;
  }

  // Inner echelon box colors - paler than the outer container
  static Color getEchelonInnerBoxBackgroundColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800.withOpacity(0.3)
        : Colors.white.withOpacity(0.8);
  }

  static Color getEchelonInnerBoxBorderColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade600.withOpacity(0.4)
        : Colors.grey.shade300.withOpacity(0.6);
  }

  static Color getEchelonInnerLabelColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade500;
  }

  static Color getEchelonInnerValueColor(BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade200
        : Colors.grey.shade700;
  }

  // Get emoji for kit type
  static String getKitTypeEmoji(String kitType) {
    return kitTypeEmojis[kitType.toLowerCase()] ?? '✨';
  }

  // Get emoji for bonus type
  static String getBonusEmoji(String bonusType) {
    return bonusEmojis[bonusType.toLowerCase()] ?? '✨';
  }

  // Get color scheme for kit type
  static KitColorScheme getColorScheme(String kitType) {
    return kitColorSchemes[kitType.toLowerCase()] ?? kitColorSchemes['kit']!;
  }
}

/// Color scheme for a specific kit type
class KitColorScheme {
  final MaterialColor primary;
  final Color badgeBackground;
  final Color borderColor;

  const KitColorScheme({
    required this.primary,
    required this.badgeBackground,
    required this.borderColor,
  });
}