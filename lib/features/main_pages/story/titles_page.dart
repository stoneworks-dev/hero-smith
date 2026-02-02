import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../widgets/titles/title_card.dart';

class TitlesPage extends ConsumerWidget {
  const TitlesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(componentsByTypeProvider('title'));
    return Scaffold(
      appBar: AppBar(title: const Text('Titles')),
      body: titlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (titles) {
          if (titles.isEmpty) {
            return const Center(child: Text('No titles found.'));
          }

          // Group by echelon (1..4) others as 0/unknown
          final Map<int, List<Component>> grouped = {};
          for (final t in titles) {
            final echelon = (t.data['echelon'] as num?)?.toInt() ?? 0;
            grouped.putIfAbsent(echelon, () => []).add(t);
          }

          const order = [1, 2, 3, 4, 0];
          final sorted = <MapEntry<int, List<Component>>>[];
          for (final i in order) {
            if (grouped.containsKey(i)) sorted.add(MapEntry(i, grouped[i]!));
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

  Widget _buildGroup(BuildContext context, int echelon, List<Component> titles) {
    titles.sort((a, b) => a.name.compareTo(b.name));
    final title = echelon > 0 ? 'Echelon $echelon' : 'Other Titles';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 45, 45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${titles.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: titles.map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TitleCard(titleComp: t),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
