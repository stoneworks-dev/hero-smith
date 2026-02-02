/// Data models and constants used by HeroMainStatsView.
///
/// This file contains pure data classes and constant tier definitions
/// that are used for displaying hero statistics and calculating insights.
library;

import 'package:flutter/material.dart';

import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_models_text.dart';
// ============================================================================
// Numeric Field Enum
// ============================================================================

/// Identifies which numeric field is being edited or displayed.
enum NumericField {
  victories,
  exp,
  level,
  staminaCurrent,
  staminaTemp,
  recoveriesCurrent,
  heroicResourceCurrent,
  surgesCurrent,
  heroTokensCurrent,
}

/// Extension to get human-readable labels for numeric fields.
extension NumericFieldLabel on NumericField {
  String get label {
    switch (this) {
      case NumericField.victories:
        return HeroMainStatsModelsText.numericFieldVictoriesLabel;
      case NumericField.exp:
        return HeroMainStatsModelsText.numericFieldExperienceLabel;
      case NumericField.level:
        return HeroMainStatsModelsText.numericFieldLevelLabel;
      case NumericField.staminaCurrent:
        return HeroMainStatsModelsText.numericFieldStaminaLabel;
      case NumericField.staminaTemp:
        return HeroMainStatsModelsText.numericFieldTemporaryStaminaLabel;
      case NumericField.recoveriesCurrent:
        return HeroMainStatsModelsText.numericFieldRecoveriesLabel;
      case NumericField.heroicResourceCurrent:
        return HeroMainStatsModelsText.numericFieldHeroicResourceLabel;
      case NumericField.surgesCurrent:
        return HeroMainStatsModelsText.numericFieldSurgesLabel;
      case NumericField.heroTokensCurrent:
        return HeroMainStatsModelsText.numericFieldHeroTokensLabel;
    }
  }
}

// ============================================================================
// Stat Display Models
// ============================================================================

/// Data for displaying a stat tile with base, total, and modification key.
class StatTileData {
  const StatTileData(this.label, this.baseValue, this.totalValue, this.modKey);

  final String label;
  final int baseValue;
  final int totalValue;
  final String modKey;
}

/// Represents the current stamina state (Healthy, Winded, Dying, Dead).
class StaminaState {
  const StaminaState(this.label, this.color);

  final String label;
  final Color color;
}

// ============================================================================
// Heroic Resource Details
// ============================================================================

/// Details about a class's heroic resource, including in/out of combat info.
class HeroicResourceDetails {
  const HeroicResourceDetails({
    required this.name,
    this.description,
    this.inCombatName,
    this.inCombatDescription,
    this.outCombatName,
    this.outCombatDescription,
    this.strainName,
    this.strainDescription,
    this.canBeNegative = false,
    this.negativeFormula,
  });

  final String name;
  final String? description;
  final String? inCombatName;
  final String? inCombatDescription;
  final String? outCombatName;
  final String? outCombatDescription;
  final String? strainName;
  final String? strainDescription;

  /// Whether this resource can go below zero (e.g., Talent's Clarity can be strained).
  final bool canBeNegative;

  /// Formula for calculating the minimum (most negative) value, e.g., "-(1 + Reason)".
  final String? negativeFormula;

  /// Calculate the minimum allowed value based on the formula and hero's stats.
  /// Returns 0 if canBeNegative is false or formula is null.
  int calculateMinValue({int reasonScore = 0}) {
    if (!canBeNegative || negativeFormula == null) return 0;

    // Parse formula like "-(1 + Reason)"
    final formula = negativeFormula!.toLowerCase().trim();

    // Handle "-(X + Reason)" pattern
    final match =
        RegExp(r'-\s*\(\s*(\d+)\s*\+\s*reason\s*\)').firstMatch(formula);
    if (match != null) {
      final baseValue = int.tryParse(match.group(1) ?? '0') ?? 0;
      return -(baseValue + reasonScore);
    }

    // Handle simple "-Reason" pattern
    if (formula == '-reason') {
      return -reasonScore;
    }

    // Handle numeric value
    final numericValue = int.tryParse(formula);
    if (numericValue != null) {
      return numericValue;
    }

    return 0;
  }
}

/// Request key for fetching heroic resource details.
class HeroicResourceRequest {
  const HeroicResourceRequest({
    required this.classId,
    required this.fallbackName,
  });

  final String? classId;
  final String? fallbackName;

  @override
  bool operator ==(Object other) {
    return other is HeroicResourceRequest &&
        other.classId == classId &&
        other.fallbackName == fallbackName;
  }

  @override
  int get hashCode => Object.hash(classId, fallbackName);
}

// ============================================================================
// Wealth Tiers
// ============================================================================

/// Represents a wealth tier with score threshold and description.
class WealthTier {
  const WealthTier(this.score, this.description);

  final int score;
  final String description;
}

/// Wealth tier definitions for the game system.
const List<WealthTier> wealthTiers = [
  WealthTier(1, HeroMainStatsModelsText.wealthTier1Description),
  WealthTier(2, HeroMainStatsModelsText.wealthTier2Description),
  WealthTier(3, HeroMainStatsModelsText.wealthTier3Description),
  WealthTier(4, HeroMainStatsModelsText.wealthTier4Description),
  WealthTier(5, HeroMainStatsModelsText.wealthTier5Description),
  WealthTier(6, HeroMainStatsModelsText.wealthTier6Description),
];

// ============================================================================
// Renown Tiers
// ============================================================================

