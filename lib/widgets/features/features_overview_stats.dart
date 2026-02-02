import 'package:flutter/material.dart';
import '../../core/models/feature.dart';
import '../../core/theme/feature_tokens.dart';

class FeaturesOverviewStats extends StatelessWidget {
  final Map<String, List<Feature>> classFeatures;

  const FeaturesOverviewStats({
    super.key,
    required this.classFeatures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFeatures = classFeatures.values.fold<int>(
      0, (sum, features) => sum + features.length);
    final totalClasses = classFeatures.length;
    final avgFeaturesPerClass = totalClasses > 0 
        ? (totalFeatures / totalClasses).round() 
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Total',
                '$totalFeatures',
                Icons.auto_stories,
                FeatureTokens.getClassColor('elementalist'),
              ),
            ),
            Container(
              width: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Classes',
                '$totalClasses',
                Icons.groups,
                FeatureTokens.getClassColor('tactician'),
              ),
            ),
            Container(
              width: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Avg/Class',
                '$avgFeaturesPerClass',
                Icons.trending_up,
                FeatureTokens.getClassColor('censor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 28, // Larger icon
        ),
        const SizedBox(width: 8), // Spacing between icon and number
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith( // Bigger text
              color: color,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 6), // Spacing between number and label
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith( // Bigger label text
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}