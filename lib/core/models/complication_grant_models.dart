import 'dart:convert';

/// Represents the different types of grants that complications can provide.
enum ComplicationGrantType {
  skill,
  skillFromGroup,
  skillFromOptions,
  ability,
  treasure,
  treasureLeveled,
  token,
  language,
  languageDead,
  increaseTotal,
  increaseTotalPerEchelon,
  decreaseTotal,
  setBaseStatIfNotAlreadyLower,
  ancestryTraits,
  pickOne,
  increaseRecovery,
  feature,
}

/// Base class for complication grants.
sealed class ComplicationGrant {
  const ComplicationGrant({
    required this.sourceComplicationId,
    required this.sourceComplicationName,
  });

  final String sourceComplicationId;
  final String sourceComplicationName;

  ComplicationGrantType get type;

  Map<String, dynamic> toJson();

  factory ComplicationGrant.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = ComplicationGrantType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => throw FormatException('Unknown grant type: $typeStr'),
    );

    return switch (type) {
      ComplicationGrantType.skill => SkillGrant.fromJson(json),
      ComplicationGrantType.skillFromGroup => SkillFromGroupGrant.fromJson(json),
      ComplicationGrantType.skillFromOptions =>
        SkillFromOptionsGrant.fromJson(json),
      ComplicationGrantType.ability => AbilityGrant.fromJson(json),
      ComplicationGrantType.treasure => TreasureGrant.fromJson(json),
      ComplicationGrantType.treasureLeveled => LeveledTreasureGrant.fromJson(json),
      ComplicationGrantType.token => TokenGrant.fromJson(json),
      ComplicationGrantType.language => LanguageGrant.fromJson(json),
      ComplicationGrantType.languageDead => DeadLanguageGrant.fromJson(json),
      ComplicationGrantType.increaseTotal => IncreaseTotalGrant.fromJson(json),
      ComplicationGrantType.increaseTotalPerEchelon =>
        IncreaseTotalPerEchelonGrant.fromJson(json),
      ComplicationGrantType.decreaseTotal => DecreaseTotalGrant.fromJson(json),
      ComplicationGrantType.setBaseStatIfNotAlreadyLower =>
        SetBaseStatIfNotLowerGrant.fromJson(json),
      ComplicationGrantType.ancestryTraits => AncestryTraitsGrant.fromJson(json),
      ComplicationGrantType.pickOne => PickOneGrant.fromJson(json),
      ComplicationGrantType.increaseRecovery => IncreaseRecoveryGrant.fromJson(json),
      ComplicationGrantType.feature => FeatureGrant.fromJson(json),
    };
  }

  /// Parse all grants from a complication's grant data.
  static List<ComplicationGrant> parseFromGrantsData(
    Map<String, dynamic> grantsData,
    String complicationId,
    String complicationName, [
    Map<String, String> choices = const {},
  ]) {
    final grants = <ComplicationGrant>[];

    // Skills - can be various formats
    if (grantsData['skills'] != null) {
      grants.addAll(_parseSkillGrants(
        grantsData['skills'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    // Abilities
    if (grantsData['abilities'] != null) {
      grants.addAll(_parseAbilityGrants(
        grantsData['abilities'],
        complicationId,
        complicationName,
      ));
    }

    // Treasures
    if (grantsData['treasures'] != null) {
      grants.addAll(_parseTreasureGrants(
        grantsData['treasures'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    // Tokens
    if (grantsData['tokens'] != null) {
      grants.addAll(_parseTokenGrants(
        grantsData['tokens'],
        complicationId,
        complicationName,
      ));
    }

    // Languages - can be int, object, or list
    if (grantsData['languages'] != null) {
      grants.addAll(_parseLanguageGrants(
        grantsData['languages'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    // increase_total - single or list
    if (grantsData['increase_total'] != null) {
      grants.addAll(_parseIncreaseTotalGrants(
        grantsData['increase_total'],
        complicationId,
        complicationName,
      ));
    }

    // decrease_total - single or list
    if (grantsData['decrease_total'] != null) {
      grants.addAll(_parseDecreaseTotalGrants(
        grantsData['decrease_total'],
        complicationId,
        complicationName,
      ));
    }

    // set_base_stat_if_not_already_lower
    if (grantsData['set_base_stat_if_not_already_lower'] != null) {
      final data = grantsData['set_base_stat_if_not_already_lower'];
      if (data is Map) {
        grants.add(SetBaseStatIfNotLowerGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          stat: (data['stat'] as String?) ?? '',
          value: (data['value'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    // ancestry_traits
    if (grantsData['ancestry_traits'] != null) {
      final data = grantsData['ancestry_traits'];
      if (data is Map) {
        grants.add(AncestryTraitsGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          ancestry: (data['ancestry'] as String?) ?? '',
          ancestryPoints: (data['ancestry_points'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    // pick_one - requires user choice
    if (grantsData['pick_one'] != null) {
      final data = grantsData['pick_one'];
      if (data is List) {
        final options = <Map<String, dynamic>>[];
        for (final item in data) {
          if (item is Map) {
            options.add(item.cast<String, dynamic>());
          }
        }
        final selectedIndex = _parseSelectedPickOneIndex(choices, complicationId);
        grants.add(PickOneGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          options: options,
          selectedIndex: selectedIndex,
        ));

        // If an option is selected, parse its grants and add them
        if (selectedIndex != null && selectedIndex >= 0 && selectedIndex < options.length) {
          final selectedOption = options[selectedIndex];
          // Parse grants from the selected option
          grants.addAll(_parseSelectedPickOneGrants(
            selectedOption,
            complicationId,
            complicationName,
            choices,
          ));
        }
      }
    }

    // increase_recovery
    if (grantsData['increase_recovery'] != null) {
      final data = grantsData['increase_recovery'];
      if (data is Map) {
        grants.add(IncreaseRecoveryGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          value: (data['value'] as String?) ?? '',
        ));
      }
    }

    // features - mounts, retainers, etc.
    if (grantsData['features'] != null) {
      grants.addAll(_parseFeatureGrants(
        grantsData['features'],
        complicationId,
        complicationName,
      ));
    }

    return grants;
  }

  static int? _parseSelectedPickOneIndex(
      Map<String, String> choices, String complicationId) {
    final key = '${complicationId}_pick_one';
    final value = choices[key];
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Parses the grants from a selected pick_one option.
  /// The option is a map that may contain grant keys like 'increase_total', 'skill', etc.
  static List<ComplicationGrant> _parseSelectedPickOneGrants(
    Map<String, dynamic> option,
    String complicationId,
    String complicationName,
    Map<String, String> choices,
  ) {
    final grants = <ComplicationGrant>[];

    // Handle increase_total
    if (option['increase_total'] != null) {
      grants.addAll(_parseIncreaseTotalGrants(
        option['increase_total'],
        complicationId,
        complicationName,
      ));
    }

    // Handle decrease_total
    if (option['decrease_total'] != null) {
      grants.addAll(_parseDecreaseTotalGrants(
        option['decrease_total'],
        complicationId,
        complicationName,
      ));
    }

    // Handle skill grants
    if (option['skill'] != null || option['skills'] != null) {
      grants.addAll(_parseSkillGrants(
        option['skill'] ?? option['skills'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    // Handle ability grants
    if (option['ability'] != null || option['abilities'] != null) {
      grants.addAll(_parseAbilityGrants(
        option['ability'] ?? option['abilities'],
        complicationId,
        complicationName,
      ));
    }

    // Handle token grants
    if (option['tokens'] != null) {
      grants.addAll(_parseTokenGrants(
        option['tokens'],
        complicationId,
        complicationName,
      ));
    }

    // Handle treasure grants
    if (option['treasure'] != null || option['treasures'] != null) {
      grants.addAll(_parseTreasureGrants(
        option['treasure'] ?? option['treasures'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    // Handle language grants
    if (option['language'] != null || option['languages'] != null) {
      grants.addAll(_parseLanguageGrants(
        option['language'] ?? option['languages'],
        complicationId,
        complicationName,
        choices,
      ));
    }

    return grants;
  }

  static List<ComplicationGrant> _parseSkillGrants(
    dynamic skillsData,
    String complicationId,
    String complicationName,
    Map<String, String> choices,
  ) {
    final grants = <ComplicationGrant>[];

    if (skillsData is List) {
      for (final skill in skillsData) {
        if (skill is Map) {
          // Skill by name
          if (skill['name'] != null) {
            grants.add(SkillGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              skillName: skill['name'].toString(),
            ));
          }
          // Skill from group
          else if (skill['group'] != null) {
            final group = skill['group'];
            final count = (skill['count'] as num?)?.toInt() ?? 1;
            final groupList = group is List
                ? group.map((e) => e.toString()).toList()
                : [group.toString()];

            grants.add(SkillFromGroupGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              groups: groupList,
              count: count,
              selectedSkillIds: _parseSelectedSkillIds(choices, complicationId, count),
            ));
          }
          // Skill from options
          else if (skill['options'] != null) {
            final options = (skill['options'] as List)
                .map((e) => e.toString())
                .toList();
            grants.add(SkillFromOptionsGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              options: options,
              selectedSkillId: choices['${complicationId}_skill_option'],
            ));
          }
        }
      }
    } else if (skillsData is Map) {
      // Single skill object (e.g., { "group": "any", "count": 2 })
      if (skillsData['group'] != null) {
        final group = skillsData['group'];
        final count = (skillsData['count'] as num?)?.toInt() ?? 1;
        final groupList = group is List
            ? group.map((e) => e.toString()).toList()
            : [group.toString()];

        grants.add(SkillFromGroupGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          groups: groupList,
          count: count,
          selectedSkillIds: _parseSelectedSkillIds(choices, complicationId, count),
        ));
      } else if (skillsData['name'] != null) {
        grants.add(SkillGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          skillName: skillsData['name'].toString(),
        ));
      }
    }

    return grants;
  }

  static List<String> _parseSelectedSkillIds(
      Map<String, String> choices, String complicationId, int count) {
    final result = <String>[];
    for (var i = 0; i < count; i++) {
      final key = '${complicationId}_skill_$i';
      final value = choices[key];
      if (value != null && value.isNotEmpty) {
        result.add(value);
      }
    }
    return result;
  }

  static List<ComplicationGrant> _parseAbilityGrants(
    dynamic abilitiesData,
    String complicationId,
    String complicationName,
  ) {
    final grants = <ComplicationGrant>[];

    if (abilitiesData is List) {
      for (final ability in abilitiesData) {
        if (ability is Map) {
          grants.add(AbilityGrant(
            sourceComplicationId: complicationId,
            sourceComplicationName: complicationName,
            abilityName: (ability['name'] as String?) ?? '',
            source: ability['source']?.toString(),
          ));
        } else if (ability is String) {
          grants.add(AbilityGrant(
            sourceComplicationId: complicationId,
            sourceComplicationName: complicationName,
            abilityName: ability,
            source: null,
          ));
        }
      }
    } else if (abilitiesData is Map) {
      // Single ability object (e.g., { "name": "Rogue Wave" })
      grants.add(AbilityGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        abilityName: (abilitiesData['name'] as String?) ?? '',
        source: abilitiesData['source']?.toString(),
      ));
    } else if (abilitiesData is String) {
      // Single ability name string
      grants.add(AbilityGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        abilityName: abilitiesData,
        source: null,
      ));
    }

    return grants;
  }

  static List<ComplicationGrant> _parseTreasureGrants(
    dynamic treasuresData,
    String complicationId,
    String complicationName,
    Map<String, String> choices,
  ) {
    final grants = <ComplicationGrant>[];

    if (treasuresData is List) {
      for (var i = 0; i < treasuresData.length; i++) {
        final treasure = treasuresData[i];
        if (treasure is Map) {
          final type = (treasure['type'] as String?) ?? 'treasure';
          final echelon = (treasure['echelon'] as num?)?.toInt();
          // Default to requiring choice - user must pick a specific treasure
          final requiresChoice = treasure['choice'] != false;
          final selectedId = choices['${complicationId}_treasure_$i'];

          if (type == 'leveled' || type.startsWith('leveled_')) {
            // Leveled treasure (weapon, armor, etc.)
            // Extract category from type (e.g., "leveled_weapon" -> "weapon")
            // or from explicit category field
            String? category = treasure['category']?.toString();
            if (category == null && type.startsWith('leveled_')) {
              category = type.substring('leveled_'.length);
            }
            grants.add(LeveledTreasureGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              category: category,
              selectedTreasureId: selectedId,
            ));
          } else {
            grants.add(TreasureGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              treasureType: type,
              echelon: echelon,
              requiresChoice: requiresChoice,
              selectedTreasureId: selectedId,
            ));
          }
        }
      }
    } else if (treasuresData is Map) {
      // Single treasure object
      final type = (treasuresData['type'] as String?) ?? 'treasure';
      final selectedId = choices['${complicationId}_treasure_0'];

      if (type == 'leveled' || type.startsWith('leveled_')) {
        // Extract category from type or explicit field
        String? category = treasuresData['category']?.toString();
        if (category == null && type.startsWith('leveled_')) {
          category = type.substring('leveled_'.length);
        }
        grants.add(LeveledTreasureGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          category: category,
          selectedTreasureId: selectedId,
        ));
      } else {
        final echelon = (treasuresData['echelon'] as num?)?.toInt();
        grants.add(TreasureGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          treasureType: type,
          echelon: echelon,
          requiresChoice: true,
          selectedTreasureId: selectedId,
        ));
      }
    }

    return grants;
  }

  static List<ComplicationGrant> _parseTokenGrants(
    dynamic tokensData,
    String complicationId,
    String complicationName,
  ) {
    final grants = <ComplicationGrant>[];

    if (tokensData is Map) {
      // Format: { "name": "antihero", "count": 3 }
      final name = tokensData['name']?.toString();
      final count = (tokensData['count'] as num?)?.toInt() ?? 0;
      if (name != null && name.isNotEmpty && count > 0) {
        grants.add(TokenGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          tokenType: name,
          count: count,
        ));
      } else {
        // Fallback: old format { "tokenType": count }
        tokensData.forEach((key, value) {
          if (key == 'name' || key == 'count') return;
          final c = (value is num) ? value.toInt() : (int.tryParse(value.toString()) ?? 0);
          grants.add(TokenGrant(
            sourceComplicationId: complicationId,
            sourceComplicationName: complicationName,
            tokenType: key.toString(),
            count: c,
          ));
        });
      }
    } else if (tokensData is List) {
      // Format: [{ "name": "antihero", "count": 3 }]
      for (final token in tokensData) {
        if (token is Map) {
          final name = token['name']?.toString();
          final count = (token['count'] as num?)?.toInt() ?? 0;
          if (name != null && name.isNotEmpty && count > 0) {
            grants.add(TokenGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              tokenType: name,
              count: count,
            ));
          }
        }
      }
    }

    return grants;
  }

  static List<ComplicationGrant> _parseLanguageGrants(
    dynamic languagesData,
    String complicationId,
    String complicationName,
    Map<String, String> choices,
  ) {
    final grants = <ComplicationGrant>[];

    if (languagesData is int) {
      // Simple count
      grants.add(LanguageGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        count: languagesData,
        selectedLanguageIds: _parseSelectedLanguageIds(choices, complicationId, languagesData),
      ));
    } else if (languagesData is Map) {
      // Object format: { "count": 1 } or { "type": "dead", "count": 1 }
      final count = (languagesData['count'] as num?)?.toInt() ?? 1;
      final type = languagesData['type']?.toString();

      if (type == 'dead') {
        grants.add(DeadLanguageGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          count: count,
          selectedLanguageIds:
              _parseSelectedDeadLanguageIds(choices, complicationId, count),
        ));
      } else {
        grants.add(LanguageGrant(
          sourceComplicationId: complicationId,
          sourceComplicationName: complicationName,
          count: count,
          selectedLanguageIds: _parseSelectedLanguageIds(choices, complicationId, count),
        ));
      }
    } else if (languagesData is List) {
      // List format: [{ "type": "dead", "count": 1 }]
      for (final lang in languagesData) {
        if (lang is Map) {
          final count = (lang['count'] as num?)?.toInt() ?? 1;
          final type = lang['type']?.toString();

          if (type == 'dead') {
            grants.add(DeadLanguageGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              count: count,
              selectedLanguageIds:
                  _parseSelectedDeadLanguageIds(choices, complicationId, count),
            ));
          } else {
            grants.add(LanguageGrant(
              sourceComplicationId: complicationId,
              sourceComplicationName: complicationName,
              count: count,
              selectedLanguageIds:
                  _parseSelectedLanguageIds(choices, complicationId, count),
            ));
          }
        }
      }
    }

    return grants;
  }

  static List<String> _parseSelectedLanguageIds(
      Map<String, String> choices, String complicationId, int count) {
    final result = <String>[];
    for (var i = 0; i < count; i++) {
      final key = '${complicationId}_language_$i';
      final value = choices[key];
      if (value != null && value.isNotEmpty) {
        result.add(value);
      }
    }
    return result;
  }

  static List<String> _parseSelectedDeadLanguageIds(
      Map<String, String> choices, String complicationId, int count) {
    final result = <String>[];
    for (var i = 0; i < count; i++) {
      final key = '${complicationId}_dead_language_$i';
      final value = choices[key];
      if (value != null && value.isNotEmpty) {
        result.add(value);
      }
    }
    return result;
  }

  static List<ComplicationGrant> _parseIncreaseTotalGrants(
    dynamic data,
    String complicationId,
    String complicationName,
  ) {
    final grants = <ComplicationGrant>[];

    if (data is Map) {
      grants.add(_createIncreaseTotalGrant(
        data.cast<String, dynamic>(),
        complicationId,
        complicationName,
      ));
    } else if (data is List) {
      for (final item in data) {
        if (item is Map) {
          grants.add(_createIncreaseTotalGrant(
            item.cast<String, dynamic>(),
            complicationId,
            complicationName,
          ));
        }
      }
    }

    return grants;
  }

  static ComplicationGrant _createIncreaseTotalGrant(
    Map<String, dynamic> data,
    String complicationId,
    String complicationName,
  ) {
    final stat = (data['stat'] as String?) ?? '';
    final rawValue = data['value'];
    final damageType = data['type']?.toString();
    final perEchelon = data['per_echelon'] == true;

    // Handle dynamic values like "level"
    int value = 0;
    String? dynamicValue;
    if (rawValue is num) {
      value = rawValue.toInt();
    } else if (rawValue is String) {
      // Check if it's a dynamic value like "level"
      final parsed = int.tryParse(rawValue);
      if (parsed != null) {
        value = parsed;
      } else {
        dynamicValue = rawValue; // e.g., "level"
      }
    }

    if (perEchelon) {
      return IncreaseTotalPerEchelonGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        stat: stat,
        valuePerEchelon: value,
        damageType: damageType,
      );
    }

    return IncreaseTotalGrant(
      sourceComplicationId: complicationId,
      sourceComplicationName: complicationName,
      stat: stat,
      value: value,
      dynamicValue: dynamicValue,
      damageType: damageType,
    );
  }

  static List<ComplicationGrant> _parseDecreaseTotalGrants(
    dynamic data,
    String complicationId,
    String complicationName,
  ) {
    final grants = <ComplicationGrant>[];

    if (data is Map) {
      grants.add(DecreaseTotalGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        stat: (data['stat'] as String?) ?? '',
        value: (data['value'] as num?)?.toInt() ?? 0,
      ));
    } else if (data is List) {
      for (final item in data) {
        if (item is Map) {
          grants.add(DecreaseTotalGrant(
            sourceComplicationId: complicationId,
            sourceComplicationName: complicationName,
            stat: (item['stat'] as String?) ?? '',
            value: (item['value'] as num?)?.toInt() ?? 0,
          ));
        }
      }
    }

    return grants;
  }

  static List<ComplicationGrant> _parseFeatureGrants(
    dynamic data,
    String complicationId,
    String complicationName,
  ) {
    final grants = <ComplicationGrant>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          grants.add(FeatureGrant(
            sourceComplicationId: complicationId,
            sourceComplicationName: complicationName,
            featureName: (item['name'] as String?) ?? '',
            featureType: (item['type'] as String?) ?? 'feature',
          ));
        }
      }
    } else if (data is Map) {
      grants.add(FeatureGrant(
        sourceComplicationId: complicationId,
        sourceComplicationName: complicationName,
        featureName: (data['name'] as String?) ?? '',
        featureType: (data['type'] as String?) ?? 'feature',
      ));
    }

    return grants;
  }
}

// ============================================================================
// Grant implementations
// ============================================================================

/// Grants a specific skill by name.
class SkillGrant extends ComplicationGrant {
  const SkillGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.skillName,
  });

  final String skillName;

  @override
  ComplicationGrantType get type => ComplicationGrantType.skill;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'skillName': skillName,
      };

  factory SkillGrant.fromJson(Map<String, dynamic> json) => SkillGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        skillName: json['skillName'] as String,
      );
}

/// Grants a skill chosen from a group (lore, intrigue, interpersonal, any, etc.).
class SkillFromGroupGrant extends ComplicationGrant {
  const SkillFromGroupGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.groups,
    required this.count,
    this.selectedSkillIds = const [],
  });

  final List<String> groups;
  final int count;
  final List<String> selectedSkillIds;

  @override
  ComplicationGrantType get type => ComplicationGrantType.skillFromGroup;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'groups': groups,
        'count': count,
        'selectedSkillIds': selectedSkillIds,
      };

  factory SkillFromGroupGrant.fromJson(Map<String, dynamic> json) =>
      SkillFromGroupGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        groups: (json['groups'] as List).map((e) => e.toString()).toList(),
        count: json['count'] as int,
        selectedSkillIds: (json['selectedSkillIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Grants a skill chosen from specific options.
class SkillFromOptionsGrant extends ComplicationGrant {
  const SkillFromOptionsGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.options,
    this.selectedSkillId,
  });

  final List<String> options;
  final String? selectedSkillId;

  @override
  ComplicationGrantType get type => ComplicationGrantType.skillFromOptions;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'options': options,
        'selectedSkillId': selectedSkillId,
      };

  factory SkillFromOptionsGrant.fromJson(Map<String, dynamic> json) =>
      SkillFromOptionsGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        options: (json['options'] as List).map((e) => e.toString()).toList(),
        selectedSkillId: json['selectedSkillId'] as String?,
      );
}

