import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../ability_colors.dart';

/// Semantic tokens provide cross-domain mappings (inputs like "fire", "maneuver")
/// to visual tokens (colors/emojis) while centralizing actual color values.
/// Use these in widgets instead of calling color classes directly.
class DamageTokens {
  DamageTokens._();

  static Color color(String element) {
    // Use enhanced ability colors for better distinction
    return AbilityColors.getDamageTypeColor(element);
  }

  static String emoji(String element) {
    // Enhanced emoji mapping with more visual distinction
    return _getDamageTypeEmoji(element);
  }
  
  static String _getDamageTypeEmoji(String damageType) {
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
}

class CharacteristicTokens {
  CharacteristicTokens._();

  static Color color(String characteristic) {
    return AppColors.getCharacteristicColor(characteristic);
  }
}

class PotencyTokens {
  PotencyTokens._();

  static Color color(String strength) {
    return AppColors.getPotencyColor(strength);
  }
}

class KeywordTokens {
  KeywordTokens._();

  static Color color(String keyword) {
    // Use enhanced ability colors for better semantic grouping
    return AbilityColors.getKeywordColor(keyword);
  }
}

class ActionTokens {
  ActionTokens._();

  static Color color(String actionType) {
    // Use enhanced ability colors for better action type distinction
    return AbilityColors.getActionTypeColor(actionType);
  }
  
  static Color lightColor(String actionType) {
    // Get light variant for backgrounds
    return AbilityColors.getActionTypeLightColor(actionType);
  }
}

class HeroicResourceTokens {
  HeroicResourceTokens._();

  static Color color(String resource) {
    // Use enhanced ability colors for better resource distinction
    return AbilityColors.getHeroicResourceColor(resource);
  }
}
