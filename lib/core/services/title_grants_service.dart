import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart';
import '../repositories/hero_entry_repository.dart';
import 'ability_resolver_service.dart';
import 'damage_resistance_service.dart';
import 'hero_config_service.dart';

/// Config key for storing characteristic choice selections per title.
/// Value shape: `{ "<titleId>": "<characteristic>" }` (e.g. `{ "demigod": "might" }`)
const _kCharChoicesKey = 'title.characteristic_choices';

/// Config key for storing ancestry trait selections per title benefit.
/// Value shape: `{ "<titleId>": ["traitId1", "traitId2"] }`
const _kAncestryTraitsKey = 'title.ancestry_traits';

/// Config key for storing ancestry trait sub-choices (immunity, ability pick).
/// Value shape: `{ "<titleId>.<traitId>": "<chosenValue>" }`
const _kAncestryTraitChoicesKey = 'title.ancestry_trait_choices';

/// Config key for storing skill choices for title grants.
/// Value shape: `{ "<titleId>__<tag>": "skillId" }` or `{ "<titleId>": ["skillId1", ...] }`
const _kSkillChoicesKey = 'title.skill_choices';

/// Config key for storing language choices for title grants.
/// Value shape: `{ "<titleId>": ["langId1", "langId2"] }`
const _kLanguageChoicesKey = 'title.language_choices';

/// Config key for storing heroic ability choice for title grants.
/// Value shape: `{ "<titleId>": "abilityId" }`
const _kHeroicAbilityChoicesKey = 'title.heroic_ability_choices';

/// Config key for storing damage type choices for damage_immunity grants.
/// Value shape: `{ "<titleId>": "damageType" }`
const _kDamageTypeChoicesKey = 'title.damage_type_choices';

/// Service to handle title grant processing.
///
/// Titles can grant abilities through their selected benefit, plus additional
/// grants such as stat modifications (renown, wealth, characteristic increases),
/// skills, and languages.
class TitleGrantsService {
  TitleGrantsService(this._db)
      : _entries = HeroEntryRepository(_db),
        _abilityResolver = AbilityResolverService(_db),
        _config = HeroConfigService(_db),
        _resistanceService = DamageResistanceService(_db);

  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final AbilityResolverService _abilityResolver;
  final HeroConfigService _config;
  final DamageResistanceService _resistanceService;
  
  /// Get all titles from the database.
  Future<List<Component>> loadTitles() async {
    return _abilityResolver.getAllTitles();
  }
  
  /// Get a title by ID from the database.
  /// Returns the title data as a Map for compatibility with existing code.
  Future<Map<String, dynamic>?> getTitleById(String titleId) async {
    final component = await _abilityResolver.getTitleById(titleId);
    if (component == null) return null;
    
    // Reconstruct the title data from Component
    final data = component.dataJson.isNotEmpty 
        ? jsonDecode(component.dataJson) as Map<String, dynamic>
        : <String, dynamic>{};
    return {
      'id': component.id,
      'name': component.name,
      ...data,
    };
  }
  
  /// Get the ability ID for a title benefit, if it grants one
  Future<String?> getAbilityIdForBenefit(
    Map<String, dynamic> title, 
    int benefitIndex,
  ) async {
    final benefits = title['benefits'] as List?;
    if (benefits == null || benefitIndex < 0 || benefitIndex >= benefits.length) return null;
    
    final benefit = benefits[benefitIndex] as Map<String, dynamic>?;
    if (benefit == null) return null;
    
    final abilityRef = benefit['ability'];
    if (abilityRef == null || abilityRef.toString().isEmpty) return null;
    
    final abilitySlug = abilityRef.toString();
    return await _abilityResolver.resolveAbilityId(
      abilitySlug,
      sourceType: 'title',
      ensureInDb: true,
    );
  }
  
  /// Apply title grants for a hero.
  ///
  /// Takes a list of selected titles in format "titleId:benefitIndex"
  /// and writes granted abilities, stat modifications, skills, and languages
  /// to hero_entries. Benefits with "auto": true are always applied.
  Future<void> applyTitleGrants({
    required String heroId,
    required List<String> selectedTitleIds,
  }) async {
    // Clear all existing title-granted entries
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
    );

    // Load stored characteristic choices
    final charChoices = await _config.getConfigValue(heroId, _kCharChoicesKey)
        ?? <String, dynamic>{};

