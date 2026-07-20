import 'dart:convert';

import '../db/app_database.dart';
import '../models/canonical_grant_model.dart';
import '../models/hero_mutation_model.dart';
import '../storage/hero_storage_contract.dart';
import 'ability_resolver_service.dart';
import 'hero_config_service.dart';
import 'hero_mutation_service.dart';

/// Represents a parsed perk grant
sealed class PerkGrant {
  const PerkGrant();

  /// Parse a grant from JSON data
  static PerkGrant? fromJson(dynamic json) {
    if (json == null) return null;

    if (_looksLikeCanonicalGrantJson(json)) {
      return _fromCanonicalGrantJson(json);
    }

    // Handle list of grants (e.g., [{"ability": "Friend Catapult"}])
    if (json is List) {
      if (json.isEmpty) return null;
      // For now, handle single-item lists
      if (json.length == 1) {
        return fromJson(json.first);
      }
      // Multiple grants in a list
      final grants =
          json.map((e) => fromJson(e)).whereType<PerkGrant>().toList();
      if (grants.isEmpty) return null;
      if (grants.length == 1) return grants.first;
      return MultiGrant(grants);
    }

    if (json is! Map) return null;

    // Check for ability grant
    if (json.containsKey('ability')) {
      return AbilityGrant(json['ability'] as String);
    }

    // Check for creature grant (save for later)
    if (json.containsKey('creature')) {
      return CreatureGrant(json['creature'] as String);
    }

    // Check for skill grant
    if (json.containsKey('skill')) {
      final skillData = json['skill'];
      if (skillData is Map) {
        final group = skillData['group'] as String?;
        final count = skillData['count'];

        if (count == 'one_owned') {
          // User picks one skill they already have from that group
          return SkillFromOwnedGrant(group: group ?? '');
        } else {
          // User picks new skill(s) from that group
          final pickCount = count is int
              ? count
              : int.tryParse(count?.toString() ?? '1') ?? 1;
          return SkillPickGrant(group: group ?? '', count: pickCount);
        }
      }
    }

    // Check for languages grant
    if (json.containsKey('languages')) {
      final count = json['languages'];
      final pickCount =
          count is int ? count : int.tryParse(count?.toString() ?? '1') ?? 1;
      return LanguageGrant(count: pickCount);
    }

    return null;
  }

  static bool _looksLikeCanonicalGrantJson(dynamic json) {
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

  static bool _mapContainsKey(Map<dynamic, dynamic> map, String key) {
    return map.keys.any((candidate) => candidate.toString() == key);
  }

  static Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> map) {
    return {for (final entry in map.entries) entry.key.toString(): entry.value};
  }

  static PerkGrant? _fromCanonicalGrantJson(dynamic json) {
    try {
      final grants = CanonicalGrant.parseList(json);
      return _fromCanonicalGrants(grants);
    } catch (_) {
      return null;
    }
  }

  static PerkGrant? _fromCanonicalGrants(List<CanonicalGrant> grants) {
    final parsed = grants
        .map(_fromCanonicalGrant)
        .whereType<PerkGrant>()
        .toList(growable: false);
    if (parsed.isEmpty) return null;
    if (parsed.length == 1) return parsed.single;
    return MultiGrant(parsed);
  }

  static PerkGrant? _fromCanonicalGrant(CanonicalGrant grant) {
    switch (grant) {
      case CanonicalEntryGrant(
          :final entryType,
          :final entryId,
          :final label,
          :final payload,
        ):
        if (entryType == HeroEntryTypes.ability) {
          return AbilityGrant(
            _canonicalDisplayName(
              entryId: entryId,
              label: label,
              payload: payload,
            ),
            abilityId: entryId,
          );
        }
        break;
      case CanonicalChoiceGrant(
          :final choiceKey,
          :final choiceType,
          :final count,
          :final groups,
          :final options,
          :final allowOwned,
          :final label,
        ):
        final normalizedChoiceType = choiceType.toLowerCase();
        if (normalizedChoiceType == 'skill') {
          final group = groups.isNotEmpty ? groups.first : '';
          if (allowOwned) {
            return SkillFromOwnedGrant(group: group);
          }
          return SkillPickGrant(group: group, count: count);
        }
        if (normalizedChoiceType == 'language') {
          return LanguageGrant(count: count);
        }
        if (normalizedChoiceType == 'creature') {
          final creatureName = options.isNotEmpty
              ? options.first
              : (label?.trim().isNotEmpty == true ? label! : choiceKey);
          return CreatureGrant(creatureName);
        }
        break;
      default:
        break;
    }

    return null;
  }

