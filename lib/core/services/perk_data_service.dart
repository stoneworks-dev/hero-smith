import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/perks_models.dart';

/// Service responsible for loading the full list of perk options from disk.
class PerkDataService {
  PerkDataService._();

  static final PerkDataService _instance = PerkDataService._();

  factory PerkDataService() => _instance;

  List<PerkOption>? _cachedOptions;

  /// Loads and caches the available perks defined in data/story/perks.json.
  Future<List<PerkOption>> loadPerks() async {
    if (_cachedOptions != null) {
      return _cachedOptions!;
    }

    final raw = await rootBundle.loadString('data/story/perks.json');
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw const FormatException('perks.json must decode to a List');
    }

    final options = decoded.whereType<Map>().map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final id = map['id']?.toString() ?? '';
      final name = map['name']?.toString() ?? '';
      final group = map['group']?.toString() ?? '';
      final description = map['description']?.toString() ?? '';
      final grantedAbilities = _extractGrantedAbilities(map['grants']);
      if (id.isEmpty || name.isEmpty) {
        throw FormatException('Invalid perk entry: $entry');
      }
      return PerkOption(
        id: id,
        name: name,
        group: group.toLowerCase(),
        description: description,
        grantedAbilities: grantedAbilities,
      );
    }).toList(growable: false);

    _cachedOptions = options;
    return options;
  }

  List<String> _extractGrantedAbilities(dynamic value) {
    if (value is! List) return const [];
    final collected = <String>[];
    for (final entry in value) {
      if (entry is Map) {
        final ability = entry['ability'];
        if (ability is String && ability.trim().isNotEmpty) {
          collected.add(ability.trim());
        }
      } else if (entry is String && entry.trim().isNotEmpty) {
        collected.add(entry.trim());
      }
    }
    if (collected.isEmpty) return const [];
    return List.unmodifiable(collected);
  }
}
