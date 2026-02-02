/// Dialog functions for editing stats.
///
/// Contains reusable dialog functions for editing various stats like
/// number fields, mods, stats, size, XP, etc.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import '../../../core/theme/navigation_theme.dart';
import 'coin_purse_model.dart';
import 'coin_purse_widget.dart';

/// Common input formatters for numeric fields.
List<TextInputFormatter> numericFormatters(bool allowNegative, int maxLength) {
  return [
    allowNegative
        ? FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))
        : FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(maxLength),
  ];
}

/// Shows a dialog to edit a generic number field.
Future<int?> showNumberEditDialog(
  BuildContext context, {
  required String label,
  required int currentValue,
  bool allowNegative = false,
}) async {
  final controller = TextEditingController(text: currentValue.toString());

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: Colors.blue.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${HeroMainStatsViewText.numberEditTitlePrefix}$label',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade400),
              ),
            ),
            inputFormatters: allowNegative
                ? numericFormatters(true, 4)
                : numericFormatters(false, 3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.numberEditCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.numberEditSaveLabel),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

/// Shows a dialog to edit XP with insights.
Future<int?> showXpEditDialog(
  BuildContext context, {
  required int currentXp,
  required int currentLevel,
  required List<String> insights,
}) async {
  final controller = TextEditingController(text: currentXp.toString());

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star, color: Colors.amber.shade400),
              ),
              const SizedBox(width: 12),
              const Text(
                HeroMainStatsViewText.xpEditTitle,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${HeroMainStatsViewText.xpEditCurrentLevelPrefix}$currentLevel',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.xpEditExperienceLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber.shade400),
                  ),
                ),
                inputFormatters: numericFormatters(false, 3),
              ),
              if (insights.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_graph,
                            size: 16,
                            color: Colors.amber.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            HeroMainStatsViewText.xpEditInsightsTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...insights.map((insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              insight,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.xpEditCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.xpEditSaveLabel),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

/// Shows a dialog to edit a modification value.
Future<int?> showModEditDialog(
  BuildContext context, {
  required String title,
  required int baseValue,
  required int currentModValue,
  required List<String> insights,
  String sourcesDescription = '',
}) async {
  final controller = TextEditingController(text: currentModValue.toString());

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune, color: Colors.purple.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${HeroMainStatsViewText.modEditTitlePrefix}$title',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${HeroMainStatsViewText.modEditBasePrefix}$baseValue',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              if (sourcesDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade400.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.purple.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sourcesDescription,
                          style: TextStyle(
                            color: Colors.purple.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.modEditModificationLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400),
                  ),
                  helperText: HeroMainStatsViewText.modEditHelperText,
                  helperStyle: TextStyle(color: Colors.grey.shade500),
                ),
                inputFormatters: numericFormatters(true, 4),
              ),
              if (insights.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        insight,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.modEditCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.modEditSaveLabel),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

/// Shows a dialog to edit a stat with auto bonuses.
Future<int?> showStatEditDialog(
  BuildContext context, {
  required String label,
  required int baseValue,
  required int currentModValue,
  String autoBonusDescription = '',
}) async {
  final controller = TextEditingController(text: currentModValue.toString());

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: Colors.blue.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${HeroMainStatsViewText.statEditTitlePrefix}$label',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${HeroMainStatsViewText.statEditBasePrefix}$baseValue',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              if (autoBonusDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade400.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          autoBonusDescription,
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.statEditModificationLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade400),
                  ),
                  helperText: HeroMainStatsViewText.statEditHelperText,
                  helperStyle: TextStyle(color: Colors.grey.shade500),
                ),
                inputFormatters: numericFormatters(true, 4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.statEditCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.statEditSaveLabel),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

/// Shows a dialog to edit size.
Future<int?> showSizeEditDialog(
  BuildContext context, {
  required String sizeBase,
  required int currentModValue,
  String sourcesDescription = '',
}) async {
  final controller = TextEditingController(text: currentModValue.toString());
  final parsed = HeroMainStats.parseSize(sizeBase);
  final categoryName = switch (parsed.category) {
    'T' => HeroMainStatsViewText.sizeCategoryTiny,
    'S' => HeroMainStatsViewText.sizeCategorySmall,
    'M' => HeroMainStatsViewText.sizeCategoryMedium,
    'L' => HeroMainStatsViewText.sizeCategoryLarge,
    _ => '',
  };
  final baseDisplay =
      categoryName.isNotEmpty ? '$sizeBase ($categoryName)' : sizeBase;

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.straighten, color: Colors.orange.shade400),
              ),
              const SizedBox(width: 12),
              const Text(
                HeroMainStatsViewText.sizeEditTitle,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${HeroMainStatsViewText.sizeEditBasePrefix}$baseDisplay',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              if (sourcesDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade400.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sourcesDescription,
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.sizeEditModificationLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange.shade400),
                  ),
                  helperText: HeroMainStatsViewText.sizeEditHelperText,
                  helperStyle: TextStyle(color: Colors.grey.shade500),
                ),
                inputFormatters: numericFormatters(true, 4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.sizeEditCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.sizeEditSaveLabel),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

