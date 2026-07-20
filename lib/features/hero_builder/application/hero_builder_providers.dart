import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../data/hero_builder_repository.dart';
import '../domain/hero_conflict_index.dart';
import '../domain/hero_draft.dart';
import 'hero_builder_commit_service.dart';
import 'hero_builder_controller.dart';

/// One baseline loader shared by every builder session.
final heroBuilderRepositoryProvider = Provider<HeroBuilderRepository>((ref) {
  return DriftHeroBuilderRepository(ref.watch(appDatabaseProvider));
});

/// The transactional writer behind `commit()`.
final heroBuilderCommitServiceProvider =
    Provider<HeroBuilderCommitExecutor>((ref) {
  return HeroBuilderCommitService(ref.watch(appDatabaseProvider));
});

/// One builder session per hero. The controller loads its baseline once when
/// first watched; picker changes after that perform no database reads.
final heroBuilderControllerProvider = StateNotifierProvider.autoDispose
    .family<HeroBuilderController, HeroBuilderState, String>((ref, heroId) {
  final controller = HeroBuilderController(
    heroId: heroId,
    repository: ref.watch(heroBuilderRepositoryProvider),
    commitExecutor: ref.watch(heroBuilderCommitServiceProvider),
  );
  controller.load();
  return controller;
});

// ---------------------------------------------------------------------------
// Narrow selectors so a Story edit does not rebuild Strife or Strength.
// ---------------------------------------------------------------------------

final heroBuilderStoryDraftProvider =
    Provider.autoDispose.family<StoryDraft, String>((ref, heroId) {
  return ref.watch(
    heroBuilderControllerProvider(heroId).select((state) => state.story),
  );
});

final heroBuilderStrifeDraftProvider =
    Provider.autoDispose.family<StrifeDraft, String>((ref, heroId) {
  return ref.watch(
    heroBuilderControllerProvider(heroId).select((state) => state.strife),
  );
});

final heroBuilderStrengthDraftProvider =
    Provider.autoDispose.family<StrengthDraft, String>((ref, heroId) {
  return ref.watch(
    heroBuilderControllerProvider(heroId).select((state) => state.strength),
  );
});

final heroBuilderDirtyProvider =
    Provider.autoDispose.family<bool, String>((ref, heroId) {
  return ref.watch(
    heroBuilderControllerProvider(heroId).select((state) => state.isDirty),
  );
});

final heroBuilderSavingProvider =
    Provider.autoDispose.family<bool, String>((ref, heroId) {
  return ref.watch(
    heroBuilderControllerProvider(heroId).select((state) => state.isSaving),
  );
});

/// The memoized projected conflict index for the current drafts. Recomputes
/// only when the baseline or a draft actually changes.
final heroBuilderConflictIndexProvider =
    Provider.autoDispose.family<HeroConflictIndex, String>((ref, heroId) {
  ref.watch(
    heroBuilderControllerProvider(heroId).select(
      (state) => (state.baseline.revision, state.draftRevision),
    ),
  );
  return ref.read(heroBuilderControllerProvider(heroId).notifier).conflictIndex;
});
