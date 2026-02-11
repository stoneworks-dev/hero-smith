import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../../core/theme/navigation_theme.dart';

/// Compact ListTile-based language card used in both the hero sheet and main pages.
class LanguageCard extends StatelessWidget {
  final Component language;

  /// Remove this language from the hero (X button in trailing). Used on the hero sheet.
  final VoidCallback? onRemove;

  /// Delete this custom component entirely (trash icon in trailing). Used on main pages.
  final VoidCallback? onDelete;

  const LanguageCard({
    super.key,
    required this.language,
    this.onRemove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = language.data;
    final region = data['region'] as String? ?? '';
    final ancestry = data['ancestry'] as String? ?? '';
    final langType = data['language_type'] as String?;
    final commonTopics = (data['common_topics'] as List?)?.cast<String>() ?? [];
    final relatedLanguages = (data['related_languages'] as List?)?.cast<String>() ?? [];

    final ds = DsTheme.of(context);
    final borderColor =
        ds.languageTypeBorder[langType ?? 'unknown'] ?? Theme.of(context).colorScheme.outlineVariant;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Build subtitle lines
    final subtitleParts = <String>[];
    if (region.isNotEmpty) {
      subtitleParts.add('Region: $region');
    }
    if (ancestry.isNotEmpty) {
      subtitleParts.add('Ancestry: $ancestry');
    }
    if (commonTopics.isNotEmpty) {
      subtitleParts.add('Topics: ${commonTopics.join(', ')}');
    }
    if (relatedLanguages.isNotEmpty) {
      subtitleParts.add('Related: ${relatedLanguages.join(', ')}');
    }
    final subtitle = subtitleParts.join(' \u2022 ');

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
          child: Icon(Icons.record_voice_over, color: borderColor, size: 18),
        ),
        title: Text(
          language.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              )
            : null,
        trailing: _buildTrailing(ds, langType, borderColor, onSurface),
      ),
    );
  }

  Widget _buildTrailing(DsTheme ds, String? langType, Color borderColor, Color onSurface) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Type badge
        if (langType != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor.withAlpha(38),
              border: Border.all(color: borderColor.withAlpha(128), width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${ds.languageTypeEmoji[langType] ?? '\ud83d\udcac'} ${langType.toUpperCase()}',
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
              tooltip: 'Delete custom language',
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
              tooltip: 'Remove language',
              onPressed: onRemove,
            ),
          ),
        ],
      ],
    );
  }
}