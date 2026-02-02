import 'component.dart';

class AbilityOption {
  const AbilityOption({
    required this.id,
    required this.name,
    required this.component,
    required this.level,
    this.isSignature = false,
    this.costAmount,
    this.resource,
    this.subclass,
  });

  final String id;
  final String name;
  final Component component;
  final int level;
  final bool isSignature;
  final int? costAmount;
  final String? resource;
  final String? subclass;
}

class AbilityAllowance {
  const AbilityAllowance({
    required this.id,
    required this.level,
    required this.pickCount,
    required this.label,
    required this.isSignature,
    required this.requiresSubclass,
    required this.includePreviousLevels,
    this.costAmount,
    this.resource,
  });

  final String id;
  final int level;
  final int pickCount;
  final String label;
  final bool isSignature;
  final bool requiresSubclass;
  final bool includePreviousLevels;
  final int? costAmount;
  final String? resource;
}

class StartingAbilityPlan {
  const StartingAbilityPlan({
    required this.allowances,
  });

  final List<AbilityAllowance> allowances;
}

class StartingAbilitySelectionResult {
  const StartingAbilitySelectionResult({
    required this.selectionsBySlot,
    required this.selectedAbilityIds,
  });

  final Map<String, String?> selectionsBySlot;
  final Set<String> selectedAbilityIds;
}

class AbilityCost {
  const AbilityCost({
    required this.resource,
    required this.amount,
  });

  final String resource;
  final int amount;

  static AbilityCost? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final resource = raw['resource']?.toString().trim();
    final amount = _toInt(raw['amount']);
    if (resource == null || resource.isEmpty || amount == null) {
      return null;
    }
    return AbilityCost(resource: resource, amount: amount);
  }
}

class AbilityRange {
  const AbilityRange({
    this.distance,
    this.area,
    this.value,
  });

  final String? distance;
  final String? area;
  final String? value;

  static AbilityRange? tryParse(dynamic raw) {
    // Handle simple string format (e.g., "3 cube within 1" or "Ranged 5")
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return AbilityRange(distance: trimmed);
    }
    if (raw is! Map) return null;
    final distance = _string(raw['distance']);
    final area = _string(raw['area']);
    final valueRaw = raw['range_value'];
    final value =
        valueRaw == null ? null : _string(valueRaw) ?? valueRaw.toString();
    if (distance == null && area == null && value == null) {
      return null;
    }
    return AbilityRange(
      distance: distance,
      area: area,
      value: value,
    );
  }
}

class AbilityTierDetail {
  const AbilityTierDetail({
    this.damageExpression,
    this.baseDamageValue,
    this.characteristicDamageOptions,
    this.damageTypes,
    this.secondaryDamageExpression,
    this.descriptiveText,
    this.potencies,
    this.conditions,
    this.allText,
  });

  final String? damageExpression;
  final int? baseDamageValue;
  final String? characteristicDamageOptions;
  final String? damageTypes;
  final String? secondaryDamageExpression;
  final String? descriptiveText;
  final String? potencies;
  final String? conditions;
  final String? allText;

  static AbilityTierDetail? tryParse(dynamic raw) {
    if (raw is! Map) return null;

    String? text(dynamic value, {String separator = ', '}) {
      if (value == null) return null;
      if (value is List) {
        final parts = <String>[];
        for (final entry in value) {
          final parsed = _string(entry);
          if (parsed != null && parsed.isNotEmpty) {
            parts.add(parsed);
          }
        }
        if (parts.isEmpty) return null;
        return parts.join(separator);
      }
      return _string(value);
    }

    final damageExpression = text(raw['damage_expression']);
    final baseDamage = _toInt(raw['base_damage_value']);
    final characteristic =
        text(raw['characteristic_damage_options'], separator: ' / ');
    final damageTypes = text(raw['damage_types'], separator: ' / ');
    final secondaryDamage = text(raw['secondary_damage_expression']);
    final descriptiveText = text(raw['descriptive_text']);
    final potencies = text(raw['potencies'], separator: '; ');
    final conditions = text(raw['conditions'], separator: '; ');
    final allText = text(raw['all_text']);

    if (damageExpression == null &&
        baseDamage == null &&
        characteristic == null &&
        damageTypes == null &&
        secondaryDamage == null &&
        descriptiveText == null &&
        potencies == null &&
        conditions == null &&
        allText == null) {
      return null;
    }

    return AbilityTierDetail(
      damageExpression: damageExpression,
      baseDamageValue: baseDamage,
      characteristicDamageOptions: characteristic,
      damageTypes: damageTypes,
      secondaryDamageExpression: secondaryDamage,
      descriptiveText: descriptiveText,
      potencies: potencies,
      conditions: conditions,
      allText: allText,
    );
  }
}

class AbilityPowerRoll {
  const AbilityPowerRoll({
    this.label,
    this.characteristics,
    required this.tiers,
  });

  final String? label;
  final String? characteristics;
  final Map<String, AbilityTierDetail> tiers;

  static AbilityPowerRoll? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final label = _string(raw['label']);
    final characteristics = _string(raw['characteristics']);
    final tiers = <String, AbilityTierDetail>{};
    final tierMap = raw['tiers'];
    if (tierMap is Map) {
      for (final entry in tierMap.entries) {
        final parsed = AbilityTierDetail.tryParse(entry.value);
        if (parsed != null) {
          tiers[entry.key.toString()] = parsed;
        }
      }
    }
    if (tiers.isEmpty && label == null && characteristics == null) {
      return null;
    }
    return AbilityPowerRoll(
      label: label,
      characteristics: characteristics,
      tiers: tiers,
    );
  }
}

class AbilityDetail {
  AbilityDetail({
    required this.id,
    required this.name,
    this.level,
    this.cost,
    this.storyText,
    this.keywords = const [],
    this.actionType,
    this.triggerText,
    this.range,
    this.targets,
    this.powerRoll,
    this.effect,
    this.specialEffect,
    this.classSlug,
    this.levelBand,
    this.sourcePath,
    required this.rawData,
  });

  factory AbilityDetail.fromComponent(Component component) {
    final data = component.data;
    // Try to parse range object first, then fall back to direct distance string
    AbilityRange? range = AbilityRange.tryParse(data['range']);
    if (range == null && data['distance'] != null) {
      range = AbilityRange.tryParse(data['distance']);
    }
    return AbilityDetail(
      id: component.id,
      name: component.name,
      level: _toInt(data['level']),
      cost: AbilityCost.tryParse(data['costs']),
      storyText: _string(data['story_text']),
      keywords: _stringList(data['keywords']),
      actionType: _string(data['action_type']),
      triggerText: _string(data['trigger_text']),
      range: range,
      targets: _string(data['targets']),
      powerRoll: AbilityPowerRoll.tryParse(data['power_roll']),
      effect: _string(data['effect']),
      specialEffect: _string(data['special_effect']),
      classSlug: _string(data['class_slug']),
      levelBand: _string(data['level_band']),
      sourcePath: _string(data['ability_source_path']),
      rawData: Map<String, dynamic>.from(data),
    );
  }

  final String id;
  final String name;
  final int? level;
  final AbilityCost? cost;
  final String? storyText;
  final List<String> keywords;
  final String? actionType;
  final String? triggerText;
  final AbilityRange? range;
  final String? targets;
  final AbilityPowerRoll? powerRoll;
  final String? effect;
  final String? specialEffect;
  final String? classSlug;
  final String? levelBand;
  final String? sourcePath;
  final Map<String, dynamic> rawData;

  String? get resourceType => cost?.resource.toLowerCase();
}

int? _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _string(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
  return const [];
}
