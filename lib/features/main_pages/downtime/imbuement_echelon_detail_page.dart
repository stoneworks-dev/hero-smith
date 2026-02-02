import 'package:flutter/material.dart';
import '../../../core/models/downtime.dart';
import '../../../core/data/downtime_data_source.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/expandable_card.dart';

class ImbuementEchelonDetailPage extends StatelessWidget {
  final int echelonLevel;
  final Map<String, List<DowntimeEntry>> imbuementsByType;
  final DowntimeDataSource dataSource;

  const ImbuementEchelonDetailPage({
    super.key,
    required this.echelonLevel,
    required this.imbuementsByType,
    required this.dataSource,
  });

  Color _getEchelonColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 9:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedTypes = imbuementsByType.keys.toList()..sort();
    final totalCount = imbuementsByType.values.fold(0, (sum, list) => sum + list.length);
    final color = _getEchelonColor(echelonLevel);

    return DefaultTabController(
      length: sortedTypes.length,
      child: Scaffold(
        backgroundColor: NavigationTheme.navBarBackground,
        appBar: AppBar(
          title: Text(dataSource.getLevelName(echelonLevel)),
          backgroundColor: NavigationTheme.navBarBackground,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: NavigationTheme.navBarBackground,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: sortedTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  final typeColor = _getTypeColor(type);
                  
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: isSelected
                                    ? NavigationTheme.selectedNavItemDecoration(typeColor)
                                    : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTypeIcon(type),
                                      color: displayColor,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getShortTypeName(type),
                                      style: TextStyle(
                                        color: displayColor,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              // Header card with new style
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
                                Icons.auto_fix_high,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$totalCount imbuements across ${imbuementsByType.length} categories',
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: sortedTypes.map((type) {
                    final imbuements = imbuementsByType[type]!;
                    return _ImbuementTypeTab(
                      type: type,
                      imbuements: imbuements,
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'armor_imbuement':
        return Icons.shield;
      case 'weapon_imbuement':
        return Icons.gavel;
      case 'implement_imbuement':
        return Icons.auto_fix_high;
      default:
        return Icons.build;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'armor_imbuement':
        return NavigationTheme.armorColor;
      case 'weapon_imbuement':
        return NavigationTheme.weaponColor;
      case 'implement_imbuement':
        return NavigationTheme.implementColor;
      default:
        return Colors.grey;
    }
  }

  String _getShortTypeName(String type) {
    switch (type) {
      case 'armor_imbuement':
        return 'Armor';
      case 'weapon_imbuement':
        return 'Weapon';
      case 'implement_imbuement':
        return 'Implement';
      default:
        return type.replaceAll('_imbuement', '').toUpperCase();
    }
  }
}

class _ImbuementTypeTab extends StatelessWidget {
  final String type;
  final List<DowntimeEntry> imbuements;
  final DowntimeDataSource dataSource;

  const _ImbuementTypeTab({
    required this.type,
    required this.imbuements,
    required this.dataSource,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'armor_imbuement':
        return Colors.indigo; // Blue
      case 'weapon_imbuement':
        return Colors.deepOrange; // Reddish
      case 'implement_imbuement':
        return Colors.teal; // Greenish
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: imbuements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final imbuement = imbuements[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _getTypeColor(type).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ExpandableCard(
              title: imbuement.name.replaceAll(
                  ' - ${dataSource.getLevelName((imbuement.raw['level'] as int? ?? 1))}-Level ${dataSource.getImbuementTypeName(imbuement.type).replaceAll('s', '')}',
                  ''),
              borderColor: _getTypeColor(type),
              expandedContent: _EntryDetails(entry: imbuement),
            ),
          );
        },
      ),
    );
  }
}

class _EntryDetails extends StatelessWidget {
  final DowntimeEntry entry;
  const _EntryDetails({required this.entry});

  @override
  Widget build(BuildContext context) {
    final desc = (entry.raw['description'] ?? '').toString();
    final imbuement = entry.raw['imbuement']?.toString() ?? '';
    final cost = entry.raw['cost']?.toString() ?? '';
    final projectGoal = entry.raw['project_goal'];
    final prerequisites = entry.raw['prerequisites'] as Map<String, dynamic>?;
    final rollCharacteristics = entry.raw['project_roll_characteristic'] as List<dynamic>?;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc.isNotEmpty) ...[
            Text(
              desc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
          ],
          
          if (imbuement.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imbuement Effect',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    imbuement,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Project details section
          if (projectGoal != null || rollCharacteristics != null || cost.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (projectGoal != null)
                        _InfoChip(
                          icon: Icons.flag,
                          label: 'Goal',
                          value: '$projectGoal points',
                          color: _getProjectGoalColor(projectGoal),
                        ),
                      if (cost.isNotEmpty)
                        _InfoChip(
                          icon: Icons.monetization_on,
                          label: 'Cost',
                          value: cost,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  
                  if (rollCharacteristics != null && rollCharacteristics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Roll Characteristics:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: rollCharacteristics.map((char) {
                        final charName = char['name']?.toString() ?? '';
                        return _CharacteristicChip(characteristic: charName);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Prerequisites section
          if (prerequisites != null && prerequisites.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Prerequisites',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildPrerequisites(context, prerequisites),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPrerequisites(
      BuildContext context, Map<String, dynamic> prerequisites) {
    final widgets = <Widget>[];

    prerequisites.forEach((key, value) {
      // Get human-readable label for the prerequisite type
      final label = _getPrerequisiteLabel(key);
      
      if (value is List && value.isNotEmpty) {
        // Extract names from the list of prerequisite objects
        final names = <String>[];
        for (final item in value) {
          if (item is Map<String, dynamic> && item['name'] != null) {
            names.add(item['name'].toString());
          } else if (item is String) {
            names.add(item);
          }
        }
        
        if (names.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPrerequisiteIcon(key),
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: names.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $name',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getPrerequisiteIcon(key),
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: '$label: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TextSpan(text: value.toString()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  String _getPrerequisiteLabel(String key) {
    switch (key.toLowerCase()) {
      case 'item_prerequisite':
        return 'Required Items';
      case 'project_source':
        return 'Knowledge Source';
      case 'location':
        return 'Location Required';
      case 'skill':
        return 'Skill Required';
      case 'level':
        return 'Level Required';
      case 'class':
        return 'Class Required';
      case 'feature':
        return 'Feature Required';
      default:
        return key.replaceAll('_', ' ').split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  IconData _getPrerequisiteIcon(String key) {
    switch (key.toLowerCase()) {
      case 'item_prerequisite':
        return Icons.inventory_2;
      case 'project_source':
        return Icons.menu_book;
      case 'location':
        return Icons.place;
      case 'skill':
        return Icons.build;
      case 'level':
        return Icons.bar_chart;
      case 'class':
        return Icons.person;
      case 'feature':
        return Icons.star;
      default:
        return Icons.arrow_right;
    }
  }

  Color _getProjectGoalColor(dynamic projectGoal) {
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
    return Colors.grey;
  }
}

class _CharacteristicChip extends StatelessWidget {
  final String characteristic;

  const _CharacteristicChip({
    required this.characteristic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCharacteristicColor(characteristic).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCharacteristicColor(characteristic).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCharacteristicIcon(characteristic),
            size: 14,
            color: _getCharacteristicColor(characteristic),
          ),
          const SizedBox(width: 4),
          Text(
            characteristic,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getCharacteristicColor(characteristic),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Color _getCharacteristicColor(String characteristic) {
    switch (characteristic.toLowerCase()) {
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
      default:
        return Colors.grey;
    }
  }

  IconData _getCharacteristicIcon(String characteristic) {
    switch (characteristic.toLowerCase()) {
      case 'might':
        return Icons.fitness_center;
      case 'agility':
        return Icons.directions_run;
      case 'reason':
        return Icons.psychology;
      case 'intuition':
        return Icons.lightbulb_outline;
      case 'presence':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}