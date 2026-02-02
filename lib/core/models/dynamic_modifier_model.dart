import 'dart:convert';

/// Represents a formula-based modifier that can be recalculated dynamically.
/// 
/// Instead of storing a static value like `+3 to recovery`, we store the formula
/// that generated it, e.g., "highest_characteristic". When the hero's stats change,
/// the modifier automatically recalculates.
class DynamicModifier {
  /// The stat being modified (e.g., 'recovery_value', 'immunity.fire', 'stamina')
  final String stat;

  /// The type of formula used to calculate the value
  final FormulaType formulaType;

  /// Additional data for the formula (e.g., stat name for 'characteristic')
  final String? formulaParam;

  /// How to apply this modifier (add, set, etc.)
  final ModifierOperation operation;

  /// Where this modifier came from (e.g., 'complication_wodewalker')
  final String source;

  /// Optional: damage/effect type for typed modifiers (immunity, weakness, etc.)
  final String? damageType;

  const DynamicModifier({
    required this.stat,
    required this.formulaType,
    this.formulaParam,
    this.operation = ModifierOperation.add,
    required this.source,
    this.damageType,
  });

  /// Calculate the current value based on hero stats
  int calculate(HeroStatsContext context) {
    switch (formulaType) {
      case FormulaType.fixed:
        return int.tryParse(formulaParam ?? '0') ?? 0;

      case FormulaType.level:
        return context.level;

      case FormulaType.highestCharacteristic:
        return [
          context.might,
          context.agility,
          context.reason,
          context.intuition,
          context.presence,
        ].reduce((a, b) => a > b ? a : b);

      case FormulaType.characteristic:
        switch (formulaParam?.toLowerCase()) {
          case 'might':
            return context.might;
          case 'agility':
            return context.agility;
          case 'reason':
            return context.reason;
          case 'intuition':
            return context.intuition;
          case 'presence':
            return context.presence;
          default:
            return 0;
        }

      case FormulaType.halfLevel:
        return context.level ~/ 2;

      case FormulaType.levelPlusOne:
        return context.level + 1;

      case FormulaType.levelMinusOne:
        return (context.level - 1).clamp(0, context.level);

      case FormulaType.fixedTimesLevelMinusOne:
        // formulaParam contains the per-level value (e.g., "3" for +3 stamina per level)
        final perLevel = int.tryParse(formulaParam ?? '0') ?? 0;
        final levelMinus1 = (context.level - 1).clamp(0, context.level);
        return perLevel * levelMinus1;

      case FormulaType.fixedTimesLevelMinusThreshold:
        // formulaParam contains "value:threshold" (e.g., "3:2" means 3 * max(0, level - 2))
        final parts = (formulaParam ?? '0:1').split(':');
        final perLevel = int.tryParse(parts[0]) ?? 0;
        final threshold = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
        final levelsAboveThreshold = (context.level - threshold).clamp(0, context.level);
        return perLevel * levelsAboveThreshold;
    }
  }

  Map<String, dynamic> toJson() => {
        'stat': stat,
        'formulaType': formulaType.name,
        'formulaParam': formulaParam,
        'operation': operation.name,
        'source': source,
        'damageType': damageType,
      };

  factory DynamicModifier.fromJson(Map<String, dynamic> json) {
    return DynamicModifier(
      stat: json['stat'] as String,
      formulaType: FormulaType.values.firstWhere(
        (e) => e.name == json['formulaType'],
        orElse: () => FormulaType.fixed,
      ),
      formulaParam: json['formulaParam'] as String?,
      operation: ModifierOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => ModifierOperation.add,
      ),
      source: json['source'] as String,
      damageType: json['damageType'] as String?,
    );
  }

  @override
  String toString() => 'DynamicModifier(stat: $stat, formula: $formulaType'
      '${formulaParam != null ? '($formulaParam)' : ''}, source: $source)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicModifier &&
          stat == other.stat &&
          formulaType == other.formulaType &&
          formulaParam == other.formulaParam &&
          operation == other.operation &&
          source == other.source &&
          damageType == other.damageType;

  @override
  int get hashCode => Object.hash(
        stat,
        formulaType,
        formulaParam,
        operation,
        source,
        damageType,
      );
}

