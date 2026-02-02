import 'package:collection/collection.dart';

import '../models/class_data.dart';
import '../models/characteristics_models.dart';

/// Shared business logic for managing starting characteristic assignments.
class StartingCharacteristicsService {
  const StartingCharacteristicsService();

  /// Builds display tokens for each array value so they can be uniquely tracked.
  List<CharacteristicValueToken> buildTokens(List<int> values) {
    return List<CharacteristicValueToken>.generate(
      values.length,
      (index) => CharacteristicValueToken(id: index, value: values[index]),
    );
  }

  /// Applies externally provided assignments to the local token map.
  Map<String, CharacteristicValueToken?> applyExternalAssignments({
    required Map<String, CharacteristicValueToken?> base,
    required List<CharacteristicValueToken> tokens,
    required Map<String, int> sourceAssignments,
  }) {
    if (tokens.isEmpty) {
      return {
        for (final entry in base.entries) entry.key: null,
      };
    }

    final normalizedSource = <String, int>{};
    sourceAssignments.forEach((key, value) {
      final normalizedKey = CharacteristicUtils.normalizeKey(key);
      if (normalizedKey != null) {
        normalizedSource[normalizedKey] = value;
      }
    });

    final usedTokenIds = <int>{};
    final updated = <String, CharacteristicValueToken?>{};
    base.forEach((stat, currentToken) {
      final desiredValue = normalizedSource[stat];
      if (desiredValue == null) {
        updated[stat] = null;
        return;
      }
      final match = tokens.firstWhereOrNull(
        (token) =>
            !usedTokenIds.contains(token.id) && token.value == desiredValue,
      );
      if (match != null) {
        updated[stat] = match;
        usedTokenIds.add(match.id);
      } else {
        updated[stat] = null;
      }
    });
    return updated;
  }

  /// Collects all level-based adjustment entries up to the selected level.
  List<AdjustmentEntry> collectAdjustmentEntries({
    required ClassData classData,
    required int selectedLevel,
  }) {
    final entries = <AdjustmentEntry>[];
    for (final levelProgression in classData.levels) {
      final levelNumber = levelProgression.level;
      if (levelNumber > selectedLevel) continue;
      final adjustments = levelProgression.characteristics;
      if (adjustments == null) continue;
      var choiceIndex = 0;
      for (final adjustment in adjustments) {
        for (final entry in adjustment.entries) {
          final normalizedKey =
              CharacteristicUtils.normalizeKey(entry.key.toString());
          if (normalizedKey == null) continue;
          final payload = parseAdjustmentPayload(entry.value);
          if (payload == null) continue;
          String? choiceId;
          if (normalizedKey == 'any') {
            choiceId = buildChoiceId(levelNumber, choiceIndex);
            choiceIndex++;
          }
          entries.add(
            AdjustmentEntry(
              level: levelNumber,
              target: normalizedKey,
              payload: payload,
              choiceId: choiceId,
            ),
          );
        }
      }
    }
    return entries;
  }

  /// Builds level choice metadata for "Any" characteristic selections.
  List<LevelChoice> buildLevelChoices(List<AdjustmentEntry> entries) {
    return entries
        .where((entry) => entry.target == 'any' && entry.choiceId != null)
        .map(
          (entry) => LevelChoice(
            id: entry.choiceId!,
            level: entry.level,
            payload: entry.payload,
          ),
        )
        .toList();
  }

  /// Builds or refreshes the level choice selections map.
  Map<String, String?> buildLevelChoiceSelections({
    required List<LevelChoice> choices,
    required Map<String, String?> previousSelections,
    required bool preserveSelections,
  }) {
    final selections = <String, String?>{};
    for (final choice in choices) {
      selections[choice.id] =
          preserveSelections ? previousSelections[choice.id] : null;
    }
    return selections;
  }