/// Grants an ability by name.
class AbilityGrant extends ComplicationGrant {
  const AbilityGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.abilityName,
    this.source,
  });

  final String abilityName;
  final String? source; // e.g., "maneuver"

  @override
  ComplicationGrantType get type => ComplicationGrantType.ability;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'abilityName': abilityName,
        'source': source,
      };

  factory AbilityGrant.fromJson(Map<String, dynamic> json) => AbilityGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        abilityName: json['abilityName'] as String,
        source: json['source'] as String?,
      );
}

/// Grants a treasure (trinket, artifact, etc.).
class TreasureGrant extends ComplicationGrant {
  const TreasureGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.treasureType,
    this.echelon,
    this.requiresChoice = false,
    this.selectedTreasureId,
  });

  final String treasureType;
  final int? echelon;
  final bool requiresChoice;
  final String? selectedTreasureId;

  @override
  ComplicationGrantType get type => ComplicationGrantType.treasure;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'treasureType': treasureType,
        'echelon': echelon,
        'requiresChoice': requiresChoice,
        'selectedTreasureId': selectedTreasureId,
      };

  factory TreasureGrant.fromJson(Map<String, dynamic> json) => TreasureGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        treasureType: json['treasureType'] as String,
        echelon: json['echelon'] as int?,
        requiresChoice: json['requiresChoice'] as bool? ?? false,
        selectedTreasureId: json['selectedTreasureId'] as String?,
      );
}