/// Shows a dialog to display max vital breakdown.
Future<void> showMaxVitalBreakdownDialog(
  BuildContext context, {
  required String label,
  required String modKey,
  required int classBase,
  required int equipmentBonus,
  required int featureBonus,
  required int choiceValue,
  required int userValue,
  required int total,
  required Future<void> Function() onEditModifier,
}) async {
  final hasChoice = equipmentBonus != 0 || choiceValue != 0;
  final hasUser = userValue != 0;
  final hasFeature = featureBonus != 0;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.favorite, color: Colors.red.shade400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label${HeroMainStatsViewText.maxVitalBreakdownTitleSuffix}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreakdownRow(
              HeroMainStatsViewText.breakdownClassBaseLabel,
              classBase,
            ),
            if (equipmentBonus > 0)
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownEquipmentLabel,
                equipmentBonus,
                isBonus: equipmentBonus > 0,
              ),
            if (hasFeature)
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownFeaturesLabel,
                featureBonus,
                isBonus: featureBonus > 0,
              ),
            if (hasChoice)
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownChoiceModsLabel,
                choiceValue,
                isBonus: choiceValue >= 0,
              ),
            if (hasUser)
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownManualModsLabel,
                userValue,
                isBonus: userValue >= 0,
              ),
            Divider(color: Colors.grey.shade700),
            _buildBreakdownRow(
              HeroMainStatsViewText.breakdownTotalLabel,
              total,
              isBold: true,
            ),
            const SizedBox(height: 16),
            Text(
              HeroMainStatsViewText.breakdownEditHint,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text(HeroMainStatsViewText.breakdownCloseLabel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await onEditModifier();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child:
                const Text(HeroMainStatsViewText.breakdownEditModifierLabel),
          ),
        ],
      );
    },
  );
}

Widget _buildBreakdownRow(String label, int value,
    {bool isBonus = false, bool isBold = false}) {
  final valueText = isBonus ? '+$value' : value.toString();
  final color = isBonus
      ? Colors.green.shade400
      : (value < 0 ? Colors.red.shade400 : Colors.white);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.white : Colors.grey.shade300,
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.red.shade400 : color,
          ),
        ),
      ],
    ),
  );
}

/// Shows a dialog to prompt for an amount (damage/healing).
Future<int?> promptForAmount(
  BuildContext context, {
  required String title,
  String? description,
}) async {
  final controller = TextEditingController(text: '1');

  try {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.favorite_border, color: Colors.red.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null) ...[
                Text(description, style: TextStyle(color: Colors.grey.shade300)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: numericFormatters(false, 3),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.promptAmountLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red.shade400),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.promptCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  Navigator.of(dialogContext).pop();
                } else {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.promptApplyLabel),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();
  }
}

