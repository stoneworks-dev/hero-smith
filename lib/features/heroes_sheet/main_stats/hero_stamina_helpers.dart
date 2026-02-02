/// Helper functions for stamina state calculations.
/// 
/// Contains pure functions for calculating stamina-related states
/// used in the hero stats view.
library;

import 'package:flutter/material.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_models_text.dart';
import 'hero_main_stats_models.dart';

/// Calculates the current stamina state based on stats.
/// 
/// Returns one of: Healthy (green), Winded (orange), Dying (redAccent), Dead (red)
StaminaState calculateStaminaState(HeroMainStats stats) {
  final max = stats.staminaMaxEffective;
  final half = (max / 2).floor();
  final current = stats.staminaCurrent;
  if (current > half) {
    return const StaminaState(
      HeroMainStatsModelsText.staminaStateHealthy,
      Colors.green,
    );
  }
  if (current > 0) {
    return const StaminaState(
      HeroMainStatsModelsText.staminaStateWinded,
      Colors.orange,
    );
  }
  if (current > -half) {
    return const StaminaState(
      HeroMainStatsModelsText.staminaStateDying,
      Colors.redAccent,
    );
  }
  return const StaminaState(
    HeroMainStatsModelsText.staminaStateDead,
    Colors.red,
  );
}

/// Gets the value from stats corresponding to a numeric field.
int getNumberValueFromStats(HeroMainStats stats, NumericField field) {
  switch (field) {
    case NumericField.victories:
      return stats.victories;
    case NumericField.exp:
      return stats.exp;
    case NumericField.level:
      return stats.level;
    case NumericField.staminaCurrent:
      return stats.staminaCurrent;
    case NumericField.staminaTemp:
      return stats.staminaTemp;
    case NumericField.recoveriesCurrent:
      return stats.recoveriesCurrent;
    case NumericField.heroicResourceCurrent:
      return stats.heroicResourceCurrent;
    case NumericField.surgesCurrent:
      return stats.surgesCurrent;
    case NumericField.heroTokensCurrent:
      return stats.heroTokensCurrent;
  }
}

/// Calculates the recovery heal amount for a hero.
int calculateRecoveryHealAmount(HeroMainStats stats) {
  return stats.recoveryValueEffective;
}

/// Formats an integer with a sign prefix (+ for positive, - for negative).
String formatSigned(int value) {
  if (value > 0) return '+$value';
  return value.toString();
}