/// The type of formula used to calculate the modifier value
enum FormulaType {
  /// A fixed numeric value (stored in formulaParam)
  fixed,

  /// The hero's current level
  level,

  /// Half the hero's level (rounded down)
  halfLevel,

  /// Hero's level + 1
  levelPlusOne,

  /// Hero's level - 1 (for stamina per level bonuses that start at level 2)
  levelMinusOne,

  /// The highest of all five characteristics
  highestCharacteristic,

  /// A specific characteristic (name in formulaParam)
  characteristic,

  /// Fixed value multiplied by (level - 1), used for stamina_per_level_increase
  /// formulaParam contains the per-level value
  fixedTimesLevelMinusOne,

  /// Fixed value multiplied by max(0, level - threshold)
  /// formulaParam contains "value:threshold" (e.g., "3:2" means 3 * max(0, level - 2))
  fixedTimesLevelMinusThreshold,
}

/// How to apply the modifier to the base stat
enum ModifierOperation {
  /// Add to the base value
  add,

  /// Set as the base value (overrides)
  set,

  /// Multiply the base value
  multiply,
}

/// Context object providing current hero stats for formula calculation
class HeroStatsContext {
  final int level;
  final int might;
  final int agility;
  final int reason;
  final int intuition;
  final int presence;

  const HeroStatsContext({
    required this.level,
    required this.might,
    required this.agility,
    required this.reason,
    required this.intuition,
    required this.presence,
  });

  /// Create from HeroMainStats
  factory HeroStatsContext.fromMainStats(dynamic stats) {
    return HeroStatsContext(
      level: stats.level as int,
      might: stats.mightTotal as int,
      agility: stats.agilityTotal as int,
      reason: stats.reasonTotal as int,
      intuition: stats.intuitionTotal as int,
      presence: stats.presenceTotal as int,
    );
  }
}

/// A collection of dynamic modifiers that can be serialized
class DynamicModifierList {
  final List<DynamicModifier> modifiers;

  const DynamicModifierList(this.modifiers);

  factory DynamicModifierList.empty() => const DynamicModifierList([]);

  factory DynamicModifierList.fromJsonString(String? json) {
    if (json == null || json.isEmpty) {
      return DynamicModifierList.empty();
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return DynamicModifierList(
          decoded
              .map((e) => DynamicModifier.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (_) {}
    return DynamicModifierList.empty();
  }

  String toJsonString() => jsonEncode(modifiers.map((m) => m.toJson()).toList());

  /// Get all modifiers for a specific stat
  List<DynamicModifier> forStat(String stat) =>
      modifiers.where((m) => m.stat == stat).toList();

  /// Get all modifiers from a specific source
  List<DynamicModifier> fromSource(String source) =>
      modifiers.where((m) => m.source == source).toList();

  /// Calculate the total bonus for a stat
  int calculateTotal(String stat, HeroStatsContext context) {
    int total = 0;
    for (final mod in forStat(stat)) {
      if (mod.operation == ModifierOperation.add) {
        total += mod.calculate(context);
      }
    }
    return total;
  }

  /// Calculate the total bonus for a typed stat (e.g., immunity.fire)
  int calculateTypedTotal(String stat, String type, HeroStatsContext context) {
    int total = 0;
    for (final mod in modifiers) {
      if (mod.stat == stat && mod.damageType == type) {
        if (mod.operation == ModifierOperation.add) {
          total += mod.calculate(context);
        }
      }
    }
    return total;
  }

  /// Add modifiers and return a new list
  DynamicModifierList add(List<DynamicModifier> newModifiers) {
    return DynamicModifierList([...modifiers, ...newModifiers]);
  }

  /// Remove modifiers from a source and return a new list
  DynamicModifierList removeSource(String source) {
    return DynamicModifierList(
      modifiers.where((m) => m.source != source).toList(),
    );
  }

  bool get isEmpty => modifiers.isEmpty;
  bool get isNotEmpty => modifiers.isNotEmpty;
  int get length => modifiers.length;
}
