/// Respite and Downtime row widget.
///
/// Contains the buttons for taking respite and navigating to downtime.
library;

import 'package:flutter/material.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';

/// Callback for taking respite action.
typedef OnTakeRespite = void Function();

/// Callback for navigating to downtime.
typedef OnNavigateDowntime = void Function();

/// Row with Respite and Downtime buttons
class RespiteDowntimeRowWidget extends StatelessWidget {
  const RespiteDowntimeRowWidget({
    super.key,
    required this.stats,
    required this.onTakeRespite,
    required this.onNavigateDowntime,
  });

  final HeroMainStats stats;
  final OnTakeRespite onTakeRespite;
  final OnNavigateDowntime onNavigateDowntime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTakeRespite,
            icon: const AppIcon(CombatIcons.respite, size: 18),
            label: const Text(HeroMainStatsViewText.respiteButtonLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade400,
              side: BorderSide(color: Colors.blue.shade400.withAlpha(128)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNavigateDowntime,
            icon: const AppIcon(CombatIcons.downtime, size: 18),
            label: const Text(HeroMainStatsViewText.downtimeButtonLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: NavigationTheme.downtimeColor,
              side: BorderSide(color: NavigationTheme.downtimeColor.withAlpha(128)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the respite confirmation dialog.
Future<bool?> showRespiteConfirmDialog(
  BuildContext context,
  HeroMainStats stats,
) async {
  final victories = stats.victories;
  final currentXp = stats.exp;
  final newXp = currentXp + victories;
  final recoveriesMax = stats.recoveriesMaxEffective;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcon(CombatIcons.respite, color: Colors.blue.shade400),
            ),
            const SizedBox(width: 12),
            const Text(
              HeroMainStatsViewText.respiteDialogTitle,
              style: TextStyle(color: FormTheme.textBright),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HeroMainStatsViewText.respiteDialogIntro,
              style: TextStyle(color: FormTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FormTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FormTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon(CombatIcons.victories,
                          size: 16, color: Colors.amber.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${HeroMainStatsViewText.respiteDialogConvertPrefix}$victories ${victories == 1 ? HeroMainStatsViewText.respiteDialogConvertSingular : HeroMainStatsViewText.respiteDialogConvertPlural}${HeroMainStatsViewText.respiteDialogConvertSuffix}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: FormTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppIcon(CombatIcons.experience,
                          size: 16, color: Colors.amber.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${HeroMainStatsViewText.respiteDialogXpPrefix}$currentXp${HeroMainStatsViewText.respiteDialogArrowSeparator}$newXp',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: FormTheme.textBright,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppIcon(CombatIcons.stamina,
                          size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${HeroMainStatsViewText.respiteDialogRecoveriesPrefix}${HeroMainStatsViewText.respiteDialogRecoveriesArrow}$recoveriesMax${HeroMainStatsViewText.respiteDialogRecoveriesSuffix}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: FormTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: FormTheme.textSecondary),
            child: const Text(HeroMainStatsViewText.respiteDialogCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: FormTheme.textBright,
            ),
            child:
                const Text(HeroMainStatsViewText.respiteDialogConfirmLabel),
          ),
        ],
      );
    },
  );
}