/// Represents a renown tier for follower count.
class RenownFollowerTier {
  const RenownFollowerTier(this.threshold, this.followers);

  final int threshold;
  final int followers;
}

/// Renown follower tier definitions.
const List<RenownFollowerTier> renownFollowers = [
  RenownFollowerTier(3, 1),
  RenownFollowerTier(6, 2),
  RenownFollowerTier(9, 3),
  RenownFollowerTier(12, 4),
];

/// Represents a renown impression tier.
class RenownImpressionTier {
  const RenownImpressionTier(this.value, this.description);

  final int value;
  final String description;
}

/// Renown impression tier definitions.
const List<RenownImpressionTier> impressionTiers = [
  RenownImpressionTier(1, HeroMainStatsModelsText.impressionTier1Description),
  RenownImpressionTier(2, HeroMainStatsModelsText.impressionTier2Description),
  RenownImpressionTier(3, HeroMainStatsModelsText.impressionTier3Description),
  RenownImpressionTier(4, HeroMainStatsModelsText.impressionTier4Description),
  RenownImpressionTier(5, HeroMainStatsModelsText.impressionTier5Description),
  RenownImpressionTier(6, HeroMainStatsModelsText.impressionTier6Description),
  RenownImpressionTier(7, HeroMainStatsModelsText.impressionTier7Description),
  RenownImpressionTier(8, HeroMainStatsModelsText.impressionTier8Description),
  RenownImpressionTier(9, HeroMainStatsModelsText.impressionTier9Description),
  RenownImpressionTier(10, HeroMainStatsModelsText.impressionTier10Description),
  RenownImpressionTier(11, HeroMainStatsModelsText.impressionTier11Description),
  RenownImpressionTier(12, HeroMainStatsModelsText.impressionTier12Description),
];

// ============================================================================
// XP Advancement Tiers
// ============================================================================

/// Represents the XP advancement speed for a hero.
enum XpSpeed {
  doubleSpeed,
  normal,
  halfSpeed;

  String get label {
    switch (this) {
      case XpSpeed.doubleSpeed:
        return 'Double Speed';
      case XpSpeed.normal:
        return 'Normal';
      case XpSpeed.halfSpeed:
        return 'Half Speed';
    }
  }

  String get shortLabel {
    switch (this) {
      case XpSpeed.doubleSpeed:
        return '2×';
      case XpSpeed.normal:
        return '1×';
      case XpSpeed.halfSpeed:
        return '½×';
    }
  }

  static XpSpeed fromString(String? value) {
    switch (value) {
      case 'doubleSpeed':
        return XpSpeed.doubleSpeed;
      case 'halfSpeed':
        return XpSpeed.halfSpeed;
      case 'normal':
      default:
        return XpSpeed.normal;
    }
  }
}

/// Represents an XP advancement tier for leveling.
class XpAdvancement {
  const XpAdvancement(this.level, this.minXp, this.maxXp);

  final int level;
  final int minXp;

  /// Use -1 for no max (level 10).
  final int maxXp;
}

/// XP advancement tier definitions for Normal speed (levels 1-10).
const List<XpAdvancement> xpAdvancementTiersNormal = [
  XpAdvancement(1, 0, 15),
  XpAdvancement(2, 16, 31),
  XpAdvancement(3, 32, 47),
  XpAdvancement(4, 48, 63),
  XpAdvancement(5, 64, 79),
  XpAdvancement(6, 80, 95),
  XpAdvancement(7, 96, 111),
  XpAdvancement(8, 112, 127),
  XpAdvancement(9, 128, 143),
  XpAdvancement(10, 144, -1), // -1 means no max
];

/// XP advancement tier definitions for Double Speed (faster leveling).
const List<XpAdvancement> xpAdvancementTiersDoubleSpeed = [
  XpAdvancement(1, 0, 7),
  XpAdvancement(2, 8, 15),
  XpAdvancement(3, 16, 23),
  XpAdvancement(4, 24, 31),
  XpAdvancement(5, 32, 39),
  XpAdvancement(6, 40, 47),
  XpAdvancement(7, 48, 55),
  XpAdvancement(8, 56, 63),
  XpAdvancement(9, 64, 71),
  XpAdvancement(10, 72, -1), // -1 means no max
];

/// XP advancement tier definitions for Half Speed (slower leveling).
const List<XpAdvancement> xpAdvancementTiersHalfSpeed = [
  XpAdvancement(1, 0, 31),
  XpAdvancement(2, 32, 63),
  XpAdvancement(3, 64, 95),
  XpAdvancement(4, 96, 127),
  XpAdvancement(5, 128, 159),
  XpAdvancement(6, 160, 191),
  XpAdvancement(7, 192, 223),
  XpAdvancement(8, 224, 255),
  XpAdvancement(9, 256, 287),
  XpAdvancement(10, 288, -1), // -1 means no max
];

/// Returns the XP advancement tiers for the given speed.
List<XpAdvancement> getXpAdvancementTiers(XpSpeed speed) {
  switch (speed) {
    case XpSpeed.doubleSpeed:
      return xpAdvancementTiersDoubleSpeed;
    case XpSpeed.halfSpeed:
      return xpAdvancementTiersHalfSpeed;
    case XpSpeed.normal:
      return xpAdvancementTiersNormal;
  }
}

/// Legacy: Default XP advancement tiers (Normal speed) for backward compatibility.
const List<XpAdvancement> xpAdvancementTiers = xpAdvancementTiersNormal;
