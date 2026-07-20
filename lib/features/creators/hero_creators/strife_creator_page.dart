import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart' as app_db;
import '../../../core/db/providers.dart';
import '../../../core/models/abilities_models.dart';
import '../../../core/models/class_data.dart';
import '../../../core/models/characteristics_models.dart';
import '../../../core/models/component.dart';
import '../../../core/models/hero_model.dart';
import '../../../core/models/perks_models.dart';
import '../../../core/models/skills_models.dart';
import '../../../core/models/subclass_models.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/abilities_service.dart';
import '../../../core/services/ability_data_service.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/perk_data_service.dart';
import '../../../core/services/perk_grants_service.dart';
import '../../../core/services/perks_service.dart';
import '../../../core/services/skill_data_service.dart';
import '../../../core/services/skills_service.dart';
import '../../../core/services/subclass_data_service.dart';
import '../../../core/services/subclass_service.dart';
import '../../../core/storage/hero_storage_contract.dart';
import '../../../core/text/creators/hero_creators/strife_creator_page_text.dart';
import '../../hero_builder/application/hero_builder_controller.dart';
import '../../hero_builder/application/hero_builder_providers.dart';
import '../../hero_builder/application/hero_draft_conversions.dart';
import '../../hero_builder/domain/hero_claim.dart';
import '../../hero_builder/domain/hero_conflict_index.dart';
import '../../hero_builder/domain/hero_draft.dart';
import '../../hero_builder/domain/hero_draft_claims.dart';
import '../../hero_builder/domain/hero_mutation_scope.dart';
import '../widgets/strife_creator/choose_abilities_widget.dart';
import '../widgets/strife_creator/choose_equipment_widget.dart';
import '../widgets/strife_creator/choose_perks_widget.dart';
import '../widgets/strife_creator/choose_skills_widget.dart';
import '../widgets/strife_creator/choose_subclass_widget.dart';
import '../widgets/strife_creator/class_selector_widget.dart';
import '../widgets/strife_creator/level_selector_widget.dart';
import '../widgets/strife_creator/starting_characteristics_widget.dart';

/// Demo page for the new Strife Creator (Level, Class, and Starting Characteristics)
class StrifeCreatorPage extends ConsumerStatefulWidget {
  const StrifeCreatorPage({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<StrifeCreatorPage> createState() => _StrifeCreatorPageState();
}

class _StrifeCreatorPageState extends ConsumerState<StrifeCreatorPage>
    with AutomaticKeepAliveClientMixin {
  // Ownership vocabulary is shared with the hero-builder draft mapping so the
  // page and the controller cannot disagree about who owns a slot.
  static const _strifeAbilityClaimSource = HeroDraftClaims.strifeAbilitySource;
  static const _strifeSkillClaimSource = HeroDraftClaims.strifeSkillSource;
  static const _strifePerkClaimSource = HeroDraftClaims.strifePerkSource;
  static const _subclassSkillClaimSource = HeroDraftClaims.subclassSkillSource;
  static const _strifeEquipmentClaimSource =
      HeroDraftClaims.equipmentSlotsSource;

  final ClassDataService _classDataService = ClassDataService();
  final StartingAbilitiesService _startingAbilitiesService =
      const StartingAbilitiesService();
  final AbilityDataService _abilityDataService = AbilityDataService();
  final StartingSkillsService _startingSkillsService =
      const StartingSkillsService();
  final SkillDataService _skillDataService = SkillDataService();
  final SubclassService _subclassPlanService = const SubclassService();
  final SubclassDataService _subclassDataService = SubclassDataService();
  final StartingPerksService _startingPerksService =
      const StartingPerksService();
  final PerkDataService _perkDataService = PerkDataService();

  static const Map<String, List<String>> _kitFeatureTypeMappings = {
    'kit': ['kit'],
    'psionic augmentation': ['psionic_augmentation'],
    'enchantment': ['enchantment'],
    'prayer': ['prayer'],
    'elementalist ward': ['ward'],
    'talent ward': ['ward'],
    'conduit ward': ['ward'],
    'ward': ['ward'],
  };

  static const List<String> _kitTypePriority = [
    'kit',
    'psionic_augmentation',
    'enchantment',
    'prayer',
    'ward',
    'stormwight_kit',
  ];

  static const _deepEq = DeepCollectionEquality();

  bool _isLoading = true;
  String? _errorMessage;

  // Load-time-only lookup used to normalize legacy skill names to IDs.
  Map<String, String> _skillIdLookup = {};

  // Fixed (non-choice) class skill grants for the current class/level/
  // subclass. Recomputed on level/class/subclass change and after every
  // skill-widget interaction (which reports its own authoritative value).
  // Not part of StrifeDraft because it is derived, not a player choice.
  Set<String> _skillGrantIds = {};

  HeroBuilderController get _controller =>
      ref.read(heroBuilderControllerProvider(widget.heroId).notifier);

  StrifeDraft get _strife =>
      ref.watch(heroBuilderStrifeDraftProvider(widget.heroId));

  /// Resolved from the draft's class id; the draft stores only the id.
  ClassData? get _selectedClass {
    final classId = _strife.classId;
    if (classId == null) return null;
    return _classDataService
        .getAllClasses()
        .firstWhereOrNull((c) => c.classId == classId);
  }

  CharacteristicArray? get _selectedArray {
    final description = _strife.arrayDescription;
    if (description == null) return null;
    return CharacteristicArray(
      description: description,
      values: _strife.arrayValues,
    );
  }

  SubclassSelectionResult? get _selectedSubclass =>
      subclassSelectionFromDraft(_strife.subclass);

  List<String?> get _selectedKitIds => _strife.equipmentIds;

  Set<String> get _currentSelectedPerkIds => _strife.perkSelections.values
      .whereType<String>()
      .where((id) => id.trim().isNotEmpty)
      .toSet();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _classDataService.initialize();
      final repo = ref.read(heroRepositoryProvider);
      final db = ref.read(appDatabaseProvider);
      final hero = await repo.load(widget.heroId);

      if (hero == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load-time-only snapshots (see field docs above).
      final skillOptions = await _skillDataService.loadSkills();
      _skillIdLookup = {
        for (final option in skillOptions) option.name.toLowerCase(): option.id,
        for (final option in skillOptions) option.id.toLowerCase(): option.id,
      };
      // Adopt the persisted baseline first; legacy healing below reads it.
      await _controller.reload();
      if (!mounted) return;

      final classId = hero.className?.trim();
      final classData = classId == null
          ? null
          : _classDataService
              .getAllClasses()
              .firstWhereOrNull((c) => c.classId == classId);

      if (classData != null) {
        final healed = await _healLegacyStrifeData(
          classData: classData,
          hero: hero,
          repo: repo,
          db: db,
        );
        if (healed) {
          await _controller.reload();
          if (!mounted) return;
        }
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      _updateGrantIdsForCurrentPlan();
      _notifyDirty();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            '${StrifeCreatorPageText.failedToLoadClassDataPrefix}$e';
      });
    }
  }