    for (final selection in selectedTitleIds) {
      final parts = selection.split(':');
      if (parts.length != 2) continue;

      final titleId = parts[0];
      final benefitIndex = int.tryParse(parts[1]) ?? 0;

      final title = await getTitleById(titleId);
      if (title == null) continue;
      final titleName = title['name'] as String? ?? titleId;

      // ── Title-level grants ──────────────────────────────────
      final titleGrants = title['grants'] as List?;
      if (titleGrants != null) {
        for (final grant in titleGrants) {
          if (grant is! Map<String, dynamic>) continue;
          await _applyGrant(
            heroId: heroId,
            titleId: titleId,
            titleName: titleName,
            grant: grant,
            charChoices: charChoices,
            grantSource: titleName,
          );
        }
      }

      // ── Benefit-level grants ────────────────────────────────
      final benefits = title['benefits'] as List? ?? [];
      final indicesToApply = <int>{};

      // Auto benefits
      for (int i = 0; i < benefits.length; i++) {
        final b = benefits[i] as Map<String, dynamic>? ?? {};
        if (b['auto'] == true) indicesToApply.add(i);
      }

      // User-chosen benefit
      if (benefitIndex >= 0 && benefitIndex < benefits.length) {
        indicesToApply.add(benefitIndex);
      }

      for (final idx in indicesToApply) {
        final benefit = benefits[idx];
        if (benefit is! Map<String, dynamic>) continue;
        final benefitName = benefit['name'] as String? ?? 'Benefit $idx';

        // Ability grant
        final abilityId = await getAbilityIdForBenefit(title, idx);
        if (abilityId != null && abilityId.isNotEmpty) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'ability',
            entryId: abilityId,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {
              'benefitIndex': idx,
              'titleName': titleName,
            },
          );
        }

