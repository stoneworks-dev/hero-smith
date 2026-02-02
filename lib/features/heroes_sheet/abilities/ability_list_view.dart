import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../core/repositories/hero_entry_repository.dart';
import '../../../core/services/ability_data_service.dart';
import '../../../core/text/heroes_sheet/abilities/ability_list_view_text.dart';
import '../../../core/theme/ability_colors.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';

/// Enum for action type categories
enum ActionCategory {
  actions,
  maneuvers,
  triggered,
}

extension ActionCategoryLabel on ActionCategory {
  String get label {
    switch (this) {
      case ActionCategory.actions:
        return AbilityListViewText.actionLabelActions;
      case ActionCategory.maneuvers:
        return AbilityListViewText.actionLabelManeuvers;
      case ActionCategory.triggered:
        return AbilityListViewText.actionLabelTriggered;
    }
  }
  
  IconData get icon {
    switch (this) {
      case ActionCategory.actions:
        return Icons.flash_on;
      case ActionCategory.maneuvers:
        return Icons.directions_run;
      case ActionCategory.triggered:
        return Icons.bolt;
    }
  }
  
  Color get color {
    switch (this) {
      case ActionCategory.actions:
        return AbilityColors.getActionTypeColor('main action');
      case ActionCategory.maneuvers:
        return AbilityColors.getActionTypeColor('maneuver');
      case ActionCategory.triggered:
        return AbilityColors.getActionTypeColor('triggered action');
    }
  }
}

/// Displays hero abilities grouped by action type (Actions, Maneuvers, Triggered)
class AbilityListView extends ConsumerStatefulWidget {
  const AbilityListView({
    super.key, 
    required this.abilityIds, 
    required this.heroId,
    this.loadAbilities,
  });

  final List<String> abilityIds;
  final String heroId;
  final Future<List<Component>> Function(List<String> abilityIds)? loadAbilities;

  @override
  ConsumerState<AbilityListView> createState() => _AbilityListViewState();
}

class _AbilityListViewState extends ConsumerState<AbilityListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ActionCategory.values.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Categorize an ability into an action category based on action_type
  ActionCategory _categorizeAbility(Component ability) {
    final data = ability.data;
    final actionType = (data['action_type']?.toString().toLowerCase() ?? '').trim();
    
    // Categorize by action_type
    if (actionType.contains('triggered')) {
      return ActionCategory.triggered;
    }
    if (actionType.contains('maneuver')) {
      return ActionCategory.maneuvers;
    }
    if (actionType.contains('action')) {
      return ActionCategory.actions;
    }
    
    // Fallback: check trigger field for older data format
    final trigger = data['trigger']?.toString().toLowerCase() ?? '';
    if (trigger == 'triggered' || trigger == 'free triggered') {
      return ActionCategory.triggered;
    }
    if (trigger == 'maneuver' || trigger == 'free maneuver') {
      return ActionCategory.maneuvers;
    }
    
    // Default to actions
    return ActionCategory.actions;
  }

  @override
  Widget build(BuildContext context) {
    
    final load = widget.loadAbilities ?? _loadAbilityComponents;

    return FutureBuilder<List<Component>>(
      future: load(widget.abilityIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: NavigationTheme.abilitiesColor));
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
                    AbilityListViewText.errorTitle,
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
                AbilityListViewText.emptyDetailsMessage,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        // Group abilities by action category
        final grouped = <ActionCategory, List<Component>>{};
        for (final category in ActionCategory.values) {
          grouped[category] = [];
        }
        
        for (final ability in abilities) {
          final category = _categorizeAbility(ability);
          grouped[category]!.add(ability);
        }
        
        // Sort each category by cost (resource_value)
        for (final category in ActionCategory.values) {
          grouped[category]!.sort((a, b) {
            final costA = (a.data['resource_value'] as num?)?.toInt() ?? 0;
            final costB = (b.data['resource_value'] as num?)?.toInt() ?? 0;
            return costA.compareTo(costB);
          });
        }

        return AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Column(
              children: [
                // Custom styled tab bar - compact horizontal
                Container(
                  color: NavigationTheme.navBarBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: List.generate(ActionCategory.values.length, (index) {
                      final category = ActionCategory.values[index];
                      final isSelected = _tabController.index == index;
                      final color = isSelected ? category.color : NavigationTheme.inactiveColor;
                      final count = grouped[category]!.length;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(index),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: isSelected
                                ? NavigationTheme.selectedNavItemDecoration(category.color)
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
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                      for (final category in ActionCategory.values)
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
  
  Widget _buildCategoryList(List<Component> abilities, ActionCategory category) {
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
                Icon(category.icon, size: 48, color: category.color.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  '${AbilityListViewText.emptyCategoryPrefix}${category.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AbilityListViewText.emptyCategorySubtitle,
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
          return _buildAbilityWithRemove(abilities[index]);
        },
      ),
    );
  }

  Widget _buildAbilityWithRemove(Component ability) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          AbilityExpandableItem(component: ability),
          Positioned(
            top: 18,
            right: 18,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeAbility(ability.id),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
              tooltip: AbilityListViewText.removeTooltip,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAbility(String abilityId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AbilityListViewText.removeDialogTitle),
        content: const Text(AbilityListViewText.removeDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AbilityListViewText.removeDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AbilityListViewText.removeDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final entries = HeroEntryRepository(db);
      
      // Remove the ability entry from hero_entries
      // Only remove if it was manually added (sourceType='manual_choice')
      // First get the entries to find the one matching our criteria
      final existingEntries = await entries.listEntriesByType(widget.heroId, 'ability');
      final toRemove = existingEntries.where(
        (e) => e.entryId == abilityId && e.sourceType == 'manual_choice',
      ).toList();
      
      for (final entry in toRemove) {
        await db.customStatement(
          'DELETE FROM hero_entries WHERE id = ?',
          [entry.id],
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AbilityListViewText.snackAbilityRemoved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AbilityListViewText.snackRemoveFailedPrefix}$e',
            ),
          ),
        );
      }
    }
  }

  Future<List<Component>> _loadAbilityComponents(
    List<String> abilityIds,
  ) async {
    final library = await AbilityDataService().loadLibrary();
    final components = <Component>[];
    final missingIds = <String>[];

    for (final id in abilityIds) {
      try {
        final component = library.byId(id) ?? library.find(id);
        if (component != null) {
          components.add(component);
        } else {
          missingIds.add(id);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to resolve ability $id: $e');
        }
        missingIds.add(id);
      }
    }

    // Check the database for any abilities not found in the library
    // (e.g., perk-granted abilities that were dynamically inserted)
    if (missingIds.isNotEmpty) {
      final db = ref.read(appDatabaseProvider);
      for (final id in missingIds) {
        try {
          final row = await db.getComponentById(id);
          if (row != null && row.type == 'ability') {
            Map<String, dynamic> data = {};
            if (row.dataJson.isNotEmpty) {
              data = jsonDecode(row.dataJson) as Map<String, dynamic>;
            }
            components.add(Component(
              id: row.id,
              type: row.type,
              name: row.name,
              data: data,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to load ability $id from database: $e');
          }
        }
      }
    }

    return components;
  }}
