import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hero_storage_contract.dart';
import '../data/hero_builder_repository.dart';
import '../domain/hero_claim.dart';
import '../domain/hero_conflict_index.dart';
import '../domain/hero_draft.dart';
import '../domain/hero_draft_claims.dart';

enum HeroBuilderCommitKind {
  success,
  validationFailure,
  staleDraft,
  storageFailure,
}

/// Typed outcome of one commit attempt. The draft is preserved on every
/// non-success outcome so the user can repair and retry.
class HeroBuilderCommitResult {
  const HeroBuilderCommitResult._(this.kind, {this.message, this.conflicts});

  const HeroBuilderCommitResult.success()
      : this._(HeroBuilderCommitKind.success);

  const HeroBuilderCommitResult.validationFailure({
    String? message,
    List<HeroConflict>? conflicts,
  }) : this._(
          HeroBuilderCommitKind.validationFailure,
          message: message,
          conflicts: conflicts,
        );

  const HeroBuilderCommitResult.staleDraft()
      : this._(
          HeroBuilderCommitKind.staleDraft,
          message: 'This hero changed while the builder was open. Reload the '
              'builder and try again.',
        );

  const HeroBuilderCommitResult.storageFailure(String message)
      : this._(HeroBuilderCommitKind.storageFailure, message: message);

  final HeroBuilderCommitKind kind;
  final String? message;
  final List<HeroConflict>? conflicts;

  bool get isSuccess => kind == HeroBuilderCommitKind.success;
}

/// Writes a validated draft to storage.
///
/// Phase 6 supplies the transactional implementation; until then the
/// controller runs without one and no production page calls [commit].
abstract class HeroBuilderCommitExecutor {
  Future<HeroBuilderCommitResult> commit({
    required String heroId,
    required HeroBuilderState state,
  });
}

/// Holds one hero's builder session: an immutable baseline, the in-memory
/// drafts, and the projected conflict index derived from both.
///
/// Every picker change is a pure state update. The database is read once per
/// load/reload and written only by [commit].
class HeroBuilderController extends StateNotifier<HeroBuilderState> {
  HeroBuilderController({
    required this.heroId,
    required HeroBuilderRepository repository,
    HeroBuilderCommitExecutor? commitExecutor,
  })  : _repository = repository,
        _commitExecutor = commitExecutor,
        super(
          HeroBuilderState.fromBaseline(HeroBuilderBaseline.empty())
              .copyWith(isLoading: true),
        );

  final String heroId;
  final HeroBuilderRepository _repository;
  final HeroBuilderCommitExecutor? _commitExecutor;

  (int, int)? _indexKey;
  HeroConflictIndex _index = HeroConflictIndex.empty;

  /// Guards against an older in-flight load overwriting a newer baseline.
  /// A caller that repairs persisted data and then reloads must win, even if
  /// a load started before the repair finishes later.
  int _loadToken = 0;

  bool get isLoaded => state.baseline.revision > 0;

  Future<void> load() async {
    final token = ++_loadToken;
    state = state.copyWith(isLoading: true, lastError: null);
    try {
      final baseline = await _repository.loadBaseline(heroId);
      if (token != _loadToken) return;
      state = HeroBuilderState.fromBaseline(baseline);
    } catch (error) {
      if (token != _loadToken) return;
      state = state.copyWith(isLoading: false, lastError: error.toString());
    }
  }

  /// Drops every unsaved draft and reloads the persisted baseline.
  Future<void> reload() => load();

  /// Restores one section to its baseline without touching the database.
  void discardSection(HeroBuilderSection section) {
    switch (section) {
      case HeroBuilderSection.story:
        _update(story: state.baseline.story);
      case HeroBuilderSection.strife:
        _update(strife: state.baseline.strife);
      case HeroBuilderSection.strength:
        _update(strength: state.baseline.strength);
    }
  }

  void discardAll() {
    _update(
      story: state.baseline.story,
      strife: state.baseline.strife,
      strength: state.baseline.strength,
    );
  }

  // ---------------------------------------------------------------------------
  // Section commands. Generic transforms keep the command surface small while
  // pages migrate; the named commands cover the plan's documented slots.
  // ---------------------------------------------------------------------------

  void updateStory(StoryDraft Function(StoryDraft draft) transform) {
    _update(story: transform(state.story));
  }

  /// Folds a deterministic, load-time-derived Story change (e.g. padding the
  /// career language slots out to the career's granted count) into both the
  /// draft and the baseline, so reconstructing it on load does not open the
  /// tab dirty. Writes nothing — the trailing empty slots persist nothing, and
  /// a real save still commits whatever the draft holds. Callers must only use
  /// this while the Story section is otherwise clean; a pending user edit must
  /// go through [updateStory] so its dirty state is preserved.
  void adoptStory(StoryDraft Function(StoryDraft draft) transform) {
    final adopted = transform(state.story);
    if (adopted == state.story && adopted == state.baseline.story) return;
    state = state.copyWith(
      baseline: state.baseline.copyWith(story: adopted),
      story: adopted,
      draftRevision: state.draftRevision + 1,
    );
  }

