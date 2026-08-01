import '../models/retainer.dart';
import '../models/retainer_instance.dart';

/// Computed stats for a retainer at a specific level.
class RetainerStats {
  final int level;
  final int stamina;
  final int speed;
  final int stability;
  final String size;
  final int freeStrikeDamage;
  final Map<String, int> characteristics;
  final List<String> immunities;
  final List<String> weaknesses;
  final List<String> movementModes;

  /// Cumulative signature damage bonuses: [tier1Bonus, tier2_3Bonus].
  final int signatureDamageBonusTier1;
  final int signatureDamageBonusTier2_3;

  /// Ability IDs available at this level: signature + passives + advancement.
  final String signatureAbilityId;
  final List<String> baseAbilityIds;
  final List<RetainerPassiveTrait> passiveTraits;
  final List<String> advancementAbilityIds;

  /// Levels where the player still needs to make a choice.
  final List<int> pendingCharacteristicChoices;
  final List<int> pendingAdvancementChoices;

  const RetainerStats({
    required this.level,
    required this.stamina,
    required this.speed,
    required this.stability,
    required this.size,
    required this.freeStrikeDamage,
    required this.characteristics,
    required this.immunities,
    required this.weaknesses,
    required this.movementModes,
    required this.signatureDamageBonusTier1,
    required this.signatureDamageBonusTier2_3,
    required this.signatureAbilityId,
    required this.baseAbilityIds,
    required this.passiveTraits,
    required this.advancementAbilityIds,
    required this.pendingCharacteristicChoices,
    required this.pendingAdvancementChoices,
  });

  int get highestCharacteristic {
    if (characteristics.isEmpty) return 0;
    return characteristics.values.reduce((a, b) => a > b ? a : b);
  }
}

/// Computes retainer stats at any level based on the advancement table rules.
///
/// Rules (from the Retainer Advancement Table):
/// - Every level: +9 stamina
/// - Level 2: Choose one characteristic +1 (max 2)
/// - Level 3: Free strike damage +2
/// - Level 4: Choose advancement ability (retainer-specific or role)
/// - Level 5: All characteristics +1 (max 3)
/// - Level 6: Free strike damage +2
/// - Level 7: Choose advancement ability
/// - Level 8: Choose one characteristic +1 (max 4)
/// - Level 9: Free strike damage +2
/// - Level 10: Choose advancement ability
///
/// Signature damage scaling:
/// - Tier 1: +1 at levels 2, 4, 6, 8, 10 (every even level)
/// - Tier 2/3: +1 at every level from 2 through 10
class RetainerAdvancementService {
  const RetainerAdvancementService();

