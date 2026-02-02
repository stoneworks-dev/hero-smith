import 'package:flutter/material.dart';
import '../../../core/models/feature.dart';
import '../../../core/repositories/feature_repository.dart';
import '../../../core/theme/feature_tokens.dart';
import '../../../widgets/features/level_dropdown_card.dart';
import '../../../widgets/features/feature_search_delegate.dart';

class ClassDetailPage extends StatelessWidget {
  final String className;
  final List<Feature> features;

  const ClassDetailPage({
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('${FeatureRepository.formatClassName(className)} Features'),
        backgroundColor: classColor.withValues(alpha: 0.1),
        foregroundColor: classColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FeatureSearchDelegate(
                  features: features,
                  className: className,
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Class header with stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    classColor.withValues(alpha: 0.15),
                    classColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: classColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: classColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              classColor.withValues(alpha: 0.2),
                              classColor.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: classColor.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getClassIcon(className),
                          color: classColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FeatureRepository.formatClassName(className),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: classColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Class Features & Abilities',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: classColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatsGrid(context),
                ],
              ),
            ),
          ),

          // Level sections
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final level = sortedLevels[index];
                  final levelFeatures = featuresByLevel[level]!;
                  return LevelDropdownCard(
                    level: level,
                    features: levelFeatures,
                    className: className,
                  );
                },
                childCount: sortedLevels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(className);
    final featuresByLevel = FeatureRepository.groupFeaturesByLevel(features);
    
    final totalFeatures = features.length;
    final subclassFeatures = features.where((f) => f.isSubclassFeature).length;
    final coreFeatures = totalFeatures - subclassFeatures;
    final levelRange = featuresByLevel.keys.isEmpty 
        ? '0' 
        : '${featuresByLevel.keys.reduce((a, b) => a < b ? a : b)}-${featuresByLevel.keys.reduce((a, b) => a > b ? a : b)}';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3.5, // Increased from 3.0 to give more height for vertical content
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(context, 'Total', '$totalFeatures', Icons.auto_stories, classColor),
        _buildStatCard(context, 'Levels', levelRange, Icons.trending_up, FeatureTokens.levelMid),
        _buildStatCard(context, 'Core', '$coreFeatures', Icons.star, FeatureTokens.coreFeature),
        _buildStatCard(context, 'Subclass', '$subclassFeatures', Icons.diamond, FeatureTokens.subclassFeature),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 32, // Larger icon for detail page
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
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
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