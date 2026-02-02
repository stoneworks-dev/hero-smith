import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../widgets/skills/skill_card.dart';

class SkillsPage extends ConsumerWidget {
  const SkillsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(componentsByTypeProvider('skill'));
    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (skills) {
          if (skills.isEmpty) {
            return const Center(child: Text('No skills found.'));
          }

          // Group by 'group' field
          final Map<String, List<Component>> grouped = {};
          for (final s in skills) {
            final group = (s.data['group'] as String?) ?? 'other';
            grouped.putIfAbsent(group, () => []).add(s);
          }

          // Desired order
          const order = ['crafting', 'exploration', 'interpersonal', 'intrigue', 'lore', 'other'];
          final sorted = <MapEntry<String, List<Component>>>[];
          for (final g in order) {
            if (grouped.containsKey(g)) sorted.add(MapEntry(g, grouped[g]!));
          }
          // Add any missing, alphabetically
          final remaining = grouped.keys.where((k) => !order.contains(k)).toList()..sort();
          for (final g in remaining) {
            sorted.add(MapEntry(g, grouped[g]!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sorted.map((entry) => _buildGroup(context, entry.key, entry.value)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String group, List<Component> skills) {
    skills.sort((a, b) => a.name.compareTo(b.name));
    final title = switch (group) {
      'crafting' => 'Crafting',
      'exploration' => 'Exploration',
      'interpersonal' => 'Interpersonal',
      'intrigue' => 'Intrigue',
      'lore' => 'Lore',
      _ => 'Other',
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
                  '${skills.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: skills.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: SkillCard(skill: s),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
