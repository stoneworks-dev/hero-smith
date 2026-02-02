import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/models/downtime.dart';
import '../../core/data/downtime_data_source.dart';
import '../../features/main_pages/downtime/project_category_detail_page.dart';
import '../../features/main_pages/downtime/imbuement_echelon_detail_page.dart';
import '../../features/main_pages/downtime/craftable_treasure_type_detail_page.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  final _ds = DowntimeDataSource();

  Color _getProjectCardColor(DowntimeEntry entry) {
    final projectGoal = entry.raw['project_goal'];
    final rollCharacteristics =
        entry.raw['project_roll_characteristic'] as List<dynamic>?;

    // Color based on project complexity and characteristics
    if (projectGoal != null) {
      final goal = int.tryParse(projectGoal.toString()) ?? 0;
      if (goal >= 1000) {
        return Colors.deepPurple; // Epic projects (1000+)
      } else if (goal >= 201) {
        return Colors.indigo; // Major projects (201-999)
      } else if (goal >= 21) {
        return Colors.blue; // Medium projects (21-200)
      } else if (goal > 0) {
        return Colors.teal; // Small projects (<30)
      }
    }

    // Color based on primary characteristic if no goal
    if (rollCharacteristics != null && rollCharacteristics.isNotEmpty) {
      final primaryChar =
          rollCharacteristics.first['name']?.toString().toLowerCase();
      switch (primaryChar) {
        case 'might':
          return Colors.red;
        case 'agility':
          return Colors.green;
        case 'reason':
          return Colors.blue;
        case 'intuition':
          return Colors.purple;
        case 'presence':
          return Colors.orange;
      }
    }

    // Default color for projects without clear categorization
    return Colors.blueGrey;
  }

  int _getProjectDifficultyCategory(DowntimeEntry entry) {
    final projectGoal = entry.raw['project_goal'];
    if (projectGoal != null) {
      final goal = int.tryParse(projectGoal.toString()) ?? 0;
      if (goal >= 1000) {
        return 4; // Epic (1000+)
      } else if (goal >= 201) {
        return 3; // Major (201-999)
      } else if (goal >= 21) {
        return 2; // Medium (21-200)
      } else if (goal > 0) {
        return 1; // Small (<30)
      }
    }
    return 0; // Unknown/no goal
  }

  String _getDifficultyTitle(int category) {
    switch (category) {
      case 4:
        return 'Epic Projects (1000+ points)';
      case 3:
        return 'Major Projects (201-999 points)';
      case 2:
        return 'Medium Projects (21-200 points)';
      case 1:
        return 'Small Projects (<30 points)';
      default:
        return 'Other Projects';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DowntimeEntry>>(
      future: _ds.loadProjects(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.projects,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downtime projects found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group projects by difficulty categories
        final groupedProjects = <int, List<DowntimeEntry>>{};
        for (final entry in items) {
          final category = _getProjectDifficultyCategory(entry);
          groupedProjects.putIfAbsent(category, () => <DowntimeEntry>[]);
          groupedProjects[category]!.add(entry);
        }

        // Sort categories in descending order (Epic -> Small -> Other)
        final sortedCategories = groupedProjects.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a project category:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: sortedCategories.map((category) {
                  final projectsInCategory = groupedProjects[category]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProjectCategoryCard(
                      category: category,
                      projects: projectsInCategory,
                      getProjectCardColor: _getProjectCardColor,
                      getDifficultyTitle: _getDifficultyTitle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectCategoryCard extends StatelessWidget {
  final int category;
  final List<DowntimeEntry> projects;
  final Color Function(DowntimeEntry) getProjectCardColor;
  final String Function(int) getDifficultyTitle;

  const _ProjectCategoryCard({
    required this.category,
    required this.projects,
    required this.getProjectCardColor,
    required this.getDifficultyTitle,
  });

  Color _getCategoryColor(int category) {
    switch (category) {
      case 4:
        return Colors.deepPurple; // Epic
      case 3:
        return Colors.indigo; // Major
      case 2:
        return Colors.blue; // Medium
      case 1:
        return Colors.teal; // Small
      default:
        return Colors.blueGrey; // Other
    }
  }

  String _getCategoryDescription(int category) {
    switch (category) {
      case 4:
        return 'Legendary endeavors requiring massive commitment and resources';
      case 3:
        return 'Significant undertakings for experienced adventurers';
      case 2:
        return 'Moderate projects suitable for most heroes';
      case 1:
        return 'Quick projects that can be completed efficiently';
      default:
        return 'Miscellaneous projects with unique requirements';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProjectCategoryDetailPage(
                category: category,
                projects: projects,
                getProjectCardColor: getProjectCardColor,
                getDifficultyTitle: getDifficultyTitle,
              ),
            ),
          );
        },
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? NavigationTheme.cardBackgroundDark
                : Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                height: 90,
                decoration: BoxDecoration(
                  gradient: NavigationTheme.accentStripeGradient(color),
                ),
              ),
              const SizedBox(width: 14),
              // Icon container
              Container(
                width: NavigationTheme.cardIconContainerSize,
                height: NavigationTheme.cardIconContainerSize,
                decoration: NavigationTheme.cardIconDecoration(color, isDark: isDark),
                child: Icon(
                  _getCategoryIcon(category),
                  color: color,
                  size: NavigationTheme.cardIconSize,
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getDifficultyTitle(category),
                        style: NavigationTheme.cardTitleStyle(color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getCategoryDescription(category),
                        style: NavigationTheme.cardSubtitleStyle(
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${projects.length} projects available',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: NavigationTheme.cardIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(int category) {
    switch (category) {
      case 4:
        return Icons.stars; // Epic
      case 3:
        return Icons.assignment_ind; // Major
      case 2:
        return Icons.assignment; // Medium
      case 1:
        return Icons.assignment_outlined; // Small
      default:
        return Icons.help_outline; // Other
    }
  }
}



class ImbuementsTab extends StatefulWidget {
  const ImbuementsTab({super.key});

  @override
  State<ImbuementsTab> createState() => _ImbuementsTabState();
}

class _ImbuementsTabState extends State<ImbuementsTab> {
  final _ds = DowntimeDataSource();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, Map<String, List<DowntimeEntry>>>>(
      future: _ds.loadImbuementsByLevelAndType(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final imbuementsByEchelon =
            snap.data ?? <int, Map<String, List<DowntimeEntry>>>{};
        if (imbuementsByEchelon.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.imbuements,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No item imbuements found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final sortedEchelons = imbuementsByEchelon.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Imbuements by Echelon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an echelon level to view available item imbuements',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ...sortedEchelons.map((echelonLevel) {
                final imbuementsByType = imbuementsByEchelon[echelonLevel]!;
                return _EchelonNavigationCard(
                  echelonLevel: echelonLevel,
                  imbuementsByType: imbuementsByType,
                  dataSource: _ds,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _EchelonNavigationCard extends StatelessWidget {
  final int echelonLevel;
  final Map<String, List<DowntimeEntry>> imbuementsByType;
  final DowntimeDataSource dataSource;

  const _EchelonNavigationCard({
    required this.echelonLevel,
    required this.imbuementsByType,
    required this.dataSource,
  });

  Color _getEchelonColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.blue; // Changed from red to blue as requested
      case 9:
        return Colors.purple; // Added purple for level 9
      default:
        return Colors.grey;
    }
  }

  String _getEchelonDescription(int level) {
    switch (level) {
      case 1:
        return 'Basic imbuements for starting adventurers';
      case 2:
        return 'Improved imbuements for developing heroes';
      case 3:
        return 'Advanced imbuements for experienced adventurers';
      case 4:
        return 'Superior imbuements for veteran heroes';
      case 5:
        return 'Legendary imbuements for master adventurers';
      case 9:
        return 'Mythical imbuements of extraordinary power';
      default:
        return 'Specialized item imbuements';
    }
  }

  IconData _getEchelonIcon(int level) {
    switch (level) {
      case 1:
        return Icons.star_half;
      case 2:
        return Icons.auto_fix_high;
      case 3:
        return Icons.auto_awesome;
      case 4:
        return Icons.stars;
      case 5:
        return Icons.diamond;
      case 9:
        return Icons.flare;
      default:
        return Icons.auto_fix_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = imbuementsByType.values.fold(0, (sum, list) => sum + list.length);
    final typeCount = imbuementsByType.length;
    final color = _getEchelonColor(echelonLevel);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImbuementEchelonDetailPage(
                echelonLevel: echelonLevel,
                imbuementsByType: imbuementsByType,
                dataSource: dataSource,
              ),
            ),
          );
        },
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? NavigationTheme.cardBackgroundDark
                : Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                height: 90,
                decoration: BoxDecoration(
                  gradient: NavigationTheme.accentStripeGradient(color),
                ),
              ),
              const SizedBox(width: 14),
              // Icon container
              Container(
                width: NavigationTheme.cardIconContainerSize,
                height: NavigationTheme.cardIconContainerSize,
                decoration: NavigationTheme.cardIconDecoration(color, isDark: isDark),
                child: Icon(
                  _getEchelonIcon(echelonLevel),
                  color: color,
                  size: NavigationTheme.cardIconSize,
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dataSource.getLevelName(echelonLevel),
                        style: NavigationTheme.cardTitleStyle(color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getEchelonDescription(echelonLevel),
                        style: NavigationTheme.cardSubtitleStyle(
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 12,
                            color: color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCount imbuements',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.category,
                            size: 12,
                            color: color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$typeCount types',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: NavigationTheme.cardIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== Treasures Tab ==========

class TreasuresTab extends StatefulWidget {
  const TreasuresTab({super.key});

  @override
  State<TreasuresTab> createState() => _TreasuresTabState();
}

class _TreasuresTabState extends State<TreasuresTab> {
  final _ds = DowntimeDataSource();

  Color _getTreasureTypeColor(String type) {
    switch (type) {
      case 'consumable':
        return Colors.teal;
      case 'trinket':
        return Colors.amber.shade700;
      case 'leveled_treasure':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getTreasureTypeIcon(String type) {
    switch (type) {
      case 'consumable':
        return Icons.local_drink;
      case 'trinket':
        return Icons.auto_awesome;
      case 'leveled_treasure':
        return Icons.shield;
      default:
        return Icons.diamond;
    }
  }

  String _getTreasureTypeDescription(String type) {
    switch (type) {
      case 'consumable':
        return 'Single-use items like potions, scrolls, and oils';
      case 'trinket':
        return 'Reusable magical items and accessories';
      case 'leveled_treasure':
        return 'Powerful equipment that grows with your hero';
      default:
        return 'Craftable treasure items';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<CraftableTreasure>>>(
      future: _ds.loadCraftableTreasuresByType(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final treasuresByType = snap.data ?? <String, List<CraftableTreasure>>{};
        if (treasuresByType.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.treasures,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No craftable treasures found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        // Order types: consumable, trinket, leveled_treasure
        final typeOrder = ['consumable', 'trinket', 'leveled_treasure'];
        final sortedTypes = treasuresByType.keys.toList()
          ..sort((a, b) {
            final indexA = typeOrder.indexOf(a);
            final indexB = typeOrder.indexOf(b);
            if (indexA == -1 && indexB == -1) return a.compareTo(b);
            if (indexA == -1) return 1;
            if (indexB == -1) return -1;
            return indexA.compareTo(indexB);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Craftable Treasures',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a treasure type to browse craftable items',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ...sortedTypes.map((type) {
                final treasures = treasuresByType[type]!;
                return _TreasureTypeCard(
                  type: type,
                  treasures: treasures,
                  color: _getTreasureTypeColor(type),
                  icon: _getTreasureTypeIcon(type),
                  description: _getTreasureTypeDescription(type),
                  dataSource: _ds,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _TreasureTypeCard extends StatelessWidget {
  final String type;
  final List<CraftableTreasure> treasures;
  final Color color;
  final IconData icon;
  final String description;
  final DowntimeDataSource dataSource;

  const _TreasureTypeCard({
    required this.type,
    required this.treasures,
    required this.color,
    required this.icon,
    required this.description,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    // Count by echelon for non-leveled, by equipment type for leveled
    final bool isLeveled = type == 'leveled_treasure';
    final Map<String, int> subcategoryCounts = {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isLeveled) {
      for (final t in treasures) {
        final equipType = t.leveledType ?? 'other';
        subcategoryCounts[equipType] = (subcategoryCounts[equipType] ?? 0) + 1;
      }
    } else {
      for (final t in treasures) {
        final echelon = t.echelon ?? 0;
        final key = dataSource.getEchelonName(echelon);
        subcategoryCounts[key] = (subcategoryCounts[key] ?? 0) + 1;
      }
    }

    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CraftableTreasureTypeDetailPage(
                type: type,
                treasures: treasures,
                color: color,
                dataSource: dataSource,
              ),
            ),
          );
        },
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? NavigationTheme.cardBackgroundDark
                : Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                height: 90,
                decoration: BoxDecoration(
                  gradient: NavigationTheme.accentStripeGradient(color),
                ),
              ),
              const SizedBox(width: 14),
              // Icon container
              Container(
                width: NavigationTheme.cardIconContainerSize,
                height: NavigationTheme.cardIconContainerSize,
                decoration: NavigationTheme.cardIconDecoration(color, isDark: isDark),
                child: Icon(
                  icon,
                  color: color,
                  size: NavigationTheme.cardIconSize,
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dataSource.getTreasureTypeName(type),
                        style: NavigationTheme.cardTitleStyle(color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: NavigationTheme.cardSubtitleStyle(
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 12,
                            color: color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${treasures.length} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isLeveled ? Icons.category : Icons.layers,
                            size: 12,
                            color: color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLeveled 
                                ? '${subcategoryCounts.length} equipment types'
                                : '${subcategoryCounts.length} echelons',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: NavigationTheme.cardIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DowntimeTabsScaffold extends StatefulWidget {
  const DowntimeTabsScaffold({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DowntimeTabsScaffold> createState() => _DowntimeTabsScaffoldState();
}

class _DowntimeTabsScaffoldState extends State<DowntimeTabsScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabData = [
    (icon: AppIcons.projects, label: 'Projects', color: NavigationTheme.projectsTabColor),
    (icon: AppIcons.imbuements, label: 'Imbuements', color: NavigationTheme.imbuementsTabColor),
    (icon: AppIcons.treasures, label: 'Treasures', color: NavigationTheme.treasuresTabColor),
    (icon: Icons.event_note, label: 'Events', color: NavigationTheme.eventsTabColor),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabData.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
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
    return Column(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          color: color,
                          size: NavigationTheme.tabIconSize,
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
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ProjectsTab(),
              ImbuementsTab(),
              TreasuresTab(),
              EventsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final _ds = DowntimeDataSource();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventTable>>(
      future: _ds.loadEventTables(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final eventTables = snap.data ?? const [];
        if (eventTables.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No event tables found'),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First section: Suggested Milestones
              _SuggestedMilestonesCard(),
              const SizedBox(height: 24),

              // Second section: Event Tables
              Text(
                'Event Tables',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _EventTablesGrid(eventTables: eventTables),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestedMilestonesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_available, color: cs.primary),
                const SizedBox(width: 8),
                Text('Suggested Event Milestones',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            const _MilestoneRow(
              color: Colors.teal,
              range: '30 or fewer points',
              suggestion: 'None',
            ),
            const _MilestoneRow(
              color: Colors.blue,
              range: '31–200 points',
              suggestion: 'One at halfway',
            ),
            const _MilestoneRow(
              color: Colors.indigo,
              range: '201–999 points',
              suggestion: 'Two at 1/3 and 2/3',
            ),
            const _MilestoneRow(
              color: Colors.deepPurple,
              range: '1,000+ points',
              suggestion: 'Three at 1/4, 1/2, 3/4',
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Color color;
  final String range;
  final String suggestion;

  const _MilestoneRow({
    required this.color,
    required this.range,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(range,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EventTablesGrid extends StatelessWidget {
  final List<EventTable> eventTables;

  const _EventTablesGrid({required this.eventTables});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: eventTables.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final table = eventTables[index];
        return _EventTableCard(table: table);
      },
    );
  }
}

class _EventTableCard extends StatelessWidget {
  final EventTable table;

  const _EventTableCard({required this.table});

  // Assign colors based on table name for visual variety
  Color _getTableColor() {
    final name = table.name.toLowerCase();
    if (name.contains('craft') || name.contains('research')) return NavigationTheme.treasuresTabColor;
    if (name.contains('career') || name.contains('hone')) return NavigationTheme.careersColor;
    if (name.contains('master') || name.contains('learn')) return NavigationTheme.featuresColor;
    if (name.contains('community') || name.contains('service')) return NavigationTheme.ancestriesColor;
    if (name.contains('fish')) return NavigationTheme.culturesColor;
    if (name.contains('loved') || name.contains('spend')) return NavigationTheme.complicationsColor;
    if (name.contains('negotiate')) return NavigationTheme.titlesColor;
    if (name.contains('quests')) return NavigationTheme.abilitiesColor;
    if (name.contains('relax')) return NavigationTheme.perksColor;
    if (name.contains('train')) return NavigationTheme.conditionsColor;
    // Fallback: use hash of name for consistent but varied colors
    final hash = name.hashCode.abs();
    final colors = [
      NavigationTheme.eventsTabColor,
      NavigationTheme.projectsTabColor,
      NavigationTheme.imbuementsTabColor,
      NavigationTheme.kitsColor,
      NavigationTheme.skillsColor,
      NavigationTheme.languagesColor,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTableColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToEventTable(context),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? NavigationTheme.cardBackgroundDark
                : Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                height: 76,
                decoration: BoxDecoration(
                  gradient: NavigationTheme.accentStripeGradient(color),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Icon container
              Container(
                width: NavigationTheme.cardIconContainerSize,
                height: NavigationTheme.cardIconContainerSize,
                decoration: NavigationTheme.cardIconDecoration(color, isDark: isDark),
                child: Icon(
                  Icons.table_chart_outlined,
                  color: color,
                  size: NavigationTheme.cardIconSize,
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        table.name.replaceAll(' Events', ''),
                        style: NavigationTheme.cardTitleStyle(color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${table.events.length} events available',
                        style: NavigationTheme.cardSubtitleStyle(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: NavigationTheme.cardIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEventTable(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EventTableDetailPage(table: table),
      ),
    );
  }
}

/// Standalone scaffold for the Events page, navigable without bottom nav
/// Used when navigating from hero downtime tracking
class EventsPageScaffold extends StatelessWidget {
  const EventsPageScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downtime Events'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: const EventsTab(),
    );
  }
}

class _EventTableDetailPage extends StatelessWidget {
  final EventTable table;

  const _EventTableDetailPage({required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        title: Text(table.name),
        backgroundColor: NavigationTheme.navBarBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Table header card with new style
          Container(
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent stripe
                Container(
                  width: NavigationTheme.cardAccentStripeWidth,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NavigationTheme.eventsTabColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                      bottomLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: NavigationTheme.eventsTabColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.table_chart,
                            color: NavigationTheme.eventsTabColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                table.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${table.events.length} events available',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Events as expandable cards with RPG tier color progression
          ...table.events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final totalEvents = table.events.length;
            
            return _EventCard(
              diceValue: event.diceValue,
              description: event.description,
              accentColor: NavigationTheme.getTierColorByIndex(index, totalEvents),
            );
          }),
        ],
      ),
    );
  }
}

/// Styled event card with expand/collapse
class _EventCard extends StatefulWidget {
  final String diceValue;
  final String description;
  final Color accentColor;

  const _EventCard({
    required this.diceValue,
    required this.description,
    required this.accentColor,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - simplified with just Roll X and colored accent
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Left color indicator
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Roll label only (no redundant dice value)
                    Expanded(
                      child: Text(
                        'Roll ${widget.diceValue}',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Expand icon
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.expand_more,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top border for content
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Description
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
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
