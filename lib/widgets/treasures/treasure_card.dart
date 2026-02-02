import 'package:flutter/material.dart';
import '../../core/models/component.dart' as model;
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/treasure_theme.dart';

/// Modern treasure card with clean, minimal styling.
///
/// Features:
/// - Left accent stripe matching treasure type
/// - Dark background for better contrast
/// - Wider nested sections that blend with the card
/// - Smooth expand/collapse animation
/// - Optional quantity display with +/- controls for stacking
/// - Optional equip/unequip toggle for equipable treasures
class TreasureCard extends StatefulWidget {
  final model.Component component;
  final VoidCallback? onTap;

  /// The quantity of this treasure (for stacking). Defaults to 1.
  final int quantity;

  /// Callback when user wants to increase quantity.
  final VoidCallback? onIncrement;

  /// Callback when user wants to decrease quantity.
  final VoidCallback? onDecrement;

  /// Callback when user wants to remove the treasure entirely.
  final VoidCallback? onRemove;

  /// Whether to show quantity controls.
  final bool showQuantityControls;

  /// Whether this treasure is currently equipped.
  final bool isEquipped;

  /// Callback when user wants to toggle equipped state.
  final VoidCallback? onToggleEquip;

  /// Whether to show the equip toggle (only for equipable treasure types).
  final bool showEquipToggle;

  const TreasureCard({
    super.key,
    required this.component,
    this.onTap,
    this.quantity = 1,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.showQuantityControls = false,
    this.isEquipped = false,
    this.onToggleEquip,
    this.showEquipToggle = false,
  });

  @override
  State<TreasureCard> createState() => _TreasureCardState();
}

