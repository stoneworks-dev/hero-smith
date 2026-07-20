import 'dart:convert';

import '../db/app_database.dart' as db;
import '../models/stat_modification_model.dart';

HeroStatModifications statModificationsFromEntries(
  Iterable<db.HeroEntry> entries,
) {
  final modifications = <String, List<StatModification>>{};

  void addModification(String stat, StatModification modification) {
    final normalizedStat = stat.toLowerCase();
    if (normalizedStat.isEmpty) return;
    if (modification.baseValue == 0 && !modification.isDynamic) return;
    modifications.putIfAbsent(normalizedStat, () => <StatModification>[]);
    modifications[normalizedStat]!.add(modification);
  }

  void parseValue(String stat, dynamic value, String defaultSource) {
    if (value is List) {
      for (final item in value) {
        parseValue(stat, item, defaultSource);
      }
      return;
    }

    if (value is Map) {
      final map = _stringKeyMap(value);
      if (_looksLikeStatModification(map)) {
        addModification(
          stat,
          StatModification.fromJson(
            _normalizeModificationJson(map),
            defaultSource: defaultSource,
          ),
        );
        return;
      }

      for (final entry in map.entries) {
        parseValue(entry.key, entry.value, defaultSource);
      }
      return;
    }

    final parsed = _toInt(value);
    if (parsed == null || parsed == 0) return;
    addModification(
      stat,
      StaticStatModification(value: parsed, source: defaultSource),
    );
  }

  for (final entry in entries) {
    final payload = entry.payload;
    if (payload == null || payload.isEmpty) continue;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) continue;

      final payloadMap = _stringKeyMap(decoded);
      final modsData = payloadMap['mods'] ?? payloadMap;
      final defaultSource = '${entry.sourceType}:${entry.sourceId}';
      parseValue(entry.entryId, modsData, defaultSource);
    } catch (_) {
      continue;
    }
  }

  return modifications.isEmpty
      ? const HeroStatModifications.empty()
      : HeroStatModifications(modifications: modifications);
}

Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> value) {
  return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
}

bool _looksLikeStatModification(Map<String, dynamic> value) {
  return value.containsKey('value') ||
      value.containsKey('dynamicValue') ||
      value.containsKey('dynamic_value') ||
      value.containsKey('perEchelon') ||
      value.containsKey('per_echelon') ||
      value.containsKey('valuePerEchelon') ||
      value.containsKey('value_per_echelon');
}

Map<String, dynamic> _normalizeModificationJson(Map<String, dynamic> value) {
  final normalized = Map<String, dynamic>.from(value);
  if (normalized.containsKey('dynamic_value')) {
    normalized['dynamicValue'] = normalized['dynamic_value'];
  }
  if (normalized.containsKey('per_echelon')) {
    normalized['perEchelon'] = normalized['per_echelon'];
  }
  if (normalized.containsKey('value_per_echelon')) {
    normalized['valuePerEchelon'] = normalized['value_per_echelon'];
  }
  return normalized;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
