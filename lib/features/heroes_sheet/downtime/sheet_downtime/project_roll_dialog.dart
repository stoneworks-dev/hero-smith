import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../core/db/providers.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/repositories/hero_repository.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/project_roll_dialog_text.dart';
import '../../main_stats/hero_main_stats_providers.dart';
import 'followers_tab.dart';

/// Accent color for projects
const Color _projectsColor = NavigationTheme.projectsTabColor;

/// Dialog for rolling project points with characteristics, edges, banes, and followers
class ProjectRollDialog extends ConsumerStatefulWidget {
  const ProjectRollDialog({
    super.key,
    required this.heroId,
    required this.project,
  });

  final String heroId;
  final HeroDowntimeProject project;

  @override
  ConsumerState<ProjectRollDialog> createState() => _ProjectRollDialogState();
}

class _ProjectRollDialogState extends ConsumerState<ProjectRollDialog> {
  final Random _random = Random();
  
  // Hero roll state - now tracks individual rolls for breakthrough display
  final List<_RollResult> _heroRolls = []; // Each roll (initial + breakthroughs)
  bool _heroHasRolled = false;
  bool _canBreakthrough = false; // True if last roll was 19+
  int _edgeCount = 0;
  int _baneCount = 0;
  int _skillCount = 0; // Now can be more than 1 with breakthroughs
  String? _selectedCharacteristic;
  
  // Follower roll state
  final Map<String, _FollowerRollState> _followerRolls = {};
  
  // Cached stats
  HeroMainStats? _heroStats;

  /// Number of breakthrough rolls (0 = just initial roll)
  int get _breakthroughCount => _heroRolls.length > 0 ? _heroRolls.length - 1 : 0;
  
  /// Max edges allowed (2 base + 2 per breakthrough)
  int get _maxEdges => 2 + (_breakthroughCount * 2);
  
  /// Max banes allowed (2 base + 2 per breakthrough)
  int get _maxBanes => 2 + (_breakthroughCount * 2);
  
  /// Max skill uses allowed (1 base + 1 per breakthrough)
  int get _maxSkillUses => 1 + _breakthroughCount;
  
  /// Characteristic multiplier (1 base + 1 per breakthrough)
  int get _characteristicMultiplier => 1 + _breakthroughCount;

  @override
  void initState() {
    super.initState();
  }

  void _updateHeroStats() {
    final statsAsync = ref.watch(heroMainStatsProvider(widget.heroId));
    statsAsync.whenData((stats) {
      if (_heroStats != stats) {
        _heroStats = stats;
      }
    });
  }

  /// Roll 2d10 and return both dice values
  _RollResult _roll2d10() {
    final d1 = _random.nextInt(10) + 1;
    final d2 = _random.nextInt(10) + 1;
    return _RollResult(d1: d1, d2: d2);
  }

  /// Get the total of all hero rolls
  int get _heroRollTotal {
    return _heroRolls.fold(0, (sum, roll) => sum + roll.total);
  }

  void _rollForHero() {
    final roll = _roll2d10();
    setState(() {
      _heroRolls.clear();
      _heroRolls.add(roll);
      _heroHasRolled = true;
      _canBreakthrough = roll.total >= 19;
      // Reset modifiers on new roll
      _edgeCount = 0;
      _baneCount = 0;
      _skillCount = 0;
    });
  }

  void _rollBreakthrough() {
    if (!_canBreakthrough) return;
    final roll = _roll2d10();
    setState(() {
      _heroRolls.add(roll);
      _canBreakthrough = roll.total >= 19;
      // Note: existing edge/bane/skill counts remain, but max increases
    });
  }

  void _addEdge() {
    if (_edgeCount < _maxEdges) {
      setState(() {
        _edgeCount++;
      });
    }
  }

  void _removeEdge() {
    if (_edgeCount > 0) {
      setState(() {
        _edgeCount--;
      });
    }
  }

  void _addBane() {
    if (_baneCount < _maxBanes) {
      setState(() {
        _baneCount++;
      });
    }
  }

  void _removeBane() {
    if (_baneCount > 0) {
      setState(() {
        _baneCount--;
      });
    }
  }

  void _addSkill() {
    if (_skillCount < _maxSkillUses) {
      setState(() {
        _skillCount++;
      });
    }
  }

  void _removeSkill() {
    if (_skillCount > 0) {
      setState(() {
        _skillCount--;
      });
    }
  }

