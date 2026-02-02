import 'dart:math' as math;

import '../models/component.dart';

/// Represents all bonuses extracted from equipment (kits, augmentations, prayers, etc.)
class EquipmentBonuses {
  const EquipmentBonuses({
    this.staminaBonus = 0,
    this.speedBonus = 0,
    this.stabilityBonus = 0,
    this.disengageBonus = 0,
    this.meleeDamageBonus = 0,
    this.rangedDamageBonus = 0,
    this.meleeDistanceBonus = 0,
    this.rangedDistanceBonus = 0,
    this.equipmentIds = const [],
  });

  /// Total stamina bonus from equipped equipment (highest value only, scaled by level)
  final int staminaBonus;

  /// Speed bonus (highest across all equipment)
  final int speedBonus;

  /// Stability bonus (highest across all equipment)
  final int stabilityBonus;

  /// Disengage bonus (highest across all equipment)
  final int disengageBonus;

  /// Melee damage bonus for the current tier
  final int meleeDamageBonus;

  /// Ranged damage bonus for the current tier
  final int rangedDamageBonus;

  /// Melee distance bonus for the current echelon
  final int meleeDistanceBonus;

  /// Ranged distance bonus for the current echelon
  final int rangedDistanceBonus;

  /// IDs of equipment contributing to these bonuses
  final List<String> equipmentIds;

  static const EquipmentBonuses empty = EquipmentBonuses();

  @override
  String toString() =>
      'EquipmentBonuses(stamina: $staminaBonus, speed: $speedBonus, '
      'stability: $stabilityBonus, disengage: $disengageBonus, '
      'meleeDmg: $meleeDamageBonus, rangedDmg: $rangedDamageBonus, '
      'meleeDist: $meleeDistanceBonus, rangedDist: $rangedDistanceBonus)';
}

/// Bonuses extracted from a single piece of equipment
class _SingleEquipmentBonuses {
  _SingleEquipmentBonuses({
    required this.id,
    this.baseStamina = 0,
    this.staminaScalesWithLevel = false,
    this.speed = 0,
    this.stability = 0,
    this.disengage = 0,
    this.meleeDamageTier1 = 0,
    this.meleeDamageTier2 = 0,
    this.meleeDamageTier3 = 0,
    this.rangedDamageTier1 = 0,
    this.rangedDamageTier2 = 0,
    this.rangedDamageTier3 = 0,
    this.meleeDistanceEchelon1 = 0,
    this.meleeDistanceEchelon2 = 0,
    this.meleeDistanceEchelon3 = 0,
    this.rangedDistanceEchelon1 = 0,
    this.rangedDistanceEchelon2 = 0,
    this.rangedDistanceEchelon3 = 0,
  });

  final String id;
  final int baseStamina;
  final bool staminaScalesWithLevel;
  final int speed;
  final int stability;
  final int disengage;
  final int meleeDamageTier1;
  final int meleeDamageTier2;
  final int meleeDamageTier3;
  final int rangedDamageTier1;
  final int rangedDamageTier2;
  final int rangedDamageTier3;
  final int meleeDistanceEchelon1;
  final int meleeDistanceEchelon2;
  final int meleeDistanceEchelon3;
  final int rangedDistanceEchelon1;
  final int rangedDistanceEchelon2;
  final int rangedDistanceEchelon3;

  /// Calculate stamina for a given level
  /// Some equipment scales: +3 at 1, +6 at 4, +9 at 7, +12 at 10
  int staminaForLevel(int level) {
    if (!staminaScalesWithLevel || baseStamina == 0) {
      return baseStamina;
    }
    // Scaling factor: 1x at 1-3, 2x at 4-6, 3x at 7-9, 4x at 10+
    final multiplier = ((level - 1) ~/ 3) + 1;
    return baseStamina * multiplier;
  }

  /// Get melee damage for tier (1, 2, or 3)
  int meleeDamageForTier(int tier) {
    switch (tier) {
      case 1:
        return meleeDamageTier1;
      case 2:
        return meleeDamageTier2;
      case 3:
        return meleeDamageTier3;
      default:
        return meleeDamageTier1;
    }
  }

