import 'package:collection/collection.dart';

import '../db/app_database.dart';
import '../models/dynamic_modifier_model.dart';

/// Service for managing dynamic (formula-based) modifiers for heroes.
///
/// Dynamic modifiers store formulas instead of static values, allowing
/// bonuses to automatically update when the hero's stats change.
///
/// Example: Wodewalker grants "recovery value + highest characteristic".
/// Instead of storing "+3", we store the formula "highest_characteristic".
/// When the hero's stats change, the bonus automatically recalculates.
class DynamicModifiersService {
  DynamicModifiersService(this._db);
  final AppDatabase _db;

  static const _kDynamicModifiers = 'dynamic_modifiers';

  /// Load all dynamic modifiers for a hero
  Future<DynamicModifierList> loadModifiers(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhereOrNull((v) => v.key == _kDynamicModifiers);
    final json = value?.jsonValue ?? value?.textValue;
    return DynamicModifierList.fromJsonString(json);
  }

  /// Save all dynamic modifiers for a hero
  Future<void> saveModifiers(String heroId, DynamicModifierList modifiers) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kDynamicModifiers,
      textValue: modifiers.toJsonString(),
    );
  }

  /// Add modifiers from a source (e.g., a complication)
  Future<void> addModifiers(
    String heroId,
    String source,
    List<DynamicModifier> newModifiers,
  ) async {
    final current = await loadModifiers(heroId);
    // Remove any existing modifiers from this source first
    final cleaned = current.removeSource(source);
    final updated = cleaned.add(newModifiers);
    await saveModifiers(heroId, updated);
  }

  /// Remove all modifiers from a source
  Future<void> removeModifiersFromSource(String heroId, String source) async {
    final current = await loadModifiers(heroId);
    final updated = current.removeSource(source);
    await saveModifiers(heroId, updated);
  }

  /// Calculate the total bonus for a stat given current hero stats
  Future<int> calculateStatBonus(
    String heroId,
    String stat,
    HeroStatsContext context,
  ) async {
    final modifiers = await loadModifiers(heroId);
    return modifiers.calculateTotal(stat, context);
  }

  /// Calculate the total bonus for a typed stat (e.g., immunity.fire)
  Future<int> calculateTypedStatBonus(
    String heroId,
    String stat,
    String type,
    HeroStatsContext context,
  ) async {
    final modifiers = await loadModifiers(heroId);
    return modifiers.calculateTypedTotal(stat, type, context);
  }

  /// Get all modifiers affecting a specific stat
  Future<List<DynamicModifier>> getModifiersForStat(
    String heroId,
    String stat,
  ) async {
    final modifiers = await loadModifiers(heroId);
    return modifiers.forStat(stat);
  }

  /// Clear all dynamic modifiers for a hero
  Future<void> clearAll(String heroId) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: _kDynamicModifiers,
      textValue: null,
    );
  }
}

/// Common stat keys for dynamic modifiers
class DynamicModifierStats {
  static const recoveryValue = 'recovery_value';
  static const stamina = 'stamina';
  static const stability = 'stability';
  static const speed = 'speed';
  static const immunity = 'immunity'; // Use with damageType
  static const weakness = 'weakness'; // Use with damageType
  static const renown = 'renown';
  static const wealth = 'wealth';
  static const recoveries = 'recoveries';
}
