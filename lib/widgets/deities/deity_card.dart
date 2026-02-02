import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../shared/section_widgets.dart';
import '../shared/expandable_card.dart';

class DeityCard extends StatelessWidget {
  final Component deity;
  const DeityCard({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final data = deity.data;
    final category = (data['category'] as String?) ?? 'other';
    final domains = (data['domains'] as List?)?.cast<String>() ?? const <String>[];

  final ds = DsTheme.of(context);
  final scheme = Theme.of(context).colorScheme;
  final borderColor = ds.deityCategoryBorder[category] ?? scheme.outlineVariant;

    return ExpandableCard(
      title: deity.name,
      borderColor: borderColor,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.1),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${ds.deityCategoryEmoji[category] ?? '🔰'} ${category.toUpperCase()}',
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
          if (domains.isNotEmpty) ...[
            SectionLabel('Domains', emoji: ds.deitySectionEmoji['domains'], color: borderColor),
            const SizedBox(height: 2),
            _buildBulletedList(domains, scheme.onSurface.withOpacity(0.9)),
          ],
        ],
      ),
    );
  }

  // Removed local badge/label helpers in favor of DsTheme + shared widgets

  Widget _buildBulletedList(List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => BulletRow(e)).toList(),
    );
  }
}
