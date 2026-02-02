import 'package:flutter/material.dart';

import '../../../core/models/downtime.dart';
import '../../../core/text/heroes_sheet/gear/gear_widgets_text.dart';
import 'gear_utils.dart';

/// Card displaying an item imbuement with expandable details.
class ImbuementCard extends StatefulWidget {
  final DowntimeEntry imbuement;

  const ImbuementCard({super.key, required this.imbuement});

  @override
  State<ImbuementCard> createState() => _ImbuementCardState();
}

class _ImbuementCardState extends State<ImbuementCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _getTypeDisplay(String imbuementType) {
    switch (imbuementType) {
      case 'armor_imbuement':
        return GearWidgetsText.imbuementTypeArmor;
      case 'weapon_imbuement':
        return GearWidgetsText.imbuementTypeWeapon;
      case 'implement_imbuement':
        return GearWidgetsText.imbuementTypeImplement;
      case 'shield_imbuement':
        return GearWidgetsText.imbuementTypeShield;
      default:
        return imbuementType.replaceAll('_', ' ');
    }
  }

  IconData _getTypeIcon(String imbuementType) {
    switch (imbuementType) {
      case 'armor_imbuement':
        return Icons.shield;
      case 'weapon_imbuement':
        return Icons.sports_martial_arts;
      case 'implement_imbuement':
        return Icons.auto_awesome;
      case 'shield_imbuement':
        return Icons.security;
      default:
        return Icons.auto_fix_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imbuementType = widget.imbuement.raw['type'] as String? ?? '';
    final level = widget.imbuement.raw['level'] as int?;
    final description = widget.imbuement.raw['description'] as String? ?? '';
    final typeDisplay = _getTypeDisplay(imbuementType);
    final typeIcon = _getTypeIcon(imbuementType);

    // Use orange scheme matching treasure card styling exactly
    const primaryColor = Colors.orange;
    final cardBorderColor = theme.brightness == Brightness.dark
      ? primaryColor.shade600.withOpacity(0.3)
      : primaryColor.shade300.withOpacity(0.5);
    final cardBgColor = theme.brightness == Brightness.dark
      ? const Color.fromARGB(255, 37, 36, 36)
      : Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardBorderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and expand icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeIcon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.imbuement.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Type and level tags
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeDisplay.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (level != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getLevelColor(level),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${GearWidgetsText.imbuementLevelPrefix}$level',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Expandable content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                            ? primaryColor.shade800.withOpacity(0.2)
                            : primaryColor.shade50.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                              ? primaryColor.shade600.withOpacity(0.5)
                              : primaryColor.shade300.withOpacity(0.8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_fix_high,
                                  size: 14,
                                  color: primaryColor.shade400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  GearWidgetsText.imbuementEffectLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: primaryColor.shade400,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
