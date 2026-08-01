import 'component.dart';

/// A passive trait on a retainer stat block (e.g. "Toxiferous", "Darkvision").
class RetainerPassiveTrait {
  final String id;
  final String name;
  final String description;

  const RetainerPassiveTrait({
    required this.id,
    required this.name,
    required this.description,
  });

  factory RetainerPassiveTrait.fromJson(Map<String, dynamic> json) {
    return RetainerPassiveTrait(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Domain model for a retainer template (stat block) parsed from a Component.
///
/// Represents the base retainer definition as written in the book.
/// Combat state and player choices are tracked separately in [RetainerInstance].
class Retainer {
  final String id;
  final String name;
  final List<String> ancestryTags;
  final int startingLevel;
  final String role;
  final String size;
  final int speed;
  final int baseStamina;
  final int stability;
  final int freeStrikeDamage;
  final List<String> immunities;
  final List<String> weaknesses;
  final List<String> movementModes;
  final Map<String, int> characteristics;
  final String signatureAbilityId;

  /// Non-signature, non-passive base abilities (e.g. maneuvers, triggered actions).
  final List<String> baseAbilities;
  final List<RetainerPassiveTrait> passiveTraits;

  /// Maps advancement level (4, 7, 10) → retainer-specific ability ID options.
  /// At each of these levels the player can choose one of these OR a role
  /// ability. Most retainers offer exactly one option per level; some (e.g.
  /// summoner-type retainers with a minion-unlock alternative) offer more.
  final Map<int, List<String>> advancementAbilities;

  /// Maximum recoveries this retainer can use per respite.
  final int maxRecoveries;

  const Retainer({
    required this.id,
    required this.name,
    required this.ancestryTags,
    required this.startingLevel,
    required this.role,
    required this.size,
    required this.speed,
    required this.baseStamina,
    required this.stability,
    required this.freeStrikeDamage,
    required this.immunities,
    required this.weaknesses,
    required this.movementModes,
    required this.characteristics,
    required this.signatureAbilityId,
    this.baseAbilities = const [],
    required this.passiveTraits,
    required this.advancementAbilities,
    this.maxRecoveries = 6,
  });

  /// Parse from a [Component] whose type is `'retainer'`.
  factory Retainer.fromComponent(Component c) {
    final d = c.data;
    return Retainer(
      id: c.id,
      name: c.name,
      ancestryTags: _stringList(d['ancestry_tags']),
      startingLevel: d['starting_level'] as int? ?? 1,
      role: d['role'] as String? ?? '',
      size: d['size'] as String? ?? '1M',
      speed: d['speed'] as int? ?? 5,
      baseStamina: d['base_stamina'] as int? ?? 21,
      stability: d['stability'] as int? ?? 0,
      freeStrikeDamage: d['free_strike_damage'] as int? ?? 2,
      immunities: _stringList(d['immunities']),
      weaknesses: _stringList(d['weaknesses']),
      movementModes: _stringList(d['movement_modes']),
      characteristics: _intMap(d['characteristics']),
      signatureAbilityId: d['signature_ability'] as String? ?? '',
      baseAbilities: _stringList(d['base_abilities']),
      passiveTraits: _parsePassiveTraits(d['passive_traits']),
      advancementAbilities: _parseAdvancementAbilities(d['advancement_abilities']),
      maxRecoveries: d['max_recoveries'] as int? ?? 6,
    );
  }

  /// The highest single characteristic value (used for power rolls).
  int get highestCharacteristic {
    if (characteristics.isEmpty) return 0;
    return characteristics.values.reduce((a, b) => a > b ? a : b);
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.cast<String>();
    return const [];
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return const {};
  }

  static List<RetainerPassiveTrait> _parsePassiveTraits(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) =>
              RetainerPassiveTrait.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  static Map<int, List<String>> _parseAdvancementAbilities(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(
          int.parse(k.toString()),
          v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
        ),
      );
    }
    return const {};
  }
}
