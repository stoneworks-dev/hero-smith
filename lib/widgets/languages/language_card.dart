import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../shared/section_widgets.dart';
import '../shared/expandable_card.dart';

class LanguageCard extends StatelessWidget {
  final Component language;

  const LanguageCard({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final data = language.data;
    final region = data['region'] as String?;
    final ancestry = data['ancestry'] as String?;
    final langType = data['language_type'] as String?;
    final related = (data['related_languages'] as List?)?.cast<String>();
    final topics = (data['common_topics'] as List?)?.cast<String>();
    final ds = DsTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final neutralText = scheme.onSurface.withOpacity(0.9);
    final borderColor = ds.languageTypeBorder[langType ?? 'unknown'] ?? scheme.outlineVariant;

    return ExpandableCard(
      title: language.name,
      borderColor: borderColor,
      badge: langType != null 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${ds.languageTypeEmoji[langType] ?? '💬'} ${langType.toUpperCase()}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: borderColor.withOpacity(0.8),
              ),
            ),
          )
        : null,
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (region != null && region.isNotEmpty) ...[
            SectionLabel('Region', emoji: ds.languageSectionEmoji['region'], color: borderColor),
            const SizedBox(height: 2),
            _buildIndentedText(region, neutralText),
          ],
          if (ancestry != null && ancestry.isNotEmpty) ...[
            SectionLabel('Ancestry', emoji: ds.languageSectionEmoji['ancestry'], color: borderColor),
            const SizedBox(height: 2),
            _buildIndentedText(ancestry, neutralText),
          ],
          if (related != null && related.isNotEmpty) ...[
            SectionLabel('Related Languages', emoji: ds.languageSectionEmoji['related'], color: borderColor),
            const SizedBox(height: 2),
            _buildBulletedList(related, neutralText),
          ],
          if (topics != null && topics.isNotEmpty) ...[
            SectionLabel('Common Topics', emoji: ds.languageSectionEmoji['topics'], color: borderColor),
            const SizedBox(height: 2),
            _buildBulletedList(topics, neutralText),
          ],
        ],
      ),
    );
  }

  // Removed: local type badge, replaced by themed text badge

  // Removed: local section label, using SectionLabel widget

  Widget _buildIndentedText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
        maxLines: 8,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBulletedList(List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 2, right: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(fontSize: 11, color: color),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}