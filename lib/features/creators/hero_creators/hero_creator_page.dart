import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/core/storage/hero_storage_contract.dart';
import 'package:hero_smith/core/text/creators/hero_creators/hero_creator_page_text.dart';
import 'package:hero_smith/core/theme/app_icon.dart';
import 'package:hero_smith/core/theme/app_icons.dart';
import 'package:hero_smith/core/theme/form_theme.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/features/creators/hero_creators/story_creator_page.dart';
import 'package:hero_smith/features/creators/hero_creators/strife_creator_page.dart';
import 'package:hero_smith/features/creators/hero_creators/strength_creator_page.dart';
import 'package:hero_smith/features/hero_builder/application/hero_builder_controller.dart';
import 'package:hero_smith/features/hero_builder/application/hero_builder_providers.dart';
import 'package:hero_smith/features/hero_builder/domain/hero_draft.dart';
import 'package:hero_smith/features/heroes_sheet/hero_sheet_page.dart';
import 'package:hero_smith/features/heroes_sheet/main_stats/hero_main_stats_providers.dart';

/// The app-bar Save action for the active creator tab. Keeping all three tabs
/// in one mapping prevents a dirty section from becoming impossible to commit.
@visibleForTesting
String? heroCreatorSaveTooltipForTab({
  required int tabIndex,
  required bool storyDirty,
  required bool strifeDirty,
  required bool strengthDirty,
}) {
  return switch (tabIndex) {
    0 when storyDirty => HeroCreatorPageText.saveHeroTooltip,
    1 when strifeDirty => HeroCreatorPageText.saveStrifeTooltip,
    2 when strengthDirty => HeroCreatorPageText.saveStrengthTooltip,
    _ => null,
  };
}

