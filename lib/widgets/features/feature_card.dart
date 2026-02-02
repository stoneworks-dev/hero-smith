import 'package:flutter/material.dart';
import '../../core/models/feature.dart';
import '../../core/models/component.dart';
import '../../core/theme/feature_tokens.dart';
import '../abilities/abilities_shared.dart';
import '../abilities/ability_expandable_item.dart';

class FeatureCard extends StatelessWidget {
  final Feature feature;
  final VoidCallback? onTap;
  final List<Component>? grantedAbilities;

  const FeatureCard({
    super.key,
    required this.feature,
    this.onTap,
    this.grantedAbilities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final classColor = FeatureTokens.getClassColor(feature.className);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: classColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feature.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLevelBadge(context),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Feature type and subclass info
              Row(
                children: [
                  _buildTypeBadge(context),
                  if (feature.subclassName != null) ...[
                    const SizedBox(width: 8),
                    _buildSubclassBadge(context),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Description with enhanced text highlighting
              AbilityTextHighlighter.highlightGameMechanics(
                feature.description,
                context,
                baseStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),

              // Display granted abilities if any
              if (grantedAbilities != null && grantedAbilities!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Granted Abilities',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...grantedAbilities!.map((component) => 
                  AbilityExpandableItem(component: component)
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = FeatureTokens.getLevelColor(feature.level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            levelColor.withValues(alpha: 0.3),
            levelColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Text(
        'Level ${feature.level}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = FeatureTokens.getFeatureTypeColor(feature.isSubclassFeature);
    final label = feature.isSubclassFeature ? 'Subclass' : 'Core';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: typeColor.withValues(alpha: 0.15),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: typeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSubclassBadge(BuildContext context) {
    final theme = Theme.of(context);
    final classColor = FeatureTokens.getClassColor(feature.className);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: classColor.withValues(alpha: 0.15),
        border: Border.all(
          color: classColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        feature.subclassName!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: classColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}