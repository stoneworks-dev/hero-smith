import 'package:flutter/material.dart';
import '../../core/models/companion.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../abilities/ability_expandable_item.dart';
import '../shared/expandable_card.dart';
import '../shared/section_widgets.dart';
import '../shared/stat_display_widgets.dart';

/// Accent color for companion UI elements.
const companionAccent = Color(0xFF8D6E63); // Earthy brown

/// Display card for a companion template (used in browser and picker).
///
/// Uses [ExpandableCard], mirroring [RetainerTemplateCard] but simpler: no
/// role badge (companions have no role), a partial characteristics grid
/// (only the keys the template actually defines), no stamina tile, and
/// abilities rendered directly from the synthesized ability Components
/// (no ID lookup needed, since companion abilities are self-contained).
class CompanionTemplateCard extends StatelessWidget {
  final Companion companion;
  const CompanionTemplateCard({super.key, required this.companion});

  @override
  Widget build(BuildContext context) {
    final neutralText =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.9);

    return ExpandableCard(
      title: companion.name,
      borderColor: companionAccent,
      leading:
          const AppIcon(GreenFormIcons.widget, color: companionAccent, size: 20),
      preview: _buildPreview(neutralText),
      expandedContent: _buildExpanded(neutralText, companionAccent),
    );
  }

  Widget _buildPreview(Color textColor) {
    final tags = [
      if (companion.stats.size != null) 'Size ${companion.stats.size}',
      ...companion.keywords,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) => _chip(t, textColor.withOpacity(0.7))).toList(),
    );
  }

  Widget _buildExpanded(Color textColor, Color accent) {
    final characteristics = companion.stats.characteristics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (characteristics.isNotEmpty) ...[
          SectionLabel('Characteristics', color: accent),
          const SizedBox(height: 4),
          _buildCharacteristics(characteristics),
        ],

        // Core stats (only whatever is defined)
        const SizedBox(height: 8),
        SectionLabel('Stats', color: accent),
        const SizedBox(height: 4),
        _buildCoreStats(),

        if (companion.stats.immunities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Immunities', color: accent),
          const SizedBox(height: 2),
          _buildTagList(companion.stats.immunities, textColor),
        ],
        if (companion.stats.movementModes.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Movement', color: accent),
          const SizedBox(height: 2),
          _buildTagList(
            companion.stats.movementModes.map(_capitalise).toList(),
            textColor,
          ),
        ],
        if (companion.stats.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel('Skills', color: accent),
          const SizedBox(height: 2),
          _buildTagList(companion.stats.skills, textColor),
        ],

        // Features
        if (companion.features.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel(
            'Features',
            color: accent,
            icon: GreenFormIcons.widget,
          ),
          const SizedBox(height: 4),
          ...companion.features.map((f) => _buildFeature(f.name, f.description, textColor)),
        ],

        // Abilities
        if (companion.abilities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel(
            'Abilities',
            color: accent,
            icon: AbilityIcons.ability,
          ),
          const SizedBox(height: 4),
          ...companion.abilities.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AbilityExpandableItem(component: c, embedded: true),
            ),
          ),
        ],

        // Advancement features
        if (companion.advancementFeatures.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionLabel(
            'Advancement Features',
            color: accent,
            icon: AbilityIcons.progression,
          ),
          const SizedBox(height: 4),
          ...companion.advancementFeatures.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${f.level}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildFeature(f.name, f.description, textColor),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCharacteristics(Map<String, int> characteristics) {
    const labels = <String, String>{
      'might': 'M',
      'agility': 'A',
      'reason': 'R',
      'intuition': 'I',
      'presence': 'P',
    };
    return Row(
      children: [
        for (final entry in characteristics.entries)
          StatGridTile(
            label: labels[entry.key] ?? entry.key.substring(0, 1).toUpperCase(),
            value: entry.value,
          ),
      ],
    );
  }

  Widget _buildCoreStats() {
    // StatGridTile wraps itself in Expanded, so it must sit directly inside
    // a Row/Flex (it throws "Incorrect use of ParentDataWidget" inside a
    // Wrap) — the freeStrike tile is a plain Container instead since it's a
    // formula string, not a StatGridTile.
    final stats = companion.stats;
    final tiles = <Widget>[
      if (stats.speed != null) StatGridTile(label: 'SPD', value: stats.speed!),
      if (stats.stability != null)
        StatGridTile(label: 'STB', value: stats.stability!),
    ];
    if (tiles.isEmpty && stats.freeStrike == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        ...tiles,
        if (stats.freeStrike != null) _textStat('FS', stats.freeStrike!),
      ],
    );
  }

  Widget _textStat(String label, String value) {
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
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
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
              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8)),
            ),
        ],
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
