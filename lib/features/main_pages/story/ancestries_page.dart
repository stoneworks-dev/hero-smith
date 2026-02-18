import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/widgets/ancestries/ancestry_card.dart';
import 'package:hero_smith/core/text/main_pages/story/ancestries_page_text.dart';

class AncestriesPage extends ConsumerWidget {
  const AncestriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestriesAsync = ref.watch(componentsByTypeProvider('ancestry'));
    final ancestryTraitsAsync = ref.watch(componentsByTypeProvider('ancestry_trait'));

    return Scaffold(
      appBar: AppBar(
        title: Text(AncestriesPageText.appBarTitle),
      ),
      body: ancestriesAsync.when(
        data: (ancestries) => ancestryTraitsAsync.when(
          data: (ancestryTraits) => _buildContent(context, ancestries, ancestryTraits),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorWidget(
            AncestriesPageText.failedToLoadTraits(error),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorWidget(
          AncestriesPageText.failedToLoadAncestries(error),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Component> ancestries, List<Component> ancestryTraits) {
    if (ancestries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.family_restroom,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AncestriesPageText.noAncestriesAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AncestriesPageText.ancestryDataWillAppear,
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Create a map for quick trait lookup
    final traitsMap = <String, Component>{};
    for (final trait in ancestryTraits) {
      final ancestryId = trait.data['ancestry_id'] as String?;
      if (ancestryId != null) {
        traitsMap[ancestryId] = trait;
      }
    }

    // Sort ancestries alphabetically
    ancestries.sort((a, b) => a.name.compareTo(b.name));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AncestriesPageText.countAvailable(ancestries.length),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // Use single column layout since ancestry information is extensive
          ...ancestries.map((ancestry) {
            final relatedTraits = traitsMap[ancestry.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AncestryCard(
                ancestry: ancestry,
                ancestryTraits: relatedTraits,
              ),
            );
          }),
        ],
      ),
    );
  }
}
