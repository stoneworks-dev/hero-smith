/// Hero Tokens section widget.
///
/// This file contains the widget that displays the party's hero tokens
/// with gain and spend buttons for various effects.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/hero_repository.dart';
import 'hero_main_stats_models.dart';
import '../../../core/theme/main_stats_theme.dart';

/// Hero token color - Royal Purple for heroic deeds
class HeroTokenColors {
  HeroTokenColors._();
  
  static const Color primary = Color.fromARGB(255, 124, 106, 255);
  static const Color light = MainStatsTheme.heroTokenLight;
  static const Color dark = Color.fromARGB(255, 70, 52, 196);
}

/// Callback for editing a number field.
typedef OnEditNumberField = void Function(String label, NumericField field);

/// Callback for gaining hero tokens.
typedef OnGainHeroToken = void Function(int amount);

/// Callback for spending hero tokens to gain surges.
typedef OnSpendForSurges = void Function(int tokenCost, int surgesGained);

/// Callback for spending hero tokens to regain stamina.
typedef OnSpendForStamina = void Function(int tokenCost, int staminaAmount);

/// Callback for spending hero tokens (generic - succeed save, reroll).
typedef OnSpendHeroTokens = void Function(int amount);

/// Hero Tokens section widget.
class HeroTokensSectionWidget extends StatelessWidget {
  const HeroTokensSectionWidget({
    super.key,
    required this.stats,
    required this.onEditNumberField,
    required this.onGainHeroToken,
    required this.onSpendForSurges,
    required this.onSpendForStamina,
    required this.onSpendHeroTokens,
    required this.onShowInfo,
  });

  final HeroMainStats stats;
  final OnEditNumberField onEditNumberField;
  final OnGainHeroToken onGainHeroToken;
  final OnSpendForSurges onSpendForSurges;
  final OnSpendForStamina onSpendForStamina;
  final OnSpendHeroTokens onSpendHeroTokens;
  final void Function(BuildContext context) onShowInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = stats.heroTokensCurrent;
    final recoveryValue = stats.recoveryValueEffective;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HeroTokenColors.light.withOpacity(0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HeroTokenColors.primary.withOpacity(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and info button
          Row(
            children: [
              const Icon(Icons.stars_outlined,
                  size: 16, color: HeroTokenColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hero Tokens',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HeroTokenColors.primary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onShowInfo(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.info_outline,
                      size: 16, color: HeroTokenColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value display (tappable to edit)
          Row(
            children: [
              InkWell(
                onTap: () => onEditNumberField(
                  'Hero Tokens',
                  NumericField.heroTokensCurrent,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    value.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HeroTokenColors.primary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Gain token button
              _buildGainButton(context),
            ],
          ),
          const SizedBox(height: 8),
          // Spend options
          Text(
            'Spend Tokens:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildSpendButton(
                context,
                label: '+2 Surges',
                cost: 1,
                enabled: value >= 1,
                onPressed: () => onSpendForSurges(1, 2),
              ),
              _buildSpendButton(
                context,
                label: 'Succeed Save',
                cost: 1,
                enabled: value >= 1,
                onPressed: () => onSpendHeroTokens(1),
              ),
              _buildSpendButton(
                context,
                label: 'Reroll Test',
                cost: 1,
                enabled: value >= 1,
                onPressed: () => onSpendHeroTokens(1),
              ),
              _buildSpendButton(
                context,
                label: '+$recoveryValue Stamina',
                cost: 2,
                enabled: value >= 2,
                onPressed: () => onSpendForStamina(2, recoveryValue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGainButton(BuildContext context) {
    final theme = Theme.of(context);
    final canGain = stats.heroTokensCurrent < 99;

    return InkWell(
      onTap: canGain ? () => onGainHeroToken(1) : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: canGain
              ? HeroTokenColors.primary.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: canGain
                ? HeroTokenColors.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 14,
              color: canGain
                  ? HeroTokenColors.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Gain Token',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: canGain
                    ? HeroTokenColors.light
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendButton(
    BuildContext context, {
    required String label,
    required int cost,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? HeroTokenColors.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          color: enabled
              ? HeroTokenColors.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: enabled
                    ? HeroTokenColors.light.withOpacity(0.2)
                    : theme.colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '$cost',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? HeroTokenColors.light
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the hero tokens info dialog with content from JSON.
Future<void> showHeroTokensInfoDialog(BuildContext context) async {
  String description = 'Hero tokens allow your party to perform heroic feats.';
  
  try {
    final jsonString = await rootBundle.loadString(
      'data/features/class_features/hero_tokens.json',
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
            const Icon(Icons.stars_outlined, color: HeroTokenColors.primary),
            const SizedBox(width: 8),
            const Text('Hero Tokens'),
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