  static String _canonicalDisplayName({
    required String entryId,
    required String? label,
    required Map<String, dynamic>? payload,
  }) {
    final payloadName = payload?['name']?.toString().trim();
    if (payloadName != null && payloadName.isNotEmpty) return payloadName;

    final labelText = label?.trim();
    if (labelText != null && labelText.isNotEmpty) return labelText;

    return entryId;
  }
}

/// Grant that provides an ability
class AbilityGrant extends PerkGrant {
  final String abilityName;
  final String? abilityId;
  const AbilityGrant(this.abilityName, {this.abilityId});
}

/// Grant that provides a creature (e.g., Familiar) - for later implementation
class CreatureGrant extends PerkGrant {
  final String creatureName;
  const CreatureGrant(this.creatureName);
}

/// Grant that requires user to choose one skill they already own from a group
class SkillFromOwnedGrant extends PerkGrant {
  final String group;
  const SkillFromOwnedGrant({required this.group});
}

/// Grant that lets user pick new skill(s) from a group
class SkillPickGrant extends PerkGrant {
  final String group;
  final int count;
  const SkillPickGrant({required this.group, required this.count});
}

/// Grant that lets user pick new language(s)
class LanguageGrant extends PerkGrant {
  final int count;
  const LanguageGrant({required this.count});
}

/// Multiple grants in one perk
class MultiGrant extends PerkGrant {
  final List<PerkGrant> grants;
  const MultiGrant(this.grants);
}

/// Service to handle perk grant choices.
///
/// Uses constructor injection for database dependency.
class PerkGrantsService {
  PerkGrantsService(this._db, {HeroMutationService? mutations})
      : _mutations = mutations ?? HeroMutationService(_db),
        _abilityResolver = AbilityResolverService(_db),
        _config = HeroConfigService(_db);

  final AppDatabase _db;
  final HeroMutationService _mutations;
  final AbilityResolverService _abilityResolver;
  final HeroConfigService _config;

  /// Get all skills from the database.
  Future<List<Component>> loadSkills() async {
    return _abilityResolver.getAllSkills();
  }

  /// Get all languages from the database.
  Future<List<Component>> loadLanguages() async {
    return _abilityResolver.getAllLanguages();
  }

  /// Get skills by group from the database.
  Future<List<Component>> getSkillsByGroup(String group) async {
    return _abilityResolver.getSkillsByGroup(group);
  }

  // --- Hero-specific grant choice storage ---

  static const _kLegacyGrantChoicePrefix = HeroValueKeys.legacyPerkGrantPrefix;

  static String _grantSelectionsKey(String perkId) =>
      HeroConfigKeys.perkSelections(perkId);

  /// Save a perk grant choice for a hero
  Future<void> saveGrantChoice({
    required String heroId,
    required String perkId,
    required String grantType,
    required List<String> chosenIds,
  }) async {
    final selections = await getAllGrantChoicesForPerk(
      heroId: heroId,
      perkId: perkId,
    );
    selections[grantType] = List<String>.from(chosenIds);

    await _mutations.saveConfigChoice(
      heroId: heroId,
      key: _grantSelectionsKey(perkId),
      value: _encodeSelections(selections),
    );
    await _clearLegacyGrantChoicesForPerk(heroId, perkId);
  }

  /// Get a perk grant choice for a hero
  Future<List<String>> getGrantChoice({
    required String heroId,
    required String perkId,
    required String grantType,
  }) async {
    final selections = await getAllGrantChoicesForPerk(
      heroId: heroId,
      perkId: perkId,
    );
    return selections[grantType] ?? [];
  }

