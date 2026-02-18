import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../ability_colors.dart';

/// Semantic tokens provide cross-domain mappings (inputs like "fire", "maneuver")
/// to visual tokens (colors/emojis) while centralizing actual color values.
/// Use these in widgets instead of calling color classes directly.

// ─── Damage ────────────────────────────────────────────────────────────────

class DamageTokens {
  DamageTokens._();

  static Color color(String element) {
    return AbilityColors.getDamageTypeColor(element);
  }

  static String emoji(String element) {
    switch (element.toLowerCase()) {
      case 'acid':
        return '🧪';
      case 'poison':
        return '☠️';
      case 'fire':
        return '🔥';
      case 'cold':
        return '❄️';
      case 'sonic':
        return '🔊';
      case 'holy':
        return '✨';
      case 'corruption':
        return '💀';
      case 'psychic':
        return '🧠';
      case 'lightning':
        return '⚡';
      default:
        return '';
    }
  }
}

// ─── Characteristics ───────────────────────────────────────────────────────

class CharacteristicTokens {
  CharacteristicTokens._();

  static Color color(String characteristic) {
    switch (characteristic.toLowerCase()) {
      case 'might':
      case 'm':
        return AppColors.mightColor;
      case 'agility':
      case 'a':
        return AppColors.agilityColor;
      case 'reason':
      case 'r':
        return AppColors.reasonColor;
      case 'intuition':
      case 'i':
        return AppColors.intuitionColor;
      case 'presence':
      case 'p':
        return AppColors.presenceColor;
      default:
        return Colors.grey;
    }
  }
}

// ─── Potency ───────────────────────────────────────────────────────────────

class PotencyTokens {
  PotencyTokens._();

  static Color color(String strength) {
    switch (strength.toLowerCase()) {
      case 'w':
      case 'weak':
        return AppColors.weakPotencyColor;
      case 'a':
      case 'average':
        return AppColors.averagePotencyColor;
      case 's':
      case 'strong':
        return AppColors.strongPotencyColor;
      default:
        return AppColors.potencyFallback;
    }
  }
}

// ─── Keywords ──────────────────────────────────────────────────────────────

class KeywordTokens {
  KeywordTokens._();

  static Color color(String keyword) {
    return AbilityColors.getKeywordColor(keyword);
  }
}

// ─── Actions ───────────────────────────────────────────────────────────────

class ActionTokens {
  ActionTokens._();

  static Color color(String actionType) {
    return AbilityColors.getActionTypeColor(actionType);
  }

  static Color lightColor(String actionType) {
    return AbilityColors.getActionTypeLightColor(actionType);
  }
}

// ─── Heroic Resources ──────────────────────────────────────────────────────

class HeroicResourceTokens {
  HeroicResourceTokens._();

  static Color color(String resource) {
    return AbilityColors.getHeroicResourceColor(resource);
  }

  static Color lightColor(String resource) {
    return AbilityColors.getHeroicResourceLightColor(resource);
  }
}
