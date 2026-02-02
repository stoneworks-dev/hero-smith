import 'package:flutter/material.dart';
import '../../../core/models/downtime.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/expandable_card.dart';

class ProjectCategoryDetailPage extends StatelessWidget {
  final int category;
  final List<DowntimeEntry> projects;
  final Color Function(DowntimeEntry) getProjectCardColor;
  final String Function(int) getDifficultyTitle;

  const ProjectCategoryDetailPage({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    
    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        title: Text(getDifficultyTitle(category)),
        backgroundColor: NavigationTheme.navBarBackground,
        elevation: 0,
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
                              Icons.info_outline,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${projects.length} projects in this category',
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
              child: ListView.separated(
                itemCount: projects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ExpandableCard(
                    title: project.name,
                    borderColor: getProjectCardColor(project),
                    expandedContent: _EntryDetails(entry: project),
                  );
                },
              ),
            ),
          ],
        ),
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
    final projectGoal = entry.raw['project_goal'];
    final prerequisites = entry.raw['prerequisites'] as Map<String, dynamic>?;
    final rollCharacteristics =
        entry.raw['project_roll_characteristic'] as List<dynamic>?;

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
            const SizedBox(height: 16),
          ],
          
          // Project details section
          if (projectGoal != null || rollCharacteristics != null) ...[
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
                  
                  if (projectGoal != null) ...[
                    _InfoChip(
                      icon: Icons.flag,
                      label: 'Goal',
                      value: '$projectGoal points',
                      color: _getProjectGoalColor(projectGoal),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  if (rollCharacteristics != null && rollCharacteristics.isNotEmpty) ...[
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
            const SizedBox(height: 16),
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