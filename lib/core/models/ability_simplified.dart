/// Simplified ability model matching the generated JSON format
class AbilitySimplified {
  const AbilitySimplified({
    required this.id,
    required this.name,
    required this.level,
    this.resource,
    this.resourceValue,
    this.storyText,
    this.keywords,
    this.actionType,
    this.triggerText,
    this.distance,
    this.targets,
    this.powerRoll,
    this.tierEffects = const [],
    this.effect,
    this.specialEffect,
  });

  final String id;
  final String name;
  final int level;
  final String? resource;
  final int? resourceValue;
  final String? storyText;
  final String? keywords;
  final String? actionType;
  final String? triggerText;
  final String? distance;
  final String? targets;
  final String? powerRoll;
  final List<AbilityEffectTier> tierEffects;
  final String? effect;
  final String? specialEffect;

  factory AbilitySimplified.fromJson(Map<String, dynamic> json) {
    List<AbilityEffectTier> parseTierEffects(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AbilityEffectTier.fromJson)
            .toList();
      }
      if (raw is Map<String, dynamic>) {
        return [AbilityEffectTier.fromJson(raw)];
      }
      return const <AbilityEffectTier>[];
    }

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      return null;
    }

    int _parseLevel(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return 1; // Default level for signature abilities
        return int.tryParse(trimmed) ?? 1;
      }
      return 1;
    }

    final tierEffects = parseTierEffects(
      json.containsKey('tier_effects') ? json['tier_effects'] : json['effects'],
    );

    final resourceValue = json.containsKey('resource_value')
        ? parseInt(json['resource_value'])
        : null;

    // Helper to safely get string values, treating empty strings as null
    String? safeString(String key) {
      final value = json[key];
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    return AbilitySimplified(
      id: json['id'] as String,
      name: json['name'] as String,
      level: _parseLevel(json['level']),
      resource: safeString('resource'),
      resourceValue: resourceValue,
      storyText: safeString('story_text'),
      keywords: safeString('keywords'),
      actionType: safeString('action_type'),
      triggerText: safeString('trigger_text'),
      distance: safeString('distance'),
      targets: safeString('targets'),
      powerRoll: safeString('power_roll') ?? safeString('roll'),
      tierEffects: tierEffects,
      effect: safeString('effect'),
      specialEffect: safeString('special_effect'),
    );
  }

  // Helper to check if ability has power roll tiers
  bool get hasPowerRoll =>
      powerRoll != null && powerRoll!.isNotEmpty && tierEffects.isNotEmpty;

  // Parse resource into amount and type (e.g., "Ferocity 3" -> amount: 3, type: "Ferocity")
  int? get resourceAmount {
    if (resourceValue != null) {
      return resourceValue;
    }
    if (resource == null || resource!.isEmpty) return null;
    final parts = resource!.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    final trailing = parts.last;
    final parsed = int.tryParse(trailing);
    return parsed;
  }

  String? get resourceType {
    final name = resource?.trim();
    if (name == null || name.isEmpty) return null;
    if (resourceValue != null) {
      return name;
    }
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length <= 1) {
      return name;
    }
    final possibleNumber = parts.last;
    final parsed = int.tryParse(possibleNumber);
    if (parsed != null) {
      return parts.sublist(0, parts.length - 1).join(' ').trim();
    }
    return name;
  }

  // Parse keywords into list
  List<String> get keywordsList {
    if (keywords == null || keywords!.isEmpty) return const [];
    return keywords!.split('/').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
  }

  bool get isSignature {
    final name = resourceType?.toLowerCase();
    if (name == 'signature') {
      return true;
    }
    final rawName = resource?.trim().toLowerCase();
    return rawName == 'signature';
  }
}

/// Represents the tier effects (tier1, tier2, tier3) for abilities with power rolls
class AbilityEffectTier {
  const AbilityEffectTier({
    this.tier1,
    this.tier2,
    this.tier3,
  });

  final String? tier1;
  final String? tier2;
  final String? tier3;

  factory AbilityEffectTier.fromJson(Map<String, dynamic> json) {
    return AbilityEffectTier(
      tier1: json['tier1'] as String?,
      tier2: json['tier2'] as String?,
      tier3: json['tier3'] as String?,
    );
  }

  // Get tier text by name
  String? getTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'tier1':
      case 'low':
        return tier1;
      case 'tier2':
      case 'mid':
        return tier2;
      case 'tier3':
      case 'high':
        return tier3;
      default:
        return null;
    }
  }
}
