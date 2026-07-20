import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart' as db;
import '../models/canonical_grant_model.dart';
import '../models/class_data.dart';
import '../models/feature.dart' as feature_model;
import '../models/hero_mutation_model.dart';
import '../models/subclass_models.dart';
import '../repositories/feature_repository.dart';
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'ability_resolver_service.dart';
import 'class_feature_data_service.dart';
import 'hero_config_service.dart';
import 'hero_duplicate_guard_service.dart';
import 'hero_mutation_service.dart';

/// One component-backed hero entry the future class-feature state will own.
///
/// [sourceId] is the `class_feature` source the entry persists under. Grants
/// sharing a source id collapse into a single `hero_entries` row, so they can
/// never duplicate one another.
class ClassFeatureEntryGrant {
  const ClassFeatureEntryGrant({
    required this.featureId,
    required this.entryType,
    required this.entryId,
    this.optionKey,
    String? sourceId,
  }) : sourceId = sourceId ?? featureId;

  final String featureId;
  final String entryType;
  final String entryId;

  /// Set when a feature option produced the grant rather than a fixed grant.
  final String? optionKey;

  final String sourceId;

  String get ownerLabel => '${HeroEntrySourceTypes.classFeature}:$sourceId';

  /// Rule-level identity: what may only be owned once across the hero.
  String get entryKey => '$entryType:$entryId';

  /// Storage-level identity: one `hero_entries` row.
  String get rowKey => '$entryType:$entryId:$sourceId';
}

class ClassFeatureGrantConflict {
  const ClassFeatureGrantConflict({
    required this.grant,
    required this.ownerLabels,
  });

  final ClassFeatureEntryGrant grant;
  final List<String> ownerLabels;
}

class ClassFeatureGrantConflictException implements Exception {
  const ClassFeatureGrantConflictException(this.conflicts);

  final List<ClassFeatureGrantConflict> conflicts;

  @override
  String toString() =>
      'Class feature grants conflict with existing hero content';
}

/// Reports the duplicate conflicts a proposed class-feature batch introduces.
///
/// Applying a batch replaces the whole `class_feature` source type, so every
/// persisted class-feature row is projected away and [proposedGrants] must
/// describe the *complete* future class-feature state. Every other owner —
/// Story, Strife, ancestry, complication, career, perk, kit, hero sheet —
/// survives and is checked. Titles and non component-backed bookkeeping rows
/// are outside the duplicate rule.
///
/// Only newly introduced conflicts are returned. A grant that rewrites the
/// exact row it already owns is left alone: its conflict predates this save,
/// and blocking it would make the tab unusable until the other owner is
/// repaired elsewhere. `HeroDataValidator` reports those standing conflicts.
List<ClassFeatureGrantConflict> projectClassFeatureGrantConflicts({
  required Iterable<db.HeroEntry> persistedEntries,
  required Iterable<ClassFeatureEntryGrant> proposedGrants,
}) {
  const guard = HeroDuplicateGuardService();

  final ownersByEntry = <String, Set<String>>{};
  final persistedFeatureRows = <String>{};
  for (final entry in persistedEntries) {
    if (!guard.guardsEntryType(entry.entryType)) continue;
    final entryKey = '${entry.entryType}:${entry.entryId}';
    if (entry.sourceType == HeroEntrySourceTypes.classFeature) {
      persistedFeatureRows.add('$entryKey:${entry.sourceId}');
      continue;
    }
    ownersByEntry.putIfAbsent(entryKey, () => <String>{}).add(
          entry.sourceId.trim().isEmpty
              ? entry.sourceType
              : '${entry.sourceType}:${entry.sourceId}',
        );
  }

  // Collapse grants that persist as one row before building the owner map, so
  // owners are evaluated against the complete future state rather than the
  // order grants happen to be resolved in.
  final batch = <String, ClassFeatureEntryGrant>{};
  for (final grant in proposedGrants) {
    if (!guard.guardsEntryType(grant.entryType)) continue;
    batch.putIfAbsent(grant.rowKey, () => grant);
  }
  for (final grant in batch.values) {
    ownersByEntry
        .putIfAbsent(grant.entryKey, () => <String>{})
        .add(grant.ownerLabel);
  }

  final conflicts = <ClassFeatureGrantConflict>[];
  for (final grant in batch.values) {
    if (persistedFeatureRows.contains(grant.rowKey)) continue;
    final owners = ownersByEntry[grant.entryKey]!
        .where((owner) => owner != grant.ownerLabel)
        .toList()
      ..sort();
    if (owners.isEmpty) continue;
    conflicts.add(
      ClassFeatureGrantConflict(
        grant: grant,
        ownerLabels: List<String>.unmodifiable(owners),
      ),
    );
  }
  return List<ClassFeatureGrantConflict>.unmodifiable(conflicts);
}

