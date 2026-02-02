/// Models for class progression data loaded from JSON files
class ClassData {
  final String classId;
  final String name;
  final String type;
  final StartingCharacteristics startingCharacteristics;
  final List<LevelProgression> levels;

  ClassData({
    required this.classId,
    required this.name,
    required this.type,
    required this.startingCharacteristics,
    required this.levels,
  });

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      classId: json['classId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      startingCharacteristics: StartingCharacteristics.fromJson(
        json['starting_characteristics'] as Map<String, dynamic>,
      ),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => LevelProgression.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StartingCharacteristics {
  final String? motto;
  final String heroicResourceName;
  final int baseStamina;
  final int staminaPerLevel;
  final int baseRecoveries;
  final int baseSpeed;
  final int baseStability;
  final int baseDisengage;
  final PotencyProgression potencyProgression;
  final StartingSkills startingSkills;
  final Map<String, int> fixedStartingCharacteristics;
  final List<CharacteristicArray> startingCharacteristicsArrays;

  StartingCharacteristics({
    required this.motto,
    required this.heroicResourceName,
    required this.baseStamina,
    required this.staminaPerLevel,
    required this.baseRecoveries,
    required this.baseSpeed,
    required this.baseStability,
    required this.baseDisengage,
    required this.potencyProgression,
    required this.startingSkills,
    required this.fixedStartingCharacteristics,
    required this.startingCharacteristicsArrays,
  });

  factory StartingCharacteristics.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert map values to int
    Map<String, int> _convertToIntMap(Map<String, dynamic> map) {
      return map.map((key, value) => MapEntry(key, value as int));
    }

    return StartingCharacteristics(
      motto: json['motto'] as String?,
      heroicResourceName: json['heroicResourceName'] as String,
      baseStamina: json['baseStamina'] as int,
      staminaPerLevel: json['stamina_per_level'] as int,
      baseRecoveries: json['baseRecoveries'] as int,
      baseSpeed: json['baseSpeed'] as int,
      baseStability: json['baseStability'] as int,
      baseDisengage: json['baseDisengage'] as int,
      potencyProgression: PotencyProgression.fromJson(
        json['potency_progression'] as Map<String, dynamic>,
      ),
      startingSkills: StartingSkills.fromJson(
        json['starting_skills'] as Map<String, dynamic>,
      ),
      fixedStartingCharacteristics: _convertToIntMap(
        json['fixed_starting_characteristics'] as Map<String, dynamic>,
      ),
      startingCharacteristicsArrays: (json['starting_characteristics_arrays']
              as List<dynamic>)
          .map((e) => CharacteristicArray.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PotencyProgression {
  final String characteristic;
  final Map<String, int> modifiers;

  PotencyProgression({
    required this.characteristic,
    required this.modifiers,
  });

  factory PotencyProgression.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert map values to int
    Map<String, int> _convertToIntMap(Map<String, dynamic> map) {
      return map.map((key, value) => MapEntry(key, value as int));
    }

    return PotencyProgression(
      characteristic: json['characteristic'] as String,
      modifiers: _convertToIntMap(json['modifiers'] as Map<String, dynamic>),
    );
  }
}

class StartingSkills {
  final List<String> skillGroups;
  final int skillCount;
  final List<String> quickBuild;
  final List<String> grantedSkills;
  final Map<String, dynamic> rawData;

  StartingSkills({
    required this.skillGroups,
    required this.skillCount,
    required this.quickBuild,
    required this.grantedSkills,
    required this.rawData,
  });

  factory StartingSkills.fromJson(Map<String, dynamic> json) {
    List<String> _toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        return [value];
      }
      return const [];
    }

    final rawCopy = Map<String, dynamic>.from(json);
    return StartingSkills(
      skillGroups: _toStringList(json['skill_groups']),
      skillCount: (json['skill_count'] as num?)?.toInt() ?? 0,
      quickBuild: _toStringList(json['quick_build']),
      grantedSkills: _toStringList(json['granted_skills'] ?? json['granted']),
      rawData: rawCopy,
    );
  }
}

class CharacteristicArray {
  final List<int> values;
  final String description;

  CharacteristicArray({
    required this.values,
    this.description = '',
  });

  factory CharacteristicArray.fromJson(Map<String, dynamic> json) {
    return CharacteristicArray(
      values: (json['values'] as List<dynamic>).map((e) => e as int).toList(),
      description: (json['description'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CharacteristicArray) return false;
    if (description != other.description) return false;
    if (values.length != other.values.length) return false;
    for (var i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(description, Object.hashAll(values));
}

class LevelProgression {
  final int level;
  final List<Feature> features;
  final Map<String, dynamic>? newAbilities;
  final Map<String, dynamic>? newSubclassAbilities;
  final List<Map<String, dynamic>>? perks;
  final List<Map<String, dynamic>>? skills;
  final List<Map<String, dynamic>>? characteristics;

  LevelProgression({
    required this.level,
    required this.features,
    this.newAbilities,
    this.newSubclassAbilities,
    this.perks,
    this.skills,
    this.characteristics,
  });

  factory LevelProgression.fromJson(Map<String, dynamic> json) {
    // Helper to normalize perks/skills/characteristics that can be either object or array
    List<Map<String, dynamic>>? _normalizeToList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e as Map<String, dynamic>).toList();
      } else if (value is Map) {
        return [value as Map<String, dynamic>];
      }
      return null;
    }

    // Helper to safely get Map or null
    Map<String, dynamic>? _safeGetMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    // Helper to parse features that can be either objects or strings
    List<Feature> _parseFeatures(List<dynamic> featuresJson) {
      return featuresJson.map((e) {
        if (e is String) {
          // If it's just a string, treat it as a granted feature with just a name
          return Feature(name: e, grantType: 'granted');
        } else if (e is Map<String, dynamic>) {
          return Feature.fromJson(e);
        } else {
          throw FormatException('Invalid feature format: $e');
        }
      }).toList();
    }

    return LevelProgression(
      level: json['level'] as int,
      features: _parseFeatures(json['features'] as List<dynamic>),
      newAbilities: _safeGetMap(json['new_abilities']),
      newSubclassAbilities: _safeGetMap(json['new_subclass_abilities']),
      perks: _normalizeToList(json['perks']),
      skills: _normalizeToList(json['skills']),
      characteristics: _normalizeToList(json['characteristics']),
    );
  }
}

class Feature {
  final String name;
  final String? grantType;
  final String? type;
  final int? deity;
  final int? domain;
  final int? count;

  Feature({
    required this.name,
    this.grantType,
    this.type,
    this.deity,
    this.domain,
    this.count,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      name: json['name'] as String,
      grantType: json['grant_type'] as String?,
      type: json['type'] as String?,
      deity: json['deity'] as int?,
      domain: json['domain'] as int?,
      count: json['count'] as int?,
    );
  }
}
