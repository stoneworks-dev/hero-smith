import 'package:flutter/material.dart';
import '../../core/models/feature.dart';
import '../../core/text/widgets/feature_widget_text.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/feature_tokens.dart';
import '../../features/main_pages/strife/level_detail_page.dart';

class LevelDropdownCard extends StatelessWidget {
  final int level;
  final List<Feature> features;
  final String className;

  const LevelDropdownCard({
    super.key,
    required this.level,
    required this.features,
    required this.className,
  });

  void _navigateToLevelDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelDetailPage(
          level: level,
          features: features,
          className: className,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = FeatureTokens.getLevelColor(level);
    final classColor = FeatureTokens.getClassColor(className);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: levelColor.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () => _navigateToLevelDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                // Level icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                      width: 1.5,
                    ),
                  ),
                  child: AppIcon(
                    LevelIcons.fromLevel(level),
                    color: levelColor,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FeatureWidgetText.levelLabelDynamic(level),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${features.length} feature${features.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: levelColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: levelColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: levelColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}