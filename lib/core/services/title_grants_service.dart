import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart';
import '../models/canonical_grant_model.dart';
import '../models/hero_mutation_model.dart';
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'ability_resolver_service.dart';
import 'hero_config_service.dart';
import 'hero_mutation_service.dart';

/// Config key for storing characteristic choice selections per title.
/// Value shape: `{ "<titleId>": "<characteristic>" }` (e.g. `{ "demigod": "might" }`)
const _kCharChoicesKey = HeroConfigKeys.titleCharacteristicChoices;

/// Config key for storing ancestry trait selections per title benefit.
/// Value shape: `{ "<titleId>": ["traitId1", "traitId2"] }`
const _kAncestryTraitsKey = HeroConfigKeys.titleAncestryTraits;

/// Config key for storing ancestry trait sub-choices (immunity, ability pick).
/// Value shape: `{ "<titleId>.<traitId>": "<chosenValue>" }`
const _kAncestryTraitChoicesKey = HeroConfigKeys.titleAncestryTraitChoices;

/// Config key for storing skill choices for title grants.
/// Value shape: `{ "<titleId>__<tag>": "skillId" }` or `{ "<titleId>": ["skillId1", ...] }`
const _kSkillChoicesKey = HeroConfigKeys.titleSkillChoices;

/// Config key for storing language choices for title grants.
/// Value shape: `{ "<titleId>": ["langId1", "langId2"] }`
const _kLanguageChoicesKey = HeroConfigKeys.titleLanguageChoices;

/// Config key for storing heroic ability choice for title grants.
/// Value shape: `{ "<titleId>": "abilityId" }`
const _kHeroicAbilityChoicesKey = HeroConfigKeys.titleHeroicAbilityChoices;

/// Config key for storing damage type choices for damage_immunity grants.
/// Value shape: `{ "<titleId>": "damageType" }`
const _kDamageTypeChoicesKey = HeroConfigKeys.titleDamageTypeChoices;

/// Service to handle title grant processing.
///
/// Titles can grant abilities through their selected benefit, plus additional
/// grants such as stat modifications (renown, wealth, characteristic increases),
/// skills, and languages.
class TitleGrantsService {
  TitleGrantsService(this._db, {HeroMutationService? mutations})
      : _entries = HeroEntryRepository(_db),
        _abilityResolver = AbilityResolverService(_db),
        _config = HeroConfigService(_db),
        _mutations = mutations ?? HeroMutationService(_db);

  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final AbilityResolverService _abilityResolver;
  final HeroConfigService _config;
  final HeroMutationService _mutations;

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
    if (benefits == null || benefitIndex < 0 || benefitIndex >= benefits.length)
      return null;

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

  HeroSource _titleSource(String titleId) => HeroSource(
        sourceType: HeroEntrySourceTypes.title,
        sourceId: titleId,
      );

  Future<void> _addTitleEntry({
    required String heroId,
    required String titleId,
    required String entryType,
    required String entryId,
    Map<String, dynamic>? payload,
  }) async {
    final normalizedEntryId = entryId.trim();
    if (normalizedEntryId.isEmpty) return;

    await _mutations.addContentEntry(
      heroId: heroId,
      source: _titleSource(titleId),
      grant: ResolvedGrant(
        entryType: entryType,
        entryId: normalizedEntryId,
        payload: payload,
      ),
    );
  }

  Future<void> _replaceTitleEntries({
    required String heroId,
    required String titleId,
    required String entryType,
    required Iterable<String> entryIds,
  }) {
    return _mutations.replaceContentEntries(
      heroId: heroId,
      source: _titleSource(titleId),
      entryType: entryType,
      entryIds: entryIds,
    );
  }

  Future<void> _saveConfigMap({
    required String heroId,
    required String key,
    required Map<String, dynamic> value,
  }) {
    return _mutations.saveConfigChoice(
      heroId: heroId,
      key: key,
      value: value,
    );
  }

  static const List<String> _titleChoiceConfigKeys = [
    _kCharChoicesKey,
    _kAncestryTraitsKey,
    _kAncestryTraitChoicesKey,
    _kSkillChoicesKey,
    _kLanguageChoicesKey,
    _kHeroicAbilityChoicesKey,
    _kDamageTypeChoicesKey,
  ];

