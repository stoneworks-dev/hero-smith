import 'package:flutter/material.dart';
import 'app_text_styles.dart';

/// Treasure-specific theming constants for colors, emojis, and component styling
class TreasureTheme {
  // Treasure type emojis
  static const Map<String, String> treasureTypeEmojis = {
    'consumable': '🧪',
    'trinket': '💎',
    'leveled_treasure': '⚔️',
    'artifact': '✨',
    'treasure': '💎',
  };

  // Crafting section color (neutral blue-grey for prerequisites)
  static const MaterialColor craftingColor = Colors.blueGrey;

  // Keyword emojis
  static const Map<String, String> keywordEmojis = {
    'magic': '✨',
    'psionic': '🧠',
    'potion': '🧪',
    'oil': '🛢️',
    'light weapon': '🗡️',
    'medium weapon': '⚔️',
    'heavy weapon': '⚒️',
    'light armor': '🛡️',
    'medium armor': '🛡️',
    'heavy armor': '🛡️',
    'shield': '🛡️',
    'head': '👑',
    'neck': '📿',
    'arms': '💪',
    'hands': '🧤',
    'feet': '👢',
    'ring': '💍',
  };

  // Treasure type color schemes
  static const Map<String, TreasureColorScheme> treasureColorSchemes = {
    'consumable': TreasureColorScheme(
      primary: Colors.green,
      badgeBackground: Color(0xFF388E3C), // green.shade600
      borderColor: Color(0xFF66BB6A), // green.shade400
    ),
    'trinket': TreasureColorScheme(
      primary: Colors.blue,
      badgeBackground: Color(0xFF1976D2), // blue.shade700
      borderColor: Color(0xFF42A5F5), // blue.shade400
    ),
    'leveled_treasure': TreasureColorScheme(
      primary: Colors.purple,
      badgeBackground: Color(0xFF7B1FA2), // purple.shade700
      borderColor: Color(0xFFAB47BC), // purple.shade400
    ),
    'artifact': TreasureColorScheme(
      primary: Colors.amber,
      badgeBackground: Color(0xFFF57F17), // amber.shade800
      borderColor: Color(0xFFFFCA28), // amber.shade400
    ),
  };

  // Echelon colors
  static const Map<int, Color> echelonColors = {
    1: Color(0xFF4CAF50), // green
    2: Color(0xFF2196F3), // blue
    3: Color(0xFF9C27B0), // purple
    4: Color(0xFFFF9800), // orange
  };

  // Level colors for leveled treasures
  static const Map<int, Color> levelColors = {
    1: Color(0xFF4CAF50), // green
    5: Color(0xFF2196F3), // blue
    9: Color(0xFF9C27B0), // purple
  };

  // Text styles
  static final TextStyle treasureNameStyle = AppTextStyles.title.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static final TextStyle treasureDescriptionStyle = AppTextStyles.body.copyWith(
    fontSize: 14,
    height: 1.4,
  );

  static final TextStyle sectionTitleStyle = AppTextStyles.subtitle.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
  );

  static final TextStyle effectTextStyle = AppTextStyles.body.copyWith(
    fontSize: 13,
    height: 1.5,
  );

  static final TextStyle levelHeaderStyle = AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Colors.white,
  );

  static final TextStyle prerequisiteStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontStyle: FontStyle.italic,
  );

  static final TextStyle keywordChipStyle = AppTextStyles.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Helper methods for theme-aware colors
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 37, 36, 36)
        : Colors.white;
  }

  static Color getCardBorderColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600.withOpacity(0.3)
        : primaryColor.shade300.withOpacity(0.5);
  }

  static Color getSectionBackgroundColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.2)
        : primaryColor.shade50.withOpacity(0.8);
  }

  static Color getSectionBorderColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600.withOpacity(0.5)
        : primaryColor.shade300.withOpacity(0.8);
  }

  static Color getKeywordChipBackgroundColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade800.withOpacity(0.4)
        : primaryColor.shade100;
  }

  static Color getKeywordChipTextColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade200
        : primaryColor.shade700;
  }

  static Color getKeywordChipBorderColor(
      BuildContext context, MaterialColor primaryColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryColor.shade600
        : primaryColor.shade400;
  }

  static Color getLevelBackgroundColor(BuildContext context, int level) {
    final baseColor = levelColors[level] ?? Colors.grey;
    return Theme.of(context).brightness == Brightness.dark
        ? baseColor.withOpacity(0.8)
        : baseColor;
  }

  static Color getEchelonBadgeColor(BuildContext context, int echelon) {
    final baseColor = echelonColors[echelon] ?? Colors.grey;
    return Theme.of(context).brightness == Brightness.dark
        ? baseColor.withOpacity(0.8)
        : baseColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade200
        : Colors.grey.shade800;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
  }

  // Get emoji for treasure type
  static String getTreasureTypeEmoji(String treasureType) {
    return treasureTypeEmojis[treasureType.toLowerCase()] ?? '💎';
  }

  // Get emoji for keyword
  static String getKeywordEmoji(String keyword) {
    return keywordEmojis[keyword.toLowerCase()] ?? '✨';
  }

  // Get color scheme for treasure type
  static TreasureColorScheme getColorScheme(String treasureType) {
    return treasureColorSchemes[treasureType.toLowerCase()] ??
        treasureColorSchemes['consumable']!;
  }
}

/// Color scheme for a specific treasure type
class TreasureColorScheme {
  final MaterialColor primary;
  final Color badgeBackground;
  final Color borderColor;

  const TreasureColorScheme({
    required this.primary,
    required this.badgeBackground,
    required this.borderColor,
  });
}
