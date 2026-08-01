import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/component.dart';
import '../../core/models/retainer.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../abilities/ability_expandable_item.dart';
import '../shared/expandable_card.dart';
import '../shared/section_widgets.dart';
import '../shared/stat_display_widgets.dart';

/// Accent color for retainer UI elements.
const retainerAccent = Color(0xFF26A69A); // Teal

/// Role accent colors for retainer cards.
const _roleColors = <String, Color>{
  'ambusher': Color(0xFF7E57C2),
  'artillery': Color(0xFFEF5350),
  'brute': Color(0xFFFF7043),
  'controller': Color(0xFF42A5F5),
  'defender': Color(0xFF66BB6A),
  'harrier': Color(0xFFFFCA28),
  'hexer': Color(0xFFAB47BC),
  'mount': Color(0xFF8D6E63),
  'support': Color(0xFF26C6DA),
};

Color retainerRoleColor(String role) =>
    _roleColors[role.toLowerCase()] ?? retainerAccent;

/// Display card for a retainer template (used in browser and picker).
///
/// Uses [ExpandableCard] with role-based accent color. Shows:
/// - Collapsed: name, role badge, starting level, ancestry tags
/// - Expanded: characteristics, abilities (signature + passives),
///   immunities, movement modes, advancement ability names
class RetainerTemplateCard extends ConsumerWidget {
  final Retainer retainer;
  const RetainerTemplateCard({super.key, required this.retainer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = retainerRoleColor(retainer.role);
    final neutralText =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.9);

    return ExpandableCard(
      title: retainer.name,
      borderColor: borderColor,
      leading: AppIcon(DowntimeIcons.follower, color: borderColor, size: 20),
      badge: _buildRoleBadge(borderColor),
      preview: _buildPreview(neutralText),
      expandedContent: _buildExpanded(context, ref, neutralText, borderColor),
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
        _capitalise(retainer.role),
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
      'Lvl ${retainer.startingLevel}',
      ...retainer.ancestryTags,
      'Size ${retainer.size}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map((t) => _chip(t, textColor.withOpacity(0.7)))
          .toList(),
    );
  }

  Widget _buildExpanded(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Characteristics
        SectionLabel('Characteristics', icon: DowntimeIcons.followerSkills, color: accent),
        const SizedBox(height: 4),
        _buildCharacteristics(),

        // Core stats
        const SizedBox(height: 8),
        SectionLabel('Stats', color: accent),
        const SizedBox(height: 4),
        _buildCoreStats(),

        // Immunities / Weaknesses
        if (retainer.immunities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Immunities', color: accent),
          const SizedBox(height: 2),
          _buildTagList(retainer.immunities, textColor),
        ],
        if (retainer.weaknesses.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Weaknesses', color: Colors.red.shade300),
          const SizedBox(height: 2),
          _buildTagList(retainer.weaknesses, textColor),
        ],

        // Movement modes
        if (retainer.movementModes.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Movement', color: accent),
          const SizedBox(height: 2),
          _buildTagList(
            retainer.movementModes.map(_capitalise).toList(),
            textColor,
          ),
        ],

        // Passive traits
        if (retainer.passiveTraits.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Passive Traits', color: accent),
          const SizedBox(height: 4),
          ...retainer.passiveTraits.map((t) => _buildPassiveTrait(t, textColor)),
        ],

        // Signature ability
        const SizedBox(height: 8),
        SectionLabel('Signature Ability', color: accent),
        const SizedBox(height: 4),
        _buildAbilityLookup(retainer.signatureAbilityId, ref, textColor, accent),

        // Base abilities (maneuvers, triggered actions, etc.)
        if (retainer.baseAbilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Abilities', color: accent),
          const SizedBox(height: 4),
          ...retainer.baseAbilities.map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildAbilityLookup(id, ref, textColor, accent),
            ),
          ),
        ],

        // Advancement abilities
        if (retainer.advancementAbilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Advancement Abilities', color: accent),
          const SizedBox(height: 4),
          ...retainer.advancementAbilities.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${e.key}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  for (final abilityId in e.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child:
                          _buildAbilityLookup(abilityId, ref, textColor, accent),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCharacteristics() {
    const order = ['might', 'agility', 'reason', 'intuition', 'presence'];
    const labels = ['M', 'A', 'R', 'I', 'P'];
    return Row(
      children: [
        for (int i = 0; i < order.length; i++)
          StatGridTile(
            label: labels[i],
            value: retainer.characteristics[order[i]] ?? 0,
          ),
      ],
    );
  }

  Widget _buildCoreStats() {
    return Row(
      children: [
        StatGridTile(label: 'STA', value: retainer.baseStamina),
        StatGridTile(label: 'SPD', value: retainer.speed),
        StatGridTile(label: 'STB', value: retainer.stability),
        StatGridTile(label: 'FS', value: retainer.freeStrikeDamage),
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

  Widget _buildPassiveTrait(RetainerPassiveTrait trait, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trait.name,
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
          // Try as component ID directly
          return _buildAbilityById(abilityId, ref, textColor, accent);
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
              child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(
          '⚔️ $abilityId',
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildAbilityById(
    String abilityId,
    WidgetRef ref,
    Color textColor,
    Color accent,
  ) {
    final componentsAsync = ref.watch(componentsByTypeProvider('ability'));
    return componentsAsync.when(
      data: (abilities) {
        final match = abilities.cast<Component?>().firstWhere(
              (a) => a!.id == abilityId,
              orElse: () => null,
            );
        if (match == null) {
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '⚔️ ${_prettifyId(abilityId)}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
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

  static String _prettifyId(String id) {
    // "angulotl_hopper__leapfrog" → "Leapfrog"
    final parts = id.split('__');
    final name = parts.length > 1 ? parts.last : id;
    return _capitalise(name.replaceAll('_', ' '));
  }
}
