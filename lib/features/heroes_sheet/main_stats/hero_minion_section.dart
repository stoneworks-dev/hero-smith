import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/repositories/minion_repository.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../widgets/minions/add_minion_dialog.dart';
import '../../../widgets/minions/minion_squad_widget.dart';
import '../../../widgets/minions/minion_template_card.dart' show minionAccent;
import 'hero_main_stats_providers.dart';

/// A compact minion-squad tracker on the hero main stats page, alongside
/// [HeroCompanionSection]/[HeroRetainerSection]. Shows 0-2 active squads
/// (the Summoner rules cap) plus an "Add Squad" action.
///
/// **Not class-gated yet** — unlike [HeroCompanionSection] (gated on
/// `classKey == 'class_beastheart'`), there is no Summoner class shell in
/// the app yet to gate on. This section is intentionally always visible for
/// now; add the `classKey == 'class_summoner'` gate here once the class
/// shell lands, so it isn't forgotten.
class HeroMinionSection extends ConsumerWidget {
  final String heroId;
  const HeroMinionSection({super.key, required this.heroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = ref.watch(heroAssemblyProvider(heroId)).valueOrNull?.classId;
    if (classId?.toLowerCase() != 'class_summoner') {
      return const SizedBox.shrink();
    }
    final squadsAsync = ref.watch(heroMinionSquadsProvider(heroId));
    final squads = squadsAsync.valueOrNull ?? const [];
    final canAddSquad = squads.length < MinionRepository.maxActiveSquads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppIcon(GreenFormIcons.widget, color: minionAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              'Minion Squads',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: minionAccent,
              ),
            ),
            const Spacer(),
            if (canAddSquad)
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: minionAccent.withValues(alpha: 0.7), size: 20),
                tooltip: 'Summon Minion Squad',
                onPressed: () => _showAddDialog(context, ref),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (squads.isEmpty)
          _buildEmptyState(context, ref)
        else
          ...squads.map(
            (instance) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MinionSquadWidget(instance: instance),
            ),
          ),
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
          color: minionAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: minionAccent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            AppIcon(GreenFormIcons.widget,
                color: minionAccent.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text(
              'No minion squads summoned',
              style: TextStyle(fontSize: 13, color: FormTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to summon a squad',
              style: TextStyle(
                fontSize: 11,
                color: minionAccent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddMinionDialog(
        onMinionSelected: (minion) async {
          final repo = ref.read(minionRepositoryProvider);
          await repo.addSquad(
            heroId: heroId,
            minionComponentId: minion.id,
            squadName: minion.name,
            memberCount: minion.stats.minionsPerSummon,
          );
        },
      ),
    );
  }
}
