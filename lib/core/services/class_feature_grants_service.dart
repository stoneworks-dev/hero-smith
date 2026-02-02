import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart' as db;
import '../models/class_data.dart';
import '../models/feature.dart' as feature_model;
import '../models/subclass_models.dart';
import '../repositories/feature_repository.dart';
import '../repositories/hero_entry_repository.dart';
import 'ability_resolver_service.dart';
import 'class_feature_data_service.dart';
import 'hero_config_service.dart';
import 'hero_entry_normalizer.dart';

/// Service for applying class feature selections to a hero.
/// 
/// This service handles storing feature grants based on user selections
/// in the class feature UI. All grants are written to hero_entries with
/// source_type='class_feature' and source_id=<featureId>.
class ClassFeatureGrantsService {
  ClassFeatureGrantsService(this._db)
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _abilityResolver = AbilityResolverService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final AbilityResolverService _abilityResolver;

  /// Config key for storing feature selections.
  static const _kFeatureSelections = 'class_feature.selections';
  
  /// Config key for storing subclass key.
  static const _kSubclassKey = 'class_feature.subclass_key';
  
  /// Config key for storing skill_group skill selections.
  static const _kSkillGroupSelections = 'class_feature.skill_group_selections';

  /// Apply class feature selections to a hero.
  /// 
  /// This stores the selected features and their grants into hero_entries.
  /// Selections are stored in hero_config.
  Future<void> applyClassFeatureSelections({
    required String heroId,
    required ClassData classData,
    required int level,
    required Map<String, Set<String>> selections,
    SubclassSelectionResult? subclassSelection,
  }) async {
    final classSlug = _classSlugFromId(classData.classId);
    if (classSlug == null) return;

    // Store selections in hero_config
    await _saveFeatureSelections(heroId, selections);
    
    // Store subclass key if present
    if (subclassSelection?.subclassKey != null) {
      await _config.setConfigValue(
        heroId: heroId,
        key: _kSubclassKey,
        value: {'key': subclassSelection!.subclassKey},
      );
    }

    // Load feature details to process grants
    final featureDetails = await _loadFeatureDetails(classSlug);
    final activeSubclassSlugs =
        ClassFeatureDataService.activeSubclassSlugs(subclassSelection);
    final domainSlugs =
        ClassFeatureDataService.selectedDomainSlugs(subclassSelection);

    // Load all features for this class up to the hero's level
    final allFeatures = await FeatureRepository.loadClassFeatures(classSlug);
    final applicableFeatures = allFeatures
        .where((f) => f.level <= level)
        .where((f) {
          if (!f.isSubclassFeature) return true;
          if (activeSubclassSlugs.isEmpty) return true;
          return ClassFeatureDataService.matchesSelectedSubclass(
            f.subclassName,
            activeSubclassSlugs,
          );
        })
        .toList();

    // Remove existing class feature grants for this hero
    await _clearAllClassFeatureGrants(heroId);

    // Clear stored feature stat bonuses in hero_values (source of truth)
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'strife.feature_stat_bonuses',
      jsonMap: const {},
    );

    // Process each applicable feature
    for (final feature in applicableFeatures) {
      await _processFeatureGrants(
        heroId: heroId,
        feature: feature,
        featureDetails: featureDetails,
        selections: selections,
        activeSubclassSlugs: activeSubclassSlugs,
        domainSlugs: domainSlugs,
      );
    }

    await _applySkillGroupSelections(
      heroId: heroId,
      selections: await loadSkillGroupSelections(heroId),
      featureDetails: featureDetails,
      applicableFeatures: applicableFeatures,
      featureSelections: selections,
      activeSubclassSlugs: activeSubclassSlugs,
      domainSlugs: domainSlugs,
    );

