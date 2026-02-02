import 'package:flutter/material.dart';

import '../../core/models/heroic_resource_progression.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/heroic_resource_theme.dart';

/// A gauge widget that displays heroic resource progression with a bar
/// that fills based on current resource value, and tier benefits that
/// change appearance based on whether they're active, inactive, or locked.
///
/// By default, only shows tiers that are:
/// - Unlocked (by hero level) AND reached (by current resource), or
/// - The next unlocked tier to reach
/// 
/// Hidden tiers can be revealed via an expandable dropdown.
class HeroicResourceGauge extends StatefulWidget {
  const HeroicResourceGauge({
    super.key,
    required this.progression,
    required this.currentResource,
    required this.heroLevel,
    this.showCompact = false,
  });

  /// The progression data containing tiers and their benefits
  final HeroicResourceProgression progression;

  /// The current heroic resource value (e.g., current Ferocity)
  final int currentResource;

  /// The hero's current level (determines which tiers are unlocked)
  final int heroLevel;

  /// If true, shows a more compact version of the gauge
  final bool showCompact;

  @override
  State<HeroicResourceGauge> createState() => _HeroicResourceGaugeState();
}

class _HeroicResourceGaugeState extends State<HeroicResourceGauge>
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;

  @override
  bool get wantKeepAlive => true;

  HeroicResourceProgression get progression => widget.progression;
  int get currentResource => widget.currentResource;
  int get heroLevel => widget.heroLevel;
  bool get showCompact => widget.showCompact;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resourceColor = _getResourceColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? HeroicResourceTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resourceColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(showCompact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark, resourceColor),
            SizedBox(height: showCompact ? 8 : 12),
            _buildProgressBar(isDark, resourceColor),
            SizedBox(height: showCompact ? 8 : 12),
            _buildTiersList(isDark, resourceColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color resourceColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: resourceColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getResourceIcon(),
            color: resourceColor,
            size: showCompact ? 16 : 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            progression.name,
            style: TextStyle(
              fontSize: showCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
        _buildCurrentValueBadge(isDark, resourceColor),
      ],
    );
  }

  Widget _buildCurrentValueBadge(bool isDark, Color resourceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resourceColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resourceColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentResource.toString(),
            style: TextStyle(
              fontSize: showCompact ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: resourceColor,
            ),
          ),
          Text(
            ' / ${progression.maxResourceValue}',
            style: TextStyle(
              fontSize: showCompact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, Color resourceColor) {
    final maxValue = progression.maxResourceValue;
    final fillPercentage = maxValue > 0 
        ? (currentResource / maxValue).clamp(0.0, 1.0) 
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tick marks for each tier threshold
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: progression.tiers.map((tier) {
                  final position = maxValue > 0
                      ? (tier.resourceThreshold / maxValue) * width
                      : 0.0;
                  final isUnlocked = tier.isUnlockedAtLevel(heroLevel);
                  final isActive = currentResource >= tier.resourceThreshold;

                  return Positioned(
                    left: position - 10,
                    child: Column(
                      children: [
                        Text(
                          tier.resourceThreshold.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: !isUnlocked
                                ? Colors.grey.shade500
                                : isActive
                                    ? resourceColor
                                    : isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Main progress bar
        Container(
          height: showCompact ? 8 : 10,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(7),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  // Filled portion
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: width * fillPercentage,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          resourceColor.withOpacity(0.8),
                          resourceColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: resourceColor.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  // Tier markers on the bar
                  ...progression.tiers.map((tier) {
                    final position = maxValue > 0
                        ? (tier.resourceThreshold / maxValue) * width
                        : 0.0;
                    final isUnlocked = tier.isUnlockedAtLevel(heroLevel);

                    return Positioned(
                      left: position - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: !isUnlocked
                              ? Colors.grey.shade600
                              : isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTiersList(bool isDark, Color resourceColor) {
    // Partition tiers into visible (reached or next-to-reach while unlocked) and hidden
    final visibleTiers = <ProgressionTier>[];
    final hiddenTiers = <ProgressionTier>[];
    bool foundNextUnlocked = false;

    for (final tier in progression.tiers) {
      final isUnlocked = tier.isUnlockedAtLevel(heroLevel);
      final isReached = currentResource >= tier.resourceThreshold;

      if (isUnlocked && isReached) {
        // Already reached this tier - always visible
        visibleTiers.add(tier);
      } else if (isUnlocked && !foundNextUnlocked) {
        // First unlocked tier not yet reached - show as "next goal"
        visibleTiers.add(tier);
        foundNextUnlocked = true;
      } else {
        // Either locked by level or beyond the next goal
        hiddenTiers.add(tier);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always-visible tiers
        ...visibleTiers.map((tier) => _TierBenefitItem(
          tier: tier,
          currentResource: currentResource,
          heroLevel: heroLevel,
          resourceColor: resourceColor,
          isDark: isDark,
          showCompact: showCompact,
        )),
        // Expandable section for hidden tiers
        if (hiddenTiers.isNotEmpty) ...[
          _buildExpandToggle(isDark, resourceColor, hiddenTiers.length),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: hiddenTiers.map((tier) => _TierBenefitItem(
                tier: tier,
                currentResource: currentResource,
                heroLevel: heroLevel,
                resourceColor: resourceColor,
                isDark: isDark,
                showCompact: showCompact,
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandToggle(bool isDark, Color resourceColor, int hiddenCount) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'Hide' : 'Show $hiddenCount more tier${hiddenCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResourceColor() {
    switch (progression.resourceName.toLowerCase()) {
      case 'ferocity':
        return AppColors.ferocityColor;
      case 'discipline':
        return AppColors.disciplineColor;
      default:
        return AppColors.primary;
    }
  }

  IconData _getResourceIcon() {
    switch (progression.resourceName.toLowerCase()) {
      case 'ferocity':
        return Icons.local_fire_department_rounded;
      case 'discipline':
        return Icons.psychology_rounded;
      default:
        return Icons.auto_awesome;
    }
  }
}

class _TierBenefitItem extends StatelessWidget {
  const _TierBenefitItem({
    required this.tier,
    required this.currentResource,
    required this.heroLevel,
    required this.resourceColor,
    required this.isDark,
    required this.showCompact,
  });

  final ProgressionTier tier;
  final int currentResource;
  final int heroLevel;
  final Color resourceColor;
  final bool isDark;
  final bool showCompact;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = tier.isUnlockedAtLevel(heroLevel);
    final isActive = isUnlocked && currentResource >= tier.resourceThreshold;
    final isLocked = !isUnlocked;

    return Padding(
      padding: EdgeInsets.only(bottom: showCompact ? 8 : 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(showCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: isLocked
              ? (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
              : isActive
                  ? resourceColor.withOpacity(isDark ? 0.15 : 0.1)
                  : (isDark ? HeroicResourceTheme.panel : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLocked
                ? Colors.grey.shade600
                : isActive
                    ? resourceColor.withOpacity(0.5)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThresholdBadge(isUnlocked, isActive, isLocked),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLocked) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocks at Level ${tier.requiredLevel}',
                          style: TextStyle(
                            fontSize: showCompact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: showCompact ? 12 : 13,
                      color: isLocked
                          ? Colors.grey.shade500
                          : isActive
                              ? (isDark ? Colors.white : Colors.grey.shade900)
                              : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700),
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      height: 1.4,
                    ),
                    child: Text(tier.benefit),
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: resourceColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdBadge(bool isUnlocked, bool isActive, bool isLocked) {
    return Container(
      width: showCompact ? 32 : 36,
      height: showCompact ? 32 : 36,
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.shade700
            : isActive
                ? resourceColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: resourceColor.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isLocked
            ? Icon(
                Icons.lock_rounded,
                size: showCompact ? 14 : 16,
                color: Colors.grey.shade500,
              )
            : Text(
                tier.resourceThreshold.toString(),
                style: TextStyle(
                  fontSize: showCompact ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
      ),
    );
  }
}
