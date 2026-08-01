import 'component.dart';

/// Base stat block for a minion template. Structurally closest to
/// [Retainer]'s stat shape (role/size/speed/stamina/stability/free strike/
/// characteristics/immunities/weaknesses/movement modes), plus two fields
/// unique to minions: which Portfolio they belong to (e.g. "demon") and the
/// essence cost/summon-batch-size pair a Summoner spends to call them (e.g.
/// "3 essence for two minions" -> essenceCost 3, minionsPerSummon 2).
/// Signature-tier minions use essenceCost 1 / minionsPerSummon 1 (summoned
/// free at the start of combat/turn per the class rules; the 1-essence cost
/// only applies when summoning *extra* signature minions via Call Forth).
class MinionStats {
  final String portfolio;
  final int essenceCost;
  final int minionsPerSummon;
  final String role;
  final String? size;
  final int? speed;
  /// A numeric value or one of M/A/R/I/P when stability follows a
  /// characteristic (for example, Walking Boulder has Stability R).
  final String? stability;
  final int? stamina;

  /// Free strike damage formula, e.g. "2" or "1+ M". Kept as a string for the
  /// same reason as [CompanionStats.freeStrike]: it is sometimes a
  /// die-formula-plus-characteristic notation, not a flat number.
  final String? freeStrike;
  final String? freeStrikeDamageType;
  final bool isSignature;
  final Map<String, int> characteristics;
  final List<String> immunities;
  final List<String> weaknesses;
  final List<String> movementModes;

  const MinionStats({
    this.portfolio = '',
    this.essenceCost = 0,
    this.minionsPerSummon = 1,
    this.role = '',
    this.size,
    this.speed,
    this.stability,
    this.stamina,
    this.freeStrike,
    this.freeStrikeDamageType,
    this.isSignature = false,
    this.characteristics = const {},
    this.immunities = const [],
    this.weaknesses = const [],
    this.movementModes = const [],
  });

  factory MinionStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MinionStats();
    return MinionStats(
      portfolio: json['portfolio'] as String? ?? '',
      essenceCost: (json['essence_cost'] as num?)?.toInt() ?? 0,
      minionsPerSummon: (json['minions_per_summon'] as num?)?.toInt() ?? 1,
      role: json['role'] as String? ?? '',
      size: json['size'] as String?,
      speed: (json['speed'] as num?)?.toInt(),
      stability: json['stability']?.toString(),
      stamina: (json['stamina'] as num?)?.toInt(),
      freeStrike: json['free_strike'] as String?,
      freeStrikeDamageType: _emptyWhenDash(json['free_strike_damage_type']),
      isSignature: json['is_signature'] as bool? ?? false,
      characteristics: _intMap(json['characteristics']),
      immunities: _stringList(json['immunities']),
      weaknesses: _stringList(json['weaknesses']),
      movementModes: _stringList(json['movement_modes']),
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

  static String? _emptyWhenDash(dynamic value) {
    final text = value as String?;
    return text == '-' ? '' : text;
  }
}

/// A named trait on a minion stat block (e.g. "Soulsight", "Extended Barbed
/// Strike"). Mirrors [CompanionFeature].
class MinionTrait {
  final String name;
  final String description;
  final int? essenceCost;

  const MinionTrait({
    required this.name,
    required this.description,
    this.essenceCost,
  });

  factory MinionTrait.fromJson(Map<String, dynamic> json) {
    return MinionTrait(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      essenceCost: (json['essence_cost'] as num?)?.toInt(),
    );
  }
}

/// A stable pointer to an ordinary ability-library record. This keeps the
/// minion card from duplicating a partial ability body.
class MinionAbilityReference {
  final String abilityId;
  final String name;

  const MinionAbilityReference({required this.abilityId, required this.name});

  factory MinionAbilityReference.fromJson(dynamic value) {
    if (value is String) {
      return MinionAbilityReference(abilityId: value, name: value);
    }
    final json = Map<String, dynamic>.from(value as Map);
    return MinionAbilityReference(
      abilityId: json['ability_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Domain model for a minion template (stat block) parsed from a Component.
///
/// Represents the base minion definition as written in the book. Unlike
/// companions/retainers (0-1 instance per hero), minions are summoned into
/// concurrent squads tracked separately by [MinionSquadInstance] — this
/// class only holds the shared species definition.
class Minion {
  final String id;
  final String name;
  final String description;
  final List<String> keywords;
  final MinionStats stats;
  final List<MinionTrait> traits;

  /// Minion abilities, synthesized into ability-shaped Components exactly
  /// like [Companion.abilities] so the existing ability rendering widgets
  /// can be reused directly. Usually 0 or 1 entries — only higher essence
  /// tiers have a named signature ability beyond their free strike.
  final List<MinionAbilityReference> abilities;

  const Minion({
    required this.id,
    required this.name,
    required this.description,
    required this.keywords,
    required this.stats,
    required this.traits,
    required this.abilities,
  });

  factory Minion.fromComponent(Component c) {
    final d = c.data;
    return Minion(
      id: c.id,
      name: c.name,
      description: d['description'] as String? ?? '',
      keywords: _stringList(d['keywords']),
      // Native minion JSON is flat. Retain the nested fallback for older
      // hand-authored entries and test fixtures.
      stats: MinionStats.fromJson(d['stats'] is Map
          ? Map<String, dynamic>.from(d['stats'] as Map)
          : d),
      traits: _parseTraits(d['traits']),
      abilities: _synthesizeAbilityComponents(c.id, d['abilities']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.cast<String>();
    return const [];
  }

  static List<MinionTrait> _parseTraits(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) => MinionTrait.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  static List<MinionAbilityReference> _synthesizeAbilityComponents(
      String minionId, dynamic value) {
    if (value is! List) return const [];
    final references = <MinionAbilityReference>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is String || entry is Map) {
        final reference = MinionAbilityReference.fromJson(entry);
        if (reference.abilityId.isNotEmpty) {
          references.add(reference);
        } else if (entry is Map) {
          final name = entry['name']?.toString() ?? 'ability_$i';
          references.add(MinionAbilityReference(
            abilityId: '${minionId}__${_slugify(name)}',
            name: name,
          ));
        }
      }
    }
    return references;
  }

  static String _slugify(String text) {
    final value = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return value.isEmpty ? 'ability' : value;
  }
}
