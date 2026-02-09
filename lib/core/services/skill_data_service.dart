import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/skills_models.dart';

/// Service responsible for loading the full list of skill options from disk.
class SkillDataService {
  SkillDataService._();

  static final SkillDataService _instance = SkillDataService._();

  factory SkillDataService() => _instance;

  List<SkillOption>? _cachedOptions;

  /// Loads and caches the available skills defined in data/story/skills.json.
  Future<List<SkillOption>> loadSkills() async {
    if (_cachedOptions != null) {
      return _cachedOptions!;
    }

    final raw = await rootBundle.loadString('data/story/skills.json');
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw const FormatException('skills.json must decode to a List');
    }

    final options = decoded.whereType<Map>().map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final id = map['id']?.toString() ?? '';
      final name = map['name']?.toString() ?? '';
      final group = map['group']?.toString() ?? '';
      final description = map['description']?.toString() ?? '';
      if (id.isEmpty || name.isEmpty) {
        throw FormatException('Invalid skill entry: $entry');
      }
      return SkillOption(
        id: id,
        name: name,
        group: group.toLowerCase(),
        description: description,
      );
    }).toList(growable: false);

    _cachedOptions = options;
    return options;
  }
}
