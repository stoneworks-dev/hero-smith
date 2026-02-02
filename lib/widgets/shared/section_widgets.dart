import 'package:flutter/material.dart';
import '../../core/theme/ds_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final String? emoji;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.emoji, this.color});

  @override
  Widget build(BuildContext context) {
    final ds = DsTheme.of(context);
    final effectiveColor = color ?? ds.sectionLabelStyle.color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.85);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.label_outline, size: 12, color: effectiveColor.withOpacity(0.9)),
        const SizedBox(width: 4),
        if (emoji != null) Text('$emoji ', style: ds.sectionLabelStyle.copyWith(color: effectiveColor)),
        Text(text, style: ds.sectionLabelStyle.copyWith(color: effectiveColor)),
      ],
    );
  }
}

class BulletRow extends StatelessWidget {
  final String text;
  const BulletRow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.9);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Text('•', style: TextStyle(color: color, height: 1.25)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 11, height: 1.25),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
