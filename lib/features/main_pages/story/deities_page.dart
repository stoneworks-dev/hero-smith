import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../widgets/deities/deity_card.dart';

class DeitiesPage extends ConsumerWidget {
  const DeitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deitiesAsync = ref.watch(componentsByTypeProvider('deity'));
    return Scaffold(
      appBar: AppBar(title: const Text('Deities')),
      body: deitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (deities) {
          if (deities.isEmpty) {
            return const Center(child: Text('No deities found.'));
          }

          // Group by category (e.g., god, saint)
          final Map<String, List<Component>> grouped = {};
          for (final d in deities) {
            final cat = (d.data['category'] as String?) ?? 'other';
            grouped.putIfAbsent(cat, () => []).add(d);
          }

          // Order: gods first, then saints, then others alphabetically
          const order = ['god', 'saint', 'other'];
          final sorted = <MapEntry<String, List<Component>>>[];
          for (final k in order) {
            if (grouped.containsKey(k)) sorted.add(MapEntry(k, grouped[k]!));
          }
          final remaining = grouped.keys.where((k) => !order.contains(k)).toList()..sort();
          for (final k in remaining) {
            sorted.add(MapEntry(k, grouped[k]!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sorted.map((e) => _buildGroup(context, e.key, e.value)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String category, List<Component> items) {
    items.sort((a, b) => a.name.compareTo(b.name));
    final title = switch (category) {
      'god' => 'Gods',
      'saint' => 'Saints',
      _ => 'Other',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 45, 45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: items.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: DeityCard(deity: d),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
