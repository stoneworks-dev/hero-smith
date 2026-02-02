import 'dart:convert';

/// Represents the different types of bonuses that ancestry traits can provide.
enum AncestryBonusType {
  setBaseStatIfNotAlreadyHigher,
  grantsAbilityName,
  increaseTotalPerEchelon,
  increaseTotal,
  decreaseTotal,
  conditionImmunity,
  pickAbilityName,
}

/// Base class for ancestry bonuses.
sealed class AncestryBonus {
  const AncestryBonus({
    required this.sourceTraitId,
    required this.sourceTraitName,
  });

  final String sourceTraitId;
  final String sourceTraitName;

  AncestryBonusType get type;

  Map<String, dynamic> toJson();

  factory AncestryBonus.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = AncestryBonusType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => throw FormatException('Unknown bonus type: $typeStr'),
    );

    return switch (type) {
      AncestryBonusType.setBaseStatIfNotAlreadyHigher =>
        SetBaseStatBonus.fromJson(json),
      AncestryBonusType.grantsAbilityName => GrantsAbilityBonus.fromJson(json),
      AncestryBonusType.increaseTotalPerEchelon =>
        IncreaseTotalPerEchelonBonus.fromJson(json),
      AncestryBonusType.increaseTotal => IncreaseTotalBonus.fromJson(json),
      AncestryBonusType.decreaseTotal => DecreaseTotalBonus.fromJson(json),
      AncestryBonusType.conditionImmunity =>
        ConditionImmunityBonus.fromJson(json),
      AncestryBonusType.pickAbilityName => PickAbilityBonus.fromJson(json),
    };
  }

  static List<AncestryBonus> parseFromTraitData(
      Map<String, dynamic> traitData, String traitId, String traitName,
      [Map<String, String> traitChoices = const {}]) {
    final bonuses = <AncestryBonus>[];

    // set_base_stat_if_not_already_higher
    if (traitData['set_base_stat_if_not_already_higher'] != null) {
      final data = traitData['set_base_stat_if_not_already_higher'];
      if (data is Map) {
        bonuses.add(SetBaseStatBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          stat: (data['stat'] as String?) ?? '',
          value: _parseValue(data['value']),
        ));
      }
    }

    // grants_ability_name or ability_name (ability_name is used in the JSON data files)
    final abilityData =
        traitData['grants_ability_name'] ?? traitData['ability_name'];
    if (abilityData != null) {
      if (abilityData is String && abilityData.isNotEmpty) {
        bonuses.add(GrantsAbilityBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          abilityNames: [abilityData],
        ));
      } else if (abilityData is List) {
        final names = abilityData
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          bonuses.add(GrantsAbilityBonus(
            sourceTraitId: traitId,
            sourceTraitName: traitName,
            abilityNames: names,
          ));
        }
      }
    }

    // increase_total_per_echelon
    if (traitData['increase_total_per_echelon'] != null) {
      final data = traitData['increase_total_per_echelon'];
      if (data is Map) {
        bonuses.add(IncreaseTotalPerEchelonBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          stat: (data['stat'] as String?) ?? '',
          valuePerEchelon: _parseIntValue(data['value']),
        ));
      }
    }

    // increase_total - can be a single object or a list
    if (traitData['increase_total'] != null) {
      final data = traitData['increase_total'];
      if (data is Map) {
        final bonus = _parseIncreaseTotalBonus(
          data.cast<String, dynamic>(),
          traitId,
          traitName,
          traitChoices,
        );
        if (bonus != null) bonuses.add(bonus);
      } else if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final bonus = _parseIncreaseTotalBonus(
              item.cast<String, dynamic>(),
              traitId,
              traitName,
              traitChoices,
            );
            if (bonus != null) bonuses.add(bonus);
          }
        }
      }
    }

    // decrease_total
    if (traitData['decrease_total'] != null) {
      final data = traitData['decrease_total'];
      if (data is Map) {
        bonuses.add(DecreaseTotalBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          stat: (data['stat'] as String?) ?? '',
          value: _parseIntValue(data['value']),
        ));
      }
    }

    // condition_immunity
    if (traitData['condition_immunity'] != null) {
      final data = traitData['condition_immunity'];
      if (data is String) {
        bonuses.add(ConditionImmunityBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          conditionName: data,
        ));
      }
    }

    // pick_ability_name - user chooses one ability from a list
    if (traitData['pick_ability_name'] != null) {
      final data = traitData['pick_ability_name'];
      if (data is List) {
        final options = data.map((e) => e.toString()).toList();
        final selectedAbility = traitChoices[traitId];

        bonuses.add(PickAbilityBonus(
          sourceTraitId: traitId,
          sourceTraitName: traitName,
          abilityOptions: options,
          selectedAbilityName: selectedAbility,
        ));

        // If an ability is selected, also add a grants_ability_name bonus
        if (selectedAbility != null && selectedAbility.isNotEmpty) {
          bonuses.add(GrantsAbilityBonus(
            sourceTraitId: traitId,
            sourceTraitName: traitName,
            abilityNames: [selectedAbility],
          ));
        }
      }
    }

    return bonuses;
  }

  /// Parse an increase_total bonus, handling pick_one for immunity/weakness choices.
  /// Returns null if this is a pick_one type and no choice has been made.
  static IncreaseTotalBonus? _parseIncreaseTotalBonus(
    Map<String, dynamic> data,
    String traitId,
    String traitName,
    Map<String, String> traitChoices,
  ) {
    final stat = (data['stat'] as String?) ?? '';

    // Handle damage type (for immunity/weakness)
    List<String>? damageTypes;
    final typeData = data['type'];
    if (typeData != null) {
      if (typeData == 'pick_one') {
        // For pick_one, get the user's choice from traitChoices
        // Try the trait id first, then signature_immunity for signature traits
        final choiceKey =
            traitId.startsWith('signature') ? 'signature_immunity' : traitId;
        final selectedType = traitChoices[choiceKey];
        if (selectedType != null && selectedType.isNotEmpty) {
          damageTypes = [selectedType];
        } else {
          // No choice made yet, don't create the bonus
          return null;
        }
      } else if (typeData is String) {
        damageTypes = [typeData];
      } else if (typeData is List) {
        damageTypes = typeData.map((e) => e.toString()).toList();
      }
    }

    return IncreaseTotalBonus(
      sourceTraitId: traitId,
      sourceTraitName: traitName,
      stat: stat,
      value: _parseValue(data['value']),
      damageTypes: damageTypes,
    );
  }

  static String _parseValue(dynamic value) {
    if (value == null) return '0';
    return value.toString();
  }

  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// Sets a base stat if the current value is not already higher.
