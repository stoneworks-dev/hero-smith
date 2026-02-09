import 'package:flutter/material.dart';

import '../../core/models/component.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import 'abilities_shared.dart';

class AbilityFullView extends StatelessWidget {
  const AbilityFullView({
    super.key,
    required this.component,
    this.abilityData,
  });

  final Component component;
  final AbilityData? abilityData;

  @override
  Widget build(BuildContext context) {
    final ability = abilityData ?? AbilityData.fromComponent(component);
    final sections = <Widget>[];

    // Only show power roll section if ability has a power roll
    if (ability.hasPowerRoll) {
      sections.add(_buildPowerRollSection(context, ability));
    }

    // Show effect text (non-tier based effects)
    if (ability.effect != null && ability.effect!.isNotEmpty) {
      sections.add(_buildLabeledText(context, 'Effect', ability.effect!));
    }

    // Show special effect text
    if (ability.specialEffect != null && ability.specialEffect!.isNotEmpty) {
      sections.add(_buildLabeledText(context, 'Special', ability.specialEffect!));
    }

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          sections[i],
        ],
      ],
    );
  }

  Widget _buildPowerRollSection(BuildContext context, AbilityData ability) {
    final headerChildren = <Widget>[
      Text(
        ability.powerRollLabel ?? 'Power roll',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.grey.shade200,
        ),
      ),
    ];

    if (ability.characteristics.isNotEmpty) {
      headerChildren.add(const SizedBox(width: 8));
      headerChildren.add(Text(
        '+',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey.shade300,
        ),
      ));
      headerChildren.add(const SizedBox(width: 6));
      headerChildren.add(Wrap(
        spacing: 6,
        runSpacing: 4,
        children: ability.characteristics
            .map((char) => _buildCharacteristicChip(context, char))
            .toList(),
      ));
    } else if (ability.characteristicSummary != null) {
      headerChildren.add(const SizedBox(width: 8));
      headerChildren.add(Text(
        '+ ${ability.characteristicSummary}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey.shade300,
        ),
      ));
    }

    final rows = ability.tiers
        .map((tier) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade800,
                    ),
                    child: Text(
                      tier.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AbilityTextHighlighter.highlightGameMechanics(
                          tier.primaryText,
                          context,
                          baseStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade200,
                          ),
                        ),
                        if (tier.secondaryText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child:
                                AbilityTextHighlighter.highlightGameMechanics(
                              tier.secondaryText!,
                              context,
                              baseStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: headerChildren,
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ],
      ],
    );
  }

  Widget _buildCharacteristicChip(BuildContext context, String label) {
    final color = CharacteristicTokens.color(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildLabeledText(
    BuildContext context,
    String label,
    String text,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 4),
        AbilityTextHighlighter.highlightGameMechanics(
          text,
          context,
          baseStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
