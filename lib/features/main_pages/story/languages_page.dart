import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../widgets/languages/language_card.dart';

class LanguagesPage extends ConsumerWidget {
  const LanguagesPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langs = ref.watch(componentsByTypeProvider('language'));
    return Scaffold(
      appBar: AppBar(title: const Text('Languages')),
      body: langs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No languages found.'));
          }
          
          // Group languages by type
          final Map<String, List<Component>> groupedLanguages = {};
          for (final language in items) {
            final langType = language.data['language_type'] as String? ?? 'unknown';
            groupedLanguages.putIfAbsent(langType, () => []).add(language);
          }
          
          // Sort groups by priority
          final orderedTypes = ['human', 'ancestral', 'dead', 'unknown'];
          final sortedGroups = <MapEntry<String, List<Component>>>[];
          
          for (final type in orderedTypes) {
            if (groupedLanguages.containsKey(type)) {
              sortedGroups.add(MapEntry(type, groupedLanguages[type]!));
            }
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedGroups.map((group) {
                return _buildLanguageGroup(
                  group.key,
                  group.value,
                  context,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLanguageGroup(String type, List<Component> languages, BuildContext context) {
    // Sort languages within each group alphabetically
    languages.sort((a, b) => a.name.compareTo(b.name));
    
    String groupTitle = switch (type) {
      'human' => 'Human Languages',
      'ancestral' => 'Ancestral Languages', 
      'dead' => 'Dead Languages',
      _ => 'Other Languages',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            children: [
              Text(
                groupTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 45, 45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${languages.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: languages.map((language) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: LanguageCard(language: language),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