/// The three creator tabs share one [HeroBuilderController] per hero, so this
/// shell no longer orchestrates the tabs through `GlobalKey`s: dirty state is
/// read straight from the controller, and Save/Discard drive the controller's
/// [HeroBuilderController.commit]/`discardSection` directly. The only shell-owned
/// state left is import-needs-save flags (a persisted config concern) and the
/// tab-switch guard bookkeeping.
class HeroCreatorPage extends ConsumerStatefulWidget {
  const HeroCreatorPage({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<HeroCreatorPage> createState() => _HeroCreatorPageState();
}

class _HeroCreatorPageState extends ConsumerState<HeroCreatorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _suppressTabNotification = false;
  bool _handlingTabPrompt = false;
  bool _importNeedsSaveStory = false;
  bool _importNeedsSaveStrife = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadImportFlag();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  HeroBuilderController get _controller =>
      ref.read(heroBuilderControllerProvider(widget.heroId).notifier);

  HeroBuilderState get _state =>
      ref.read(heroBuilderControllerProvider(widget.heroId));

  // Dirty getters read the controller live so async handlers see the current
  // value across an `await` gap. Import flags force a tab dirty until its next
  // successful commit.
  bool get _storyDirty => _state.storyDirty || _importNeedsSaveStory;
  bool get _strifeDirty => _state.strifeDirty || _importNeedsSaveStrife;
  bool get _strengthDirty => _state.strengthDirty;
  bool get _anyDirty => _storyDirty || _strifeDirty || _strengthDirty;

  HeroBuilderSection _sectionFor(int index) {
    switch (index) {
      case 0:
        return HeroBuilderSection.story;
      case 1:
        return HeroBuilderSection.strife;
      default:
        return HeroBuilderSection.strength;
    }
  }

  bool _tabDirty(int index) {
    switch (index) {
      case 0:
        return _storyDirty;
      case 1:
        return _strifeDirty;
      default:
        return _strengthDirty;
    }
  }

  Future<void> _loadImportFlag() async {
    final config = ref.read(heroConfigServiceProvider);
    final storyConfig = await config.getConfigValue(
      widget.heroId,
      HeroConfigKeys.importNeedsSaveStory,
    );
    final strifeConfig = await config.getConfigValue(
      widget.heroId,
      HeroConfigKeys.importNeedsSaveStrife,
    );
    final needsStory = storyConfig?['value'] == true;
    final needsStrife = strifeConfig?['value'] == true;
    if (!mounted) return;
    if (_importNeedsSaveStory == needsStory &&
        _importNeedsSaveStrife == needsStrife) {
      return;
    }
    setState(() {
      _importNeedsSaveStory = needsStory;
      _importNeedsSaveStrife = needsStrife;
    });
  }

  Future<void> _clearImportFlag({
    bool storySaved = false,
    bool strifeSaved = false,
  }) async {
    if (!_importNeedsSaveStory && !_importNeedsSaveStrife) return;
    final config = ref.read(heroConfigServiceProvider);
    if (storySaved && _importNeedsSaveStory) {
      await config.setConfigValue(
        heroId: widget.heroId,
        key: HeroConfigKeys.importNeedsSaveStory,
        value: {'value': false},
      );
    }
    if (strifeSaved && _importNeedsSaveStrife) {
      await config.setConfigValue(
        heroId: widget.heroId,
        key: HeroConfigKeys.importNeedsSaveStrife,
        value: {'value': false},
      );
    }
    if (!mounted) return;
    setState(() {
      if (storySaved) _importNeedsSaveStory = false;
      if (strifeSaved) _importNeedsSaveStrife = false;
    });
  }

  /// Commits every dirty section in one transaction. Because the commit service
  /// already plans all three sections from the shared draft, this is the single
  /// save path for the whole builder — the per-tab "save" and "save all" flows
  /// collapse into it.
  Future<bool> _commit() async {
    // An empty hero name persists as "New Hero", matching the old Story save.
    if (_state.story.name.trim().isEmpty) {
      _controller.updateStory((draft) => draft.copyWith(name: 'New Hero'));
    }

    final result = await _controller.commit();
    if (!mounted) return result.isSuccess;

    if (result.isSuccess) {
      // Refresh downstream providers so the hero sheet and derived stats
      // reflect the committed data (previously done inside the Strife save).
      // `heroRepositoryProvider` is deliberately *not* invalidated here: it is
      // a stateless `Provider<HeroRepository>` wrapping the database (no
      // per-hero cache), so invalidating it discards and recreates a wrapper
      // object without affecting data freshness — pure dead weight.
      ref.invalidate(heroEquipmentBonusesProvider(widget.heroId));
      ref.invalidate(heroValuesProvider(widget.heroId));
      ref.invalidate(heroAssemblyProvider(widget.heroId));
      await _clearImportFlag(storySaved: true, strifeSaved: true);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(HeroCreatorPageText.saved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${HeroCreatorPageText.failedToSavePrefix}${result.message ?? ''}',
          ),
          backgroundColor:
              result.kind == HeroBuilderCommitKind.validationFailure
                  ? Colors.orange.shade800
                  : Colors.red,
        ),
      );
    }
    return result.isSuccess;
  }

  Future<void> _handleTabChange() async {
    if (_suppressTabNotification || _handlingTabPrompt) {
      _suppressTabNotification = false;
      return;
    }
    if (!mounted) return;

    final oldIndex = _tabController.previousIndex;
    final newIndex = _tabController.index;

    if (oldIndex == newIndex) {
      setState(() {});
      return;
    }

    if (_tabDirty(oldIndex)) {
      _handlingTabPrompt = true;
      // Temporarily block the tab change while we prompt.
      _suppressTabNotification = true;
      _tabController.index = oldIndex;

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(HeroCreatorPageText.tabChangeDialogTitle),
          content: Text(
            '${HeroCreatorPageText.tabChangeDialogContentPrefix}'
            '${_tabLabel(oldIndex)}'
            '${HeroCreatorPageText.tabChangeDialogContentSuffix}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text(HeroCreatorPageText.tabChangeDialogCancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('discard'),
              child:
                  const Text(HeroCreatorPageText.tabChangeDialogDiscardLabel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop('save'),
              icon: const Icon(Icons.save),
              label: const Text(HeroCreatorPageText.tabChangeDialogSaveLabel),
            ),
          ],
        ),
      );

      if (result == 'save') {
        final saved = await _commit();
        if (mounted && saved) {
          _suppressTabNotification = true;
          _tabController.index = newIndex;
        }
      } else if (result == 'discard') {
        // Every section now restores its baseline in memory with no database
        // write, so all three tabs honour Discard literally.
        _controller.discardSection(_sectionFor(oldIndex));
        if (mounted) {
          _suppressTabNotification = true;
          _tabController.index = newIndex;
        }
      }
      // On 'cancel' or a dismissed dialog we stay on the current tab.
      _handlingTabPrompt = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _tabLabel(int index) {
    switch (index) {
      case 0:
        return HeroCreatorPageText.tabChangeDialogContentStoryLabel;
      case 1:
        return HeroCreatorPageText.tabChangeDialogContentStrifeLabel;
      default:
        return HeroCreatorPageText.tabChangeDialogContentStrengthLabel;
    }
  }

  Future<bool> _onWillPop() async {
    if (!_anyDirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(HeroCreatorPageText.willPopDialogTitle),
        content: const Text(HeroCreatorPageText.willPopDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text(HeroCreatorPageText.willPopDialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text(HeroCreatorPageText.willPopDialogDiscardLabel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop('save'),
            icon: const Icon(Icons.save),
            label: const Text(HeroCreatorPageText.willPopDialogSaveLabel),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _commit();
      return true;
    }
    if (result == 'discard') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final builderState =
        ref.watch(heroBuilderControllerProvider(widget.heroId));
    final persistedEntries =
        ref.watch(heroEntriesProvider(widget.heroId)).valueOrNull ?? const [];

    final selectedComponentIds = <String>{};
    void addId(String? value) {
      final id = value?.trim();
      if (id != null && id.isNotEmpty) selectedComponentIds.add(id);
    }

    final story = builderState.story;
    addId(story.ancestryId);
    selectedComponentIds.addAll(story.ancestryTraitIds);
    selectedComponentIds.addAll(story.ancestryTraitChoices.values);
    addId(story.environmentId);
    addId(story.organisationId);
    addId(story.upbringingId);
    addId(story.environmentSkillId);
    addId(story.organisationSkillId);
    addId(story.upbringingSkillId);
    addId(story.cultureLanguageId);
    addId(story.careerId);
    for (final id in story.careerLanguageIds) {
      addId(id);
    }
    selectedComponentIds.addAll(story.careerSkillIds);
    selectedComponentIds.addAll(story.careerPerkIds);
    addId(story.complicationId);
    selectedComponentIds.addAll(story.complicationChoices.values);

    final strife = builderState.strife;
    addId(strife.classId);
    for (final id in strife.levelChoiceSelections.values) {
      addId(id);
    }
    for (final id in strife.skillSelections.values) {
      addId(id);
    }
    for (final id in strife.abilitySelections.values) {
      addId(id);
    }
    for (final id in strife.perkSelections.values) {
      addId(id);
    }
    for (final id in strife.equipmentIds) {
      addId(id);
    }
    addId(strife.subclass?.subclassKey);
    addId(strife.subclass?.deityId);

    for (final entry in builderState.strength.featureSelections.entries) {
      addId(entry.key);
      selectedComponentIds.addAll(entry.value);
    }
    for (final selections
        in builderState.strength.skillGroupSelections.values) {
      selectedComponentIds.addAll(selections.values);
    }
    for (final entry in persistedEntries) {
      addId(entry.entryId);
    }

    final allComponents =
        ref.watch(allComponentsProvider).valueOrNull ?? const [];
    final retiredSelections = allComponents
        .where(
          (component) =>
              component.isRetired &&
              selectedComponentIds.contains(component.id),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final storyDirty = builderState.storyDirty || _importNeedsSaveStory;
    final strifeDirty = builderState.strifeDirty || _importNeedsSaveStrife;
    final strengthDirty = builderState.strengthDirty;

    final trimmedName = builderState.story.name.trim();
    final heroTitle = trimmedName.isEmpty
        ? HeroCreatorPageText.heroTitleInitial
        : trimmedName;
    final heroNameForSheet = trimmedName.isEmpty ? heroTitle : trimmedName;
    final saveTooltip = heroCreatorSaveTooltipForTab(
      tabIndex: _tabController.index,
      storyDirty: storyDirty,
      strifeDirty: strifeDirty,
      strengthDirty: strengthDirty,
    );

    // Tab data with icons and colors
    const tabData = [
      (
        icon: NavIcons.story,
        label: HeroCreatorPageText.tabLabelStory,
        color: NavigationTheme.storyColor
      ),
      (
        icon: NavIcons.strife,
        label: HeroCreatorPageText.tabLabelStrife,
        color: NavigationTheme.strifeColor
      ),
      (
        icon: AbilityIcons.progression,
        label: HeroCreatorPageText.tabLabelStrength,
        color: NavigationTheme.featuresColor
      ),
    ];

    return ProviderScope(
      overrides: [
        retiredContentVisibleIdsProvider.overrideWithValue(
          Set<String>.unmodifiable(selectedComponentIds),
        ),
      ],
      child: PopScope(
        canPop: !(storyDirty || strifeDirty || strengthDirty),
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && _anyDirty) {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: NavigationTheme.navBarBackground,
          appBar: AppBar(
            title: Text(
              heroTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: FormTheme.textBright,
              ),
            ),
            centerTitle: true,
            backgroundColor: NavigationTheme.navBarBackground,
            elevation: 0,
            iconTheme: const IconThemeData(color: FormTheme.textBright),
            actions: [
              IconButton(
                onPressed: () async {
                  if (_anyDirty) {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                            HeroCreatorPageText.viewSheetDialogTitle),
                        content: const Text(
                            HeroCreatorPageText.viewSheetDialogContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop('cancel'),
                            child: const Text(
                                HeroCreatorPageText.viewSheetDialogCancelLabel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop('discard'),
                            child: const Text(HeroCreatorPageText
                                .viewSheetDialogDiscardLabel),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(ctx).pop('save'),
                            icon: const Icon(Icons.save),
                            label: const Text(
                                HeroCreatorPageText.viewSheetDialogSaveLabel),
                          ),
                        ],
                      ),
                    );
                    if (result == 'cancel' || result == null) return;
                    if (result == 'save') {
                      await _commit();
                    }
                  }
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HeroSheetPage(
                        heroId: widget.heroId,
                        heroName: heroNameForSheet,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                tooltip: HeroCreatorPageText.viewHeroSheetTooltip,
              ),
              if (saveTooltip != null)
                IconButton(
                  onPressed: _commit,
                  icon: const Icon(Icons.save),
                  tooltip: saveTooltip,
                ),
            ],
          ),
          body: Column(
            children: [
              // Custom styled tab bar
              Container(
                color: NavigationTheme.navBarBackground,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(tabData.length, (index) {
                    final tab = tabData[index];
                    final isSelected = _tabController.index == index;
                    final color =
                        isSelected ? tab.color : NavigationTheme.inactiveColor;

                    // Show dirty indicator
                    final isDirty = (index == 0 && storyDirty) ||
                        (index == 1 && strifeDirty) ||
                        (index == 2 && strengthDirty);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: isSelected
                              ? NavigationTheme.selectedNavItemDecoration(
                                  tab.color)
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AppIcon(
                                    tab.icon,
                                    color: color,
                                    size: NavigationTheme.tabIconSize,
                                  ),
                                  if (isDirty)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: NavigationTheme
                                                .navBarBackground,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                style: NavigationTheme.tabLabelStyle(
                                  color: color,
                                  isSelected: isSelected,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (retiredSelections.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade300,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              HeroCreatorPageText.retiredContentTitle,
                              style: TextStyle(
                                color: FormTheme.textBright,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              HeroCreatorPageText.retiredContentMessage,
                              style: TextStyle(
                                color: FormTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              retiredSelections
                                  .map((component) => component.name)
                                  .join(', '),
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StoryCreatorTab(heroId: widget.heroId),
                    StrifeCreatorPage(heroId: widget.heroId),
                    StrenghtCreatorPage(heroId: widget.heroId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