  /// Parses an adjustment payload from JSON-like data.
  AdjustmentPayload? parseAdjustmentPayload(dynamic data) {
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      return AdjustmentPayload(
        increaseBy: CharacteristicUtils.toIntOrNull(
            map['increaseBy'] ?? map['increase_by']),
        setTo: CharacteristicUtils.toIntOrNull(map['setTo'] ?? map['set_to']),
        max: CharacteristicUtils.toIntOrNull(map['max']),
      );
    }
    if (data is num) {
      return AdjustmentPayload(increaseBy: data.toInt());
    }
    return null;
  }

  /// Builds a summary of totals, fixed values, array contributions, and bonuses.
  CharacteristicSummary buildCharacteristicSummary({
    required Map<String, int> fixedValues,
    required Map<String, CharacteristicValueToken?> assignments,
    required List<AdjustmentEntry> adjustmentEntries,
    required Map<String, String?> levelChoiceSelections,
  }) {
    final totals = <String, int>{};
    final arrayContrib = <String, int>{};
    for (final stat in CharacteristicUtils.characteristicOrder) {
      final fixed = fixedValues[stat] ?? 0;
      final assignment = assignments[stat]?.value ?? 0;
      totals[stat] = fixed + assignment;
      arrayContrib[stat] = assignments.containsKey(stat) ? assignment : 0;
    }

    final levelBonuses = <String, int>{
      for (final stat in CharacteristicUtils.characteristicOrder) stat: 0,
    };

    for (final entry in adjustmentEntries) {
      if (entry.target == 'all') {
        for (final stat in CharacteristicUtils.characteristicOrder) {
          _applyAdjustmentToStat(stat, entry.payload, totals, levelBonuses);
        }
      } else if (entry.target == 'any') {
        final choiceId = entry.choiceId;
        if (choiceId == null) continue;
        final chosenStat = levelChoiceSelections[choiceId];
        if (chosenStat != null) {
          _applyAdjustmentToStat(
            chosenStat,
            entry.payload,
            totals,
            levelBonuses,
          );
        }
      } else if (CharacteristicUtils.characteristicOrder
          .contains(entry.target)) {
        _applyAdjustmentToStat(entry.target, entry.payload, totals, levelBonuses);
      }
    }

    return CharacteristicSummary(
      totals: totals,
      fixed: Map<String, int>.from(fixedValues),
      array: arrayContrib,
      levelBonuses: levelBonuses,
    );
  }

  /// Computes potency values for weak/average/strong bands.
  Map<String, int> computePotency({
    required ClassData classData,
    required Map<String, int> totals,
  }) {
    final progression = classData.startingCharacteristics.potencyProgression;
    final baseKey = CharacteristicUtils.normalizeKey(progression.characteristic) ??
        progression.characteristic.toLowerCase();
    final baseScore = totals[baseKey] ?? 0;
    final result = <String, int>{};
    progression.modifiers.forEach((strength, modifier) {
      result[strength.toLowerCase()] = baseScore + modifier;
    });
    return result;
  }

  static String buildChoiceId(int level, int index) => 'L${level}_$index';

  static void _applyAdjustmentToStat(
    String stat,
    AdjustmentPayload payload,
    Map<String, int> totals,
    Map<String, int> bonuses,
  ) {
    final before = totals[stat] ?? 0;
    final after = _applyPayload(before, payload);
    totals[stat] = after;
    final delta = after - before;
    if (delta != 0) {
      bonuses[stat] = (bonuses[stat] ?? 0) + delta;
    }
  }

  static int _applyPayload(int current, AdjustmentPayload payload) {
    var value = current;
    final increase = payload.increaseBy;
    if (increase != null) {
      value += increase;
    }
    final setTo = payload.setTo;
    if (setTo != null && value < setTo) {
      value = setTo;
    }
    final maxValue = payload.max;
    if (maxValue != null && value > maxValue) {
      value = maxValue;
    }
    return value;
  }
}
