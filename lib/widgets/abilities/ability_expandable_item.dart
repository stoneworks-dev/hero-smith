import 'package:flutter/material.dart';

import '../../core/models/component.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/semantic/semantic_tokens.dart';
import 'abilities_shared.dart';
import 'ability_full_view.dart';
import 'ability_summary.dart';

class AbilityExpandableItem extends StatefulWidget {
  const AbilityExpandableItem({
    super.key, 
    required this.component,
    this.embedded = false,
  });

  final Component component;
  /// When true, removes margins and adjusts styling for embedding inside other cards
  final bool embedded;

  @override
  State<AbilityExpandableItem> createState() => _AbilityExpandableItemState();
}

class _AbilityExpandableItemState extends State<AbilityExpandableItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ability = AbilityData.fromComponent(widget.component);

    // Use action type color for border, fallback to grey if no action type
    final borderColor = ability.actionType != null
        ? ActionTokens.color(ability.actionType!)
        : Colors.grey.shade600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: widget.embedded 
          ? EdgeInsets.zero 
          : const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(widget.embedded ? 10 : 14),
        border: Border.all(
          color: _expanded ? borderColor : borderColor.withValues(alpha: 0.5),
          width: _expanded ? 2.0 : 1.0,
        ),
        boxShadow: widget.embedded ? null : [
          BoxShadow(
            color: borderColor.withValues(alpha: _expanded ? 0.25 : 0.15),
            blurRadius: _expanded ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.embedded ? 10 : 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.embedded ? 10 : 14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: widget.embedded 
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AbilitySummary(
                        component: widget.component,
                        abilityData: ability,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: borderColor,
                    ),
                  ],
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Divider(
                                color: borderColor.withValues(alpha: 0.4),
                                thickness: 1,
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              AbilityFullView(
                                component: widget.component,
                                abilityData: ability,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