  /// Compute full stats for a retainer at a given [mentorLevel].
  ///
  /// [template] is the base retainer stat block from Components.
  /// [instance] is the player's retainer with chosen abilities/characteristics.
  /// If [instance] is null, pending choices are computed but no player choices
  /// are applied (useful for previews).
  RetainerStats computeStats({
    required Retainer template,
    required int mentorLevel,
    RetainerInstance? instance,
  }) {
    // Effective level is clamped to starting_level..10
    final effectiveLevel = mentorLevel.clamp(template.startingLevel, 10);

    // --- Stamina ---
    // Base + 9 per level above 1
    final stamina =
        template.baseStamina + (9 * (effectiveLevel - template.startingLevel));

    // --- Characteristics ---
    final chars = Map<String, int>.from(template.characteristics);
    _applyCharacteristicBumps(
      chars,
      effectiveLevel,
      template.startingLevel,
      instance?.characteristicChoices ?? const {},
    );

    // --- Free strike damage ---
    var freeStrikeDamage = template.freeStrikeDamage;
    for (final lvl in _freeStrikeLevels) {
      if (lvl > effectiveLevel) break;
      if (lvl <= template.startingLevel) continue;
      freeStrikeDamage += 2;
    }

    // --- Signature damage bonuses ---
    int sigTier1 = 0;
    int sigTier2_3 = 0;
    for (int lvl = template.startingLevel + 1; lvl <= effectiveLevel; lvl++) {
      final entry = _advTable[lvl];
      if (entry != null) {
        sigTier1 += entry.sigTier1;
        sigTier2_3 += entry.sigTier2_3;
      }
    }

    // --- Advancement abilities ---
    final advAbilityIds = <String>[];
    final pendingAdv = <int>[];
    for (final lvl in _advancementAbilityLevels) {
      if (lvl > effectiveLevel) break;
      if (lvl < template.startingLevel) continue;
      final chosen = instance?.advancementChoices[lvl];
      if (chosen != null && chosen.isNotEmpty) {
        advAbilityIds.add(chosen);
      } else {
        pendingAdv.add(lvl);
      }
    }

    // --- Pending characteristic choices ---
    final pendingChars = <int>[];
    for (final lvl in _characteristicChoiceLevels) {
      if (lvl > effectiveLevel) break;
      if (lvl <= template.startingLevel) continue;
      // Level 5 is automatic (all +1), no choice needed
      if (lvl == 5) continue;
      final chosen = instance?.characteristicChoices[lvl];
      if (chosen == null || chosen.isEmpty) {
        pendingChars.add(lvl);
      }
    }

    return RetainerStats(
      level: effectiveLevel,
      stamina: stamina,
      speed: template.speed,
      stability: template.stability,
      size: template.size,
      freeStrikeDamage: freeStrikeDamage,
      characteristics: chars,
      immunities: template.immunities,
      weaknesses: template.weaknesses,
      movementModes: template.movementModes,
      signatureDamageBonusTier1: sigTier1,
      signatureDamageBonusTier2_3: sigTier2_3,
      signatureAbilityId: template.signatureAbilityId,
      baseAbilityIds: template.baseAbilities,
      passiveTraits: template.passiveTraits,
      advancementAbilityIds: advAbilityIds,
      pendingCharacteristicChoices: pendingChars,
      pendingAdvancementChoices: pendingAdv,
    );
  }

  /// Available retainer-specific ability IDs at a given advancement level.
  /// The player picks ONE from either these options or the role's ability.
  List<String> retainerAbilityOptions(Retainer template, int level) {
    return template.advancementAbilities[level] ?? const [];
  }

  // ---------------------------------------------------------------------------
  // Internal rules
  // ---------------------------------------------------------------------------

  /// Levels where free strike damage increases by +2.
  static const _freeStrikeLevels = [3, 6, 9];

  /// Levels where the player chooses an advancement ability.
  static const _advancementAbilityLevels = [4, 7, 10];

  /// Levels where characteristic bumps happen (2 = one, 5 = all, 8 = one).
  static const _characteristicChoiceLevels = [2, 5, 8];

  /// Apply characteristic bumps from levels 2, 5, 8.
  void _applyCharacteristicBumps(
    Map<String, int> chars,
    int effectiveLevel,
    int startingLevel,
    Map<int, String> choices,
  ) {
    // Level 2: choose one +1
    if (effectiveLevel >= 2 && startingLevel < 2) {
      final chosen = choices[2];
      if (chosen != null && chars.containsKey(chosen)) {
        chars[chosen] = chars[chosen]! + 1;
      }
    }

    // Level 5: all +1
    if (effectiveLevel >= 5 && startingLevel < 5) {
      for (final key in chars.keys.toList()) {
        chars[key] = chars[key]! + 1;
      }
    }

    // Level 8: choose one +1
    if (effectiveLevel >= 8 && startingLevel < 8) {
      final chosen = choices[8];
      if (chosen != null && chars.containsKey(chosen)) {
        chars[chosen] = chars[chosen]! + 1;
      }
    }
  }
}

/// Pre-computed advancement table entries for signature damage scaling.
class _AdvEntry {
  final int sigTier1;
  final int sigTier2_3;
  const _AdvEntry(this.sigTier1, this.sigTier2_3);
}

const _advTable = <int, _AdvEntry>{
  2: _AdvEntry(1, 1),
  3: _AdvEntry(0, 1),
  4: _AdvEntry(1, 1),
  5: _AdvEntry(0, 1),
  6: _AdvEntry(1, 1),
  7: _AdvEntry(0, 1),
  8: _AdvEntry(1, 1),
  9: _AdvEntry(0, 1),
  10: _AdvEntry(1, 1),
};
