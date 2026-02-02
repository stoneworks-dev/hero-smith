import 'package:flutter/material.dart';
import '../../../core/data/downtime_data_source.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/expandable_card.dart';

/// Detail page for a specific type of craftable treasure (consumable, trinket, or leveled)
class CraftableTreasureTypeDetailPage extends StatelessWidget {
  final String type;
  final List<CraftableTreasure> treasures;
  final Color color;
  final DowntimeDataSource dataSource;

  const CraftableTreasureTypeDetailPage({
    super.key,
    required this.type,
    required this.treasures,
    required this.color,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'leveled_treasure') {
      return _LeveledTreasureDetailPage(
        treasures: treasures,
        color: color,
        dataSource: dataSource,
      );
    }

    // For consumables and trinkets, group by echelon
    final byEchelon = <int, List<CraftableTreasure>>{};
    for (final treasure in treasures) {
      final echelon = treasure.echelon ?? 0;
      byEchelon.putIfAbsent(echelon, () => <CraftableTreasure>[]);
      byEchelon[echelon]!.add(treasure);
    }

    final sortedEchelons = byEchelon.keys.toList()..sort();

    // Echelon colors for tabs
    Color getEchelonColor(int echelon) {
      switch (echelon) {
        case 1: return NavigationTheme.echelon1Color;
        case 2: return NavigationTheme.echelon2Color;
        case 3: return NavigationTheme.echelon3Color;
        case 4: return NavigationTheme.echelon4Color;
        default: return color;
      }
    }

    return DefaultTabController(
      length: sortedEchelons.length,
      child: Scaffold(
        backgroundColor: NavigationTheme.navBarBackground,
        appBar: AppBar(
          title: Text(dataSource.getTreasureTypeName(type)),
          backgroundColor: NavigationTheme.navBarBackground,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: NavigationTheme.navBarBackground,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: sortedEchelons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final echelon = entry.value;
                  final echelonColor = getEchelonColor(echelon);
                  final count = byEchelon[echelon]!.length;
                  
                  return Expanded(
                    child: Builder(
                      builder: (context) {
                        final tabController = DefaultTabController.of(context);
                        return AnimatedBuilder(
                          animation: tabController,
                          builder: (context, _) {
                            final isSelected = tabController.index == index;
                            final displayColor = isSelected ? echelonColor : NavigationTheme.inactiveColor;
                            
                            return GestureDetector(
                              onTap: () => tabController.animateTo(index),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: isSelected
                                    ? NavigationTheme.selectedNavItemDecoration(echelonColor)
                                    : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dataSource.getEchelonName(echelon),
                                      style: TextStyle(
                                        color: displayColor,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '($count)',
                                      style: TextStyle(
                                        color: displayColor.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHeader(
                type: type,
                totalCount: treasures.length,
                echelonCount: sortedEchelons.length,
                color: color,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: sortedEchelons.map((echelon) {
                    return _TreasureListTab(
                      treasures: byEchelon[echelon]!,
                      color: color,
                      dataSource: dataSource,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail page specifically for leveled treasures, grouped by equipment type
class _LeveledTreasureDetailPage extends StatelessWidget {
  final List<CraftableTreasure> treasures;
  final Color color;
  final DowntimeDataSource dataSource;

  const _LeveledTreasureDetailPage({
    required this.treasures,
    required this.color,
    required this.dataSource,
  });

  IconData _getEquipmentTypeIcon(String equipType) {
    switch (equipType) {
      case 'armor':
        return Icons.security;
      case 'weapon':
        return Icons.gavel;
      case 'implement':
        return Icons.auto_fix_high;
      case 'shield':
        return Icons.shield;
      default:
        return Icons.diamond;
    }
  }

  String _getEquipmentTypeName(String equipType) {
    switch (equipType) {
      case 'armor':
        return 'Armor';
      case 'weapon':
        return 'Weapons';
      case 'implement':
        return 'Implements';
      case 'shield':
        return 'Shields';
      default:
        return equipType
            .split('_')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
            .join(' ');
    }
  }

  Color _getEquipmentTypeColor(String equipType) {
    switch (equipType) {
      case 'armor':
        return NavigationTheme.armorColor;
      case 'weapon':
        return NavigationTheme.weaponColor;
      case 'implement':
        return NavigationTheme.implementColor;
      case 'shield':
        return NavigationTheme.shieldColor;
      default:
        return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by equipment type
    final byEquipType = <String, List<CraftableTreasure>>{};
    for (final treasure in treasures) {
      final equipType = treasure.leveledType ?? 'other';
      byEquipType.putIfAbsent(equipType, () => <CraftableTreasure>[]);
      byEquipType[equipType]!.add(treasure);
    }

    final typeOrder = ['armor', 'shield', 'weapon', 'implement', 'other'];
    final sortedTypes = byEquipType.keys.toList()
      ..sort((a, b) {
        final indexA = typeOrder.indexOf(a);
        final indexB = typeOrder.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return DefaultTabController(
      length: sortedTypes.length,
      child: Scaffold(
        backgroundColor: NavigationTheme.navBarBackground,
        appBar: AppBar(
          title: const Text('Leveled Treasures'),
          backgroundColor: NavigationTheme.navBarBackground,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: NavigationTheme.navBarBackground,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: sortedTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final equipType = entry.value;
                  final typeColor = _getEquipmentTypeColor(equipType);
                  final count = byEquipType[equipType]!.length;
                  
                  return Expanded(
                    child: Builder(
                      builder: (context) {
                        final tabController = DefaultTabController.of(context);
                        return AnimatedBuilder(
                          animation: tabController,
                          builder: (context, _) {
                            final isSelected = tabController.index == index;
                            final displayColor = isSelected ? typeColor : NavigationTheme.inactiveColor;
                            
                            return GestureDetector(
                              onTap: () => tabController.animateTo(index),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: isSelected
                                    ? NavigationTheme.selectedNavItemDecoration(typeColor)
                                    : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getEquipmentTypeIcon(equipType),
                                      color: displayColor,
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getEquipmentTypeName(equipType),
                                      style: TextStyle(
                                        color: displayColor,
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '($count)',
                                      style: TextStyle(
                                        color: displayColor.withValues(alpha: 0.7),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHeader(
                type: 'leveled_treasure',
                totalCount: treasures.length,
                echelonCount: sortedTypes.length,
                color: color,
                isLeveled: true,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: sortedTypes.map((equipType) {
                    return _TreasureListTab(
                      treasures: byEquipType[equipType]!,
                      color: color,
                      dataSource: dataSource,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String type;
  final int totalCount;
  final int echelonCount;
  final Color color;
  final bool isLeveled;

  const _SummaryHeader({
    required this.type,
    required this.totalCount,
    required this.echelonCount,
    required this.color,
    this.isLeveled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 70,
            decoration: BoxDecoration(
              gradient: NavigationTheme.accentStripeGradient(color),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: NavigationTheme.cardIconDecoration(color),
                    child: Icon(
                      Icons.diamond,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$totalCount craftable items across $echelonCount ${isLeveled ? 'equipment types' : 'echelons'}',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureListTab extends StatelessWidget {
  final List<CraftableTreasure> treasures;
  final Color color;
  final DowntimeDataSource dataSource;

  const _TreasureListTab({
    required this.treasures,
    required this.color,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    // Sort treasures alphabetically by name
    final sortedTreasures = List<CraftableTreasure>.from(treasures)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: sortedTreasures.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final treasure = sortedTreasures[index];
          return _CraftableTreasureCard(
            treasure: treasure,
            color: color,
          );
        },
      ),
    );
  }
}

class _CraftableTreasureCard extends StatelessWidget {
  final CraftableTreasure treasure;
  final Color color;

  const _CraftableTreasureCard({
    required this.treasure,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ExpandableCard(
        title: treasure.name,
        borderColor: color,
        expandedContent: _TreasureDetails(treasure: treasure, color: color),
      ),
    );
  }
}

class _TreasureDetails extends StatelessWidget {
  final CraftableTreasure treasure;
  final Color color;

  const _TreasureDetails({
    required this.treasure,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keywords
          if (treasure.keywords.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: treasure.keywords.map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    keyword,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Description
          if (treasure.description.isNotEmpty) ...[
            Text(
              treasure.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Effect
          _buildEffect(context),

          // Level variants for leveled treasures
          if (treasure.raw['leveled'] == true) ...[
            _buildLevelVariants(context),
          ],

          // Crafting Info Section
          const Divider(height: 24),
          _CraftingInfoSection(treasure: treasure, color: color),
        ],
      ),
    );
  }

  Widget _buildEffect(BuildContext context) {
    final effect = treasure.raw['effect'] as Map<String, dynamic>?;
    if (effect == null) return const SizedBox.shrink();

    final effectDescription = effect['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'EFFECT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          effectDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLevelVariants(BuildContext context) {
    final theme = Theme.of(context);
    final levels = [
      {'level': 1, 'data': treasure.raw['level_1']},
      {'level': 5, 'data': treasure.raw['level_5']},
      {'level': 9, 'data': treasure.raw['level_9']},
    ];

    final availableLevels = levels.where((level) => level['data'] != null).toList();
    
    if (availableLevels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'LEVEL VARIANTS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...availableLevels.map((level) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLevelCard(
            context,
            level['level'] as int,
            level['data'] as Map<String, dynamic>,
          ),
        )),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    int level,
    Map<String, dynamic> levelData,
  ) {
    final theme = Theme.of(context);
    final effectDescription = levelData['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    final levelColor = _getLevelColor(level);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              'LEVEL $level',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Level content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              effectDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green.shade600;
      case 5:
        return Colors.blue.shade600;
      case 9:
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

class _CraftingInfoSection extends StatelessWidget {
  final CraftableTreasure treasure;
  final Color color;

  const _CraftingInfoSection({
    required this.treasure,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.construction, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              'CRAFTING PROJECT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Project Goal
        if (treasure.projectGoal != null) ...[
          _InfoRow(
            icon: Icons.flag,
            label: 'Project Goal',
            value: '${treasure.projectGoal} points',
            color: color,
          ),
          const SizedBox(height: 8),
        ],

        // Goal Description
        if (treasure.projectGoalDescription != null && 
            treasure.projectGoalDescription!.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.info_outline,
            label: 'Goal Note',
            value: treasure.projectGoalDescription!,
            color: color,
          ),
          const SizedBox(height: 8),
        ],

        // Roll Characteristics
        if (treasure.projectRollCharacteristics.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.casino,
            label: 'Roll Characteristics',
            value: treasure.projectRollCharacteristics.join(' or '),
            color: color,
          ),
          const SizedBox(height: 8),
        ],

        // Prerequisites
        if (treasure.itemPrerequisite != null && 
            treasure.itemPrerequisite!.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.checklist,
            label: 'Prerequisites',
            value: treasure.itemPrerequisite!,
            color: color,
          ),
          const SizedBox(height: 8),
        ],

        // Project Source
        if (treasure.projectSource != null && 
            treasure.projectSource!.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.menu_book,
            label: 'Source',
            value: treasure.projectSource!,
            color: color,
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
