import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../core/theme/form_theme.dart';
import '../../../widgets/languages/language_card.dart';
import '../../../core/text/main_pages/story/languages_page_text.dart';

class LanguagesPage extends ConsumerWidget {
  const LanguagesPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langs = ref.watch(componentsByTypeProvider('language'));
    return Scaffold(
      appBar: AppBar(title: Text(LanguagesPageText.appBarTitle)),
      body: langs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(LanguagesPageText.errorMessage(e))),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(LanguagesPageText.noLanguagesFound));
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
          // Add any remaining types not in orderedTypes (e.g. custom language types)
          final remaining = groupedLanguages.keys
              .where((k) => !orderedTypes.contains(k))
              .toList()
            ..sort();
          for (final g in remaining) {
            sortedGroups.add(MapEntry(g, groupedLanguages[g]!));
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
                  ref,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLanguageGroup(String type, List<Component> languages, BuildContext context, WidgetRef ref) {
    // Sort languages within each group alphabetically
    languages.sort((a, b) => a.name.compareTo(b.name));
    
    String groupTitle = switch (type) {
      'human' => LanguagesPageText.humanLanguages,
      'ancestral' => LanguagesPageText.ancestralLanguages, 
      'dead' => LanguagesPageText.deadLanguages,
      'unknown' => LanguagesPageText.otherLanguages,
      _ => LanguagesPageText.languageGroupTitle(type),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FormTheme.textBright,
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
              child: LanguageCard(
                language: language,
                onDelete: language.source == 'user'
                    ? () => _confirmDelete(context, ref, language.name, language.id, 'Language')
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  void _confirmDelete(BuildContext context, WidgetRef ref, String name, String id, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguagesPageText.deleteCustomTitle(type)),
        content: Text(LanguagesPageText.removeConfirmation(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LanguagesPageText.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(appDatabaseProvider).deleteComponent(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(LanguagesPageText.delete),
          ),
        ],
      ),
    );
  }
}
