import 'package:flutter/material.dart';
import '../../core/models/feature.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/feature_tokens.dart';
import 'feature_level_section.dart';

class ClassFeaturesView extends StatelessWidget {
  final String className;
  final List<Feature> features;

  const ClassFeaturesView({
    super.key,
    required this.className,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(className);
    final featuresByLevel = FeatureRepository.groupFeaturesByLevel(features);
    final sortedLevels = FeatureRepository.getSortedLevels(featuresByLevel);

    return CustomScrollView(
      slivers: [
        // Class header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  classColor.withValues(alpha: 0.2),
                  classColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: classColor.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: classColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: classColor.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        _getClassIcon(className),
                        color: classColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FeatureRepository.formatClassName(className),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: classColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Class Features',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: classColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsRow(context),
              ],
            ),
          ),
        ),

        // Feature sections by level
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final level = sortedLevels[index];
              final levelFeatures = featuresByLevel[level]!;
              return FeatureLevelSection(
                level: level,
                features: levelFeatures,
              );
            },
            childCount: sortedLevels.length,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(className);
    final featuresByLevel = FeatureRepository.groupFeaturesByLevel(features);
    
    final totalFeatures = features.length;
    final subclassFeatures = features.where((f) => f.isSubclassFeature).length;
    final coreFeatures = totalFeatures - subclassFeatures;
    final levelRange = featuresByLevel.keys.isEmpty 
        ? '0' 
        : '${featuresByLevel.keys.reduce((a, b) => a < b ? a : b)}-${featuresByLevel.keys.reduce((a, b) => a > b ? a : b)}';

    return Row(
      children: [
        _buildStatChip(context, 'Total', '$totalFeatures', classColor),
        const SizedBox(width: 12),
        _buildStatChip(context, 'Core', '$coreFeatures', FeatureTokens.coreFeature),
        const SizedBox(width: 12),
        _buildStatChip(context, 'Subclass', '$subclassFeatures', FeatureTokens.subclassFeature),
        const SizedBox(width: 12),
        _buildStatChip(context, 'Levels', levelRange, theme.colorScheme.outline),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getClassIcon(String className) {
    switch (className.toLowerCase()) {
      case 'censor': return Icons.gavel;
      case 'conduit': return Icons.flash_on;
      case 'elementalist': return Icons.whatshot;
      case 'fury': return Icons.psychology;
      case 'null': return Icons.radio_button_unchecked;
      case 'shadow': return Icons.visibility_off;
      case 'tactician': return Icons.military_tech;
      case 'talent': return Icons.diamond;
      case 'troubadour': return Icons.music_note;
      default: return Icons.person;
    }
  }
}