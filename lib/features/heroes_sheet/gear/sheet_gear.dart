import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text/heroes_sheet/gear/sheet_gear_text.dart';
import '../../../core/theme/navigation_theme.dart';
import 'inventory_tab.dart';
import 'kits_tab.dart';
import 'treasures_tab.dart';

// Re-export utilities and widgets for external use
export 'gear_dialogs.dart';
export 'gear_utils.dart';
export 'gear_widgets.dart';
export 'inventory_widgets.dart';
export 'kit_widgets.dart';

/// Gear and treasures management for the hero with tabbed interface.
class SheetGear extends ConsumerStatefulWidget {
  const SheetGear({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<SheetGear> createState() => _SheetGearState();
}

class _SheetGearState extends ConsumerState<SheetGear>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab data with icons and colors
  static const _tabData = [
    (
      icon: Icons.shield,
      label: SheetGearText.tabKitsLabel,
      color: NavigationTheme.kitsColor
    ),
    (
      icon: Icons.auto_awesome,
      label: SheetGearText.tabTreasuresLabel,
      color: NavigationTheme.treasureColor
    ),
    (
      icon: Icons.inventory_2,
      label: SheetGearText.tabInventoryLabel,
      color: NavigationTheme.itemsColor
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom styled tab bar - only rebuilds on tab change
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Container(
              color: NavigationTheme.navBarBackground,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: List.generate(_tabData.length, (index) {
                  final tab = _tabData[index];
                  final isSelected = _tabController.index == index;
                  final color =
                      isSelected ? tab.color : NavigationTheme.inactiveColor;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: isSelected
                            ? NavigationTheme.selectedNavItemDecoration(
                                tab.color)
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              color: color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tab.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        Expanded(
          child: Container(
            color: NavigationTheme.cardBackgroundDark,
            child: TabBarView(
              controller: _tabController,
              children: [
                KitsTab(heroId: widget.heroId),
                TreasuresTab(heroId: widget.heroId),
                InventoryTab(heroId: widget.heroId),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
