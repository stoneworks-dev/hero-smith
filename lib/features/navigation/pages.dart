import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/text/navigation/pages_text.dart';

class HeroesPage extends ConsumerWidget {
  const HeroesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentsAsync = ref.watch(allComponentsProvider);
    return componentsAsync.when(
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(PagesText.heroesPage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text(PagesText.noComponentsLoaded))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = items[index];
                        return ListTile(
                          title: Text(c.name.isEmpty ? c.id : c.name),
                          subtitle: Text(c.type),
                          dense: true,
                        );
                      },
                    ),
            ),
          ],
        );
      },
      error: (e, st) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(PagesText.heroesPage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: Text(PagesText.error(e)),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: Text(PagesText.heroesPage)),
    );
  }
}

class StrifePage extends StatelessWidget {
  const StrifePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text(PagesText.strifePage));
}

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text(PagesText.storyPage));
}

class GearPage extends StatelessWidget {
  const GearPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text(PagesText.gearPage));
}

class DowntimeProjectsPage extends StatelessWidget {
  const DowntimeProjectsPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text(PagesText.downtimeProjectsPage));
}
