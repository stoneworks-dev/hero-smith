import 'package:flutter/material.dart';
import '../../../core/text/main_pages/strife/strife_page_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/retainers/retainer_template_card.dart';
import '../../../widgets/shared/nav_card.dart';
import 'abilities_page.dart';
import 'conditions_page.dart';
import 'retainers_page.dart';
import 'strife_features_page.dart';

class StrifePage extends StatelessWidget {
  const StrifePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        NavCard(
          icon: Icons.bolt,
          title: StrifePageText.abilitiesTitle,
          subtitle: StrifePageText.abilitiesSubtitle,
          accentColor: NavigationTheme.abilitiesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AbilitiesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.extension,
          title: StrifePageText.featuresTitle,
          subtitle: StrifePageText.featuresSubtitle,
          accentColor: NavigationTheme.featuresColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StrifeFeaturesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.warning_amber_rounded,
          title: StrifePageText.conditionsTitle,
          subtitle: StrifePageText.conditionsSubtitle,
          accentColor: NavigationTheme.conditionsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConditionsPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.groups_3_outlined,
          title: StrifePageText.retainersTitle,
          subtitle: StrifePageText.retainersSubtitle,
          accentColor: retainerAccent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RetainersPage()),
          ),
        ),
      ],
    );
  }
}
