import 'dart:convert';

/// Represents a single stat modification with its source.
///
/// This is a sealed class hierarchy supporting three scaling types:
/// - [StaticStatModification]: Fixed value that doesn't scale
/// - [LevelScaledStatModification]: Value equals the hero's level
/// - [EchelonScaledStatModification]: Value scales with echelon (levels 1-3 = 1x, 4-6 = 2x, 7-9 = 3x, 10 = 4x)
sealed class StatModification {
  /// The source of this modification (e.g., "Ancestry", "Complication: Bereaved")
  final String source;

  const StatModification({required this.source});

  /// Calculate the actual value based on the hero's level.
  int getActualValue(int heroLevel);

  /// Whether this modification has dynamic scaling (changes with level)
  bool get isDynamic;

  /// The base value used for this modification (for display/serialization)
  int get baseValue;

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson();

  /// Deserialize from JSON
  factory StatModification.fromJson(
    Map<String, dynamic> json, {
    String? defaultSource,
  }) {
    final source = json['source'] as String? ?? defaultSource ?? 'Unknown';
    final dynamicValue = json['dynamicValue'] as String?;
    final perEchelon = json['perEchelon'] as bool? ?? false;
    final valuePerEchelon = (json['valuePerEchelon'] as num?)?.toInt() ?? 0;
    final value = (json['value'] as num?)?.toInt() ?? 0;

    // Determine which subclass to create based on the JSON fields
    if (dynamicValue == 'level') {
      return LevelScaledStatModification(source: source);
    } else if (perEchelon && valuePerEchelon > 0) {
      return EchelonScaledStatModification(
        valuePerEchelon: valuePerEchelon,
        source: source,
      );
    } else {
      return StaticStatModification(value: value, source: source);
    }
  }

  /// Create a static modification (most common case)
  factory StatModification.static({
    required int value,
    required String source,
  }) = StaticStatModification;

  /// Create a level-scaled modification (value = hero level)
  factory StatModification.levelScaled({
    required String source,
  }) = LevelScaledStatModification;

  /// Create an echelon-scaled modification (value = valuePerEchelon × echelon)
  factory StatModification.echelonScaled({
    required int valuePerEchelon,
    required String source,
  }) = EchelonScaledStatModification;
}

/// A stat modification with a fixed value that doesn't scale with level.
class StaticStatModification extends StatModification {
  /// The fixed value of this modification
  final int value;

  const StaticStatModification({
    required this.value,
    required super.source,
  });

  @override
  int getActualValue(int heroLevel) => value;

  @override
  bool get isDynamic => false;

  @override
  int get baseValue => value;

  @override
  Map<String, dynamic> toJson() => {
        'value': value,
        'source': source,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticStatModification &&
          value == other.value &&
          source == other.source;

  @override
  int get hashCode => Object.hash(value, source);

  @override
  String toString() => 'StaticStatModification(value: $value, source: $source)';
}

/// A stat modification where the value equals the hero's level.
/// 
/// Example: "Mundane" complication grants corruption/holy/psychic immunity
/// equal to the hero's level.
class LevelScaledStatModification extends StatModification {
  const LevelScaledStatModification({required super.source});

  @override
  int getActualValue(int heroLevel) => heroLevel;

  @override
  bool get isDynamic => true;

  @override
  int get baseValue => 0;

  @override
  Map<String, dynamic> toJson() => {
        'value': 0,
        'source': source,
        'dynamicValue': 'level',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelScaledStatModification && source == other.source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => 'LevelScaledStatModification(source: $source)';
}

/// A stat modification that scales with echelon.
/// 
/// Echelon calculation: (heroLevel - 1) ~/ 3 + 1
/// - Levels 1-3: echelon 1 (1x valuePerEchelon)
/// - Levels 4-6: echelon 2 (2x valuePerEchelon)
/// - Levels 7-9: echelon 3 (3x valuePerEchelon)
/// - Level 10:   echelon 4 (4x valuePerEchelon)
/// 
/// Example: "Elemental Inside" complication grants +3 stamina per echelon.
class EchelonScaledStatModification extends StatModification {
  /// The value added per echelon
  final int valuePerEchelon;

  const EchelonScaledStatModification({
    required this.valuePerEchelon,
    required super.source,
  });

  @override
  int getActualValue(int heroLevel) {
    final echelon = ((heroLevel - 1) ~/ 3) + 1;
    return valuePerEchelon * echelon;
  }

  @override
  bool get isDynamic => true;

  @override
  int get baseValue => valuePerEchelon;

  @override
  Map<String, dynamic> toJson() => {
        'value': 0,
        'source': source,
        'perEchelon': true,
        'valuePerEchelon': valuePerEchelon,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchelonScaledStatModification &&
          valuePerEchelon == other.valuePerEchelon &&
          source == other.source;

  @override
  int get hashCode => Object.hash(valuePerEchelon, source);

  @override
  String toString() =>
      'EchelonScaledStatModification(valuePerEchelon: $valuePerEchelon, source: $source)';
}

/// Collection of all stat modifications for a hero.
class HeroStatModifications {
  final Map<String, List<StatModification>> modifications;

