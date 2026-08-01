import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/models/minion_squad_instance.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../retainers/retainer_template_card.dart' show retainerRoleColor;

/// Manual tracker for one active minion squad: member count and pooled
/// Stamina. Unlike a companion's Stamina (which mirrors the hero's own max),
/// a squad's max Stamina is the template's per-member Stamina times the
/// current member count — recomputed here, not stored, since it changes
/// whenever the member count changes.
///
/// Adjusted entirely manually (mirrors [CompanionRampageWidget]'s +/-
/// stepper pattern) rather than automated from combat rules — this app
/// tracks resource state manually elsewhere too (e.g. Rampage), and full
/// summon-cap/in-combat-cost rules automation is out of scope.
class MinionSquadWidget extends ConsumerWidget {
  const MinionSquadWidget({super.key, required this.instance});

  final MinionSquadInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync =
        ref.watch(minionTemplateProvider(instance.minionComponentId));
    final template = templateAsync.valueOrNull;
    if (template == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final accent = retainerRoleColor(template.stats.role);
    final maxStamina = (template.stats.stamina ?? 0) * instance.memberCount;
    final currentStamina = (instance.currentStamina ?? maxStamina).clamp(0, maxStamina);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(GreenFormIcons.widget, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () => _showRenameDialog(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          instance.squadName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined,
                          size: 11, color: accent.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade300, size: 18),
                tooltip: 'Remove Squad',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmRemove(context, ref),
              ),
            ],
          ),
          Text(
            template.name,
            style: TextStyle(fontSize: 10, color: FormTheme.textMuted),
          ),
          const SizedBox(height: 8),
          _buildCountRow(ref, accent),
          const SizedBox(height: 6),
          _buildStaminaRow(ref, accent, currentStamina, maxStamina),
        ],
      ),
    );
  }

  Widget _buildCountRow(WidgetRef ref, Color accent) {
    return Row(
      children: [
        Text(
          'Members',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: accent),
        ),
        const Spacer(),
        _stepButton(
          accent: accent,
          icon: Icons.remove_circle_outline,
          onPressed: instance.memberCount > 1
              ? () => _setMemberCount(ref, instance.memberCount - 1)
              : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${instance.memberCount}',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: accent),
          ),
        ),
        _stepButton(
          accent: accent,
          icon: Icons.add_circle_outline,
          onPressed: instance.memberCount < 8
              ? () => _setMemberCount(ref, instance.memberCount + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStaminaRow(
      WidgetRef ref, Color accent, int currentStamina, int maxStamina) {
    return Row(
      children: [
        Text(
          'Stamina',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: accent),
        ),
        const Spacer(),
        _stepButton(
          accent: accent,
          icon: Icons.remove_circle_outline,
          onPressed: currentStamina > 0
              ? () => _setStamina(ref, currentStamina - 1)
              : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$currentStamina / $maxStamina',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: accent),
          ),
        ),
        _stepButton(
          accent: accent,
          icon: Icons.add_circle_outline,
          onPressed: currentStamina < maxStamina
              ? () => _setStamina(ref, currentStamina + 1)
              : null,
        ),
      ],
    );
  }

  Widget _stepButton(
      {required Color accent, required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: accent,
      disabledColor: FormTheme.textMuted,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  void _setMemberCount(WidgetRef ref, int memberCount) {
    ref
        .read(minionRepositoryProvider)
        .updateCombatState(instance.id, memberCount: memberCount);
  }

  void _setStamina(WidgetRef ref, int currentStamina) {
    ref
        .read(minionRepositoryProvider)
        .updateCombatState(instance.id, currentStamina: currentStamina);
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade300, size: 24),
            const SizedBox(width: 8),
            const Text('Remove Squad',
                style: TextStyle(color: FormTheme.textBright)),
          ],
        ),
        content: Text(
          'Remove ${instance.squadName}?',
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
      await ref.read(minionRepositoryProvider).removeSquad(instance.id);
    }
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: instance.squadName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: const Text('Rename Squad',
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
    if (result != null && result != instance.squadName) {
      await ref.read(minionRepositoryProvider).updateName(instance.id, result);
    }
  }
}