    // Rebuild damage resistances from all hero_entries (including new grants)
    final normalizer = HeroEntryNormalizer(_db);
    await normalizer.normalize(heroId);
  }

  /// Remove all class feature grants for a hero.
  Future<void> removeClassFeatureGrants(String heroId) async {
    await _clearAllClassFeatureGrants(heroId);
    await _config.removeConfigKey(heroId, _kFeatureSelections);
    await _config.removeConfigKey(heroId, _kSubclassKey);
    await _config.removeConfigKey(heroId, _kSkillGroupSelections);
  }

  /// Remove grants for a specific feature.
  Future<void> removeFeatureGrants(String heroId, String featureId) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'class_feature',
      sourceId: featureId,
    );
  }

  /// Load current feature selections from hero_config.
  Future<Map<String, Set<String>>> loadFeatureSelections(String heroId) async {
    final config = await _config.getConfigValue(heroId, _kFeatureSelections);
    if (config == null) return const {};
    
    final result = <String, Set<String>>{};
    config.forEach((key, value) {
      final normalizedKey = key.toString().trim();
      if (normalizedKey.isEmpty) return;
      if (value is List) {
        final set = value
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
        if (set.isNotEmpty) result[normalizedKey] = set;
      } else if (value is String && value.trim().isNotEmpty) {
        result[normalizedKey] = {value.trim()};
      }
    });
    return result;
  }

  /// Load stored subclass key.
  Future<String?> loadSubclassKey(String heroId) async {
    final config = await _config.getConfigValue(heroId, _kSubclassKey);
    return config?['key']?.toString();
  }

  /// Load skill_group skill selections.
  /// Returns Map<featureId, Map<grantKey, skillId>>.
  Future<Map<String, Map<String, String>>> loadSkillGroupSelections(
    String heroId,
  ) async {
    final config = await _config.getConfigValue(heroId, _kSkillGroupSelections);
    if (config == null) return const {};
    
    final result = <String, Map<String, String>>{};
    config.forEach((featureId, grantMap) {
      if (grantMap is! Map) return;
      final innerMap = <String, String>{};
      grantMap.forEach((grantKey, skillId) {
        final keyStr = grantKey.toString().trim();
        final skillStr = skillId?.toString().trim() ?? '';
        if (keyStr.isNotEmpty && skillStr.isNotEmpty) {
          innerMap[keyStr] = skillStr;
        }
      });
      if (innerMap.isNotEmpty) {
        result[featureId.toString().trim()] = innerMap;
      }
    });
    return result;
  }

  /// Save skill_group skill selections.
  Future<void> saveSkillGroupSelections(
    String heroId,
    Map<String, Map<String, String>> selections,
  ) async {
    // Convert to JSON-serializable map
    final jsonMap = <String, dynamic>{
      for (final entry in selections.entries)
        entry.key: entry.value,
    };
    await _config.setConfigValue(
      heroId: heroId,
      key: _kSkillGroupSelections,
      value: jsonMap,
    );
  }

  /// Save a single skill_group skill selection and update hero_entries.
  /// This removes the old skill entry (if any) and adds the new one.
  Future<void> setSkillGroupSelection({
    required String heroId,
    required String featureId,
    required String grantKey,
    required String? skillId,
  }) async {
    // Load current selections
    final current = await loadSkillGroupSelections(heroId);
    // Deep copy to avoid modifying the original
    final updated = <String, Map<String, String>>{
      for (final entry in current.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    
    // Get the old skill ID (if any) to remove it from hero_entries
    final oldSkillId = updated[featureId]?[grantKey];
    
    // Update the selection
    if (skillId == null || skillId.isEmpty) {
      // Remove the selection
      if (updated.containsKey(featureId)) {
        updated[featureId]!.remove(grantKey);
        if (updated[featureId]!.isEmpty) {
          updated.remove(featureId);
        }
      }
    } else {
      // Add/update the selection
      updated.putIfAbsent(featureId, () => {});
      updated[featureId]![grantKey] = skillId;
    }
    
    // Save updated selections
    await saveSkillGroupSelections(heroId, updated);
    
    // Remove old skill entry from hero_entries if it exists
    if (oldSkillId != null && oldSkillId.isNotEmpty && oldSkillId != skillId) {
      // The source ID includes the grant key to differentiate from other grants
      final sourceId = '${featureId}_skill_group_$grantKey';
      await _entries.removeEntriesFromSource(
        heroId: heroId,
        sourceType: 'class_feature',
        sourceId: sourceId,
      );
    }
    
    // Add new skill entry to hero_entries
    if (skillId != null && skillId.isNotEmpty) {
      final sourceId = '${featureId}_skill_group_$grantKey';
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'skill',
        entryId: skillId,
        sourceType: 'class_feature',
        sourceId: sourceId,
        gainedBy: 'choice',
      );
    }
  }

  /// Get all abilities granted by class features.
  Future<List<String>> getGrantedAbilities(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'ability');
    return entries
        .where((e) => e.sourceType == 'class_feature')
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all skills granted by class features.
  Future<List<String>> getGrantedSkills(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'skill');
    return entries
        .where((e) => e.sourceType == 'class_feature')
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all features (class_feature entries) for a hero.
  Future<List<db.HeroEntry>> getClassFeatureEntries(String heroId) async {
    final entries = await _entries.listEntriesByType(heroId, 'class_feature');
    return entries.where((e) => e.sourceType == 'class_feature').toList();
  }

  // Private implementation

  Future<void> _saveFeatureSelections(
    String heroId,
    Map<String, Set<String>> selections,
  ) async {
    final jsonMap = <String, dynamic>{
      for (final entry in selections.entries)
        entry.key: entry.value.toList(),
    };
    await _config.setConfigValue(
      heroId: heroId,
      key: _kFeatureSelections,
      value: jsonMap,
    );
  }

  Future<void> _clearAllClassFeatureGrants(String heroId) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'class_feature',
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadFeatureDetails(
      String classSlug) async {
    final featureMaps = await FeatureRepository.loadClassFeatureMaps(classSlug);
    final details = <String, Map<String, dynamic>>{};
    for (final entry in featureMaps) {
      final id = entry['id']?.toString();
      if (id == null || id.isEmpty) continue;
      details[id] = Map<String, dynamic>.from(entry);
    }
    return details;
  }

  Future<void> _processFeatureGrants({
    required String heroId,
    required feature_model.Feature feature,
    required Map<String, Map<String, dynamic>> featureDetails,
    required Map<String, Set<String>> selections,
    required Set<String> activeSubclassSlugs,
    required Set<String> domainSlugs,
  }) async {
    final details = featureDetails[feature.id];
    
    // Always add the feature itself as a class_feature entry
    await _entries.addEntry(
      heroId: heroId,
      entryType: 'class_feature',
      entryId: feature.id,
      sourceType: 'class_feature',
      sourceId: feature.id,
      gainedBy: 'grant',
      payload: {
        'name': feature.name,
        'level': feature.level,
        'type': feature.type,
        'is_subclass_feature': feature.isSubclassFeature,
        if (feature.subclassName != null) 'subclass_name': feature.subclassName,
      },
    );

    if (details == null) return;

    // Process grants (auto-granted items)
    final isGrants = ClassFeatureDataService.hasGrants(details);
    final options = ClassFeatureDataService.extractOptionMaps(details);

    if (isGrants && options.isNotEmpty) {
      final remainingDomainSlugs =
          ClassFeatureDataService.remainingConduitDomainSlugsForFeature(
        featureId: feature.id,
        selectedDomainSlugs: domainSlugs,
        selections: selections,
        featureDetailsById: featureDetails,
      );
      final filterSecondaryDomains = remainingDomainSlugs.isNotEmpty;
      // Auto-grant all items that match the active subclass
      for (final option in options) {
        if (_optionMatchesSubclass(option, activeSubclassSlugs)) {
          if (filterSecondaryDomains) {
            final domain = option['domain']?.toString().trim();
            if (domain == null || domain.isEmpty) {
              continue;
            }
            final slug = ClassFeatureDataService.slugify(domain);
            if (!remainingDomainSlugs.contains(slug)) {
              continue;
            }
          }
          await _applyOptionGrants(heroId, feature.id, option);
        }
      }
    } else if (options.isNotEmpty) {
      // Apply user-selected options
      final selectedKeys = selections[feature.id] ?? const <String>{};
      for (final optionKey in selectedKeys) {
        final option = options.firstWhereOrNull(
          (o) => ClassFeatureDataService.featureOptionKey(o) == optionKey,
        );
        if (option != null) {
          await _applyOptionGrants(heroId, feature.id, option);
        }
      }
    }

    // Process top-level ability grant (e.g., "ability": "Judgment")
    await _processTopLevelAbility(heroId, feature.id, details);

    // Process stat_mods if present
    await _processStatMods(heroId, feature.id, details);

    // Process resistance grants if present
    await _processResistanceGrants(heroId, feature.id, details);

    // Process title grants if present
    await _processTitleGrants(heroId, feature.id, details);

    // Process top-level grants array (for stat bonuses, condition immunities, etc.)
    await _processGrantsArray(heroId, feature.id, details, activeSubclassSlugs, feature.level);
  }

  Future<void> _applySkillGroupSelections({
    required String heroId,
    required Map<String, Map<String, String>> selections,
    required Map<String, Map<String, dynamic>> featureDetails,
    required List<feature_model.Feature> applicableFeatures,
    required Map<String, Set<String>> featureSelections,
    required Set<String> activeSubclassSlugs,
    required Set<String> domainSlugs,
  }) async {
    if (selections.isEmpty) return;
    final applicableIds = {
      for (final feature in applicableFeatures) feature.id,
    };

    for (final entry in selections.entries) {
      final featureId = entry.key.trim();
      if (featureId.isEmpty || !applicableIds.contains(featureId)) {
        continue;
      }
      final details = featureDetails[featureId];
      if (details == null) continue;

      final options = ClassFeatureDataService.extractOptionMaps(details);
      if (options.isEmpty) continue;

      final selectedKeys = featureSelections[featureId] ?? const <String>{};
      final isGrants = ClassFeatureDataService.hasGrants(details);
      final remainingDomainSlugs =
          ClassFeatureDataService.remainingConduitDomainSlugsForFeature(
        featureId: featureId,
        selectedDomainSlugs: domainSlugs,
        selections: featureSelections,
        featureDetailsById: featureDetails,
      );
      final filterSecondaryDomains = remainingDomainSlugs.isNotEmpty;

      for (final option in options) {
        final skillGroup = option['skill_group']?.toString().trim();
        if (skillGroup == null || skillGroup.isEmpty) continue;

        final optionKey = ClassFeatureDataService.featureOptionKey(option);
        final isSelected = isGrants
            ? _optionMatchesSubclass(option, activeSubclassSlugs)
            : selectedKeys.contains(optionKey);
        if (!isSelected) continue;
        if (filterSecondaryDomains) {
          final domain = option['domain']?.toString().trim();
          if (domain == null || domain.isEmpty) continue;
          final slug = ClassFeatureDataService.slugify(domain);
          if (!remainingDomainSlugs.contains(slug)) continue;
        }

        final grantKey = ClassFeatureDataService.optionGrantKey(option);
        final skillId = entry.value[grantKey];
        if (skillId == null || skillId.trim().isEmpty) continue;

        await _entries.addEntry(
          heroId: heroId,
          entryType: 'skill',
          entryId: skillId,
          sourceType: 'class_feature',
          sourceId: '${featureId}_skill_group_$grantKey',
          gainedBy: 'choice',
        );
      }
    }
  }

  bool _optionMatchesSubclass(
    Map<String, dynamic> option,
    Set<String> activeSubclassSlugs,
  ) {
    if (activeSubclassSlugs.isEmpty) return true;

    // Check various subclass indicator keys
    for (final key in _subclassOptionKeys) {
      final value = option[key];
      if (value == null) continue;
      
      Set<String> optionSlugs;
      if (value is String) {
        optionSlugs = ClassFeatureDataService.slugVariants(value);
      } else if (value is List) {
        optionSlugs = value
            .whereType<String>()
            .expand((v) => ClassFeatureDataService.slugVariants(v))
            .toSet();
      } else {
        continue;
      }

      if (optionSlugs.isEmpty) continue;
      return optionSlugs.intersection(activeSubclassSlugs).isNotEmpty;
    }

    // No subclass restriction, so it matches
    return true;
  }

  Future<void> _applyOptionGrants(
    String heroId,
    String featureId,
    Map<String, dynamic> option,
  ) async {
    // Grant skill if specified
    final skill = option['skill']?.toString();
    if (skill != null && skill.isNotEmpty) {
      final skillId = await _resolveSkillId(skill);
      if (skillId != null) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'skill',
          entryId: skillId,
          sourceType: 'class_feature',
          sourceId: featureId,
          gainedBy: 'grant',
        );
      }
    }

    // Grant ability or abilities if specified
    final abilityNames = <String>{};
    _collectAbilityNames(abilityNames, option['ability']);
    _collectAbilityNames(abilityNames, option['abilities']);
    if (abilityNames.isNotEmpty) {
      for (final abilityName in abilityNames) {
        final abilityId = await _abilityResolver.resolveAbilityId(
          abilityName,
          sourceType: 'class_feature',
        );
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'ability',
          entryId: abilityId,
          sourceType: 'class_feature',
          sourceId: featureId,
          gainedBy: 'grant',
        );
      }
    }

    // Grant feature benefits with stat_mods
    final statMods = option['stat_mods'] ?? option['statMods'];
    if (statMods is Map) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'stat_mod',
        entryId: '${featureId}_option_stat_mod',
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
        payload: {'mods': statMods},
      );
    }

    // Grant resistances from option
    final immunities = option['immunities'] ?? option['immunity'];
    if (immunities != null) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'immunity',
        entryId: '${featureId}_option_immunity',
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
        payload: {'immunities': _normalizeToList(immunities)},
      );
    }

    // Grant titles from option
    final title = option['title']?.toString();
    if (title != null && title.isNotEmpty) {
      final titleId = await _resolveTitleId(title);
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'title',
        entryId: titleId,
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
      );
    }
  }

  Future<void> _processStatMods(
    String heroId,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final statMods = details['stat_mods'] ?? details['statMods'];
    if (statMods is! Map) return;

    await _entries.addEntry(
      heroId: heroId,
      entryType: 'stat_mod',
      entryId: '${featureId}_stat_mod',
      sourceType: 'class_feature',
      sourceId: featureId,
      gainedBy: 'grant',
      payload: {'mods': statMods},
    );
  }

  Future<void> _processResistanceGrants(
    String heroId,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final immunities = details['immunities'] ?? details['immunity'];
    if (immunities != null) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'immunity',
        entryId: '${featureId}_immunity',
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
        payload: {'immunities': _normalizeToList(immunities)},
      );
    }

    final weaknesses = details['weaknesses'] ?? details['weakness'];
    if (weaknesses != null) {
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'weakness',
        entryId: '${featureId}_weakness',
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
        payload: {'weaknesses': _normalizeToList(weaknesses)},
      );
    }
  }

  Future<void> _processTitleGrants(
    String heroId,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final titles = details['titles'] ?? details['granted_titles'];
    if (titles == null) return;

    final titleList = _normalizeToList(titles);
    for (final title in titleList) {
      if (title.isEmpty) continue;
      final titleId = await _resolveTitleId(title);
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'title',
        entryId: titleId,
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
      );
    }
  }

  /// Process top-level ability granted by a feature (e.g., "ability": "Judgment")
  Future<void> _processTopLevelAbility(
    String heroId,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final abilityNames = <String>{};
    _collectAbilityNames(abilityNames, details['ability']);
    if (abilityNames.isEmpty) return;

    for (final abilityName in abilityNames) {
      final abilityId = await _abilityResolver.resolveAbilityId(
        abilityName,
        sourceType: 'class_feature',
      );
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'ability',
        entryId: abilityId,
        sourceType: 'class_feature',
        sourceId: featureId,
        gainedBy: 'grant',
      );
    }
  }

  /// Process the top-level "grants" array in a feature.
  /// 
  /// Handles various grant types:
  /// - speed_bonus: Grants speed bonus (may be static or linked to characteristic)
  /// - disengage_bonus: Grants disengage bonus (may be static or linked to characteristic)
  /// - stamina_increase: Grants stamina increase
  /// - condition_immunity: Grants immunity to a condition
  /// - ability: Grants an ability
  /// - skill: Grants a skill
  /// - language: Grants a language
  Future<void> _processGrantsArray(
    String heroId,
    String featureId,
    Map<String, dynamic> details,
    Set<String> activeSubclassSlugs,
    int featureLevel,
  ) async {
    final grants = details['grants'];
    if (grants is! List) return;

    // Collect stat bonuses to merge into a single hero_values entry later
    final statBonuses = <String, dynamic>{};
    final conditionImmunities = <String>[];
    final damageResistanceGrants = <Map<String, dynamic>>[];

    for (final grant in grants) {
      if (grant is! Map<String, dynamic>) continue;

      // Check if this grant is subclass-specific
      if (!_optionMatchesSubclass(grant, activeSubclassSlugs)) continue;

      // Process each type of grant
      for (final entry in grant.entries) {
        final key = entry.key;
        final value = entry.value;

        // Skip subclass keys and metadata keys
        if (_subclassOptionKeys.contains(key)) continue;
        if (key == 'name' || key == 'description') continue;

        switch (key) {
          // Stat bonuses (may be static int or characteristic name like "Agility")
          case 'speed_bonus':
          case 'disengage_bonus':
          case 'stability_bonus':
          case 'stamina_increase':
          case 'recoveries_bonus':
            statBonuses[key] = value;
            break;

          // Stamina per level increase: adds extra stamina for each level past the feature level
          case 'stamina_per_level_increase':
            if (value is int || value is num) {
              statBonuses['stamina_per_level_increase'] = {
                'value': (value is int) ? value : (value as num).toInt(),
                'feature_level': featureLevel,
              };
            }
            break;

          // increase_total: array or single object of stat increases (supports immunity with level scaling)
          case 'increase_total':
            _processIncreaseTotalGrant(value, statBonuses, damageResistanceGrants, featureId);
            break;

          // Condition immunity
          case 'condition_immunity':
            if (value is String && value.isNotEmpty) {
              conditionImmunities.add(value);
            }
            break;

          // Ability grant
          case 'ability':
            final abilityNames = <String>{};
            _collectAbilityNames(abilityNames, value);
            for (final abilityName in abilityNames) {
              final abilityId = await _abilityResolver.resolveAbilityId(
                abilityName,
                sourceType: 'class_feature',
              );
              await _entries.addEntry(
                heroId: heroId,
                entryType: 'ability',
                entryId: abilityId,
                sourceType: 'class_feature',
                sourceId: featureId,
                gainedBy: 'grant',
              );
            }
            break;

          // Skill grant
          case 'skill':
            if (value is String && value.isNotEmpty) {
              final skillId = await _resolveSkillId(value);
              if (skillId != null) {
                await _entries.addEntry(
                  heroId: heroId,
                  entryType: 'skill',
                  entryId: skillId,
                  sourceType: 'class_feature',
                  sourceId: featureId,
                  gainedBy: 'grant',
                );
              }
            }
            break;

          // Language grant
          case 'language':
            if (value is String && value.isNotEmpty) {
              await _entries.addEntry(
                heroId: heroId,
                entryType: 'language',
                entryId: 'language_${ClassFeatureDataService.slugify(value)}',
                sourceType: 'class_feature',
                sourceId: featureId,
                gainedBy: 'grant',
                payload: {'name': value},
              );
            }
            break;

          // Nested grants object (contains stamina_per_level_increase, increase_total, etc.)
          case 'grants':
            if (value is Map<String, dynamic>) {
              _processNestedGrants(
                value,
                statBonuses,
                damageResistanceGrants,
                featureId,
                featureLevel,
              );
            }
            break;

          default:
            // Store other grants generically in payload for future use
            break;
        }
      }
    }

    // Store stat bonuses into hero_values under strife.feature_stat_bonuses
    // We keep a map keyed by featureId to preserve source
    if (statBonuses.isNotEmpty) {
      // Load existing map (if any) to merge with other features
      final values = await _db.getHeroValues(heroId);
      final hvRow = values.firstWhereOrNull((v) => v.key == 'strife.feature_stat_bonuses');
      Map<String, dynamic> combined = {};
      final raw = hvRow?.jsonValue ?? hvRow?.textValue;
      if (raw != null && raw.isNotEmpty) {
        try {
          combined = Map<String, dynamic>.from(jsonDecode(raw));
        } catch (_) {
          combined = {};
        }
      }

      combined[featureId] = statBonuses;

      // Clear legacy hero_entries for feature_stat_bonus to avoid double counting
      await _db.clearHeroEntryType(heroId, 'feature_stat_bonus');

      await _db.upsertHeroValue(
        heroId: heroId,
        key: 'strife.feature_stat_bonuses',
        jsonMap: combined,
      );
    }

    // Store damage resistance grants (immunity/weakness with level scaling)
    if (damageResistanceGrants.isNotEmpty) {
      var grantIndex = 0;
      for (final grant in damageResistanceGrants) {
        final damageType = grant['type']?.toString().toLowerCase() ?? '';
        if (damageType.isEmpty) continue;
        
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'damage_resistance',
          entryId: '${featureId}_resistance_${damageType}_$grantIndex',
          sourceType: 'class_feature',
          sourceId: featureId,
          gainedBy: 'grant',
          payload: grant,
        );
        grantIndex++;
      }
    }

    // Store condition immunities
    if (conditionImmunities.isNotEmpty) {
      for (final condition in conditionImmunities) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'condition_immunity',
          entryId: 'immunity_$condition',
          sourceType: 'class_feature',
          sourceId: featureId,
          gainedBy: 'grant',
          payload: {'condition': condition},
        );
      }
    }
  }

  /// Process nested grants object containing stamina_per_level_increase, increase_total, etc.
  void _processNestedGrants(
    Map<String, dynamic> nestedGrants,
    Map<String, dynamic> statBonuses,
    List<Map<String, dynamic>> damageResistanceGrants,
    String featureId,
    int featureLevel,
  ) {
    for (final entry in nestedGrants.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        // Stamina per level increase: adds extra stamina for each level past the feature level
        case 'stamina_per_level_increase':
          if (value is int) {
            // Store both the per-level value and the feature level for proper calculation
            statBonuses['stamina_per_level_increase'] = {
              'value': value,
              'feature_level': featureLevel,
            };
          } else if (value is num) {
            statBonuses['stamina_per_level_increase'] = {
              'value': value.toInt(),
              'feature_level': featureLevel,
            };
          }
          break;

        // increase_total: array of stat increases (supports immunity with level scaling)
        case 'increase_total':
          if (value is List) {
            for (final item in value) {
              if (item is! Map<String, dynamic>) continue;
              final stat = item['stat']?.toString().toLowerCase();
              if (stat == null) continue;

              if (stat == 'immunity' || stat == 'weakness') {
                // Damage resistance grant with potential level scaling
                final damageType = item['type']?.toString();
                final itemValue = item['value'];
                if (damageType != null) {
                  damageResistanceGrants.add({
                    'stat': stat,
                    'type': damageType,
                    'value': itemValue,
                    'source': featureId,
                  });
                }
              } else {
                // Regular stat increase
                final itemValue = item['value'];
                if (itemValue is int) {
                  final existingValue = statBonuses[stat];
                  if (existingValue is int) {
                    statBonuses[stat] = existingValue + itemValue;
                  } else {
                    statBonuses[stat] = itemValue;
                  }
                } else if (itemValue is String) {
                  // Dynamic value like "level"
                  statBonuses['${stat}_dynamic'] = itemValue;
                }
              }
            }
          } else if (value is Map<String, dynamic>) {
            // Single increase_total object
            final stat = value['stat']?.toString().toLowerCase();
            if (stat == null) break;

            if (stat == 'immunity' || stat == 'weakness') {
              final damageType = value['type']?.toString();
              final itemValue = value['value'];
              if (damageType != null) {
                damageResistanceGrants.add({
                  'stat': stat,
                  'type': damageType,
                  'value': itemValue,
                  'source': featureId,
                });
              }
            } else {
              final itemValue = value['value'];
              if (itemValue is int) {
                statBonuses[stat] = (statBonuses[stat] as int? ?? 0) + itemValue;
              } else if (itemValue is String) {
                statBonuses['${stat}_dynamic'] = itemValue;
              }
            }
          }
          break;

        default:
          // Unknown nested grant type, ignore
          break;
      }
    }
  }

  /// Process increase_total grant (array or single object of stat increases).
  void _processIncreaseTotalGrant(
    dynamic value,
    Map<String, dynamic> statBonuses,
    List<Map<String, dynamic>> damageResistanceGrants,
    String featureId,
  ) {
    if (value is List) {
      for (final item in value) {
        if (item is! Map<String, dynamic>) continue;
        _processSingleIncreaseTotal(item, statBonuses, damageResistanceGrants, featureId);
      }
    } else if (value is Map<String, dynamic>) {
      _processSingleIncreaseTotal(value, statBonuses, damageResistanceGrants, featureId);
    }
  }

  /// Process a single increase_total object.
  void _processSingleIncreaseTotal(
    Map<String, dynamic> item,
    Map<String, dynamic> statBonuses,
    List<Map<String, dynamic>> damageResistanceGrants,
    String featureId,
  ) {
    final stat = item['stat']?.toString().toLowerCase();
    if (stat == null) return;

    if (stat == 'immunity' || stat == 'weakness') {
      // Damage resistance grant with potential level scaling
      final damageType = item['type']?.toString();
      final itemValue = item['value'];
      if (damageType != null) {
        damageResistanceGrants.add({
          'stat': stat,
          'type': damageType,
          'value': itemValue,
          'source': featureId,
        });
      }
    } else {
      // Regular stat increase
      final itemValue = item['value'];
      if (itemValue is int) {
        final existingValue = statBonuses[stat];
        if (existingValue is int) {
          statBonuses[stat] = existingValue + itemValue;
        } else {
          statBonuses[stat] = itemValue;
        }
      } else if (itemValue is String) {
        // Dynamic value like "level"
        statBonuses['${stat}_dynamic'] = itemValue;
      }
    }
  }

  List<String> _normalizeToList(dynamic value) {
    if (value == null) return const [];
    if (value is String) return [value];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  void _collectAbilityNames(Set<String> target, dynamic value) {
    for (final name in _normalizeToList(value)) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) {
        target.add(trimmed);
      }
    }
  }

  Future<String?> _resolveSkillId(String skillName) async {
    final components = await _db.getAllComponents();
    final match = components.firstWhereOrNull(
      (c) => c.type == 'skill' && c.name.toLowerCase() == skillName.toLowerCase(),
    );
    return match?.id ?? 'skill_${ClassFeatureDataService.slugify(skillName)}';
  }

  Future<String> _resolveTitleId(String titleName) async {
    final components = await _db.getAllComponents();
    final match = components.firstWhereOrNull(
      (c) => c.type == 'title' && c.name.toLowerCase() == titleName.toLowerCase(),
    );
    return match?.id ?? 'title_${ClassFeatureDataService.slugify(titleName)}';
  }

  String? _classSlugFromId(String? classId) {
    if (classId == null || classId.trim().isEmpty) return null;
    var slug = classId.trim().toLowerCase();
    if (slug.startsWith('class_')) {
      slug = slug.substring('class_'.length);
    }
    return slug.isEmpty ? null : slug;
  }

  static const List<String> _subclassOptionKeys = [
    'subclass',
    'subclass_name',
    'tradition',
    'order',
    'doctrine',
    'mask',
    'path',
    'circle',
    'college',
    'element',
    'role',
    'discipline',
    'oath',
    'school',
    'guild',
    'domain',
    'aspect',
  ];
}
