import 'package:flutter/material.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/project_detail_card_text.dart';
import '../../../../widgets/downtime/downtime_tabs.dart';

/// Accent color for projects
const Color _projectsColor = NavigationTheme.projectsTabColor;

/// Card displaying project details with progress
class ProjectDetailCard extends StatefulWidget {
  const ProjectDetailCard({
    super.key,
    required this.project,
    required this.heroId,
    this.onTap,
    this.onAddPoints,
    this.onRoll,
    this.onDelete,
    this.onAddToGear,
    this.isTreasureProject = false,
    this.treasureData,
    this.isImbuementProject = false,
    this.imbuementData,
  });

  final HeroDowntimeProject project;
  final String heroId;
  final VoidCallback? onTap;
  final VoidCallback? onAddPoints;
  final VoidCallback? onRoll;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToGear;
  final bool isTreasureProject;
  final Map<String, dynamic>? treasureData;
  final bool isImbuementProject;
  final Map<String, dynamic>? imbuementData;

  @override
  State<ProjectDetailCard> createState() => _ProjectDetailCardState();
}

class _ProjectDetailCardState extends State<ProjectDetailCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.project.progress;
    final isCompleted = widget.project.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCompleted ? Colors.green.withAlpha(128) : Colors.grey.shade800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row - always visible
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.project.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    // Progress indicator in header
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : _projectsColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    ],
                    if (widget.onTap != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            color: Colors.grey.shade500),
                        onPressed: widget.onTap,
                        iconSize: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: ProjectDetailCardText.editTooltip,
                      ),
                    ],
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.grey.shade500),
                        onPressed: widget.onDelete,
                        iconSize: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: ProjectDetailCardText.removeTooltip,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (widget.project.description.isNotEmpty) ...[
                    Text(
                      widget.project.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Effect description from treasure data
                  if (widget.treasureData != null) ...[
                    _buildTreasureEffects(theme),
                  ],

                  // Effect description from imbuement data
                  if (widget.imbuementData != null) ...[
                    _buildImbuementEffects(theme),
                  ],

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : _projectsColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Points display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.project.currentPoints} / ${widget.project.projectGoal} points',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _projectsColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Event indicators
                  if (widget.project.events.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.project.events.map((event) {
                        final triggered = event.triggered;
                        return _EventChip(
                          event: event,
                          triggered: triggered,
                          theme: theme,
                        );
                      }).toList(),
                    ),
                    // Show event descriptions for triggered events
                    ...widget.project.events
                        .where((e) =>
                            e.triggered &&
                            e.eventDescription != null &&
                            e.eventDescription!.isNotEmpty)
                        .map((event) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withAlpha(80),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 16,
                                      color: Colors.amber.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Event at ${event.pointThreshold} pts',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: Colors.amber.shade400,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            event.eventDescription!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                  ],

                  // Notes section
                  if (widget.project.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withAlpha(80),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ProjectDetailCardText.notesLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.project.notes,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Roll characteristics
                  if (widget.project.rollCharacteristics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: widget.project.rollCharacteristics.map((char) {
                        return Chip(
                          label: Text(
                            char.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          backgroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade700),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                  ],

                  // Add Points and Roll buttons (show if not completed and goal not yet reached)
                  if (!isCompleted &&
                      widget.onAddPoints != null &&
                      widget.onAddToGear == null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onAddPoints,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                                ProjectDetailCardText.addPointsButtonLabel),
                            style: FilledButton.styleFrom(
                              backgroundColor: _projectsColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        if (widget.onRoll != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onRoll,
                              icon: const Icon(Icons.casino, size: 20),
                              label: const Text(
                                  ProjectDetailCardText.rollButtonLabel),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _projectsColor,
                                side: BorderSide(color: _projectsColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Add to Gear button for treasure projects that reached their goal
                  if (widget.isTreasureProject &&
                      widget.onAddToGear != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onAddToGear,
                        icon: const Icon(Icons.backpack, size: 20),
                        label: const Text(
                          ProjectDetailCardText.addCraftedItemToGearLabel,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],

                  // Add Imbuement to Gear button for imbuement projects that reached their goal
                  if (widget.isImbuementProject &&
                      widget.onAddToGear != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onAddToGear,
                        icon: const Icon(Icons.auto_fix_high, size: 20),
                        label: const Text(
                          ProjectDetailCardText.addImbuementToGearLabel,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          foregroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasureEffects(ThemeData theme) {
    final data = widget.treasureData!;
    final effect = data['effect'] as Map<String, dynamic>?;
    final effectDescription = effect?['effect_description'] as String?;
    final isLeveled = data['leveled'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Base effect
        if (effectDescription != null && effectDescription.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ProjectDetailCardText.treasureEffectLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.deepPurple.shade400,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  effectDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Level variants for leveled treasures
        if (isLeveled) ...[
          _buildLevelVariants(theme, data),
        ],
      ],
    );
  }

  Widget _buildImbuementEffects(ThemeData theme) {
    final data = widget.imbuementData!;
    final description = data['description'] as String?;
    final imbuementType = data['type'] as String?;
    final level = data['level'] as int?;

    // Get display name for imbuement type
    String typeDisplay = '';
    if (imbuementType != null) {
      switch (imbuementType) {
        case 'armor_imbuement':
          typeDisplay = ProjectDetailCardText.imbuementTypeArmorLabel;
          break;
        case 'weapon_imbuement':
          typeDisplay = ProjectDetailCardText.imbuementTypeWeaponLabel;
          break;
        case 'implement_imbuement':
          typeDisplay = ProjectDetailCardText.imbuementTypeImplementLabel;
          break;
        case 'shield_imbuement':
          typeDisplay = ProjectDetailCardText.imbuementTypeShieldLabel;
          break;
        default:
          typeDisplay = imbuementType.replaceAll('_', ' ');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imbuement type and level badge
        if (typeDisplay.isNotEmpty || level != null) ...[
          Row(
            children: [
              if (typeDisplay.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeDisplay.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.deepPurple.shade300,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              if (level != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(level).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LEVEL $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getLevelColor(level),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Description
        if (description != null && description.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ProjectDetailCardText.imbuementEffectLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.deepPurple.shade400,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildLevelVariants(ThemeData theme, Map<String, dynamic> data) {
    final levels = [
      {'level': 1, 'data': data['level_1']},
      {'level': 5, 'data': data['level_5']},
      {'level': 9, 'data': data['level_9']},
    ];

    final availableLevels =
        levels.where((level) => level['data'] != null).toList();

    if (availableLevels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ProjectDetailCardText.levelVariantsLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...availableLevels.map((level) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLevelCard(
                theme,
                level['level'] as int,
                level['data'] as Map<String, dynamic>,
              ),
            )),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildLevelCard(
    ThemeData theme,
    int level,
    Map<String, dynamic> levelData,
  ) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              'LEVEL $level',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              effectDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: Colors.grey.shade300,
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

/// Event chip that becomes tappable when triggered
class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.event,
    required this.triggered,
    required this.theme,
  });

  final ProjectEvent event;
  final bool triggered;
  final ThemeData theme;

  void _navigateToEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EventsPageScaffold(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Event at ${event.pointThreshold} pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: triggered ? Colors.amber.shade300 : Colors.grey.shade300,
            ),
          ),
          if (triggered) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: Colors.amber.shade400,
            ),
          ],
        ],
      ),
      backgroundColor: triggered
          ? Colors.amber.withAlpha(40)
          : Colors.grey.shade800,
      side: BorderSide(
        color: triggered
            ? Colors.amber.shade600
            : Colors.grey.shade700,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );

    if (triggered) {
      return InkWell(
        onTap: () => _navigateToEvents(context),
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: ProjectDetailCardText.eventChipTooltipTriggered,
          child: chip,
        ),
      );
    }

    return chip;
  }
}
