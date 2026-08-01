import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/minion.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import '../abilities/ability_expandable_item.dart';
import '../retainers/retainer_template_card.dart' show retainerRoleColor;
import '../shared/expandable_card.dart';
import '../shared/section_widgets.dart';
import '../shared/stat_display_widgets.dart';

/// Accent color for minion UI elements (section header, generic chrome).
/// Individual cards use [retainerRoleColor] instead, since minions share the
/// same role vocabulary (ambusher/artillery/brute/...) as retainers.
const minionAccent = Color(0xFF5E35B1); // Arcane purple

const _portfolioLabels = <String, String>{
  'demon': 'Demon',
  'elemental': 'Elemental',
  'fey': 'Fey',
  'undead': 'Undead',
};

/// Display card for a minion species template (used in browser and picker).
///
/// Mirrors [CompanionTemplateCard] (abilities are embedded/self-contained,
/// not ID-referenced like retainers), plus a role badge (reusing
/// [retainerRoleColor], since minions share the retainer role vocabulary)
/// and a portfolio/essence-cost subtitle.
class MinionTemplateCard extends ConsumerWidget {
  final Minion minion;
  const MinionTemplateCard({super.key, required this.minion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neutralText =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.9);
    final accent = retainerRoleColor(minion.stats.role);

    return ExpandableCard(
      title: minion.name,
      borderColor: accent,
      leading: AppIcon(GreenFormIcons.widget, color: accent, size: 20),
      badge: _buildRoleBadge(accent),
      preview: _buildPreview(neutralText),
      expandedContent: _buildExpanded(neutralText, accent, ref),
    );
  }

  Widget _buildRoleBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _capitalise(minion.stats.role),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPreview(Color textColor) {
    final tags = [
      if (_portfolioLabels.containsKey(minion.stats.portfolio))
        _portfolioLabels[minion.stats.portfolio]!,
      if (minion.stats.essenceCost > 0)
        '${minion.stats.essenceCost} essence / ${minion.stats.minionsPerSummon}',
      if (minion.stats.isSignature) 'Signature',
      if (minion.stats.size != null) 'Size ${minion.stats.size}',
      ...minion.keywords,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) => _chip(t, textColor.withOpacity(0.7))).toList(),
    );
  }

  Widget _buildExpanded(Color textColor, Color accent, WidgetRef ref) {
    final characteristics = minion.stats.characteristics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (minion.description.isNotEmpty) ...[
          Text(
            minion.description,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (characteristics.isNotEmpty) ...[
          SectionLabel('Characteristics', color: accent),
          const SizedBox(height: 4),
          _buildCharacteristics(characteristics),
        ],
        const SizedBox(height: 8),
        SectionLabel('Stats', color: accent),
        const SizedBox(height: 4),
        _buildCoreStats(),
        if (minion.stats.immunities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Immunities', color: accent),
          const SizedBox(height: 2),
          _buildTagList(minion.stats.immunities, textColor),
        ],
        if (minion.stats.weaknesses.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Weaknesses', color: Colors.red.shade300),
          const SizedBox(height: 2),
          _buildTagList(minion.stats.weaknesses, textColor),
        ],
        if (minion.stats.movementModes.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Movement', color: accent),
          const SizedBox(height: 2),
          _buildTagList(
            minion.stats.movementModes.map(_capitalise).toList(),
            textColor,
          ),
        ],
        if (minion.traits.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Traits', color: accent, icon: GreenFormIcons.widget),
          const SizedBox(height: 4),
          ...minion.traits.map((t) => _buildTrait(t, textColor)),
        ],
        if (minion.abilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Abilities', color: accent, icon: AbilityIcons.ability),
          const SizedBox(height: 4),
          ...minion.abilities.map((ability) => _buildAbilityReference(ability, ref)),
        ],
      ],
    );
  }

  Widget _buildCharacteristics(Map<String, int> characteristics) {
    const order = ['might', 'agility', 'reason', 'intuition', 'presence'];
    const labels = ['M', 'A', 'R', 'I', 'P'];
    return Row(
      children: [
        for (int i = 0; i < order.length; i++)
          if (characteristics.containsKey(order[i]))
            StatGridTile(label: labels[i], value: characteristics[order[i]]!),
      ],
    );
  }

  Widget _buildCoreStats() {
    final stats = minion.stats;
    final tiles = <Widget>[
      if (stats.speed != null) StatGridTile(label: 'SPD', value: stats.speed!),
      if (stats.stamina != null)
        StatGridTile(label: 'STA', value: stats.stamina!),
      if (stats.stability != null)
        int.tryParse(stats.stability!) != null
            ? StatGridTile(label: 'STB', value: int.parse(stats.stability!))
            : _characteristicStability(stats.stability!),
    ];
    if (tiles.isEmpty && stats.freeStrike == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        ...tiles,
        if (stats.freeStrike != null)
          _freeStrikeStat(stats.freeStrike!, stats.freeStrikeDamageType ?? ''),
      ],
    );
  }

  Widget _freeStrikeStat(String value, String damageType) {
    final normalizedType = damageType.trim().toLowerCase();
    final hasDamageType = normalizedType.isNotEmpty;
    final damageColor = hasDamageType
        ? DamageTokens.color(normalizedType)
        : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FS', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
              if (hasDamageType) ...[
                const SizedBox(width: 3),
                AppIcon(DamageTypeIcons.fromName(normalizedType), size: 11, color: damageColor),
                const SizedBox(width: 2),
                Text(
                  damageType,
                  style: TextStyle(fontSize: 9, color: damageColor, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ],
      ),
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

  Widget _characteristicStability(String characteristic) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CharacteristicBadge(characteristic),
            const SizedBox(height: 4),
            Text('STB', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrait(MinionTrait trait, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trait.essenceCost == null
                ? trait.name
                : '${trait.name} \u2022 ${trait.essenceCost} Essence',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (trait.description.isNotEmpty)
            Text(
              trait.description,
              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8)),
            ),
        ],
      ),
    );
  }

  Widget _buildAbilityReference(MinionAbilityReference ability, WidgetRef ref) {
    final resolved = ref.watch(abilityByNameProvider(ability.abilityId));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: resolved.when(
        data: (component) => component == null
            ? Text(ability.name.isEmpty ? ability.abilityId : ability.name)
            : AbilityExpandableItem(component: component, embedded: true),
        loading: () => Text(ability.name.isEmpty ? ability.abilityId : ability.name),
        error: (_, __) => Text(ability.name.isEmpty ? ability.abilityId : ability.name),
      ),
    );
  }

  Widget _chip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: textColor),
      ),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
