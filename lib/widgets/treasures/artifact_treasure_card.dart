import 'package:flutter/material.dart';
import '../../core/models/component.dart' as model;
import 'base_treasure_card.dart';
import '../../core/theme/treasure_theme.dart';

/// Widget for displaying artifact treasures (primarily large text descriptions)
class ArtifactTreasureCard extends StatelessWidget {
  final model.Component component;

  const ArtifactTreasureCard({
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
          const SizedBox(height: 16),
        ],
        
        // Artifact powers (large text block)
        _buildArtifactPowers(context, colorScheme),
        
        const SizedBox(height: 12),
        
        // Prerequisite information (usually minimal for artifacts)
        _buildPrerequisiteInfo(context, colorScheme),
      ],
    );
  }

  Widget _buildArtifactPowers(BuildContext context, TreasureColorScheme colorScheme) {
    final effect = component.data['effect'] as Map<String, dynamic>?;
    if (effect == null) return const SizedBox.shrink();

    final effectDescription = effect['effect_description'] as String?;
    if (effectDescription == null || effectDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    // For artifacts, we want to present the text in a more prominent way
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TreasureTheme.getSectionBackgroundColor(context, colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TreasureTheme.getSectionBorderColor(context, colorScheme.primary),
          width: 1,
        ),
        // Add a subtle gradient for artifacts to make them feel special
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TreasureTheme.getSectionBackgroundColor(context, colorScheme.primary),
            TreasureTheme.getSectionBackgroundColor(context, colorScheme.primary).withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: TreasureTheme.getTextColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                'ARTIFACT POWERS',
                style: TreasureTheme.sectionTitleStyle.copyWith(
                  color: TreasureTheme.getTextColor(context),
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormattedArtifactText(context, effectDescription),
        ],
      ),
    );
  }

  Widget _buildFormattedArtifactText(BuildContext context, String text) {
    // Split the text into paragraphs and format them nicely
    final paragraphs = text.split('\n\n');
    final widgets = <Widget>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isEmpty) continue;

      // Check if this paragraph is a power name (ends with colon or starts with bold patterns)
      final isPowerTitle = paragraph.contains(':') && 
                          (paragraph.split(':')[0].length < 50) &&
                          (paragraph.indexOf(':') < paragraph.length / 2);

      if (isPowerTitle) {
        final parts = paragraph.split(':');
        if (parts.length >= 2) {
          widgets.add(Padding(
            padding: EdgeInsets.only(top: i > 0 ? 16 : 0, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts[0].trim(),
                  style: TreasureTheme.sectionTitleStyle.copyWith(
                    color: TreasureTheme.getTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parts.sublist(1).join(':').trim(),
                  style: TreasureTheme.effectTextStyle.copyWith(
                    color: TreasureTheme.getTextColor(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ));
        }
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            paragraph,
            style: TreasureTheme.effectTextStyle.copyWith(
              color: TreasureTheme.getTextColor(context),
              height: 1.6,
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

  Widget _buildPrerequisiteInfo(BuildContext context, TreasureColorScheme colorScheme) {
    final prerequisite = component.data['item_prerequisite'] as String?;
    
    // Only show if there's meaningful prerequisite info (not just "Unknown")
    if (prerequisite == null || 
        prerequisite.isEmpty || 
        prerequisite.toLowerCase() == 'unknown') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TreasureTheme.getSectionBackgroundColor(context, colorScheme.primary).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TreasureTheme.getSectionBorderColor(context, colorScheme.primary).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACQUISITION',
            style: TreasureTheme.sectionTitleStyle.copyWith(
              color: TreasureTheme.getTextColor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            prerequisite,
            style: TreasureTheme.prerequisiteStyle.copyWith(
              color: TreasureTheme.getSecondaryTextColor(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}