  /// Get all grant choices for a hero (for a specific perk)
  Future<Map<String, List<String>>> getAllGrantChoicesForPerk({
    required String heroId,
    required String perkId,
  }) async {
    final legacySelections = await _loadLegacyGrantChoicesForPerk(
      heroId,
      perkId,
    );
    final configSelections = await _loadConfigGrantChoicesForPerk(
      heroId,
      perkId,
    );

    return {
      ...legacySelections,
      ...configSelections,
    };
  }

  Map<String, dynamic> _encodeSelections(
    Map<String, List<String>> selections,
  ) {
    return {
      for (final entry in selections.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  Future<Map<String, List<String>>> _loadConfigGrantChoicesForPerk(
    String heroId,
    String perkId,
  ) async {
    final config = await _config.getConfigValue(
      heroId,
      _grantSelectionsKey(perkId),
    );
    return _parseSelections(config);
  }

  Future<Map<String, List<String>>> _loadLegacyGrantChoicesForPerk(
    String heroId,
    String perkId,
  ) async {
    final prefix = '$_kLegacyGrantChoicePrefix$perkId.';
    final values = await _db.getHeroValues(heroId);
    final result = <String, List<String>>{};

    for (final value in values) {
      if (!value.key.startsWith(prefix)) continue;

      final grantType = value.key.substring(prefix.length);
      final raw = value.jsonValue ?? value.textValue;
      if (raw == null) continue;

      result[grantType] = _parseChoiceList(raw);
    }

    return result;
  }

  Map<String, List<String>> _parseSelections(dynamic rawSelections) {
    if (rawSelections is! Map) return {};

    final result = <String, List<String>>{};
    for (final entry in rawSelections.entries) {
      final key = entry.key?.toString();
      if (key == null || key.isEmpty) continue;
      result[key] = _parseChoiceList(entry.value);
    }
    return result;
  }

  List<String> _parseChoiceList(dynamic rawValue) {
    if (rawValue is String) {
      try {
        return _parseChoiceList(jsonDecode(rawValue));
      } catch (_) {
        return rawValue.isEmpty ? [] : [rawValue];
      }
    }

    if (rawValue is Map && rawValue['list'] is List) {
      return _stringList(rawValue['list'] as List);
    }

    if (rawValue is List) {
      return _stringList(rawValue);
    }

    return [];
  }

  List<String> _stringList(List<dynamic> values) {
    return values.map((value) => value.toString()).toList();
  }

  /// Get hero's current skills
  Future<List<String>> getHeroSkillIds({
    required String heroId,
  }) async {
    return await _db.getHeroComponentIds(heroId, 'skill');
  }

  /// Get hero's current languages
  Future<List<String>> getHeroLanguageIds({
    required String heroId,
  }) async {
    return await _db.getHeroComponentIds(heroId, 'language');
  }

  /// Ensure all perk grants are applied for a hero.
  /// This is useful when viewing the abilities sheet to make sure any
  /// perk-granted abilities are properly registered in the hero's abilities.
  Future<void> ensureAllPerkGrantsApplied({
    required String heroId,
  }) async {
    // Get all perk IDs for this hero
    final perkIds = await _db.getHeroComponentIds(heroId, 'perk');
    if (perkIds.isEmpty) return;

    // Get all perk components
    final allComponents = await _db.getAllComponents();
    final perkComponents = allComponents
        .where((c) => c.type == 'perk' && perkIds.contains(c.id))
        .toList();

    // Apply grants for each perk
    for (final perkComp in perkComponents) {
      try {
        Map<String, dynamic> data = {};
        if (perkComp.dataJson.isNotEmpty) {
          data = jsonDecode(perkComp.dataJson) as Map<String, dynamic>;
        }
        final grantsJson = data['grants'];
        if (grantsJson != null) {
          await applyPerkGrants(
            heroId: heroId,
            perkId: perkComp.id,
            grantsJson: grantsJson,
          );
        }
      } catch (_) {
        // Skip if perk data is invalid
      }
    }
  }

  // =========================================================================
  // Methods to persist perk grants to hero component collections
  // =========================================================================

  /// Apply all grants from a perk when it is selected.
  /// This adds any ability grants to the hero's ability components.
  Future<void> applyPerkGrants({
    required String heroId,
    required String perkId,
    required dynamic grantsJson,
  }) async {
    final grant = PerkGrant.fromJson(grantsJson);
    if (grant == null) {
      await _replaceHeroAbilities(heroId, perkId, const []);
      await _clearLegacyPerkAbilityGrants(heroId, perkId);
      return;
    }

    final abilityGrants = <AbilityGrant>[];
    _collectAbilityGrants(grant, abilityGrants);

    if (abilityGrants.isEmpty) {
      await _replaceHeroAbilities(heroId, perkId, const []);
      await _clearLegacyPerkAbilityGrants(heroId, perkId);
      return;
    }

    final abilityIds = await _resolveAbilityGrantIds(abilityGrants);

    await _replaceHeroAbilities(heroId, perkId, abilityIds);
    await _clearLegacyPerkAbilityGrants(heroId, perkId);
  }

  /// Remove all grants from a perk when it is deselected.
  Future<void> removePerkGrants({
    required String heroId,
    required String perkId,
    bool removePerkEntry = true,
  }) async {
    await _clearLegacyPerkAbilityGrants(heroId, perkId);

    // Clear all grant choices for this perk
    await _clearAllGrantChoicesForPerk(heroId, perkId);

    // Remove all abilities from this specific perk source.
    await _removeFromHeroAbilities(heroId, perkId);

    // Remove all languages from hero that were granted by this perk
    await _removeFromHeroLanguages(heroId, perkId);

    // Remove all skill picks from hero (not skill_owned, those are already owned)
    await _removeFromHeroSkills(heroId, perkId);

    if (removePerkEntry) {
      // Compatibility path for callers that own the selected perk itself.
      await _mutations.removeEntryById(
        heroId: heroId,
        entryType: HeroEntryTypes.perk,
        entryId: perkId,
        recomputeAggregates: false,
      );
    }
  }

  /// Save a perk grant choice and also update hero components.
  Future<void> saveGrantChoiceAndApply({
    required String heroId,
    required String perkId,
    required String grantType,
    required List<String> chosenIds,
  }) async {
    // Save the new choices
    await saveGrantChoice(
      heroId: heroId,
      perkId: perkId,
      grantType: grantType,
      chosenIds: chosenIds,
    );

    // Apply changes to hero entries
    // For languages and skills, we remove all and re-add all to ensure consistency
    // This handles multi-slot selections correctly (e.g., Linguist grants 2 languages)
    if (grantType == 'language') {
      // Remove all language entries from this perk
      await _removeFromHeroLanguages(heroId, perkId);
      // Add all current choices
      if (chosenIds.isNotEmpty) {
        await _addToHeroLanguages(heroId, perkId, chosenIds);
      }
    } else if (grantType == 'skill_pick') {
      // Remove all skill entries from this perk
      await _removeFromHeroSkills(heroId, perkId);
      // Add all current choices
      if (chosenIds.isNotEmpty) {
        await _addToHeroSkills(heroId, perkId, chosenIds);
      }
    }
    // skill_owned doesn't add new skills, just tracks selection
  }

  // --- Private helpers for ability grants ---

  void _collectAbilityGrants(
    PerkGrant grant,
    List<AbilityGrant> abilityGrants,
  ) {
    switch (grant) {
      case AbilityGrant():
        abilityGrants.add(grant);
      case MultiGrant(:final grants):
        for (final g in grants) {
          _collectAbilityGrants(g, abilityGrants);
        }
      default:
        break;
    }
  }

  Future<List<String>> _resolveAbilityGrantIds(
    List<AbilityGrant> grants,
  ) async {
    final resolvedIds = <String>[];
    final seenIds = <String>{};
    final namesToResolve = <String>[];

    void addId(String id) {
      final normalizedId = id.trim();
      if (normalizedId.isEmpty || !seenIds.add(normalizedId)) return;
      resolvedIds.add(normalizedId);
    }

    for (final grant in grants) {
      final abilityId = grant.abilityId?.trim();
      if (abilityId != null && abilityId.isNotEmpty) {
        addId(abilityId);
      } else if (grant.abilityName.trim().isNotEmpty) {
        namesToResolve.add(grant.abilityName);
      }
    }

    if (namesToResolve.isNotEmpty) {
      final resolvedFromNames = await _abilityResolver.resolveAbilityIds(
        namesToResolve,
        sourceType: 'perk',
        ensureInDb: true,
      );
      for (final abilityId in resolvedFromNames) {
        addId(abilityId);
      }
    }

    return resolvedIds;
  }

  Future<void> _clearAllGrantChoicesForPerk(
    String heroId,
    String perkId,
  ) async {
    await _mutations.removeConfigChoice(
      heroId: heroId,
      key: _grantSelectionsKey(perkId),
    );
    await _clearLegacyGrantChoicesForPerk(heroId, perkId);
  }

  Future<void> _clearLegacyGrantChoicesForPerk(
    String heroId,
    String perkId,
  ) async {
    final prefix = '$_kLegacyGrantChoicePrefix$perkId.';
    final values = await _db.getHeroValues(heroId);
    for (final value in values) {
      if (value.key.startsWith(prefix)) {
        await _db.deleteHeroValue(heroId: heroId, key: value.key);
      }
    }
  }

  Future<void> _clearLegacyPerkAbilityGrants(
    String heroId,
    String perkId,
  ) async {
    await _db.deleteHeroValue(
      heroId: heroId,
      key: '${HeroValueKeys.legacyPerkAbilitiesPrefix}$perkId',
    );
  }

  // --- Private helpers for hero components ---

  HeroSource _perkSource(String perkId) => HeroSource(
        sourceType: HeroEntrySourceTypes.perk,
        sourceId: perkId,
      );

  Iterable<ResolvedGrant> _contentGrants(
    String entryType,
    Iterable<String> entryIds,
  ) sync* {
    for (final id in entryIds) {
      final entryId = id.trim();
      if (entryId.isEmpty) continue;
      yield ResolvedGrant(entryType: entryType, entryId: entryId);
    }
  }

  Future<void> _replaceHeroAbilities(
      String heroId, String perkId, List<String> abilityIds) async {
    await _mutations.replaceContentEntries(
      heroId: heroId,
      source: _perkSource(perkId),
      entryType: HeroEntryTypes.ability,
      entryIds: abilityIds,
    );
  }

  Future<void> _removeFromHeroAbilities(
    String heroId,
    String perkId,
  ) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _perkSource(perkId),
      entryType: HeroEntryTypes.ability,
      recomputeAggregates: false,
    );
  }

  Future<void> _addToHeroLanguages(
      String heroId, String perkId, List<String> languageIds) async {
    if (languageIds.isEmpty) return;
    await _mutations.addContentEntries(
      heroId: heroId,
      source: _perkSource(perkId),
      grants: _contentGrants(HeroEntryTypes.language, languageIds),
    );
  }

  /// Removes ALL language entries granted by this perk.
  /// Note: This removes all languages from the perk, not specific ones.
  Future<void> _removeFromHeroLanguages(
    String heroId,
    String perkId,
  ) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _perkSource(perkId),
      entryType: HeroEntryTypes.language,
      recomputeAggregates: false,
    );
  }

  Future<void> _addToHeroSkills(
      String heroId, String perkId, List<String> skillIds) async {
    if (skillIds.isEmpty) return;
    await _mutations.addContentEntries(
      heroId: heroId,
      source: _perkSource(perkId),
      grants: _contentGrants(HeroEntryTypes.skill, skillIds),
    );
  }

  /// Removes ALL skill entries granted by this perk.
  /// Note: This removes all skills from the perk, not specific ones.
  Future<void> _removeFromHeroSkills(
    String heroId,
    String perkId,
  ) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _perkSource(perkId),
      entryType: HeroEntryTypes.skill,
      recomputeAggregates: false,
    );
  }
}