class _TreasureCardState extends State<TreasureCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  bool get wantKeepAlive => true;

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

  /// Check if this treasure type can be equipped.
  bool _isEquipableTreasure() {
    final type = widget.component.type.toLowerCase();
    // Consumables can't be equipped - they're one-time use
    // Trinkets, artifacts, and leveled treasures can be equipped
    return type == 'trinket' || type == 'artifact' || type == 'leveled_treasure';
  }

  /// Build the equip toggle button.
  Widget _buildEquipToggle(BuildContext context) {
    final isEquipped = widget.isEquipped;
    final equipColor = isEquipped ? Colors.green.shade400 : Colors.grey.shade400;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onToggleEquip,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: equipColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: equipColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEquipped ? Icons.check_circle : Icons.radio_button_unchecked,
                color: equipColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isEquipped ? 'EQUIPPED' : 'EQUIP',
                style: TextStyle(
                  color: equipColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.component.type.toLowerCase()) {
      case 'consumable':
        return NavigationTheme.consumablesColor;
      case 'trinket':
        return NavigationTheme.trinketsColor;
      case 'leveled_treasure':
        return NavigationTheme.leveledColor;
      case 'artifact':
        return NavigationTheme.artifactsColor;
      default:
        return NavigationTheme.treasureColor;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.component.type.toLowerCase()) {
      case 'consumable':
        return Icons.science_outlined;
      case 'trinket':
        return Icons.diamond_outlined;
      case 'leveled_treasure':
        return Icons.trending_up;
      case 'artifact':
        return Icons.auto_awesome;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final accentColor = _getAccentColor();
    final isEquipable = _isEquipableTreasure();

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        border: widget.isEquipped
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? _toggleExpanded,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent stripe (green glow when equipped)
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: widget.isEquipped ? Colors.green.shade400 : accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                    bottomLeft:
                        Radius.circular(NavigationTheme.cardBorderRadius),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, accentColor),
                      const SizedBox(height: 10),
                      // Equip toggle row (for equipable treasures)
                      if (widget.showEquipToggle && isEquipable) ...[
                        _buildEquipToggle(context),
                        const SizedBox(height: 10),
                      ],
                      _buildDescription(context),
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: _buildExpandedContent(context, accentColor),
                      ),
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

  Widget _buildHeader(BuildContext context, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity badge above the name (when quantity > 1 or controls shown)
        if (widget.quantity > 1 || widget.showQuantityControls)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildQuantityControls(accentColor),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(),
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Name and type badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.component.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBadges(context, accentColor),
                ],
              ),
            ),
            // Expand/collapse indicator
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
      ],
    );
  }

  Widget _buildQuantityControls(Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quantity label with count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2,
                color: accentColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'x${widget.quantity}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // +/- controls (only if callbacks provided)
        if (widget.showQuantityControls) ...[
          const SizedBox(width: 8),
          // Decrement button
          _buildQuantityButton(
            icon: widget.quantity <= 1 ? Icons.delete_outline : Icons.remove,
            onTap: widget.quantity <= 1 ? widget.onRemove : widget.onDecrement,
            color: widget.quantity <= 1
                ? Colors.red.shade400
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          // Increment button
          _buildQuantityButton(
            icon: Icons.add,
            onTap: widget.onIncrement,
            color: Colors.green.shade400,
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(BuildContext context, Color accentColor) {
    final badges = <Widget>[];

    // Type badge
    badges.add(_buildBadge(
      widget.component.type.replaceAll('_', ' ').toUpperCase(),
      accentColor,
    ));

    // Echelon badge
    final echelon = widget.component.data['echelon'];
    if (echelon != null) {
      final echelonColor = _getEchelonColor(echelon);
      badges.add(_buildBadge('E$echelon', echelonColor));
    }

    // Leveled badge
    if (widget.component.data['leveled'] == true) {
      badges.add(_buildBadge('LEVELED', NavigationTheme.leveledColor));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges,
    );
  }

  Color _getEchelonColor(int echelon) {
    switch (echelon) {
      case 1:
        return NavigationTheme.echelon1Color;
      case 2:
        return NavigationTheme.echelon2Color;
      case 3:
        return NavigationTheme.echelon3Color;
      case 4:
        return NavigationTheme.echelon4Color;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = widget.component.data['description'] as String?;
    if (description == null || description.isEmpty)
      return const SizedBox.shrink();

    return Text(
      description,
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
        height: 1.4,
      ),
      maxLines: _isExpanded ? null : 2,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedContent(BuildContext context, Color accentColor) {
    final colorScheme = TreasureTheme.getColorScheme(widget.component.type);
    final keywords = List<String>.from(widget.component.data['keywords'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Keywords
        if (keywords.isNotEmpty) ...[
          TreasureKeywordChips(keywords: keywords, accentColor: accentColor),
          const SizedBox(height: 16),
        ],

        // Effect section
        _buildEffectSection(context, accentColor),

        // Level variants (for leveled treasures)
        _buildLevelVariants(context, accentColor),

        // Crafting info
        _buildCraftingSection(context, accentColor, colorScheme),
      ],
    );
  }

  Widget _buildEffectSection(BuildContext context, Color accentColor) {
    final effect = widget.component.data['effect'] as Map<String, dynamic>?;
    if (effect == null) return const SizedBox.shrink();

    final effectDescription = effect['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    final isArtifact = widget.component.type.toLowerCase() == 'artifact';

    return TreasureSection(
      title: isArtifact ? 'ARTIFACT POWERS' : 'EFFECT',
      icon: isArtifact ? Icons.auto_awesome : Icons.flash_on,
      accentColor: accentColor,
      child: isArtifact
          ? _buildFormattedArtifactText(context, effectDescription)
          : Text(
              effectDescription,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 13,
                height: 1.5,
              ),
            ),
    );
  }

  Widget _buildFormattedArtifactText(BuildContext context, String text) {
    final paragraphs = text.split('\n\n');
    final widgets = <Widget>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isEmpty) continue;

      final isPowerTitle = paragraph.contains(':') &&
          (paragraph.split(':')[0].length < 50) &&
          (paragraph.indexOf(':') < paragraph.length / 2);

      if (isPowerTitle) {
        final parts = paragraph.split(':');
        if (parts.length >= 2) {
          widgets.add(Padding(
            padding: EdgeInsets.only(top: i > 0 ? 14 : 0, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts[0].trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parts.sublist(1).join(':').trim(),
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ));
        }
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            paragraph,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildLevelVariants(BuildContext context, Color accentColor) {
    final levels = [
      {'level': 1, 'data': widget.component.data['level_1']},
      {'level': 5, 'data': widget.component.data['level_5']},
      {'level': 9, 'data': widget.component.data['level_9']},
    ];

    final availableLevels =
        levels.where((level) => level['data'] != null).toList();
    if (availableLevels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Section header
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'LEVEL VARIANTS',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Level sections - flat, full-width with top border only
        ...availableLevels.map((level) => _buildLevelSection(
              context,
              level['level'] as int,
              level['data'] as Map<String, dynamic>,
            )),
      ],
    );
  }

  Widget _buildLevelSection(
    BuildContext context,
    int level,
    Map<String, dynamic> levelData,
  ) {
    final effectDescription = levelData['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    final levelColor = _getLevelColor(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colored top border
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: levelColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: levelColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'LEVEL $level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Content - full width, no box
        Text(
          effectDescription,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getLevelColor(int level) {
    return TreasureTheme.levelColors[level] ?? Colors.grey;
  }

  Widget _buildCraftingSection(
    BuildContext context,
    Color accentColor,
    TreasureColorScheme colorScheme,
  ) {
    final prerequisite = widget.component.data['item_prerequisite'] as String?;
    final projectSource = widget.component.data['project_source'] as String?;
    final projectGoal = widget.component.data['project_goal'];
    final projectGoalDescription =
        widget.component.data['project_goal_description'] as String?;
    final projectRollCharacteristics =
        widget.component.data['project_roll_characteristics'];

    final hasContent = (prerequisite != null &&
            prerequisite.isNotEmpty &&
            prerequisite.toLowerCase() != 'unknown') ||
        projectSource != null ||
        projectGoal != null;

    if (!hasContent) return const SizedBox.shrink();

    final craftingItems = <Widget>[];

    if (prerequisite != null &&
        prerequisite.isNotEmpty &&
        prerequisite.toLowerCase() != 'unknown') {
      craftingItems.add(_buildCraftingRow('Prerequisite', prerequisite));
    }

    if (projectSource != null && projectSource.isNotEmpty) {
      craftingItems.add(_buildCraftingRow('Source', projectSource));
    }

    if (projectRollCharacteristics != null) {
      final chars = List<String>.from(projectRollCharacteristics);
      if (chars.isNotEmpty) {
        craftingItems.add(_buildCraftingRow('Roll', chars.join(' + ')));
      }
    }

    if (projectGoal != null) {
      final goalText =
          projectGoalDescription != null && projectGoalDescription.isNotEmpty
              ? '$projectGoal ($projectGoalDescription)'
              : '$projectGoal';
      craftingItems.add(_buildCraftingRow('Goal', goalText));
    }

    if (craftingItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        TreasureSection(
          title: 'CRAFTING',
          icon: Icons.construction,
          accentColor: accentColor,
          child: Column(
            children: craftingItems,
          ),
        ),
      ],
    );
  }

  Widget _buildCraftingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SHARED COMPONENTS
// ============================================================

/// A section container with a title bar that blends with the card.
/// Uses minimal borders and a subtle background to reduce visual clutter.
class TreasureSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const TreasureSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - blended with container, no separate border
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Divider - subtle line
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 1,
            color: accentColor.withOpacity(0.15),
          ),
          // Content - full width
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Keyword chips with modern styling
class TreasureKeywordChips extends StatelessWidget {
  final List<String> keywords;
  final Color accentColor;

  const TreasureKeywordChips({
    super.key,
    required this.keywords,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keywords.map((keyword) => _buildChip(keyword)).toList(),
    );
  }

  Widget _buildChip(String keyword) {
    final emoji = TreasureTheme.getKeywordEmoji(keyword);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            keyword,
            style: TextStyle(
              color: accentColor.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
