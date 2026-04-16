/// Shared combat dialogs for damage, healing, and amount input.
///
/// Used by both hero and retainer combat UIs to avoid duplicating dialog code.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';

/// Shows a simple numeric input dialog (e.g. for damage or healing).
///
/// Returns the entered integer, or `null` if dismissed.
Future<int?> showCombatAmountDialog(
  BuildContext context, {
  required String title,
  String? description,
  required IconData icon,
  required Color color,
}) async {
  final controller = TextEditingController(text: '1');
  try {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: FormTheme.textBright,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              Text(
                description,
                style: TextStyle(color: FormTheme.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(color: FormTheme.textBright),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: FormTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FormTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FormTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: FormTheme.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v <= 0) {
                Navigator.of(ctx).pop();
              } else {
                Navigator.of(ctx).pop(v);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    return result;
  } finally {
    controller.dispose();
  }
}

/// Shows a healing dialog with an optional "Apply as Temp Stamina" toggle.
///
/// Returns the amount and whether it should be applied as temp stamina,
/// or `null` if dismissed.
Future<({int amount, bool applyToTemp})?> showHealingAmountDialog(
  BuildContext context, {
  required String title,
  String? description,
  bool showTempToggle = true,
}) async {
  final controller = TextEditingController(text: '1');
  try {
    final result = await showDialog<({int amount, bool applyToTemp})>(
      context: context,
      builder: (ctx) {
        bool applyToTemp = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final color = Colors.green.shade400;
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
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.healing, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: FormTheme.textBright,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description != null) ...[
                    Text(
                      description,
                      style: TextStyle(color: FormTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    style: const TextStyle(color: FormTheme.textBright),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: FormTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: FormTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: FormTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: color),
                      ),
                    ),
                  ),
                  if (showTempToggle) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: applyToTemp,
                          onChanged: (v) =>
                              setDialogState(() => applyToTemp = v ?? false),
                          activeColor: Colors.cyan,
                        ),
                        Expanded(
                          child: Text(
                            'Apply as Temporary Stamina',
                            style: TextStyle(
                              color: FormTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: FormTheme.textSecondary),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  onPressed: () {
                    final v = int.tryParse(controller.text.trim());
                    if (v == null || v <= 0) {
                      Navigator.of(ctx).pop();
                    } else {
                      Navigator.of(ctx)
                          .pop((amount: v, applyToTemp: applyToTemp));
                    }
                  },
                  child: const Text('Heal'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  } finally {
    controller.dispose();
  }
}
