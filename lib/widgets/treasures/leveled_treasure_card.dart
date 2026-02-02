import 'package:flutter/material.dart';
import '../../core/models/component.dart' as model;
import 'base_treasure_card.dart';
import '../../core/theme/treasure_theme.dart';

/// Widget for displaying leveled treasures with their three level variants
class LeveledTreasureCard extends StatelessWidget {
  final model.Component component;

  const LeveledTreasureCard({
    super.key,
    required this.component,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = TreasureTheme.getColorScheme(component.type);
    final keywords = List<String>.from(component.data['keywords'] ?? []);
    final leveledType = component.data['leveled_type'] as String?;
    
    return BaseTreasureCard(
      component: component,
      children: [
        // Leveled type and keywords
        Row(
          children: [
            if (leveledType != null) ...[
              _buildLeveledTypeChip(context, colorScheme, leveledType),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: KeywordChips(keywords: keywords, colorScheme: colorScheme),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Base effect
        _buildBaseEffect(context, colorScheme),
        
        const SizedBox(height: 16),
        
        // Level variants
        _buildLevelVariants(context, colorScheme),
        
        const SizedBox(height: 12),
        
        // Crafting information
        PrerequisiteSection(
          prerequisite: component.data['item_prerequisite'],
          projectSource: component.data['project_source'],
          projectRollCharacteristics: component.data['project_roll_characteristics'] != null 
              ? List<String>.from(component.data['project_roll_characteristics'])
              : null,
          projectGoal: component.data['project_goal'],
          projectGoalDescription: component.data['project_goal_description'],
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildLeveledTypeChip(BuildContext context, TreasureColorScheme colorScheme, String leveledType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TreasureTheme.getLevelBackgroundColor(context, 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        leveledType.toUpperCase(),
        style: TreasureTheme.keywordChipStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBaseEffect(BuildContext context, TreasureColorScheme colorScheme) {
    final effect = component.data['effect'] as Map<String, dynamic>?;
    if (effect == null) return const SizedBox.shrink();

    final effectDescription = effect['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return EffectSection(
      title: 'BASE EFFECT',
      text: effectDescription,
      colorScheme: colorScheme,
    );
  }

  Widget _buildLevelVariants(BuildContext context, TreasureColorScheme colorScheme) {
    final levels = [
      {'level': 1, 'data': component.data['level_1']},
      {'level': 5, 'data': component.data['level_5']},
      {'level': 9, 'data': component.data['level_9']},
    ];

    final availableLevels = levels.where((level) => level['data'] != null).toList();
    
    if (availableLevels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEVEL VARIANTS',
          style: TreasureTheme.sectionTitleStyle.copyWith(
            color: TreasureTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ...availableLevels.map((level) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLevelCard(
            context,
            colorScheme,
            level['level'] as int,
            level['data'] as Map<String, dynamic>,
          ),
        )),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    TreasureColorScheme colorScheme,
    int level,
    Map<String, dynamic> levelData,
  ) {
    final effectDescription = levelData['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TreasureTheme.getLevelBackgroundColor(context, level).withOpacity(0.5),
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
              color: TreasureTheme.getLevelBackgroundColor(context, level),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              'LEVEL $level',
              style: TreasureTheme.levelHeaderStyle,
            ),
          ),
          // Level content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              effectDescription,
              style: TreasureTheme.effectTextStyle.copyWith(
                color: TreasureTheme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}