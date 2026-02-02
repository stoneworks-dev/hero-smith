import 'package:flutter/material.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/nav_card.dart';
import 'abilities_page.dart';
import 'strife_features_page.dart';
import 'conditions_page.dart';

class StrifePage extends StatelessWidget {
  const StrifePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        NavCard(
          icon: Icons.bolt,
          title: 'Abilities',
          subtitle: 'Browse and search all abilities',
          accentColor: NavigationTheme.abilitiesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AbilitiesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.extension,
          title: 'Features',
          subtitle: 'Browse and search all features',
          accentColor: NavigationTheme.featuresColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StrifeFeaturesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.warning_amber_rounded,
          title: 'Conditions',
          subtitle: 'Status effects and their rules',
          accentColor: NavigationTheme.conditionsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConditionsPage()),
          ),
        ),
      ],
    );
  }
}
