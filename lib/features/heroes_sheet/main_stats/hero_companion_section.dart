import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/companion.dart';
import '../../../core/models/companion_instance.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/semantic/semantic_tokens.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';
import '../../../widgets/companions/add_companion_dialog.dart';
import '../../../widgets/companions/companion_rampage_widget.dart';
import '../../../widgets/companions/companion_template_card.dart';
import '../../../widgets/shared/expandable_card.dart';
import '../../../widgets/shared/section_widgets.dart';
import '../../../core/repositories/companion_repository.dart';
import '../../../core/repositories/hero_repository.dart';
import 'combat_dialogs.dart';
import 'hero_main_stats_providers.dart';
import 'hero_stamina_helpers.dart';
import 'stamina_bar_widget.dart';

/// The only class whose heroes have a companion, per the Beastheart rules.
/// Class ids in this app are prefixed (e.g. `class_censor`, `class_conduit`
/// — see each class's `classId` field in `data/classes_levels_and_stats/`),
/// so this must match that convention, not a bare `beastheart`.
const _companionClassId = 'class_beastheart';

/// A compact companion section that lives on the hero main stats page,
/// directly below the vitals card (Stamina, Recoveries, Heroic Resource,
/// Surges) since — per the rules ("Companion Stamina and Recoveries") — a
/// companion's Stamina maximum always equals its hero's Stamina maximum and
/// it has no Recoveries of its own; it spends the hero's. Only shown for
/// Beastheart heroes.
///
/// Mirrors [HeroRetainerSection]'s structure (template + mentor-level
/// advancement via [CompanionAdvancementService], stamina bar, damage/heal,
/// add/swap/remove/rename), but simpler where the rules are simpler: no
/// player choices among advancement options (features unlock automatically
/// by hero level) and no companion-only recovery count (recoveries and max
/// stamina are read live from the hero's own vitals).
class HeroCompanionSection extends ConsumerWidget {
  final String heroId;
  const HeroCompanionSection({super.key, required this.heroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assemblyAsync = ref.watch(heroAssemblyProvider(heroId));
    final classId = assemblyAsync.valueOrNull?.classId;
    if (classId?.toLowerCase() != _companionClassId) {
      return const SizedBox.shrink();
    }

    final instanceAsync = ref.watch(heroCompanionProvider(heroId));
    final instance = instanceAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const AppIcon(GreenFormIcons.widget,
                color: companionAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              'Companion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: companionAccent,
              ),
            ),
            const Spacer(),
            if (instance != null) ...[
              // Swap companion
              IconButton(
                icon: Icon(Icons.swap_horiz_rounded,
                    color: companionAccent.withValues(alpha: 0.7), size: 20),
                tooltip: 'Change Companion',
                onPressed: () =>
                    _showAddDialog(context, ref, replaceId: instance.id),
                visualDensity: VisualDensity.compact,
              ),
              // Remove companion
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade300, size: 20),
                tooltip: 'Remove Companion',
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
          _CompanionStatsCard(heroId: heroId, instance: instance),
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
          color: companionAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: companionAccent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            AppIcon(GreenFormIcons.widget,
                color: companionAccent.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text(
              'No companion assigned',
              style: TextStyle(
                fontSize: 13,
                color: FormTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add a companion',
              style: TextStyle(
                fontSize: 11,
                color: companionAccent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref,
      {String? replaceId}) {
    showDialog(
      context: context,
      builder: (_) => AddCompanionDialog(
        onCompanionSelected: (companion) async {
          final repo = ref.read(companionRepositoryProvider);
          // Remove existing companion first if swapping
          if (replaceId != null) {
            await repo.removeCompanion(replaceId);
          }
          await repo.addCompanion(
            heroId: heroId,
            companionComponentId: companion.id,
            name: companion.name,
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    CompanionInstance instance,
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
            const Text('Remove Companion',
                style: TextStyle(color: FormTheme.textBright)),
          ],
        ),
        content: Text(
          'Remove ${instance.name}?',
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
      final repo = ref.read(companionRepositoryProvider);
      await repo.removeCompanion(instance.id);
    }
  }
}

/// Keeps level-gated companion features available without making the main
/// Features section noisy by default.
class _AdvancementFeaturesDisclosure extends StatefulWidget {
  const _AdvancementFeaturesDisclosure({
    required this.features,
    required this.heroLevel,
    required this.textColor,
    required this.accent,
  });

  final List<CompanionAdvancementFeature> features;
  final int heroLevel;
  final Color textColor;
  final Color accent;

  @override
  State<_AdvancementFeaturesDisclosure> createState() =>
      _AdvancementFeaturesDisclosureState();
}

class _AdvancementFeaturesDisclosureState
    extends State<_AdvancementFeaturesDisclosure> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, size: 18),
            ),
            label: Text(
              _isExpanded
                  ? 'Hide advancement features'
                  : 'Expand advancement features',
            ),
            style: TextButton.styleFrom(
              foregroundColor: widget.accent,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.features.map(_buildFeature).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(CompanionAdvancementFeature feature) {
    final unlocked = widget.heroLevel >= feature.level;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Level ${feature.level}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? widget.accent.withValues(alpha: 0.8)
                        : Colors.grey.shade600,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(locked)',
                    style: TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              feature.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
            ),
            if (feature.description.isNotEmpty)
              Text(
                feature.description,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.textColor.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Displays the active companion's template stats, a stamina bar tracking
/// the companion's own current stamina against the hero's max, and a rename
/// affordance.
class _CompanionStatsCard extends ConsumerWidget {
  final String heroId;
  final CompanionInstance instance;
  const _CompanionStatsCard({required this.heroId, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(heroCompanionTemplateProvider(heroId));
    final template = templateAsync.valueOrNull;
    final heroStatsAsync = ref.watch(heroMainStatsProvider(heroId));
    final heroStats = heroStatsAsync.valueOrNull;

    if (template == null || heroStats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final advancementAsync = ref.watch(heroCompanionStatsProvider(heroId));
    final heroLevel = advancementAsync.valueOrNull?.level ?? heroStats.level;
    final textColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);

    return ExpandableCard(
      title: instance.name,
      borderColor: companionAccent,
      expandOnTap: false,
      showExpandButton: true,
      showHeaderExpandIndicator: false,
      expandButtonLabel: 'Expand features',
      collapseButtonLabel: 'Hide features',
      leading: const AppIcon(GreenFormIcons.widget,
          color: companionAccent, size: 20),
      subtitle: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showRenameDialog(context, ref),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 12, color: companionAccent.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              'Tap to rename',
              style: TextStyle(
                fontSize: 10,
                color: companionAccent.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      preview: _buildPreview(
        context,
        ref,
        template,
        heroStats,
        heroLevel,
        textColor,
      ),
      expandedContent:
          _buildExpanded(template, heroLevel, textColor, companionAccent),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview (collapsed): stamina, shared recoveries, quick stats
  // ---------------------------------------------------------------------------

  Widget _buildPreview(
    BuildContext context,
    WidgetRef ref,
    Companion template,
    HeroMainStats heroStats,
    int heroLevel,
    Color textColor,
  ) {
    // Per the rules, the companion's Stamina maximum always equals the
    // hero's Stamina maximum; only the companion's *current* stamina is its
    // own.
    final maxStamina = heroStats.staminaMaxEffective;
    final currentStamina = instance.currentStamina ?? maxStamina;
    final staminaState = calculateStaminaStateFromValues(
      currentStamina: currentStamina,
      maxStamina: maxStamina,
    );
    final recoveryHealAmount = calculateRecoveryHealAmount(heroStats);
    final heroRecoveriesLeft = heroStats.recoveriesCurrent;
    final stats = template.stats;

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
        // Full-width stamina bar.
        StaminaBarWidget(
          maxStamina: maxStamina,
          currentStamina: currentStamina,
          tempHp: instance.tempStamina,
          staminaState: staminaState,
        ),
        const SizedBox(height: 4),
        // Current / Temp / Max values with the compact fate control.
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _vitalItem('CUR', currentStamina, staminaState.color),
                  const SizedBox(width: 8),
                  _vitalItem('TMP', instance.tempStamina, Colors.cyan.shade300),
                  const SizedBox(width: 8),
                  _vitalItem(
                    'MAX',
                    maxStamina,
                    textColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StaminaFateButton(
              semanticLabel: 'Change companion stamina',
              onPressed: () => _showStaminaFateDialog(
                context,
                ref,
                currentStamina,
                maxStamina,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildStatChips(stats),
        const Divider(height: 14),
        // Shared recoveries row — the companion has no recovery pool of its
        // own; it spends the hero's.
        Row(
          children: [
            Icon(Icons.shield_rounded, size: 14, color: Colors.amber.shade400),
            const SizedBox(width: 6),
            Text(
              'Recoveries (shared)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade400,
              ),
            ),
            const SizedBox(width: 12),
            _vitalItem(
                'Left',
                heroRecoveriesLeft,
                heroRecoveriesLeft > 0
                    ? Colors.amber.shade400
                    : Colors.grey.shade600),
            const SizedBox(width: 8),
            _vitalItem('Heal', recoveryHealAmount, Colors.green.shade400),
            const Spacer(),
            FilledButton.tonal(
              onPressed: heroRecoveriesLeft > 0
                  ? () => _useRecovery(ref, currentStamina, maxStamina,
                      recoveryHealAmount, heroRecoveriesLeft)
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
                  Icon(Icons.shield_rounded,
                      size: 14,
                      color: heroRecoveriesLeft > 0
                          ? Colors.amber.shade400
                          : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Use',
                    style: TextStyle(
                      fontSize: 11,
                      color: heroRecoveriesLeft > 0
                          ? Colors.amber.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 14),
        // Rampage is part of the companion card. Its gauge has its own
        // disclosure, so its current value remains visible without the height.
        CompanionRampageWidget(instance: instance, heroLevel: heroLevel),
      ],
    );
  }

  /// A compact at-a-glance strip: characteristic chips use their semantic
  /// colours while core companion stats keep the card's brown accent.
  Widget _buildStatChips(CompanionStats stats) {
    const labels = <String, String>{
      'might': 'M',
      'agility': 'A',
      'reason': 'R',
      'intuition': 'I',
      'presence': 'P',
    };

    final characteristicChips = [
      for (final entry in stats.characteristics.entries)
        _statChip(
          labels[entry.key] ?? entry.key.substring(0, 1).toUpperCase(),
          entry.value >= 0 ? '+${entry.value}' : '${entry.value}',
          CharacteristicTokens.color(entry.key),
        ),
    ];
    final coreStatChips = [
      if (stats.size != null)
        _statChip('SIZE', '${stats.size}', companionAccent),
      if (stats.speed != null)
        _statChip('SPD', '${stats.speed}', companionAccent),
      if (stats.stability != null)
        _statChip('STB', '${stats.stability}', companionAccent),
      if (stats.freeStrike != null)
        _statChip('FS', stats.freeStrike!, companionAccent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (characteristicChips.isNotEmpty)
          _buildStatChipRow(characteristicChips),
        if (characteristicChips.isNotEmpty && coreStatChips.isNotEmpty)
          const SizedBox(height: 6),
        if (coreStatChips.isNotEmpty) _buildStatChipRow(coreStatChips),
      ],
    );
  }

  Widget _buildStatChipRow(List<Widget> chips) {
    return Row(
      children: [
        for (var index = 0; index < chips.length; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(child: chips[index]),
        ],
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: FormTheme.textBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Combat state mutations
  // ---------------------------------------------------------------------------

  /// Spend one of the hero's recoveries to heal the companion. Per the
  /// rules, the companion has no recovery pool of its own.
  void _useRecovery(
    WidgetRef ref,
    int currentStamina,
    int maxStamina,
    int healAmount,
    int heroRecoveriesLeft,
  ) {
    if (heroRecoveriesLeft <= 0) return;
    final newStamina = math.min(currentStamina + healAmount, maxStamina);
    ref
        .read(companionRepositoryProvider)
        .updateCombatState(instance.id, currentStamina: newStamina);
    ref.read(heroRepositoryProvider).updateVitals(
          heroId,
          recoveriesCurrent: heroRecoveriesLeft - 1,
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

    final repo = ref.read(companionRepositoryProvider);
    switch (result.fate) {
      case StaminaFate.damage:
        _applyDamage(
          repo,
          currentStamina,
          maxStamina,
          result.amount,
        );
        break;
      case StaminaFate.heal:
        final newStamina = math.min(currentStamina + result.amount, maxStamina);
        repo.updateCombatState(instance.id, currentStamina: newStamina);
        break;
      case StaminaFate.tempStamina:
        repo.updateCombatState(
          instance.id,
          tempStamina: instance.tempStamina + result.amount,
        );
        break;
    }
  }

  void _applyDamage(
    CompanionRepository repo,
    int currentStamina,
    int maxStamina,
    int amount,
  ) {
    var temp = instance.tempStamina;
    var current = currentStamina;
    if (amount <= temp) {
      temp -= amount;
    } else {
      final remaining = amount - temp;
      temp = 0;
      current -= remaining;
    }
    final halfMax = maxStamina ~/ 2;
    current = current.clamp(-halfMax, maxStamina);

    repo.updateCombatState(instance.id, currentStamina: current, tempStamina: temp);
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

  // ---------------------------------------------------------------------------
  // Expanded content: characteristics, features, abilities, advancement
  // ---------------------------------------------------------------------------

  Widget _buildExpanded(
    Companion template,
    int heroLevel,
    Color textColor,
    Color accent,
  ) {
    final activeAdvancementFeatures =
        template.featuresUnlockedAt(heroLevel);
    final futureFeatures = template.advancementFeatures
        .where((feature) => feature.level > heroLevel)
        .toList();
    final hasFeatures = template.features.isNotEmpty ||
        activeAdvancementFeatures.isNotEmpty ||
        futureFeatures.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFeatures) ...[
          SectionLabel(
            'Features',
            color: accent,
            icon: GreenFormIcons.widget,
          ),
          const SizedBox(height: 4),
          ...template.features
              .map((f) => _buildFeature(f.name, f.description, textColor)),
          ...activeAdvancementFeatures.map(
            (f) => _buildFeature(f.name, f.description, textColor),
          ),
          if (futureFeatures.isNotEmpty)
            _AdvancementFeaturesDisclosure(
              features: futureFeatures,
              heroLevel: heroLevel,
              textColor: textColor,
              accent: accent,
            ),
        ],

        if (template.abilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel(
            'Abilities',
            color: accent,
            icon: AbilityIcons.ability,
          ),
          const SizedBox(height: 4),
          ...template.abilities.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AbilityExpandableItem(component: c, embedded: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeature(String name, String description, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
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
        title: const Text('Rename Companion',
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
      ref.read(companionRepositoryProvider).updateName(instance.id, result);
    }
  }
}
