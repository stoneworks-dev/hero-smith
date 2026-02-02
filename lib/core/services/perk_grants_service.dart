import 'dart:convert';

import '../db/app_database.dart';
import '../repositories/hero_entry_repository.dart';
import 'ability_resolver_service.dart';

/// Represents a parsed perk grant
sealed class PerkGrant {
  const PerkGrant();
  
  /// Parse a grant from JSON data
  static PerkGrant? fromJson(dynamic json) {
    if (json == null) return null;
    
    // Handle list of grants (e.g., [{"ability": "Friend Catapult"}])
    if (json is List) {
      if (json.isEmpty) return null;
      // For now, handle single-item lists
      if (json.length == 1) {
        return fromJson(json.first);
      }
      // Multiple grants in a list
      final grants = json.map((e) => fromJson(e)).whereType<PerkGrant>().toList();
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
          final pickCount = count is int ? count : int.tryParse(count?.toString() ?? '1') ?? 1;
          return SkillPickGrant(group: group ?? '', count: pickCount);
        }
      }
    }
    
    // Check for languages grant
    if (json.containsKey('languages')) {
      final count = json['languages'];
      final pickCount = count is int ? count : int.tryParse(count?.toString() ?? '1') ?? 1;
      return LanguageGrant(count: pickCount);
    }
    
    return null;
  }
}

/// Grant that provides an ability
class AbilityGrant extends PerkGrant {
  final String abilityName;
  const AbilityGrant(this.abilityName);
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
  PerkGrantsService(this._db)
      : _entries = HeroEntryRepository(_db),
        _abilityResolver = AbilityResolverService(_db);
  
  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final AbilityResolverService _abilityResolver;
  
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
  
  /// Key format: perk_grant.<perk_id>.<grant_type>
  static String _grantChoiceKey(String perkId, String grantType) =>
    'perk_grant.$perkId.$grantType';
  
  /// Save a perk grant choice for a hero
  Future<void> saveGrantChoice({
    required String heroId,
    required String perkId,
    required String grantType,
    required List<String> chosenIds,
  }) async {
    final key = _grantChoiceKey(perkId, grantType);
    await _db.upsertHeroValue(
      heroId: heroId,
      key: key,
      jsonMap: {'list': chosenIds},
    );
  }
  
