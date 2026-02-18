import 'package:flutter/material.dart';

import '../../core/models/component.dart';
import '../../core/text/widgets/ability_widget_text.dart';
import '../../core/theme/ability_colors.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icon_data.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import '../../core/theme/form_theme.dart';
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
        : FormTheme.textSecondary;
    final metadataColor = FormTheme.textMuted;
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
                    AbilityWidgetText.levelLabel(ability.level!),
                    FormTheme.border,
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
                      FormTheme.textBright,
                    ),
                  ),
                if (ability.actionType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildBadge(
                      context,
                      ability.actionType!,
                      ActionTokens.color(ability.actionType!),
                      FormTheme.textBright,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (ability.keywords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 2,
              runSpacing: 4,
              children: [
                for (var i = 0; i < ability.keywords.length; i++) ...[
                  Text(
                    ability.keywords[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AbilityColors.getKeywordColor(ability.keywords[i]),
                    ),
                  ),
                  if (i < ability.keywords.length - 1)
                    Text(
                      ', ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ],
            ),
          ),
        if (ability.triggerText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildAppIconInfoRow(
              context,
              AppIcons.abilities.triggered,
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
                _buildColoredInfoRow(context, AppIcons.abilities.range, ability.rangeSummary!, const Color(0xFFFFB74D)),
              if (ability.targets != null)
                _buildColoredInfoRow(context, AppIcons.abilities.target, ability.targets!, const Color(0xFF4DD0E1)),
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
    // Level badge (neutral grey) needs brighter text than colored badges
    final isNeutral = background == FormTheme.border;
    final textColor = isNeutral
        ? Colors.grey.shade300
        : background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background.withValues(alpha: 0.15),
        border: Border.all(
          color: background.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
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
          color: FormTheme.textMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: FormTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppIconInfoRow(BuildContext context, AppIconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
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

  Widget _buildColoredInfoRow(BuildContext context, AppIconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          icon,
          size: 16,
          color: color.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
