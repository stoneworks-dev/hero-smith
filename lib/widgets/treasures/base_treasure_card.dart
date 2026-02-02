import 'package:flutter/material.dart';
import '../../core/models/component.dart' as model;
import '../../core/theme/treasure_theme.dart';

/// Base treasure card widget with common styling and layout
class BaseTreasureCard extends StatefulWidget {
  final model.Component component;
  final List<Widget> children;
  final VoidCallback? onTap;

  const BaseTreasureCard({
    super.key,
    required this.component,
    required this.children,
    this.onTap,
  });

  @override
  State<BaseTreasureCard> createState() => _BaseTreasureCardState();
}

class _BaseTreasureCardState extends State<BaseTreasureCard> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colorScheme = TreasureTheme.getColorScheme(widget.component.type);
    
    return Card(
      margin: EdgeInsets.zero,
      color: TreasureTheme.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: TreasureTheme.getCardBorderColor(context, colorScheme.primary),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap ?? _toggleExpanded,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildHeader(context, colorScheme)),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: TreasureTheme.getSecondaryTextColor(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDescription(context),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ...widget.children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TreasureColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type emoji badge
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.badgeBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            TreasureTheme.getTreasureTypeEmoji(widget.component.type),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        // Name and echelon
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.component.name,
                style: TreasureTheme.treasureNameStyle.copyWith(
                  color: TreasureTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              _buildHeaderChips(context, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderChips(BuildContext context, TreasureColorScheme colorScheme) {
    final chips = <Widget>[];
    
    // Type chip
    chips.add(_buildChip(
      context,
      colorScheme,
      widget.component.type.replaceAll('_', ' ').toUpperCase(),
    ));

    // Echelon chip (if available)
    final echelon = widget.component.data['echelon'];
    if (echelon != null) {
      chips.add(_buildChip(
        context,
        colorScheme,
        'E$echelon',
        backgroundColor: TreasureTheme.getEchelonBadgeColor(context, echelon),
      ));
    }

    // Leveled chip (if it's a leveled treasure)
    if (widget.component.data['leveled'] == true) {
      chips.add(_buildChip(
        context,
        colorScheme,
        'LEVELED',
        backgroundColor: TreasureTheme.getLevelBackgroundColor(context, 1),
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildChip(
    BuildContext context,
    TreasureColorScheme colorScheme,
    String text, {
    Color? backgroundColor,
  }) {
    final bgColor = backgroundColor ?? 
        TreasureTheme.getKeywordChipBackgroundColor(context, colorScheme.primary);
    final textColor = backgroundColor != null 
        ? Colors.white
        : TreasureTheme.getKeywordChipTextColor(context, colorScheme.primary);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: backgroundColor == null ? Border.all(
          color: TreasureTheme.getKeywordChipBorderColor(context, colorScheme.primary),
          width: 0.5,
        ) : null,
      ),
      child: Text(
        text,
        style: TreasureTheme.keywordChipStyle.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = widget.component.data['description'] as String?;
    if (description == null || description.isEmpty) return const SizedBox.shrink();
    
    return Text(
      description,
      style: TreasureTheme.treasureDescriptionStyle.copyWith(
        color: TreasureTheme.getSecondaryTextColor(context),
      ),
    );
  }
}

/// Common widget for displaying keywords as chips
class KeywordChips extends StatelessWidget {
  final List<String> keywords;
  final TreasureColorScheme colorScheme;

  const KeywordChips({
    super.key,
    required this.keywords,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: keywords.map((keyword) => _buildKeywordChip(context, keyword)).toList(),
    );
  }

  Widget _buildKeywordChip(BuildContext context, String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TreasureTheme.getKeywordChipBackgroundColor(context, colorScheme.primary),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TreasureTheme.getKeywordChipBorderColor(context, colorScheme.primary),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TreasureTheme.getKeywordEmoji(keyword),
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            keyword,
            style: TreasureTheme.keywordChipStyle.copyWith(
              color: TreasureTheme.getKeywordChipTextColor(context, colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Common widget for displaying effect text in a styled container
class EffectSection extends StatelessWidget {
  final String title;
  final String text;
  final TreasureColorScheme colorScheme;

  const EffectSection({
    super.key,
    required this.title,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TreasureTheme.getSectionBackgroundColor(context, colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TreasureTheme.getSectionBorderColor(context, colorScheme.primary),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TreasureTheme.sectionTitleStyle.copyWith(
              color: TreasureTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TreasureTheme.effectTextStyle.copyWith(
              color: TreasureTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Common widget for displaying prerequisite information
class PrerequisiteSection extends StatelessWidget {
  final String? prerequisite;
  final String? projectSource;
  final List<String>? projectRollCharacteristics;
  final int? projectGoal;
  final String? projectGoalDescription;
  final TreasureColorScheme colorScheme;

  const PrerequisiteSection({
    super.key,
    required this.prerequisite,
    required this.projectSource,
    required this.projectRollCharacteristics,
    required this.projectGoal,
    required this.projectGoalDescription,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = prerequisite != null || 
                      projectSource != null || 
                      projectGoal != null;
    
    if (!hasContent) return const SizedBox.shrink();

    final sections = <Widget>[];

    if (prerequisite != null && prerequisite!.isNotEmpty) {
      sections.add(_buildPrerequisiteItem(context, 'Prerequisite', prerequisite!));
    }

    if (projectSource != null && projectSource!.isNotEmpty) {
      sections.add(_buildPrerequisiteItem(context, 'Source', projectSource!));
    }

    if (projectRollCharacteristics != null && projectRollCharacteristics!.isNotEmpty) {
      sections.add(_buildPrerequisiteItem(
        context,
        'Roll',
        projectRollCharacteristics!.join(' + '),
      ));
    }

    if (projectGoal != null) {
      final goalText = projectGoalDescription != null && projectGoalDescription!.isNotEmpty
          ? '$projectGoal ($projectGoalDescription)'
          : '$projectGoal';
      sections.add(_buildPrerequisiteItem(context, 'Goal', goalText));
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    // Use neutral crafting color instead of treasure-specific color
    const craftingColor = TreasureTheme.craftingColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TreasureTheme.getSectionBackgroundColor(context, craftingColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TreasureTheme.getSectionBorderColor(context, craftingColor),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRAFTING',
            style: TreasureTheme.sectionTitleStyle.copyWith(
              color: TreasureTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          ...sections.map((section) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: section,
          )),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteItem(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TreasureTheme.prerequisiteStyle.copyWith(
              color: TreasureTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TreasureTheme.prerequisiteStyle.copyWith(
              color: TreasureTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }
}