/// Example: "set_base_stat_if_not_already_higher": {"stat": "speed", "value": 6}
class SetBaseStatBonus extends AncestryBonus {
  const SetBaseStatBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.stat,
    required this.value,
  });

  final String stat;
  final String value; // Can be int or string like "1L"

  @override
  AncestryBonusType get type => AncestryBonusType.setBaseStatIfNotAlreadyHigher;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'stat': stat,
        'value': value,
      };

  factory SetBaseStatBonus.fromJson(Map<String, dynamic> json) {
    return SetBaseStatBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      stat: json['stat'] as String? ?? '',
      value: json['value']?.toString() ?? '0',
    );
  }
}

/// Grants one or more abilities by name.
/// Example: "grants_ability_name": "Barbed Tail"
/// Or: "grants_ability_name": ["Vengeance Mark", "Detonate Sigil"]
class GrantsAbilityBonus extends AncestryBonus {
  const GrantsAbilityBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.abilityNames,
  });

  final List<String> abilityNames;

  @override
  AncestryBonusType get type => AncestryBonusType.grantsAbilityName;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'abilityNames': abilityNames,
      };

  factory GrantsAbilityBonus.fromJson(Map<String, dynamic> json) {
    final names = json['abilityNames'];
    return GrantsAbilityBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      abilityNames: names is List
          ? names.map((e) => e.toString()).toList()
          : [names?.toString() ?? ''],
    );
  }
}

/// Increases a total stat by a value per echelon (levels 1-3, 4-6, 7-9, 10).
/// Example: "increase_total_per_echelon": {"stat": "stamina", "value": 6}
class IncreaseTotalPerEchelonBonus extends AncestryBonus {
  const IncreaseTotalPerEchelonBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.stat,
    required this.valuePerEchelon,
  });

  final String stat;
  final int valuePerEchelon;

  @override
  AncestryBonusType get type => AncestryBonusType.increaseTotalPerEchelon;

  /// Calculate the total bonus based on hero level.
  /// Echelon 1: levels 1-3, Echelon 2: levels 4-6, Echelon 3: levels 7-9, Echelon 4: level 10
  int calculateBonus(int heroLevel) {
    final echelon = switch (heroLevel) {
      <= 3 => 1,
      <= 6 => 2,
      <= 9 => 3,
      _ => 4,
    };
    return valuePerEchelon * echelon;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'stat': stat,
        'valuePerEchelon': valuePerEchelon,
      };

  factory IncreaseTotalPerEchelonBonus.fromJson(Map<String, dynamic> json) {
    return IncreaseTotalPerEchelonBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      stat: json['stat'] as String? ?? '',
      valuePerEchelon: (json['valuePerEchelon'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Increases a total stat by a flat value or formula.
/// Example: "increase_total": {"stat": "stability", "value": 1}
/// Or for immunities: "increase_total": {"stat": "immunity", "type": "corruption", "value": "level + 2"}
class IncreaseTotalBonus extends AncestryBonus {
  const IncreaseTotalBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.stat,
    required this.value,
    this.damageTypes,
  });

  final String stat;
  final String value; // Can be int or formula like "level + 2"
  final List<String>? damageTypes; // For immunity/weakness stats

  @override
  AncestryBonusType get type => AncestryBonusType.increaseTotal;

  /// Calculate the numeric value of this bonus.
  /// For formulas like "level + 2", pass the hero level.
  int calculateValue(int heroLevel) {
    // Try parsing as int first
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Handle formulas
    final normalized = value.toLowerCase().replaceAll(' ', '');

    // Pattern: "level+X" or "level-X" or just "level"
    if (normalized == 'level') {
      return heroLevel;
    }

    final levelPlusMatch = RegExp(r'level\+(\d+)').firstMatch(normalized);
    if (levelPlusMatch != null) {
      final addition = int.parse(levelPlusMatch.group(1)!);
      return heroLevel + addition;
    }

    final levelMinusMatch = RegExp(r'level-(\d+)').firstMatch(normalized);
    if (levelMinusMatch != null) {
      final subtraction = int.parse(levelMinusMatch.group(1)!);
      return heroLevel - subtraction;
    }

    // Default to 0 if we can't parse
    return 0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'stat': stat,
        'value': value,
        if (damageTypes != null) 'damageTypes': damageTypes,
      };

  factory IncreaseTotalBonus.fromJson(Map<String, dynamic> json) {
    final types = json['damageTypes'];
    return IncreaseTotalBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      stat: json['stat'] as String? ?? '',
      value: json['value']?.toString() ?? '0',
      damageTypes:
          types is List ? types.map((e) => e.toString()).toList() : null,
    );
  }
}

