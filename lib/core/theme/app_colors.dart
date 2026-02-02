import 'package:flutter/material.dart';

/// Central color definitions for the Draw Steel Hero Smith app
class AppColors {
  AppColors._();

  // Brand / Palette
  static const Color primary = Color(0xFF2C6E49);
  static const Color secondary = Color(0xFF4C956C);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color accent = Color(0xFFFFA500);

  // Characteristic colors - used throughout the app for character stats
  static const Color mightColor = Color(0xFFD32F2F); // Red
  static const Color agilityColor = Color(0xFF388E3C); // Green
  static const Color reasonColor = Color(0xFF1976D2); // Blue
  static const Color intuitionColor = Color(0xFF7B1FA2); // Purple
  static const Color presenceColor = Color(0xFFF57C00); // Orange

  // Elemental damage type colors
  static const Color acidColor = Color(0xFFB2FF59); // Lime Green
  static const Color poisonColor = Color(0xFF4CAF50); // Green
  static const Color fireColor = Color(0xFFFF5722); // Deep Orange
  static const Color coldColor = Color.fromARGB(255, 84, 171, 243); // Blue
  static const Color sonicColor = Color(0xFF9E9E9E); // Grey
  static const Color holyColor = Color(0xFFFFC107); // Amber
  static const Color corruptionColor = Color(0xFF9C27B0); // Dark Grey
  static const Color psychicColor = Color.fromARGB(255, 235, 79, 206); // Purple
  static const Color lightningColor = Color(0xFFFFEB3B); // Yellow

  // Potency strength colors
  static const Color weakPotencyColor = Color(0xFF81C784); // Light Green
  static const Color averagePotencyColor = Color(0xFFFFB74D); // Light Orange
  static const Color strongPotencyColor = Color(0xFFE57373); // Light Red

  // UI element colors (general fallbacks)
  static const Color keywordColor = Color(0xFF607D8B); // Blue Grey
  static const Color actionTypeColor = Color(0xFF00796B); // Teal
  static const Color potencyColor = Color(0xFF5D4037); // Brown
  static const Color rangeTargetColor = Color(0xFF546E7A); // Blue Grey

  // Specific keyword colors for better visual distinction
  static const Color areaKeywordColor = Color(0xFFE91E63); // Pink - for area effects
  static const Color chargeKeywordColor = Color(0xFFFF9800); // Orange - for charging attacks
  static const Color magicKeywordColor = Color(0xFF9C27B0); // Purple - for magical abilities
  static const Color meleeKeywordColor = Color(0xFFD32F2F); // Red - for melee combat
  static const Color psionicKeywordColor = Color(0xFF673AB7); // Deep Purple - for psionic powers
  static const Color rangedKeywordColor = Color(0xFF4CAF50); // Green - for ranged attacks
  static const Color strikeKeywordColor = Color(0xFFFF5722); // Deep Orange - for strike attacks
  static const Color weaponKeywordColor = Color(0xFF795548); // Brown - for weapon attacks

  // Specific action type colors
  static const Color mainActionColor = Color(0xFFD32F2F); // Red - primary actions
  static const Color maneuverColor = Color(0xFF1976D2); // Blue - tactical maneuvers
  static const Color moveActionColor = Color(0xFF388E3C); // Green - movement actions
  static const Color triggeredActionColor = Color(0xFFE91E63); // Pink - reactive actions
  static const Color freeManeuverColor = Color(0xFF00ACC1); // Cyan - free tactical actions
  static const Color freeTriggeredActionColor = Color(0xFFAB47BC); // Light Purple - free reactive actions

  // Class heroic resource colors
  static const Color wrathColor = Color(0xFFB71C1C); // Dark Red - fury and anger
  static const Color pietyColor = Color(0xFFFFD700); // Gold - divine devotion
  static const Color essenceColor = Color(0xFF4A148C); // Deep Purple - magical essence
  static const Color ferocityColor = Color(0xFFFF6F00); // Dark Orange - wild ferocity
  static const Color disciplineColor = Color(0xFF1565C0); // Blue - tactical discipline
  static const Color insightColor = Color(0xFF00695C); // Teal - wisdom and knowledge
  static const Color focusColor = Color(0xFF6A1B9A); // Purple - mental concentration
  static const Color clarityColor = Color(0xFF37474F); // Blue Grey - clear thinking
  static const Color dramaColor = Color(0xFFE91E63); // Pink - theatrical drama