/// Grants a leveled treasure (weapon, armor, etc.).
class LeveledTreasureGrant extends ComplicationGrant {
  const LeveledTreasureGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    this.category, // e.g., "weapon", "armor" - null means any leveled treasure
    this.selectedTreasureId,
  });

  final String? category;
  final String? selectedTreasureId;

  @override
  ComplicationGrantType get type => ComplicationGrantType.treasureLeveled;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'category': category,
        'selectedTreasureId': selectedTreasureId,
      };

  factory LeveledTreasureGrant.fromJson(Map<String, dynamic> json) =>
      LeveledTreasureGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        category: json['category'] as String?,
        selectedTreasureId: json['selectedTreasureId'] as String?,
      );
}

/// Grants tokens (antihero, destiny, etc.).
class TokenGrant extends ComplicationGrant {
  const TokenGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.tokenType,
    required this.count,
  });

  final String tokenType;
  final int count;

  @override
  ComplicationGrantType get type => ComplicationGrantType.token;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'tokenType': tokenType,
        'count': count,
      };

  factory TokenGrant.fromJson(Map<String, dynamic> json) => TokenGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        tokenType: json['tokenType'] as String,
        count: json['count'] as int,
      );
}

/// Grants a language choice.
class LanguageGrant extends ComplicationGrant {
  const LanguageGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.count,
    this.selectedLanguageIds = const [],
  });

  final int count;
  final List<String> selectedLanguageIds;

  @override
  ComplicationGrantType get type => ComplicationGrantType.language;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'count': count,
        'selectedLanguageIds': selectedLanguageIds,
      };

  factory LanguageGrant.fromJson(Map<String, dynamic> json) => LanguageGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        count: json['count'] as int,
        selectedLanguageIds: (json['selectedLanguageIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Grants a dead language choice.
class DeadLanguageGrant extends ComplicationGrant {
  const DeadLanguageGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.count,
    this.selectedLanguageIds = const [],
  });

  final int count;
  final List<String> selectedLanguageIds;

  @override
  ComplicationGrantType get type => ComplicationGrantType.languageDead;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'count': count,
        'selectedLanguageIds': selectedLanguageIds,
      };

  factory DeadLanguageGrant.fromJson(Map<String, dynamic> json) =>
      DeadLanguageGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        count: json['count'] as int,
        selectedLanguageIds: (json['selectedLanguageIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Increases a total stat (stamina, renown, wealth, immunity, weakness, stability, etc.).
class IncreaseTotalGrant extends ComplicationGrant {
  const IncreaseTotalGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.stat,
    this.value = 0,
    this.dynamicValue,
    this.damageType,
  });

  final String stat;
  final int value;
  final String? dynamicValue; // For values like "level" that scale
  final String? damageType; // For immunity/weakness

  /// Get the actual value, potentially based on hero level
  int getActualValue(int heroLevel) {
    if (dynamicValue == 'level') {
      return heroLevel;
    }
    return value;
  }

  @override
  ComplicationGrantType get type => ComplicationGrantType.increaseTotal;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'stat': stat,
        'value': value,
        'dynamicValue': dynamicValue,
        'damageType': damageType,
      };

  factory IncreaseTotalGrant.fromJson(Map<String, dynamic> json) =>
      IncreaseTotalGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        stat: json['stat'] as String,
        value: (json['value'] as num?)?.toInt() ?? 0,
        dynamicValue: json['dynamicValue'] as String?,
        damageType: json['damageType'] as String?,
      );
}

