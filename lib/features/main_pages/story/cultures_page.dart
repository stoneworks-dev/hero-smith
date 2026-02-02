import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/widgets/cultures/culture_card.dart';

class CulturesPage extends ConsumerWidget {
  const CulturesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all three culture types
    final environmentsAsync = ref.watch(componentsByTypeProvider('culture_environment'));
    final organisationsAsync = ref.watch(componentsByTypeProvider('culture_organisation'));
    final upbringingsAsync = ref.watch(componentsByTypeProvider('culture_upbringing'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultures'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cultures',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your culture is a combination of environment, organization, and upbringing.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Environments Section
            environmentsAsync.when(
              loading: () => _buildLoadingSection('Environments'),
              error: (error, stack) => _buildErrorSection('Environments', error),
              data: (environments) => _buildCultureGroup(
                context,
                'Environments',
                '🏞️',
                'Where your culture lives and thrives',
                environments,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Organizations Section
            organisationsAsync.when(
              loading: () => _buildLoadingSection('Organizations'),
              error: (error, stack) => _buildErrorSection('Organizations', error),
              data: (organisations) => _buildCultureGroup(
                context,
                'Organizations',
                '🏛️',
                'How your culture is structured and governed',
                organisations,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Upbringings Section
            upbringingsAsync.when(
              loading: () => _buildLoadingSection('Upbringings'),
              error: (error, stack) => _buildErrorSection('Upbringings', error),
              data: (upbringings) => _buildCultureGroup(
                context,
                'Upbringings',
                '👨‍👩‍👧‍👦',
                'How you were raised within your culture',
                upbringings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCultureGroup(
    BuildContext context,
    String title,
    String emoji,
    String description,
    List<Component> cultures,
  ) {
    if (cultures.isEmpty) {
      return _buildEmptySection(title);
    }

    // Sort alphabetically
    final sortedCultures = [...cultures];
    sortedCultures.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Row(
          children: [
            Text(
              '$emoji $title',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text(
                '${sortedCultures.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color.fromARGB(255, 52, 51, 51),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        // Culture cards - now in vertical layout
        Column(
          children: sortedCultures.map((culture) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: CultureCard(culture: culture),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorSection(String title, Object error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading $title',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No $title found',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
