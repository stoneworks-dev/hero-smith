import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/component.dart';
import '../../core/theme/ds_theme.dart';
import '../abilities/ability_expandable_item.dart';
import '../shared/section_widgets.dart';
import '../shared/expandable_card.dart';

class TitleCard extends ConsumerWidget {
  final Component titleComp;
  const TitleCard({super.key, required this.titleComp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = titleComp.data;
    final int echelon = (data['echelon'] as num?)?.toInt() ?? 0;
    final String? prerequisite = data['prerequisite'] as String?;
    final String? description = data['description_text'] as String?;
  final List<dynamic>? benefits = data['benefits'] as List<dynamic>?;
    final String? special = data['special'] as String?;

  final ds = DsTheme.of(context);
  final scheme = Theme.of(context).colorScheme;
  final borderColor = ds.titleEchelonBorder[echelon] ?? ds.titleEchelonBorder[0]!;
  final neutralText = scheme.onSurface.withOpacity(0.9);

    return ExpandableCard(
      title: titleComp.name,
      borderColor: borderColor,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.1),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          echelon > 0 ? 'E$echelon' : 'E?',
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
          if (prerequisite != null && prerequisite.isNotEmpty) ...[
            SectionLabel('Prerequisite', emoji: '🗝️', color: borderColor),
            const SizedBox(height: 2),
            _buildIndentedText(prerequisite, neutralText),
          ],
          if (description != null && description.isNotEmpty) ...[
            SectionLabel('Description', emoji: '📝', color: borderColor),
            const SizedBox(height: 2),
            _buildIndentedText(description, neutralText),
          ],
          if (benefits != null && benefits.isNotEmpty) ...[
            SectionLabel('Benefits', emoji: '🎁', color: borderColor),
            const SizedBox(height: 2),
            _buildBenefits(benefits, neutralText, ref, borderColor),
          ],
          if (special != null && special.isNotEmpty) ...[
            SectionLabel('Special', emoji: '✨', color: ds.specialSectionColor),
            const SizedBox(height: 2),
            _buildIndentedText(special, neutralText),
          ],
        ],
      ),
    );
  }

  // Removed colored badge; using neutral text badge

  Widget _buildInfoRow(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: textColor),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Minimal chips-style: render each benefit as an icon + text row
  Widget _buildBenefits(List<dynamic> benefits, Color textColor, WidgetRef ref, Color accentColor) {
    if (benefits.isEmpty) {
      return _buildInfoRow(Icons.card_giftcard_outlined, 'No listed benefits', textColor);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in benefits.where((b) => b != null))
            _buildBenefitWidget(b, textColor, ref, accentColor),
        ],
      ),
    );
  }
  
  Widget _buildBenefitWidget(dynamic b, Color textColor, WidgetRef ref, Color accentColor) {
    if (b is String) {
      return _buildBulletRow(b, textColor);
    }
    if (b is Map) {
      final ability = b['ability'];
      final name = b['name'] as String? ?? '';
      final description = b['description'] as String? ?? b['desc'] as String? ?? b['text'] as String? ?? '';
      
      // If there's an ability, show expanded ability card
      if (ability is String && ability.trim().isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty) ...[
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (description.isNotEmpty) ...[
              _buildBulletRow(description, textColor),
              const SizedBox(height: 4),
            ],
            _buildAbilityLookup(ability, ref, textColor, accentColor),
            const SizedBox(height: 8),
          ],
        );
      }
      
      // No ability - just show text
      final formatted = _formatBenefit(b);
      if (formatted.isNotEmpty) {
        return _buildBulletRow(formatted, textColor);
      }
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildAbilityLookup(String abilityName, WidgetRef ref, Color textColor, Color accentColor) {
    final abilityAsync = ref.watch(abilityByNameProvider(abilityName));
    
    return abilityAsync.when(
      data: (ability) {
        if (ability == null) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '⚔️ Ability: $abilityName',
              style: TextStyle(fontSize: 11, color: textColor, fontStyle: FontStyle.italic),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AbilityExpandableItem(component: ability, embedded: true),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text('Loading $abilityName...', style: TextStyle(fontSize: 10, color: textColor)),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          '⚔️ Ability: $abilityName',
          style: TextStyle(fontSize: 11, color: textColor, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  String _formatBenefit(dynamic b) {
    // Strings are passed through
    if (b is String) return b;
    // Maps may contain ability, grants, text, or other fields
    if (b is Map) {
      final ability = b['ability'];
      final grants = b['grants'];
      final text = b['text'] ?? b['description'] ?? b['desc'];

      final parts = <String>[];
      if (ability is String && ability.trim().isNotEmpty) {
        parts.add('Ability: $ability');
      }
      if (grants is List) {
        final grantParts = <String>[];
        for (final g in grants) {
          if (g is Map) {
            final type = g['type'];
            final value = g['value'] ?? g['count'];
            String spec = '';
            final specific = g['specific'];
            if (specific is List && specific.isNotEmpty) {
              spec = ' (${specific.join(', ')})';
            }
            final typeStr = type is String ? type : 'grant';
            final valStr = value != null ? ' +$value' : '';
            grantParts.add('${_titleCase(typeStr)}$valStr$spec');
          } else if (g is String) {
            grantParts.add(g);
          }
        }
        if (grantParts.isNotEmpty) {
          parts.add('Grants: ${grantParts.join(', ')}');
        }
      }
      if (text is String && text.trim().isNotEmpty) {
        parts.add(text);
      }

      if (parts.isNotEmpty) return parts.join('; ');

      // Fallback: surface key details if present
      final keys = b.keys.cast<String>().toList();
      keys.sort();
      final kv = keys.map((k) => '$k: ${b[k]}').join(', ');
      return kv;
    }
    // Unknown type fallback
    return b.toString();
  }

  // Removed local section label; using SectionLabel

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

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

  Widget _buildBulletRow(String text, Color color) {
    return Padding(
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
              text,
              style: TextStyle(fontSize: 11, color: color),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
