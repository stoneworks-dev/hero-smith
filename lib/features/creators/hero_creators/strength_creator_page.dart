import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/subclass_models.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/class_feature_data_service.dart';
import '../../../core/text/creators/hero_creators/strength_creator_page_text.dart';
import '../../../core/theme/creator_theme.dart';
import '../../../core/theme/form_theme.dart';
import '../../hero_builder/application/hero_builder_controller.dart';
import '../../hero_builder/application/hero_builder_providers.dart';
import '../../hero_builder/application/hero_draft_conversions.dart';
import '../../hero_builder/domain/hero_conflict_index.dart';
import '../../hero_builder/domain/hero_draft.dart';
import '../widgets/strength_creator/class_features_section.dart';
import '../../../widgets/creature stat block/hero_green_form_widget.dart';

class StrenghtCreatorPage extends ConsumerStatefulWidget {
  const StrenghtCreatorPage({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<StrenghtCreatorPage> createState() =>
      _StrenghtCreatorPageState();
}

class _StrenghtCreatorPageState extends ConsumerState<StrenghtCreatorPage>
    with AutomaticKeepAliveClientMixin {
  final ClassDataService _classDataService = ClassDataService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  bool _hasLoadedOnce = false;

  int _pendingChoicesCount = 0;

  /// True once the user has changed a feature selection this baseline. While
  /// false, the section's load-time emit (deterministic domain/subclass/deity
  /// auto-derivations) is folded into the baseline instead of dirtying the tab.
  /// Reset whenever a fresh baseline is loaded or committed.
  bool _userEditedStrength = false;

  HeroBuilderController get _controller =>
      ref.read(heroBuilderControllerProvider(widget.heroId).notifier);

  StrengthDraft get _strength =>
      ref.watch(heroBuilderStrengthDraftProvider(widget.heroId));

  /// Level, subclass, and equipment are Strife-owned; Strength only reads them.
  StrifeDraft get _strife =>
      ref.watch(heroBuilderStrifeDraftProvider(widget.heroId));

  /// A picker signalled an edit. Dirty state is derived by the shell from the
  /// controller; this just rebuilds the tab so any local UI stays in sync.
  void _notifyDirty() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showFullScreenLoader = false}) async {
    final useFullScreenLoader = !_hasLoadedOnce || showFullScreenLoader;
    setState(() {
      _isLoading = useFullScreenLoader;
      _isRefreshing = !useFullScreenLoader;
      _error = null;
    });

    try {
      await _classDataService.initialize();
      final repo = ref.read(heroRepositoryProvider);
      final hero = await repo.load(widget.heroId);

      if (hero == null) {
        setState(() {
          _error = StrengthCreatorPageText.heroDataNotFoundMessage;
          _isLoading = false;
        });
        return;
      }

      final classId = hero.className?.trim();
      final allClasses = _classDataService.getAllClasses();
      final classData =
          allClasses.firstWhereOrNull((c) => c.classId == classId);

      final domainNames = hero.domain == null
          ? <String>[]
          : hero.domain!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final savedSubclassKey = await repo.getSubclassKey(widget.heroId);
      final subclassName = hero.subclass?.trim();
      final subclassKey = savedSubclassKey ??
          (subclassName != null && subclassName.isNotEmpty
              ? ClassFeatureDataService.slugify(subclassName)
              : null);

      SubclassSelectionResult? subclassSelection;
      if ((subclassName?.isNotEmpty ?? false) ||
          (hero.deityId?.trim().isNotEmpty ?? false) ||
          domainNames.isNotEmpty) {
        subclassSelection = SubclassSelectionResult(
          subclassKey: subclassKey,
          subclassName: subclassName,
          deityId: hero.deityId?.trim().isNotEmpty == true
              ? hero.deityId!.trim()
              : null,
          deityName: hero.deityId?.trim().isNotEmpty == true
              ? hero.deityId!.trim()
              : null,
          domainNames: domainNames,
        );
      }

      var savedFeatureSelections =
          await repo.getFeatureSelections(widget.heroId);
      // Detect subclass changes and clear stale feature grants/selections so
      // features from a previous subclass are not kept.
      try {
        final grantService = ref.read(classFeatureGrantsServiceProvider);
        final storedSubclassKey =
            (await grantService.loadSubclassKey(widget.heroId))?.trim();
        final currentSubclassKey = subclassSelection?.subclassKey?.trim();
        // Only treat as a change if we HAD a stored subclass and it's different.
        // If storedSubclassKey is null/empty, this is the first save - not a change.
        final hadPreviousSubclass =
            storedSubclassKey != null && storedSubclassKey.isNotEmpty;
        final subclassChanged = hadPreviousSubclass &&
            storedSubclassKey != (currentSubclassKey ?? '');

        if (subclassChanged) {
          // Remove old class feature grants and clear persisted selections.
          await grantService.removeClassFeatureGrants(widget.heroId);
          await repo.saveFeatureSelections(widget.heroId, const {});
          savedFeatureSelections = const {};
        }
      } catch (_) {
        // If cleanup fails, continue with existing selections; a future save
        // will still re-apply correct grants.
      }

      // Re-apply class feature grants on load so new grant handlers (like
      // grants[] speed/disengage bonuses) take effect even if the user doesn't
      // change any selections in this session. This repairs persisted data, so
      // it must finish before the draft baseline is read below.
      if (classData != null) {
        try {
          final grantService = ref.read(classFeatureGrantsServiceProvider);
          await grantService.applyClassFeatureSelections(
            heroId: widget.heroId,
            classData: classData,
            level: hero.level,
            selections: savedFeatureSelections,
            subclassSelection: subclassSelection,
          );
        } catch (_) {
          // Best-effort: keep loading UI even if re-apply fails.
        }
      }

      // Adopt the repaired state as the baseline. Selections, skill-group
      // choices, level, subclass, and equipment all come from the draft now.
      await _controller.reload();

      if (!mounted) return;
      setState(() {
        _hasLoadedOnce = true;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
      _notifyDirty();
    } catch (e) {
      if (!mounted) return;
      if (!_hasLoadedOnce || showFullScreenLoader) {
        setState(() {
          _error =
              '${StrengthCreatorPageText.failedToLoadStrengthDataPrefix}$e';
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${StrengthCreatorPageText.failedToRefreshFeaturesPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Records a *user* feature-selection change in the draft. Conflicts are
  /// surfaced by the pickers from the projected index and blocked again at
  /// commit, so a change no longer needs a database round trip to be accepted.
  Future<bool> _handleSelectionsChanged(
    Map<String, Set<String>> selections,
  ) async {
    _userEditedStrength = true;
    final current = ref
        .read(heroBuilderControllerProvider(widget.heroId))
        .strength
        .featureSelections;
    for (final featureId in {...current.keys, ...selections.keys}) {
      final next = selections[featureId] ?? const <String>{};
      if (const SetEquality<String>()
          .equals(current[featureId] ?? const <String>{}, next)) {
        continue;
      }
      _controller.setFeatureSelection(featureId, next);
    }
    _notifyDirty();
    return true;
  }

  /// Handles the section's load-time emit (fired only from its `_load`, never
  /// from a user click). The emitted map is the persisted selections plus the
  /// deterministic domain/subclass/deity auto-derivations the section rebuilds
  /// every load; grants re-derive those from the subclass/domain slugs, so
  /// folding them into the baseline keeps the tab from opening dirty without
  /// changing anything that gets committed. If the user already has a pending
  /// edit this baseline, the emit is treated as a normal draft change so that
  /// dirty state is preserved.
  void _handleLoadedSelections(Map<String, Set<String>> selections) {
    if (_userEditedStrength) {
      _handleSelectionsChanged(selections);
      return;
    }
    _controller.adoptStrengthFeatureSelections(selections);
    _notifyDirty();
  }

  Future<void> _handleSkillGroupSelectionChanged(
    String featureId,
    String grantKey,
    String? skillId,
  ) async {
    _controller.setFeatureSkillSlot(
      featureId: featureId,
      grantKey: grantKey,
      skillId: skillId,
    );
    _notifyDirty();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // A fresh baseline (initial load, reload, or post-commit adoption) clears
    // the user-edit flag, so the section's next load-time emit can be folded
    // into the baseline again instead of dirtying the tab.
    ref.listen<int>(
      heroBuilderControllerProvider(widget.heroId)
          .select((state) => state.baseline.revision),
      (previous, next) {
        if (previous != next) _userEditedStrength = false;
      },
    );

    final strength = _strength;
    final strife = _strife;
    final subclassSelection = subclassSelectionFromDraft(strife.subclass);
    final draftClassId = strife.classId?.trim();
    final classData = draftClassId == null || draftClassId.isEmpty
        ? null
        : _classDataService
            .getAllClasses()
            .firstWhereOrNull((candidate) => candidate.classId == draftClassId);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CreatorTheme.strengthAccent,
        ),
      );
    }

    if (_error != null && !_hasLoadedOnce) {
      return _NoticeCard(
        icon: Icons.error_outline,
        accentColor: CreatorTheme.errorColor,
        title: StrengthCreatorPageText.noticeTitleSomethingWentWrong,
        message: _error!,
        action: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, color: CreatorTheme.errorColor),
          label: const Text(
            StrengthCreatorPageText.noticeActionRetryLabel,
            style: TextStyle(color: CreatorTheme.errorColor),
          ),
        ),
      );
    }

    final notices = <Widget>[];
    if (classData == null) {
      notices.add(
        _NoticeCard(
          icon: Icons.info_outline,
          accentColor: CreatorTheme.warningColor,
          title: StrengthCreatorPageText.noticeTitleClassRequired,
          message: StrengthCreatorPageText.noticeMessageClassRequired,
        ),
      );
    }
    if (classData != null && subclassSelection == null) {
      notices.add(
        _NoticeCard(
          icon: Icons.warning_amber_rounded,
          accentColor: CreatorTheme.warningColor,
          title: StrengthCreatorPageText.noticeTitleSubclassMissing,
          message: StrengthCreatorPageText.noticeMessageSubclassMissing,
        ),
      );
    }

    final content = <Widget>[
      // Pending choices notification banner
      if (_pendingChoicesCount > 0)
        _PendingChoicesBanner(count: _pendingChoicesCount),
      if (notices.isNotEmpty) ...[
        ...notices,
        const SizedBox(height: 12),
      ],
      if (classData != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AutoHeroGreenFormWidget(
            heroId: widget.heroId,
            sectionTitle: StrengthCreatorPageText.greenFormSectionTitle,
            sectionSpacing: 12,
          ),
        ),
      if (classData != null)
        ClassFeaturesSection(
          classData: classData,
          selectedLevel: strife.level,
          selectedSubclass: subclassSelection,
          initialSelections: strength.featureSelections,
          equipmentIds: strife.equipmentIds,
          onSelectionsChanged: _handleLoadedSelections,
          onSelectionsChangeRequested: _handleSelectionsChanged,
          skillGroupSelections: strength.skillGroupSelections,
          onSkillGroupSelectionChanged: _handleSkillGroupSelectionChanged,
          skillConflictIndex: _skillConflictIndex,
          onPendingChoicesChanged: (count) {
            if (_pendingChoicesCount != count) {
              // Defer setState to avoid calling it during build phase
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pendingChoicesCount != count) {
                  setState(() {
                    _pendingChoicesCount = count;
                  });
                }
              });
            }
          },
        )
      else
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            StrengthCreatorPageText.chooseClassFirstMessage,
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 24),
    ];

    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      addAutomaticKeepAlives: true,
      children: content,
    );

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _load(),
          child: listView,
        ),
        if (_isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: true,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: CreatorTheme.strengthAccent,
                backgroundColor:
                    CreatorTheme.strengthAccent.withValues(alpha: 0.2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  /// The builder's projected index, memoized per draft revision. It already
  /// projects every editor's own source away and re-adds its draft claims, so
  /// a nested skill slot never conflicts with itself while every other owner —
  /// Story, Strife, perks, the hero sheet — still blocks.
  HeroConflictIndex get _skillConflictIndex =>
      ref.watch(heroBuilderConflictIndexProvider(widget.heroId));
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: CreatorTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: CreatorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingChoicesBanner extends StatelessWidget {
  const _PendingChoicesBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade700.withValues(alpha: 0.15),
              Colors.orange.shade600.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade600.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app_outlined,
                  color: Colors.orange.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? StrengthCreatorPageText.pendingChoicesSingular
                          : StrengthCreatorPageText.pendingChoicesPlural(count),
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      StrengthCreatorPageText.pendingChoicesHint,
                      style: TextStyle(
                        color: FormTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.orange.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef StrenghtCreatorPageState = _StrenghtCreatorPageState;
