import 'package:flutter/material.dart';
import '../../../core/models/feature.dart';
import '../../../core/text/main_pages/strife/level_detail_page_text.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/feature_tokens.dart';
import '../../../core/repositories/feature_repository.dart';
import '../../../widgets/features/feature_dropdown_section.dart';

class LevelDetailPage extends StatelessWidget {
  final int level;
  final List<Feature> features;
  final String className;

  const LevelDetailPage({
    super.key,
    required this.level,
    required this.features,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(className);
    final levelColor = FeatureTokens.getLevelColor(level);
    
    // Group features by type/category for dropdowns
    final featuresByType = _groupFeaturesByType(features);

    return Scaffold(
      appBar: AppBar(
        title: Text(LevelDetailPageText.appBarTitle(level)),
        backgroundColor: levelColor.withValues(alpha: 0.1),
        foregroundColor: levelColor,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: CustomScrollView(
        slivers: [
          // Header with level info
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    levelColor.withValues(alpha: 0.15),
                    classColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: levelColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          levelColor.withValues(alpha: 0.2),
                          levelColor.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: AppIcon(
                      LevelIcons.fromLevel(level),
                      color: levelColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LevelDetailPageText.classLevelTitle(FeatureRepository.formatClassName(className), level),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: levelColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LevelDetailPageText.featuresAvailable(features.length),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: levelColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feature dropdown sections
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = featuresByType.entries.elementAt(index);
                  return FeatureDropdownSection(
                    title: entry.key,
                    features: entry.value,
                    className: className,
                    level: level,
                  );
                },
                childCount: featuresByType.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Feature>> _groupFeaturesByType(List<Feature> features) {
    final Map<String, List<Feature>> grouped = {};
    
    for (final feature in features) {
      String category;
      
      if (feature.isSubclassFeature) {
        category = LevelDetailPageText.subclassFeatures;
      } else if (feature.name.toLowerCase().contains('maneuver')) {
        category = LevelDetailPageText.maneuvers;
      } else if (feature.name.toLowerCase().contains('spell') || 
                 feature.name.toLowerCase().contains('magic')) {
        category = LevelDetailPageText.magicalAbilities;
      } else if (feature.description.toLowerCase().contains('passive') ||
                 feature.description.toLowerCase().contains('always')) {
        category = LevelDetailPageText.passiveFeatures;
      } else {
        category = LevelDetailPageText.coreFeatures;
      }
      
      grouped.putIfAbsent(category, () => []).add(feature);
    }
    
    return grouped;
  }

}