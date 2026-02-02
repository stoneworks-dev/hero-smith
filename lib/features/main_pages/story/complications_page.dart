import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/widgets/complications/complication_card.dart';

class ComplicationsPage extends ConsumerWidget {
  const ComplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complicationsAsync = ref.watch(componentsByTypeProvider('complication'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complications'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      ),
      body: complicationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load complications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (complications) {
          if (complications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No complications found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort complications alphabetically by name
          final sortedComplications = [...complications];
          sortedComplications.sort((a, b) => a.name.compareTo(b.name));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '${sortedComplications.length} complications available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                
                // Complication cards - now in vertical layout
                Column(
                  children: sortedComplications.map((complication) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ComplicationCard(complication: complication),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