/// Service for applying class feature selections to a hero.
///
/// This service handles storing feature grants based on user selections
/// in the class feature UI. All grants are written to hero_entries with
/// source_type='class_feature' and source_id=<featureId>.
class ClassFeatureGrantsService {
  ClassFeatureGrantsService(this._db, {HeroMutationService? mutations})
      : _entries = HeroEntryRepository(_db),
        _config = HeroConfigService(_db),
        _abilityResolver = AbilityResolverService(_db),
        _mutations = mutations ?? HeroMutationService(_db);

  final db.AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final AbilityResolverService _abilityResolver;
  final HeroMutationService _mutations;

  /// Config key for storing feature selections.
  static const _kFeatureSelections = HeroConfigKeys.classFeatureSelections;

  /// Config key for storing subclass key.
  static const _kSubclassKey = HeroConfigKeys.classFeatureSubclassKey;

  /// Config key for storing skill_group skill selections.
  static const _kSkillGroupSelections =
      HeroConfigKeys.classFeatureSkillGroupSelections;

  /// Apply class feature selections to a hero.
  ///
  /// The complete future class-feature state is resolved and validated first,
  /// then committed in one transaction, so a mid-write failure cannot leave the
  /// hero holding part of a batch.
  /// [skillGroupSelections] overrides the stored nested choices. A draft
  /// commit passes its in-memory values so the batch is resolved, validated,
  /// and persisted from one consistent state instead of stale config.
  Future<void> applyClassFeatureSelections({
    required String heroId,
    required ClassData classData,
    required int level,
    required Map<String, Set<String>> selections,
    SubclassSelectionResult? subclassSelection,
    Map<String, Map<String, String>>? skillGroupSelections,
  }) async {
    final batch = await _resolveClassFeatureBatch(
      heroId: heroId,
      classData: classData,
      level: level,
      selections: selections,
      subclassSelection: subclassSelection,
      skillGroupSelections: skillGroupSelections,
    );
    if (batch == null) return;

    final conflicts = await _conflictsForBatch(heroId, batch);
    if (conflicts.isNotEmpty) {
      throw ClassFeatureGrantConflictException(conflicts);
    }

    await _db.transaction(() async {
      // Store selections in hero_config
      await _saveFeatureSelections(heroId, selections);
      if (skillGroupSelections != null) {
        await saveSkillGroupSelections(heroId, skillGroupSelections);
      }

      // Store subclass key if present.
      final subclassKey = subclassSelection?.subclassKey?.trim();
      if (subclassKey != null && subclassKey.isNotEmpty) {
        await _mutations.saveConfigChoice(
          heroId: heroId,
          key: _kSubclassKey,
          value: {'key': subclassKey},
        );
      } else {
        await _mutations.removeConfigChoice(heroId: heroId, key: _kSubclassKey);
      }

      // Remove existing class feature grants for this hero
      await _clearAllClassFeatureGrants(
        heroId,
        recomputeAggregates: false,
      );

      // Clear the legacy value cache; feature stat bonuses are source-scoped entries.
      await _db.deleteHeroValue(
        heroId: heroId,
        key: HeroValueKeys.legacyFeatureStatBonuses,
      );

      await _writeBatch(heroId, batch);

      // Rebuild damage resistances from all hero_entries (including new grants).
      await _mutations.recomputeAggregates(heroId);
    });
  }

  /// Preflights the complete class-feature state [selections] would persist.
  ///
  /// Returns the conflicts that applying the batch would introduce, so a caller
  /// can report them without attempting the write.
  Future<List<ClassFeatureGrantConflict>> validateFeatureSelections({
    required String heroId,
    required ClassData classData,
    required int level,
    required Map<String, Set<String>> selections,
    SubclassSelectionResult? subclassSelection,
    Map<String, Map<String, String>>? skillGroupSelections,
  }) async {
    final batch = await _resolveClassFeatureBatch(
      heroId: heroId,
      classData: classData,
      level: level,
      selections: selections,
      subclassSelection: subclassSelection,
      skillGroupSelections: skillGroupSelections,
    );
    if (batch == null) return const [];
    return _conflictsForBatch(heroId, batch);
  }

  /// Every component-backed entry the future class-feature state would own.
  ///
  /// This covers fixed top-level grants, automatically matched subclass/domain
  /// grants, selected option grants, nested canonical grants, and stored
  /// skill-group choices. Titles and bookkeeping rows are excluded because they
  /// are outside the duplicate rule.
  Future<List<ClassFeatureEntryGrant>> previewClassFeatureEntryGrants({
    required String heroId,
    required ClassData classData,
    required int level,
    required Map<String, Set<String>> selections,
    SubclassSelectionResult? subclassSelection,
    Map<String, Map<String, String>>? skillGroupSelections,
  }) async {
    final batch = await _resolveClassFeatureBatch(
      heroId: heroId,
      classData: classData,
      level: level,
      selections: selections,
      subclassSelection: subclassSelection,
      skillGroupSelections: skillGroupSelections,
    );
    return batch?.componentGrants ?? const [];
  }

  Future<List<ClassFeatureGrantConflict>> _conflictsForBatch(
    String heroId,
    _ClassFeatureBatch batch,
  ) async {
    return projectClassFeatureGrantConflicts(
      persistedEntries: await _entries.listAllEntriesForHero(heroId),
      proposedGrants: batch.componentGrants,
    );
  }

