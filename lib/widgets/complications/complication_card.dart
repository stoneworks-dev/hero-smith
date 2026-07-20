import 'package:flutter/material.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/theme/ds_theme.dart';
import 'package:hero_smith/widgets/shared/expandable_card.dart';

class ComplicationCard extends StatelessWidget {
  final Component complication;
  final bool showGrants;

  const ComplicationCard({
    super.key,
    required this.complication,
    this.showGrants = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    final data = complication.data;
    final name = complication.name;
    final description = data['description'] as String? ?? '';
    final effects = data['effects'] as Map<String, dynamic>?;
    final grants = data['grants'];

    return ExpandableCard(
      title: name,
      borderColor: theme.complicationBorder,
      badge: Chip(
        label: Text(
          '⚔️ Complication',
          style: theme.badgeTextStyle,
        ),
        backgroundColor: theme.complicationBorder.withOpacity(0.1),
        side: BorderSide(color: theme.complicationBorder, width: 1),
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
              '${theme.complicationSectionEmoji['description']} Description',
              _buildDescriptionContent(description),
            ),
            const SizedBox(height: 16),
          ],
          if (effects != null && effects.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.complicationSectionEmoji['effects']} Effects',
              _buildEffectsContent(context, effects),
            ),
            const SizedBox(height: 16),
          ],
          if (showGrants && _hasGrantContent(grants)) ...[
            _buildSection(
              context,
              '${theme.complicationSectionEmoji['grants']} Grants',
              _buildGrantsContent(context, grants),
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

  Widget _buildEffectsContent(
      BuildContext context, Map<String, dynamic> effects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effects['benefit'] != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade900.withAlpha(60),
              border: Border.all(color: Colors.teal.shade600, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Benefit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effects['benefit'].toString(),
                  style: TextStyle(
                    color: Colors.teal.shade200,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (effects['drawback'] != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D)
                  .withAlpha(60), // Deep crimson background
              border: Border.all(color: const Color(0xFFB71C1C), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '❌ Drawback',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effects['drawback'].toString(),
                  style: TextStyle(
                    color: Colors.red.shade200,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (effects['both'] != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withAlpha(40),
              border: Border.all(color: Colors.amber.shade700, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚖️ Mixed Effect',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effects['both'].toString(),
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _hasGrantContent(Object? grants) {
    if (grants is List) return grants.isNotEmpty;
    if (grants is Map) return grants.isNotEmpty;
    return false;
  }

  Widget _buildGrantsContent(BuildContext context, Object? grants) {
    final List<Widget> grantWidgets = [];

    final canonicalGrants = _canonicalGrantList(grants);
    if (canonicalGrants != null) {
      for (final grant in canonicalGrants) {
        if (grant is Map) {
          final displayText = _formatCanonicalGrant(
            grant.cast<String, dynamic>(),
          );
          if (displayText != null) {
            grantWidgets.add(_buildGrantItem(displayText));
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grantWidgets,
      );
    }

    if (grants is! Map) {
      return const SizedBox.shrink();
    }

    final legacyGrants = grants.cast<String, dynamic>();

    legacyGrants.forEach((key, value) {
      switch (key) {
        case 'treasures':
          if (value is List) {
            for (final treasure in value) {
              final treasureMap = treasure as Map<String, dynamic>;
              final type = treasureMap['type'] ?? 'treasure';
              final echelon = treasureMap['echelon'];
              final choice = treasureMap['choice'] == true;

              String displayText = 'Treasure: $type';
              if (echelon != null) {
                displayText += ' (Echelon $echelon)';
              }
              if (choice) {
                displayText += ' (your choice)';
              }

              grantWidgets.add(_buildGrantItem(displayText));
            }
          }
          break;
        case 'tokens':
          if (value is Map) {
            final tokenMap = value as Map<String, dynamic>;
            if (tokenMap.containsKey('name') && tokenMap.containsKey('count')) {
              final tokenType = tokenMap['name'];
              final amount = tokenMap['count'];
              grantWidgets.add(_buildGrantItem(
                  '$amount $tokenType token${amount == 1 ? '' : 's'}'));
            } else {
              tokenMap.forEach((tokenType, amount) {
                grantWidgets.add(_buildGrantItem(
                    '$amount $tokenType token${amount == 1 ? '' : 's'}'));
              });
            }
          }
          break;
        default:
          // Handle other grant types generically
          grantWidgets.add(_buildGrantItem('$key: $value'));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grantWidgets,
    );
  }

  List<Object?>? _canonicalGrantList(Object? grants) {
    if (grants is List) {
      final hasCanonicalKind = grants.any(
        (item) => item is Map && item.containsKey('kind'),
      );
      return hasCanonicalKind ? grants.cast<Object?>() : null;
    }
    if (grants is Map) {
      if (grants['schema'] == 'hero_smith.grants.v1' &&
          grants['grants'] is List) {
        return (grants['grants'] as List).cast<Object?>();
      }
      if (grants.containsKey('kind')) return [grants];
    }
    return null;
  }

  String? _formatCanonicalGrant(Map<String, dynamic> grant) {
    switch (grant['kind']?.toString()) {
      case 'entry':
        final entryType = grant['entry_type']?.toString() ?? 'entry';
        final payload = grant['payload'];
        final name = payload is Map ? payload['name']?.toString() : null;
        final label = grant['label']?.toString();
        final entryId = grant['entry_id']?.toString();
        final displayName = name ?? label ?? entryId ?? entryType;
        return '${entryType.replaceAll('_', ' ')}: $displayName';
      case 'token':
        final token = grant['token']?.toString() ?? 'token';
        final amount = grant['max_value'] ?? grant['count'] ?? grant['value'];
        return '$amount $token token${amount == 1 ? '' : 's'}';
      default:
        return grant['label']?.toString();
    }
  }

  Widget _buildGrantItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
