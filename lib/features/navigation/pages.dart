import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';

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
              child: Text('Heroes Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No components loaded'))
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
            child: Text('Heroes Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: Text('Error: $e'),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: Text('Heroes Page')),
    );
  }
}

class StrifePage extends StatelessWidget {
  const StrifePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Strife Page'));
}

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Story Page'));
}

class GearPage extends StatelessWidget {
  const GearPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Gear Page'));
}

class DowntimeProjectsPage extends StatelessWidget {
  const DowntimeProjectsPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Downtime Projects Page'));
}