/// Increases a total stat per echelon (e.g., stamina +3 per echelon).
class IncreaseTotalPerEchelonGrant extends ComplicationGrant {
  const IncreaseTotalPerEchelonGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.stat,
    required this.valuePerEchelon,
    this.damageType,
  });

  final String stat;
  final int valuePerEchelon;
  final String? damageType;

  @override
  ComplicationGrantType get type =>
      ComplicationGrantType.increaseTotalPerEchelon;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'stat': stat,
        'valuePerEchelon': valuePerEchelon,
        'damageType': damageType,
      };

  factory IncreaseTotalPerEchelonGrant.fromJson(Map<String, dynamic> json) =>
      IncreaseTotalPerEchelonGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        stat: json['stat'] as String,
        valuePerEchelon: json['valuePerEchelon'] as int,
        damageType: json['damageType'] as String?,
      );
}

/// Decreases a total stat (e.g., speed -1).
class DecreaseTotalGrant extends ComplicationGrant {
  const DecreaseTotalGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.stat,
    required this.value,
  });

  final String stat;
  final int value;

  @override
  ComplicationGrantType get type => ComplicationGrantType.decreaseTotal;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'stat': stat,
        'value': value,
      };

  factory DecreaseTotalGrant.fromJson(Map<String, dynamic> json) =>
      DecreaseTotalGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        stat: json['stat'] as String,
        value: json['value'] as int,
      );
}

