import 'package:flutter/material.dart';

import '../../core/models/component.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import 'abilities_shared.dart';

class AbilitySummary extends StatelessWidget {
  const AbilitySummary({
    super.key,
    required this.component,
    this.abilityData,
  });

  final Component component;
  final AbilityData? abilityData;

  @override
  Widget build(BuildContext context) {
    final ability = abilityData ?? AbilityData.fromComponent(component);

    final resourceColor = ability.resourceType != null
        ? HeroicResourceTokens.color(ability.resourceType!)
        : Colors.grey.shade400;
    final metadataColor = Colors.grey.shade500;
    final resourceLabel = ability.resourceLabel;
    final costAmount = ability.costAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: ability.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.grey.shade100,
                      ),
                      children: [
                        if (ability.costString != null && resourceLabel == null)
                          TextSpan(
                            text: ' (${ability.costString})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: resourceColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (ability.flavor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        ability.flavor!,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: metadataColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ability.level != null)
                  _buildBadge(
                    context,
                    'Level ${ability.level}',
                    Colors.grey.shade700,
                    Colors.grey.shade200,
                  ),
                if (resourceLabel != null)
                  Padding(
                    padding: EdgeInsets.only(top: ability.level != null ? 6 : 0),
                    child: _buildBadge(
                      context,
                      costAmount != null && costAmount > 0
                          ? '$resourceLabel $costAmount'
                          : resourceLabel,
                      resourceColor,
                      Colors.white,
                    ),
                  ),
                if (ability.actionType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildBadge(
                      context,
                      ability.actionType!,
                      ActionTokens.color(ability.actionType!),
                      Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (ability.keywords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              ability.keywords.join(', '),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        if (ability.triggerText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildInfoRow(
              context,
              Icons.bolt,
              'Trigger: ${ability.triggerText}',
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (ability.rangeSummary != null)
                _buildInfoRow(context, Icons.straighten, ability.rangeSummary!),
              if (ability.targets != null)
                _buildInfoRow(context, Icons.adjust, ability.targets!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background.withValues(alpha: 0.85),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}
