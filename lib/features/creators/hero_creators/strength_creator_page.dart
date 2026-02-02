import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/class_data.dart';
import '../../../core/models/subclass_models.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/class_feature_data_service.dart';
import '../../../core/services/class_feature_grants_service.dart';
import '../../../core/text/creators/hero_creators/strength_creator_page_text.dart';
import '../../../core/theme/creator_theme.dart';
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
  ClassData? _classData;
  SubclassSelectionResult? _subclassSelection;
  int _selectedLevel = 1;
  Map<String, Set<String>> _featureSelections = const {};
  List<String?> _equipmentIds = const [];
  Map<String, Map<String, String>> _skillGroupSelections = const {};
  Set<String> _reservedSkillIds = const {};
  int _pendingChoicesCount = 0;

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
        final db = ref.read(appDatabaseProvider);
        final grantService = ClassFeatureGrantsService(db);
        final storedSubclassKey =
            (await grantService.loadSubclassKey(widget.heroId))?.trim();
        final currentSubclassKey = subclassSelection?.subclassKey?.trim();
        // Only treat as a change if we HAD a stored subclass and it's different.
        // If storedSubclassKey is null/empty, this is the first save - not a change.
        final hadPreviousSubclass = storedSubclassKey != null && storedSubclassKey.isNotEmpty;
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
      
      // Load equipment IDs for kit detection
      final equipmentIds = await repo.getEquipmentIds(widget.heroId);
      
      // Load skill_group selections
      Map<String, Map<String, String>> skillGroupSelections = const {};
      Set<String> reservedSkillIds = const {};
      try {
        final db = ref.read(appDatabaseProvider);
        final grantService = ClassFeatureGrantsService(db);
        skillGroupSelections = await grantService.loadSkillGroupSelections(widget.heroId);
        
        // Get reserved skill IDs (skills from all sources)
        final allSkillEntries = await repo.getSkillEntries(widget.heroId);
        reservedSkillIds = allSkillEntries.map((e) => e.entryId).toSet();
      } catch (_) {
        // Best-effort: continue without skill group data
      }

      // Re-apply class feature grants on load so new grant handlers (like
      // grants[] speed/disengage bonuses) take effect even if the user doesn't
      // change any selections in this session.
      if (classData != null) {
        try {
          final db = ref.read(appDatabaseProvider);
          final grantService = ClassFeatureGrantsService(db);
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

      if (!mounted) return;
      setState(() {
        _classData = classData;
        _subclassSelection = subclassSelection;
        _selectedLevel = hero.level;
        _featureSelections = savedFeatureSelections.isNotEmpty
            ? savedFeatureSelections
            : const {};
        _equipmentIds = equipmentIds;
        _skillGroupSelections = skillGroupSelections;
        _reservedSkillIds = reservedSkillIds;
        _hasLoadedOnce = true;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
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
            content:
                Text('${StrengthCreatorPageText.failedToRefreshFeaturesPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> reload() => _load();

  Future<void> _handleSelectionsChanged(
    Map<String, Set<String>> selections,
  ) async {
    setState(() {
      _featureSelections = selections;
    });
    try {
      final repo = ref.read(heroRepositoryProvider);
      await repo.saveFeatureSelections(widget.heroId, selections);
      if (_classData != null) {
        final db = ref.read(appDatabaseProvider);
        final grantService = ClassFeatureGrantsService(db);
        await grantService.applyClassFeatureSelections(
          heroId: widget.heroId,
          classData: _classData!,
          level: _selectedLevel,
          selections: selections,
          subclassSelection: _subclassSelection,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${StrengthCreatorPageText.failedToSaveFeatureSelectionsPrefix}$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSkillGroupSelectionChanged(
    String featureId,
    String grantKey,
    String? skillId,
  ) async {
    // Update local state immediately for responsiveness
    setState(() {
      final updated = Map<String, Map<String, String>>.from(_skillGroupSelections);
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
      _skillGroupSelections = updated;
      
      // Update reserved skill IDs
      final updatedReserved = Set<String>.from(_reservedSkillIds);
      // Remove the old skill from reserved if it was replaced
      // (we'll re-add the new one)
      if (skillId != null && skillId.isNotEmpty) {
        updatedReserved.add(skillId);
      }
      _reservedSkillIds = updatedReserved;
    });
    
    // Save to database
    try {
      final db = ref.read(appDatabaseProvider);
      final grantService = ClassFeatureGrantsService(db);
      await grantService.setSkillGroupSelection(
        heroId: widget.heroId,
        featureId: featureId,
        grantKey: grantKey,
        skillId: skillId,
      );
      
      // Reload reserved skills to ensure consistency
      final repo = ref.read(heroRepositoryProvider);
      final allSkillEntries = await repo.getSkillEntries(widget.heroId);
      if (mounted) {
        setState(() {
          _reservedSkillIds = allSkillEntries.map((e) => e.entryId).toSet();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${StrengthCreatorPageText.failedToSaveSkillSelectionPrefix}$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
    if (_classData == null) {
      notices.add(
        _NoticeCard(
          icon: Icons.info_outline,
          accentColor: CreatorTheme.warningColor,
          title: StrengthCreatorPageText.noticeTitleClassRequired,
          message:
              StrengthCreatorPageText.noticeMessageClassRequired,
        ),
      );
    }
    if (_classData != null && _subclassSelection == null) {
      notices.add(
        _NoticeCard(
          icon: Icons.warning_amber_rounded,
          accentColor: CreatorTheme.warningColor,
          title: StrengthCreatorPageText.noticeTitleSubclassMissing,
          message:
              StrengthCreatorPageText.noticeMessageSubclassMissing,
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
      if (_classData != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AutoHeroGreenFormWidget(
            heroId: widget.heroId,
            sectionTitle: StrengthCreatorPageText.greenFormSectionTitle,
            sectionSpacing: 12,
          ),
        ),
      if (_classData != null)
        ClassFeaturesSection(
          classData: _classData!,
          selectedLevel: _selectedLevel,
          selectedSubclass: _subclassSelection,
          initialSelections: _featureSelections,
          equipmentIds: _equipmentIds,
          onSelectionsChanged: _handleSelectionsChanged,
          skillGroupSelections: _skillGroupSelections,
          onSkillGroupSelectionChanged: _handleSkillGroupSelectionChanged,
          reservedSkillIds: _reservedSkillIds,
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
                backgroundColor: CreatorTheme.strengthAccent.withValues(alpha: 0.2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
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
                        color: Colors.grey.shade400,
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