/// Sets base stat if not already lower (e.g., Wealth to -5).
class SetBaseStatIfNotLowerGrant extends ComplicationGrant {
  const SetBaseStatIfNotLowerGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.stat,
    required this.value,
  });

  final String stat;
  final int value;

  @override
  ComplicationGrantType get type =>
      ComplicationGrantType.setBaseStatIfNotAlreadyLower;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'stat': stat,
        'value': value,
      };

  factory SetBaseStatIfNotLowerGrant.fromJson(Map<String, dynamic> json) =>
      SetBaseStatIfNotLowerGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        stat: json['stat'] as String,
        value: json['value'] as int,
      );
}

/// Grants ancestry traits (e.g., 2 dragon knight traits).
class AncestryTraitsGrant extends ComplicationGrant {
  const AncestryTraitsGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.ancestry,
    required this.ancestryPoints,
  });

  final String ancestry;
  final int ancestryPoints;

  @override
  ComplicationGrantType get type => ComplicationGrantType.ancestryTraits;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'ancestry': ancestry,
        'ancestryPoints': ancestryPoints,
      };

  factory AncestryTraitsGrant.fromJson(Map<String, dynamic> json) =>
      AncestryTraitsGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        ancestry: json['ancestry'] as String,
        ancestryPoints: json['ancestryPoints'] as int,
      );
}

