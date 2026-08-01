/// Domain model for one active minion squad belonging to a specific hero.
///
/// Unlike [CompanionInstance]/[RetainerInstance] (each capped at exactly 0-1
/// active row per hero), a Summoner can have **up to 2 concurrent squads** —
/// see [MinionRepository.addSquad] for where that cap is enforced. Each squad
/// pools its Stamina across its members (per the rules, a squad is one
/// summon-able group of the same minion species) rather than tracking each
/// member's Stamina individually, so only a squad-level current/temp Stamina
/// and a member count are stored here. The base minion template (per-member
/// Stamina, role, stats) is loaded separately from the Components table as a
/// [Minion]; the squad's pooled max Stamina is `template.stats.stamina *
/// memberCount`, computed where both are in scope rather than stored twice.
class MinionSquadInstance {
  final String id;
  final String heroId;
  final String minionComponentId;
  final String squadName;
  final int memberCount;
  final int? currentStamina;
  final int tempStamina;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MinionSquadInstance({
    required this.id,
    required this.heroId,
    required this.minionComponentId,
    required this.squadName,
    this.memberCount = 1,
    this.currentStamina,
    this.tempStamina = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  MinionSquadInstance copyWith({
    String? id,
    String? heroId,
    String? minionComponentId,
    String? squadName,
    int? memberCount,
    int? currentStamina,
    int? tempStamina,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MinionSquadInstance(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      minionComponentId: minionComponentId ?? this.minionComponentId,
      squadName: squadName ?? this.squadName,
      memberCount: memberCount ?? this.memberCount,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
