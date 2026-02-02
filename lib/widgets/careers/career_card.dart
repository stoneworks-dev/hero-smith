import 'package:flutter/material.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/theme/ds_theme.dart';
import 'package:hero_smith/widgets/shared/expandable_card.dart';

class CareerCard extends StatelessWidget {
  final Component career;

  const CareerCard({
    super.key,
    required this.career,
  });

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    final data = career.data;
    final name = career.name;
    final description = data['description'] as String? ?? '';

    return ExpandableCard(
      title: name,
      borderColor: theme.careerBorder,
      badge: Chip(
        label: Text(
          '💼 Career',
          style: theme.badgeTextStyle,
        ),
        backgroundColor: theme.careerBorder.withOpacity(0.1),
        side: BorderSide(color: theme.careerBorder, width: 1),
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
              '${theme.careerSectionEmoji['description']} Description',
              _buildDescriptionContent(description),
            ),
            const SizedBox(height: 16),
          ],
          _buildSection(
            context,
            '${theme.careerSectionEmoji['skills']} Skills & Languages',
            _buildSkillsContent(context, data),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '${theme.careerSectionEmoji['resources']} Starting Resources',
            _buildResourcesContent(context, data),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '${theme.careerSectionEmoji['perks']} Perks',
            _buildPerksContent(context, data),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '${theme.careerSectionEmoji['incitingIncidents']} Inciting Incidents',
            _buildIncitingIncidentsContent(context, data),
          ),
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

  Widget _buildSkillsContent(BuildContext context, Map<String, dynamic> data) {
    final skillsNumber = data['skills_number'] as int? ?? 0;
    final skillGroups = data['skill_groups'] as List<dynamic>? ?? [];
    final grantedSkills = data['granted_skills'] as List<dynamic>? ?? [];
    final skillGrantDescription =
        data['skill_grant_description'] as String? ?? '';
    final languages = data['languages'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skills summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withAlpha(50),
            border: Border.all(color: Colors.blue.shade700, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills: $skillsNumber total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade300,
                ),
              ),
              if (languages > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Languages: $languages',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade300,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Granted skills
        if (grantedSkills.isNotEmpty) ...[
          const Text(
            'Granted Skills:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grantedSkills.map((skill) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900.withAlpha(60),
                  border: Border.all(color: Colors.teal.shade600, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  skill.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade300,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Skill groups
        if (skillGroups.isNotEmpty) ...[
          const Text(
            'Available Skill Groups:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: skillGroups.map((group) {
              final groupName = group.toString();
              final capitalizedName = _capitalize(groupName);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withAlpha(60),
                  border: Border.all(color: Colors.purple.shade600, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  capitalizedName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.purple.shade300,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Skill grant description
        if (skillGrantDescription.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withAlpha(40),
              border: Border.all(color: Colors.amber.shade700, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              skillGrantDescription,
              style: TextStyle(
                color: Colors.amber.shade300,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResourcesContent(
      BuildContext context, Map<String, dynamic> data) {
    final renown = data['renown'] as int? ?? 0;
    final wealth = data['wealth'] as int? ?? 0;
    final projectPoints = data['project_points'] as int? ?? 0;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _buildResourceChip('Renown', renown, Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResourceChip('Wealth', wealth, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResourceChip(
                'Project\nPoints', projectPoints, Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String label, int value, MaterialColor color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade900.withAlpha(50),
        border: Border.all(color: color.shade700, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade400,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPerksContent(BuildContext context, Map<String, dynamic> data) {
    final perkType = data['perk_type'] as String? ?? '';
    final perksNumber = data['perks_number'] as int? ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade900.withAlpha(60),
        border: Border.all(color: Colors.purple.shade600, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perks: $perksNumber',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade300,
            ),
          ),
          if (perkType.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Type: $perkType',
              style: TextStyle(
                color: Colors.purple.shade400,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncitingIncidentsContent(
      BuildContext context, Map<String, dynamic> data) {
    final incitingIncidents =
        data['inciting_incidents'] as List<dynamic>? ?? [];

    if (incitingIncidents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withAlpha(80),
          border: Border.all(color: Colors.grey.shade700, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No inciting incidents defined',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: incitingIncidents.map<Widget>((incident) {
        final incidentMap = incident as Map<String, dynamic>;
        final name = incidentMap['name'] as String? ?? '';
        final description = incidentMap['description'] as String? ?? '';

        return _IncitingIncidentDropdown(
          name: name,
          description: description,
        );
      }).toList(),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _IncitingIncidentDropdown extends StatefulWidget {
  final String name;
  final String description;

  const _IncitingIncidentDropdown({
    required this.name,
    required this.description,
  });

  @override
  State<_IncitingIncidentDropdown> createState() =>
      _IncitingIncidentDropdownState();
}

class _IncitingIncidentDropdownState extends State<_IncitingIncidentDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withAlpha(50),
        border: Border.all(color: Colors.red.shade700, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name.isNotEmpty ? widget.name : 'Unnamed Incident',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && widget.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.description,
                style: TextStyle(
                  color: Colors.red.shade400,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