  /// Resolves the complete future class-feature batch without writing.
  ///
  /// All component/asset lookups happen here, so the write phase only replays
  /// resolved rows. Returns null when the class id has no usable slug.
  Future<_ClassFeatureBatch?> _resolveClassFeatureBatch({
    required String heroId,
    required ClassData classData,
    required int level,
    required Map<String, Set<String>> selections,
    SubclassSelectionResult? subclassSelection,
    Map<String, Map<String, String>>? skillGroupSelections,
  }) async {
    final classSlug = _classSlugFromId(classData.classId);
    if (classSlug == null) return null;

    final featureDetails = await _loadFeatureDetails(classSlug);
    final activeSubclassSlugs =
        ClassFeatureDataService.activeSubclassSlugs(subclassSelection);
    final domainSlugs =
        ClassFeatureDataService.selectedDomainSlugs(subclassSelection);

    final allFeatures = await FeatureRepository.loadClassFeatures(classSlug);
    final applicableFeatures =
        allFeatures.where((f) => f.level <= level).where((f) {
      if (!f.isSubclassFeature) return true;
      if (activeSubclassSlugs.isEmpty) return true;
      return ClassFeatureDataService.matchesSelectedSubclass(
        f.subclassName,
        activeSubclassSlugs,
      );
    }).toList();

    final batch = _ClassFeatureBatch();
    for (final feature in applicableFeatures) {
      await _collectFeatureGrants(
        batch: batch,
        feature: feature,
        featureDetails: featureDetails,
        selections: selections,
        activeSubclassSlugs: activeSubclassSlugs,
        domainSlugs: domainSlugs,
      );
    }

    _collectSkillGroupGrants(
      batch: batch,
      selections:
          skillGroupSelections ?? await loadSkillGroupSelections(heroId),
      featureDetails: featureDetails,
      applicableFeatures: applicableFeatures,
      featureSelections: selections,
      activeSubclassSlugs: activeSubclassSlugs,
      domainSlugs: domainSlugs,
    );

    return batch;
  }

  Future<void> _writeBatch(String heroId, _ClassFeatureBatch batch) async {
    for (final entry in batch.entries) {
      await _mutations.addContentEntry(
        heroId: heroId,
        source: _classFeatureSource(entry.sourceId, gainedBy: entry.gainedBy),
        grant: ResolvedGrant(
          entryType: entry.entryType,
          entryId: entry.entryId,
          payload: entry.payload,
        ),
      );
    }

    for (final resistance in batch.resistances) {
      await _mutations.addResistance(
        heroId: heroId,
        source: _classFeatureSource(resistance.sourceId),
        damageType: resistance.damageType,
        immunity: resistance.immunity,
        weakness: resistance.weakness,
        dynamicImmunity: resistance.dynamicImmunity,
        dynamicWeakness: resistance.dynamicWeakness,
        immunityPerEchelon: resistance.immunityPerEchelon,
        weaknessPerEchelon: resistance.weaknessPerEchelon,
        recompute: false,
      );
    }
  }

  /// Remove all class feature grants for a hero.
  Future<void> removeClassFeatureGrants(String heroId) async {
    await _clearAllClassFeatureGrants(heroId);
    await _mutations.removeConfigChoice(
        heroId: heroId, key: _kFeatureSelections);
    await _mutations.removeConfigChoice(heroId: heroId, key: _kSubclassKey);
    await _mutations.removeConfigChoice(
      heroId: heroId,
      key: _kSkillGroupSelections,
    );
  }

