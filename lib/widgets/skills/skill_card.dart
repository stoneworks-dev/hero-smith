import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../shared/section_widgets.dart';
import '../shared/expandable_card.dart';

class SkillCard extends StatelessWidget {
  final Component skill;

  const SkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final data = skill.data;
    final group = (data['group'] as String?) ?? 'other';
    final description = data['description'] as String?;

    final ds = DsTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final Color borderColor = ds.skillGroupBorder[group] ?? scheme.outlineVariant;
    final Color neutralText = scheme.onSurface.withOpacity(0.9);

    return ExpandableCard(
      title: skill.name,
      borderColor: borderColor,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.1),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${ds.skillGroupEmoji[group] ?? '🧩'} ${group.toUpperCase()}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: borderColor.withOpacity(0.8),
          ),
        ),
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel('Group', emoji: '📂', color: borderColor),
          const SizedBox(height: 2),
          _buildIndentedText(_titleCase(group), neutralText),
          if (description != null && description.isNotEmpty) ...[
            SectionLabel('Description', emoji: '📝', color: borderColor),
            const SizedBox(height: 2),
            _buildIndentedText(description, neutralText),
          ],
        ],
      ),
    );
  }

  // Removed local badge and section label; using DsTheme + SectionLabel

  Widget _buildIndentedText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
