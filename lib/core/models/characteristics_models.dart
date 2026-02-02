import 'package:collection/collection.dart';

/// Shared constants and value objects for starting characteristic workflows.
class CharacteristicUtils {
  CharacteristicUtils._();

  static const List<String> characteristicOrder = [
    'might',
    'agility',
    'reason',
    'intuition',
    'presence',
  ];

  static const Map<String, String> characteristicAliases = {
    'might': 'might',
    'm': 'might',
    'agility': 'agility',
    'a': 'agility',
    'reason': 'reason',
    'r': 'reason',
    'intuition': 'intuition',
    'intuitition': 'intuition',
    'i': 'intuition',
    'presence': 'presence',
    'p': 'presence',
    'all': 'all',
    'any': 'any',
  };

  static const MapEquality<String, int> intMapEquality =
      MapEquality<String, int>();

  static String? normalizeKey(String? key) {
    if (key == null) return null;
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return characteristicAliases[normalized] ?? normalized;
  }

  static String displayName(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  static String formatSigned(int value) => value >= 0 ? '+$value' : '$value';

  static int? toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class CharacteristicValueToken {
  const CharacteristicValueToken({
    required this.id,
    required this.value,
  });

  final int id;
  final int value;
}

class AdjustmentPayload {
  const AdjustmentPayload({
    this.increaseBy,
    this.setTo,
    this.max,
  });

  final int? increaseBy;
  final int? setTo;
  final int? max;
}

class AdjustmentEntry {
  const AdjustmentEntry({
    required this.level,
    required this.target,
    required this.payload,
    this.choiceId,
  });

  final int level;
  final String target;
  final AdjustmentPayload payload;
  final String? choiceId;
}

class LevelChoice {
  const LevelChoice({
    required this.id,
    required this.level,
    required this.payload,
  });

  final String id;
  final int level;
  final AdjustmentPayload payload;
}

class CharacteristicSummary {
  const CharacteristicSummary({
    required this.totals,
    required this.fixed,
    required this.array,
    required this.levelBonuses,
  });

  final Map<String, int> totals;
  final Map<String, int> fixed;
  final Map<String, int> array;
  final Map<String, int> levelBonuses;
}