  int get _heroModifierTotal {
    int mod = 0;
    mod += _edgeCount * 2; // Each edge adds 2
    mod -= _baneCount * 2; // Each bane subtracts 2
    mod += _skillCount * 2; // Each skill use adds 2
    if (_selectedCharacteristic != null && _heroStats != null) {
      // Characteristic is multiplied by breakthrough count + 1
      mod += _getCharacteristicValue(_selectedCharacteristic!) * _characteristicMultiplier;
    }
    return mod;
  }

  int _getCharacteristicValue(String characteristic) {
    if (_heroStats == null) return 0;
    switch (characteristic.toLowerCase()) {
      case 'might':
        return _heroStats!.mightTotal;
      case 'agility':
        return _heroStats!.agilityTotal;
      case 'reason':
        return _heroStats!.reasonTotal;
      case 'intuition':
        return _heroStats!.intuitionTotal;
      case 'presence':
        return _heroStats!.presenceTotal;
      default:
        return 0;
    }
  }

  int get _heroFinalTotal {
    if (!_heroHasRolled) return 0;
    final total = _heroRollTotal + _heroModifierTotal;
    return total < 1 ? 1 : total; // Minimum of 1
  }

  int get _grandTotal {
    int total = _heroHasRolled ? _heroFinalTotal : 0;
    for (final followerRoll in _followerRolls.values) {
      if (followerRoll.hasRolled) {
        total += followerRoll.finalTotal;
      }
    }
    return total;
  }

