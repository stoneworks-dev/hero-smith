import 'dart:convert';

/// Represents a tracked damage resistance (immunity or weakness) for a specific damage type.
/// Immunities and weaknesses are additive: if you have 5 immunity and 3 weakness,
/// the net result is 2 immunity.
class DamageResistance {
  const DamageResistance({
    required this.damageType,
    this.baseImmunity = 0,
    this.baseWeakness = 0,
    this.bonusImmunity = 0,
    this.bonusWeakness = 0,
    this.sources = const [],
    // Dynamic immunity/weakness fields
    this.dynamicImmunity,
    this.dynamicWeakness,
    this.immunityPerEchelon = 0,
    this.weaknessPerEchelon = 0,
  });

  /// The damage type (e.g., "fire", "cold", "corruption", "psychic")
  final String damageType;

  /// Base immunity value (manually set by user)
  final int baseImmunity;

  /// Base weakness value (manually set by user)
  final int baseWeakness;

  /// Bonus immunity from ancestry traits or other sources (calculated)
  final int bonusImmunity;

  /// Bonus weakness from ancestry traits or other sources (calculated)
  final int bonusWeakness;

  /// List of sources contributing to this resistance (trait names, etc.)
  final List<String> sources;

  /// Dynamic immunity value (e.g., "level" means immunity = hero level)
  final String? dynamicImmunity;

  /// Dynamic weakness value (e.g., "level" means weakness = hero level)
  final String? dynamicWeakness;

  /// Immunity value per echelon (calculated as valuePerEchelon * echelon)
  final int immunityPerEchelon;

  /// Weakness value per echelon (calculated as valuePerEchelon * echelon)
  final int weaknessPerEchelon;

  /// Whether this resistance has dynamic scaling
  bool get hasDynamicImmunity => dynamicImmunity != null || immunityPerEchelon > 0;
  bool get hasDynamicWeakness => dynamicWeakness != null || weaknessPerEchelon > 0;

  /// Calculate total immunity at a given hero level
  int totalImmunityAtLevel(int heroLevel) {
    int total = baseImmunity + bonusImmunity;
    if (dynamicImmunity == 'level') {
      total += heroLevel;
    }
    if (immunityPerEchelon > 0) {
      final echelon = ((heroLevel - 1) ~/ 3) + 1;
      total += immunityPerEchelon * echelon;
    }
    return total;
  }

  /// Calculate total weakness at a given hero level
  int totalWeaknessAtLevel(int heroLevel) {
    int total = baseWeakness + bonusWeakness;
    if (dynamicWeakness == 'level') {
      total += heroLevel;
    }
    if (weaknessPerEchelon > 0) {
      final echelon = ((heroLevel - 1) ~/ 3) + 1;
      total += weaknessPerEchelon * echelon;
    }
    return total;
  }

  /// Net resistance value at a given hero level
  int netValueAtLevel(int heroLevel) {
    return totalImmunityAtLevel(heroLevel) - totalWeaknessAtLevel(heroLevel);
  }

  /// Total immunity before netting against weakness (static, for backward compat)
  int get totalImmunity => baseImmunity + bonusImmunity;

  /// Total weakness before netting against immunity (static, for backward compat)
  int get totalWeakness => baseWeakness + bonusWeakness;

  /// Net resistance value. Positive = immunity, Negative = weakness (static)
  int get netValue => totalImmunity - totalWeakness;

  /// Whether this results in immunity (net positive)
  bool get hasImmunity => netValue > 0;

  /// Whether this results in weakness (net negative)
  bool get hasWeakness => netValue < 0;

  /// Display string for the net value (static)
  String get displayValue {
    final net = netValue;
    if (net > 0) return 'Immunity $net';
    if (net < 0) return 'Weakness ${net.abs()}';
    return 'None';
  }

  /// Display string for the net value at a given hero level
  String displayValueAtLevel(int heroLevel) {
    final net = netValueAtLevel(heroLevel);
    if (net > 0) return 'Immunity $net';
    if (net < 0) return 'Weakness ${net.abs()}';
    return 'None';
  }

  DamageResistance copyWith({
    String? damageType,
    int? baseImmunity,
    int? baseWeakness,
    int? bonusImmunity,
    int? bonusWeakness,
    List<String>? sources,
    String? dynamicImmunity,
    String? dynamicWeakness,
    int? immunityPerEchelon,
    int? weaknessPerEchelon,
  }) {
    return DamageResistance(
      damageType: damageType ?? this.damageType,
      baseImmunity: baseImmunity ?? this.baseImmunity,
      baseWeakness: baseWeakness ?? this.baseWeakness,
      bonusImmunity: bonusImmunity ?? this.bonusImmunity,
      bonusWeakness: bonusWeakness ?? this.bonusWeakness,
      sources: sources ?? this.sources,
      dynamicImmunity: dynamicImmunity ?? this.dynamicImmunity,
      dynamicWeakness: dynamicWeakness ?? this.dynamicWeakness,
      immunityPerEchelon: immunityPerEchelon ?? this.immunityPerEchelon,
      weaknessPerEchelon: weaknessPerEchelon ?? this.weaknessPerEchelon,
    );
  }