  Future<void> _filterTitleChoiceConfig({
    required String heroId,
    required bool Function(String titleId) keepTitle,
  }) async {
    for (final key in _titleChoiceConfigKeys) {
      final existing = await _config.getConfigValue(heroId, key);
      if (existing == null || existing.isEmpty) continue;

      final filtered = <String, dynamic>{};
      for (final entry in existing.entries) {
        if (keepTitle(_titleIdFromChoiceKey(entry.key))) {
          filtered[entry.key] = entry.value;
        }
      }

      if (const DeepCollectionEquality().equals(existing, filtered)) {
        continue;
      }

      if (filtered.isEmpty) {
        await _mutations.removeConfigChoice(heroId: heroId, key: key);
      } else {
        await _saveConfigMap(heroId: heroId, key: key, value: filtered);
      }
    }
  }

  String _titleIdFromChoiceKey(String key) {
    final taggedIndex = key.indexOf('__');
    if (taggedIndex > 0) return key.substring(0, taggedIndex);

    final subChoiceIndex = key.indexOf('.');
    if (subChoiceIndex > 0) return key.substring(0, subChoiceIndex);

    return key;
  }

  Set<String> _selectionTitleIds(List<String> selectedTitleIds) {
    return {
      for (final selection in selectedTitleIds)
        if (selection.split(':').length == 2) selection.split(':').first.trim(),
    }..remove('');
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
    final selectedTitleIdSet = _selectionTitleIds(selectedTitleIds);

    // Clear all existing title-granted entries
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.title,
      recomputeAggregates: false,
    );

    await _filterTitleChoiceConfig(
      heroId: heroId,
      keepTitle: (titleId) => selectedTitleIdSet.contains(titleId),
    );

    // Load stored characteristic choices
    final charChoices =
        await _config.getConfigValue(heroId, _kCharChoicesKey) ??
            <String, dynamic>{};

    for (final selection in selectedTitleIds) {
      final parts = selection.split(':');
      if (parts.length != 2) continue;

      final titleId = parts[0].trim();
      if (titleId.isEmpty) continue;
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
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.ability,
            entryId: abilityId,
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
    await _mutations.recomputeAggregates(heroId);
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
    if (_looksLikeCanonicalGrantJson(grant)) {
      final canonicalGrants = CanonicalGrant.parseList(
        grant,
        defaultSource: grantSource,
      );
      for (final canonicalGrant in canonicalGrants) {
        await _applyCanonicalGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: canonicalGrant,
          charChoices: charChoices,
          grantSource: grantSource,
        );
      }
      return;
    }

    final type = grant['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'renown':
      case 'wealth':
        final value = (grant['value'] as num?)?.toInt() ?? 0;
        if (value == 0) return;
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: HeroEntryTypes.statMod,
          entryId: type, // 'renown' or 'wealth'
          payload: {
            'mods': [
              {'value': value, 'source': grantSource},
            ],
          },
        );

      case 'characteristic_increase':
        final choices =
            (grant['choices'] as List?)?.whereType<String>().toList() ?? [];
        final value = (grant['value'] as num?)?.toInt() ?? 1;
        // Use the tag (if present) to disambiguate multiple char grants on one title
        final tag = grant['tag'] as String?;
        final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
        final chosen = charChoices[choiceKey] as String?;