  /// Repairs legacy/imported Strife data in place so the controller's fresh
  /// baseline reflects healed selections instead of opening dirty. Mirrors
  /// what the page inferred purely in memory before this conversion; the
  /// difference is that the inference is now persisted once (like Strength's
  /// load-time healing) so the healed state becomes the baseline itself.
  /// Returns whether anything was written.
  Future<bool> _healLegacyStrifeData({
    required ClassData classData,
    required HeroModel hero,
    required HeroRepository repo,
    required app_db.AppDatabase db,
  }) async {
    var healed = false;
    final baseline =
        ref.read(heroBuilderControllerProvider(widget.heroId)).baseline.strife;

    // Subclass skill hydration: backfill skill/skillGroup for legacy heroes
    // whose subclass choice predates the dedicated subclass:subclass_skill
    // entry row.
    final subclassSelection = subclassSelectionFromDraft(baseline.subclass);
    if (subclassSelection != null &&
        (subclassSelection.skill?.trim().isEmpty ?? true)) {
      final hydrated = await _hydrateSubclassSelection(
        classData: classData,
        selection: subclassSelection,
      );
      final hydratedSkillId = _resolveSkillId(hydrated?.skill);
      if (hydratedSkillId != null && hydratedSkillId.isNotEmpty) {
        await repo.saveSubclassSkill(widget.heroId, hydratedSkillId);
        await db.setHeroConfig(
          heroId: widget.heroId,
          configKey: 'strife.subclass_skill_id',
          value: {'id': hydratedSkillId},
        );
        healed = true;
      }
    }

    if (baseline.abilitySelections.isEmpty) {
      var abilityIds = await db.getHeroComponentIds(widget.heroId, 'ability');
      if (abilityIds.isEmpty) {
        final importedConfig = await db.getHeroConfigValue(
          widget.heroId,
          'strife.import_ability_ids',
        );
        final importedList = importedConfig?['list'] as List?;
        if (importedList != null && importedList.isNotEmpty) {
          abilityIds = importedList
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      final inferred = await _restoreAbilitySelections(
        classData: classData,
        selectedLevel: baseline.level,
        abilityIds: abilityIds,
      );
      if (inferred.isNotEmpty) {
        await db.setHeroConfig(
          heroId: widget.heroId,
          configKey: 'strife.ability_selections',
          value: inferred,
        );
        await db.deleteHeroConfig(widget.heroId, 'strife.import_ability_ids');
        healed = true;
      }
    }

    if (baseline.skillSelections.isEmpty) {
      final skillIds = await db.getHeroComponentIds(widget.heroId, 'skill');
      final inferred = await _restoreSkillSelections(
        classData: classData,
        selectedLevel: baseline.level,
        skillIds: skillIds,
        subclassSelection: subclassSelectionFromDraft(baseline.subclass),
      );
      if (inferred.isNotEmpty) {
        await db.setHeroConfig(
          heroId: widget.heroId,
          configKey: 'strife.skill_selections',
          value: inferred,
        );
        healed = true;
      }
    }

    if (baseline.perkSelections.isEmpty) {
      final perkIds = await db.getHeroComponentIds(widget.heroId, 'perk');
      final inferred = await _restorePerkSelections(
        classData: classData,
        selectedLevel: baseline.level,
        perkIds: perkIds,
      );
      if (inferred.isNotEmpty) {
        await db.setHeroConfig(
          heroId: widget.heroId,
          configKey: 'strife.perk_selections',
          value: inferred,
        );
        healed = true;
      }
    }

    final equipmentIds = baseline.equipmentIds;
    final hasEquipment =
        equipmentIds.any((id) => id != null && id.trim().isNotEmpty);
    if (hasEquipment) {
      final matched = await _matchEquipmentToSlots(
        classData: classData,
        equipmentIds: equipmentIds,
        db: db,
      );
      if (!const ListEquality<String?>().equals(matched, equipmentIds)) {
        await repo.saveEquipmentIds(widget.heroId, matched);
        healed = true;
      }
    }

    return healed;
  }

  Future<Map<String, String?>> _restoreAbilitySelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> abilityIds,
  }) async {
    if (abilityIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingAbilitiesService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final classSlug = _classSlug(classData.classId);
    final components = await _abilityDataService.loadClassAbilities(classSlug);
    final options = components.map(_mapComponentToAbilityOption).toList();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};
    final unmatched = <AbilityOption>[];

    for (final abilityId in abilityIds) {
      final option = optionById[abilityId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignAbility(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        unmatched.add(option);
      }
    }

    for (final option in unmatched) {
      _tryAssignAbility(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: true,
      );
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  Future<Map<String, String?>> _restoreSkillSelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> skillIds,
    required SubclassSelectionResult? subclassSelection,
  }) async {
    if (skillIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingSkillsService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
      subclassSelection: subclassSelection,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final options = await _skillDataService.loadSkills();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};

    for (final skillId in skillIds) {
      final option = optionById[skillId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignSkill(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        _tryAssignSkill(
          allowanceList: plan.allowances,
          filledCounts: filledCounts,
          selections: selections,
          option: option,
          ignoreConstraints: true,
        );
      }
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  String? _resolveSkillId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    return _skillIdLookup[lower] ?? _skillIdLookup[trimmed] ?? trimmed;
  }

  HeroConflictIndex get _strifeAbilityConflictIndex {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    if (entries == null) return HeroConflictIndex.empty;
    final perks = ref.watch(componentsByTypeProvider(HeroEntryTypes.perk));
    final abilities =
        ref.watch(componentsByTypeProvider(HeroEntryTypes.ability));

    return _buildStrifeAbilityConflictIndex(
      entries: entries,
      perks: perks.valueOrNull,
      abilities: abilities.valueOrNull,
    );
  }

  HeroConflictIndex _buildStrifeAbilityConflictIndex({
    required List<app_db.HeroEntry> entries,
    required List<Component>? perks,
    required List<Component>? abilities,
  }) {
    final persistedClaims =
        entries.where((entry) => entry.entryType == HeroEntryTypes.ability).map(
              (entry) => HeroEntryClaim(
                key: HeroEntryKey(
                  entryType: entry.entryType,
                  canonicalEntryId: entry.entryId,
                ),
                owner: HeroClaimOwner.persisted(
                  source: HeroClaimSource(
                    sourceType: entry.sourceType,
                    sourceId: entry.sourceId,
                  ),
                  displayLabel: entry.sourceId.trim().isEmpty
                      ? entry.sourceType
                      : '${entry.sourceType}:${entry.sourceId}',
                ),
              ),
            );

    return HeroConflictIndex.projected(
      persistedClaims: persistedClaims,
      mutationScopes: [
        HeroMutationScope.single(
          _strifeAbilityClaimSource,
          entryType: HeroEntryTypes.ability,
        ),
        for (final perkId in _currentSelectedPerkIds)
          HeroMutationScope.single(
            HeroClaimSource(
              sourceType: HeroEntrySourceTypes.perk,
              sourceId: perkId,
            ),
            entryType: HeroEntryTypes.ability,
          ),
      ],
      draftClaims: perks == null || abilities == null
          ? const []
          : _strifePerkAbilityDraftClaims(
              perks: perks,
              abilities: abilities,
            ),
    );
  }

  Iterable<HeroEntryClaim> _strifePerkAbilityDraftClaims({
    required List<Component> perks,
    required List<Component> abilities,
  }) sync* {
    final selectedPerkIds = _currentSelectedPerkIds;
    final abilityIds = <String, String>{
      for (final ability in abilities) ability.id.toLowerCase(): ability.id,
      for (final ability in abilities) ability.name.toLowerCase(): ability.id,
    };

    for (final perk
        in perks.where((perk) => selectedPerkIds.contains(perk.id))) {
      final grant = PerkGrant.fromJson(perk.data['grants']);
      if (grant == null) continue;
      for (final abilityGrant in _abilityGrantsFrom(grant)) {
        final abilityId = abilityGrant.abilityId?.trim().isNotEmpty == true
            ? abilityGrant.abilityId!.trim()
            : abilityIds[abilityGrant.abilityName.trim().toLowerCase()];
        if (abilityId == null || abilityId.isEmpty) continue;
        yield HeroEntryClaim(
          key: HeroEntryKey(
            entryType: HeroEntryTypes.ability,
            canonicalEntryId: abilityId,
          ),
          owner: HeroClaimOwner.draft(
            source: HeroClaimSource(
              sourceType: HeroEntrySourceTypes.perk,
              sourceId: perk.id,
            ),
            slotKey: 'strife.perks:grant:${perk.id}:$abilityId',
            displayLabel: '${perk.name} grant',
          ),
        );
      }
    }
  }

  Iterable<AbilityGrant> _abilityGrantsFrom(PerkGrant grant) sync* {
    switch (grant) {
      case AbilityGrant():
        yield grant;
      case MultiGrant(:final grants):
        for (final nested in grants) {
          yield* _abilityGrantsFrom(nested);
        }
      default:
        break;
    }
  }

  HeroConflictIndex get _strifeSkillConflictIndex {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    if (entries == null) return HeroConflictIndex.empty;

    final persistedClaims =
        entries.where((entry) => entry.entryType == HeroEntryTypes.skill).map(
              (entry) => HeroEntryClaim(
                key: HeroEntryKey(
                  entryType: entry.entryType,
                  canonicalEntryId: entry.entryId,
                ),
                owner: HeroClaimOwner.persisted(
                  source: HeroClaimSource(
                    sourceType: entry.sourceType,
                    sourceId: entry.sourceId,
                  ),
                  displayLabel: entry.sourceId.trim().isEmpty
                      ? entry.sourceType
                      : '${entry.sourceType}:${entry.sourceId}',
                ),
              ),
            );

    return HeroConflictIndex.projected(
      persistedClaims: persistedClaims,
      mutationScopes: [
        HeroMutationScope.single(
          _strifeSkillClaimSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _subclassSkillClaimSource,
          entryType: HeroEntryTypes.skill,
        ),
        ...entries
            .where(
              (entry) =>
                  entry.entryType == HeroEntryTypes.skill &&
                  entry.sourceType == HeroEntrySourceTypes.classEntry,
            )
            .map(
              (entry) => HeroMutationScope.single(
                HeroClaimSource(
                  sourceType: entry.sourceType,
                  sourceId: entry.sourceId,
                ),
                entryType: HeroEntryTypes.skill,
              ),
            ),
      ],
      draftClaims: _strifeSkillDraftClaims(),
    );
  }

  HeroConflictIndex get _strifePerkConflictIndex {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    if (entries == null) return HeroConflictIndex.empty;

    final persistedClaims =
        entries.where((entry) => entry.entryType == HeroEntryTypes.perk).map(
              (entry) => HeroEntryClaim(
                key: HeroEntryKey(
                  entryType: entry.entryType,
                  canonicalEntryId: entry.entryId,
                ),
                owner: HeroClaimOwner.persisted(
                  source: HeroClaimSource(
                    sourceType: entry.sourceType,
                    sourceId: entry.sourceId,
                  ),
                  displayLabel: entry.sourceId.trim().isEmpty
                      ? entry.sourceType
                      : '${entry.sourceType}:${entry.sourceId}',
                ),
              ),
            );

    final draftClaims = _strife.perkSelections.entries
        .where((selection) => selection.value?.trim().isNotEmpty == true)
        .map(
          (selection) => HeroEntryClaim(
            key: HeroEntryKey(
              entryType: HeroEntryTypes.perk,
              canonicalEntryId: selection.value!,
            ),
            owner: HeroClaimOwner.draft(
              source: _strifePerkClaimSource,
              slotKey: HeroDraftClaims.strifePerkSlot(selection.key),
              displayLabel: 'Strife perk choice',
            ),
          ),
        );

    return HeroConflictIndex.projected(
      persistedClaims: persistedClaims,
      mutationScopes: [
        HeroMutationScope.single(
          _strifePerkClaimSource,
          entryType: HeroEntryTypes.perk,
        ),
      ],
      draftClaims: draftClaims,
    );
  }

  Iterable<HeroEntryClaim> _strifeSkillDraftClaims() sync* {
    for (final selection in _strife.skillSelections.entries) {
      final skillId = _resolveSkillId(selection.value);
      if (skillId == null) continue;
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: skillId,
        ),
        owner: HeroClaimOwner.draft(
          source: _strifeSkillClaimSource,
          slotKey: HeroDraftClaims.strifeSkillSlot(selection.key),
          displayLabel: 'Strife skill choice',
        ),
      );
    }

    final subclassSkillId = _resolveSkillId(_selectedSubclass?.skill);
    if (subclassSkillId != null) {
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: subclassSkillId,
        ),
        owner: const HeroClaimOwner.draft(
          source: _subclassSkillClaimSource,
          slotKey: HeroDraftClaims.subclassSkillSlot,
          displayLabel: 'Subclass skill',
        ),
      );
    }