  Map<String, dynamic> toJson() => {
        'damageType': damageType,
        'baseImmunity': baseImmunity,
        'baseWeakness': baseWeakness,
        'bonusImmunity': bonusImmunity,
        'bonusWeakness': bonusWeakness,
        'sources': sources,
        if (dynamicImmunity != null) 'dynamicImmunity': dynamicImmunity,
        if (dynamicWeakness != null) 'dynamicWeakness': dynamicWeakness,
        if (immunityPerEchelon > 0) 'immunityPerEchelon': immunityPerEchelon,
        if (weaknessPerEchelon > 0) 'weaknessPerEchelon': weaknessPerEchelon,
      };

  factory DamageResistance.fromJson(Map<String, dynamic> json) {
    return DamageResistance(
      damageType: json['damageType'] as String? ?? '',
      baseImmunity: (json['baseImmunity'] as num?)?.toInt() ?? 0,
      baseWeakness: (json['baseWeakness'] as num?)?.toInt() ?? 0,
      bonusImmunity: (json['bonusImmunity'] as num?)?.toInt() ?? 0,
      bonusWeakness: (json['bonusWeakness'] as num?)?.toInt() ?? 0,
      sources: (json['sources'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dynamicImmunity: json['dynamicImmunity'] as String?,
      dynamicWeakness: json['dynamicWeakness'] as String?,
      immunityPerEchelon: (json['immunityPerEchelon'] as num?)?.toInt() ?? 0,
      weaknessPerEchelon: (json['weaknessPerEchelon'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Container for all damage resistances for a hero.
class HeroDamageResistances {
  const HeroDamageResistances({
    required this.resistances,
  });

  final List<DamageResistance> resistances;

  /// Get a copy with only base values (strips all bonus values).
  /// Used for saving to storage - bonus values are calculated at runtime.
  HeroDamageResistances get baseOnly {
    return HeroDamageResistances(
      resistances: resistances.map((r) => DamageResistance(
        damageType: r.damageType,
        baseImmunity: r.baseImmunity,
        baseWeakness: r.baseWeakness,
        // All bonus/dynamic values are stripped
      )).toList(),
    );
  }

  /// Get resistance for a specific damage type, or null if not tracked.
  DamageResistance? forType(String damageType) {
    final normalized = damageType.toLowerCase();
    return resistances.cast<DamageResistance?>().firstWhere(
          (r) => r!.damageType.toLowerCase() == normalized,
          orElse: () => null,
        );
  }

  /// Get all types that have any immunity or weakness (static check)
  List<DamageResistance> get activeResistances {
    return resistances.where((r) => r.netValue != 0).toList();
  }

  /// Get all types that have any immunity or weakness at a given hero level
  List<DamageResistance> activeResistancesAtLevel(int heroLevel) {
    return resistances.where((r) => r.netValueAtLevel(heroLevel) != 0).toList();
  }

  /// Add or update a resistance for a damage type
  HeroDamageResistances upsertResistance(DamageResistance resistance) {
    final normalized = resistance.damageType.toLowerCase();
    final updated = List<DamageResistance>.from(resistances);
    final index = updated.indexWhere(
      (r) => r.damageType.toLowerCase() == normalized,
    );
    if (index >= 0) {
      updated[index] = resistance;
    } else {
      updated.add(resistance);
    }
    return HeroDamageResistances(resistances: updated);
  }

  /// Remove a resistance by damage type
  HeroDamageResistances removeResistance(String damageType) {
    final normalized = damageType.toLowerCase();
    return HeroDamageResistances(
      resistances: resistances
          .where((r) => r.damageType.toLowerCase() != normalized)
          .toList(),
    );
  }

  /// Merge bonus values from ancestry/traits while preserving base values.
  /// 
  /// If [clearMissing] is true (default), bonuses for damage types not in [bonuses]
  /// will be cleared to 0. If false, existing bonus values are preserved for types
  /// not in [bonuses].
  HeroDamageResistances applyBonuses(
    Map<String, DamageResistanceBonus> bonuses, {
    bool clearMissing = true,
  }) {
    final updated = <DamageResistance>[];
    final processed = <String>{};

    // Update existing resistances
    for (final existing in resistances) {
      final key = existing.damageType.toLowerCase();
      processed.add(key);
      final bonus = bonuses[key];
      if (bonus != null) {
        updated.add(existing.copyWith(
          bonusImmunity: bonus.immunity,
          bonusWeakness: bonus.weakness,
          sources: bonus.sources,
          dynamicImmunity: bonus.dynamicImmunity,
          dynamicWeakness: bonus.dynamicWeakness,
          immunityPerEchelon: bonus.immunityPerEchelon,
          weaknessPerEchelon: bonus.weaknessPerEchelon,
        ));
      } else if (clearMissing) {
        // Clear bonus values for types not in the bonus map
        updated.add(existing.copyWith(
          bonusImmunity: 0,
          bonusWeakness: 0,
          sources: const [],
        ));
      } else {
        // Preserve existing bonus values
        updated.add(existing);
      }
    }

    // Add new damage types from bonuses that weren't in existing resistances
    for (final entry in bonuses.entries) {
      if (!processed.contains(entry.key)) {
        updated.add(DamageResistance(
          damageType: entry.value.damageType,
          bonusImmunity: entry.value.immunity,
          bonusWeakness: entry.value.weakness,
          sources: entry.value.sources,
          dynamicImmunity: entry.value.dynamicImmunity,
          dynamicWeakness: entry.value.dynamicWeakness,
          immunityPerEchelon: entry.value.immunityPerEchelon,
          weaknessPerEchelon: entry.value.weaknessPerEchelon,
        ));
      }
    }

    return HeroDamageResistances(resistances: updated);
  }

  /// Merge bonuses from multiple sources additively.
  /// 
  /// Unlike [applyBonuses], this adds the bonus values to existing bonuses
  /// rather than replacing them, and combines source lists.
  HeroDamageResistances mergeBonuses(Map<String, DamageResistanceBonus> bonuses) {
    final updated = <DamageResistance>[];
    final processed = <String>{};

    // Update existing resistances by adding new bonuses
    for (final existing in resistances) {
      final key = existing.damageType.toLowerCase();
      processed.add(key);
      final bonus = bonuses[key];
      if (bonus != null) {
        // Combine sources, avoiding duplicates
        final combinedSources = <String>{...existing.sources, ...bonus.sources}.toList();
        updated.add(existing.copyWith(
          bonusImmunity: existing.bonusImmunity + bonus.immunity,
          bonusWeakness: existing.bonusWeakness + bonus.weakness,
          sources: combinedSources,
        ));
      } else {
        // No new bonus for this type, keep existing
        updated.add(existing);
      }
    }

    // Add new damage types from bonuses that weren't in existing resistances
    for (final entry in bonuses.entries) {
      if (!processed.contains(entry.key)) {
        updated.add(DamageResistance(
          damageType: entry.value.damageType,
          bonusImmunity: entry.value.immunity,
          bonusWeakness: entry.value.weakness,
          sources: entry.value.sources,
        ));
      }
    }

    return HeroDamageResistances(resistances: updated);
  }

  Map<String, dynamic> toJson() => {
        'resistances': resistances.map((r) => r.toJson()).toList(),
      };

  factory HeroDamageResistances.fromJson(Map<String, dynamic> json) {
    final list = json['resistances'] as List?;
    return HeroDamageResistances(
      resistances: list
              ?.map((r) => DamageResistance.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory HeroDamageResistances.fromJsonString(String jsonString) {
    return HeroDamageResistances.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  static const empty = HeroDamageResistances(resistances: []);
}

/// Intermediate structure for accumulating bonuses from multiple sources
class DamageResistanceBonus {
  DamageResistanceBonus({
    required this.damageType,
    this.immunity = 0,
    this.weakness = 0,
    List<String>? sources,
    this.dynamicImmunity,
    this.dynamicWeakness,
    this.immunityPerEchelon = 0,
    this.weaknessPerEchelon = 0,
  }) : sources = sources ?? [];

  final String damageType;
  int immunity;
  int weakness;
  final List<String> sources;
  String? dynamicImmunity;
  String? dynamicWeakness;
  int immunityPerEchelon;
  int weaknessPerEchelon;

  void addImmunity(int value, String source) {
    immunity += value;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  void addWeakness(int value, String source) {
    weakness += value;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  void setDynamicImmunity(String value, String source) {
    dynamicImmunity = value;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  void setDynamicWeakness(String value, String source) {
    dynamicWeakness = value;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  void addImmunityPerEchelon(int valuePerEchelon, String source) {
    immunityPerEchelon += valuePerEchelon;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }

  void addWeaknessPerEchelon(int valuePerEchelon, String source) {
    weaknessPerEchelon += valuePerEchelon;
    if (!sources.contains(source)) {
      sources.add(source);
    }
  }
}

/// Standard damage types in the system
class DamageTypes {
  DamageTypes._();

  static const String acid = 'acid';
  static const String cold = 'cold';
  static const String corruption = 'corruption';
  static const String fire = 'fire';
  static const String holy = 'holy';
  static const String lightning = 'lightning';
  static const String poison = 'poison';
  static const String psychic = 'psychic';
  static const String sonic = 'sonic';
  /// Generic "all damage" type - applies to all damage
  static const String damage = 'damage';

  static const List<String> all = [
    acid,
    cold,
    corruption,
    fire,
    holy,
    lightning,
    poison,
    psychic,
    sonic,
    damage, // Generic "all damage" type
  ];

  static String displayName(String type) {
    if (type.isEmpty) return 'Unknown';
    if (type == damage) return 'All Damage';
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }
}