  /// Remove grants for a specific feature.
  Future<void> removeFeatureGrants(String heroId, String featureId) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _classFeatureSource(featureId),
      recomputeAggregates: false,
    );

    final skillGroupSelections = await loadSkillGroupSelections(heroId);
    final featureSkillGroups = skillGroupSelections[featureId];
    if (featureSkillGroups != null) {
      for (final grantKey in featureSkillGroups.keys) {
        await _mutations.removeSource(
          heroId: heroId,
          source: _classFeatureSource(
            _skillGroupSourceId(featureId, grantKey),
            gainedBy: HeroEntryGainedBy.choice,
          ),
          entryType: HeroEntryTypes.skill,
          recomputeAggregates: false,
        );
      }
    }

    await _mutations.recomputeAggregates(heroId);
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
      for (final entry in selections.entries) entry.key: entry.value,
    };
    await _mutations.saveConfigChoice(
      heroId: heroId,
      key: _kSkillGroupSelections,
      value: jsonMap,
    );
  }

  /// Save a single skill_group skill selection and update hero_entries.
  /// This replaces the exact nested-choice source with the current skill.
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

    final sourceId = _skillGroupSourceId(featureId, grantKey);
    await _mutations.replaceContentEntries(
      heroId: heroId,
      source: _classFeatureSource(
        sourceId,
        gainedBy: HeroEntryGainedBy.choice,
      ),
      entryType: HeroEntryTypes.skill,
      entryIds:
          skillId == null || skillId.trim().isEmpty ? const [] : [skillId],
      gainedBy: HeroEntryGainedBy.choice,
    );
  }

  /// Get all abilities granted by class features.
  Future<List<String>> getGrantedAbilities(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.ability,
    );
    return entries
        .where((e) => e.sourceType == HeroEntrySourceTypes.classFeature)
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all skills granted by class features.
  Future<List<String>> getGrantedSkills(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.skill,
    );
    return entries
        .where((e) => e.sourceType == HeroEntrySourceTypes.classFeature)
        .map((e) => e.entryId)
        .toList();
  }

  /// Get all features (class_feature entries) for a hero.
  Future<List<db.HeroEntry>> getClassFeatureEntries(String heroId) async {
    final entries = await _entries.listEntriesByType(
      heroId,
      HeroEntryTypes.classFeature,
    );
    return entries
        .where((e) => e.sourceType == HeroEntrySourceTypes.classFeature)
        .toList();
  }

  @visibleForTesting
  Future<void> applyFeatureDetailsForTesting({
    required String heroId,
    required feature_model.Feature feature,
    required Map<String, dynamic> details,
    Map<String, Set<String>> selections = const {},
    Set<String> activeSubclassSlugs = const {},
    Set<String> domainSlugs = const {},
  }) async {
    final featureDetails = {feature.id: details};
    final batch = _ClassFeatureBatch();
    await _collectFeatureGrants(
      batch: batch,
      feature: feature,
      featureDetails: featureDetails,
      selections: selections,
      activeSubclassSlugs: activeSubclassSlugs,
      domainSlugs: domainSlugs,
    );
    _collectSkillGroupGrants(
      batch: batch,
      selections: await loadSkillGroupSelections(heroId),
      featureDetails: featureDetails,
      applicableFeatures: [feature],
      featureSelections: selections,
      activeSubclassSlugs: activeSubclassSlugs,
      domainSlugs: domainSlugs,
    );
    await _writeBatch(heroId, batch);
    await _mutations.recomputeAggregates(heroId);
  }

  // Private implementation

  Future<void> _saveFeatureSelections(
    String heroId,
    Map<String, Set<String>> selections,
  ) async {
    final jsonMap = <String, dynamic>{
      for (final entry in selections.entries) entry.key: entry.value.toList(),
    };
    await _mutations.saveConfigChoice(
      heroId: heroId,
      key: _kFeatureSelections,
      value: jsonMap,
    );
  }

  Future<void> _clearAllClassFeatureGrants(
    String heroId, {
    bool recomputeAggregates = true,
  }) async {
    await _mutations.removeSourceType(
      heroId: heroId,
      sourceType: HeroEntrySourceTypes.classFeature,
      recomputeAggregates: recomputeAggregates,
    );
  }

  HeroSource _classFeatureSource(
    String sourceId, {
    String gainedBy = HeroEntryGainedBy.grant,
  }) {
    return HeroSource(
      sourceType: HeroEntrySourceTypes.classFeature,
      sourceId: sourceId,
      gainedBy: gainedBy,
    );
  }

  String _skillGroupSourceId(String featureId, String grantKey) {
    return '${featureId}_skill_group_$grantKey';
  }

  void _addClassFeatureGrant({
    required _ClassFeatureBatch batch,
    required String featureId,
    required String entryType,
    required String entryId,
    String? sourceId,
    String? optionKey,
    Map<String, dynamic>? payload,
    String gainedBy = HeroEntryGainedBy.grant,
  }) {
    batch.addEntry(
      _ResolvedFeatureEntry(
        featureId: featureId,
        sourceId: sourceId ?? featureId,
        optionKey: optionKey,
        entryType: entryType,
        entryId: entryId,
        payload: payload,
        gainedBy: gainedBy,
      ),
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

  Future<void> _collectFeatureGrants({
    required _ClassFeatureBatch batch,
    required feature_model.Feature feature,
    required Map<String, Map<String, dynamic>> featureDetails,
    required Map<String, Set<String>> selections,
    required Set<String> activeSubclassSlugs,
    required Set<String> domainSlugs,
  }) async {
    final details = featureDetails[feature.id];

    // Always add the feature itself as a class_feature entry
    _addClassFeatureGrant(
      batch: batch,
      featureId: feature.id,
      entryType: HeroEntryTypes.classFeature,
      entryId: feature.id,
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
    // The subclass picker owns its fixed skill under subclass:subclass_skill.
    // Re-granting that same skill from this selector feature creates a false
    // duplicate-owner conflict during the first save.
    final includeDirectOptionSkill =
        feature.type.trim().toLowerCase() != 'subclass';

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
          await _collectOptionGrants(
            batch,
            feature.id,
            option,
            includeDirectSkillGrant: includeDirectOptionSkill,
          );
        }
      }
    } else if (options.isNotEmpty) {
      // Apply user-selected options.
      final selectedKeys = selections[feature.id] ?? const <String>{};
      for (final option in options) {
        if (_optionMatchesSelection(
          option,
          selectedKeys: selectedKeys,
          activeSubclassSlugs: activeSubclassSlugs,
          domainSlugs: domainSlugs,
        )) {
          await _collectOptionGrants(
            batch,
            feature.id,
            option,
            includeDirectSkillGrant: includeDirectOptionSkill,
          );
        }
      }
    }

    // Process top-level ability grant (e.g., "ability": "Judgment")
    await _collectTopLevelAbility(batch, feature.id, details);

    // Process stat_mods if present
    _collectStatMods(batch, feature.id, details);

    // Process resistance grants if present
    _collectResistanceGrants(batch, feature.id, details);

    // Process title grants if present
    await _collectTitleGrants(batch, feature.id, details);

    // Process top-level grants array (for stat bonuses, condition immunities, etc.)
    await _collectGrantsArray(
        batch, feature.id, details, activeSubclassSlugs, feature.level);
  }

  void _collectSkillGroupGrants({
    required _ClassFeatureBatch batch,
    required Map<String, Map<String, String>> selections,
    required Map<String, Map<String, dynamic>> featureDetails,
    required List<feature_model.Feature> applicableFeatures,
    required Map<String, Set<String>> featureSelections,
    required Set<String> activeSubclassSlugs,
    required Set<String> domainSlugs,
  }) {
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
        final skillGroup = ClassFeatureDataService.optionSkillGroup(option);
        if (skillGroup == null || skillGroup.isEmpty) continue;

        final isSelected = isGrants
            ? _optionMatchesSubclass(option, activeSubclassSlugs)
            : _optionMatchesSelection(
                option,
                selectedKeys: selectedKeys,
                activeSubclassSlugs: activeSubclassSlugs,
                domainSlugs: domainSlugs,
              );
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

        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          sourceId: _skillGroupSourceId(featureId, grantKey),
          optionKey: grantKey,
          entryType: HeroEntryTypes.skill,
          entryId: skillId,
          gainedBy: HeroEntryGainedBy.choice,
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

  bool _optionMatchesSelection(
    Map<String, dynamic> option, {
    required Set<String> selectedKeys,
    required Set<String> activeSubclassSlugs,
    required Set<String> domainSlugs,
  }) {
    if (_selectedKeysMatchOption(option, selectedKeys)) {
      return true;
    }
    if (selectedKeys.isNotEmpty) return false;
    if (!_hasDomainSelectionMetadata(option) || domainSlugs.isEmpty) {
      return false;
    }
    return ClassFeatureDataService.isOptionActiveForSelection(
      option,
      activeSubclassSlugs: activeSubclassSlugs,
      selectedDomainSlugs: domainSlugs,
    );
  }

  bool _selectedKeysMatchOption(
    Map<String, dynamic> option,
    Set<String> selectedKeys,
  ) {
    if (selectedKeys.isEmpty) return false;
    final selectedVariants = selectedKeys
        .expand(ClassFeatureDataService.slugVariants)
        .where((key) => key.isNotEmpty)
        .toSet();
    if (selectedVariants.isEmpty) return false;
    return _optionSelectionKeyVariants(option)
        .any((key) => selectedVariants.contains(key));
  }

  Set<String> _optionSelectionKeyVariants(Map<String, dynamic> option) {
    final variants = <String>{};

    void addValue(Object? value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return;
      variants.addAll(ClassFeatureDataService.slugVariants(text));
    }

    addValue(ClassFeatureDataService.featureOptionKey(option));
    addValue(ClassFeatureDataService.optionGrantKey(option));
    for (final key in const [
      'domain',
      'subclass',
      'subclass_name',
      'name',
      'title',
      'ability',
      'ability_id',
      'skill',
    ]) {
      addValue(option[key]);
    }

    return variants;
  }

  bool _hasDomainSelectionMetadata(Map<String, dynamic> option) {
    final domain = option['domain']?.toString().trim();
    return domain != null && domain.isNotEmpty;
  }

  Future<void> _collectOptionGrants(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> option, {
    bool includeDirectSkillGrant = true,
  }) async {
    final optionKey = ClassFeatureDataService.featureOptionKey(option);

    // Grant skill if specified
    final skill = option['skill']?.toString();
    if (includeDirectSkillGrant && skill != null && skill.isNotEmpty) {
      final skillId = await _resolveSkillId(skill);
      if (skillId != null) {
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          optionKey: optionKey,
          entryType: HeroEntryTypes.skill,
          entryId: skillId,
        );
      }
    }

    // Grant ability or abilities if specified
    final abilityNames = <String>{};
    _collectAbilityNames(abilityNames, option['ability']);
    _collectAbilityNames(abilityNames, option['abilities']);
    for (final abilityName in abilityNames) {
      final abilityId = await _abilityResolver.resolveAbilityId(
        abilityName,
        sourceType: HeroEntrySourceTypes.classFeature,
      );
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        optionKey: optionKey,
        entryType: HeroEntryTypes.ability,
        entryId: abilityId,
      );
    }

    // Grant feature benefits with stat_mods
    final statMods = option['stat_mods'] ?? option['statMods'];
    if (statMods is Map) {
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        optionKey: optionKey,
        entryType: HeroEntryTypes.statMod,
        entryId: '${featureId}_option_stat_mod',
        payload: {'mods': statMods},
      );
    }

    // Grant resistances from option
    final immunities = option['immunities'] ?? option['immunity'];
    if (immunities != null) {
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        optionKey: optionKey,
        entryType: HeroEntryTypes.immunity,
        entryId: '${featureId}_option_immunity',
        payload: {'immunities': _normalizeToList(immunities)},
      );
    }

    // Grant titles from option
    final title = option['title']?.toString();
    if (title != null && title.isNotEmpty) {
      final titleId = await _resolveTitleId(title);
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        optionKey: optionKey,
        entryType: HeroEntryTypes.title,
        entryId: titleId,
      );
    }

    _collectCanonicalGrantValue(
      batch: batch,
      featureId: featureId,
      optionKey: optionKey,
      value: option['grants'],
    );
  }

  void _collectStatMods(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> details,
  ) {
    final statMods = details['stat_mods'] ?? details['statMods'];
    if (statMods is! Map) return;

    _addClassFeatureGrant(
      batch: batch,
      featureId: featureId,
      entryType: HeroEntryTypes.statMod,
      entryId: '${featureId}_stat_mod',
      payload: {'mods': statMods},
    );
  }

  void _collectResistanceGrants(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> details,
  ) {
    final immunities = details['immunities'] ?? details['immunity'];
    if (immunities != null) {
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        entryType: HeroEntryTypes.immunity,
        entryId: '${featureId}_immunity',
        payload: {'immunities': _normalizeToList(immunities)},
      );
    }

    final weaknesses = details['weaknesses'] ?? details['weakness'];
    if (weaknesses != null) {
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        entryType: HeroEntryTypes.weakness,
        entryId: '${featureId}_weakness',
        payload: {'weaknesses': _normalizeToList(weaknesses)},
      );
    }
  }

  Future<void> _collectTitleGrants(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final titles = details['titles'] ?? details['granted_titles'];
    if (titles == null) return;

    final titleList = _normalizeToList(titles);
    for (final title in titleList) {
      if (title.isEmpty) continue;
      final titleId = await _resolveTitleId(title);
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        entryType: HeroEntryTypes.title,
        entryId: titleId,
      );
    }
  }

  /// Process top-level ability granted by a feature (e.g., "ability": "Judgment")
  Future<void> _collectTopLevelAbility(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> details,
  ) async {
    final abilityNames = <String>{};
    _collectAbilityNames(abilityNames, details['ability']);
    if (abilityNames.isEmpty) return;

    for (final abilityName in abilityNames) {
      final abilityId = await _abilityResolver.resolveAbilityId(
        abilityName,
        sourceType: HeroEntrySourceTypes.classFeature,
      );
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        entryType: HeroEntryTypes.ability,
        entryId: abilityId,
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
  Future<void> _collectGrantsArray(
    _ClassFeatureBatch batch,
    String featureId,
    Map<String, dynamic> details,
    Set<String> activeSubclassSlugs,
    int featureLevel,
  ) async {
    final grants = details['grants'];
    if (grants is Map && _isCanonicalGrantValue(grants)) {
      _collectCanonicalGrantValue(
        batch: batch,
        featureId: featureId,
        value: grants,
      );
      return;
    }
    if (grants is! List) return;

    // Collect stat bonuses to merge into a single source-scoped entry.
    final statBonuses = <String, dynamic>{};
    final conditionImmunities = <String>[];
    final damageResistanceGrants = <Map<String, dynamic>>[];

    for (final rawGrant in grants) {
      final grant = _stringKeyedMapOrNull(rawGrant);
      if (grant == null) continue;

      // Check if this grant is subclass-specific
      if (!_optionMatchesSubclass(grant, activeSubclassSlugs)) continue;

      if (_isCanonicalGrantValue(grant)) {
        _collectCanonicalGrantValue(
          batch: batch,
          featureId: featureId,
          value: grant,
        );
        continue;
      }

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
            _processIncreaseTotalGrant(
                value, statBonuses, damageResistanceGrants, featureId);
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
                sourceType: HeroEntrySourceTypes.classFeature,
              );
              _addClassFeatureGrant(
                batch: batch,
                featureId: featureId,
                entryType: HeroEntryTypes.ability,
                entryId: abilityId,
              );
            }
            break;

          // Skill grant
          case 'skill':
            if (value is String && value.isNotEmpty) {
              final skillId = await _resolveSkillId(value);
              if (skillId != null) {
                _addClassFeatureGrant(
                  batch: batch,
                  featureId: featureId,
                  entryType: HeroEntryTypes.skill,
                  entryId: skillId,
                );
              }
            }
            break;

          // Language grant
          case 'language':
            if (value is String && value.isNotEmpty) {
              _addClassFeatureGrant(
                batch: batch,
                featureId: featureId,
                entryType: HeroEntryTypes.language,
                entryId: 'language_${ClassFeatureDataService.slugify(value)}',
                payload: {'name': value},
              );
            }
            break;

          // Nested grants object (contains stamina_per_level_increase, increase_total, etc.)
          case 'grants':
            if (_isCanonicalGrantValue(value)) {
              _collectCanonicalGrantValue(
                batch: batch,
                featureId: featureId,
                value: value,
              );
            } else if (value is Map<String, dynamic>) {
              _processNestedGrants(
                value,
                statBonuses,
                damageResistanceGrants,
                featureId,
                featureLevel,
              );
            } else if (value is Map) {
              _processNestedGrants(
                value.cast<String, dynamic>(),
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

    // Store stat bonuses as source-scoped hero_entries.
    if (statBonuses.isNotEmpty) {
      _addClassFeatureGrant(
        batch: batch,
        featureId: featureId,
        entryType: HeroEntryTypes.featureStatBonus,
        entryId: '${featureId}_stat_bonus',
        payload: statBonuses,
      );
    }

    // Store damage resistance grants (immunity/weakness with level scaling)
    if (damageResistanceGrants.isNotEmpty) {
      _collectDamageResistanceGrants(
        batch: batch,
        featureId: featureId,
        grants: damageResistanceGrants,
      );
    }

    // Store condition immunities
    if (conditionImmunities.isNotEmpty) {
      for (final condition in conditionImmunities) {
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          entryType: HeroEntryTypes.conditionImmunity,
          entryId: 'immunity_$condition',
          payload: {'condition': condition},
        );
      }
    }
  }

  void _collectCanonicalGrantValue({
    required _ClassFeatureBatch batch,
    required String featureId,
    required Object? value,
    String? optionKey,
  }) {
    if (!_isCanonicalGrantValue(value)) return;

    final grants = <CanonicalGrant>[];
    if (value is List) {
      for (final item in value) {
        final map = _stringKeyedMapOrNull(item);
        if (map == null || !map.containsKey('kind')) continue;
        grants.add(
          CanonicalGrant.fromJson(
            map,
            defaultSource: featureId,
          ),
        );
      }
    } else {
      grants.addAll(
        CanonicalGrant.parseList(
          value,
          defaultSource: featureId,
        ),
      );
    }

    for (final grant in grants) {
      _collectCanonicalGrant(
        batch: batch,
        featureId: featureId,
        optionKey: optionKey,
        grant: grant,
      );
    }
  }

  void _collectCanonicalGrant({
    required _ClassFeatureBatch batch,
    required String featureId,
    required CanonicalGrant grant,
    String? optionKey,
  }) {
    switch (grant) {
      case CanonicalEntryGrant():
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          optionKey: optionKey,
          entryType: grant.entryType,
          entryId: grant.entryId,
          payload: grant.payload,
          gainedBy: grant.gainedBy,
        );
      case CanonicalStatModGrant():
        final stat = grant.stat.trim().toLowerCase();
        if (stat.isEmpty) return;
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          optionKey: optionKey,
          entryType: HeroEntryTypes.statMod,
          entryId: grant.entryId ??
              '${featureId}_${ClassFeatureDataService.slugify(stat)}_stat_mod',
          payload: {
            'mods': {
              stat: grant.modifications
                  .map((modification) => modification.toJson())
                  .toList(),
            },
            ...?grant.payload,
          },
        );
      case CanonicalResistanceGrant():
        if (!grant.hasEffect) return;
        batch.addResistance(
          _ResolvedFeatureResistance(
            sourceId: featureId,
            damageType: grant.damageType,
            immunity: grant.immunity,
            weakness: grant.weakness,
            dynamicImmunity: grant.dynamicImmunity,
            dynamicWeakness: grant.dynamicWeakness,
            immunityPerEchelon: grant.immunityPerEchelon,
            weaknessPerEchelon: grant.weaknessPerEchelon,
          ),
        );
      case CanonicalTreasureGrant():
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          optionKey: optionKey,
          entryType: HeroEntryTypes.treasure,
          entryId: grant.treasureId,
          payload: grant.entryPayload,
        );
      case CanonicalEquipmentBonusesGrant():
        _addClassFeatureGrant(
          batch: batch,
          featureId: featureId,
          optionKey: optionKey,
          entryType: HeroEntryTypes.equipmentBonuses,
          entryId: grant.entryId,
          payload: grant.toJson(),
        );
      case CanonicalChoiceGrant():
      case CanonicalTokenGrant():
        break;
    }
  }

  bool _isCanonicalGrantValue(Object? value) {
    if (value is Map) {
      final map = _stringKeyedMapOrNull(value);
      if (map == null) return false;
      return map['schema'] == canonicalGrantSchemaId || map.containsKey('kind');
    }
    if (value is List) {
      return value.any((item) {
        final map = _stringKeyedMapOrNull(item);
        return map != null && map.containsKey('kind');
      });
    }
    return false;
  }

  void _collectDamageResistanceGrants({
    required _ClassFeatureBatch batch,
    required String featureId,
    required List<Map<String, dynamic>> grants,
  }) {
    final grantsByType = <String, _ClassFeatureResistanceGrant>{};

    for (final grant in grants) {
      final stat = grant['stat']?.toString().trim().toLowerCase();
      final damageType = grant['type']?.toString().trim().toLowerCase();
      if (stat == null || damageType == null || damageType.isEmpty) continue;

      final accumulator = grantsByType.putIfAbsent(
        damageType,
        () => _ClassFeatureResistanceGrant(),
      );
      accumulator.add(stat: stat, value: grant['value']);
    }

    for (final entry in grantsByType.entries) {
      final grant = entry.value;
      batch.addResistance(
        _ResolvedFeatureResistance(
          sourceId: featureId,
          damageType: entry.key,
          immunity: grant.immunity,
          weakness: grant.weakness,
          dynamicImmunity: grant.dynamicImmunity,
          dynamicWeakness: grant.dynamicWeakness,
        ),
      );
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
                statBonuses[stat] =
                    (statBonuses[stat] as int? ?? 0) + itemValue;
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
        _processSingleIncreaseTotal(
            item, statBonuses, damageResistanceGrants, featureId);
      }
    } else if (value is Map<String, dynamic>) {
      _processSingleIncreaseTotal(
          value, statBonuses, damageResistanceGrants, featureId);
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
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Map<String, dynamic>? _stringKeyedMapOrNull(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
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
      (c) =>
          c.type == 'skill' && c.name.toLowerCase() == skillName.toLowerCase(),
    );
    return match?.id ?? 'skill_${ClassFeatureDataService.slugify(skillName)}';
  }

  Future<String> _resolveTitleId(String titleName) async {
    final components = await _db.getAllComponents();
    final match = components.firstWhereOrNull(
      (c) =>
          c.type == 'title' && c.name.toLowerCase() == titleName.toLowerCase(),
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

/// One resolved `hero_entries` row the class-feature batch will write.
class _ResolvedFeatureEntry {
  const _ResolvedFeatureEntry({
    required this.featureId,
    required this.sourceId,
    required this.entryType,
    required this.entryId,
    this.optionKey,
    this.payload,
    this.gainedBy = HeroEntryGainedBy.grant,
  });

  final String featureId;
  final String sourceId;
  final String entryType;
  final String entryId;
  final String? optionKey;
  final Map<String, dynamic>? payload;
  final String gainedBy;
}

/// One resolved resistance the class-feature batch will write.
class _ResolvedFeatureResistance {
  const _ResolvedFeatureResistance({
    required this.sourceId,
    required this.damageType,
    this.immunity = 0,
    this.weakness = 0,
    this.dynamicImmunity,
    this.dynamicWeakness,
    this.immunityPerEchelon = 0,
    this.weaknessPerEchelon = 0,
  });

  final String sourceId;
  final String damageType;
  final int immunity;
  final int weakness;
  final String? dynamicImmunity;
  final String? dynamicWeakness;
  final int immunityPerEchelon;
  final int weaknessPerEchelon;
}

/// The complete future `class_feature` state, resolved before any write.
///
/// Collecting the whole batch first is what lets validation see the same rows
/// the writer will produce, so the preview cannot drift from persistence.
class _ClassFeatureBatch {
  final List<_ResolvedFeatureEntry> entries = [];
  final List<_ResolvedFeatureResistance> resistances = [];

  void addEntry(_ResolvedFeatureEntry entry) {
    if (entry.entryId.trim().isEmpty) return;
    entries.add(entry);
  }

  void addResistance(_ResolvedFeatureResistance resistance) {
    resistances.add(resistance);
  }

  /// The component-backed subset the hero-wide duplicate rule guards.
  List<ClassFeatureEntryGrant> get componentGrants {
    const guard = HeroDuplicateGuardService();
    return [
      for (final entry in entries)
        if (guard.guardsEntryType(entry.entryType))
          ClassFeatureEntryGrant(
            featureId: entry.featureId,
            sourceId: entry.sourceId,
            optionKey: entry.optionKey,
            entryType: entry.entryType,
            entryId: entry.entryId.trim(),
          ),
    ];
  }
}

class _ClassFeatureResistanceGrant {
  int immunity = 0;
  int weakness = 0;
  String? dynamicImmunity;
  String? dynamicWeakness;

  void add({required String stat, required dynamic value}) {
    if (stat != 'immunity' && stat != 'weakness') return;

    if (value is num) {
      _addStatic(stat, value.toInt());
      return;
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return;

    final parsed = int.tryParse(text);
    if (parsed != null) {
      _addStatic(stat, parsed);
      return;
    }

    if (stat == 'immunity') {
      dynamicImmunity = text;
    } else {
      dynamicWeakness = text;
    }
  }

  void _addStatic(String stat, int value) {
    if (stat == 'immunity') {
      immunity += value;
    } else {
      weakness += value;
    }
  }
}
