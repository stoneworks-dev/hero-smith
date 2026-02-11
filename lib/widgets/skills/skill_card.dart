import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../../core/theme/navigation_theme.dart';

/// Compact ListTile-based skill card used in both the hero sheet and main pages.
class SkillCard extends StatelessWidget {
  final Component skill;

  /// Remove this skill from the hero (X button in trailing). Used on the hero sheet.
  final VoidCallback? onRemove;

  /// Delete this custom component entirely (trash icon in trailing). Used on main pages.
  final VoidCallback? onDelete;

  const SkillCard({
    super.key,
    required this.skill,
    this.onRemove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = skill.data;
    final group = (data['group'] as String?) ?? 'other';
    final description = data['description'] as String? ?? '';

    final ds = DsTheme.of(context);
    final borderColor =
        ds.skillGroupBorder[group] ?? Theme.of(context).colorScheme.outlineVariant;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: borderColor.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.miscellaneous_services, color: borderColor, size: 18),
        ),
        title: Text(
          skill.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: description.isNotEmpty
            ? Text(
                description,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: _buildTrailing(ds, group, borderColor, onSurface),
      ),
    );
  }

  Widget _buildTrailing(DsTheme ds, String group, Color borderColor, Color onSurface) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: borderColor.withAlpha(38),
            border: Border.all(color: borderColor.withAlpha(128), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${ds.skillGroupEmoji[group] ?? '\ud83e\udde9'} ${group.toUpperCase()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: onSurface.withAlpha(230),
            ),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
              tooltip: 'Delete custom skill',
              onPressed: onDelete,
            ),
          ),
        ],
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
              tooltip: 'Remove skill',
              onPressed: onRemove,
            ),
          ),
        ],
      ],
    );
  }
}
