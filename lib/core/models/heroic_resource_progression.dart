/// Model classes for heroic resource progression tables (Growing Ferocity, Discipline Mastery)

/// Represents a single tier in a heroic resource progression table.
class ProgressionTier {
  const ProgressionTier({
    required this.resourceThreshold,
    required this.benefit,
    this.requiredLevel,
  });

  /// The resource value required to unlock this tier (e.g., 2, 4, 6, 8, 10, 12 for Ferocity)
  final int resourceThreshold;

  /// The benefit text gained at this tier
  final String benefit;

  /// The hero level required to unlock this tier (null means available at level 1)
  final int? requiredLevel;

  /// Whether this tier is unlocked at the given hero level
  bool isUnlockedAtLevel(int heroLevel) {
    if (requiredLevel == null) return true;
    return heroLevel >= requiredLevel!;
  }

  factory ProgressionTier.fromJson(Map<String, dynamic> json, String resourceKey) {
    return ProgressionTier(
      resourceThreshold: (json[resourceKey] as num?)?.toInt() ?? 0,
      benefit: json['benefit']?.toString() ?? '',
      requiredLevel: (json['level'] as num?)?.toInt(),
    );
  }
}

/// Represents a complete heroic resource progression table.
class HeroicResourceProgression {
  const HeroicResourceProgression({
    required this.id,
    required this.name,
    required this.resourceName,
    required this.tiers,
  });

  /// Unique identifier (e.g., "berserker_growing_ferocity")
  final String id;

  /// Display name (e.g., "Berserker Growing Ferocity")
  final String name;

  /// The name of the heroic resource (e.g., "Ferocity", "Discipline")
  final String resourceName;

  /// The progression tiers in ascending order of resource threshold
  final List<ProgressionTier> tiers;

  /// Get the maximum resource value in this progression
  int get maxResourceValue {
    if (tiers.isEmpty) return 0;
    return tiers.map((t) => t.resourceThreshold).reduce((a, b) => a > b ? a : b);
  }

  /// Get tiers that are unlocked at the given hero level
  List<ProgressionTier> tiersUnlockedAtLevel(int heroLevel) {
    return tiers.where((t) => t.isUnlockedAtLevel(heroLevel)).toList();
  }

  /// Get tiers that are locked at the given hero level
  List<ProgressionTier> tiersLockedAtLevel(int heroLevel) {
    return tiers.where((t) => !t.isUnlockedAtLevel(heroLevel)).toList();
  }

  /// Get the current active tier based on resource value and hero level
  ProgressionTier? getCurrentTier(int currentResource, int heroLevel) {
    final unlocked = tiersUnlockedAtLevel(heroLevel);
    ProgressionTier? current;
    for (final tier in unlocked) {
      if (currentResource >= tier.resourceThreshold) {
        current = tier;
      }
    }
    return current;
  }

  /// Get the next tier to unlock based on current resource and hero level
  ProgressionTier? getNextTier(int currentResource, int heroLevel) {
    final unlocked = tiersUnlockedAtLevel(heroLevel);
    for (final tier in unlocked) {
      if (currentResource < tier.resourceThreshold) {
        return tier;
      }
    }
    return null;
  }

  factory HeroicResourceProgression.fromJson(
    Map<String, dynamic> json, {
    required String resourceName,
    required String resourceKey,
  }) {
    final progression = json['progression'] as List<dynamic>? ?? [];
    final tiers = progression
        .map((e) => ProgressionTier.fromJson(e as Map<String, dynamic>, resourceKey))
        .toList()
      ..sort((a, b) => a.resourceThreshold.compareTo(b.resourceThreshold));

    return HeroicResourceProgression(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      resourceName: resourceName,
      tiers: tiers,
    );
  }
}

/// Enum for heroic resource types that use progression tables
enum HeroicResourceType {
  ferocity,
  discipline,
}

extension HeroicResourceTypeExtension on HeroicResourceType {
  String get displayName {
    switch (this) {
      case HeroicResourceType.ferocity:
        return 'Ferocity';
      case HeroicResourceType.discipline:
        return 'Discipline';
    }
  }

  String get jsonKey {
    switch (this) {
      case HeroicResourceType.ferocity:
        return 'ferocity';
      case HeroicResourceType.discipline:
        return 'discipline';
    }
  }

  String get className {
    switch (this) {
      case HeroicResourceType.ferocity:
        return 'fury';
      case HeroicResourceType.discipline:
        return 'null';
    }
  }
}
