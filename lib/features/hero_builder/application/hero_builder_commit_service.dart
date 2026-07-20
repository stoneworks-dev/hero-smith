import '../../../core/db/app_database.dart' as db;
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/ancestry_bonus_service.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/class_feature_grants_service.dart';
import '../../../core/services/complication_grants_service.dart';
import '../../../core/services/story_creator_service.dart';
import '../../../core/services/strife_creator_service.dart';
import '../../../core/storage/hero_storage_contract.dart';
import '../domain/hero_draft.dart';
import 'hero_builder_controller.dart';
import 'hero_draft_conversions.dart';

/// One planned write, declaring the exact scope it replaces.
///
/// Every asset lookup happens while the plan is built, so [run] performs
/// storage work only and the transaction stays as short as possible.
class HeroCommitOperation {
  const HeroCommitOperation({
    required this.section,
    required this.replacedScope,
    required this.run,
  });

  final HeroBuilderSection section;

  /// Human-readable description of what this operation replaces, for
  /// diagnostics and review. Example: `class_feature source type + configs`.
  final String replacedScope;

  final Future<void> Function() run;
}

/// Raised while building a plan, before anything is written.
class HeroCommitPlanException implements Exception {
  const HeroCommitPlanException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Writes a validated hero-builder draft in one transaction.
///
/// The service plans first (resolving assets and validating projected claims),
/// then applies every operation inside a single Drift transaction, so a
/// mid-plan failure cannot leave the hero partially updated.
///
/// Only the Strength section is supported so far. A dirty section without a
/// committer is reported rather than silently skipped — dropping a user's edits
/// would be worse than refusing the save.
class HeroBuilderCommitService implements HeroBuilderCommitExecutor {
  HeroBuilderCommitService(
    this._db, {
    ClassFeatureGrantsService? classFeatureGrants,
    ClassDataService? classDataService,
    StoryCreatorService? storyService,
    StrifeCreatorService? strifeService,
  })  : _classFeatureGrants =
            classFeatureGrants ?? ClassFeatureGrantsService(_db),
        _classDataService = classDataService ?? ClassDataService(),
        _storyService = storyService ??
            StoryCreatorService(
              HeroRepository(_db),
              AncestryBonusService(_db),
              ComplicationGrantsService(_db),
              _db,
            ),
        _strifeService = strifeService ?? StrifeCreatorService(_db);

  final db.AppDatabase _db;
  final ClassFeatureGrantsService _classFeatureGrants;
  final ClassDataService _classDataService;
  final StoryCreatorService _storyService;
  final StrifeCreatorService _strifeService;

  @override
  Future<HeroBuilderCommitResult> commit({
    required String heroId,
    required HeroBuilderState state,
  }) async {
    final List<HeroCommitOperation> plan;
    try {
      plan = await buildPlan(heroId: heroId, state: state);
    } on ClassFeatureGrantConflictException catch (error) {
      return HeroBuilderCommitResult.validationFailure(
        message: _describeConflicts(error),
      );
    } on HeroCommitPlanException catch (error) {
      return HeroBuilderCommitResult.storageFailure(error.message);
    }

    if (plan.isEmpty) return const HeroBuilderCommitResult.success();

    try {
      await _db.transaction(() async {
        for (final operation in plan) {
          await operation.run();
        }
      });
      return const HeroBuilderCommitResult.success();
    } on ClassFeatureGrantConflictException catch (error) {
      // Defence in depth: the plan already validated, so reaching here means
      // the projected state changed underneath us. The transaction rolled back.
      return HeroBuilderCommitResult.validationFailure(
        message: _describeConflicts(error),
      );
    } catch (error) {
      return HeroBuilderCommitResult.storageFailure(error.toString());
    }
  }

  /// Builds the operations for every dirty section. Performs no writes.
  Future<List<HeroCommitOperation>> buildPlan({
    required String heroId,
    required HeroBuilderState state,
  }) async {
    final plan = <HeroCommitOperation>[];

    if (state.storyDirty) {
      plan.add(_planStory(heroId: heroId, state: state));
    }
    if (state.strifeDirty) {
      plan.add(await _planStrife(heroId: heroId, state: state));
    }
    if (state.strengthDirty) {
      plan.add(await _planStrength(heroId: heroId, state: state));
    }

    return List<HeroCommitOperation>.unmodifiable(plan);
  }

