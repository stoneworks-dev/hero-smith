/// Model class for Green Elementalist animal forms.
/// 
/// This represents a creature form that a Green Elementalist can shapeshift into
/// using the "Disciple of the Green" ability.
class GreenAnimalForm {
  const GreenAnimalForm({
    required this.id,
    required this.name,
    required this.level,
    required this.temporaryStamina,
    required this.baseSpeed,
    this.movementType,
    required this.size,
    required this.stabilityBonus,
    required this.meleeDamageBonus,
    this.special,
  });

  /// Unique identifier for this form
  final String id;

  /// Display name of the animal form
  final String name;

  /// Required hero level to access this form
  final int level;

  /// Temporary stamina granted when entering this form
  final int temporaryStamina;

  /// Base speed in this form
  final int baseSpeed;

  /// Special movement type (e.g., "fly", "swim", "climb", "burrow", "swim_only")
  final String? movementType;

  /// Size category (e.g., "1T", "1S", "1M", "1L", "2", "3", "4")
  final String size;

  /// Bonus to stability in this form
  final int stabilityBonus;

  /// Melee damage bonus for each power roll tier
  final MeleeDamageBonus meleeDamageBonus;

  /// Special ability or effect for this form
  final String? special;

  /// Factory constructor to create from JSON
  factory GreenAnimalForm.fromJson(Map<String, dynamic> json) {
    return GreenAnimalForm(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      temporaryStamina: json['temporary_stamina'] as int? ?? 0,
      baseSpeed: json['base_speed'] as int,
      movementType: json['movement_type'] as String?,
      size: json['size'] as String,
      stabilityBonus: json['stability_bonus'] as int? ?? 0,
      meleeDamageBonus: MeleeDamageBonus.fromJson(
        json['melee_damage_bonus'] as Map<String, dynamic>,
      ),
      special: json['special'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'temporary_stamina': temporaryStamina,
        'base_speed': baseSpeed,
        if (movementType != null) 'movement_type': movementType,
        'size': size,
        'stability_bonus': stabilityBonus,
        'melee_damage_bonus': meleeDamageBonus.toJson(),
        if (special != null) 'special': special,
      };

  /// Get a human-readable movement description
  String get movementDescription {
    if (movementType == null) return 'Walk $baseSpeed';
    switch (movementType) {
      case 'fly':
        return 'Walk $baseSpeed, Fly $baseSpeed';
      case 'swim':
        return 'Walk $baseSpeed, Swim $baseSpeed';
      case 'swim_only':
        return 'Swim $baseSpeed (cannot walk)';
      case 'climb':
        return 'Walk $baseSpeed, Climb $baseSpeed';
      case 'burrow':
        return 'Walk $baseSpeed, Burrow $baseSpeed';
      default:
        return 'Walk $baseSpeed';
    }
  }

  /// Get a formatted size string
  String get sizeDisplay {
    final sizeMap = {
      '1T': 'Size 1T (Tiny)',
      '1S': 'Size 1S (Small)',
      '1M': 'Size 1M (Medium)',
      '1L': 'Size 1L (Large)',
      '2': 'Size 2',
      '3': 'Size 3',
      '4': 'Size 4',
    };
    return sizeMap[size] ?? 'Size $size';
  }
}

/// Represents melee damage bonuses across power roll tiers.
class MeleeDamageBonus {
  const MeleeDamageBonus({
    this.tier1,
    this.tier2,
    this.tier3,
  });

  /// Damage bonus on tier 1 (11 or lower)
  final int? tier1;

  /// Damage bonus on tier 2 (12-16)
  final int? tier2;

  /// Damage bonus on tier 3 (17+)
  final int? tier3;

  factory MeleeDamageBonus.fromJson(Map<String, dynamic> json) {
    return MeleeDamageBonus(
      tier1: json['1st_tier'] as int?,
      tier2: json['2nd_tier'] as int?,
      tier3: json['3rd_tier'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        '1st_tier': tier1,
        '2nd_tier': tier2,
        '3rd_tier': tier3,
      };

  /// Check if any damage bonus is defined
  bool get hasDamageBonus =>
      (tier1 != null && tier1! > 0) ||
      (tier2 != null && tier2! > 0) ||
      (tier3 != null && tier3! > 0);

  /// Get a compact display string for all tiers
  String get displayString {
    if (!hasDamageBonus) return 'No bonus damage';
    final parts = <String>[];
    if (tier1 != null && tier1! > 0) parts.add('T1: +$tier1');
    if (tier2 != null && tier2! > 0) parts.add('T2: +$tier2');
    if (tier3 != null && tier3! > 0) parts.add('T3: +$tier3');
    return parts.join(', ');
  }
}
