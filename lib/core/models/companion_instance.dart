/// Domain model for a companion instance belonging to a specific hero.
///
/// Unlike [RetainerInstance], there are no player choices to store (companion
/// advancement features unlock automatically by level). Combat state is also
/// simpler: per the rules ("Companion Stamina and Recoveries"), a companion's
/// Stamina maximum always equals its hero's Stamina maximum and it has no
/// Recoveries of its own — it spends the hero's. So only *current* stamina is
/// tracked here; max stamina and recovery count are read from the hero's own
/// vitals. The base companion template is loaded separately from the
/// Components table as a [Companion].
class CompanionInstance {
  final String id;
  final String heroId;
  final String companionComponentId;
  final String name;
  final int? currentStamina;
  final int tempStamina;

  /// The companion's current rampage stacks (0..24). Adjusted manually — not
  /// tied to the class heroic resource; lost at the end of an encounter.
  final int currentRampage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanionInstance({
    required this.id,
    required this.heroId,
    required this.companionComponentId,
    required this.name,
    this.currentStamina,
    this.tempStamina = 0,
    this.currentRampage = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  CompanionInstance copyWith({
    String? id,
    String? heroId,
    String? companionComponentId,
    String? name,
    int? currentStamina,
    int? tempStamina,
    int? currentRampage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanionInstance(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      companionComponentId: companionComponentId ?? this.companionComponentId,
      name: name ?? this.name,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      currentRampage: currentRampage ?? this.currentRampage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