  /// Plans the Story write. The controller's `blockingConflicts()` already
  /// validated every guarded family the draft models (culture/career language,
  /// skill, and perk) before this runs, so no extra validation is needed here;
  /// `saveStory` itself is transactional and writes only Story-owned sources.
  HeroCommitOperation _planStory({
    required String heroId,
    required HeroBuilderState state,
  }) {
    final payload = storyPayloadFromDraft(heroId: heroId, draft: state.story);
    return HeroCommitOperation(
      section: HeroBuilderSection.story,
      replacedScope: 'name/ancestry/career, culture + career sources, '
          'ancestry traits, and complication grants',
      run: () => _storyService.saveStory(payload),
    );
  }

  /// Plans the Strife write. `blockingConflicts()` already validated every
  /// slot family Strife shares with `HeroDraftClaims` (ability, skill, perk,
  /// subclass skill, equipment) before this runs; `saveStrife` itself is
  /// transactional and, like Story, writes only Strife-owned sources.
  Future<HeroCommitOperation> _planStrife({
    required String heroId,
    required HeroBuilderState state,
  }) async {
    await _classDataService.initialize();

    final classId = state.strife.classId?.trim();
    if (classId == null || classId.isEmpty) {
      throw const HeroCommitPlanException(
        'The hero has no class, so Strife selections cannot be saved.',
      );
    }
    final classData = _classDataService.getClassById(classId);
    if (classData == null) {
      throw HeroCommitPlanException('Unknown class "$classId".');
    }

    // The perks the baseline had persisted, so the grant sync inside
    // `saveStrife` can tell which removed perks need their grants revoked.
    final previousPerkIds = state.baseline.strife.perkSelections.values
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final payload = strifePayloadFromDraft(
      heroId: heroId,
      draft: state.strife,
      classData: classData,
      previousClassId: state.baseline.strife.classId,
      previousPerkIds: previousPerkIds,
    );

    return HeroCommitOperation(
      section: HeroBuilderSection.strife,
      replacedScope: 'level/class/subclass/deity/domain, characteristics, '
          'vitals, potencies, kit/equipment grants and bonuses, and the '
          'ability/skill/perk manual-choice sources',
      run: () => _strifeService.saveStrife(payload),
    );
  }

  Future<HeroCommitOperation> _planStrength({
    required String heroId,
    required HeroBuilderState state,
  }) async {
    // Resolve assets before the transaction.
    await _classDataService.initialize();

    final classId = state.strife.classId?.trim();
    if (classId == null || classId.isEmpty) {
      throw const HeroCommitPlanException(
        'The hero has no class, so class feature selections cannot be applied.',
      );
    }
    final classData = _classDataService.getClassById(classId);
    if (classData == null) {
      throw HeroCommitPlanException('Unknown class "$classId".');
    }

    // The class-feature batch reads only the subclass key, name, and domains;
    // the draft's resolved skill id is owned by `subclass:subclass_skill`.
    final subclassSelection = subclassSelectionFromDraft(state.strife.subclass);
    final strength = state.strength;

    // Validate the projected final claims before opening the transaction.
    final conflicts = await _classFeatureGrants.validateFeatureSelections(
      heroId: heroId,
      classData: classData,
      level: state.strife.level,
      selections: strength.featureSelections,
      subclassSelection: subclassSelection,
      skillGroupSelections: strength.skillGroupSelections,
    );
    if (conflicts.isNotEmpty) {
      throw ClassFeatureGrantConflictException(conflicts);
    }

    return HeroCommitOperation(
      section: HeroBuilderSection.strength,
      replacedScope: '${HeroEntrySourceTypes.classFeature} source type, '
          '${HeroConfigKeys.classFeatureSelections}, '
          '${HeroConfigKeys.classFeatureSubclassKey}, '
          '${HeroConfigKeys.classFeatureSkillGroupSelections}',
      run: () => _classFeatureGrants.applyClassFeatureSelections(
        heroId: heroId,
        classData: classData,
        level: state.strife.level,
        selections: strength.featureSelections,
        subclassSelection: subclassSelection,
        skillGroupSelections: strength.skillGroupSelections,
      ),
    );
  }

  static String _describeConflicts(ClassFeatureGrantConflictException error) {
    return error.conflicts
        .map(
          (conflict) =>
              '${conflict.grant.entryType}:${conflict.grant.entryId} is already '
              'granted by ${conflict.ownerLabels.join(', ')}',
        )
        .join('; ');
  }
}
