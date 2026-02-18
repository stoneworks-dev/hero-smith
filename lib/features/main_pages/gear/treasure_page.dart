import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/main_pages/gear/treasure_page_text.dart';
import '../../../widgets/shared/nav_card.dart';
import '../../../widgets/treasures/treasures.dart';
import 'echelon_treasure_detail_page.dart';
import 'leveled_treasure_type_page.dart';

class TreasurePage extends ConsumerStatefulWidget {
  const TreasurePage({super.key});

  @override
  ConsumerState<TreasurePage> createState() => _TreasurePageState();
}

class _TreasurePageState extends ConsumerState<TreasurePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabData = [
    (label: 'Consumables', color: NavigationTheme.consumablesColor),
    (label: 'Trinkets', color: NavigationTheme.trinketsColor),
    (label: 'Leveled', color: NavigationTheme.leveledColor),
    (label: 'Artifacts', color: NavigationTheme.artifactsColor),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabData.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TreasurePageText.appBarTitle),
        backgroundColor: NavigationTheme.navBarBackground,
      ),
      body: Column(
        children: [
          Container(
            color: NavigationTheme.navBarBackground,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_tabData.length, (index) {
                final tab = _tabData[index];
                final isSelected = _tabController.index == index;
                final color = isSelected ? tab.color : NavigationTheme.inactiveColor;

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
                      child: Text(
                        tab.label,
                        style: NavigationTheme.tabLabelStyle(
                          color: color,
                          isSelected: isSelected,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Consumables - Echelon Groups
                const _EchelonGroupsTab(treasureType: 'consumable', displayName: 'Consumables'),
                // Trinkets - Echelon Groups
                const _EchelonGroupsTab(treasureType: 'trinket', displayName: 'Trinkets'),
                // Leveled - Equipment Type Groups
                const _LeveledTreasureTypesTab(),
                // Artifacts
                _TreasureList(
                  stream: ref.watch(componentsByTypeProvider('artifact')),
                  itemBuilder: (c) => TreasureCard(component: c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EchelonGroupsTab extends StatelessWidget {
  final String treasureType;
  final String displayName;

  const _EchelonGroupsTab({
    required this.treasureType,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NavCard(
          icon: Icons.looks_one_outlined,
          title: TreasurePageText.echelonTitle(1, displayName),
          subtitle: TreasurePageText.echelonSubtitle(1, displayName),
          accentColor: NavigationTheme.echelon1Color,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EchelonTreasureDetailPage(
                echelon: 1,
                treasureType: treasureType,
                displayName: displayName,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.looks_two_outlined,
          title: TreasurePageText.echelonTitle(2, displayName),
          subtitle: TreasurePageText.echelonSubtitle(2, displayName),
          accentColor: NavigationTheme.echelon2Color,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EchelonTreasureDetailPage(
                echelon: 2,
                treasureType: treasureType,
                displayName: displayName,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.looks_3_outlined,
          title: TreasurePageText.echelonTitle(3, displayName),
          subtitle: TreasurePageText.echelonSubtitle(3, displayName),
          accentColor: NavigationTheme.echelon3Color,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EchelonTreasureDetailPage(
                echelon: 3,
                treasureType: treasureType,
                displayName: displayName,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.looks_4_outlined,
          title: TreasurePageText.echelonTitle(4, displayName),
          subtitle: TreasurePageText.echelonSubtitle(4, displayName),
          accentColor: NavigationTheme.echelon4Color,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EchelonTreasureDetailPage(
                echelon: 4,
                treasureType: treasureType,
                displayName: displayName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeveledTreasureTypesTab extends StatelessWidget {
  const _LeveledTreasureTypesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NavCard(
          icon: Icons.shield_outlined,
          title: TreasurePageText.armorAndShieldsNavTitle,
          subtitle: TreasurePageText.armorAndShieldsNavSubtitle,
          accentColor: NavigationTheme.armorColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ArmorShieldPage(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.auto_fix_high,
          title: TreasurePageText.implementsNavTitle,
          subtitle: TreasurePageText.implementsNavSubtitle,
          accentColor: NavigationTheme.implementColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeveledTreasureTypePage(
                leveledType: 'implement',
                displayName: 'Implements',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.gavel,
          title: TreasurePageText.weaponsNavTitle,
          subtitle: TreasurePageText.weaponsNavSubtitle,
          accentColor: NavigationTheme.weaponColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeveledTreasureTypePage(
                leveledType: 'weapon',
                displayName: 'Weapons',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.category,
          title: TreasurePageText.otherNavTitle,
          subtitle: TreasurePageText.otherNavSubtitle,
          accentColor: NavigationTheme.otherLeveledColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeveledTreasureTypePage(
                leveledType: 'other',
                displayName: 'Other',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArmorShieldPage extends ConsumerStatefulWidget {
  const _ArmorShieldPage();

  @override
  ConsumerState<_ArmorShieldPage> createState() => _ArmorShieldPageState();
}

class _ArmorShieldPageState extends ConsumerState<_ArmorShieldPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabData = [
    (label: 'Armor', color: NavigationTheme.armorColor),
    (label: 'Shields', color: NavigationTheme.shieldColor),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabData.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TreasurePageText.armorShieldsTitle),
        backgroundColor: NavigationTheme.navBarBackground,
      ),
      body: Column(
        children: [
          Container(
            color: NavigationTheme.navBarBackground,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_tabData.length, (index) {
                final tab = _tabData[index];
                final isSelected = _tabController.index == index;
                final color = isSelected ? tab.color : NavigationTheme.inactiveColor;

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
                      child: Text(
                        tab.label,
                        style: NavigationTheme.tabLabelStyle(
                          color: color,
                          isSelected: isSelected,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LeveledTreasureTypeList(
                  stream: ref.watch(componentsByTypeProvider('leveled_treasure')),
                  leveledType: 'armor',
                ),
                _LeveledTreasureTypeList(
                  stream: ref.watch(componentsByTypeProvider('leveled_treasure')),
                  leveledType: 'shield',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeveledTreasureTypeList extends StatelessWidget {
  final AsyncValue<List<model.Component>> stream;
  final String leveledType;

  const _LeveledTreasureTypeList({
    required this.stream,
    required this.leveledType,
  });

  @override
  Widget build(BuildContext context) {
    return stream.when(
      data: (items) {
        final filteredItems = items
            .where((item) => item.data['leveled_type'] == leveledType)
            .toList();
        
        if (filteredItems.isEmpty) {
          return Center(child: Text(TreasurePageText.noTreasuresForType));
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => TreasureCard(component: filteredItems[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: filteredItems.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(TreasurePageText.errorMessage(e))),
    );
  }
}

class _TreasureList extends StatelessWidget {
  final AsyncValue<List<model.Component>> stream;
  final Widget Function(model.Component) itemBuilder;

  const _TreasureList({
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return stream.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Text(TreasurePageText.noneAvailable));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => itemBuilder(items[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: items.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(TreasurePageText.errorMessage(e))),
    );
  }
}


