import 'package:flutter/material.dart';

import '../../../core/models/component.dart' as model;
import '../../../core/text/heroes_sheet/gear/kit_widgets_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';
import '../../../widgets/kits/equipment_card.dart';

/// Wrapper widget that displays a favorite kit using the appropriate existing kit card
/// and adds action buttons for remove from favorites and swap.
/// Cards start collapsed and expand when clicked.
class FavoriteKitCardWrapper extends StatelessWidget {
  const FavoriteKitCardWrapper({
    super.key,
    required this.kit,
    required this.isEquipped,
    required this.onSwap,
    required this.onRemoveFavorite,
    this.equippedSlotLabel,
  });

  final model.Component kit;
  final bool isEquipped;
  final VoidCallback onSwap;
  final VoidCallback onRemoveFavorite;
  final String? equippedSlotLabel;

  String? _getBadgeLabel(String type) {
    switch (type) {
      case 'psionic_augmentation':
        return KitWidgetsText.badgeAugmentation;
      case 'prayer':
        return KitWidgetsText.badgePrayer;
      case 'enchantment':
        return KitWidgetsText.badgeEnchantment;
      default:
        return null;
    }
  }

  Widget _buildKitCard() {
    return EquipmentCard(
      component: kit,
      badgeLabel: _getBadgeLabel(kit.type),
      initiallyExpanded: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row above the card
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Row(
              children: [
                // Equipped badge or Swap button
                if (isEquipped)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NavigationTheme.kitsColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: NavigationTheme.kitsColor.withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          equippedSlotLabel != null
                              ? '${KitWidgetsText.equippedBadgeWithSlotPrefix}$equippedSlotLabel'
                              : KitWidgetsText.equippedBadgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Material(
                    color: FormTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: onSwap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.published_with_changes,
                              size: 12,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              KitWidgetsText.swapButtonLabel,
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                // Favorite heart button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onRemoveFavorite,
                    borderRadius: BorderRadius.circular(16),
                    child: Tooltip(
                      message: KitWidgetsText.removeFavoriteTooltip,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: FormTheme.surface.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main card with left accent border
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquipped
                    ? NavigationTheme.kitsColor
                    : Colors.grey.shade800,
                width: isEquipped ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent strip for equipped
                  if (isEquipped)
                    Container(
                      width: 4,
                      color: NavigationTheme.kitsColor,
                    ),
                  // The actual kit card
                  Expanded(child: _buildKitCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legacy card for reference - kept for backwards compatibility.
@Deprecated('Use FavoriteKitCardWrapper instead')
class KitFavoriteCard extends StatelessWidget {
  const KitFavoriteCard({
    super.key,
    required this.kit,
    required this.isEquipped,
    required this.onSwap,
    required this.onRemoveFavorite,
  });

  final model.Component kit;
  final bool isEquipped;
  final VoidCallback onSwap;
  final VoidCallback onRemoveFavorite;

  @override
  Widget build(BuildContext context) {
    return FavoriteKitCardWrapper(
      kit: kit,
      isEquipped: isEquipped,
      onSwap: onSwap,
      onRemoveFavorite: onRemoveFavorite,
    );
  }
}

/// A small chip displaying a stat bonus.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
