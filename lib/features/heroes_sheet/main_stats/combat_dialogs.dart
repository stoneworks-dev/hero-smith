/// Shared combat dialogs for damage, healing, and amount input.
///
/// Used by both hero and retainer combat UIs to avoid duplicating dialog code.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';

/// The combat-state adjustment selected in [showStaminaFateDialog].
enum StaminaFate { damage, heal, tempStamina }

/// Compact shared damage/healing control used by heroes and followers.
class StaminaFateButton extends StatelessWidget {
  const StaminaFateButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
  });

  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 34,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Colors.red.shade600,
                Colors.red.shade400,
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.2),
            child: Material(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(
                      CombatIcons.damage,
                      size: 15,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 22),
                    AppIcon(
                      CombatIcons.heal,
                      size: 15,
                      color: Colors.green.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prompts for one companion stamina adjustment.
///
/// The dialog deliberately combines the three possible outcomes so the
/// companion's combat control opens a single decision point instead of a
/// separate prompt for damage and healing. [showDialog] is barrier-dismissible
/// by default; the close button provides an explicit alternative.
Future<({int amount, StaminaFate fate})?> showStaminaFateDialog(
  BuildContext context,
) async {
  return showDialog<({int amount, StaminaFate fate})>(
    context: context,
    builder: (ctx) {
      var amountText = '1';
      String? error;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          void choose(StaminaFate fate) {
            final amount = int.tryParse(amountText.trim());
            if (amount == null || amount <= 0) {
              setDialogState(() => error = 'Enter a positive amount.');
              return;
            }
            Navigator.of(ctx).pop((amount: amount, fate: fate));
          }

          return AlertDialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: FormTheme.borderDim),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'What Will Your Fate Be?',
                    style: TextStyle(
                      color: FormTheme.textBright,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: FormTheme.textSecondary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what happens next.',
                  style: TextStyle(color: FormTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: amountText,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) {
                    amountText = value;
                    if (error != null) setDialogState(() => error = null);
                  },
                  style: const TextStyle(color: FormTheme.textBright),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    errorText: error,
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
                      borderSide: BorderSide(color: Colors.amber.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _fateButton(
                        label: 'Damage',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.red.shade600,
                        onPressed: () => choose(StaminaFate.damage),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _fateButton(
                        label: 'Heal',
                        icon: Icons.favorite_rounded,
                        color: Colors.green.shade600,
                        onPressed: () => choose(StaminaFate.heal),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _fateButton(
                        label: 'Temp Stamina',
                        icon: Icons.shield_rounded,
                        color: Colors.cyan.shade600,
                        onPressed: () => choose(StaminaFate.tempStamina),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _fateButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.18),
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: color.withValues(alpha: 0.55)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9),
        ),
      ],
    ),
  );
}

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
