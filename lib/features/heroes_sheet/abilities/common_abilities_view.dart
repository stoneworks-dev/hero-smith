import 'package:flutter/material.dart';

import '../../../core/models/component.dart';
import '../../../core/services/ability_data_service.dart';
import '../../../core/text/heroes_sheet/abilities/common_abilities_view_text.dart';
import '../../../core/theme/ability_colors.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';

/// Enum for common ability categories
enum CommonAbilityCategory {
  actions,
  move,
  maneuvers,
}

extension CommonAbilityCategoryLabel on CommonAbilityCategory {
  String get label {
    switch (this) {
      case CommonAbilityCategory.actions:
        return CommonAbilitiesViewText.actionLabelActions;
      case CommonAbilityCategory.move:
        return CommonAbilitiesViewText.actionLabelMove;
      case CommonAbilityCategory.maneuvers:
        return CommonAbilitiesViewText.actionLabelManeuvers;
    }
  }

  IconData get icon {
    switch (this) {
      case CommonAbilityCategory.actions:
        return Icons.flash_on;
      case CommonAbilityCategory.move:
        return Icons.directions_walk;
      case CommonAbilityCategory.maneuvers:
        return Icons.directions_run;
    }
  }

  Color get color {
    switch (this) {
      case CommonAbilityCategory.actions:
        return AbilityColors.getActionTypeColor('main action');
      case CommonAbilityCategory.move:
        return AbilityColors.getActionTypeColor('move action');
      case CommonAbilityCategory.maneuvers:
        return AbilityColors.getActionTypeColor('maneuver');
    }
  }
}

/// Displays common abilities available to all heroes.
///
/// Common abilities are loaded from the ability library and grouped by category:
/// - Actions (Main Actions)
/// - Move (Move Actions)
/// - Maneuvers
class CommonAbilitiesView extends StatefulWidget {
  const CommonAbilitiesView({super.key});

  @override
  State<CommonAbilitiesView> createState() => _CommonAbilitiesViewState();
}

class _CommonAbilitiesViewState extends State<CommonAbilitiesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: CommonAbilityCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Categorize an ability based on its action_type field
  CommonAbilityCategory _categorizeAbility(Component ability) {
    final data = ability.data;
    final actionType =
        (data['action_type']?.toString().toLowerCase() ?? '').trim();

    // Categorize by action_type
    if (actionType.contains('move')) {
      return CommonAbilityCategory.move;
    }
    if (actionType.contains('maneuver')) {
      return CommonAbilityCategory.maneuvers;
    }
    // Main actions and any other type go into Actions tab
    return CommonAbilityCategory.actions;
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<Component>>(
      future: _loadCommonAbilities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: NavigationTheme.featuresColor));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    CommonAbilitiesViewText.errorTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final abilities = snapshot.data ?? [];

        if (abilities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                CommonAbilitiesViewText.emptyListMessage,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        // Group abilities by category
        final grouped = <CommonAbilityCategory, List<Component>>{};
        for (final category in CommonAbilityCategory.values) {
          grouped[category] = [];
        }

        for (final ability in abilities) {
          final category = _categorizeAbility(ability);
          grouped[category]!.add(ability);
        }

        // Sort each category by name
        for (final category in CommonAbilityCategory.values) {
          grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
        }

        return AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Column(
              children: [
                // Custom styled tab bar - compact horizontal
                Container(
                  color: NavigationTheme.navBarBackground,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: List.generate(CommonAbilityCategory.values.length,
                        (index) {
                      final category = CommonAbilityCategory.values[index];
                      final isSelected = _tabController.index == index;
                      final color = isSelected
                          ? category.color
                          : NavigationTheme.inactiveColor;
                      final count = grouped[category]!.length;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(index),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: isSelected
                                ? NavigationTheme.selectedNavItemDecoration(
                                    category.color)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  color: color,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    category.label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: category.color.withValues(alpha: isSelected ? 1.0 : 0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for (final category in CommonAbilityCategory.values)
                        _buildCategoryList(grouped[category]!, category),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(
      List<Component> abilities, CommonAbilityCategory category) {
    final theme = Theme.of(context);

    if (abilities.isEmpty) {
      return Container(
        color: NavigationTheme.cardBackgroundDark,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon,
                    size: 48, color: category.color.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  '${CommonAbilitiesViewText.emptyCategoryPrefix}${category.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CommonAbilitiesViewText.emptyCategorySubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: NavigationTheme.cardBackgroundDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: abilities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AbilityExpandableItem(component: abilities[index]),
          );
        },
      ),
    );
  }

  Future<List<Component>> _loadCommonAbilities() async {
    final library = await AbilityDataService().loadLibrary();
    final components = <Component>[];

    for (final component in library.components) {
      final path = component.data['ability_source_path'] as String? ?? '';
      final normalizedPath = path.toLowerCase();
      if (normalizedPath.contains('class_abilities_new/common/') ||
          normalizedPath
              .contains('class_abilities_simplified/common_abilities')) {
        components.add(component);
      }
    }

    // Sort by name
    components.sort((a, b) => a.name.compareTo(b.name));

    return components;
  }
}
