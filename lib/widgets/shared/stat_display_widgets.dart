/// Shared stat display widgets for characteristics and attributes.
///
/// Extracted from [CombinedStatsCardWidget] so both hero and retainer
/// UIs can share the same visual language.
library;

import 'package:flutter/material.dart';

import '../../core/theme/form_theme.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import '../../features/heroes_sheet/main_stats/hero_stamina_helpers.dart';

// ---------------------------------------------------------------------------
// Characteristic badge  (M / A / R / I / P)
// ---------------------------------------------------------------------------

/// Colored rounded badge for a single characteristic letter.
///
/// For the five characteristics (M, A, R, I, P) it renders a tinted
/// background with a matching border.  Other labels fall back to a plain
/// secondary‑text style.
class CharacteristicBadge extends StatelessWidget {
  const CharacteristicBadge(this.label, {super.key});

  final String label;

  static const _characteristics = {'M', 'A', 'R', 'I', 'P'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upper = label.toUpperCase();

    if (!_characteristics.contains(upper)) {
      return Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: FormTheme.textSecondary,
        ),
      );
    }

    final color = CharacteristicTokens.color(upper);
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
}

// ---------------------------------------------------------------------------
// Read‑only stat tile  (label + value pill)
// ---------------------------------------------------------------------------

/// A single stat tile with a [CharacteristicBadge] label and a value pill.
///
/// Wraps itself in [Expanded] so it can sit in a [Row] alongside siblings.
/// An optional [modValue] renders a small delta indicator next to the total.
/// When [onTap] is provided the tile becomes tappable.
class StatGridTile extends StatelessWidget {
  const StatGridTile({
    super.key,
    required this.label,
    required this.value,
    this.modValue = 0,
    this.onTap,
  });

  final String label;
  final int value;
  final int modValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = value >= 0;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacteristicBadge(label),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive
                  ? FormTheme.surfaceMuted
                  : Colors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatSigned(value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? FormTheme.textBright
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
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return Expanded(child: content);
  }
}
