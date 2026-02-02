import 'package:flutter/material.dart';
import '../../core/models/component.dart' as model;
import 'base_treasure_card.dart';
import '../../core/theme/treasure_theme.dart';

/// Widget for displaying consumable treasures
class ConsumableTreasureCard extends StatelessWidget {
  final model.Component component;

  const ConsumableTreasureCard({
    super.key,
    required this.component,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = TreasureTheme.getColorScheme(component.type);
    final keywords = List<String>.from(component.data['keywords'] ?? []);
    
    return BaseTreasureCard(
      component: component,
      children: [
        // Keywords
        if (keywords.isNotEmpty) ...[
          KeywordChips(keywords: keywords, colorScheme: colorScheme),
          const SizedBox(height: 12),
        ],
        
        // Effect
        _buildEffect(context, colorScheme),
        
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

  Widget _buildEffect(BuildContext context, TreasureColorScheme colorScheme) {
    final effect = component.data['effect'] as Map<String, dynamic>?;
    if (effect == null) return const SizedBox.shrink();

    final effectDescription = effect['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return EffectSection(
      title: 'EFFECT',
      text: effectDescription,
      colorScheme: colorScheme,
    );
  }
}