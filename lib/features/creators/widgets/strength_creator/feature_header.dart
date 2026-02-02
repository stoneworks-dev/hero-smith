part of 'class_features_widget.dart';

class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({
    required this.feature,
    required this.featureStyle,
    required this.grantType,
    required this.isExpanded,
    required this.onToggle,
    required this.widget,
  });

  final Feature feature;
  final _FeatureStyle featureStyle;
  final String grantType;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ClassFeaturesWidget widget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDomainLinked = widget.domainLinkedFeatureIds.contains(feature.id);
    final isDeityLinked = widget.deityLinkedFeatureIds.contains(feature.id);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(14),
        bottom: isExpanded ? Radius.zero : const Radius.circular(14),
      ),
      child: Container(
        decoration: isExpanded
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    featureStyle.borderColor.withValues(alpha: 0.12),
                    featureStyle.borderColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                // Grant type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: featureStyle.borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: featureStyle.borderColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    featureStyle.icon,
                    size: 20,
                    color: featureStyle.borderColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CreatorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        featureStyle.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: featureStyle.borderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expand icon
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: CreatorTheme.textSecondary,
                  ),
                ),
              ],
            ),
            // Tags row
            if (feature.isSubclassFeature || isDomainLinked || isDeityLinked) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (feature.isSubclassFeature)
                    _SmallTag(
                      icon: Icons.star_rounded,
                      label: widget.subclassLabel?.isNotEmpty == true
                          ? widget.subclassLabel!
                          : FeatureHeaderText.subclassLabelFallback,
                      color: Colors.purple.shade300,
                    ),
                  if (isDomainLinked)
                    _SmallTag(
                      icon: Icons.account_tree_rounded,
                      label: FeatureHeaderText.domainLabel,
                      color: Colors.teal,
                    ),
                  if (isDeityLinked)
                    _SmallTag(
                      icon: Icons.auto_awesome,
                      label: FeatureHeaderText.deityLabel,
                      color: Colors.amber.shade700,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
