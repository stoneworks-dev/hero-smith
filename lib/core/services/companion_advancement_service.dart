import '../models/companion.dart';

/// Computed advancement state for a companion at a specific hero level.
///
/// Mirrors [RetainerStats]' shape, but there is no companion-only combat
/// state or stamina/characteristic scaling to compute: the Beastheart book
/// gives the companion a fixed stat block, and every level-driven mechanic
/// (Stamina Gained, Characteristic Increase, etc.) belongs to the hero, not
/// the companion. See companion_instance.dart for the fuller rationale.
class CompanionAdvancementState {
  final int level;

  /// Advancement features unlocked at or before [level] (e.g. levels 3/6/10).
  final List<CompanionAdvancementFeature> unlockedFeatures;

  /// Levels with an advancement feature the hero hasn't reached yet.
  final List<int> pendingLevels;

  const CompanionAdvancementState({
    required this.level,
    required this.unlockedFeatures,
    required this.pendingLevels,
  });
}

/// Resolves a companion template's advancement features against the hero's
/// current (mentor) level. Structural counterpart to
/// [RetainerAdvancementService], trimmed to what the Beastheart companion
/// rules actually define: the companion advances in lockstep with its
/// bonded hero, with no separate choices or stat growth of its own.
class CompanionAdvancementService {
  const CompanionAdvancementService();

  CompanionAdvancementState computeStats({
    required Companion template,
    required int mentorLevel,
  }) {
    final unlocked = template.featuresUnlockedAt(mentorLevel);
    final pending = template.advancementFeatures
        .where((f) => f.level > mentorLevel)
        .map((f) => f.level)
        .toList()
      ..sort();
    return CompanionAdvancementState(
      level: mentorLevel,
      unlockedFeatures: unlocked,
      pendingLevels: pending,
    );
  }
}
