import 'dart:convert';

/// Domain model for a retainer instance belonging to a specific hero.
///
/// Stores the player's choices (advancement abilities, characteristic bumps)
/// and combat state. The base retainer template is loaded separately from the
/// Components table as a [Retainer].
class RetainerInstance {
  final String id;
  final String heroId;
  final String retainerComponentId;
  final String name;
  final String role;
  final bool isCustom;
  final Map<String, dynamic>? customData;

  /// Player's chosen advancement abilities at levels 4/7/10.
  /// Maps level (int) → ability component ID.
  /// Each choice is either the retainer-specific ability or a role ability.
  final Map<int, String> advancementChoices;

  /// Player's chosen characteristic bumps at levels 2 and 8.
  /// Maps level (int) → characteristic name (e.g. "might", "agility").
  /// Level 5 increases all by 1 automatically (not stored here).
  final Map<int, String> characteristicChoices;

  /// The retainer's own tracked level (1-10). Independent of the hero's
  /// level — retainers level up on their own via [RetainerRepository.levelUp].
  final int level;

  // Combat state
  final int? currentStamina;
  final int tempStamina;
  final int currentRecoveries;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// All retainers have 6 recoveries.
  static const int maxRecoveries = 6;

  const RetainerInstance({
    required this.id,
    required this.heroId,
    required this.retainerComponentId,
    required this.name,
    required this.role,
    this.isCustom = false,
    this.customData,
    this.advancementChoices = const {},
    this.characteristicChoices = const {},
    this.level = 1,
    this.currentStamina,
    this.tempStamina = 0,
    this.currentRecoveries = maxRecoveries,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  RetainerInstance copyWith({
    String? id,
    String? heroId,
    String? retainerComponentId,
    String? name,
    String? role,
    bool? isCustom,
    Map<String, dynamic>? customData,
    Map<int, String>? advancementChoices,
    Map<int, String>? characteristicChoices,
    int? level,
    int? currentStamina,
    int? tempStamina,
    int? currentRecoveries,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RetainerInstance(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      retainerComponentId: retainerComponentId ?? this.retainerComponentId,
      name: name ?? this.name,
      role: role ?? this.role,
      isCustom: isCustom ?? this.isCustom,
      customData: customData ?? this.customData,
      advancementChoices: advancementChoices ?? this.advancementChoices,
      characteristicChoices:
          characteristicChoices ?? this.characteristicChoices,
      level: level ?? this.level,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      currentRecoveries: currentRecoveries ?? this.currentRecoveries,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON helpers for encoding/decoding the map fields stored in DB columns.
  // ---------------------------------------------------------------------------

  static Map<int, String> decodeIntStringMap(String? json) {
    if (json == null || json.isEmpty || json == '{}') return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  static String encodeIntStringMap(Map<int, String> map) {
    if (map.isEmpty) return '{}';
    return jsonEncode(map.map((k, v) => MapEntry(k.toString(), v)));
  }
}