/// Shows a dialog to prompt for healing amount with temp option.
Future<({int amount, bool applyToTemp})?> promptForHealingAmount(
  BuildContext context, {
  required String title,
  String? description,
}) async {
  final controller = TextEditingController(text: '1');

  try {
    final result = await showDialog<({int amount, bool applyToTemp})>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.healing, color: Colors.green.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null) ...[
                Text(description, style: TextStyle(color: Colors.grey.shade300)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: numericFormatters(false, 3),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: HeroMainStatsViewText.promptAmountLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(HeroMainStatsViewText.promptCancelLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  Navigator.of(dialogContext).pop();
                } else {
                  Navigator.of(dialogContext).pop(
                    (amount: value, applyToTemp: true),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.promptApplyTempLabel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  Navigator.of(dialogContext).pop();
                } else {
                  Navigator.of(dialogContext).pop(
                    (amount: value, applyToTemp: false),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text(HeroMainStatsViewText.promptApplyLabel),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();
  }
}

/// Shows a dice roll confirmation dialog for resource generation.
Future<int?> showDiceRollDialog(
  BuildContext context, {
  required int rolledValue,
  required List<int> alternatives,
  required String diceType,
  Map<int, int>? diceToValueMapping,
}) async {
  // Find which dice roll corresponds to the rolled value
  int? rolledDice;
  if (diceToValueMapping != null) {
    for (final entry in diceToValueMapping.entries) {
      if (entry.value == rolledValue) {
        rolledDice = entry.key;
        break;
      }
    }
  }

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.casino, color: Colors.purple.shade400),
            ),
            const SizedBox(width: 12),
            Text(
              '$diceType${HeroMainStatsViewText.diceRollTitleSuffix}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rolledDice != null && diceToValueMapping != null) ...[
              Text(
                '${HeroMainStatsViewText.diceRolledDicePrefix}$rolledDice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.purple.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${HeroMainStatsViewText.diceGainPrefix}$rolledValue${HeroMainStatsViewText.diceGainSuffix}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.amber.shade400,
                ),
              ),
            ] else
              Text(
                '${HeroMainStatsViewText.diceRolledValuePrefix}$rolledValue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.purple.shade400,
                ),
              ),
            const SizedBox(height: 16),
            // Show the dice-to-value mapping table if available
            if (diceToValueMapping != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  children: [
                    Text(
                      HeroMainStatsViewText.diceRollValuesTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: diceToValueMapping.entries.map((entry) {
                        final isRolled = entry.key == rolledDice;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isRolled
                                ? Colors.purple.withAlpha(60)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isRolled
                                ? Border.all(
                                    color: Colors.purple.shade400,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${entry.key}',
                                style: TextStyle(
                                  fontWeight: isRolled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '+${entry.value}',
                                style: TextStyle(
                                  color: Colors.purple.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              HeroMainStatsViewText.diceAcceptPrompt,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: alternatives.map((value) {
                final isRolled = value == rolledValue;
                return ActionChip(
                  label: Text(
                    '+$value',
                    style: TextStyle(
                      fontWeight:
                          isRolled ? FontWeight.bold : FontWeight.normal,
                      color: isRolled ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                  backgroundColor:
                      isRolled ? Colors.purple.shade600 : Colors.grey.shade800,
                  side: isRolled
                      ? BorderSide(color: Colors.purple.shade400, width: 2)
                      : BorderSide(color: Colors.grey.shade700),
                  onPressed: () => Navigator.of(dialogContext).pop(value),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text(HeroMainStatsViewText.diceCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(rolledValue),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(
              '${HeroMainStatsViewText.diceAcceptPrefix}$rolledValue',
            ),
          ),
        ],
      );
    },
  );
}

/// Shows a dialog to edit wealth with coin purse.
/// Returns a tuple of (modValue, coinPurse) or null if cancelled.
Future<(int, CoinPurse)?> showWealthEditDialog(
  BuildContext context, {
  required int baseValue,
  required int currentModValue,
  required CoinPurse coinPurse,
  required List<String> insights,
  String sourcesDescription = '',
}) async {
  final controller = TextEditingController(text: currentModValue.toString());
  CoinPurse localPurse = coinPurse;

  try {
    final result = await showDialog<(int, CoinPurse)?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: NavigationTheme.cardBackgroundDark,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade800),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.paid, color: Colors.purple.shade400),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Modify Wealth',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${HeroMainStatsViewText.modEditBasePrefix}$baseValue',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                      if (sourcesDescription.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.purple.shade400.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Colors.purple.shade400,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sourcesDescription,
                                  style: TextStyle(
                                    color: Colors.purple.shade300,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: HeroMainStatsViewText.modEditModificationLabel,
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.purple.shade400),
                          ),
                          helperText: HeroMainStatsViewText.modEditHelperText,
                          helperStyle: TextStyle(color: Colors.grey.shade500),
                        ),
                        inputFormatters: numericFormatters(true, 4),
                      ),
                      if (insights.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...insights.map((insight) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                insight,
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12),
                              ),
                            )),
                      ],
                      const SizedBox(height: 16),
                      CoinPurseWidget(
                        coinPurse: localPurse,
                        onChanged: (newPurse) {
                          setState(() {
                            localPurse = newPurse;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400),
                  child: const Text(HeroMainStatsViewText.modEditCancelLabel),
                ),
                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text);
                    if (value != null) {
                      Navigator.of(dialogContext).pop((value, localPurse));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(HeroMainStatsViewText.modEditSaveLabel),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  } finally {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.dispose();
  }
}