  /// Get color for a characteristic score (M, A, R, I, P)
  // TODO(deprecate): Prefer CharacteristicTokens.color from semantic_tokens.dart
  static Color getCharacteristicColor(String characteristic) {
    switch (characteristic.toLowerCase()) {
      case 'might':
      case 'm':
        return mightColor;
      case 'agility':
      case 'a':
        return agilityColor;
      case 'reason':
      case 'r':
        return reasonColor;
      case 'intuition':
      case 'i':
        return intuitionColor;
      case 'presence':
      case 'p':
        return presenceColor;
      default:
        return Colors.grey;
    }
  }

  /// Get color for elemental damage types
  // TODO(deprecate): Prefer DamageTokens.color from semantic_tokens.dart
  static Color getElementalColor(String element) {
    switch (element.toLowerCase()) {
      case 'acid':
        return acidColor;
      case 'poison':
        return poisonColor;
      case 'fire':
        return fireColor;
      case 'cold':
        return coldColor;
      case 'sonic':
        return sonicColor;
      case 'holy':
        return holyColor;
      case 'corruption':
        return corruptionColor;
      case 'psychic':
        return psychicColor;
      case 'lightning':
        return lightningColor;
      default:
        return Colors.grey;
    }
  }

  /// Get emoji for damage types to make them more visually distinctive
  // TODO(deprecate): Move to DamageTokens.emoji in semantic_tokens.dart
  static String getDamageTypeEmoji(String damageType) {
    switch (damageType.toLowerCase()) {
      case 'acid':
        return '🧪'; // test tube for acid
      case 'poison':
        return '☠️'; // skull and crossbones for poison
      case 'fire':
        return '🔥'; // fire emoji
      case 'cold':
        return '❄️'; // snowflake for cold
      case 'sonic':
        return '🔊'; // speaker for sonic
      case 'holy':
        return '✨'; // sparkles for holy/radiant
      case 'corruption':
        return '💀'; // skull for corruption/necrotic
      case 'psychic':
        return '🧠'; // brain for psychic
      case 'lightning':
        return '⚡'; // lightning bolt
      default:
        return ''; // no emoji for unknown types
    }
  }

  /// Get color for potency strength (w=weak, a=average, s=strong)
  // TODO(deprecate): Prefer PotencyTokens.color from semantic_tokens.dart
  static Color getPotencyColor(String strength) {
    switch (strength.toLowerCase()) {
      case 'w':
      case 'weak':
        return weakPotencyColor;
      case 'a':
      case 'average':
        return averagePotencyColor;
      case 's':
      case 'strong':
        return strongPotencyColor;
      default:
        return potencyColor;
    }
  }

  /// Get color for specific ability keywords
  // TODO(deprecate): Prefer KeywordTokens.color from semantic_tokens.dart
  static Color getKeywordColor(String keyword) {
    switch (keyword.toLowerCase()) {
      case 'area':
        return areaKeywordColor;
      case 'charge':
        return chargeKeywordColor;
      case 'magic':
        return magicKeywordColor;
      case 'melee':
        return meleeKeywordColor;
      case 'psionic':
        return psionicKeywordColor;
      case 'ranged':
        return rangedKeywordColor;
      case 'strike':
        return strikeKeywordColor;
      case 'weapon':
        return weaponKeywordColor;
      default:
        return keywordColor; // fallback to general keyword color
    }
  }

  /// Get color for specific action types
  // TODO(deprecate): Prefer ActionTokens.color from semantic_tokens.dart
  static Color getActionTypeColor(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'main action':
        return mainActionColor;
      case 'maneuver':
        return maneuverColor;
      case 'move action':
        return moveActionColor;
      case 'triggered action':
        return triggeredActionColor;
      case 'free maneuver':
        return freeManeuverColor;
      case 'free triggered action':
        return freeTriggeredActionColor;
      default:
        return actionTypeColor; // fallback to general action type color
    }
  }

  /// Get color for class heroic resources
  // TODO(deprecate): Prefer HeroicResourceTokens.color from semantic_tokens.dart
  static Color getHeroicResourceColor(String resource) {
    switch (resource.toLowerCase()) {
      case 'wrath':
        return wrathColor;
      case 'piety':
        return pietyColor;
      case 'essence':
        return essenceColor;
      case 'ferocity':
        return ferocityColor;
      case 'discipline':
        return disciplineColor;
      case 'insight':
        return insightColor;
      case 'focus':
        return focusColor;
      case 'clarity':
        return clarityColor;
      case 'drama':
        return dramaColor;
      default:
        return Colors.blueGrey; // fallback color for unknown resources
    }
  }
}