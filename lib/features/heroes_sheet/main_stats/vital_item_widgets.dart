/// Vital item widgets for displaying stamina, recoveries, etc.
///
/// This file contains widgets for displaying and editing vital stats.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import 'hero_main_stats_models.dart';
import 'hero_stamina_helpers.dart';

/// Callback for persisting a number field.
typedef OnPersistNumberField = Future<void> Function(
    NumericField field, String value);

/// Widget for displaying and editing a vital value.
class VitalItemWidget extends StatelessWidget {
  const VitalItemWidget({
    super.key,
    required this.label,
    required this.value,
    required this.field,
    required this.onPersist,
    this.allowNegative = false,
  });

  final String label;
  final int value;
  final NumericField field;
  final OnPersistNumberField onPersist;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: value.toString());
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              '${HeroMainStatsViewText.vitalItemEditTitlePrefix}$label',
            ),
            content: TextField(
              controller: controller,
              keyboardType:
                  TextInputType.numberWithOptions(signed: allowNegative),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: HeroMainStatsViewText.vitalItemValueLabel,
                border: OutlineInputBorder(),
              ),
              inputFormatters: _formatters(allowNegative, 4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(HeroMainStatsViewText.vitalItemCancelLabel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: const Text(HeroMainStatsViewText.vitalItemSaveLabel),
              ),
            ],
          );
        },
      );
      if (result != null && result.isNotEmpty && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await onPersist(field, result);
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  List<TextInputFormatter> _formatters(bool allowNegative, int maxLength) {
    return [
      allowNegative
          ? FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))
          : FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }
}

/// Widget for displaying a max vital value with breakdown.
class MaxVitalItemWidget extends StatelessWidget {
  const MaxVitalItemWidget({
    super.key,
    required this.label,
    required this.value,
    required this.modKey,
    required this.baseValue,
    required this.choiceValue,
    required this.userValue,
    required this.onShowBreakdown,
    this.equipmentBonus = 0,
    this.featureBonus = 0,
  });

  final String label;
  final int value;
  final String modKey;
  final int baseValue;
  final int choiceValue;
  final int userValue;
  final int equipmentBonus;
  final int featureBonus;
  final Future<void> Function() onShowBreakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherChoice = choiceValue - equipmentBonus;
    final hasBreakdown = equipmentBonus != 0 ||
        otherChoice != 0 ||
        userValue != 0 ||
        featureBonus != 0;

    return InkWell(
      onTap: onShowBreakdown,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                if (hasBreakdown)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 10,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasBreakdown)
                  Text(
                    ' ($baseValue'
                    '${equipmentBonus != 0 ? formatSigned(equipmentBonus) : ''}'
                    '${featureBonus != 0 ? formatSigned(featureBonus) : ''}'
                    '${otherChoice != 0 ? formatSigned(otherChoice) : ''}'
                    '${userValue != 0 ? formatSigned(userValue) : ''})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 9,
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

/// Widget for building a breakdown row in dialogs.
class BreakdownRowWidget extends StatelessWidget {
  const BreakdownRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isBonus = false,
    this.isBold = false,
  });

  final String label;
  final int value;
  final bool isBonus;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = isBonus ? '+$value' : value.toString();
    final color = isBonus
        ? Colors.green
        : (value < 0 ? Colors.red : theme.colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valueText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? null : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact action button for damage/heal actions.
class CompactActionButtonWidget extends StatelessWidget {
  const CompactActionButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
