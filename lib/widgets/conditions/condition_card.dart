import 'package:flutter/material.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/widgets/shared/expandable_card.dart';

class ConditionCard extends StatelessWidget {
  final Component condition;
  final VoidCallback? onDelete;

  const ConditionCard({
    super.key,
    required this.condition,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = condition.data;
    final name = condition.name;
    final shortDescription = data['short_description'] as String? ?? '';
    final longDescription = data['long_description'] as String? ?? '';

    return ExpandableCard(
      title: name,
      borderColor: Colors.red.shade400,
      badge: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: const Text(
              '⚠️ Condition',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.red.shade400.withOpacity(0.1),
            side: BorderSide(color: Colors.red.shade400, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (onDelete != null && condition.source == 'user') ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              tooltip: 'Delete custom condition',
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shortDescription.isNotEmpty) ...[
            _buildSection(
              context,
              '📋 Summary',
              _buildDescriptionContent(shortDescription),
            ),
            const SizedBox(height: 16),
          ],
          if (longDescription.isNotEmpty) ...[
            _buildSection(
              context,
              '📖 Details',
              _buildDescriptionContent(longDescription),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildDescriptionContent(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 55, 55, 55),
        border: Border.all(color: const Color.fromARGB(255, 63, 63, 63), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        description,
        style: const TextStyle(
          height: 1.4,
          fontSize: 14,
        ),
      ),
    );
  }
}