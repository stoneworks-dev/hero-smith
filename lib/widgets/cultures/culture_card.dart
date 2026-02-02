import 'package:flutter/material.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/theme/ds_theme.dart';
import 'package:hero_smith/widgets/shared/expandable_card.dart';

class CultureCard extends StatelessWidget {
  final Component culture;

  const CultureCard({
    super.key,
    required this.culture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    final data = culture.data;
    final name = culture.name;
    final description = data['description'] as String? ?? '';
    final skillGroups = data['skillGroups'] as List<dynamic>?;
    final specificSkills = data['specificSkills'] as List<dynamic>?;
    final skillDescription = data['skillDescription'] as String? ?? '';

    // Determine culture type and get appropriate theming
    final cultureType = culture.type;
    final borderColor =
        theme.cultureTypeBorder[cultureType] ?? Colors.grey.shade300;
    final typeEmoji = theme.cultureTypeEmoji[cultureType] ?? '🏛️';

    // Create type-specific badge text
    final badgeText = switch (cultureType) {
      'culture_environment' => '$typeEmoji Environment',
      'culture_organisation' => '$typeEmoji Organization',
      'culture_upbringing' => '$typeEmoji Upbringing',
      _ => '$typeEmoji Culture',
    };

    return ExpandableCard(
      title: name,
      borderColor: borderColor,
      badge: Chip(
        label: Text(
          badgeText,
          style: theme.badgeTextStyle,
        ),
        backgroundColor: borderColor.withOpacity(0.1),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.cultureSectionEmoji['description']} Description',
              _buildDescriptionContent(description),
            ),
            const SizedBox(height: 16),
          ],
          if (skillGroups != null && skillGroups.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.cultureSectionEmoji['skillGroups']} Skill Groups',
              _buildSkillGroupsContent(context, skillGroups),
            ),
            const SizedBox(height: 16),
          ],
          if (specificSkills != null && specificSkills.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.cultureSectionEmoji['specificSkills']} Specific Skills',
              _buildSpecificSkillsContent(context, specificSkills),
            ),
            const SizedBox(height: 16),
          ],
          if (skillDescription.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.cultureSectionEmoji['skillGroups']} Skill Selection',
              _buildSkillDescriptionContent(skillDescription),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, Widget content) {
    final theme = DsTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: theme.sectionLabelStyle,
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildDescriptionContent(String description) {
    return Text(
      description,
      style: const TextStyle(height: 1.4),
    );
  }

  Widget _buildSkillGroupsContent(
      BuildContext context, List<dynamic> skillGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: skillGroups.map((group) {
        final groupName = group.toString();
        final capitalizedName = _capitalize(groupName);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withAlpha(60),
            border: Border.all(color: Colors.blue.shade700, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            capitalizedName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade300,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecificSkillsContent(
      BuildContext context, List<dynamic> specificSkills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specificSkills.map((skill) {
        final skillName = skill.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.shade900.withAlpha(60),
            border: Border.all(color: Colors.teal.shade600, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            skillName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.teal.shade300,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillDescriptionContent(String skillDescription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withAlpha(40),
        border: Border.all(color: Colors.amber.shade700, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        skillDescription,
        style: TextStyle(
          color: Colors.amber.shade300,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
