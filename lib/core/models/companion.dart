import 'component.dart';

/// Base stat block for a companion template. Every field is nullable/partial
/// because companions don't share a fixed stat shape with retainers (e.g. a
/// companion may only define 2 of the 5 characteristics, and has no stamina
/// field at all).
class CompanionStats {
  final String? size;
  final int? speed;
  final Map<String, int> characteristics;
  final List<String> immunities;
  final List<String> movementModes;

  /// Free strike damage formula, e.g. "1+ M". Kept as a string because it is
  /// a die-formula-plus-characteristic notation, not a flat number.
  final String? freeStrike;
  final int? stability;
  final List<String> skills;

  const CompanionStats({
    this.size,
    this.speed,
    this.characteristics = const {},
    this.immunities = const [],
    this.movementModes = const [],
    this.freeStrike,
    this.stability,
    this.skills = const [],
  });

  factory CompanionStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanionStats();
    return CompanionStats(
      size: json['size'] as String?,
      speed: (json['speed'] as num?)?.toInt(),
      characteristics: _intMap(json['characteristics']),
      immunities: _stringList(json['immunities']),
      movementModes: _stringList(json['movement_modes']),
      freeStrike: json['free_strike'] as String?,
      stability: (json['stability'] as num?)?.toInt(),
      skills: _stringList(json['skills']),
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return const {};
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.cast<String>();
    return const [];
  }
}

/// A fixed (always-on) companion feature, e.g. "Strong Like Bear".
class CompanionFeature {
  final String name;
  final String description;

  const CompanionFeature({required this.name, required this.description});

  factory CompanionFeature.fromJson(Map<String, dynamic> json) {
    return CompanionFeature(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// A companion feature unlocked automatically at a specific hero level.
/// Unlike retainer advancement abilities, there is no player choice among
/// options here.
class CompanionAdvancementFeature {
  final String name;
  final String description;
  final int level;

  const CompanionAdvancementFeature({
    required this.name,
    required this.description,
    required this.level,
  });

  factory CompanionAdvancementFeature.fromJson(Map<String, dynamic> json) {
    return CompanionAdvancementFeature(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Domain model for a companion template (stat block) parsed from a
/// Component. Represents the base companion definition as written in the
/// book. Player choices and any future combat state are tracked separately.
class Companion {
  final String id;
  final String name;
  final List<String> keywords;
  final CompanionStats stats;
  final List<CompanionFeature> features;

  /// Companion abilities, synthesized into ability-shaped Components so the
  /// existing ability rendering widgets can be reused directly. Companion
  /// abilities are embedded inline in the source record (unlike retainer
  /// abilities, which are referenced by ID into a separate file), so there is
  /// nothing to look up.
  final List<Component> abilities;
  final List<CompanionAdvancementFeature> advancementFeatures;

  const Companion({
    required this.id,
    required this.name,
    required this.keywords,
    required this.stats,
    required this.features,
    required this.abilities,
    required this.advancementFeatures,
  });

  factory Companion.fromComponent(Component c) {
    final d = c.data;
    return Companion(
      id: c.id,
      name: c.name,
      keywords: _stringList(d['keywords']),
      stats: CompanionStats.fromJson(d['stats'] as Map<String, dynamic>?),
      features: _parseFeatures(d['features']),
      abilities: _synthesizeAbilityComponents(c.id, d['abilities']),
      advancementFeatures: _parseAdvancementFeatures(d['advancement_features']),
    );
  }

  /// Advancement features unlocked at or before [heroLevel]. Companion
  /// advancement is automatic, so this is a plain filter rather than a
  /// choice-resolution step.
  List<CompanionAdvancementFeature> featuresUnlockedAt(int heroLevel) {
    return advancementFeatures.where((f) => f.level <= heroLevel).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.cast<String>();
    return const [];
  }

  static List<CompanionFeature> _parseFeatures(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) => CompanionFeature.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  static List<CompanionAdvancementFeature> _parseAdvancementFeatures(
      dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) =>
              CompanionAdvancementFeature.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  static List<Component> _synthesizeAbilityComponents(
      String companionId, dynamic value) {
    if (value is! List) return const [];
    final components = <Component>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final name = map.remove('name') as String? ?? 'ability_$i';
      components.add(Component(
        id: '${companionId}__ability_${_slugify(name)}',
        type: 'ability',
        name: name,
        data: map,
      ));
    }
    return components;
  }

  static String _slugify(String text) {
    final value = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return value.isEmpty ? 'ability' : value;
  }
}