        if (chosen != null && choices.contains(chosen)) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.statMod,
            entryId: chosen,
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
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: HeroEntryTypes.statMod,
          entryId: 'followers_cap',
          payload: {
            'mods': [
              {'value': value, 'source': grantSource},
            ],
          },
        );

      case 'languages':
        final specific =
            (grant['specific'] as List?)?.whereType<String>().toList();
        if (specific != null && specific.isNotEmpty) {
          await _replaceTitleEntries(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.language,
            entryIds: specific,
          );
        }
        // Non-specific language grants (count only) — apply stored choices.
        final langCount = (grant['count'] as num?)?.toInt() ?? 0;
        if (specific == null && langCount > 0) {
          final langChoices =
              await _config.getConfigValue(heroId, _kLanguageChoicesKey) ??
                  <String, dynamic>{};
          final chosen =
              (langChoices[titleId] as List?)?.whereType<String>().toList() ??
                  [];
          if (chosen.isNotEmpty) {
            await _replaceTitleEntries(
              heroId: heroId,
              titleId: titleId,
              entryType: HeroEntryTypes.language,
              entryIds: chosen.take(langCount).toList(),
            );
          }
        }

      case 'skill_choice':
        // Skill grants with a specific single skill are auto-applied.
        final specificSkill = grant['skill'] as String?;
        if (specificSkill != null) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.skill,
            entryId: specificSkill,
          );
        }
        // Group-based or unconstrained skill choices — apply stored choices.
        if (specificSkill == null) {
          final skillChoices =
              await _config.getConfigValue(heroId, _kSkillChoicesKey) ??
                  <String, dynamic>{};
          final tag = grant['tag'] as String?;
          final group = grant['group'] as String?;
          final choiceKey = tag != null
              ? '${titleId}__$tag'
              : (group != null ? '${titleId}__$group' : titleId);
          final count = (grant['count'] as num?)?.toInt() ?? 1;
          final raw = skillChoices[choiceKey];
          final chosen = raw is List
              ? raw.whereType<String>().toList()
              : raw is String
                  ? [raw]
                  : <String>[];
          if (chosen.isNotEmpty) {
            await _replaceTitleEntries(
              heroId: heroId,
              titleId: titleId,
              entryType: HeroEntryTypes.skill,
              entryIds: chosen.take(count).toList(),
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
        final abilityChoices =
            await _config.getConfigValue(heroId, _kHeroicAbilityChoicesKey) ??
                <String, dynamic>{};
        final chosenAbilityId = abilityChoices[titleId] as String?;
        if (chosenAbilityId != null && chosenAbilityId.isNotEmpty) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.ability,
            entryId: chosenAbilityId,
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
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: HeroEntryTypes.itemPrerequisite,
          entryId: '${titleId}_${category}_$tag',
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
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.conditionImmunity,
            entryId: condition,
            payload: {'titleName': titleName, 'grantSource': grantSource},
          );
        }
    }
  }

  bool _looksLikeCanonicalGrantJson(dynamic json) {
    if (json is List) {
      return json.any((item) => item is Map && _mapContainsKey(item, 'kind'));
    }
    if (json is! Map) return false;

    final map = _stringKeyedMap(json);
    if (map['schema'] == canonicalGrantSchemaId) return true;
    if (map.containsKey('kind')) return true;

    final grants = map['grants'];
    return grants is List &&
        grants.any((item) => item is Map && _mapContainsKey(item, 'kind'));
  }

  bool _mapContainsKey(Map<dynamic, dynamic> map, String key) {
    return map.keys.any((candidate) => candidate.toString() == key);
  }

  Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> map) {
    return {for (final entry in map.entries) entry.key.toString(): entry.value};
  }

  Future<void> _applyCanonicalGrant({
    required String heroId,
    required String titleId,
    required String titleName,
    required CanonicalGrant grant,
    required Map<String, dynamic> charChoices,
    required String grantSource,
  }) async {
    switch (grant) {
      case CanonicalEntryGrant():
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: grant.entryType,
          entryId: grant.entryId,
          payload: {
            'titleName': titleName,
            'grantSource': grantSource,
            ...?grant.payload,
          },
        );

      case CanonicalStatModGrant():
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: HeroEntryTypes.statMod,
          entryId: grant.entryId ?? grant.stat,
          payload: {
            'mods': grant.modifications
                .map((modification) => modification.toJson())
                .toList(),
          },
        );

      case CanonicalResistanceGrant():
        if (!grant.hasEffect) return;
        await _mutations.addResistance(
          heroId: heroId,
          source: _titleSource(titleId),
          damageType: grant.damageType,
          immunity: grant.immunity,
          weakness: grant.weakness,
          dynamicImmunity: grant.dynamicImmunity,
          dynamicWeakness: grant.dynamicWeakness,
          immunityPerEchelon: grant.immunityPerEchelon,
          weaknessPerEchelon: grant.weaknessPerEchelon,
          recompute: false,
        );

      case CanonicalChoiceGrant():
        await _applyCanonicalChoiceGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: grant,
          charChoices: charChoices,
          grantSource: grantSource,
        );

      case CanonicalTokenGrant():
      case CanonicalTreasureGrant():
      case CanonicalEquipmentBonusesGrant():
        return;
    }
  }

  Future<void> _applyCanonicalChoiceGrant({
    required String heroId,
    required String titleId,
    required String titleName,
    required CanonicalChoiceGrant grant,
    required Map<String, dynamic> charChoices,
    required String grantSource,
  }) async {
    switch (grant.choiceType) {
      case 'characteristic':
        final tag = _payloadString(grant, 'tag');
        final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
        final chosen = charChoices[choiceKey] as String?;
        final choices = grant.options;
        if (chosen != null && (choices.isEmpty || choices.contains(chosen))) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.statMod,
            entryId: chosen,
            payload: {
              'mods': [
                {
                  'value': _payloadInt(grant, 'value') ?? 1,
                  'source': grantSource,
                },
              ],
            },
          );
        }

      case 'skill':
        final skillChoices =
            await _config.getConfigValue(heroId, _kSkillChoicesKey) ??
                <String, dynamic>{};
        final tag = _payloadString(grant, 'tag');
        final group = grant.groups.firstOrNull;
        final choiceKey = tag != null
            ? '${titleId}__$tag'
            : (group != null ? '${titleId}__$group' : titleId);
        final raw = skillChoices[choiceKey];
        final chosen = raw is List
            ? raw.whereType<String>().toList()
            : raw is String
                ? [raw]
                : <String>[];
        if (chosen.isNotEmpty) {
          await _replaceTitleEntries(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.skill,
            entryIds: chosen.take(grant.count).toList(),
          );
        }

      case 'language':
        final languageChoices =
            await _config.getConfigValue(heroId, _kLanguageChoicesKey) ??
                <String, dynamic>{};
        final chosen =
            (languageChoices[titleId] as List?)?.whereType<String>().toList() ??
                [];
        if (chosen.isNotEmpty) {
          await _replaceTitleEntries(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.language,
            entryIds: chosen.take(grant.count).toList(),
          );
        }

      case 'ability':
        final abilityChoices = await _config.getConfigValue(
              heroId,
              _kHeroicAbilityChoicesKey,
            ) ??
            <String, dynamic>{};
        final chosenAbilityId = abilityChoices[titleId] as String?;
        if (chosenAbilityId != null && chosenAbilityId.isNotEmpty) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.ability,
            entryId: chosenAbilityId,
            payload: {
              'titleName': titleName,
              'grantType': 'heroic_ability_choice',
              ...?grant.payload,
            },
          );
        }

      case 'ancestry_trait':
        final ancestry = _payloadString(grant, 'ancestry');
        if (ancestry == null) return;
        await _applyAncestryPointsGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: {
            'ancestry': ancestry,
            'value': _payloadInt(grant, 'points') ?? grant.count,
          },
          grantSource: grantSource,
        );

      case 'damage_type':
        await _applyDamageImmunityGrant(
          heroId: heroId,
          titleId: titleId,
          titleName: titleName,
          grant: {
            'damage_type': 'choose',
            'damage_type_options': grant.options,
            if (_payloadString(grant, 'value_source') != null)
              'value_source': _payloadString(grant, 'value_source'),
            if (_payloadInt(grant, 'value') != null)
              'value': _payloadInt(grant, 'value'),
            if (_payloadString(grant, 'note') != null)
              'note': _payloadString(grant, 'note'),
          },
          grantSource: grantSource,
        );
    }
  }

  String? _payloadString(CanonicalChoiceGrant grant, String key) {
    final value = grant.payload?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  int? _payloadInt(CanonicalChoiceGrant grant, String key) {
    final value = grant.payload?[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Save a characteristic choice for a title and re-apply grants.
  Future<void> setCharacteristicChoice({
    required String heroId,
    required String titleId,
    required String characteristic,
    String? tag,
  }) async {
    final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
    final existing = await _config.getConfigValue(heroId, _kCharChoicesKey) ??
        <String, dynamic>{};
    existing[choiceKey] = characteristic;
    await _saveConfigMap(
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
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.title,
    );
    await _filterTitleChoiceConfig(
      heroId: heroId,
      keepTitle: (_) => false,
    );
  }

  /// Remove grants for a specific title.
  Future<void> removeTitleGrantsForTitle({
    required String heroId,
    required String titleId,
  }) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _titleSource(titleId),
    );
    await _filterTitleChoiceConfig(
      heroId: heroId,
      keepTitle: (choiceTitleId) => choiceTitleId != titleId,
    );
  }

  /// Get all abilities granted by titles for a hero.
  Future<List<String>> getGrantedAbilities({
    required String heroId,
  }) async {
    final all =
        await _entries.listEntriesByType(heroId, HeroEntryTypes.ability);
    return all
        .where((e) => e.sourceType == HeroEntrySourceTypes.title)
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
    final storedTraits =
        await _config.getConfigValue(heroId, _kAncestryTraitsKey) ??
            <String, dynamic>{};
    final selectedTraitIds =
        (storedTraits[titleId] as List?)?.whereType<String>().toList() ?? [];
    if (selectedTraitIds.isEmpty) return;

    final storedSubChoices =
        await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey) ??
            <String, dynamic>{};

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
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.ability,
            entryId: abilityId,
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
            await _addTitleEntry(
              heroId: heroId,
              titleId: titleId,
              entryType: HeroEntryTypes.ability,
              entryId: abilityId,
              payload: {'titleName': titleName, 'traitName': traitName},
            );
          }
        }
      }

      // condition_immunity → condition immunity entry
      final condImmunity = traitMap['condition_immunity'] as String?;
      if (condImmunity != null && condImmunity.isNotEmpty) {
        await _addTitleEntry(
          heroId: heroId,
          titleId: titleId,
          entryType: HeroEntryTypes.conditionImmunity,
          entryId: condImmunity,
          payload: {'titleName': titleName, 'traitName': traitName},
        );
      }

      // set_base_stat_if_not_already_higher → stat_mod entry
      final setBase = traitMap['set_base_stat_if_not_already_higher'];
      if (setBase is Map) {
        final stat = setBase['stat'] as String?;
        final value = (setBase['value'] as num?)?.toInt();
        if (stat != null && value != null) {
          await _addTitleEntry(
            heroId: heroId,
            titleId: titleId,
            entryType: HeroEntryTypes.statMod,
            entryId: stat,
            payload: {
              'mods': [
                {
                  'value': value,
                  'source': '$traitName ($grantSource)',
                  'mode': 'set_base'
                },
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
            await _addTitleEntry(
              heroId: heroId,
              titleId: titleId,
              entryType: HeroEntryTypes.statMod,
              entryId: '$stat.$effectiveType',
              payload: {
                'mods': [
                  {
                    'value': increase['value'],
                    'source': '$traitName ($grantSource)'
                  },
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
    final existing =
        await _config.getConfigValue(heroId, _kAncestryTraitsKey) ??
            <String, dynamic>{};
    existing[titleId] = traitIds;
    await _saveConfigMap(
      heroId: heroId,
      key: _kAncestryTraitsKey,
      value: existing,
    );
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
    final existing =
        await _config.getConfigValue(heroId, _kAncestryTraitChoicesKey) ??
            <String, dynamic>{};
    existing['$titleId.$traitId'] = value;
    await _saveConfigMap(
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
    final choiceKey = tag != null
        ? '${titleId}__$tag'
        : (group != null ? '${titleId}__$group' : titleId);
    final existing = await _config.getConfigValue(heroId, _kSkillChoicesKey) ??
        <String, dynamic>{};
    existing[choiceKey] = skillIds;
    await _saveConfigMap(
      heroId: heroId,
      key: _kSkillChoicesKey,
      value: existing,
    );
  }

  /// Get skill choice(s) for a title grant.
  Future<List<String>> getSkillChoice({
    required String heroId,
    required String titleId,
    String? tag,
    String? group,
  }) async {
    final choiceKey = tag != null
        ? '${titleId}__$tag'
        : (group != null ? '${titleId}__$group' : titleId);
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
    final existing =
        await _config.getConfigValue(heroId, _kLanguageChoicesKey) ??
            <String, dynamic>{};
    existing[titleId] = languageIds;
    await _saveConfigMap(
      heroId: heroId,
      key: _kLanguageChoicesKey,
      value: existing,
    );
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
    final existing =
        await _config.getConfigValue(heroId, _kHeroicAbilityChoicesKey) ??
            <String, dynamic>{};
    existing[titleId] = abilityId;
    await _saveConfigMap(
      heroId: heroId,
      key: _kHeroicAbilityChoicesKey,
      value: existing,
    );
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
      final choices =
          await _config.getConfigValue(heroId, _kDamageTypeChoicesKey) ??
              <String, dynamic>{};
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

    await _mutations.addResistance(
      heroId: heroId,
      source: _titleSource(titleId),
      damageType: damageType,
      immunity: immunityValue,
      dynamicImmunity: dynamicImmunity,
      recompute: false,
    );
  }

  /// Read the hero's five characteristics and return the highest value.
  Future<int> _getHighestCharacteristic(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    int highest = 0;
    for (final key in [
      'stats.might',
      'stats.agility',
      'stats.reason',
      'stats.intuition',
      'stats.presence'
    ]) {
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
    final existing =
        await _config.getConfigValue(heroId, _kDamageTypeChoicesKey) ??
            <String, dynamic>{};
    existing[titleId] = damageType;
    await _saveConfigMap(
      heroId: heroId,
      key: _kDamageTypeChoicesKey,
      value: existing,
    );
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
