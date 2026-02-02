import 'package:flutter/material.dart';

/// Dedicated color palette for abilities with enhanced visual distinction
/// This replaces the old approach with a more systematic color scheme
class AbilityColors {
  AbilityColors._();

  // === ACTION TYPE COLORS ===
  // Each action type gets a distinct color family with good contrast
  
  /// Main Action - Bold Crimson (Most important actions)
  static const Color mainAction = Color(0xFFB71C1C);
  static const Color mainActionLight = Color(0xFFFFCDD2);
  static const Color mainActionDark = Color(0xFF8E0000);
  
  /// Maneuver - Strategic Royal Blue (Tactical positioning)
  static const Color maneuver = Color(0xFF1565C0);
  static const Color maneuverLight = Color(0xFFBBDEFB);
  static const Color maneuverDark = Color(0xFF0D47A1);
  
  /// Move Action - Vibrant Emerald (Movement and positioning)
  static const Color moveAction = Color(0xFF2E7D32);
  static const Color moveActionLight = Color(0xFFC8E6C9);
  static const Color moveActionDark = Color(0xFF1B5E20);
  
  /// Triggered Action - Deep Amethyst (Responsive actions)
  static const Color triggeredAction = Color(0xFF6A1B9A);
  static const Color triggeredActionLight = Color(0xFFE1BEE7);
  static const Color triggeredActionDark = Color(0xFF4A148C);
  
  /// Free Maneuver - Electric Teal (Quick tactical moves)
  static const Color freeManeuver = Color(0xFF00838F);
  static const Color freeManeuverLight = Color(0xFFB2EBF2);
  static const Color freeManeuverDark = Color(0xFF006064);
  
  /// Free Triggered Action - Blazing Orange (Quick reactions)
  static const Color freeTriggeredAction = Color(0xFFE65100);
  static const Color freeTriggeredActionLight = Color(0xFFFFE0B2);
  static const Color freeTriggeredActionDark = Color(0xFFBF360C);
  
  /// Free Action - Fresh Turquoise (Minimal cost actions)
  static const Color freeAction = Color(0xFF00695C);
  static const Color freeActionLight = Color(0xFFB2DFDB);
  static const Color freeActionDark = Color(0xFF004D40);
  
  /// Villain Action - Sinister Violet (NPC/Monster actions)
  static const Color villainAction = Color(0xFF7B1FA2);
  static const Color villainActionLight = Color(0xFFE1BEE7);
  static const Color villainActionDark = Color(0xFF4A148C);

  // === KEYWORD COLORS ===
  // Semantic grouping with distinct color families
  
  /// Combat Keywords - Red spectrum
  static const Color meleeKeyword = Color(0xFFE53935);
  static const Color rangedKeyword = Color(0xFF43A047);
  static const Color strikeKeyword = Color(0xFFFF5722);
  static const Color weaponKeyword = Color(0xFF8D6E63);
  
  /// Magic Keywords - Purple/Pink spectrum
  static const Color magicKeyword = Color(0xFF8E24AA);
  static const Color psionicKeyword = Color(0xFF5E35B1);
  static const Color arcaneKeyword = Color(0xFF7B1FA2);
  static const Color divineKeyword = Color(0xFFFFB300);
  
  /// Area/Effect Keywords - Blue spectrum
  static const Color areaKeyword = Color(0xFF1E88E5);
  static const Color blastKeyword = Color(0xFF039BE5);
  static const Color burstKeyword = Color(0xFF00ACC1);
  static const Color emanationKeyword = Color(0xFF0097A7);
  
  /// Movement Keywords - Green spectrum
  static const Color chargeKeyword = Color(0xFFFF8F00);
  static const Color rushKeyword = Color(0xFFFFA000);
  static const Color retreatKeyword = Color(0xFF689F38);
  static const Color shiftKeyword = Color(0xFF7CB342);
  
  /// Status Keywords - Orange/Yellow spectrum
  static const Color debuffKeyword = Color(0xFFFF7043);
  static const Color buffKeyword = Color(0xFF66BB6A);
  static const Color healingKeyword = Color(0xFF26C6DA);
  static const Color persistentKeyword = Color(0xFFAB47BC);

  // === HEROIC RESOURCE COLORS ===
  // Class-specific resources with modern, vibrant identities
  // Each resource has a main color and a light variant for backgrounds
  
  /// Wrath - Fury's burning rage (Modern Crimson)
  static const Color wrath = Color(0xFFDC2626);
  static const Color wrathLight = Color(0xFFFEE2E2);
  