  void _confirmAndAddPoints() {
    if (_grandTotal > 0) {
      Navigator.of(context).pop(_grandTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final followersAsync = ref.watch(heroFollowersProvider(widget.heroId));
    
    // Update hero stats from provider
    _updateHeroStats();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: NavigationTheme.navBarBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _projectsColor.withAlpha(60),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _projectsColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.casino, color: _projectsColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ProjectRollDialogText.dialogTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.project.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Roll Section
                    _buildHeroRollSection(context),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade800),
                    const SizedBox(height: 16),
                    
                    // Follower Contributions Section
                    _buildFollowerSection(context, followersAsync),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade800),
                    const SizedBox(height: 16),
                    
                    // Grand Total
                    _buildGrandTotalSection(context),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                        side: BorderSide(color: Colors.grey.shade700),
                      ),
                      child: const Text(ProjectRollDialogText.cancelButtonLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _grandTotal > 0 ? _confirmAndAddPoints : null,
                      icon: const Icon(Icons.add),
                      label: Text('Add $_grandTotal Points'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _projectsColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade700,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroRollSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _projectsColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person, color: _projectsColor, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  ProjectRollDialogText.heroSectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Roll button
            FilledButton.icon(
              onPressed: _rollForHero,
              icon: const Icon(Icons.casino),
              label: Text(
                _heroHasRolled
                    ? ProjectRollDialogText.heroRerollButtonLabel
                    : ProjectRollDialogText.heroRollButtonLabel,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _projectsColor,
                foregroundColor: Colors.white,
              ),
            ),
            
            // Display all rolls
            if (_heroHasRolled) ...[
              const SizedBox(height: 16),
              
              // Individual roll displays
              ..._heroRolls.asMap().entries.map((entry) {
                final index = entry.key;
                final roll = entry.value;
                final isBreakthrough = index > 0;
                final isBreakthroughRoll = roll.total >= 19;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBreakthroughRoll 
                          ? Colors.amber.withAlpha(50)
                          : Colors.grey.shade800.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                      border: isBreakthroughRoll 
                          ? Border.all(color: Colors.amber, width: 2)
                          : Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      children: [
                        if (isBreakthrough) ...[
                          Icon(Icons.bolt, size: 18, color: Colors.amber.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Breakthrough ${index}:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.casino, size: 18, color: _projectsColor),
                          const SizedBox(width: 6),
                          Text(
                            ProjectRollDialogText.heroInitialRollLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          '${roll.d1} + ${roll.d2} = ${roll.total}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isBreakthroughRoll ? Colors.amber.shade600 : Colors.white,
                          ),
                        ),
                        if (isBreakthroughRoll) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ProjectRollDialogText.heroBreakthroughBadgeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              
              // Breakthrough roll button (if last roll was 19+)
              if (_canBreakthrough) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _rollBreakthrough,
                    icon: const Icon(Icons.bolt),
                    label: const Text(
                      ProjectRollDialogText.heroBreakthroughButtonLabel,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Roll total with modifiers
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _projectsColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _projectsColor.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ProjectRollDialogText.heroRollTotalLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          '$_heroRollTotal',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_heroModifierTotal != 0) ...[
                          Text(
                            ' ${_heroModifierTotal >= 0 ? '+' : ''}$_heroModifierTotal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _heroModifierTotal >= 0 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        Text(
                          ' = $_heroFinalTotal',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _projectsColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Modifier buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Edge button
                  _ModifierButton(
                    label: ProjectRollDialogText.heroEdgeLabel,
                    count: _edgeCount,
                    maxCount: _maxEdges,
                    isPositive: true,
                    onAdd: _addEdge,
                    onRemove: _removeEdge,
                  ),
                  
                  // Bane button
                  _ModifierButton(
                    label: ProjectRollDialogText.heroBaneLabel,
                    count: _baneCount,
                    maxCount: _maxBanes,
                    isPositive: false,
                    onAdd: _addBane,
                    onRemove: _removeBane,
                  ),
                  
                  // Skill button (now a counter, not toggle)
                  _ModifierButton(
                    label: ProjectRollDialogText.heroSkillLabel,
                    count: _skillCount,
                    maxCount: _maxSkillUses,
                    isPositive: true,
                    onAdd: _addSkill,
                    onRemove: _removeSkill,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Characteristic dropdown
              _buildCharacteristicDropdown(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final characteristics = ['Might', 'Agility', 'Reason', 'Intuition', 'Presence'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Characteristic${_characteristicMultiplier > 1 ? ' (x$_characteristicMultiplier)' : ''}:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _selectedCharacteristic,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          hint: const Text(ProjectRollDialogText.heroCharacteristicHint),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(ProjectRollDialogText.heroCharacteristicNoneLabel),
            ),
            ...characteristics.map((char) {
              final baseValue = _getCharacteristicValue(char);
              final totalValue = baseValue * _characteristicMultiplier;
              return DropdownMenuItem<String?>(
                value: char,
                child: Text(_characteristicMultiplier > 1 
                    ? '$char (+$totalValue = $baseValue×$_characteristicMultiplier)'
                    : '$char (+$totalValue)'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCharacteristic = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFollowerSection(
    BuildContext context,
    AsyncValue<List<Follower>> followersAsync,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.group, color: Colors.purple.shade300, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              ProjectRollDialogText.followerSectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        followersAsync.when(
          data: (followers) {
            if (followers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ProjectRollDialogText.noFollowersLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: followers.map((follower) {
                return _buildFollowerRollCard(context, follower);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: _projectsColor)),
          error: (e, _) => Text('Error loading followers: $e', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    );
  }

  Widget _buildFollowerRollCard(BuildContext context, Follower follower) {
    final theme = Theme.of(context);
    final rollState = _followerRolls[follower.id] ?? _FollowerRollState();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.purple.withAlpha(50),
                  child: Icon(Icons.person, size: 16, color: Colors.purple.shade300),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    follower.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _rollForFollower(follower),
                  icon: const Icon(Icons.casino, size: 16),
                  label: Text(
                    rollState.hasRolled
                        ? ProjectRollDialogText.followerRerollButtonLabel
                        : ProjectRollDialogText.followerRollButtonLabel,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade300,
                    side: BorderSide(color: Colors.purple.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            
            if (rollState.hasRolled) ...[
              const SizedBox(height: 8),
              
              // Show individual rolls
              ...rollState.rolls.asMap().entries.map((entry) {
                final index = entry.key;
                final roll = entry.value;
                final isBreakthrough = index > 0;
                final isBreakthroughRoll = roll.total >= 19;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBreakthroughRoll 
                          ? Colors.amber.withAlpha(40)
                          : Colors.grey.shade800.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                      border: isBreakthroughRoll 
                          ? Border.all(color: Colors.amber, width: 1)
                          : Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBreakthrough
                              ? 'B${index}: '
                              : ProjectRollDialogText.followerRollPrefixLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isBreakthrough ? Colors.amber.shade600 : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          '${roll.d1}+${roll.d2}=${roll.total}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isBreakthroughRoll) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.bolt, size: 12, color: Colors.amber.shade700),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              
              // Breakthrough button
              if (rollState.canBreakthrough) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _rollFollowerBreakthrough(follower.id),
                    icon: Icon(Icons.bolt, size: 14, color: Colors.amber.shade300),
                    label: const Text(
                      ProjectRollDialogText.followerBreakthroughButtonLabel,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade300,
                      side: BorderSide(color: Colors.amber.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Roll total with modifiers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rollState.rollTotal}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (rollState.modifierTotal != 0) ...[
                      Text(
                        '${rollState.modifierTotal >= 0 ? '+' : ''}${rollState.modifierTotal}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: rollState.modifierTotal >= 0 
                              ? Colors.green 
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    Text(
                      ' = ${rollState.finalTotal}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Follower modifiers
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SmallModifierButton(
                    label: ProjectRollDialogText.followerEdgeLabel,
                    count: rollState.edgeCount,
                    maxCount: rollState.maxEdges,
                    isPositive: true,
                    onAdd: () => _addFollowerEdge(follower.id),
                    onRemove: () => _removeFollowerEdge(follower.id),
                  ),
                  _SmallModifierButton(
                    label: ProjectRollDialogText.followerBaneLabel,
                    count: rollState.baneCount,
                    maxCount: rollState.maxBanes,
                    isPositive: false,
                    onAdd: () => _addFollowerBane(follower.id),
                    onRemove: () => _removeFollowerBane(follower.id),
                  ),
                  _SmallModifierButton(
                    label: ProjectRollDialogText.followerSkillLabel,
                    count: rollState.skillCount,
                    maxCount: rollState.maxSkillUses,
                    isPositive: true,
                    onAdd: () => _addFollowerSkill(follower.id),
                    onRemove: () => _removeFollowerSkill(follower.id),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Follower characteristic dropdown
              _buildFollowerCharacteristicDropdown(context, follower, rollState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerCharacteristicDropdown(
    BuildContext context,
    Follower follower,
    _FollowerRollState rollState,
  ) {
    final characteristics = ['Might', 'Agility', 'Reason', 'Intuition', 'Presence'];
    final multiplier = rollState.characteristicMultiplier;
    
    int getFollowerCharValue(String char) {
      switch (char.toLowerCase()) {
        case 'might': return follower.might;
        case 'agility': return follower.agility;
        case 'reason': return follower.reason;
        case 'intuition': return follower.intuition;
        case 'presence': return follower.presence;
        default: return 0;
      }
    }
    
    return DropdownButtonFormField<String?>(
      value: rollState.selectedCharacteristic,
      dropdownColor: NavigationTheme.cardBackgroundDark,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purple.shade400)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        isDense: true,
        labelText: 'Characteristic${multiplier > 1 ? ' (x$multiplier)' : ''}',
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(ProjectRollDialogText.followerCharacteristicNoneLabel),
        ),
        ...characteristics.map((char) {
          final baseValue = getFollowerCharValue(char);
          final totalValue = baseValue * multiplier;
          return DropdownMenuItem<String?>(
            value: char,
            child: Text(
              '$char (+$totalValue${multiplier > 1 ? ')' : ')'}',
              style: const TextStyle(fontSize: 13),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          final state = _followerRolls[follower.id] ?? _FollowerRollState();
          _followerRolls[follower.id] = state.copyWith(
            selectedCharacteristic: value,
            follower: follower,
          );
        });
      },
    );
  }

  void _rollForFollower(Follower follower) {
    final roll = _roll2d10();
    setState(() {
      _followerRolls[follower.id] = _FollowerRollState(
        rolls: [roll],
        hasRolled: true,
        canBreakthrough: roll.total >= 19,
        follower: follower,
      );
    });
  }

  void _rollFollowerBreakthrough(String followerId) {
    final state = _followerRolls[followerId];
    if (state == null || !state.canBreakthrough) return;
    final roll = _roll2d10();
    setState(() {
      _followerRolls[followerId] = state.copyWith(
        rolls: [...state.rolls, roll],
        canBreakthrough: roll.total >= 19,
      );
    });
  }

  void _addFollowerEdge(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.edgeCount < state.maxEdges) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(edgeCount: state.edgeCount + 1);
      });
    }
  }

  void _removeFollowerEdge(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.edgeCount > 0) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(edgeCount: state.edgeCount - 1);
      });
    }
  }

  void _addFollowerBane(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.baneCount < state.maxBanes) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(baneCount: state.baneCount + 1);
      });
    }
  }

  void _removeFollowerBane(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.baneCount > 0) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(baneCount: state.baneCount - 1);
      });
    }
  }

  void _addFollowerSkill(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.skillCount < state.maxSkillUses) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(skillCount: state.skillCount + 1);
      });
    }
  }

  void _removeFollowerSkill(String followerId) {
    final state = _followerRolls[followerId];
    if (state != null && state.skillCount > 0) {
      setState(() {
        _followerRolls[followerId] = state.copyWith(skillCount: state.skillCount - 1);
      });
    }
  }

  Widget _buildGrandTotalSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _projectsColor.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _projectsColor.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ProjectRollDialogText.totalPointsLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            '$_grandTotal',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _projectsColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// State for a follower's roll
class _FollowerRollState {
  final List<_RollResult> rolls; // All rolls including breakthroughs
  final bool hasRolled;
  final bool canBreakthrough;
  final int edgeCount;
  final int baneCount;
  final int skillCount; // Now a counter, not boolean
  final String? selectedCharacteristic;
  final Follower? follower;

  const _FollowerRollState({
    this.rolls = const [],
    this.hasRolled = false,
    this.canBreakthrough = false,
    this.edgeCount = 0,
    this.baneCount = 0,
    this.skillCount = 0,
    this.selectedCharacteristic,
    this.follower,
  });

  int get rollTotal => rolls.fold(0, (sum, roll) => sum + roll.total);
  
  /// Number of breakthrough rolls
  int get breakthroughCount => rolls.isNotEmpty ? rolls.length - 1 : 0;
  
  /// Max edges (2 base + 2 per breakthrough)
  int get maxEdges => 2 + (breakthroughCount * 2);
  
  /// Max banes (2 base + 2 per breakthrough)
  int get maxBanes => 2 + (breakthroughCount * 2);
  
  /// Max skill uses (1 base + 1 per breakthrough)
  int get maxSkillUses => 1 + breakthroughCount;
  
  /// Characteristic multiplier (1 base + 1 per breakthrough)
  int get characteristicMultiplier => 1 + breakthroughCount;

  int get modifierTotal {
    int mod = 0;
    mod += edgeCount * 2;
    mod -= baneCount * 2;
    mod += skillCount * 2;
    if (selectedCharacteristic != null && follower != null) {
      mod += _getCharValue() * characteristicMultiplier;
    }
    return mod;
  }

  int _getCharValue() {
    if (follower == null || selectedCharacteristic == null) return 0;
    switch (selectedCharacteristic!.toLowerCase()) {
      case 'might': return follower!.might;
      case 'agility': return follower!.agility;
      case 'reason': return follower!.reason;
      case 'intuition': return follower!.intuition;
      case 'presence': return follower!.presence;
      default: return 0;
    }
  }

  int get finalTotal {
    if (!hasRolled) return 0;
    final total = rollTotal + modifierTotal;
    return total < 1 ? 1 : total; // Minimum of 1
  }

  _FollowerRollState copyWith({
    List<_RollResult>? rolls,
    bool? hasRolled,
    bool? canBreakthrough,
    int? edgeCount,
    int? baneCount,
    int? skillCount,
    String? selectedCharacteristic,
    Follower? follower,
  }) {
    return _FollowerRollState(
      rolls: rolls ?? this.rolls,
      hasRolled: hasRolled ?? this.hasRolled,
      canBreakthrough: canBreakthrough ?? this.canBreakthrough,
      edgeCount: edgeCount ?? this.edgeCount,
      baneCount: baneCount ?? this.baneCount,
      skillCount: skillCount ?? this.skillCount,
      selectedCharacteristic: selectedCharacteristic ?? this.selectedCharacteristic,
      follower: follower ?? this.follower,
    );
  }
}

/// Modifier button with count display
class _ModifierButton extends StatelessWidget {
  const _ModifierButton({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.isPositive,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final int maxCount;
  final bool isPositive;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;
    final modifier = isPositive ? '+2' : '-2';
    
    return Container(
      decoration: BoxDecoration(
        color: count > 0 ? color.withAlpha(30) : Colors.grey.shade800.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0 ? color : Colors.grey.shade700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: count > 0 ? onRemove : null,
            icon: Icon(Icons.remove, size: 18, color: count > 0 ? Colors.white : Colors.grey.shade600),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label ($modifier)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: count > 0 ? color : Colors.grey.shade400,
                  ),
                ),
                Text(
                  '$count / $maxCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: count > 0 ? color : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: count < maxCount ? onAdd : null,
            icon: Icon(Icons.add, size: 18, color: count < maxCount ? Colors.white : Colors.grey.shade600),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Smaller modifier button for followers
class _SmallModifierButton extends StatelessWidget {
  const _SmallModifierButton({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.isPositive,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final int maxCount;
  final bool isPositive;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? color.withAlpha(30) : Colors.grey.shade800.withAlpha(50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: count > 0 ? color : Colors.grey.shade700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: count > 0 ? onRemove : null,
            child: Icon(
              Icons.remove,
              size: 14,
              color: count > 0 ? color : Colors.grey.shade600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$label $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: count > 0 ? color : Colors.grey.shade400,
              ),
            ),
          ),
          InkWell(
            onTap: count < maxCount ? onAdd : null,
            child: Icon(
              Icons.add,
              size: 14,
              color: count < maxCount ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a single 2d10 roll result
class _RollResult {
  final int d1;
  final int d2;

  const _RollResult({required this.d1, required this.d2});

  int get total => d1 + d2;
}
