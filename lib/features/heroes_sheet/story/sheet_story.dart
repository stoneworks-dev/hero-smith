import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/class_data.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/models/subclass_models.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/class_feature_data_service.dart';
import '../../../core/services/class_feature_grants_service.dart';
import '../../../core/services/complication_grants_service.dart';
import '../../../core/services/story_creator_service.dart';
import '../../../core/services/skill_data_service.dart';
import '../../../core/services/subclass_data_service.dart';

import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/story_theme.dart';
import '../../../core/text/heroes_sheet/story/sheet_story_text.dart';
import '../../creators/widgets/strength_creator/class_features_section.dart';

import '../../../widgets/perks/perks_selection_widget.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';
import 'story_sections/story_sections.dart';

part 'sheet_story_story_tab.dart';
part 'sheet_story_skills_tab.dart';
part 'sheet_story_languages_tab.dart';
part 'sheet_story_titles_tab.dart';
part 'sheet_story_features_tab.dart';
part 'sheet_story_perks_tab.dart';

// Provider to fetch a single component by ID
final componentByIdProvider =
    FutureProvider.family<model.Component?, String>((ref, id) async {
  final allComponents = await ref.read(allComponentsProvider.future);
  return allComponents.firstWhere(
    (c) => c.id == id,
    orElse: () => model.Component(
      id: '',
      type: '',
      name: 'Not found',
      data: const {},
      source: '',
    ),
  );
});

/// Class features, narrative, background, and progression notes for the hero.
class SheetStory extends ConsumerStatefulWidget {
  const SheetStory({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<SheetStory> createState() => _SheetStoryState();
}

class _SheetStoryState extends ConsumerState<SheetStory>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  dynamic _storyData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(storyCreatorServiceProvider);
      final result = await service.loadInitialData(widget.heroId);
      
      if (mounted) {
        setState(() {
          _storyData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load story data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark themed tab bar
        Container(
          color: NavigationTheme.navBarBackground,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _getTabColor(_tabController.index),
                      width: 3,
                    ),
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: [
                  _buildTab(SheetStoryTabsText.features, Icons.auto_awesome, 0, NavigationTheme.kitsColor),
                  _buildTab(SheetStoryTabsText.story, Icons.menu_book, 1, StoryTheme.storyAccent),
                  _buildTab(SheetStoryTabsText.skills, Icons.psychology, 2, StoryTheme.skillsAccent),
                  _buildTab(SheetStoryTabsText.languages, Icons.translate, 3, StoryTheme.languagesAccent),
                  _buildTab(SheetStoryTabsText.perks, Icons.star, 4, StoryTheme.perksAccent),
                  _buildTab(SheetStoryTabsText.titles, Icons.military_tech, 5, StoryTheme.titlesAccent),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FeaturesTab(heroId: widget.heroId),
              _buildStoryTab(context),
              _SkillsTab(heroId: widget.heroId),
              _LanguagesTab(heroId: widget.heroId),
              _PerksTab(heroId: widget.heroId),
              _TitlesTab(heroId: widget.heroId),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTabColor(int index) {
    const colors = [
      NavigationTheme.kitsColor, // Features
      StoryTheme.storyAccent, // Story - Purple
      StoryTheme.skillsAccent, // Skills - Green
      StoryTheme.languagesAccent, // Languages - Blue
      StoryTheme.perksAccent, // Perks - Orange
      StoryTheme.titlesAccent, // Titles - Gold
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }

  Widget _buildTab(String label, IconData icon, int index, Color color) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? color : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
