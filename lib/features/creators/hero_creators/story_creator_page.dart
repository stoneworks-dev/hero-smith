import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/core/storage/hero_storage_contract.dart';
import 'package:hero_smith/core/text/creators/hero_creators/story_creator_page_text.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_ancestry_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_career_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_complication_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_culture_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_name_section.dart';
import 'package:hero_smith/features/hero_builder/application/hero_builder_controller.dart';
import 'package:hero_smith/features/hero_builder/application/hero_builder_providers.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_claim.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_conflict_index.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_draft.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_draft_claims.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_mutation_scope.dart';

class StoryCreatorTab extends ConsumerStatefulWidget {
  const StoryCreatorTab({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<StoryCreatorTab> createState() => StoryCreatorTabState();
}

class StoryCreatorTabState extends ConsumerState<StoryCreatorTab>
    with AutomaticKeepAliveClientMixin {
  // Ownership vocabulary is shared with the hero-builder draft mapping so the
  // page and the controller cannot disagree about who owns a slot.
  static const _cultureLanguageSource = HeroDraftClaims.cultureLanguageSource;
  static const _careerLanguageSource = HeroDraftClaims.careerChoiceSource;
  static const _cultureEnvironmentSource =
      HeroDraftClaims.cultureEnvironmentSource;
  static const _cultureOrganisationSource =
      HeroDraftClaims.cultureOrganisationSource;
  static const _cultureUpbringingSource =
      HeroDraftClaims.cultureUpbringingSource;
  static const _careerChoiceSource = HeroDraftClaims.careerChoiceSource;

  final TextEditingController _nameCtrl = TextEditingController();

  bool _hasLoadedOnce = false;

  HeroBuilderController get _controller =>
      ref.read(heroBuilderControllerProvider(widget.heroId).notifier);

  /// The Story section's current draft. Ancestry and complication grants are
  /// still page-local (they need async expansion before joining
  /// [HeroDraftClaims]), but their values now live on this same draft object
  /// so discard and commit stay in sync automatically.
  StoryDraft get _story =>
      ref.watch(heroBuilderStoryDraftProvider(widget.heroId));

  HeroConflictIndex get _storyLanguageConflictIndex {
    return _storyConflictIndex(
      entryType: HeroEntryTypes.language,
      mutationScopes: [
        HeroMutationScope.single(
          _cultureLanguageSource,
          entryType: HeroEntryTypes.language,
        ),
        HeroMutationScope.single(
          _careerLanguageSource,
          entryType: HeroEntryTypes.language,
        ),
      ],
      draftClaims: _storyLanguageDraftClaims(),
    );
  }

  HeroConflictIndex get _storySkillConflictIndex {
    return _storyConflictIndex(
      entryType: HeroEntryTypes.skill,
      mutationScopes: [
        ..._persistedSourceScopes(
          sourceType: HeroEntrySourceTypes.ancestry,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureEnvironmentSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureOrganisationSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureUpbringingSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _careerChoiceSource,
          entryType: HeroEntryTypes.skill,
        ),
      ],
      draftClaims: _storySkillDraftClaims(),
    );
  }

  HeroConflictIndex get _complicationConflictIndex {
    final story = _story;
    final baselineStory =
        ref.watch(heroBuilderControllerProvider(widget.heroId)).baseline.story;
    final complicationSources = <HeroClaimSource>{};
    for (final id in [baselineStory.complicationId, story.complicationId]) {
      final normalized = id?.trim();
      if (normalized == null || normalized.isEmpty) continue;
      complicationSources.add(
        HeroClaimSource(
          sourceType: HeroEntrySourceTypes.complication,
          sourceId: normalized,
        ),
      );
      complicationSources.add(
        HeroClaimSource(
          sourceType: HeroEntrySourceTypes.complicationAncestryTrait,
          sourceId: normalized,
        ),
      );
    }

    return _storyConflictIndex(
      mutationScopes: [
        ...complicationSources.map(HeroMutationScope.single),
        HeroMutationScope.single(
          const HeroClaimSource(
            sourceType: 'manual_choice',
            sourceId: HeroEntryTypes.complication,
          ),
          entryType: HeroEntryTypes.complication,
        ),
        ..._persistedSourceScopes(
          sourceType: HeroEntrySourceTypes.ancestry,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureLanguageSource,
          entryType: HeroEntryTypes.language,
        ),
        HeroMutationScope.single(
          _careerLanguageSource,
          entryType: HeroEntryTypes.language,
        ),
        HeroMutationScope.single(
          _cultureEnvironmentSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureOrganisationSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _cultureUpbringingSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _careerChoiceSource,
          entryType: HeroEntryTypes.skill,
        ),
        HeroMutationScope.single(
          _careerChoiceSource,
          entryType: HeroEntryTypes.perk,
        ),
      ],
      draftClaims: [
        ..._storyLanguageDraftClaims(),
        ..._storySkillDraftClaims(),
        ..._storyPerkDraftClaims(),
        ..._complicationSelectionDraftClaims(),
      ],
    );
  }

  Iterable<HeroMutationScope> _persistedSourceScopes({
    required String sourceType,
    required String entryType,
  }) sync* {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    final sources = (entries ?? const [])
        .where(
          (entry) =>
              entry.entryType == entryType && entry.sourceType == sourceType,
        )
        .map(
          (entry) => HeroClaimSource(
            sourceType: entry.sourceType,
            sourceId: entry.sourceId,
          ),
        )
        .toSet();
    for (final source in sources) {
      yield HeroMutationScope.single(source, entryType: entryType);
    }
  }

  HeroConflictIndex get _storyPerkConflictIndex {
    return _storyConflictIndex(
      entryType: HeroEntryTypes.perk,
      mutationScopes: [
        HeroMutationScope.single(
          _careerChoiceSource,
          entryType: HeroEntryTypes.perk,
        ),
      ],
      draftClaims: _storyPerkDraftClaims(),
    );
  }

  HeroConflictIndex _storyConflictIndex({
    String? entryType,
    required Iterable<HeroMutationScope> mutationScopes,
    required Iterable<HeroEntryClaim> draftClaims,
  }) {
    final entries = ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull;
    final persistedClaims = (entries ?? const [])
        .where((entry) => entryType == null || entry.entryType == entryType)
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
        );
    return HeroConflictIndex.projected(
      persistedClaims: persistedClaims,
      mutationScopes: mutationScopes,
      draftClaims: draftClaims,
    );
  }

  /// Shared culture/career claims for one entry type. Sources and slot keys
  /// come from [HeroDraftClaims], so this page and the draft controller stay
  /// interchangeable.
  Iterable<HeroEntryClaim> _sharedStoryDraftClaims(String entryType) {
    return HeroDraftClaims.draftClaims(
      story: _story,
      strife: StrifeDraft(),
      strength: StrengthDraft(),
    ).where((claim) => claim.key.normalizedEntryType == entryType);
  }

  Iterable<HeroEntryClaim> _storyLanguageDraftClaims() =>
      _sharedStoryDraftClaims(HeroEntryTypes.language);

  Iterable<HeroEntryClaim> _storySkillDraftClaims() sync* {
    yield* _ancestrySkillDraftClaims();
    yield* _sharedStoryDraftClaims(HeroEntryTypes.skill);
  }

  Iterable<HeroEntryClaim> _ancestrySkillDraftClaims() sync* {
    final ancestrySource = HeroClaimSource(
      sourceType: HeroEntrySourceTypes.ancestry,
      sourceId: _story.ancestryId?.trim() ?? '',
    );
    for (final choice in _story.ancestryTraitChoices.entries) {
      final entryId = choice.value.trim();
      if (!entryId.startsWith('skill_')) continue;
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: entryId,
        ),
        owner: HeroClaimOwner.draft(
          source: ancestrySource,
          slotKey: 'story.ancestry:${choice.key}',
          displayLabel: 'Ancestry skill choice',
        ),
      );
    }
  }

  Iterable<HeroEntryClaim> _storyPerkDraftClaims() =>
      _sharedStoryDraftClaims(HeroEntryTypes.perk);

  HeroConflictIndex get _storyAncestryAbilityConflictIndex {
    final baselineStory =
        ref.watch(heroBuilderControllerProvider(widget.heroId)).baseline.story;
    final loadedAncestryId = baselineStory.ancestryId?.trim();
    final selectedAncestryId = _story.ancestryId?.trim();
    final scopes = <HeroMutationScope>[];
    if (loadedAncestryId != null && loadedAncestryId.isNotEmpty) {
      final source = HeroClaimSource(
        sourceType: HeroEntrySourceTypes.ancestry,
        sourceId: loadedAncestryId,
      );
      if (loadedAncestryId != selectedAncestryId) {
        scopes.add(
          HeroMutationScope.single(source, entryType: HeroEntryTypes.ability),
        );
      } else {
        scopes.add(
          HeroMutationScope.single(
            source,
            entryType: HeroEntryTypes.ability,
            entryIds: _abilityIdsForChoices(baselineStory.ancestryTraitChoices),
          ),
        );
      }
    }
    return _storyConflictIndex(
      entryType: HeroEntryTypes.ability,
      mutationScopes: scopes,
      draftClaims: _ancestryAbilityDraftClaims(),
    );
  }

  HeroConflictIndex get _storyAncestryTraitConflictIndex => _storyConflictIndex(
        entryType: HeroEntryTypes.ancestryTrait,
        mutationScopes: _persistedSourceScopes(
          sourceType: HeroEntrySourceTypes.ancestry,
          entryType: HeroEntryTypes.ancestryTrait,
        ),
        draftClaims: _ancestryTraitDraftClaims(),
      );

  HeroConflictIndex get _storyAncestrySelectionConflictIndex =>
      _storyConflictIndex(
        entryType: HeroEntryTypes.ancestry,
        mutationScopes: _persistedSourceScopes(
          sourceType: HeroEntrySourceTypes.ancestry,
          entryType: HeroEntryTypes.ancestry,
        ),
        draftClaims: _ancestrySelectionDraftClaims(),
      );

  Iterable<HeroEntryClaim> _complicationSelectionDraftClaims() sync* {
    final complicationId = _story.complicationId?.trim();
    if (complicationId == null || complicationId.isEmpty) return;
    yield HeroEntryClaim(
      key: HeroEntryKey(
        entryType: HeroEntryTypes.complication,
        canonicalEntryId: complicationId,
      ),
      owner: const HeroClaimOwner.draft(
        source: HeroClaimSource(
          sourceType: 'manual_choice',
          sourceId: HeroEntryTypes.complication,
        ),
        slotKey: 'story.complication:selection#0',
        displayLabel: 'Story complication',
      ),
    );
  }

  Iterable<HeroEntryClaim> _ancestryAbilityDraftClaims() sync* {
    final source = HeroClaimSource(
      sourceType: HeroEntrySourceTypes.ancestry,
      sourceId: _story.ancestryId?.trim() ?? '',
    );
    for (final choice in _story.ancestryTraitChoices.entries) {
      final abilityIds = _abilityIdsForChoices({choice.key: choice.value});
      if (abilityIds.isEmpty) continue;
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.ability,
          canonicalEntryId: abilityIds.single,
        ),
        owner: HeroClaimOwner.draft(
          source: source,
          slotKey: 'story.ancestry:${choice.key}',
          displayLabel: 'Ancestry ability choice',
        ),
      );
    }
  }

  Set<String> _abilityIdsForChoices(Map<String, String> choices) {
    final abilities =
        ref.watch(selectableComponentsByTypeProvider('ability')).valueOrNull ??
            const [];
    final ids = <String>{};
    for (final value in choices.values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      for (final ability in abilities) {
        if (ability.id == normalized ||
            ability.name.trim().toLowerCase() == normalized.toLowerCase()) {
          ids.add(ability.id);
          break;
        }
      }
    }
    return ids;
  }

  Iterable<HeroEntryClaim> _ancestryTraitDraftClaims() sync* {
    final source = HeroClaimSource(
      sourceType: HeroEntrySourceTypes.ancestry,
      sourceId: _story.ancestryId?.trim() ?? '',
    );
    for (final traitId in _story.ancestryTraitIds) {
      yield HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.ancestryTrait,
          canonicalEntryId: traitId,
        ),
        owner: HeroClaimOwner.draft(
          source: source,
          slotKey: 'story.ancestry:trait:$traitId',
          displayLabel: 'Ancestry trait',
        ),
      );
    }
  }

  Iterable<HeroEntryClaim> _ancestrySelectionDraftClaims() sync* {
    final ancestryId = _story.ancestryId?.trim();
    if (ancestryId == null || ancestryId.isEmpty) return;
    yield HeroEntryClaim(
      key: HeroEntryKey(
        entryType: HeroEntryTypes.ancestry,
        canonicalEntryId: ancestryId,
      ),
      owner: HeroClaimOwner.draft(
        source: HeroClaimSource(
          sourceType: HeroEntrySourceTypes.ancestry,
          sourceId: ancestryId,
        ),
        slotKey: 'story.ancestry:selection#0',
        displayLabel: 'Story ancestry',
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_handleNameChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    _controller.updateStory((draft) => draft.copyWith(name: _nameCtrl.text));
  }

  /// Child sections signal an edit through `onDirty`. Dirty state itself is now
  /// derived by the shell from the controller; this just rebuilds the tab so any
  /// non-draft-backed local UI stays in sync.
  void _notifyDirty() {
    if (mounted) setState(() {});
  }

  void _onAncestryChanged(String? value) {
    _controller.updateStory(
      (draft) => draft.copyWith(
        ancestryId: value,
        ancestryTraitIds: const {},
        ancestryTraitChoices: const {},
      ),
    );
    _notifyDirty();
  }

  void _onTraitSelectionChanged(String traitId, bool isSelected) {
    _controller.updateStory((draft) {
      final traitIds = Set<String>.from(draft.ancestryTraitIds);
      final traitChoices = Map<String, String>.from(draft.ancestryTraitChoices);
      if (isSelected) {
        traitIds.add(traitId);
      } else {
        traitIds.remove(traitId);
        traitChoices.remove(traitId);
      }
      return draft.copyWith(
        ancestryTraitIds: traitIds,
        ancestryTraitChoices: traitChoices,
      );
    });
    _notifyDirty();
  }

  void _onTraitChoiceChanged(String traitOrSignatureId, String choiceValue) {
    _controller.updateStory((draft) {
      final traitChoices = Map<String, String>.from(draft.ancestryTraitChoices)
        ..[traitOrSignatureId] = choiceValue;
      return draft.copyWith(ancestryTraitChoices: traitChoices);
    });
    _notifyDirty();
  }

  void _onLanguageChanged(String? value) {
    _controller.updateStory((draft) {
      final careerLanguageIds = [
        for (final id in draft.careerLanguageIds) id == value ? null : id,
      ];
      return draft.copyWith(
        cultureLanguageId: value,
        careerLanguageIds: careerLanguageIds,
      );
    });
    _notifyDirty();
  }

  void _onEnvironmentChanged(String? value) {
    _controller.updateStory((draft) => draft.copyWith(environmentId: value));
    _notifyDirty();
  }

  void _onOrganisationChanged(String? value) {
    _controller.updateStory((draft) => draft.copyWith(organisationId: value));
    _notifyDirty();
  }

  void _onUpbringingChanged(String? value) {
    _controller.updateStory((draft) => draft.copyWith(upbringingId: value));
    _notifyDirty();
  }

  void _onEnvironmentSkillChanged(String? value) {
    _controller
        .updateStory((draft) => draft.copyWith(environmentSkillId: value));
    _notifyDirty();
  }

  void _onOrganisationSkillChanged(String? value) {
    _controller
        .updateStory((draft) => draft.copyWith(organisationSkillId: value));
    _notifyDirty();
  }

  void _onUpbringingSkillChanged(String? value) {
    _controller
        .updateStory((draft) => draft.copyWith(upbringingSkillId: value));
    _notifyDirty();
  }

  void _onCareerChanged(String? value) {
    _controller.updateStory(
      (draft) => draft.copyWith(
        careerId: value,
        careerSkillIds: const {},
        careerPerkIds: const {},
        careerIncidentName: null,
        careerLanguageIds: const <String?>[],
      ),
    );
    _notifyDirty();
  }

  void _onCareerLanguageSlotsChanged(int slots) {
    final normalized = slots.clamp(0, 10);
    StoryDraft resize(StoryDraft draft) {
      if (normalized == draft.careerLanguageIds.length) return draft;
      final ids = List<String?>.of(draft.careerLanguageIds);
      if (ids.length > normalized) {
        return draft.copyWith(
          careerLanguageIds: ids.take(normalized).toList(),
        );
      }
      ids.addAll(
        List<String?>.filled(normalized - ids.length, null, growable: false),
      );
      return draft.copyWith(careerLanguageIds: ids);
    }

    // The career's granted language-slot count is derived from career data and
    // recomputed on every load. Padding the persisted slots out to that count
    // (e.g. a hero who chose 1 of 2 granted slots loads with a length-1 list)
    // must not open the tab dirty. When the Story section is otherwise clean,
    // fold the resize into the baseline; if the user already has a pending edit,
    // treat it as a normal draft change so the dirty state is preserved.
    final storyDirty =
        ref.read(heroBuilderControllerProvider(widget.heroId)).storyDirty;
    if (storyDirty) {
      _controller.updateStory(resize);
    } else {
      _controller.adoptStory(resize);
    }
    _notifyDirty();
  }

  void _onCareerLanguageChanged(int index, String? value) {
    if (index < 0) return;
    _controller.updateStory((draft) {
      final ids = List<String?>.of(draft.careerLanguageIds);
      while (ids.length <= index) {
        ids.add(null);
      }
      if (ids[index] == value) return draft;
      ids[index] = value;
      return draft.copyWith(careerLanguageIds: ids);
    });
    _notifyDirty();
  }

  void _onCareerSkillsChanged(Set<String> ids) {
    _controller.updateStory((draft) => draft.copyWith(careerSkillIds: ids));
    _notifyDirty();
  }

  void _onCareerPerksChanged(Set<String> ids) {
    _controller.updateStory((draft) => draft.copyWith(careerPerkIds: ids));
    _notifyDirty();
  }

  void _onIncidentChanged(String? value) {
    _controller
        .updateStory((draft) => draft.copyWith(careerIncidentName: value));
    _notifyDirty();
  }

  void _onComplicationChanged(String? value) {
    _controller.updateStory(
      (draft) => draft.copyWith(
        complicationId: value,
        complicationChoices: const {},
      ),
    );
    _notifyDirty();
  }

  void _onComplicationChoicesChanged(Map<String, String> choices) {
    _controller
        .updateStory((draft) => draft.copyWith(complicationChoices: choices));
    _notifyDirty();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final builderState =
        ref.watch(heroBuilderControllerProvider(widget.heroId));

    ref.listen<HeroBuilderState>(
      heroBuilderControllerProvider(widget.heroId),
      (previous, next) {
        if (previous?.baseline.revision != next.baseline.revision) {
          _hasLoadedOnce = true;
        }
        // Resync the name field whenever the draft name is changed by the
        // controller rather than by typing — i.e. on load/reload (baseline
        // revision bump) and on a shell-driven Discard (draft reverts to
        // baseline without a revision change). During editing the listener
        // keeps `_nameCtrl.text` and `draft.name` equal, so this never fights
        // the user's keystrokes.
        if (_nameCtrl.text != next.story.name) {
          _nameCtrl.text = next.story.name;
        }
      },
    );

    if (builderState.isLoading && !_hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    if (builderState.lastError != null && !_hasLoadedOnce) {
      return _ErrorView(
        message: builderState.lastError!,
        onRetry: () => _controller.reload(),
      );
    }

    if (!_hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    final story = builderState.story;

    final languageConflictIndex = _storyLanguageConflictIndex;
    final skillConflictIndex = _storySkillConflictIndex;
    final perkConflictIndex = _storyPerkConflictIndex;
    final ancestryAbilityConflictIndex = _storyAncestryAbilityConflictIndex;
    final ancestryTraitConflictIndex = _storyAncestryTraitConflictIndex;
    final ancestrySelectionConflictIndex = _storyAncestrySelectionConflictIndex;
    final complicationConflictIndex = _complicationConflictIndex;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: StoryNameSection(
            nameController: _nameCtrl,
            selectedAncestryId: story.ancestryId,
            onDirty: _notifyDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryAncestrySection(
            selectedAncestryId: story.ancestryId,
            selectedTraitIds: story.ancestryTraitIds,
            traitChoices: story.ancestryTraitChoices,
            skillConflictIndex: skillConflictIndex,
            abilityConflictIndex: ancestryAbilityConflictIndex,
            traitConflictIndex: ancestryTraitConflictIndex,
            ancestryConflictIndex: ancestrySelectionConflictIndex,
            onAncestryChanged: _onAncestryChanged,
            onTraitSelectionChanged: _onTraitSelectionChanged,
            onTraitChoiceChanged: _onTraitChoiceChanged,
            onDirty: _notifyDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryCultureSection(
            selectedAncestryId: story.ancestryId,
            environmentId: story.environmentId,
            organisationId: story.organisationId,
            upbringingId: story.upbringingId,
            selectedLanguageId: story.cultureLanguageId,
            languageConflictIndex: languageConflictIndex,
            environmentSkillId: story.environmentSkillId,
            organisationSkillId: story.organisationSkillId,
            upbringingSkillId: story.upbringingSkillId,
            skillConflictIndex: skillConflictIndex,
            onLanguageChanged: _onLanguageChanged,
            onEnvironmentChanged: _onEnvironmentChanged,
            onOrganisationChanged: _onOrganisationChanged,
            onUpbringingChanged: _onUpbringingChanged,
            onEnvironmentSkillChanged: _onEnvironmentSkillChanged,
            onOrganisationSkillChanged: _onOrganisationSkillChanged,
            onUpbringingSkillChanged: _onUpbringingSkillChanged,
            onDirty: _notifyDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryCareerSection(
            heroId: widget.heroId,
            careerId: story.careerId,
            chosenSkillIds: story.careerSkillIds,
            chosenPerkIds: story.careerPerkIds,
            incidentName: story.careerIncidentName,
            careerLanguageIds: story.careerLanguageIds,
            languageConflictIndex: languageConflictIndex,
            skillConflictIndex: skillConflictIndex,
            perkConflictIndex: perkConflictIndex,
            onCareerChanged: _onCareerChanged,
            onCareerLanguageSlotsChanged: _onCareerLanguageSlotsChanged,
            onCareerLanguageChanged: _onCareerLanguageChanged,
            onSkillSelectionChanged: _onCareerSkillsChanged,
            onPerkSelectionChanged: _onCareerPerksChanged,
            onIncidentChanged: _onIncidentChanged,
            onDirty: _notifyDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryComplicationSection(
            selectedComplicationId: story.complicationId,
            complicationChoices: story.complicationChoices,
            conflictIndex: complicationConflictIndex,
            onComplicationChanged: _onComplicationChanged,
            onChoicesChanged: _onComplicationChoicesChanged,
            onDirty: _notifyDirty,
            heroAncestryTraitIds: story.ancestryTraitIds,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(StoryCreatorPageText.errorViewRetry),
            ),
          ],
        ),
      ),
    );
  }
}
