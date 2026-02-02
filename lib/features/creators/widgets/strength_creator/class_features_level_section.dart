part of 'class_features_widget.dart';

class _LevelSection extends StatefulWidget {
  const _LevelSection({
    super.key,
    required this.levelNumber,
    required this.currentLevel,
    required this.features,
    required this.widget,
  });

  final int levelNumber;
  final int currentLevel;
  final List<Feature> features;
  final ClassFeaturesWidget widget;

  @override
  State<_LevelSection> createState() => _LevelSectionState();
}

class _LevelSectionState extends State<_LevelSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final levelColor = FeatureTokens.getLevelColor(widget.levelNumber);
    final isUnlocked = widget.levelNumber <= widget.currentLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: CreatorTheme.cardBackground,
        border: Border.all(
          color: isUnlocked
              ? levelColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: levelColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('level_${widget.levelNumber}'),
            initiallyExpanded: isUnlocked,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            backgroundColor: CreatorTheme.cardBackground,
            collapsedBackgroundColor: CreatorTheme.cardBackground,
            iconColor: isUnlocked ? levelColor : Colors.grey,
            collapsedIconColor: isUnlocked ? levelColor : Colors.grey,
            leading: _LevelBadge(level: widget.levelNumber, isUnlocked: isUnlocked),
            title: Text(
              '${ClassFeaturesLevelSectionText.levelTitlePrefix}'
              '${widget.levelNumber}'
              '${ClassFeaturesLevelSectionText.levelTitleSuffix}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? CreatorTheme.textPrimary
                    : CreatorTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            subtitle: Text(
              '${widget.features.length}'
              '${widget.features.length == 1 ? ClassFeaturesLevelSectionText.featureCountSingularSuffix : ClassFeaturesLevelSectionText.featureCountPluralSuffix}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CreatorTheme.textSecondary,
              ),
            ),
            children: [
              Divider(
                height: 1,
                color: levelColor.withValues(alpha: 0.2),
              ),
              Container(
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < widget.features.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index < widget.features.length - 1 ? 12 : 0,
                        ),
                        child: _FeatureCard(
                          // Include selection count in key to force rebuild when choice is made
                          key: ValueKey(
                            '${widget.features[index].id}_'
                            '${widget.widget.selectedOptions[widget.features[index].id]?.length ?? 0}',
                          ),
                          feature: widget.features[index],
                          widget: widget.widget,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.isUnlocked});

  final int level;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final levelColor = FeatureTokens.getLevelColor(level);
    final effectiveColor = isUnlocked ? levelColor : Colors.grey;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveColor.withValues(alpha: 0.3),
            effectiveColor.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}