/// Requires choosing one option from a list of grants.
class PickOneGrant extends ComplicationGrant {
  const PickOneGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.options,
    this.selectedIndex,
  });

  final List<Map<String, dynamic>> options;
  final int? selectedIndex;

  @override
  ComplicationGrantType get type => ComplicationGrantType.pickOne;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'options': options,
        'selectedIndex': selectedIndex,
      };

  factory PickOneGrant.fromJson(Map<String, dynamic> json) => PickOneGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        options: (json['options'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        selectedIndex: json['selectedIndex'] as int?,
      );

  /// Get a human-readable description of an option.
  String getOptionDescription(int index) {
    if (index < 0 || index >= options.length) return 'Unknown';
    final option = options[index];

    // Most pick_one options contain increase_total
    final increaseTotal = option['increase_total'];
    if (increaseTotal is Map) {
      final stat = increaseTotal['stat']?.toString() ?? '';
      final value = increaseTotal['value'] ?? 0;
      return '+$value ${stat.replaceAll('_', ' ')}';
    }

    return 'Option ${index + 1}';
  }
}

/// Increases recovery value (e.g., by highest characteristic).
class IncreaseRecoveryGrant extends ComplicationGrant {
  const IncreaseRecoveryGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.value,
  });

  final String value; // Can be "highest_characteristic" or a number

  @override
  ComplicationGrantType get type => ComplicationGrantType.increaseRecovery;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'value': value,
      };

  factory IncreaseRecoveryGrant.fromJson(Map<String, dynamic> json) =>
      IncreaseRecoveryGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        value: json['value'] as String,
      );
}

