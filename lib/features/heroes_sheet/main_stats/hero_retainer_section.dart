import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/retainer.dart';
import '../../../core/models/retainer_instance.dart';
import '../../../core/services/retainer_advancement_service.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';
import '../../../widgets/retainers/add_retainer_dialog.dart';
import '../../../widgets/retainers/retainer_template_card.dart';
import '../../../widgets/shared/expandable_card.dart';
import '../../../widgets/shared/section_widgets.dart';
import '../../../widgets/shared/stat_display_widgets.dart';
import 'combat_dialogs.dart';
import 'hero_stamina_helpers.dart';
import 'stamina_bar_widget.dart';

/// A compact retainer section that lives on the hero main stats page.
///
/// Displays the hero's active retainer with computed stats, stamina tracking,
/// advancement choices, and name editing. Shows a prompt to add one when empty.
class HeroRetainerSection extends ConsumerWidget {
  final String heroId;
  const HeroRetainerSection({super.key, required this.heroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instanceAsync = ref.watch(heroRetainerProvider(heroId));
    final instance = instanceAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            AppIcon(DowntimeIcons.follower,
                color: retainerAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              'Retainer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: retainerAccent,
              ),
            ),
            const Spacer(),
            if (instance != null) ...[
              // Swap retainer
              IconButton(
                icon: Icon(Icons.swap_horiz_rounded,
                    color: retainerAccent.withValues(alpha: 0.7), size: 20),
                tooltip: 'Change Retainer',
                onPressed: () => _showAddDialog(context, ref, replaceId: instance.id),
                visualDensity: VisualDensity.compact,
              ),
              // Remove retainer
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade300, size: 20),
                tooltip: 'Remove Retainer',
                onPressed: () => _confirmRemove(context, ref, instance),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (instance == null)
          _buildEmptyState(context, ref)
        else
          _RetainerStatsCard(heroId: heroId, instance: instance),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showAddDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: retainerAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: retainerAccent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            AppIcon(DowntimeIcons.addFollower,
                color: retainerAccent.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text(
              'No retainer assigned',
              style: TextStyle(
                fontSize: 13,
                color: FormTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add a retainer',
              style: TextStyle(
                fontSize: 11,
                color: retainerAccent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, {String? replaceId}) {
    showDialog(
      context: context,
      builder: (_) => AddRetainerDialog(
        onRetainerSelected: (retainer) async {
          final repo = ref.read(retainerRepositoryProvider);
          // Remove existing retainer first if swapping
          if (replaceId != null) {
            await repo.removeRetainer(replaceId);
          }
          await repo.addRetainer(
            heroId: heroId,
            retainerComponentId: retainer.id,
            name: retainer.name,
            role: retainer.role,
            startingLevel: retainer.startingLevel,
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    RetainerInstance instance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade300, size: 24),
            const SizedBox(width: 8),
            const Text('Remove Retainer',
                style: TextStyle(color: FormTheme.textBright)),
          ],
        ),
        content: Text(
          'Remove ${instance.name}? This will clear all advancement choices.',
          style: TextStyle(color: FormTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade300),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(retainerRepositoryProvider);
      await repo.removeRetainer(instance.id);
    }
  }
}

/// Displays the active retainer's computed stats with combat state tracking.
class _RetainerStatsCard extends ConsumerWidget {
  final String heroId;
  final RetainerInstance instance;
  const _RetainerStatsCard({required this.heroId, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(heroRetainerTemplateProvider(heroId));
    final statsAsync = ref.watch(heroRetainerStatsProvider(heroId));

    final template = templateAsync.valueOrNull;
    final stats = statsAsync.valueOrNull;

    if (template == null || stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final accent = retainerRoleColor(instance.role);
    final textColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);

    return ExpandableCard(
      title: instance.name,
      borderColor: accent,
      leading: AppIcon(DowntimeIcons.follower, color: accent, size: 20),
      badge: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleBadge(accent),
          const SizedBox(width: 6),
          _levelButton(context, ref, accent),
        ],
      ),
      subtitle: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showRenameDialog(context, ref),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 12, color: accent.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              'Tap to rename',
              style: TextStyle(
                fontSize: 10,
                color: accent.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      preview: _buildPreview(context, ref, stats, textColor, accent),
      expandedContent:
          _buildExpanded(context, ref, stats, template, textColor, accent),
    );
  }

  Widget _roleBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${instance.role[0].toUpperCase()}${instance.role.substring(1)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  /// Button-style level chip shown beside the retainer's name. Displays the
  /// current level with a small "tap to level" hint and opens the level
  /// up/down dialog on tap (retainers level independently of their hero).
  /// When the hero has out-leveled the retainer it highlights with a
  /// "tap to level up" prompt.
  Widget _levelButton(BuildContext context, WidgetRef ref, Color accent) {
    final canLevelUp =
        ref.watch(heroRetainerLevelUpAvailableProvider(heroId)).valueOrNull ??
            false;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showLevelDialog(context, ref, accent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: canLevelUp ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: canLevelUp ? 0.7 : 0.4),
            width: canLevelUp ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lv ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${instance.level}',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                if (canLevelUp) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_upward_rounded, size: 14, color: accent),
                ],
              ],
            ),
            Text(
              canLevelUp ? 'tap to level up' : 'tap to level',
              style: TextStyle(
                fontSize: 8,
                fontStyle: FontStyle.italic,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog with −/+ steppers to level the retainer up or down.
  Future<void> _showLevelDialog(
      BuildContext context, WidgetRef ref, Color accent) async {
    final repo = ref.read(retainerRepositoryProvider);
    var level = instance.level;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: FormTheme.borderDim),
          ),
          title: const Text('Retainer Level',
              style: TextStyle(color: FormTheme.textBright, fontSize: 16)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepButton(
                icon: Icons.remove,
                enabled: level > 1,
                onTap: () {
                  setDialogState(() => level--);
                  repo.setLevel(instance.id, level);
                },
              ),
              const SizedBox(width: 24),
              Text(
                '$level',
                style: TextStyle(
                  color: accent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              _stepButton(
                icon: Icons.add,
                enabled: level < 10,
                onTap: () {
                  setDialogState(() => level++);
                  repo.setLevel(instance.id, level);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? FormTheme.surfaceDark
              : FormTheme.surfaceDark.withValues(alpha: 0.4),
          border: Border.all(
            color: enabled ? FormTheme.borderLight : FormTheme.borderDim,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? FormTheme.textBright : FormTheme.textMuted,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview (collapsed)
  // ---------------------------------------------------------------------------

  Widget _buildPreview(
    BuildContext context,
    WidgetRef ref,
    RetainerStats stats,
    Color textColor,
    Color accent,
  ) {
    final currentStamina = instance.currentStamina ?? stats.stamina;
    final maxStamina = stats.stamina;
    final hasPending = stats.pendingCharacteristicChoices.isNotEmpty ||
        stats.pendingAdvancementChoices.isNotEmpty;
    final staminaState = calculateStaminaStateFromValues(
      currentStamina: currentStamina,
      maxStamina: maxStamina,
    );
    final recoveryHealAmount = maxStamina ~/ 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stamina state label
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: staminaState.color),
            const SizedBox(width: 4),
            Text(
              staminaState.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: staminaState.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Full-width stamina bar (reused from hero).
        StaminaBarWidget(
          maxStamina: maxStamina,
          currentStamina: currentStamina,
          tempHp: instance.tempStamina,
          staminaState: staminaState,
        ),
        const SizedBox(height: 4),
        // Current / Temp / Max values with the shared compact fate control.
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showStaminaEditDialog(
                        context, ref, currentStamina, maxStamina),
                    child:
                        _vitalItem('Current', currentStamina, staminaState.color),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        _showTempEditDialog(context, ref, instance.tempStamina),
                    child: _vitalItem(
                        'Temp', instance.tempStamina, Colors.cyan.shade300),
                  ),
                  const SizedBox(width: 12),
                  _vitalItem(
                    'Max',
                    maxStamina,
                    textColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StaminaFateButton(
              semanticLabel: 'Change retainer stamina',
              onPressed: () => _showStaminaFateDialog(
                context,
                ref,
                currentStamina,
                maxStamina,
              ),
            ),
          ],
        ),
        const Divider(height: 16),
        // Recoveries row
        Row(
          children: [
            Icon(Icons.shield_rounded,
                size: 14, color: Colors.amber.shade400),
            const SizedBox(width: 6),
            Text(
              'Recoveries',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade400,
              ),
            ),
            const SizedBox(width: 12),
            _vitalItem('Left', instance.currentRecoveries,
                instance.currentRecoveries > 0
                    ? Colors.amber.shade400
                    : Colors.grey.shade600),
            const SizedBox(width: 8),
            _vitalItem(
                'Max', RetainerInstance.maxRecoveries, textColor.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            _vitalItem('Heal', recoveryHealAmount, Colors.green.shade400),
            const Spacer(),
            FilledButton.tonal(
              onPressed: instance.currentRecoveries > 0
                  ? () => _useRecovery(ref, currentStamina, maxStamina)
                  : null,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: const Color.fromARGB(255, 37, 42, 40),
                foregroundColor: Colors.amber.shade400,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14,
                      color: instance.currentRecoveries > 0
                          ? Colors.amber.shade400
                          : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Use',
                    style: TextStyle(
                      fontSize: 11,
                      color: instance.currentRecoveries > 0
                          ? Colors.amber.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasPending) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(
              '⚠ Choices pending',
              style: TextStyle(fontSize: 10, color: Colors.amber.shade300),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Expanded content
  // ---------------------------------------------------------------------------

  Widget _buildExpanded(
    BuildContext context,
    WidgetRef ref,
    RetainerStats stats,
    Retainer template,
    Color textColor,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Characteristics
        SectionLabel('Characteristics',
            icon: DowntimeIcons.followerSkills, color: accent),
        const SizedBox(height: 4),
        _buildCharacteristics(stats),

        // Core stats
        const SizedBox(height: 8),
        SectionLabel('Stats', color: accent),
        const SizedBox(height: 4),
        _buildCoreStats(stats),

        // Sig damage bonuses
        if (stats.signatureDamageBonusTier1 > 0 ||
            stats.signatureDamageBonusTier2_3 > 0) ...[
          const SizedBox(height: 8),
          SectionLabel('Signature Damage Bonus', color: accent),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 12,
              children: [
                if (stats.signatureDamageBonusTier1 > 0)
                  _chip('Tier 1: +${stats.signatureDamageBonusTier1}',
                      textColor),
                if (stats.signatureDamageBonusTier2_3 > 0)
                  _chip('Tier 2/3: +${stats.signatureDamageBonusTier2_3}',
                      textColor),
              ],
            ),
          ),
        ],

        // Immunities / Weaknesses
        if (stats.immunities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Immunities', color: accent),
          const SizedBox(height: 2),
          _buildTagList(stats.immunities, textColor),
        ],
        if (stats.weaknesses.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Weaknesses', color: Colors.red.shade300),
          const SizedBox(height: 2),
          _buildTagList(stats.weaknesses, textColor),
        ],

        // Movement modes
        if (stats.movementModes.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Movement', color: accent),
          const SizedBox(height: 2),
          _buildTagList(
            stats.movementModes
                .map((m) => '${m[0].toUpperCase()}${m.substring(1)}')
                .toList(),
            textColor,
          ),
        ],

        // Passive traits
        if (stats.passiveTraits.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Passive Traits', color: accent),
          const SizedBox(height: 4),
          ...stats.passiveTraits.map((t) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    if (t.description.isNotEmpty)
                      Text(t.description,
                          style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.8))),
                  ],
                ),
              )),
        ],

        // Signature ability
        const SizedBox(height: 8),
        SectionLabel('Signature Ability', color: accent),
        const SizedBox(height: 4),
        _buildAbilityLookup(stats.signatureAbilityId, ref, textColor, accent),

        // Base abilities (maneuvers, triggered actions, etc.)
        if (stats.baseAbilityIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Abilities', color: accent),
          const SizedBox(height: 4),
          ...stats.baseAbilityIds.map((id) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildAbilityLookup(id, ref, textColor, accent),
              )),
        ],

        // Advancement abilities
        if (stats.advancementAbilityIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Advancement Abilities', color: accent),
          const SizedBox(height: 4),
          ...stats.advancementAbilityIds.map((id) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildAbilityLookup(id, ref, textColor, accent),
              )),
        ],

        // Level bonuses — always visible for editing
        const SizedBox(height: 8),
        _buildLevelBonuses(context, ref, stats, template, textColor, accent),

        // Respite button
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () => _resetStaminaOnRespite(context, ref, stats),
            icon: Icon(Icons.hotel_rounded,
                size: 16, color: accent.withValues(alpha: 0.8)),
            label: Text(
              'Respite — Restore Stamina',
              style: TextStyle(
                  fontSize: 11, color: accent.withValues(alpha: 0.8)),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pending choices (actionable)
  // ---------------------------------------------------------------------------

  /// Always-visible level bonuses section.
  ///
  /// Shows every applicable characteristic choice (levels 2, 8) and
  /// advancement ability choice (levels 4, 7, 10) that are within range.
  /// Already-made choices display the selection with a "Change" affordance.
  /// Pending choices display an amber prompt.
  Widget _buildLevelBonuses(
    BuildContext context,
    WidgetRef ref,
    RetainerStats stats,
    Retainer template,
    Color textColor,
    Color accent,
  ) {
    // Determine which levels are applicable
    final startLvl = template.startingLevel;
    final effectiveLvl = stats.level;

    // Characteristic choice levels (2, 8) — level 5 is auto and not shown
    final charLevels = [2, 8]
        .where((l) => l > startLvl && l <= effectiveLvl)
        .toList();

    // Advancement ability choice levels (4, 7, 10)
    final advLevels = [4, 7, 10]
        .where((l) => l >= startLvl && l <= effectiveLvl)
        .toList();

    if (charLevels.isEmpty && advLevels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Level Bonuses', color: accent),
        const SizedBox(height: 4),
        for (final lvl in charLevels) ...[
          _buildCharacteristicChoiceRow(
            context, ref, lvl, stats, accent, textColor),
          const SizedBox(height: 4),
        ],
        for (final lvl in advLevels) ...[
          _buildAdvancementChoiceRow(
            context, ref, lvl, stats, template, accent, textColor),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildCharacteristicChoiceRow(
    BuildContext context,
    WidgetRef ref,
    int level,
    RetainerStats stats,
    Color accent,
    Color textColor,
  ) {
    final chosen = instance.characteristicChoices[level];
    final isPending = chosen == null || chosen.isEmpty;
    final color = isPending ? Colors.amber.shade300 : accent;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showCharacteristicChoiceDialog(
          context, ref, level, stats, accent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPending
              ? Colors.amber.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPending
                ? Colors.amber.withValues(alpha: 0.15)
                : accent.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isPending
                    ? 'Level $level: Choose a characteristic +1'
                    : 'Level $level: ${_capitalise(chosen)} +1',
                style: TextStyle(
                  fontSize: 10,
                  color: isPending ? Colors.amber.shade200 : textColor,
                ),
              ),
            ),
            Icon(
              isPending ? Icons.chevron_right_rounded : Icons.edit_outlined,
              size: 14,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancementChoiceRow(
    BuildContext context,
    WidgetRef ref,
    int level,
    RetainerStats stats,
    Retainer template,
    Color accent,
    Color textColor,
  ) {
    final chosen = instance.advancementChoices[level];
    final isPending = chosen == null || chosen.isEmpty;
    final color = isPending ? Colors.amber.shade300 : accent;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showAdvancementChoiceDialog(
          context, ref, level, template, accent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPending
              ? Colors.amber.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPending
                ? Colors.amber.withValues(alpha: 0.15)
                : accent.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isPending
                    ? 'Level $level: Choose an advancement ability'
                    : 'Level $level: ${_prettifyId(chosen)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isPending ? Colors.amber.shade200 : textColor,
                ),
              ),
            ),
            Icon(
              isPending ? Icons.chevron_right_rounded : Icons.edit_outlined,
              size: 14,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ---------------------------------------------------------------------------
  // Combat state mutations
  // ---------------------------------------------------------------------------

  /// Use a recovery: spend one recovery, heal stamina by recovery value
  /// (one-third max stamina, rounded down).
  void _useRecovery(WidgetRef ref, int currentStamina, int maxStamina) {
    if (instance.currentRecoveries <= 0) return;
    final healAmount = maxStamina ~/ 3;
    final newStamina = math.min(currentStamina + healAmount, maxStamina);
    final repo = ref.read(retainerRepositoryProvider);
    repo.updateCombatState(
      instance.id,
      currentStamina: newStamina,
      currentRecoveries: instance.currentRecoveries - 1,
    );
  }

  Future<void> _showStaminaFateDialog(
    BuildContext context,
    WidgetRef ref,
    int currentStamina,
    int maxStamina,
  ) async {
    final result = await showStaminaFateDialog(context);
    if (result == null || result.amount <= 0) return;
    final repo = ref.read(retainerRepositoryProvider);
    switch (result.fate) {
      case StaminaFate.damage:
        var temp = instance.tempStamina;
        var current = currentStamina;
        if (result.amount <= temp) {
          temp -= result.amount;
        } else {
          current -= result.amount - temp;
          temp = 0;
        }
        final halfMax = maxStamina ~/ 2;
        current = current.clamp(-halfMax, maxStamina);
        repo.updateCombatState(
          instance.id,
          currentStamina: current,
          tempStamina: temp,
        );
        break;
      case StaminaFate.heal:
        final healed = math.min(currentStamina + result.amount, maxStamina);
        repo.updateCombatState(instance.id, currentStamina: healed);
        break;
      case StaminaFate.tempStamina:
        repo.updateCombatState(
          instance.id,
          tempStamina: instance.tempStamina + result.amount,
        );
        break;
    }
  }

  Future<void> _resetStaminaOnRespite(
    BuildContext context,
    WidgetRef ref,
    RetainerStats stats,
  ) async {
    final repo = ref.read(retainerRepositoryProvider);
    await repo.updateCombatState(
      instance.id,
      currentStamina: stats.stamina,
      tempStamina: 0,
      currentRecoveries: RetainerInstance.maxRecoveries,
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _showStaminaEditDialog(
    BuildContext context,
    WidgetRef ref,
    int currentValue,
    int maxStamina,
  ) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: const Text('Edit Stamina',
            style: TextStyle(color: FormTheme.textBright, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
            LengthLimitingTextInputFormatter(5),
          ],
          style: const TextStyle(color: FormTheme.textBright),
          decoration: InputDecoration(
            hintText: 'Max: $maxStamina',
            hintStyle: TextStyle(color: FormTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      final halfMax = maxStamina ~/ 2;
      final clamped = result.clamp(-halfMax, maxStamina);
      ref
          .read(retainerRepositoryProvider)
          .updateCombatState(instance.id, currentStamina: clamped);
    }
  }

  Future<void> _showTempEditDialog(
    BuildContext context,
    WidgetRef ref,
    int currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: const Text('Edit Temp Stamina',
            style: TextStyle(color: FormTheme.textBright, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: const TextStyle(color: FormTheme.textBright),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      ref
          .read(retainerRepositoryProvider)
          .updateCombatState(instance.id, tempStamina: math.max(0, result));
    }
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: instance.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: const Text('Rename Retainer',
            style: TextStyle(color: FormTheme.textBright, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: FormTheme.textBright),
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: FormTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.of(ctx).pop(name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result != instance.name) {
      ref.read(retainerRepositoryProvider).updateName(instance.id, result);
    }
  }

  Future<void> _showCharacteristicChoiceDialog(
    BuildContext context,
    WidgetRef ref,
    int level,
    RetainerStats stats,
    Color accent,
  ) async {
    const chars = ['might', 'agility', 'reason', 'intuition', 'presence'];
    const labels = ['Might', 'Agility', 'Reason', 'Intuition', 'Presence'];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Text(
          'Level $level: Increase a Characteristic',
          style: const TextStyle(color: FormTheme.textBright, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose one characteristic to increase by +1.',
              style: TextStyle(fontSize: 12, color: FormTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ...List.generate(chars.length, (i) {
              final current = stats.characteristics[chars[i]] ?? 0;
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title: Text(
                  '${labels[i]}  (current: $current → ${current + 1})',
                  style: const TextStyle(
                      fontSize: 13, color: FormTheme.textBright),
                ),
                leading: Icon(Icons.trending_up, color: accent, size: 18),
                onTap: () => Navigator.of(ctx).pop(chars[i]),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (result != null) {
      await ref.read(retainerRepositoryProvider).setCharacteristicChoice(
            instance.id,
            level: level,
            characteristic: result,
          );
    }
  }

  Future<void> _showAdvancementChoiceDialog(
    BuildContext context,
    WidgetRef ref,
    int level,
    Retainer template,
    Color accent,
  ) async {
    // Build list of options: retainer-specific + role abilities for this level
    final svc = ref.read(retainerAdvancementServiceProvider);
    final retainerOptions = svc.retainerAbilityOptions(template, level);

    // Role abilities are seeded as components with advancement_level field
    final roleAbilities = await _loadRoleAbilities(ref, template.role, level);
    final combinedOptions = [...retainerOptions, ...roleAbilities];

    if (combinedOptions.isEmpty) {
      // Fallback — just store role ability marker
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No advancement abilities available for this level')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _AdvancementAbilityPickerDialog(
        level: level,
        abilityIds: combinedOptions,
        accent: accent,
        retainerName: template.name,
      ),
    );

    if (result != null) {
      await ref.read(retainerRepositoryProvider).setAdvancementChoice(
            instance.id,
            level: level,
            abilityId: result,
          );
    }
  }

  Future<List<String>> _loadRoleAbilities(
    WidgetRef ref,
    String role,
    int level,
  ) async {
    // Role advancement abilities are seeded as components of type 'ability'
    // with IDs like "role_ambusher__go_for_the_jugular"
    final allAbilities =
        await ref.read(componentsByTypeProvider('ability').future);
    final rolePrefix = 'role_${role.toLowerCase()}__';
    return allAbilities
        .where((a) {
          if (!a.id.startsWith(rolePrefix)) return false;
          final advLevel = a.data['advancement_level'];
          return advLevel == level;
        })
        .map((a) => a.id)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Shared helper builders
  // ---------------------------------------------------------------------------

  Widget _buildCharacteristics(RetainerStats stats) {
    const order = ['might', 'agility', 'reason', 'intuition', 'presence'];
    const labels = ['M', 'A', 'R', 'I', 'P'];
    return Row(
      children: [
        for (int i = 0; i < order.length; i++)
          StatGridTile(
            label: labels[i],
            value: stats.characteristics[order[i]] ?? 0,
          ),
      ],
    );
  }

  Widget _buildCoreStats(RetainerStats stats) {
    return Row(
      children: [
        StatGridTile(label: 'STA', value: stats.stamina),
        StatGridTile(label: 'SPD', value: stats.speed),
        StatGridTile(label: 'STB', value: stats.stability),
        StatGridTile(label: 'FS', value: stats.freeStrikeDamage),
      ],
    );
  }

  Widget _buildTagList(List<String> tags, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map((t) => _chip(t, textColor)).toList(),
      ),
    );
  }

  Widget _buildAbilityLookup(
    String abilityId,
    WidgetRef ref,
    Color textColor,
    Color accent,
  ) {
    final abilityAsync = ref.watch(abilityByNameProvider(abilityId));
    return abilityAsync.when(
      data: (ability) {
        if (ability == null) {
          return _buildAbilityById(abilityId, ref, textColor);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AbilityExpandableItem(component: ability, embedded: true),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child:
                  CircularProgressIndicator(strokeWidth: 1.5, color: accent),
            ),
            const SizedBox(width: 8),
            Text('Loading...',
                style: TextStyle(fontSize: 10, color: textColor)),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(
          '⚔️ $abilityId',
          style: TextStyle(
              fontSize: 11, color: textColor, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildAbilityById(
    String abilityId,
    WidgetRef ref,
    Color textColor,
  ) {
    final componentsAsync = ref.watch(componentsByTypeProvider('ability'));
    return componentsAsync.when(
      data: (abilities) {
        final match = abilities.where((a) => a.id == abilityId).firstOrNull;
        if (match == null) {
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '⚔️ ${_prettifyId(abilityId)}',
              style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontStyle: FontStyle.italic),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AbilityExpandableItem(component: match, embedded: true),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _vitalItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }

  static String _prettifyId(String id) {
    final parts = id.split('__');
    final name = parts.length > 1 ? parts.last : id;
    return '${name[0].toUpperCase()}${name.substring(1).replaceAll('_', ' ')}';
  }
}

// =============================================================================
// Advancement ability picker dialog
// =============================================================================

class _AdvancementAbilityPickerDialog extends ConsumerWidget {
  final int level;
  final List<String> abilityIds;
  final Color accent;
  final String retainerName;

  const _AdvancementAbilityPickerDialog({
    required this.level,
    required this.abilityIds,
    required this.accent,
    required this.retainerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abilitiesAsync = ref.watch(componentsByTypeProvider('ability'));

    return AlertDialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: FormTheme.borderDim),
      ),
      title: Text(
        'Level $level: Choose Advancement Ability',
        style: const TextStyle(color: FormTheme.textBright, fontSize: 15),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: abilitiesAsync.when(
          data: (allAbilities) {
            final options = abilityIds.map((id) {
              final match = allAbilities.where((a) => a.id == id).firstOrNull;
              return (id: id, component: match);
            }).toList();

            return ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final opt = options[i];
                final name = opt.component?.name ??
                    _RetainerStatsCard._prettifyId(opt.id);
                final desc = opt.component?.data['description'] as String? ??
                    opt.component?.data['effect'] as String? ??
                    '';
                final isRole = opt.id.startsWith('role_');

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(ctx).pop(opt.id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isRole
                                  ? Icons.groups_rounded
                                  : Icons.auto_awesome,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FormTheme.textBright,
                                ),
                              ),
                            ),
                            if (isRole)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Role',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: accent.withValues(alpha: 0.8)),
                                ),
                              ),
                          ],
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: FormTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error loading abilities: $e',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
      ],
    );
  }
}
