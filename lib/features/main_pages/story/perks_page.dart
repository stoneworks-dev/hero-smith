import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../widgets/perks/perk_card.dart';

class PerksPage extends ConsumerWidget {
  const PerksPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perksAsync = ref.watch(componentsByTypeProvider('perk'));
    return Scaffold(
      appBar: AppBar(title: const Text('Perks')),
      body: perksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (perks) {
          if (perks.isEmpty) {
            return const Center(child: Text('No perks found.'));
          }

          // Group by 'group' field
          final Map<String, List<Component>> grouped = {};
          for (final p in perks) {
            final group = (p.data['group'] as String?) ?? 'exploration';
            grouped.putIfAbsent(group, () => []).add(p);
          }

          // Desired order based on the groups we found
          const order = [
            'crafting',
            'exploration',
            'interpersonal',
            'intrigue',
            'lore',
            'supernatural'
          ];
          final sorted = <MapEntry<String, List<Component>>>[];
          for (final g in order) {
            if (grouped.containsKey(g)) sorted.add(MapEntry(g, grouped[g]!));
          }
          // Add any missing, alphabetically
          final remaining =
              grouped.keys.where((k) => !order.contains(k)).toList()..sort();
          for (final g in remaining) {
            sorted.add(MapEntry(g, grouped[g]!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sorted
                  .map((entry) => _buildGroup(context, entry.key, entry.value))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(
      BuildContext context, String group, List<Component> perks) {
    perks.sort((a, b) => a.name.compareTo(b.name));
    final title = switch (group) {
      'exploration' => 'Exploration',
      'interpersonal' => 'Interpersonal',
      'intrigue' => 'Intrigue',
      'lore' => 'Lore',
      'supernatural' => 'Supernatural',
      _ => _capitalize(group),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 45, 45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${perks.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: perks.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: PerkCard(perk: p),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