/// Grants a feature (mount, retainer, etc.) from a complication.
class FeatureGrant extends ComplicationGrant {
  const FeatureGrant({
    required super.sourceComplicationId,
    required super.sourceComplicationName,
    required this.featureName,
    required this.featureType,
  });

  final String featureName;
  final String featureType;

  @override
  ComplicationGrantType get type => ComplicationGrantType.feature;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceComplicationId': sourceComplicationId,
        'sourceComplicationName': sourceComplicationName,
        'featureName': featureName,
        'featureType': featureType,
      };

  factory FeatureGrant.fromJson(Map<String, dynamic> json) =>
      FeatureGrant(
        sourceComplicationId: json['sourceComplicationId'] as String,
        sourceComplicationName: json['sourceComplicationName'] as String,
        featureName: json['featureName'] as String,
        featureType: json['featureType'] as String,
      );
}

// ============================================================================
// Applied grants container
// ============================================================================

/// Container for all applied complication grants for a hero.
class AppliedComplicationGrants {
  const AppliedComplicationGrants({
    required this.complicationId,
    required this.complicationName,
    required this.grants,
  });

  final String complicationId;
  final String complicationName;
  final List<ComplicationGrant> grants;

  static const empty = AppliedComplicationGrants(
    complicationId: '',
    complicationName: '',
    grants: [],
  );

  Map<String, dynamic> toJson() => {
        'complicationId': complicationId,
        'complicationName': complicationName,
        'grants': grants.map((g) => g.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory AppliedComplicationGrants.fromJson(Map<String, dynamic> json) {
    final grantsJson = json['grants'] as List? ?? [];
    return AppliedComplicationGrants(
      complicationId: json['complicationId'] as String? ?? '',
      complicationName: json['complicationName'] as String? ?? '',
      grants: grantsJson
          .map((g) => ComplicationGrant.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AppliedComplicationGrants.fromJsonString(String jsonStr) {
    return AppliedComplicationGrants.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}
