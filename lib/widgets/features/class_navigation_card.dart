import 'package:flutter/material.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/feature_tokens.dart';
import '../../core/repositories/feature_repository.dart';

class ClassNavigationCard extends StatelessWidget {
  final String className;
  final int featureCount;
  final VoidCallback onTap;

  const ClassNavigationCard({
    super.key,
    required this.className,
    required this.featureCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(className);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: classColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                classColor.withValues(alpha: 0.08),
                classColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Class icon
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
                    width: 1.5,
                  ),
                ),
                child: AppIcon(
                  ClassIcons.fromName(className),
                  color: classColor,
                  size: 32,
                ),
              ),

              const SizedBox(width: 20),

              // Class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FeatureRepository.formatClassName(className),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: classColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$featureCount feature${featureCount != 1 ? 's' : ''} available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                  borderRadius: BorderRadius.circular(8),
                  color: classColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: classColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}