  /// Get ranged damage for tier (1, 2, or 3)
  int rangedDamageForTier(int tier) {
    switch (tier) {
      case 1:
        return rangedDamageTier1;
      case 2:
        return rangedDamageTier2;
      case 3:
        return rangedDamageTier3;
      default:
        return rangedDamageTier1;
    }
  }

  /// Get melee distance for echelon (1, 2, or 3)
  int meleeDistanceForEchelon(int echelon) {
    switch (echelon) {
      case 1:
        return meleeDistanceEchelon1;
      case 2:
        return meleeDistanceEchelon2;
      case 3:
        return meleeDistanceEchelon3;
      default:
        return meleeDistanceEchelon1;
    }
  }

  /// Get ranged distance for echelon (1, 2, or 3)
  int rangedDistanceForEchelon(int echelon) {
    switch (echelon) {
      case 1:
        return rangedDistanceEchelon1;
      case 2:
        return rangedDistanceEchelon2;
      case 3:
        return rangedDistanceEchelon3;
      default:
        return rangedDistanceEchelon1;
    }
  }
}

/// Service for extracting and combining equipment bonuses.
class KitBonusService {
  const KitBonusService();

  /// Calculate tier based on level (1-3 = tier 1, 4-6 = tier 2, 7-10 = tier 3)
  static int tierForLevel(int level) {
    if (level <= 3) return 1;
    if (level <= 6) return 2;
    return 3;
  }

  /// Calculate echelon based on level (1-3 = echelon 1, 4-6 = echelon 2, 7-10 = echelon 3)
  static int echelonForLevel(int level) {
    if (level <= 3) return 1;
    if (level <= 6) return 2;
    return 3;
  }

  /// Extract and combine bonuses from multiple equipment components.
  /// For all stat bonuses (stamina, speed, stability, disengage), we take the HIGHEST value only.
  /// Equipment bonuses do not stack - only the best bonus from equipped items applies.
  /// For damage/distance bonuses, we take the HIGHEST value per tier/echelon.
  EquipmentBonuses calculateBonuses({
    required List<Component> equipment,
    required int heroLevel,
  }) {
    if (equipment.isEmpty) {
      return EquipmentBonuses.empty;
    }

    final tier = tierForLevel(heroLevel);
    final echelon = echelonForLevel(heroLevel);

    // Extract bonuses from each equipment piece
    final allBonuses = <_SingleEquipmentBonuses>[];
    for (final component in equipment) {
      final bonus = _extractBonuses(component);
      if (bonus != null) {
        allBonuses.add(bonus);
      }
    }

    if (allBonuses.isEmpty) {
      return EquipmentBonuses.empty;
    }

    // Combine bonuses according to the rules:
    // - Stamina, Speed, Stability, Disengage: HIGHEST value only (not stacking)
    // - Damage, Distance: HIGHEST value for current tier/echelon

    int maxStamina = 0;
    int maxSpeed = 0;
    int maxStability = 0;
    int maxDisengage = 0;
    int maxMeleeDamage = 0;
    int maxRangedDamage = 0;
    int maxMeleeDistance = 0;
    int maxRangedDistance = 0;
    final ids = <String>[];

    for (final bonus in allBonuses) {
      ids.add(bonus.id);
      
      // Take highest value for all stat bonuses (no stacking)
      maxStamina = math.max(maxStamina, bonus.staminaForLevel(heroLevel));
      maxSpeed = math.max(maxSpeed, bonus.speed);
      maxStability = math.max(maxStability, bonus.stability);
      maxDisengage = math.max(maxDisengage, bonus.disengage);
      maxMeleeDamage = math.max(maxMeleeDamage, bonus.meleeDamageForTier(tier));
      maxRangedDamage = math.max(maxRangedDamage, bonus.rangedDamageForTier(tier));
      maxMeleeDistance = math.max(maxMeleeDistance, bonus.meleeDistanceForEchelon(echelon));
      maxRangedDistance = math.max(maxRangedDistance, bonus.rangedDistanceForEchelon(echelon));
    }

    return EquipmentBonuses(
      staminaBonus: maxStamina,
      speedBonus: maxSpeed,
      stabilityBonus: maxStability,
      disengageBonus: maxDisengage,
      meleeDamageBonus: maxMeleeDamage,
      rangedDamageBonus: maxRangedDamage,
      meleeDistanceBonus: maxMeleeDistance,
      rangedDistanceBonus: maxRangedDistance,
      equipmentIds: ids,
    );
  }