  /// Get a perk grant choice for a hero
  Future<List<String>> getGrantChoice({
    required String heroId,
    required String perkId,
    required String grantType,
  }) async {
    final key = _grantChoiceKey(perkId, grantType);
    final values = await _db.getHeroValues(heroId);
    
    for (final value in values) {
      if (value.key == key) {
        final jsonStr = value.jsonValue;
        if (jsonStr != null) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (map['list'] is List) {
            return (map['list'] as List).cast<String>();
          }
        }
      }
    }
    return [];
  }
  
  /// Get all grant choices for a hero (for a specific perk)
  Future<Map<String, List<String>>> getAllGrantChoicesForPerk({
    required String heroId,
    required String perkId,
  }) async {
    final prefix = 'perk_grant.$perkId.';
    final values = await _db.getHeroValues(heroId);
    final result = <String, List<String>>{};
    
    for (final value in values) {
      if (value.key.startsWith(prefix)) {
        final grantType = value.key.substring(prefix.length);
        final jsonStr = value.jsonValue;
        if (jsonStr != null) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (map['list'] is List) {
            result[grantType] = (map['list'] as List).cast<String>();
          }
        }
      }
    }
    return result;
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
    if (grant == null) return;
    
    final abilityNames = <String>[];
    _collectAbilityNames(grant, abilityNames);
    
    if (abilityNames.isEmpty) return;
    
    // Find ability IDs from the database or perk_abilities.json
    final abilityIds = await _abilityResolver.resolveAbilityIds(
      abilityNames,
      sourceType: 'perk',
      ensureInDb: true,
    );
    if (abilityIds.isEmpty) return;
    
    // Track which abilities came from this perk (legacy, kept for backwards compat)
    await _savePerkAbilityGrants(heroId, perkId, abilityIds);
    
    // Add to hero's ability entries with proper source tracking
    await _addToHeroAbilities(heroId, perkId, abilityIds);
  }
  
  /// Remove all grants from a perk when it is deselected.
  Future<void> removePerkGrants({
    required String heroId,
    required String perkId,
  }) async {
    // Get the abilities that were granted by this perk
    final grantedAbilityIds = await _loadPerkAbilityGrants(heroId, perkId);
    
    // Remove the ability grant tracking
    await _clearPerkAbilityGrants(heroId, perkId);
    
    // Clear all grant choices for this perk
    await _clearAllGrantChoicesForPerk(heroId, perkId);
    
    // Remove abilities from hero (only if not granted by other perks)
    if (grantedAbilityIds.isNotEmpty) {
      await _removeFromHeroAbilities(heroId, grantedAbilityIds, perkId);
    }
    
    // Remove all languages from hero that were granted by this perk
    await _removeFromHeroLanguages(heroId, perkId);
    
    // Remove all skill picks from hero (not skill_owned, those are already owned)
    await _removeFromHeroSkills(heroId, perkId);
    
    // Remove the perk entry itself (regardless of source type - handles career perks too)
    await _entries.removeEntryById(heroId, 'perk', perkId);
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
      heroId: heroId, perkId: perkId, grantType: grantType, chosenIds: chosenIds,
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
  
  void _collectAbilityNames(PerkGrant grant, List<String> names) {
    switch (grant) {
      case AbilityGrant(:final abilityName):
        names.add(abilityName);
      case MultiGrant(:final grants):
        for (final g in grants) {
          _collectAbilityNames(g, names);
        }
      default:
        break;
    }
  }
  
  static const _kPerkAbilitiesPrefix = 'perk_abilities.';
  
  Future<void> _savePerkAbilityGrants(
    String heroId, String perkId, List<String> abilityIds,
  ) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: '$_kPerkAbilitiesPrefix$perkId',
      jsonMap: {'list': abilityIds},
    );
  }
  
  Future<List<String>> _loadPerkAbilityGrants(
    String heroId, String perkId,
  ) async {
    final values = await _db.getHeroValues(heroId);
    for (final value in values) {
      if (value.key == '$_kPerkAbilitiesPrefix$perkId') {
        final jsonStr = value.jsonValue;
        if (jsonStr != null) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (map['list'] is List) {
            return (map['list'] as List).cast<String>();
          }
        }
      }
    }
    return [];
  }
  
  Future<void> _clearPerkAbilityGrants(
    String heroId, String perkId,
  ) async {
    await _db.deleteHeroValue(heroId: heroId, key: '$_kPerkAbilitiesPrefix$perkId');
  }
  
  Future<void> _clearAllGrantChoicesForPerk(
    String heroId, String perkId,
  ) async {
    final prefix = 'perk_grant.$perkId.';
    final values = await _db.getHeroValues(heroId);
    for (final value in values) {
      if (value.key.startsWith(prefix)) {
        await _db.deleteHeroValue(heroId: heroId, key: value.key);
      }
    }
  }
  
  // --- Private helpers for hero components ---
  
  Future<void> _addToHeroAbilities(String heroId, String perkId, List<String> abilityIds) async {
    if (abilityIds.isEmpty) return;
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'ability',
      entryIds: abilityIds,
      gainedBy: 'grant',
    );
  }
  
  Future<void> _removeFromHeroAbilities(
    String heroId, List<String> abilityIds, String perkId,
  ) async {
    // Simply remove all abilities from this specific perk
    // Other perks' abilities are stored separately with their own sourceId
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'ability',
    );
  }
  
  Future<void> _addToHeroLanguages(String heroId, String perkId, List<String> languageIds) async {
    if (languageIds.isEmpty) return;
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'language',
      entryIds: languageIds,
      gainedBy: 'grant',
    );
  }
  
  /// Removes ALL language entries granted by this perk.
  /// Note: This removes all languages from the perk, not specific ones.
  Future<void> _removeFromHeroLanguages(
    String heroId, String perkId,
  ) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'language',
    );
  }
  
  Future<void> _addToHeroSkills(String heroId, String perkId, List<String> skillIds) async {
    if (skillIds.isEmpty) return;
    await _entries.addEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'skill',
      entryIds: skillIds,
      gainedBy: 'grant',
    );
  }
  
  /// Removes ALL skill entries granted by this perk.
  /// Note: This removes all skills from the perk, not specific ones.
  Future<void> _removeFromHeroSkills(
    String heroId, String perkId,
  ) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'perk',
      sourceId: perkId,
      entryType: 'skill',
    );
  }
}
