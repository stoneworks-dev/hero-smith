import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/core/text/creators/hero_creators/hero_creator_page_text.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/features/creators/hero_creators/story_creator_page.dart';
import 'package:hero_smith/features/creators/hero_creators/strife_creator_page.dart';
import 'package:hero_smith/features/creators/hero_creators/strength_creator_page.dart';
import 'package:hero_smith/features/heroes_sheet/hero_sheet_page.dart';

class HeroCreatorPage extends ConsumerStatefulWidget {
  const HeroCreatorPage({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<HeroCreatorPage> createState() => _HeroCreatorPageState();
}

class _HeroCreatorPageState extends ConsumerState<HeroCreatorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<StoryCreatorTabState> _storyTabKey =
      GlobalKey<StoryCreatorTabState>();
  final GlobalKey<_StrifeCreatorTabState> _strifeTabKey =
      GlobalKey<_StrifeCreatorTabState>();
  final GlobalKey<StrenghtCreatorPageState> _strengthPageKey =
      GlobalKey<StrenghtCreatorPageState>();

  bool _storyDirty = false;
  bool _strifeDirty = false;
  String _heroTitle = HeroCreatorPageText.heroTitleInitial;
  String? _heroName;
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

  Future<void> _loadImportFlag() async {
    final db = ref.read(appDatabaseProvider);
    final storyConfig =
        await db.getHeroConfigValue(widget.heroId, 'import.needs_save_story');
    final strifeConfig =
        await db.getHeroConfigValue(widget.heroId, 'import.needs_save_strife');
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
      if (_importNeedsSaveStory) _storyDirty = true;
      if (_importNeedsSaveStrife) _strifeDirty = true;
    });
  }

  Future<void> _clearImportFlag({
    bool storySaved = false,
    bool strifeSaved = false,
  }) async {
    if (!_importNeedsSaveStory && !_importNeedsSaveStrife) return;
    final db = ref.read(appDatabaseProvider);
    if (storySaved && _importNeedsSaveStory) {
      await db.setHeroConfig(
        heroId: widget.heroId,
        configKey: 'import.needs_save_story',
        value: {'value': false},
      );
    }
    if (strifeSaved && _importNeedsSaveStrife) {
      await db.setHeroConfig(
        heroId: widget.heroId,
        configKey: 'import.needs_save_strife',
        value: {'value': false},
      );
    }
    if (!mounted) return;
    setState(() {
      if (storySaved) _importNeedsSaveStory = false;
      if (strifeSaved) _importNeedsSaveStrife = false;
      _storyDirty = _storyTabKey.currentState?.isDirty ?? false;
      _strifeDirty = _strifeTabKey.currentState?.isDirty ?? false;
      if (_importNeedsSaveStory) _storyDirty = true;
      if (_importNeedsSaveStrife) _strifeDirty = true;
    });
  }

  Future<void> _handleTabChange() async {
    if (_suppressTabNotification || _handlingTabPrompt) {
      _suppressTabNotification = false;
      return;
    }
    if (!mounted) return;

    // Check if trying to leave a dirty tab
    final oldIndex = _tabController.previousIndex;
    final newIndex = _tabController.index;

    if (oldIndex == newIndex) {
      setState(() {});
      return;
    }

    // Check if the old tab has unsaved changes
    final bool hasUnsavedChanges =
        (oldIndex == 0 && _storyDirty) || (oldIndex == 1 && _strifeDirty);

    if (hasUnsavedChanges) {
      _handlingTabPrompt = true;
      // Temporarily block the tab change
      _suppressTabNotification = true;
      _tabController.index = oldIndex;

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(HeroCreatorPageText.tabChangeDialogTitle),
          content: Text(
            '${HeroCreatorPageText.tabChangeDialogContentPrefix}'
            '${oldIndex == 0 ? HeroCreatorPageText.tabChangeDialogContentStoryLabel : HeroCreatorPageText.tabChangeDialogContentStrifeLabel}'
            '${HeroCreatorPageText.tabChangeDialogContentSuffix}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child:
                  const Text(HeroCreatorPageText.tabChangeDialogCancelLabel),
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
        if (oldIndex == 0) {
          await _saveStory();
        } else if (oldIndex == 1) {
          await _saveStrife();
        }
        if (mounted) {
          _suppressTabNotification = true;
          _tabController.index = newIndex;
        }
      } else if (result == 'discard') {
        if (mounted) {
          _suppressTabNotification = true;
          _tabController.index = newIndex;
        }
      }
      // If 'cancel' or dialog dismissed, stay on current tab (already set above)
      _handlingTabPrompt = false;
    }

    if (mounted && _tabController.index == 2) {
      _strengthPageKey.currentState?.reload();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleStoryDirty(bool dirty) {
    final effectiveDirty = dirty || _importNeedsSaveStory;
    if (_storyDirty == effectiveDirty) return;
    setState(() {
      _storyDirty = effectiveDirty;
    });
  }

  void _handleStoryTitleChanged(String title) {
    final normalized = title.trim().isEmpty
        ? HeroCreatorPageText.heroTitleFallback
        : title.trim();
    if (_heroTitle == normalized) return;
    setState(() {
      _heroTitle = normalized;
      _heroName = title.trim().isNotEmpty ? title.trim() : null;
    });
  }

  void _handleStrifeDirty(bool dirty) {
    final effectiveDirty = dirty || _importNeedsSaveStrife;
    if (_strifeDirty == effectiveDirty) return;
    setState(() {
      _strifeDirty = effectiveDirty;
    });
  }

  Future<void> _saveStory() async {
    final state = _storyTabKey.currentState;
    if (state == null) return;
    await state.save();
    await _clearImportFlag(storySaved: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved!')),
    );
  }

  Future<void> _saveStrife() async {
    final state = _strifeTabKey.currentState;
    if (state == null) return;
    await state.save();
    await _clearImportFlag(strifeSaved: true);
  }

  Future<void> _saveAll() async {
    if (_storyDirty) {
      await _saveStory();
    }
    final strifeState = _strifeTabKey.currentState;
    if (strifeState != null && strifeState.isDirty) {
      await strifeState.save();
    }
    await _clearImportFlag(storySaved: true, strifeSaved: true);
  }

  Future<bool> _onWillPop() async {
    if (!(_storyDirty || _strifeDirty)) return true;
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
      await _saveAll();
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
    
    // Tab data with icons and colors
    const tabData = [
      (icon: Icons.auto_stories, label: HeroCreatorPageText.tabLabelStory, color: NavigationTheme.storyColor),
      (icon: Icons.local_fire_department, label: HeroCreatorPageText.tabLabelStrife, color: NavigationTheme.strifeColor),
      (icon: Icons.fitness_center, label: HeroCreatorPageText.tabLabelStrength, color: NavigationTheme.featuresColor),
    ];
    
    return PopScope(
      canPop: !(_storyDirty || _strifeDirty),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && (_storyDirty || _strifeDirty)) {
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
            _heroTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: NavigationTheme.navBarBackground,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () async {
                if (_storyDirty || _strifeDirty) {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title:
                          const Text(HeroCreatorPageText.viewSheetDialogTitle),
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
                          child: const Text(
                              HeroCreatorPageText.viewSheetDialogDiscardLabel),
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
                    await _saveAll();
                  }
                }
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HeroSheetPage(
                      heroId: widget.heroId,
                      heroName: _heroName ?? _heroTitle,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              tooltip: HeroCreatorPageText.viewHeroSheetTooltip,
            ),
            if (_tabController.index == 0 && _storyDirty)
              IconButton(
                onPressed: _saveStory,
                icon: const Icon(Icons.save),
                tooltip: HeroCreatorPageText.saveHeroTooltip,
              )
            else if (_tabController.index == 1 && _strifeDirty)
              IconButton(
                onPressed: _saveStrife,
                icon: const Icon(Icons.save),
                tooltip: HeroCreatorPageText.saveStrifeTooltip,
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
                  final color = isSelected ? tab.color : NavigationTheme.inactiveColor;
                  
                  // Show dirty indicator
                  final isDirty = (index == 0 && _storyDirty) || (index == 1 && _strifeDirty);

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
                            ? NavigationTheme.selectedNavItemDecoration(tab.color)
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
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
                                          color: NavigationTheme.navBarBackground,
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
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StoryCreatorTab(
                    key: _storyTabKey,
                    heroId: widget.heroId,
                    onDirtyChanged: _handleStoryDirty,
                    onTitleChanged: _handleStoryTitleChanged,
                  ),
                  StrifeCreatorTab(
                    key: _strifeTabKey,
                    heroId: widget.heroId,
                    onDirtyChanged: _handleStrifeDirty,
                  ),
                  StrenghtCreatorPage(
                    key: _strengthPageKey,
                    heroId: widget.heroId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StrifeCreatorTab extends StatefulWidget {
  const StrifeCreatorTab({
    super.key,
    required this.heroId,
    required this.onDirtyChanged,
  });

  final String heroId;
  final ValueChanged<bool> onDirtyChanged;

  @override
  _StrifeCreatorTabState createState() => _StrifeCreatorTabState();
}

class _StrifeCreatorTabState extends State<StrifeCreatorTab>
    with AutomaticKeepAliveClientMixin {
  bool _dirty = false;
  final GlobalKey<StrifeCreatorPageState> _pageKey =
    GlobalKey<StrifeCreatorPageState>();

  bool get isDirty => _dirty;

  void _handleDirtyChanged(bool dirty) {
    if (_dirty == dirty) return;
    setState(() {
      _dirty = dirty;
    });
    widget.onDirtyChanged(dirty);
  }

  Future<void> save() async {
    final state = _pageKey.currentState;
    if (state == null) return;
    await state.handleSave();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StrifeCreatorPage(
      key: _pageKey,
      heroId: widget.heroId,
      onDirtyChanged: _handleDirtyChanged,
      onSaveRequested: () async {
        setState(() {
          _dirty = false;
        });
        widget.onDirtyChanged(false);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