  /// Extract bonuses from a single equipment component
  _SingleEquipmentBonuses? _extractBonuses(Component component) {
    final data = component.data;
    
    // Parse basic stats
    final baseStamina = _parseIntOrNull(data['stamina_bonus']) ?? 0;
    final speed = _parseIntOrNull(data['speed_bonus']) ?? 0;
    final stability = _parseIntOrNull(data['stability_bonus']) ?? 0;
    final disengage = _parseIntOrNull(data['disengage_bonus']) ?? 0;

    // All kit stamina bonuses scale with level/echelon.
    // At levels 1-3 (echelon 1): 1x base stamina
    // At levels 4-6 (echelon 2): 2x base stamina
    // At levels 7-9 (echelon 3): 3x base stamina
    // At level 10 (echelon 4): 4x base stamina
    // This applies to all non-zero stamina bonuses from kits.
    final staminaScales = baseStamina > 0;

    // Parse tiered melee damage
    final meleeDamage = data['melee_damage_bonus'];
    final meleeTier1 = _parseTieredValue(meleeDamage, '1st_tier');
    final meleeTier2 = _parseTieredValue(meleeDamage, '2nd_tier');
    final meleeTier3 = _parseTieredValue(meleeDamage, '3rd_tier');

    // Parse tiered ranged damage
    final rangedDamage = data['ranged_damage_bonus'];
    final rangedTier1 = _parseTieredValue(rangedDamage, '1st_tier');
    final rangedTier2 = _parseTieredValue(rangedDamage, '2nd_tier');
    final rangedTier3 = _parseTieredValue(rangedDamage, '3rd_tier');

    // Parse echelon melee distance
    final meleeDistance = data['melee_distance_bonus'];
    final meleeEchelon1 = _parseTieredValue(meleeDistance, '1st_echelon');
    final meleeEchelon2 = _parseTieredValue(meleeDistance, '2nd_echelon');
    final meleeEchelon3 = _parseTieredValue(meleeDistance, '3rd_echelon');

    // Parse echelon ranged distance
    final rangedDistance = data['ranged_distance_bonus'];
    final rangedEchelon1 = _parseTieredValue(rangedDistance, '1st_echelon');
    final rangedEchelon2 = _parseTieredValue(rangedDistance, '2nd_echelon');
    final rangedEchelon3 = _parseTieredValue(rangedDistance, '3rd_echelon');

    return _SingleEquipmentBonuses(
      id: component.id,
      baseStamina: baseStamina,
      staminaScalesWithLevel: staminaScales,
      speed: speed,
      stability: stability,
      disengage: disengage,
      meleeDamageTier1: meleeTier1,
      meleeDamageTier2: meleeTier2,
      meleeDamageTier3: meleeTier3,
      rangedDamageTier1: rangedTier1,
      rangedDamageTier2: rangedTier2,
      rangedDamageTier3: rangedTier3,
      meleeDistanceEchelon1: meleeEchelon1,
      meleeDistanceEchelon2: meleeEchelon2,
      meleeDistanceEchelon3: meleeEchelon3,
      rangedDistanceEchelon1: rangedEchelon1,
      rangedDistanceEchelon2: rangedEchelon2,
      rangedDistanceEchelon3: rangedEchelon3,
    );
  }

  int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _parseTieredValue(dynamic tierData, String key) {
    if (tierData == null) return 0;
    if (tierData is Map) {
      return _parseIntOrNull(tierData[key]) ?? 0;
    }
    return 0;
  }
}