/// Decreases a total stat by a flat value.
/// Example: "decrease_total": {"stat": "saving throw", "value": 1}
class DecreaseTotalBonus extends AncestryBonus {
  const DecreaseTotalBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.stat,
    required this.value,
  });

  final String stat;
  final int value;

  @override
  AncestryBonusType get type => AncestryBonusType.decreaseTotal;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'stat': stat,
        'value': value,
      };

  factory DecreaseTotalBonus.fromJson(Map<String, dynamic> json) {
    return DecreaseTotalBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      stat: json['stat'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Grants immunity to a condition.
/// Example: "condition_immunity": "dazed"
class ConditionImmunityBonus extends AncestryBonus {
  const ConditionImmunityBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.conditionName,
  });

  final String conditionName;

  @override
  AncestryBonusType get type => AncestryBonusType.conditionImmunity;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'conditionName': conditionName,
      };

  factory ConditionImmunityBonus.fromJson(Map<String, dynamic> json) {
    return ConditionImmunityBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      conditionName: json['conditionName'] as String? ?? '',
    );
  }
}

/// Allows picking one ability from a list of options.
/// Example: "pick_ability_name": ["Concussive Slam", "Psionic Bolt", "Minor Acceleration"]
class PickAbilityBonus extends AncestryBonus {
  const PickAbilityBonus({
    required super.sourceTraitId,
    required super.sourceTraitName,
    required this.abilityOptions,
    required this.selectedAbilityName,
  });

  final List<String> abilityOptions;
  final String? selectedAbilityName;

  @override
  AncestryBonusType get type => AncestryBonusType.pickAbilityName;

  PickAbilityBonus copyWith({String? selectedAbilityName}) {
    return PickAbilityBonus(
      sourceTraitId: sourceTraitId,
      sourceTraitName: sourceTraitName,
      abilityOptions: abilityOptions,
      selectedAbilityName: selectedAbilityName ?? this.selectedAbilityName,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceTraitId': sourceTraitId,
        'sourceTraitName': sourceTraitName,
        'abilityOptions': abilityOptions,
        'selectedAbilityName': selectedAbilityName,
      };

  factory PickAbilityBonus.fromJson(Map<String, dynamic> json) {
    final options = json['abilityOptions'];
    return PickAbilityBonus(
      sourceTraitId: json['sourceTraitId'] as String? ?? '',
      sourceTraitName: json['sourceTraitName'] as String? ?? '',
      abilityOptions:
          options is List ? options.map((e) => e.toString()).toList() : [],
      selectedAbilityName: json['selectedAbilityName'] as String?,
    );
  }
}

/// Container for all bonuses applied from ancestry (signature + selected traits).
class AppliedAncestryBonuses {
  const AppliedAncestryBonuses({
    required this.ancestryId,
    required this.bonuses,
  });

  final String ancestryId;
  final List<AncestryBonus> bonuses;

  Map<String, dynamic> toJson() => {
        'ancestryId': ancestryId,
        'bonuses': bonuses.map((b) => b.toJson()).toList(),
      };

  factory AppliedAncestryBonuses.fromJson(Map<String, dynamic> json) {
    final bonusList = json['bonuses'] as List?;
    return AppliedAncestryBonuses(
      ancestryId: json['ancestryId'] as String? ?? '',
      bonuses: bonusList
              ?.map((b) => AncestryBonus.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppliedAncestryBonuses.fromJsonString(String jsonString) {
    return AppliedAncestryBonuses.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  static const empty = AppliedAncestryBonuses(ancestryId: '', bonuses: []);
}