  /// Piety - Censor's divine conviction (Rich Gold)
  static const Color piety = Color(0xFFF59E0B);
  static const Color pietyLight = Color(0xFFFEF3C7);
  
  /// Essence - Elementalist's primal power (Vivid Purple)
  static const Color essence = Color(0xFF8B5CF6);
  static const Color essenceLight = Color(0xFFEDE9FE);
  
  /// Ferocity - Barbarian's wild fury (Vibrant Orange)
  static const Color ferocity = Color(0xFFF97316);
  static const Color ferocityLight = Color(0xFFFFEDD5);
  
  /// Discipline - Tactician's strategic control (Modern Blue)
  static const Color discipline = Color(0xFF3B82F6);
  static const Color disciplineLight = Color(0xFFDBEAFE);
  
  /// Insight - Null's mental clarity (Ocean Teal)
  static const Color insight = Color(0xFF14B8A6);
  static const Color insightLight = Color(0xFFCCFBF1);
  
  /// Focus - Conduit's channeled energy (Electric Violet)
  static const Color focus = Color(0xFFA855F7);
  static const Color focusLight = Color(0xFFF3E8FF);
  
  /// Clarity - Talent's psionic focus (Slate Blue)
  static const Color clarity = Color(0xFF64748B);
  static const Color clarityLight = Color(0xFFF1F5F9);
  
  /// Drama - Troubadour's theatrical flair (Hot Pink)
  static const Color drama = Color(0xFFEC4899);
  static const Color dramaLight = Color(0xFFFCE7F3);
  
  /// Shadow - Shadow's darkness (Deep Indigo)
  static const Color shadow = Color(0xFF4F46E5);
  static const Color shadowLight = Color(0xFFE0E7FF);

  // === DAMAGE TYPE COLORS ===
  // Enhanced elemental colors with better contrast
  
  static const Color fire = Color(0xFFFF3D00);         // Bright Red-Orange
  static const Color cold = Color(0xFF0288D1);         // Clear Blue
  static const Color lightning = Color(0xFFFFD600);    // Electric Yellow
  static const Color acid = Color(0xFF8BC34A);         // Acidic Green
  static const Color poison = Color(0xFF4CAF50);       // Toxic Green
  static const Color sonic = Color(0xFF9E9E9E);        // Sound Grey
  static const Color holy = Color(0xFFFFB300);         // Divine Gold
  static const Color corruption = Color(0xFF6A1B9A);   // Dark Purple
  static const Color psychic = Color(0xFFE91E63);      // Mind Pink

  // === COMBAT RESOURCE COLORS ===
  // Vital combat resources with energetic, thematic colors
  
  /// Surges - Explosive battle power (Electric Amber)
  static const Color surge = Color(0xFFF59E0B);
  static const Color surgeLight = Color(0xFFFEF3C7);
  static const Color surgeDark = Color(0xFFD97706);
  
  /// Recoveries - Life-saving healing (Vibrant Emerald)
  static const Color recovery = Color(0xFF10B981);
  static const Color recoveryLight = Color(0xFFD1FAE5);
  static const Color recoveryDark = Color(0xFF059669);

  // === UTILITY METHODS ===
  
  /// Get action type color with proper fallback
  static Color getActionTypeColor(String actionType) {
    final normalized = actionType.toLowerCase().trim();
    
    switch (normalized) {
      case 'main action':
        return mainAction;
      case 'maneuver':
        return maneuver;
      case 'move action':
      case 'move':
        return moveAction;
      case 'triggered action':
        return triggeredAction;
      case 'free maneuver':
        return freeManeuver;
      case 'free triggered action':
        return freeTriggeredAction;
      case 'free action':
      case 'free':
        return freeAction;
      case 'villain action':
        return villainAction;
      default:
        return const Color(0xFF546E7A); // Neutral blue-grey
    }
  }
  
  /// Get action type light variant for backgrounds
  static Color getActionTypeLightColor(String actionType) {
    final normalized = actionType.toLowerCase().trim();
    
    switch (normalized) {
      case 'main action':
        return mainActionLight;
      case 'maneuver':
        return maneuverLight;
      case 'move action':
      case 'move':
        return moveActionLight;
      case 'triggered action':
        return triggeredActionLight;
      case 'free maneuver':
        return freeManeuverLight;
      case 'free triggered action':
        return freeTriggeredActionLight;
      case 'free action':
      case 'free':
        return freeActionLight;
      case 'villain action':
        return villainActionLight;
      default:
        return const Color(0xFFECEFF1); // Neutral light
    }
  }
  
