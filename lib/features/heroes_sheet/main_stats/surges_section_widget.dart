/// Surges section widget.
///
/// This file contains the widget that displays the hero's surges
/// with add and spend buttons.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import '../../../core/theme/ability_colors.dart';
import 'hero_main_stats_models.dart';

/// Callback for editing a number field.
typedef OnEditNumberField = void Function(String label, NumericField field);

/// Callback for spending surges.
typedef OnSpendSurges = void Function(int amount);

/// Callback for adding surges.
typedef OnAddSurges = void Function(int amount);

/// Surges section widget.
class SurgesSectionWidget extends StatelessWidget {
  const SurgesSectionWidget({
    super.key,
    required this.stats,
    required this.onEditNumberField,
    required this.onSpendSurges,
    required this.onAddSurges,
    required this.onShowInfo,
  });

  final HeroMainStats stats;
  final OnEditNumberField onEditNumberField;
  final OnSpendSurges onSpendSurges;
  final OnAddSurges onAddSurges;
  final void Function(BuildContext context) onShowInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = stats.surgesCurrent;

    // Calculate surge damage based on highest attribute
    final highestAttribute = [
      stats.mightTotal,
      stats.agilityTotal,
      stats.reasonTotal,
      stats.intuitionTotal,
      stats.presenceTotal,
    ].reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.electric_bolt_outlined,
                  size: 14, color: AbilityColors.surge),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  HeroMainStatsViewText.surgesSectionTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AbilityColors.surge,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onShowInfo(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.info_outline,
                      size: 14, color: AbilityColors.surge),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => onEditNumberField(
              HeroMainStatsViewText.surgesEditLabel,
              NumericField.surgesCurrent,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AbilityColors.surge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Add surges buttons (+1, +2)
          Row(
            children: [
              _buildAddSurgeButton(context, 1),
              const SizedBox(width: 4),
              _buildAddSurgeButton(context, 2),
            ],
          ),
          const SizedBox(height: 4),
          // Spend surges buttons
          Row(
            children: [
              Expanded(
                child: _buildSurgeButton(
                  context,
                  cost: 1,
                  label:
                      '+$highestAttribute${HeroMainStatsViewText.surgesDamageSuffix}',
                  enabled: value >= 1,
                  onPressed: () => onSpendSurges(1),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSurgeButton(
                  context,
                  cost: 2,
                  label: HeroMainStatsViewText.surgesPotencyLabel,
                  enabled: value >= 2,
                  onPressed: () => onSpendSurges(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddSurgeButton(BuildContext context, int amount) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onAddSurges(amount),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(31, 248, 199, 1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AbilityColors.surge.withOpacity(0.5),
          ),
        ),
        child: Text(
          '+$amount',
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color.fromARGB(255, 217, 119, 6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSurgeButton(
    BuildContext context, {
    required int cost,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? const Color.fromARGB(255, 245, 159, 11).withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          color: enabled
              ? const Color.fromARGB(255, 245, 159, 11).withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$cost${HeroMainStatsViewText.surgeCostSuffix}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? AbilityColors.surgeDark
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the surges info dialog with content from JSON.
Future<void> showSurgesInfoDialog(BuildContext context) async {
  String description = 'Surges allow you to deal extra damage or increase potency.';
  
  try {
    final jsonString = await rootBundle.loadString(
      'data/features/class_features/surges_description.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);
    if (data.isNotEmpty && data[0] is Map) {
      description = data[0]['description'] as String? ?? description;
    }
  } catch (_) {
    // Use default description if loading fails
  }

  if (!context.mounted) return;

  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.electric_bolt_outlined, color: AbilityColors.surge),
            const SizedBox(width: 8),
            const Text('Surges'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
