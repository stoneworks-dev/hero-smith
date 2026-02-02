import 'package:flutter/material.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/nav_card.dart';
import 'items_page.dart';
import 'kits_page.dart';
import 'treasure_page.dart';

class GearPage extends StatelessWidget {
  const GearPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NavCard(
          icon: Icons.backpack_outlined,
          title: 'Kits',
          subtitle: 'Preset equipment bundles by role',
          accentColor: NavigationTheme.kitsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const KitsPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.handyman_outlined,
          title: 'Items',
          subtitle: 'All items (coming soon)',
          accentColor: NavigationTheme.itemsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GearItemsPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.diamond_outlined,
          title: 'Treasure',
          subtitle: 'Loot, valuables, and special finds',
          accentColor: NavigationTheme.treasureColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TreasurePage()),
          ),
        ),
      ],
    );
  }
}