  /// Get keyword color with semantic grouping
  static Color getKeywordColor(String keyword) {
    final normalized = keyword.toLowerCase().trim();
    
    // Combat keywords
    if (_combatKeywords.contains(normalized)) {
      switch (normalized) {
        case 'melee': return meleeKeyword;
        case 'ranged': return rangedKeyword;
        case 'strike': return strikeKeyword;
        case 'weapon': return weaponKeyword;
        default: return meleeKeyword;
      }
    }
    
    // Magic keywords
    if (_magicKeywords.contains(normalized)) {
      switch (normalized) {
        case 'magic': return magicKeyword;
        case 'psionic': return psionicKeyword;
        case 'arcane': return arcaneKeyword;
        case 'divine': return divineKeyword;
        default: return magicKeyword;
      }
    }
    
    // Area keywords
    if (_areaKeywords.contains(normalized)) {
      switch (normalized) {
        case 'area': return areaKeyword;
        case 'blast': return blastKeyword;
        case 'burst': return burstKeyword;
        case 'emanation': return emanationKeyword;
        default: return areaKeyword;
      }
    }
    
    // Movement keywords
    if (_movementKeywords.contains(normalized)) {
      switch (normalized) {
        case 'charge': return chargeKeyword;
        case 'rush': return rushKeyword;
        case 'retreat': return retreatKeyword;
        case 'shift': return shiftKeyword;
        default: return chargeKeyword;
      }
    }
    
    // Status keywords
    if (_statusKeywords.contains(normalized)) {
      switch (normalized) {
        case 'debuff': return debuffKeyword;
        case 'buff': return buffKeyword;
        case 'healing': return healingKeyword;
        case 'persistent': return persistentKeyword;
        default: return buffKeyword;
      }
    }
    
    // Default keyword color
    return const Color(0xFF607D8B);
  }
  
  /// Get heroic resource color
  static Color getHeroicResourceColor(String resource) {
    final normalized = resource.toLowerCase().trim();
    
    switch (normalized) {
      case 'wrath': return wrath;
      case 'piety': return piety;
      case 'essence': return essence;
      case 'ferocity': return ferocity;
      case 'discipline': return discipline;
      case 'insight': return insight;
      case 'focus': return focus;
      case 'clarity': return clarity;
      case 'drama': return drama;
      case 'shadow': return shadow;
      case 'heroic_resource':
      case 'heroic resource':
        return const Color(0xFF7C3AED); // Default heroic purple
      default:
        return const Color(0xFF64748B); // Modern neutral slate
    }
  }
  
  /// Get heroic resource light color for backgrounds
  static Color getHeroicResourceLightColor(String resource) {
    final normalized = resource.toLowerCase().trim();
    
    switch (normalized) {
      case 'wrath': return wrathLight;
      case 'piety': return pietyLight;
      case 'essence': return essenceLight;
      case 'ferocity': return ferocityLight;
      case 'discipline': return disciplineLight;
      case 'insight': return insightLight;
      case 'focus': return focusLight;
      case 'clarity': return clarityLight;
      case 'drama': return dramaLight;
      case 'shadow': return shadowLight;
      case 'heroic_resource':
      case 'heroic resource':
        return const Color(0xFFEDE9FE); // Default heroic purple light
      default:
        return const Color(0xFFF1F5F9); // Modern neutral slate light
    }
  }
  
  /// Get damage type color
  static Color getDamageTypeColor(String damageType) {
    final normalized = damageType.toLowerCase().trim();
    
    switch (normalized) {
      case 'fire': return fire;
      case 'cold': return cold;
      case 'lightning': return lightning;
      case 'acid': return acid;
      case 'poison': return poison;
      case 'sonic': return sonic;
      case 'holy': return holy;
      case 'corruption': return corruption;
      case 'psychic': return psychic;
      default: return const Color(0xFF9E9E9E);
    }
  }

  // === KEYWORD GROUPINGS ===
  
  static const Set<String> _combatKeywords = {
    'melee', 'ranged', 'strike', 'weapon', 'attack', 'combat'
  };
  
  static const Set<String> _magicKeywords = {
    'magic', 'psionic', 'arcane', 'divine', 'spell', 'enchantment'
  };
  
  static const Set<String> _areaKeywords = {
    'area', 'blast', 'burst', 'emanation', 'cone', 'line', 'sphere'
  };
  
  static const Set<String> _movementKeywords = {
    'charge', 'rush', 'retreat', 'shift', 'teleport', 'dash'
  };
  
  static const Set<String> _statusKeywords = {
    'debuff', 'buff', 'healing', 'persistent', 'ongoing', 'condition'
  };
}