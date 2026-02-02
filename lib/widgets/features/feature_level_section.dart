import 'package:flutter/material.dart';
import '../../core/models/feature.dart';
import '../../core/theme/feature_tokens.dart';
import 'feature_card.dart';

class FeatureLevelSection extends StatelessWidget {
  final int level;
  final List<Feature> features;

  const FeatureLevelSection({
    super.key,
    required this.level,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = FeatureTokens.getLevelColor(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level header
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                levelColor.withValues(alpha: 0.2),
                levelColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: levelColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getLevelIcon(level),
                color: levelColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Level $level',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: levelColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: levelColor.withValues(alpha: 0.2),
                ),
                child: Text(
                  '${features.length} feature${features.length != 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Features list
        ...features.map((feature) => FeatureCard(feature: feature)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getLevelIcon(int level) {
    if (level <= 3) return Icons.star_outline;
    if (level <= 6) return Icons.star_half;
    if (level <= 9) return Icons.star;
    return Icons.auto_awesome;
  }
}