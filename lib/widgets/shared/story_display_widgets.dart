import 'package:flutter/material.dart';

import '../../core/theme/story_theme.dart';
import '../../core/theme/form_theme.dart';

/// A row displaying labeled information with an icon.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: StoryTheme.storyAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty) ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays an effect item (benefit, drawback, or mixed).
class EffectItemDisplay extends StatelessWidget {
  const EffectItemDisplay({
    super.key,
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
  });

  final String label;
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a grant item with icon and text.
class GrantItemDisplay extends StatelessWidget {
  const GrantItemDisplay({
    super.key,
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: StoryTheme.storyAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a reference to an ability.
class AbilityReferenceDisplay extends StatelessWidget {
  const AbilityReferenceDisplay({
    super.key,
    required this.ability,
  });

  final dynamic ability;

  @override
  Widget build(BuildContext context) {
    if (ability == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StoryTheme.storyAccent.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: StoryTheme.storyAccent.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flash_on,
            size: 16,
            color: StoryTheme.storyAccent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Ability: ${ability.toString()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a reference to a feature.
class FeatureReferenceDisplay extends StatelessWidget {
  const FeatureReferenceDisplay({
    super.key,
    required this.feature,
  });

  final dynamic feature;

  @override
  Widget build(BuildContext context) {
    if (feature == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            size: 16,
            color: Colors.amber.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Feature: ${feature.toString()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card displaying a selected trait with name, description, cost, and optional ability.
class SelectedTraitCard extends StatelessWidget {
  const SelectedTraitCard({
    super.key,
    required this.trait,
  });

  final Map<String, dynamic> trait;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FormTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trait['name']?.toString() ?? 'Unknown Trait',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (trait['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              trait['description'].toString(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
          if (trait['cost'] != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StoryTheme.storyAccent.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Cost: ${trait['cost']} pt${trait['cost'] == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: StoryTheme.storyAccent,
                ),
              ),
            ),
          ],
          if (trait['ability_name'] != null &&
              trait['ability_name'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            AbilityReferenceDisplay(ability: trait['ability_name']),
          ],
        ],
      ),
    );
  }
}

/// Displays an inciting incident with name and description.
class IncitingIncidentDisplay extends StatelessWidget {
  const IncitingIncidentDisplay({
    super.key,
    required this.careerData,
    required this.incidentName,
  });

  final Map<String, dynamic> careerData;
  final String incidentName;

  @override
  Widget build(BuildContext context) {
    final incidents = careerData['inciting_incidents'] as List?;

    if (incidents == null) {
      return Text(incidentName, style: const TextStyle(color: Colors.white));
    }

    final incident = incidents.cast<Map<String, dynamic>>().firstWhere(
          (i) => i['name']?.toString() == incidentName,
          orElse: () => <String, dynamic>{},
        );

    if (incident.isEmpty) {
      return Text(incidentName, style: const TextStyle(color: Colors.white));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StoryTheme.storyAccent.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StoryTheme.storyAccent.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 18,
                color: StoryTheme.storyAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  incident['name']?.toString() ?? incidentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (incident['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              incident['description'].toString(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