  void updateStrife(StrifeDraft Function(StrifeDraft draft) transform) {
    _update(strife: transform(state.strife));
  }

  void updateStrength(StrengthDraft Function(StrengthDraft draft) transform) {
    _update(strength: transform(state.strength));
  }

  void setCultureLanguage(String? languageId) {
    updateStory((draft) => draft.copyWith(cultureLanguageId: languageId));
  }

  void setCareerLanguageSlot(int index, String? languageId) {
    updateStory((draft) {
      final slots = List<String?>.from(draft.careerLanguageIds);
      while (slots.length <= index) {
        slots.add(null);
      }
      slots[index] = languageId;
      return draft.copyWith(careerLanguageIds: slots);
    });
  }

  void setStrifeAbilitySlot(String slotKey, String? abilityId) {
    updateStrife(
      (draft) => draft.withSlot(
          family: 'ability', slotKey: slotKey, entryId: abilityId),
    );
  }

  void setStrifeSkillSlot(String slotKey, String? skillId) {
    updateStrife(
      (draft) =>
          draft.withSlot(family: 'skill', slotKey: slotKey, entryId: skillId),
    );
  }

  void setStrifePerkSlot(String slotKey, String? perkId) {
    updateStrife(
      (draft) =>
          draft.withSlot(family: 'perk', slotKey: slotKey, entryId: perkId),
    );
  }

  void setFeatureSelection(String featureId, Set<String> optionKeys) {
    updateStrength(
        (draft) => draft.withFeatureSelection(featureId, optionKeys));
  }

  /// Folds deterministic, load-time-derived Strength feature selections
  /// (domain/subclass/deity-linked options the section recomputes identically
  /// on every load) into both the draft and the baseline, so reconstructing
  /// them does not open the tab dirty. Writes nothing: grants re-derive these
  /// from the subclass/domain slugs, and a real save still persists whatever
  /// the draft holds. Only for the section's load-time emit, never user edits.
  void adoptStrengthFeatureSelections(
    Map<String, Set<String>> featureSelections,
  ) {
    final adopted =
        state.strength.copyWith(featureSelections: featureSelections);
    if (adopted == state.strength && adopted == state.baseline.strength) {
      return;
    }
    state = state.copyWith(
      baseline: state.baseline.copyWith(strength: adopted),
      strength: adopted,
      draftRevision: state.draftRevision + 1,
    );
  }

