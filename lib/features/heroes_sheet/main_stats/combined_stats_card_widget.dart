/// Combined stats card widget for characteristics and attributes.
///
/// This file contains the card that displays M/A/R/I/P characteristics
/// and Size/Speed/Disengage/Stability attributes.
library;

import 'package:flutter/material.dart';

import '../../../core/models/hero_mod_keys.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/semantic/semantic_tokens.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import 'hero_stamina_helpers.dart';

/// Callback for editing a stat.
typedef OnEditStat = void Function({
  required String label,
  required String modKey,
  required int baseValue,
  required int currentModValue,
  int featureBonus,
  Color? accentColor,
});

/// Callback for editing size.
typedef OnEditSize = void Function({
  required String sizeBase,
  required int currentModValue,
});

/// Combined attributes and combat stats card with grid layout
class CombinedStatsCardWidget extends StatelessWidget {
  const CombinedStatsCardWidget({
    super.key,
    required this.stats,
    required this.onEditStat,
    required this.onEditSize,
    required this.getUserModValue,
  });

  final HeroMainStats stats;
  final OnEditStat onEditStat;
  final OnEditSize onEditSize;
  final int Function(String modKey) getUserModValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Characteristics section header (M/A/R/I/P)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_outline, size: 14, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.characteristicsSectionTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 5-column characteristic grid
            Row(
              children: [
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.characteristicShortLabelM,
                  stats.mightBase,
                  stats.mightTotal,
                  HeroModKeys.might,
                  HeroMainStatsViewText.characteristicFullLabelMight,
                  accentColor: AppColors.mightColor,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.characteristicShortLabelA,
                  stats.agilityBase,
                  stats.agilityTotal,
                  HeroModKeys.agility,
                  HeroMainStatsViewText.characteristicFullLabelAgility,
                  accentColor: AppColors.agilityColor,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.characteristicShortLabelR,
                  stats.reasonBase,
                  stats.reasonTotal,
                  HeroModKeys.reason,
                  HeroMainStatsViewText.characteristicFullLabelReason,
                  accentColor: AppColors.reasonColor,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.characteristicShortLabelI,
                  stats.intuitionBase,
                  stats.intuitionTotal,
                  HeroModKeys.intuition,
                  HeroMainStatsViewText.characteristicFullLabelIntuition,
                  accentColor: AppColors.intuitionColor,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.characteristicShortLabelP,
                  stats.presenceBase,
                  stats.presenceTotal,
                  HeroModKeys.presence,
                  HeroMainStatsViewText.characteristicFullLabelPresence,
                  accentColor: AppColors.presenceColor,
                ),
              ],
            ),
            // Potency section
            _buildPotencyRow(context, stats),
            Divider(height: 20, color: Colors.grey.shade800),
            // Attributes section header (Size, Speed, Disengage, Stability)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 14, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.attributesSectionTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 4-column attributes grid
            Row(
              children: [
                _buildGridSizeItem(
                    context, stats.sizeBase, stats.sizeTotal, HeroModKeys.size),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.attributeShortLabelSpeed,
                  stats.speedBase,
                  stats.speedTotal,
                  HeroModKeys.speed,
                  HeroMainStatsViewText.attributeFullLabelSpeed,
                  featureBonus: stats.speedFeatureBonus,
                  accentColor: Colors.orange,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.attributeShortLabelDisengage,
                  stats.disengageBase,
                  stats.disengageTotal,
                  HeroModKeys.disengage,
                  HeroMainStatsViewText.attributeFullLabelDisengage,
                  featureBonus: stats.disengageFeatureBonus,
                  accentColor: Colors.orange,
                ),
                _buildGridStatItem(
                  context,
                  HeroMainStatsViewText.attributeShortLabelStability,
                  stats.stabilityBase,
                  stats.stabilityTotal,
                  HeroModKeys.stability,
                  HeroMainStatsViewText.attributeFullLabelStability,
                  featureBonus: stats.stabilityFeatureBonus,
                  accentColor: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build potency row based on class data
  Widget _buildPotencyRow(BuildContext context, HeroMainStats stats) {
    final theme = Theme.of(context);
    final classId = stats.classId;

    if (classId == null || classId.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate potency based on highest characteristic
    final totals = {
      'might': stats.mightTotal,
      'agility': stats.agilityTotal,
      'reason': stats.reasonTotal,
      'intuition': stats.intuitionTotal,
      'presence': stats.presenceTotal,
    };

    return FutureBuilder<Map<String, int>?>(
      future: _computePotencyForClass(classId, totals),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final potencyValues = snapshot.data!;
        const order = ['strong', 'average', 'weak'];

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: order.map((strength) {
              final value = potencyValues[strength] ?? 0;
              final label = strength[0].toUpperCase();
              final color = AppColors.getPotencyColor(strength);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withAlpha(150)),
                    color: color.withAlpha(40),
                  ),
                  child: Text(
                    '$label ${formatSigned(value)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<Map<String, int>?> _computePotencyForClass(
    String classId,
    Map<String, int> totals,
  ) async {
    try {
      final classDataService = ClassDataService();
      await classDataService.initialize();
      final classData = classDataService.getClassById(classId);
      if (classData == null) return null;

      final progression = classData.startingCharacteristics.potencyProgression;
      final baseKey = progression.characteristic.toLowerCase();
      final baseScore = totals[baseKey] ?? 0;
      final result = <String, int>{};
      progression.modifiers.forEach((strength, modifier) {
        result[strength.toLowerCase()] = baseScore + modifier;
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  Widget _buildGridStatItem(
    BuildContext context,
    String shortLabel,
    int baseValue,
    int totalValue,
    String modKey,
    String fullLabel, {
    int featureBonus = 0,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final modValue = totalValue - baseValue;
    final manualMod = getUserModValue(modKey);
    final isPositive = totalValue >= 0;

    return Expanded(
      child: InkWell(
        onTap: () => onEditStat(
          label: fullLabel,
          modKey: modKey,
          baseValue: baseValue,
          currentModValue: manualMod,
          featureBonus: featureBonus,
          accentColor: accentColor,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCharacteristicLabel(shortLabel, theme),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.grey.shade800.withAlpha(150)
                      : Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatSigned(totalValue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? Colors.white
                            : Colors.red.shade400,
                      ),
                    ),
                    if (modValue != 0)
                      Text(
                        modValue > 0 ? ' +$modValue' : ' $modValue',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: modValue > 0
                              ? Colors.green.shade400
                              : Colors.red.shade400,
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

  /// Builds a styled characteristic label (M, A, R, I, P) matching the ability card style.
  Widget _buildCharacteristicLabel(String label, ThemeData theme) {
    // Only apply characteristic colors for M, A, R, I, P
    final isCharacteristic =
        ['M', 'A', 'R', 'I', 'P'].contains(label.toUpperCase());

    if (!isCharacteristic) {
      // For non-characteristic labels (SPD, DIS, STB), use default styling
      return Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade400,
        ),
      );
    }

    final color = CharacteristicTokens.color(label.toUpperCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGridSizeItem(
    BuildContext context,
    String sizeBase,
    String sizeTotal,
    String modKey,
  ) {
    final theme = Theme.of(context);
    // Use progression index difference to calculate mod value
    final baseIndex = HeroMainStats.sizeToIndex(sizeBase);
    final totalIndex = HeroMainStats.sizeToIndex(sizeTotal);
    final modValue = totalIndex - baseIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onEditSize(
          sizeBase: sizeBase,
          currentModValue: modValue,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                HeroMainStatsViewText.sizeShortLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withAlpha(150),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sizeTotal,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (modValue != 0)
                      Text(
                        modValue > 0 ? ' +$modValue' : ' $modValue',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: modValue > 0
                              ? Colors.green.shade400
                              : Colors.red.shade400,
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