  const HeroStatModifications({required this.modifications});

  const HeroStatModifications.empty() : modifications = const {};

  factory HeroStatModifications.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! Map) return const HeroStatModifications.empty();
      
      final mods = <String, List<StatModification>>{};
      for (final entry in json.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        
        if (value is List) {
          // New format: list of modifications
          mods[key] = value
              .whereType<Map<String, dynamic>>()
              .map((e) => StatModification.fromJson(e))
              .toList();
        } else if (value is Map) {
          // Single modification format
          mods[key] = [StatModification.fromJson(value as Map<String, dynamic>)];
        } else if (value is num) {
          // Legacy format: just a number (no source info)
          mods[key] = [StaticStatModification(value: value.toInt(), source: 'Ancestry')];
        }
      }
      return HeroStatModifications(modifications: mods);
    } catch (_) {
      return const HeroStatModifications.empty();
    }
  }

  String toJsonString() {
    final map = <String, dynamic>{};
    for (final entry in modifications.entries) {
      map[entry.key] = entry.value.map((m) => m.toJson()).toList();
    }
    return jsonEncode(map);
  }

  /// Get total modification value for a stat.
  /// Uses [baseValue] for static mods; for dynamic mods, use [getTotalForStatAtLevel].
  int getTotalForStat(String stat) {
    final mods = modifications[stat.toLowerCase()];
    if (mods == null || mods.isEmpty) return 0;
    return mods.fold(0, (sum, m) => sum + m.baseValue);
  }

  /// Get total modification value for a stat, calculating dynamic values based on hero level.
  int getTotalForStatAtLevel(String stat, int heroLevel) {
    final mods = modifications[stat.toLowerCase()];
    if (mods == null || mods.isEmpty) return 0;
    return mods.fold(0, (sum, m) => sum + m.getActualValue(heroLevel));
  }

  /// Get all modifications for a stat.
  List<StatModification> getModsForStat(String stat) {
    return modifications[stat.toLowerCase()] ?? [];
  }

  /// Check if any modifications exist for a stat.
  bool hasModsForStat(String stat) {
    final mods = modifications[stat.toLowerCase()];
    return mods != null && mods.isNotEmpty;
  }

  /// Get a formatted string of all sources for a stat.
  /// Uses pattern matching to provide context-aware descriptions for dynamic mods.
  String getSourcesDescription(String stat, [int heroLevel = 1]) {
    final mods = getModsForStat(stat);
    if (mods.isEmpty) return '';
    
    return mods.map((m) {
      final actualValue = m.getActualValue(heroLevel);
      final sign = actualValue >= 0 ? '+' : '';
      
      // Use pattern matching to provide type-specific descriptions
      final suffix = switch (m) {
        StaticStatModification() => '',
        LevelScaledStatModification() => ' (scales with level)',
        EchelonScaledStatModification() => ' (scales with echelon)',
      };
      
      return '$sign$actualValue from ${m.source}$suffix';
    }).join(', ');
  }

  /// Add or update a modification.
  HeroStatModifications withModification(
    String stat,
    int value,
    String source,
  ) {
    final key = stat.toLowerCase();
    final currentMods = List<StatModification>.from(modifications[key] ?? []);
    
    // Find existing mod from this source and update it
    final existingIndex = currentMods.indexWhere((m) => m.source == source);
    if (existingIndex >= 0) {
      currentMods[existingIndex] = StaticStatModification(value: value, source: source);
    } else {
      currentMods.add(StaticStatModification(value: value, source: source));
    }
    
    return HeroStatModifications(
      modifications: {
        ...modifications,
        key: currentMods,
      },
    );
  }

  /// Remove all modifications from a specific source.
  HeroStatModifications removeSource(String source) {
    final newMods = <String, List<StatModification>>{};
    
    for (final entry in modifications.entries) {
      final filtered = entry.value.where((m) => m.source != source).toList();
      if (filtered.isNotEmpty) {
        newMods[entry.key] = filtered;
      }
    }
    
    return HeroStatModifications(modifications: newMods);
  }

  /// Clear all modifications.
  HeroStatModifications clear() => const HeroStatModifications.empty();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroStatModifications &&
          _mapsEqual(modifications, other.modifications);

  static bool _mapsEqual(
    Map<String, List<StatModification>> a,
    Map<String, List<StatModification>> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final listA = a[key]!;
      final listB = b[key]!;
      if (listA.length != listB.length) return false;
      for (var i = 0; i < listA.length; i++) {
        if (listA[i] != listB[i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
    modifications.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))),
  );
}