    for (final skillId in _skillGrantIds) {
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: skillId,
        ),
        owner: HeroClaimOwner.draft(
          source: HeroClaimSource(
            sourceType: HeroEntrySourceTypes.classEntry,
            sourceId: _selectedClass?.classId ?? 'class_grant',
          ),
          slotKey: 'strife.skills:grant:$skillId',
          displayLabel: 'Class skill grant',
        ),
      );
    }
  }

  HeroConflictIndex get _strifeEquipmentConflictIndex {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    if (entries == null) return HeroConflictIndex.empty;

    return _buildStrifeEquipmentConflictIndex(entries);
  }

  HeroConflictIndex _buildStrifeEquipmentConflictIndex(
    List<app_db.HeroEntry> entries,
  ) {
    return HeroConflictIndex.projected(
      persistedClaims: entries
          .where((entry) => entry.entryType == HeroEntryTypes.equipment)
          .map(
            (entry) => HeroEntryClaim(
              key: HeroEntryKey(
                entryType: entry.entryType,
                canonicalEntryId: entry.entryId,
              ),
              owner: HeroClaimOwner.persisted(
                source: HeroClaimSource(
                  sourceType: entry.sourceType,
                  sourceId: entry.sourceId,
                ),
                displayLabel: entry.sourceId.trim().isEmpty
                    ? entry.sourceType
                    : '${entry.sourceType}:${entry.sourceId}',
              ),
            ),
          ),
      mutationScopes: [
        HeroMutationScope.single(
          _strifeEquipmentClaimSource,
          entryType: HeroEntryTypes.equipment,
        ),
        ...entries
            .where(
              (entry) =>
                  entry.entryType == HeroEntryTypes.equipment &&
                  entry.sourceType == HeroEntrySourceTypes.kit,
            )
            .map(
              (entry) => HeroMutationScope.single(
                HeroClaimSource(
                  sourceType: entry.sourceType,
                  sourceId: entry.sourceId,
                ),
                entryType: HeroEntryTypes.equipment,
              ),
            ),
      ],
      draftClaims: _selectedKitIds
          .asMap()
          .entries
          .where((slot) => slot.value?.trim().isNotEmpty == true)
          .map(
            (slot) => HeroEntryClaim(
              key: HeroEntryKey(
                entryType: HeroEntryTypes.equipment,
                canonicalEntryId: slot.value!,
              ),
              owner: HeroClaimOwner.draft(
                source: _strifeEquipmentClaimSource,
                slotKey: _equipmentSlotKey(slot.key),
                displayLabel: 'Strife equipment slot ${slot.key + 1}',
              ),
            ),
          ),
    );
  }

  String _equipmentSlotKey(int index) => HeroDraftClaims.equipmentSlot(index);

  void _updateGrantIdsForCurrentPlan() {
    final classData = _selectedClass;
    if (classData == null) {
      setState(() => _skillGrantIds = {});
      return;
    }

    final plan = _startingSkillsService.buildPlan(
      classData: classData,
      selectedLevel: _strife.level,
      subclassSelection: _selectedSubclass,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );
    final grantIds =
        plan.grantedSkillNames.map(_resolveSkillId).whereType<String>().toSet();
    if (!const SetEquality<String>().equals(grantIds, _skillGrantIds)) {
      setState(() => _skillGrantIds = grantIds);
    }
  }

  Future<Map<String, String?>> _restorePerkSelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> perkIds,
  }) async {
    if (perkIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingPerksService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final options = await _perkDataService.loadPerks();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};

    for (final perkId in perkIds) {
      final option = optionById[perkId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignPerk(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        _tryAssignPerk(
          allowanceList: plan.allowances,
          filledCounts: filledCounts,
          selections: selections,
          option: option,
          ignoreConstraints: true,
        );
      }
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  bool _tryAssignAbility({
    required List<AbilityAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required AbilityOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsAbility(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsAbility({
    required AbilityAllowance allowance,
    required AbilityOption option,
  }) {
    if (allowance.isSignature != option.isSignature) {
      return false;
    }
    if (allowance.costAmount != null &&
        allowance.costAmount != option.costAmount) {
      return false;
    }
    final hasSubclass = option.subclass != null && option.subclass!.isNotEmpty;
    if (allowance.requiresSubclass && !hasSubclass) {
      return false;
    }
    if (!allowance.requiresSubclass && hasSubclass) {
      return false;
    }
    if (allowance.includePreviousLevels) {
      if (option.level > allowance.level) {
        return false;
      }
    } else {
      if (option.level != 0 && option.level != allowance.level) {
        return false;
      }
    }
    return true;
  }

  bool _tryAssignSkill({
    required List<SkillAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required SkillOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsSkill(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsSkill({
    required SkillAllowance allowance,
    required SkillOption option,
  }) {
    if (allowance.allowedGroups.isEmpty) {
      return true;
    }
    return allowance.allowedGroups.contains(option.group.toLowerCase());
  }

  bool _tryAssignPerk({
    required List<PerkAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required PerkOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsPerk(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsPerk({
    required PerkAllowance allowance,
    required PerkOption option,
  }) {
    if (allowance.allowedGroups.isEmpty) {
      return true;
    }
    return allowance.allowedGroups.contains(option.group.toLowerCase());
  }

  AbilityOption _mapComponentToAbilityOption(Component component) {
    final data = component.data;
    final costsRaw = data['costs'];

    final bool isSignature;
    if (costsRaw is String) {
      isSignature = costsRaw.toLowerCase() == 'signature';
    } else if (costsRaw is Map) {
      isSignature = costsRaw['signature'] == true;
    } else {
      isSignature = false;
    }

    final int? costAmount;
    final String? resource;
    if (costsRaw is Map) {
      final amountRaw = costsRaw['amount'];
      costAmount = amountRaw is num ? amountRaw.toInt() : null;
      resource = costsRaw['resource']?.toString();
    } else {
      costAmount = null;
      resource = null;
    }

    final level = data['level'] is num
        ? (data['level'] as num).toInt()
        : CharacteristicUtils.toIntOrNull(data['level']) ?? 0;
    final subclassRaw = data['subclass']?.toString().trim();
    final subclass =
        subclassRaw == null || subclassRaw.isEmpty ? null : subclassRaw;

    return AbilityOption(
      id: component.id,
      name: component.name,
      component: component,
      level: level,
      isSignature: isSignature,
      costAmount: costAmount,
      resource: resource,
      subclass: subclass,
    );
  }

  String _classSlug(String classId) {
    final normalized = classId.trim().toLowerCase();
    if (normalized.startsWith('class_')) {
      return normalized.substring('class_'.length);
    }
    return normalized;
  }

  Future<SubclassSelectionResult?> _hydrateSubclassSelection({
    required ClassData classData,
    required SubclassSelectionResult selection,
  }) async {
    try {
      final plan = _subclassPlanService.buildPlan(
        classData: classData,
        selectedLevel: _strife.level,
      );
      if (!plan.hasSubclassChoice || plan.subclassFeatureName == null) {
        return selection;
      }

      final data = await _subclassDataService.loadSubclassFeatureData(
        classSlug: _classSlug(classData.classId),
        featureName: plan.subclassFeatureName!,
      );
      final options = data?.options ?? const <SubclassOption>[];
      SubclassOption? option;
      if (selection.subclassKey != null) {
        option = options.firstWhereOrNull(
          (opt) => opt.key == selection.subclassKey,
        );
      }
      option ??= options.firstWhereOrNull(
        (opt) =>
            opt.name.toLowerCase() ==
            (selection.subclassName ?? '').toLowerCase(),
      );
      if (option == null) return selection;
      return selection.copyWith(
        subclassName: selection.subclassName ?? option.name,
        skill: option.skill ?? selection.skill,
        skillGroup: option.skillGroup ?? selection.skillGroup,
      );
    } catch (_) {
      return selection;
    }
  }

  /// A picker signalled an edit. Dirty state is derived by the shell from the
  /// controller; this just rebuilds the tab so any non-draft-backed local UI
  /// (e.g. the fixed skill-grant display) stays in sync.
  void _notifyDirty() {
    if (mounted) setState(() {});
  }

  void _handleLevelChanged(int level) {
    if (level == _strife.level) return;
    _controller.updateStrife((d) => d.copyWith(level: level));
    _updateGrantIdsForCurrentPlan();
    _notifyDirty();
  }

  void _handleClassChanged(ClassData classData) {
    if (_strife.classId == classData.classId) return;
    _controller.updateStrife(
      (d) => d.copyWith(
        classId: classData.classId,
        arrayDescription: null,
        arrayValues: const [],
        assignedCharacteristics: const {},
        levelChoiceSelections: const {},
        skillSelections: const {},
        abilitySelections: const {},
        perkSelections: const {},
        subclass: null,
        equipmentIds: const <String?>[],
      ),
    );
    setState(() {});
    _updateGrantIdsForCurrentPlan();
    _notifyDirty();
  }

  void _handleArrayChanged(CharacteristicArray? array) {
    if (_selectedArray == array) return;
    _controller.updateStrife(
      (d) => d.copyWith(
        arrayDescription: array?.description,
        arrayValues: array?.values ?? const [],
        assignedCharacteristics: const {},
      ),
    );
    _notifyDirty();
  }

  void _handleAssignmentsChanged(Map<String, int> assignments) {
    if (_deepEq.equals(_strife.assignedCharacteristics, assignments)) return;
    _controller
        .updateStrife((d) => d.copyWith(assignedCharacteristics: assignments));
    _notifyDirty();
  }

  void _handleFinalTotalsChanged(Map<String, int> totals) {
    // Not tracked by the draft. The original page never used the final
    // totals for anything beyond a dirty check that its own snapshot never
    // actually included, so there is nothing to forward here.
  }

  void _handleLevelChoiceSelectionsChanged(Map<String, String?> selections) {
    if (_deepEq.equals(_strife.levelChoiceSelections, selections)) return;
    _controller
        .updateStrife((d) => d.copyWith(levelChoiceSelections: selections));
    _notifyDirty();
  }

  void _handleSkillSelectionsChanged(StartingSkillSelectionResult result) {
    final sameSlots =
        _deepEq.equals(_strife.skillSelections, result.selectionsBySlot);
    final sameGrants =
        _deepEq.equals(_skillGrantIds, result.grantedSkillIds.toSet());
    if (sameSlots && sameGrants) return;
    _controller.updateStrife(
        (d) => d.copyWith(skillSelections: result.selectionsBySlot));
    setState(() {
      _skillGrantIds = Set<String>.from(result.grantedSkillIds);
    });
    _notifyDirty();
  }

  void _handlePerkSelectionsChanged(StartingPerkSelectionResult result) {
    if (_deepEq.equals(_strife.perkSelections, result.selectionsBySlot)) return;
    _controller.updateStrife(
        (d) => d.copyWith(perkSelections: result.selectionsBySlot));
    _notifyDirty();
  }

  void _handleAbilitySelectionsChanged(StartingAbilitySelectionResult result) {
    if (_deepEq.equals(_strife.abilitySelections, result.selectionsBySlot)) {
      return;
    }
    _controller.updateStrife(
      (d) => d.copyWith(abilitySelections: result.selectionsBySlot),
    );
    _notifyDirty();
  }

  void _handleSubclassSelectionChanged(SubclassSelectionResult result) {
    final current = _selectedSubclass;
    final sameDeity = current?.deityId == result.deityId;
    final sameSubclass = current?.subclassName == result.subclassName &&
        current?.subclassKey == result.subclassKey;
    final sameDomains = _deepEq.equals(
        current?.domainNames ?? const <String>[], result.domainNames);
    if (sameDeity && sameSubclass && sameDomains) return;
    _controller.updateStrife(
      (d) => d.copyWith(
        subclass: StrifeSubclassDraft(
          subclassKey: result.subclassKey,
          subclassName: result.subclassName,
          skillId: _resolveSkillId(result.skill),
          deityId: result.deityId,
          domainNames: result.domainNames,
        ),
      ),
    );
    _updateGrantIdsForCurrentPlan();
    _notifyDirty();
  }

  void _handleKitChangedAtSlot(int slotIndex, String? kitId) {
    final current = _selectedKitIds;
    if (slotIndex < current.length && current[slotIndex] == kitId) {
      return;
    }
    _controller.updateStrife((d) {
      final ids = List<String?>.from(d.equipmentIds);
      while (ids.length <= slotIndex) {
        ids.add(null);
      }
      ids[slotIndex] = kitId;
      return d.copyWith(equipmentIds: ids);
    });
    _notifyDirty();
  }

  List<Widget> _buildKitWidgets() {
    final classData = _selectedClass;
    if (classData == null) return [];

    final slots = _determineKitSlots(classData);
    if (slots.isEmpty) return [];

    final totalSlots = slots.fold<int>(0, (sum, slot) => sum + slot.count);
    final kitIds = List<String?>.from(_selectedKitIds);
    while (kitIds.length < totalSlots) {
      kitIds.add(null);
    }

    final equipmentSlots = <EquipmentSlot>[];
    final equipmentConflictIndex = _strifeEquipmentConflictIndex;
    var kitIndex = 0;

    for (final slot in slots) {
      for (var i = 0; i < slot.count; i++) {
        final currentIndex = kitIndex;
        final label = _buildEquipmentSlotLabel(
          allowedTypes: slot.allowedTypes,
          groupCount: slot.count,
          indexWithinGroup: i,
          globalIndex: kitIndex,
        );
        final helperText = slot.allowedTypes.length > 1
            ? 'Allowed types: ${slot.allowedTypes.map(_formatKitTypeName).join(', ')}'
            : null;

        final currentSelection =
            currentIndex < kitIds.length ? kitIds[currentIndex] : null;

        equipmentSlots.add(
          EquipmentSlot(
            label: label,
            allowedTypes: slot.allowedTypes,
            selectedItemId: currentSelection,
            onChanged: (kitId) => _handleKitChangedAtSlot(currentIndex, kitId),
            helperText: helperText,
            classId: classData.classId,
            conflictIndex: equipmentConflictIndex,
            slotKey: _equipmentSlotKey(currentIndex),
          ),
        );
        kitIndex++;
      }
    }

    return [
      EquipmentAndModificationsWidget(
        key: const ValueKey('equipment_and_modifications'),
        slots: equipmentSlots,
      ),
    ];
  }

  String _buildEquipmentSlotLabel({
    required List<String> allowedTypes,
    required int groupCount,
    required int indexWithinGroup,
    required int globalIndex,
  }) {
    if (allowedTypes.length == 1) {
      final base = _formatKitTypeName(allowedTypes.first);
      if (groupCount > 1) {
        return '$base ${indexWithinGroup + 1}';
      }
      return base;
    }
    return 'Equipment ${globalIndex + 1}';
  }

  String _formatKitTypeName(String type) {
    switch (type) {
      case 'psionic_augmentation':
        return 'Psionic Augmentation';
      case 'stormwight_kit':
        return 'Stormwight Kit';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  /// Match loaded equipment IDs to the correct slots based on their types
  Future<List<String?>> _matchEquipmentToSlots({
    required ClassData classData,
    required List<String?> equipmentIds,
    required app_db.AppDatabase db,
  }) async {
    final slots = _determineKitSlots(classData);
    if (slots.isEmpty) return <String?>[];

    // Build flat list of slot allowed types
    final slotTypes = <List<String>>[];
    for (final slot in slots) {
      for (var i = 0; i < slot.count; i++) {
        slotTypes.add(slot.allowedTypes);
      }
    }

    // Initialize result with nulls
    final result = List<String?>.filled(slotTypes.length, null);
    final usedIds = <String>{};

    // Load equipment types for each ID
    final equipmentTypes = <String, String>{};
    for (final id in equipmentIds) {
      if (id == null || id.isEmpty) {
        continue;
      }
      final component = await db.getComponentById(id);
      if (component != null) {
        equipmentTypes[id] = component.type;
      }
    }

    // First pass: match equipment to slots where type exactly matches
    for (var slotIndex = 0; slotIndex < slotTypes.length; slotIndex++) {
      final allowedTypes = slotTypes[slotIndex];
      for (final id in equipmentIds) {
        if (id == null || id.isEmpty) continue;
        if (usedIds.contains(id)) continue;
        final type = equipmentTypes[id];
        if (type != null && allowedTypes.contains(type)) {
          result[slotIndex] = id;
          usedIds.add(id);
          break;
        }
      }
    }

    // Second pass: fill remaining slots with any remaining equipment
    for (var slotIndex = 0; slotIndex < result.length; slotIndex++) {
      if (result[slotIndex] != null) continue;
      for (final id in equipmentIds) {
        if (id == null || id.isEmpty) continue;
        if (usedIds.contains(id)) continue;
        result[slotIndex] = id;
        usedIds.add(id);
        break;
      }
    }

    return result;
  }

  /// Determines kit slots and allowed types for each slot
  /// Returns list of (count, [allowed types]) pairs
  List<({int count, List<String> allowedTypes})> _determineKitSlots(
    ClassData classData,
  ) {
    // Special case: Stormwight Fury - only stormwight kits
    final subclassName = _selectedSubclass?.subclassName?.toLowerCase() ?? '';
    if (classData.classId == 'class_fury' && subclassName == 'stormwight') {
      return [
        (count: 1, allowedTypes: ['stormwight_kit'])
      ];
    }

    final kitFeatures = <Map<String, dynamic>>[];
    final typesList = <String>[];

    // Collect all kit-related features
    for (final level in classData.levels) {
      for (final feature in level.features) {
        final name = feature.name.trim().toLowerCase();
        if (name == 'kit' || _kitFeatureTypeMappings.containsKey(name)) {
          kitFeatures.add({
            'name': name,
            'count': feature.count ?? 1,
          });

          final mapped = _kitFeatureTypeMappings[name];
          if (mapped != null) {
            typesList.addAll(mapped);
          } else if (name == 'kit') {
            typesList.add('kit');
          }
        }
      }
    }

    if (kitFeatures.isEmpty) {
      return [];
    }

    // Remove duplicates while preserving order
    final uniqueTypes = <String>[];
    final seen = <String>{};
    for (final type in typesList) {
      if (seen.add(type)) {
        uniqueTypes.add(type);
      }
    }

    // Calculate total count needed
    var totalCount = 0;
    for (final feature in kitFeatures) {
      totalCount += feature['count'] as int;
    }

    // If we have multiple types and count > 1, create one slot per type
    if (uniqueTypes.length > 1 && totalCount >= uniqueTypes.length) {
      return uniqueTypes
          .map((type) => (count: 1, allowedTypes: [type]))
          .toList();
    }

    // Otherwise, create slots of the same type
    final sortedTypes = _sortKitTypesByPriority(uniqueTypes);
    return [
      (count: totalCount, allowedTypes: sortedTypes),
    ];
  }

  List<String> _sortKitTypesByPriority(Iterable<String> types) {
    final seen = <String>{};
    final sorted = <String>[];

    for (final type in _kitTypePriority) {
      if (types.contains(type) && seen.add(type)) {
        sorted.add(type);
      }
    }

    for (final type in types) {
      if (seen.add(type)) {
        sorted.add(type);
      }
    }

    return sorted;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Recompute the fixed class-skill grants when the class/level/subclass are
    // changed by the controller rather than by a picker — i.e. on a shell-driven
    // Discard or reload (the picker handlers already recompute inline). Grant ids
    // are derived display state, not a player choice, so they live outside the
    // draft and must be resynced explicitly.
    ref.listen<StrifeDraft>(
      heroBuilderStrifeDraftProvider(widget.heroId),
      (previous, next) {
        if (previous == null) return;
        if (previous.classId != next.classId ||
            previous.level != next.level ||
            previous.subclass != next.subclass) {
          _updateGrantIdsForCurrentPlan();
        }
      },
    );

    final strife = _strife;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _load();
                },
                child: const Text(StrifeCreatorPageText.retryLabel),
              ),
            ],
          ),
        ),
      );
    }

    final selectedClass = _selectedClass;
    final selectedSubclass = _selectedSubclass;

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('strife_creator_scroll_view'),
        child: Column(
          children: [
            // Level Selector
            LevelSelectorWidget(
              key: const ValueKey('level_selector'),
              selectedLevel: strife.level,
              onLevelChanged: _handleLevelChanged,
            ),

            // Class Selector
            ClassSelectorWidget(
              key: const ValueKey('class_selector'),
              availableClasses: _classDataService.getAllClasses(),
              selectedClass: selectedClass,
              selectedLevel: strife.level,
              onClassChanged: _handleClassChanged,
            ),

            if (selectedClass != null) ...[
              ChooseSubclassWidget(
                key: const ValueKey('choose_subclass'),
                classData: selectedClass,
                selectedLevel: strife.level,
                selectedSubclass: selectedSubclass,
                onSelectionChanged: _handleSubclassSelectionChanged,
                skillConflictIndex: _strifeSkillConflictIndex,
                skillNameToIdLookup: _skillIdLookup,
              ),
              StartingCharacteristicsWidget(
                key: const ValueKey('starting_characteristics'),
                classData: selectedClass,
                selectedLevel: strife.level,
                selectedArray: _selectedArray,
                assignedCharacteristics: strife.assignedCharacteristics,
                initialLevelChoiceSelections: strife.levelChoiceSelections,
                onArrayChanged: _handleArrayChanged,
                onAssignmentsChanged: _handleAssignmentsChanged,
                onFinalTotalsChanged: _handleFinalTotalsChanged,
                onLevelChoiceSelectionsChanged:
                    _handleLevelChoiceSelectionsChanged,
              ),
              ..._buildKitWidgets(),
              StartingAbilitiesWidget(
                key: const ValueKey('starting_abilities'),
                classData: selectedClass,
                selectedLevel: strife.level,
                selectedSubclassName: selectedSubclass?.subclassName,
                selectedDomainNames: selectedSubclass?.domainNames ?? const [],
                selectedAbilities: strife.abilitySelections,
                conflictIndex: _strifeAbilityConflictIndex,
                onSelectionChanged: _handleAbilitySelectionsChanged,
              ),
              StartingSkillsWidget(
                key: const ValueKey('starting_skills'),
                classData: selectedClass,
                selectedLevel: strife.level,
                selectedSubclass: selectedSubclass,
                selectedSkills: strife.skillSelections,
                conflictIndex: _strifeSkillConflictIndex,
                onSelectionChanged: _handleSkillSelectionsChanged,
              ),
              StartingPerksWidget(
                key: const ValueKey('starting_perks'),
                heroId: widget.heroId,
                classData: selectedClass,
                selectedLevel: strife.level,
                selectedPerks: strife.perkSelections,
                conflictIndex: _strifePerkConflictIndex,
                skillConflictIndex: _strifeSkillConflictIndex,
                // `one_owned` perk grants need the projected effective skill
                // set. Duplicate filtering for new skill/language grants is
                // source-scoped inside PerksSelectionWidget.
                ownedSkillIds: _strifeSkillConflictIndex
                    .claimedEntryIds(HeroEntryTypes.skill),
                onSelectionChanged: _handlePerkSelectionsChanged,
              ),
            ],

            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Public type alias for accessing the internal state from parent widgets.
typedef StrifeCreatorPageState = _StrifeCreatorPageState;