        // Other grants on the benefit
        final benefitGrants = benefit['grants'] as List?;
        if (benefitGrants != null) {
          for (final grant in benefitGrants) {
            if (grant is! Map<String, dynamic>) continue;
            await _applyGrant(
              heroId: heroId,
              titleId: titleId,
              titleName: titleName,
              grant: grant,
              charChoices: charChoices,
              grantSource: '$benefitName ($titleName)',
            );
          }
        }
      }
    }

    // Recompute aggregate damage resistances (title grants may add immunity)
    await _resistanceService.recomputeAggregateResistances(heroId);
  }

  /// Apply a single grant entry. Dispatches based on `grant['type']`.
  Future<void> _applyGrant({
    required String heroId,
    required String titleId,
    required String titleName,
    required Map<String, dynamic> grant,
    required Map<String, dynamic> charChoices,
    required String grantSource,
  }) async {
    final type = grant['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'renown':
      case 'wealth':
        final value = (grant['value'] as num?)?.toInt() ?? 0;
        if (value == 0) return;
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'stat_mod',
          entryId: type, // 'renown' or 'wealth'
          sourceType: 'title',
          sourceId: titleId,
          gainedBy: 'grant',
          payload: {
            'mods': [
              {'value': value, 'source': grantSource},
            ],
          },
        );

      case 'characteristic_increase':
        final choices = (grant['choices'] as List?)
                ?.whereType<String>()
                .toList() ??
            [];
        final value = (grant['value'] as num?)?.toInt() ?? 1;
        // Use the tag (if present) to disambiguate multiple char grants on one title
        final tag = grant['tag'] as String?;
        final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
        final chosen = charChoices[choiceKey] as String?;

        if (chosen != null && choices.contains(chosen)) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'stat_mod',
            entryId: chosen,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {
              'mods': [
                {'value': value, 'source': grantSource},
              ],
            },
          );
        }
        // If no choice stored yet, skip — UI will prompt.

      case 'followers_cap':
        final value = (grant['value'] as num?)?.toInt() ?? 0;
        if (value == 0) return;
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'stat_mod',
          entryId: 'followers_cap',
          sourceType: 'title',
          sourceId: titleId,
          gainedBy: 'grant',
          payload: {
            'mods': [
              {'value': value, 'source': grantSource},
            ],
          },
        );

      case 'languages':
        final specific = (grant['specific'] as List?)
            ?.whereType<String>()
            .toList();
        if (specific != null && specific.isNotEmpty) {
          await _entries.addEntriesFromSource(
            heroId: heroId,
            sourceType: 'title',
            sourceId: titleId,
            entryType: 'language',
            entryIds: specific,
            gainedBy: 'grant',
          );
        }
        // Non-specific language grants (count only) — apply stored choices.
        final langCount = (grant['count'] as num?)?.toInt() ?? 0;
        if (specific == null && langCount > 0) {
          final langChoices = await _config.getConfigValue(heroId, _kLanguageChoicesKey)
              ?? <String, dynamic>{};
          final chosen = (langChoices[titleId] as List?)
              ?.whereType<String>()
              .toList() ?? [];
          if (chosen.isNotEmpty) {
            await _entries.addEntriesFromSource(
              heroId: heroId,
              sourceType: 'title',
              sourceId: titleId,
              entryType: 'language',
              entryIds: chosen.take(langCount).toList(),
              gainedBy: 'grant',
            );
          }
        }

      case 'skill_choice':
        // Skill grants with a specific single skill are auto-applied.
        final specificSkill = grant['skill'] as String?;
        if (specificSkill != null) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'skill',
            entryId: specificSkill,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
          );
        }
        // Group-based or unconstrained skill choices — apply stored choices.
        if (specificSkill == null) {
          final skillChoices = await _config.getConfigValue(heroId, _kSkillChoicesKey)
              ?? <String, dynamic>{};
          final tag = grant['tag'] as String?;
          final group = grant['group'] as String?;
          final choiceKey = tag != null ? '${titleId}__$tag' : (group != null ? '${titleId}__$group' : titleId);
          final count = (grant['count'] as num?)?.toInt() ?? 1;
          final raw = skillChoices[choiceKey];
          final chosen = raw is List
              ? raw.whereType<String>().toList()
              : raw is String ? [raw] : <String>[];
          if (chosen.isNotEmpty) {
            await _entries.addEntriesFromSource(
              heroId: heroId,
              sourceType: 'title',
              sourceId: titleId,
              entryType: 'skill',
              entryIds: chosen.take(count).toList(),
              gainedBy: 'grant',
            );
          }
        }

      case 'ancestry_points':
        await _applyAncestryPointsGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: grant,
          grantSource: grantSource,
        );

      case 'heroic_ability_choice':
        final abilityChoices = await _config.getConfigValue(heroId, _kHeroicAbilityChoicesKey)
            ?? <String, dynamic>{};
        final chosenAbilityId = abilityChoices[titleId] as String?;
        if (chosenAbilityId != null && chosenAbilityId.isNotEmpty) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'ability',
            entryId: chosenAbilityId,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {
              'titleName': titleName,
              'grantType': 'heroic_ability_choice',
            },
          );
        }

      case 'item_prerequisite':
        // Informational only — stored as a note entry so the hero sheet
        // can display it, but no mechanical stat changes needed.
        final category = grant['category'] as String? ?? '';
        final tag = grant['tag'] as String? ?? '';
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'item_prerequisite',
          entryId: '${titleId}_${category}_$tag',
          sourceType: 'title',
          sourceId: titleId,
          gainedBy: 'grant',
          payload: {
            'category': category,
            'tag': tag,
            'count': (grant['count'] as num?)?.toInt() ?? 1,
            'titleName': titleName,
          },
        );

      case 'damage_immunity':
        await _applyDamageImmunityGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: grant,
          grantSource: grantSource,
        );

      case 'condition_immunity':
        final condition = grant['condition'] as String?;
        if (condition != null && condition.isNotEmpty) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'condition_immunity',
            entryId: condition,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {'titleName': titleName, 'grantSource': grantSource},
          );
        }
    }
  }

  /// Save a characteristic choice for a title and re-apply grants.
  Future<void> setCharacteristicChoice({
    required String heroId,
    required String titleId,
    required String characteristic,
    String? tag,
  }) async {
    final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
    final existing = await _config.getConfigValue(heroId, _kCharChoicesKey)
        ?? <String, dynamic>{};
    existing[choiceKey] = characteristic;
    await _config.setConfigValue(
      heroId: heroId,
      key: _kCharChoicesKey,
      value: existing,
    );
  }

  /// Get the stored characteristic choice for a title.
  Future<String?> getCharacteristicChoice({
    required String heroId,
    required String titleId,
    String? tag,
  }) async {
    final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
    final choices = await _config.getConfigValue(heroId, _kCharChoicesKey);
    return choices?[choiceKey] as String?;
  }

  /// Get all stored characteristic choices for a hero.
  /// Returns a map of choiceKey → characteristic name.
  Future<Map<String, String>> getAllCharacteristicChoices({
    required String heroId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kCharChoicesKey);
    if (raw == null) return {};
    return Map<String, String>.from(
      raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
  
  /// Remove all title grants for a hero.
  Future<void> removeTitleGrants({
    required String heroId,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
    );
  }
  
  /// Remove grants for a specific title.
  Future<void> removeTitleGrantsForTitle({
    required String heroId,
    required String titleId,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
      sourceId: titleId,
    );
  }
  
  /// Get all abilities granted by titles for a hero.
  Future<List<String>> getGrantedAbilities({
    required String heroId,
  }) async {
    final all = await _entries.listEntriesByType(heroId, 'ability');
    return all
        .where((e) => e.sourceType == 'title')
        .map((e) => e.entryId)
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Ancestry Points
  // ══════════════════════════════════════════════════════════════════════════

  /// Apply ancestry_points grant: resolve stored trait selections and write entries.
  Future<void> _applyAncestryPointsGrant({
    required String heroId,
    required String titleId,
    required String titleName,
    required Map<String, dynamic> grant,
    required String grantSource,
  }) async {
    final ancestryId = grant['ancestry'] as String?;
    if (ancestryId == null) return;

    // Load stored selections
    final storedTraits = await _config.getConfigValue(heroId, _kAncestryTraitsKey)
        ?? <String, dynamic>{};
    final selectedTraitIds = (storedTraits[titleId] as List?)
        ?.whereType<String>()
        .toList() ?? [];
    if (selectedTraitIds.isEmpty) return;

    final storedSubChoices = await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey)
        ?? <String, dynamic>{};

    // Load the ancestry_trait component from DB
    final allComponents = await _db.getAllComponents();
    final traitsComp = allComponents.where((c) {
      if (c.type != 'ancestry_trait') return false;
      final data = c.dataJson.isNotEmpty
          ? jsonDecode(c.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};
      final aid = data['ancestry_id'] as String?;
      return aid == ancestryId || aid == 'ancestry_$ancestryId';
    }).firstOrNull;
    if (traitsComp == null) return;

    final traitsData = jsonDecode(traitsComp.dataJson) as Map<String, dynamic>;
    final traitsList = (traitsData['traits'] as List?) ?? [];

    for (final trait in traitsList) {
      if (trait is! Map) continue;
      final traitMap = trait.cast<String, dynamic>();
      final traitId = (traitMap['id'] ?? traitMap['name']).toString();
      if (!selectedTraitIds.contains(traitId)) continue;

      final traitName = (traitMap['name'] ?? traitId).toString();

      // grants_ability_name → ability entry
      final abilityName = traitMap['grants_ability_name'] as String?;
      if (abilityName != null && abilityName.isNotEmpty) {
        final abilityId = await _abilityResolver.resolveAbilityId(
          abilityName,
          sourceType: 'title',
          ensureInDb: true,
        );
        if (abilityId.isNotEmpty) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'ability',
            entryId: abilityId,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {'titleName': titleName, 'traitName': traitName},
          );
        }
      }

      // pick_ability_name → user-chosen ability entry
      final pickAbilityNames = traitMap['pick_ability_name'] as List?;
      if (pickAbilityNames != null && pickAbilityNames.isNotEmpty) {
        final subKey = '$titleId.$traitId';
        final chosenName = storedSubChoices[subKey] as String?;
        if (chosenName != null && chosenName.isNotEmpty) {
          final abilityId = await _abilityResolver.resolveAbilityId(
            chosenName,
            sourceType: 'title',
            ensureInDb: true,
          );
          if (abilityId.isNotEmpty) {
            await _entries.addEntry(
              heroId: heroId,
              entryType: 'ability',
              entryId: abilityId,
              sourceType: 'title',
              sourceId: titleId,
              gainedBy: 'grant',
              payload: {'titleName': titleName, 'traitName': traitName},
            );
          }
        }
      }

      // condition_immunity → condition immunity entry
      final condImmunity = traitMap['condition_immunity'] as String?;
      if (condImmunity != null && condImmunity.isNotEmpty) {
        await _entries.addEntry(
          heroId: heroId,
          entryType: 'condition_immunity',
          entryId: condImmunity,
          sourceType: 'title',
          sourceId: titleId,
          gainedBy: 'grant',
          payload: {'titleName': titleName, 'traitName': traitName},
        );
      }

      // set_base_stat_if_not_already_higher → stat_mod entry
      final setBase = traitMap['set_base_stat_if_not_already_higher'];
      if (setBase is Map) {
        final stat = setBase['stat'] as String?;
        final value = (setBase['value'] as num?)?.toInt();
        if (stat != null && value != null) {
          await _entries.addEntry(
            heroId: heroId,
            entryType: 'stat_mod',
            entryId: stat,
            sourceType: 'title',
            sourceId: titleId,
            gainedBy: 'grant',
            payload: {
              'mods': [
                {'value': value, 'source': '$traitName ($grantSource)', 'mode': 'set_base'},
              ],
            },
          );
        }
      }

      // increase_total → stat_mod entry (e.g., immunity scaling)
      final increase = traitMap['increase_total'];
      if (increase is Map) {
        final stat = increase['stat'] as String?;
        final type = increase['type'] as String?;
        if (stat != null) {
          // For pick_one immunity, the user must choose the type
          final effectiveType = type == 'pick_one'
              ? storedSubChoices['$titleId.$traitId'] as String?
              : type;
          if (effectiveType != null) {
            await _entries.addEntry(
              heroId: heroId,
              entryType: 'stat_mod',
              entryId: '$stat.$effectiveType',
              sourceType: 'title',
              sourceId: titleId,
              gainedBy: 'grant',
              payload: {
                'mods': [
                  {'value': increase['value'], 'source': '$traitName ($grantSource)'},
                ],
              },
            );
          }
        }
      }
    }
  }

  /// Save ancestry trait selections for a title.
  Future<void> setAncestryTraitSelections({
    required String heroId,
    required String titleId,
    required List<String> traitIds,
  }) async {
    final existing = await _config.getConfigValue(heroId, _kAncestryTraitsKey)
        ?? <String, dynamic>{};
    existing[titleId] = traitIds;
    await _config.setConfigValue(heroId: heroId, key: _kAncestryTraitsKey, value: existing);
  }

  /// Get ancestry trait selections for a title.
  Future<List<String>> getAncestryTraitSelections({
    required String heroId,
    required String titleId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kAncestryTraitsKey);
    return (raw?[titleId] as List?)?.whereType<String>().toList() ?? [];
  }

  /// Save a sub-choice for an ancestry trait (e.g., immunity type, ability pick).
  Future<void> setAncestryTraitSubChoice({
    required String heroId,
    required String titleId,
    required String traitId,
    required String value,
  }) async {
    final existing = await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey)
        ?? <String, dynamic>{};
    existing['$titleId.$traitId'] = value;
    await _config.setConfigValue(
      heroId: heroId,
      key: _kAncestryTraitChoicesKey,
      value: existing,
    );
  }

  /// Get a sub-choice for an ancestry trait.
  Future<String?> getAncestryTraitSubChoice({
    required String heroId,
    required String titleId,
    required String traitId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey);
    return raw?['$titleId.$traitId'] as String?;
  }

  /// Get all ancestry trait sub-choices for a hero.
  Future<Map<String, String>> getAllAncestryTraitSubChoices({
    required String heroId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey);
    if (raw == null) return {};
    return Map<String, String>.from(
      raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Skill Choices
  // ══════════════════════════════════════════════════════════════════════════

  /// Save skill choice(s) for a title grant.
  Future<void> setSkillChoice({
    required String heroId,
    required String titleId,
    required List<String> skillIds,
    String? tag,
    String? group,
  }) async {
    final choiceKey = tag != null ? '${titleId}__$tag' : (group != null ? '${titleId}__$group' : titleId);
    final existing = await _config.getConfigValue(heroId, _kSkillChoicesKey)
        ?? <String, dynamic>{};
    existing[choiceKey] = skillIds;
    await _config.setConfigValue(heroId: heroId, key: _kSkillChoicesKey, value: existing);
  }

  /// Get skill choice(s) for a title grant.
  Future<List<String>> getSkillChoice({
    required String heroId,
    required String titleId,
    String? tag,
    String? group,
  }) async {
    final choiceKey = tag != null ? '${titleId}__$tag' : (group != null ? '${titleId}__$group' : titleId);
    final raw = await _config.getConfigValue(heroId, _kSkillChoicesKey);
    final val = raw?[choiceKey];
    if (val is List) return val.whereType<String>().toList();
    if (val is String) return [val];
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Language Choices
  // ══════════════════════════════════════════════════════════════════════════

  /// Save language choice(s) for a title grant.
  Future<void> setLanguageChoice({
    required String heroId,
    required String titleId,
    required List<String> languageIds,
  }) async {
    final existing = await _config.getConfigValue(heroId, _kLanguageChoicesKey)
        ?? <String, dynamic>{};
    existing[titleId] = languageIds;
    await _config.setConfigValue(heroId: heroId, key: _kLanguageChoicesKey, value: existing);
  }

  /// Get language choice(s) for a title grant.
  Future<List<String>> getLanguageChoice({
    required String heroId,
    required String titleId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kLanguageChoicesKey);
    return (raw?[titleId] as List?)?.whereType<String>().toList() ?? [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Heroic Ability Choice
  // ══════════════════════════════════════════════════════════════════════════

  /// Save a heroic ability choice for a title grant.
  Future<void> setHeroicAbilityChoice({
    required String heroId,
    required String titleId,
    required String abilityId,
  }) async {
    final existing = await _config.getConfigValue(heroId, _kHeroicAbilityChoicesKey)
        ?? <String, dynamic>{};
    existing[titleId] = abilityId;
    await _config.setConfigValue(heroId: heroId, key: _kHeroicAbilityChoicesKey, value: existing);
  }

  /// Get the stored heroic ability choice for a title.
  Future<String?> getHeroicAbilityChoice({
    required String heroId,
    required String titleId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kHeroicAbilityChoicesKey);
    return raw?[titleId] as String?;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Damage Immunity
  // ══════════════════════════════════════════════════════════════════════════

  /// Apply a damage_immunity grant.
  ///
  /// Supported JSON shapes:
  /// - Static value: `{ "type": "damage_immunity", "damage_type": "psychic", "value": 10 }`
  /// - Level-scaled:  `{ ... "damage_type": "corruption", "value_source": "level" }`
  /// - Highest char:  `{ ... "damage_type": "corruption", "value_source": "highest_characteristic" }`
  /// - User-chosen type: `{ ... "damage_type": "choose", "damage_type_options": [...] }`
  Future<void> _applyDamageImmunityGrant({
    required String heroId,
    required String titleId,
    required String titleName,
    required Map<String, dynamic> grant,
    required String grantSource,
  }) async {
    // Determine damage type
    String? damageType = grant['damage_type'] as String?;
    if (damageType == null) return;

    // If user must choose the damage type, load their stored choice
    if (damageType == 'choose') {
      final choices = await _config.getConfigValue(heroId, _kDamageTypeChoicesKey)
          ?? <String, dynamic>{};
      final chosen = choices[titleId] as String?;
      if (chosen == null || chosen.isEmpty) return; // UI will prompt
      damageType = chosen;
    }

    // Determine immunity value
    final valueSource = grant['value_source'] as String?;
    int immunityValue = 0;
    String? dynamicImmunity;

    if (valueSource == 'level') {
      // Level-scaled immunity
      dynamicImmunity = 'level';
    } else if (valueSource == 'highest_characteristic') {
      // Resolve highest characteristic at apply-time
      immunityValue = await _getHighestCharacteristic(heroId);
    } else {
      // Static value
      immunityValue = (grant['value'] as num?)?.toInt() ?? 0;
    }

    await _resistanceService.addResistanceEntry(
      heroId: heroId,
      damageType: damageType,
      sourceType: 'title',
      sourceId: titleId,
      immunity: immunityValue,
      dynamicImmunity: dynamicImmunity,
    );
  }

  /// Read the hero's five characteristics and return the highest value.
  Future<int> _getHighestCharacteristic(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    int highest = 0;
    for (final key in ['stats.might', 'stats.agility', 'stats.reason', 'stats.intuition', 'stats.presence']) {
      final row = values.firstWhereOrNull((v) => v.key == key);
      if (row != null) {
        final v = row.value ?? int.tryParse(row.textValue ?? '') ?? 0;
        if (v > highest) highest = v;
      }
    }
    return highest;
  }

  /// Save a damage type choice for a title's damage_immunity grant.
  Future<void> setDamageTypeChoice({
    required String heroId,
    required String titleId,
    required String damageType,
  }) async {
    final existing = await _config.getConfigValue(heroId, _kDamageTypeChoicesKey)
        ?? <String, dynamic>{};
    existing[titleId] = damageType;
    await _config.setConfigValue(heroId: heroId, key: _kDamageTypeChoicesKey, value: existing);
  }

  /// Get the stored damage type choice for a title.
  Future<String?> getDamageTypeChoice({
    required String heroId,
    required String titleId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kDamageTypeChoicesKey);
    return raw?[titleId] as String?;
  }

  /// Get all stored damage type choices for a hero.
  Future<Map<String, String>> getAllDamageTypeChoices({
    required String heroId,
  }) async {
    final raw = await _config.getConfigValue(heroId, _kDamageTypeChoicesKey);
    if (raw == null) return {};
    return Map<String, String>.from(
      raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}
