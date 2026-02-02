import 'package:flutter/material.dart';

import '../creators/hero_creators/hero_creator_page.dart';
import '../../core/text/heroes_sheet/hero_sheet_page_text.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/hero_sheet_theme.dart';
import 'abilities/sheet_abilities.dart';
import 'gear/sheet_gear.dart';
import 'main_stats/sheet_main_stats.dart';
import 'sheet_notes.dart';
import 'story/sheet_story.dart';

/// Top-level hero sheet that hosts all hero information.
class HeroSheetPage extends StatefulWidget {
  const HeroSheetPage({
    super.key,
    required this.heroId,
    required this.heroName,
  });

  final String heroId;
  final String heroName;

  @override
  State<HeroSheetPage> createState() => _HeroSheetPageState();
}

class _HeroSheetPageState extends State<HeroSheetPage> {
  int _currentIndex = 0;
  late final List<Widget> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      SheetMainStats(heroId: widget.heroId, heroName: widget.heroName),
      SheetAbilities(heroId: widget.heroId),
      SheetGear(heroId: widget.heroId),
      SheetStory(heroId: widget.heroId),
      SheetNotes(heroId: widget.heroId),
    ];
  }

  void _onSectionTapped(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(HeroSheetPageText.appBarTitle(widget.heroName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: HeroSheetPageText.editHeroTooltip,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HeroCreatorPage(heroId: widget.heroId),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _sections,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NavigationTheme.navBarBackground,
          boxShadow: NavigationTheme.navBarShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.person, HeroSheetPageText.navMain),
                _buildNavItem(1, Icons.flash_on, HeroSheetPageText.navAbilities),
                _buildNavItem(2, Icons.backpack, HeroSheetPageText.navGear),
                _buildNavItem(3, Icons.auto_awesome, HeroSheetPageText.navFeatures),
                _buildNavItem(4, Icons.sticky_note_2, HeroSheetPageText.navNotes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? HeroSheetTheme.orderedSectionAccents[index]
        : NavigationTheme.inactiveColor;

    return GestureDetector(
      onTap: () => _onSectionTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? NavigationTheme.selectedNavItemDecoration(
                HeroSheetTheme.orderedSectionAccents[index],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: NavigationTheme.navBarIconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: NavigationTheme.navLabelStyle(
                color: color,
                isSelected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