  void setFeatureSkillSlot({
    required String featureId,
    required String grantKey,
    required String? skillId,
  }) {
    updateStrength(
      (draft) => draft.withSkillGroupSelection(
        featureId: featureId,
        grantKey: grantKey,
        skillId: skillId,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Conflicts
  // ---------------------------------------------------------------------------

  /// The projected claim index for the current drafts, memoized by
  /// `(baseline.revision, draftRevision)` so pickers and save-time validation
  /// read the same instance with no database work.
  HeroConflictIndex get conflictIndex {
    final key = (state.baseline.revision, state.draftRevision);
    if (_indexKey != key) {
      _index = HeroConflictIndex.projected(
        persistedClaims: state.baseline.persistedClaims,
        draftClaims: HeroDraftClaims.draftClaims(
          story: state.story,
          strife: state.strife,
          strength: state.strength,
        ),
        mutationScopes: HeroDraftClaims.mutationScopes(
          baselineStrength: state.baseline.strength,
          strength: state.strength,
        ),
      );
      _indexKey = key;
    }
    return _index;
  }

  /// Conflict for one slot's candidate, ignoring only that slot's own claim.
  HeroConflict? slotConflict({
    required String entryType,
    required String? entryId,
    required String slotKey,
  }) {
    final normalized = entryId?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return conflictIndex.conflictFor(
      HeroEntryKey(entryType: entryType, canonicalEntryId: normalized),
      ignoredDraftSlotKey: slotKey,
    );
  }

  /// Every draft claim that still conflicts with another owner. These block
  /// [commit], mirroring the save-time rule the migrated editors use today.
  List<HeroConflict> blockingConflicts() {
    final index = conflictIndex;
    final seen = <HeroEntryKey>{};
    final blocking = <HeroConflict>[];
    final claims = HeroDraftClaims.draftClaims(
      story: state.story,
      strife: state.strife,
      strength: state.strength,
    );
    for (final claim in claims) {
      if (!seen.add(claim.key)) continue;
      final conflict = index.conflictFor(
        claim.key,
        ignoredDraftSlotKey: claim.owner.slotKey,
      );
      if (conflict != null) {
        blocking.add(conflict);
      }
    }
    return List<HeroConflict>.unmodifiable(blocking);
  }

  // ---------------------------------------------------------------------------
  // Commit
  // ---------------------------------------------------------------------------

  Future<HeroBuilderCommitResult> commit() async {
    if (!isLoaded || state.isLoading) {
      return const HeroBuilderCommitResult.storageFailure(
        'The hero builder has not finished loading.',
      );
    }
    if (state.isSaving) {
      return const HeroBuilderCommitResult.storageFailure(
        'A commit is already in progress.',
      );
    }
    if (!state.isDirty) {
      return const HeroBuilderCommitResult.success();
    }

    final conflicts = blockingConflicts();
    if (conflicts.isNotEmpty) {
      return HeroBuilderCommitResult.validationFailure(
        message: _describeConflicts(conflicts),
        conflicts: conflicts,
      );
    }

    final executor = _commitExecutor;
    if (executor == null) {
      return const HeroBuilderCommitResult.storageFailure(
        'No commit executor is wired yet; the transactional commit service '
        'arrives in Phase 6.',
      );
    }

    state = state.copyWith(isSaving: true, lastError: null);
    try {
      final currentFingerprint = await _repository.entriesFingerprint(heroId);
      if (currentFingerprint != state.baseline.entriesFingerprint) {
        final adopted = await _adoptImmediatePerkGrantWrites();
        if (!adopted) {
          state = state.copyWith(isSaving: false);
          return const HeroBuilderCommitResult.staleDraft();
        }

        // Perk-nested choices still use their legacy immediate-persistence
        // path. Refreshing their claims can reveal a conflict that was not in
        // the session baseline, so validate the updated projection once more
        // before any commit operation runs.
        final refreshedConflicts = blockingConflicts();
        if (refreshedConflicts.isNotEmpty) {
          final message = _describeConflicts(refreshedConflicts);
          state = state.copyWith(isSaving: false, lastError: message);
          return HeroBuilderCommitResult.validationFailure(
            message: message,
            conflicts: refreshedConflicts,
          );
        }
      }

      final result = await executor.commit(heroId: heroId, state: state);
      if (result.isSuccess) {
        // Reload once so the baseline equals what was committed, and retire any
        // load that started before this commit.
        final token = ++_loadToken;
        final baseline = await _repository.loadBaseline(heroId);
        if (token != _loadToken) return result;
        state = HeroBuilderState.fromBaseline(baseline);
      } else {
        state = state.copyWith(isSaving: false, lastError: result.message);
      }
      return result;
    } catch (error) {
      state = state.copyWith(isSaving: false, lastError: error.toString());
      return HeroBuilderCommitResult.storageFailure(error.toString());
    }
  }

  /// Adopts the one builder-owned write path that has not moved into the
  /// in-memory draft yet: language/skill choices nested under a selected perk.
  ///
  /// Those pickers persist `(perk, perkId)` entries immediately. Without this
  /// narrow reconciliation, the stale-draft guard mistakes the builder's own
  /// write for an edit from another screen and refuses the later Save. Every
  /// changed claim must belong to a perk selected in either the loaded or the
  /// current draft; all other fingerprint changes remain stale failures.
  Future<bool> _adoptImmediatePerkGrantWrites() async {
    final previousBaseline = state.baseline;
    final refreshed = await _repository.loadBaseline(heroId);

    final allowedPerkIds = <String>{
      ...previousBaseline.story.careerPerkIds,
      ...state.story.careerPerkIds,
      ...previousBaseline.strife.perkSelections.values.whereType<String>(),
      ...state.strife.perkSelections.values.whereType<String>(),
    }..removeWhere((id) => id.trim().isEmpty);
    if (allowedPerkIds.isEmpty) return false;

    final previousClaims = previousBaseline.persistedClaims.toSet();
    final refreshedClaims = refreshed.persistedClaims.toSet();
    final changedClaims = <HeroEntryClaim>{
      ...previousClaims.difference(refreshedClaims),
      ...refreshedClaims.difference(previousClaims),
    };
    if (changedClaims.isEmpty ||
        changedClaims.any(
          (claim) =>
              claim.owner.source.normalizedSourceType !=
                  HeroEntrySourceTypes.perk ||
              !allowedPerkIds.contains(claim.owner.source.normalizedSourceId),
        )) {
      return false;
    }

    // Keep the user's original baseline drafts so dirty/discard semantics do
    // not change. Only the persisted claim snapshot and its fingerprint move
    // forward. The refreshed revision invalidates the memoized conflict index.
    final reconciledBaseline = HeroBuilderBaseline(
      revision: refreshed.revision,
      story: previousBaseline.story,
      strife: previousBaseline.strife,
      strength: previousBaseline.strength,
      persistedClaims: refreshed.persistedClaims,
      entriesFingerprint: refreshed.entriesFingerprint,
      compatibilityWarnings: previousBaseline.compatibilityWarnings,
    );
    state = state.copyWith(baseline: reconciledBaseline);
    return true;
  }

  static String _describeConflicts(List<HeroConflict> conflicts) {
    final details = conflicts.map((conflict) {
      final owners = conflict.owners
          .map(
            (owner) => owner.displayLabel ?? owner.source.toString(),
          )
          .join(', ');
      return '${conflict.key} is already selected by $owners';
    }).join('; ');
    return 'Resolve duplicate selections before saving: $details.';
  }

  void _update({
    StoryDraft? story,
    StrifeDraft? strife,
    StrengthDraft? strength,
  }) {
    state = state.copyWith(
      story: story,
      strife: strife,
      strength: strength,
      draftRevision: state.draftRevision + 1,
    );
  }
}
