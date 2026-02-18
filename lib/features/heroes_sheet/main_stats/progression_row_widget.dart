/// Progression row widget for displaying Level, XP, Victories, Wealth, Renown.
///
/// This file contains the compact horizontal row for hero progression stats.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icon_data.dart';
import '../../../core/models/hero_mod_keys.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import 'hero_main_stats_models.dart';
import 'hero_stat_insights.dart';
import 'hero_stamina_helpers.dart';

/// Callback types for progression row interactions.
typedef OnEditNumberField = void Function(String label, NumericField field);
typedef OnEditXp = void Function(int currentXp);
typedef OnEditMod = void Function({
  required String title,
  required String modKey,
  required int baseValue,
  required int currentModValue,
  required List<String> insights,
  Color? accentColor,
  AppIconData? icon,
});

/// Compact horizontal row for Level, XP, Victories, Wealth, Renown
class ProgressionRowWidget extends StatelessWidget {
  const ProgressionRowWidget({
    super.key,
    required this.stats,
    required this.onEditNumberField,
    required this.onEditXp,
    required this.onEditMod,
  });

  final HeroMainStats? stats;
  final OnEditNumberField onEditNumberField;
  final OnEditXp onEditXp;
  final OnEditMod onEditMod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = stats?.level ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            // Level - prominent display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(100)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    HeroMainStatsViewText.progressionLevelLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    level.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: FormTheme.textBright,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // XP and Victories
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressionItem(
                    context,
                    icon: CombatIcons.experience,
                    label: HeroMainStatsViewText.progressionXpLabel,
                    field: NumericField.exp,
                  ),
                  _buildProgressionItem(
                    context,
                    icon: CombatIcons.victories,
                    label: HeroMainStatsViewText.progressionVictoriesLabel,
                    field: NumericField.victories,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: FormTheme.border,
            ),
            // Wealth and Renown
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEconomyItem(
                    context,
                    icon: CombatIcons.wealth,
                    label: HeroMainStatsViewText.progressionWealthLabel,
                    baseValue: stats?.wealthBase ?? 0,
                    totalValue: stats?.wealthTotal ?? 0,
                    modKey: HeroModKeys.wealth,
                    insights: generateWealthInsights(stats?.wealthTotal ?? 0),
                    accentColor: Colors.purple.shade400,
                  ),
                  _buildEconomyItem(
                    context,
                    icon: CombatIcons.renown,
                    label: HeroMainStatsViewText.progressionRenownLabel,
                    baseValue: stats?.renownBase ?? 0,
                    totalValue: stats?.renownTotal ?? 0,
                    modKey: HeroModKeys.renown,
                    insights: generateRenownInsights(stats?.renownTotal ?? 0),
                    accentColor: Colors.purple.shade400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionItem(
    BuildContext context, {
    required AppIconData icon,
    required String label,
    required NumericField field,
  }) {
    final theme = Theme.of(context);
    final value =
        stats != null ? getNumberValueFromStats(stats!, field) : 0;

    return InkWell(
      onTap: () {
        if (field == NumericField.exp) {
          onEditXp(value);
        } else {
          onEditNumberField(label, field);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 16, color: Colors.amber.shade400),
            const SizedBox(height: 2),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: FormTheme.textBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomyItem(
    BuildContext context, {
    required AppIconData icon,
    required String label,
    required int baseValue,
    required int totalValue,
    required String modKey,
    required List<String> insights,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final modValue = totalValue - baseValue;
    final color = accentColor ?? Colors.purple.shade400;

    return InkWell(
      onTap: () => onEditMod(
        title: label,
        modKey: modKey,
        baseValue: baseValue,
        currentModValue: modValue,
        insights: insights,
        accentColor: color,
        icon: icon,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalValue.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FormTheme.textBright,
                  ),
                ),
                if (modValue != 0)
                  Text(
                    modValue > 0 ? '+$modValue' : modValue.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: modValue > 0
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
