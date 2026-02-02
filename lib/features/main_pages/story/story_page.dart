import 'package:flutter/material.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../widgets/shared/nav_card.dart';
import 'ancestries_page.dart';
import 'cultures_page.dart';
import 'careers_page.dart';
import 'complications_page.dart';
import 'languages_page.dart';
import 'skills_page.dart';
import 'titles_page.dart';
import 'perks_page.dart';
import 'deities_page.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        NavCard(
          icon: Icons.groups,
          title: 'Ancestries',
          subtitle: 'Background origins and lineages',
          accentColor: NavigationTheme.ancestriesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AncestriesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.public,
          title: 'Cultures',
          subtitle: 'Peoples and societies of the world',
          accentColor: NavigationTheme.culturesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CulturesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.work_outline,
          title: 'Careers',
          subtitle: 'Occupations and life paths',
          accentColor: NavigationTheme.careersColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CareersPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.report_problem_outlined,
          title: 'Complications',
          subtitle: 'Entanglements and hardships',
          accentColor: NavigationTheme.complicationsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ComplicationsPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.translate,
          title: 'Languages',
          subtitle: 'Tongues spoken across the lands',
          accentColor: NavigationTheme.languagesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LanguagesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.school_outlined,
          title: 'Skills',
          subtitle: 'Capabilities and training',
          accentColor: NavigationTheme.skillsColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SkillsPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.military_tech,
          title: 'Titles',
          subtitle: 'Ranks, honors, and renown',
          accentColor: NavigationTheme.titlesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TitlesPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.auto_awesome,
          title: 'Perks',
          subtitle: 'Special boons and edges',
          accentColor: NavigationTheme.perksColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PerksPage()),
          ),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.wb_sunny_outlined,
          title: 'Deities',
          subtitle: 'Gods, saints, and higher powers',
          accentColor: NavigationTheme.deitiesColor,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeitiesPage()),
          ),
        ),
      ],
    );
  }
}
