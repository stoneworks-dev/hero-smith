/// Heroic resource section widget.
///
/// This file contains the widget that displays the hero's heroic resource
/// with generation buttons, spend buttons, and resource details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/resource_generation_service.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import '../../../core/theme/ability_colors.dart';
import 'hero_main_stats_models.dart';

/// Callback for editing a number field.
typedef OnEditNumberField = void Function(
    String label, NumericField field);

/// Callback for spending heroic resource.
typedef OnSpendResource = void Function(int amount);

/// Callback for applying resource generation.
typedef OnApplyGeneration = void Function(int amount);

/// Callback for handling resource generation with confirmation.
typedef OnHandleResourceGeneration = void Function(
  BuildContext context,
  HeroMainStats stats,
  String optionKey,
);

/// Heroic resource section widget.
class HeroicResourceSectionWidget extends StatelessWidget {
  const HeroicResourceSectionWidget({
    super.key,
    required this.stats,
    required this.resourceDetails,
    required this.minValue,
    required this.onEditNumberField,
    required this.onSpendResource,
    required this.onHandleResourceGeneration,
    required this.onShowResourceDetails,
  });

  final HeroMainStats stats;
  final AsyncValue<HeroicResourceDetails?> resourceDetails;
  final int minValue;
  final OnEditNumberField onEditNumberField;
  final OnSpendResource onSpendResource;
  final OnHandleResourceGeneration onHandleResourceGeneration;
  final void Function(BuildContext, String, HeroicResourceDetails?)
      onShowResourceDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = stats.heroicResourceCurrent;

    return resourceDetails.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => _buildResourceDisplay(
        context,
        stats,
        stats.heroicResourceName ??
            HeroMainStatsViewText.resourceFallbackErrorName,
        value,
      ),
      data: (details) {
        final resourceName = details?.name ??
            stats.heroicResourceName ??
            HeroMainStatsViewText.resourceFallbackName;
        final hasDetails = (details?.description ?? '').isNotEmpty ||
            (details?.inCombatDescription ?? '').isNotEmpty ||
            (details?.outCombatDescription ?? '').isNotEmpty ||
            (details?.strainDescription ?? '').isNotEmpty;

        // Calculate minimum value for resources that can go negative
        final effectiveMinValue =
            details?.calculateMinValue(reasonScore: stats.reasonTotal) ??
                minValue;
        final canBeNegative = details?.canBeNegative ?? false;
        
        // Get the resource-specific color
        final resourceColor = AbilityColors.getHeroicResourceColor(resourceName);

        return Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_outlined,
                      size: 14, color: resourceColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resourceName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: resourceColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasDetails)
                    InkWell(
                      onTap: () => onShowResourceDetails(
                          context, resourceName, details),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.info_outline,
                            size: 14, color: resourceColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => onEditNumberField(
                    resourceName, NumericField.heroicResourceCurrent),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toString(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: value < 0 ? Colors.red : resourceColor,
                        ),
                      ),
                      if (canBeNegative) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${HeroMainStatsViewText.resourceMinPrefix}$effectiveMinValue${HeroMainStatsViewText.resourceMinSuffix}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildResourceGenerationButtons(context, stats, resourceColor),
              _buildHeroicResourceSpendButtons(
                  context, stats, effectiveMinValue, resourceColor),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  /// Builds the resource generation buttons based on class
  Widget _buildResourceGenerationButtons(
      BuildContext context, HeroMainStats stats, Color resourceColor) {
    return FutureBuilder<List<GenerationPreset>>(
      future:
          _getResourceGenerationOptions(stats.classId, heroLevel: stats.level),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter out 'victories' option if victories is 0 (would give +0)
        final options = snapshot.data!
            .where((option) => option.key != 'victories' || stats.victories > 0)
            .toList();

        if (options.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: options.map((option) {
            final label = ResourceGenerationService.instance.getDisplayLabel(
              option.key,
              stats.victories,
            );

            return InkWell(
              onTap: () =>
                  onHandleResourceGeneration(context, stats, option.key),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: resourceColor.withOpacity(0.5),
                  ),
                  color: resourceColor.withOpacity(0.1),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: resourceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<GenerationPreset>> _getResourceGenerationOptions(String? classId,
      {int heroLevel = 1}) async {
    await ResourceGenerationService.instance.initialize();
    return ResourceGenerationService.instance
        .getGenerationOptionsForClass(classId, heroLevel: heroLevel);
  }

  Widget _buildHeroicResourceSpendButtons(
      BuildContext context, HeroMainStats stats, int effectiveMinValue, Color resourceColor) {
    const amounts = [1, 3, 5, 7, 9, 11];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: amounts.map((amount) {
        // Button is enabled if spending this amount won't go below the minimum
        final resultingValue = stats.heroicResourceCurrent - amount;
        final enabled = resultingValue >= effectiveMinValue;
        return _buildHeroicResourceButton(
          context,
          label: '-$amount',
          amount: amount,
          enabled: enabled,
          color: resourceColor,
        );
      }).toList(),
    );
  }

  Widget _buildHeroicResourceButton(
    BuildContext context, {
    required String label,
    required int amount,
    required bool enabled,
    required Color color,
  }) {
    return InkWell(
      onTap: enabled ? () => onSpendResource(amount) : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled ? color.withOpacity(0.6) : color.withOpacity(0.2),
          ),
          color: enabled ? color.withOpacity(0.15) : color.withOpacity(0.05),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? color : color.withOpacity(0.4),
              ),
        ),
      ),
    );
  }

  Widget _buildResourceDisplay(
      BuildContext context, HeroMainStats stats, String name, int value) {
    final theme = Theme.of(context);
    final resourceColor = AbilityColors.getHeroicResourceColor(name);
    
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined,
                  size: 14, color: resourceColor),
              const SizedBox(width: 4),
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: resourceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => onEditNumberField(
                name, NumericField.heroicResourceCurrent),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: resourceColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildHeroicResourceSpendButtons(context, stats, minValue, resourceColor),
          const SizedBox(height: 6),
          _buildResourceGenerationButtons(context, stats, resourceColor),
        ],
      ),
    );
  }
}

/// Shows the resource details dialog.
void showResourceDetailsDialog(
  BuildContext context,
  String name,
  HeroicResourceDetails? details,
) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((details?.description ?? '').isNotEmpty) ...[
                Text(
                  details!.description!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if ((details?.inCombatDescription ?? '').isNotEmpty) ...[
                Text(
                  details?.inCombatName ??
                      HeroMainStatsViewText.resourceDetailsInCombatFallback,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  details!.inCombatDescription!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if ((details?.outCombatDescription ?? '').isNotEmpty) ...[
                Text(
                  details?.outCombatName ??
                      HeroMainStatsViewText.resourceDetailsOutCombatFallback,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  details!.outCombatDescription!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if ((details?.strainDescription ?? '').isNotEmpty) ...[
                Text(
                  details?.strainName ??
                      HeroMainStatsViewText.resourceDetailsStrainFallback,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details!.strainDescription!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(HeroMainStatsViewText.resourceDetailsCloseLabel),
          ),
        ],
      );
    },
  );
}
