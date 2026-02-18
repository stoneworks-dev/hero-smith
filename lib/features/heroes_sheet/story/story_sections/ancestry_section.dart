import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/text/heroes_sheet/story/sheet_story_ancestry_section_text.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/core/theme/story_theme.dart';

import '../../../../core/theme/form_theme.dart';
import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../widgets/shared/story_display_widgets.dart';

// Provider to fetch a single component by ID (same as in sheet_story.dart)
final _componentByIdProvider =
    FutureProvider.family<model.Component?, String>((ref, id) async {
  final allComponents = await ref.read(allComponentsProvider.future);
  return allComponents.firstWhere(
    (c) => c.id == id,
    orElse: () => model.Component(
      id: '',
      type: '',
      name: 'Not found',
      data: const {},
      source: '',
    ),
  );
});

/// Displays the ancestry section with signature ability and selected traits.
class AncestrySection extends ConsumerWidget {
  const AncestrySection({
    super.key,
    required this.ancestryId,
    required this.traitIds,
  });

  final String? ancestryId;
  final List<String> traitIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ancestryId == null || ancestryId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final ancestryAsync = ref.watch(_componentByIdProvider(ancestryId!));
    final traitsAsync = ref.watch(allComponentsProvider);

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: StoryTheme.storyAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.family_restroom, color: StoryTheme.storyAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  SheetStoryAncestrySectionText.sectionTitle,
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ancestryAsync.when(
              loading: () => const CircularProgressIndicator(color: StoryTheme.storyAccent),
              error: (e, _) => Text(
                '${SheetStoryAncestrySectionText.errorLoadingAncestryPrefix}$e',
                style: TextStyle(color: Colors.red.shade300),
              ),
              data: (ancestry) {
                if (ancestry == null) {
                  return Text(
                    SheetStoryAncestrySectionText.ancestryNotFound,
                    style: TextStyle(color: FormTheme.textSecondary),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      label: SheetStoryAncestrySectionText.ancestryLabel,
                      value: ancestry.name,
                      icon: Icons.family_restroom,
                    ),
                    if (ancestry.data['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ancestry.data['description'].toString(),
                        style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (traitIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              traitsAsync.when(
                loading: () => const CircularProgressIndicator(color: StoryTheme.storyAccent),
                error: (e, _) => Text('Error loading traits: $e', style: TextStyle(color: Colors.red.shade300)),
                data: (allTraits) => _buildTraitsContent(context, allTraits),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTraitsContent(
    BuildContext context,
    List<model.Component> allTraits,
  ) {
    final ancestryTraitComponent = allTraits.cast<dynamic>().firstWhere(
          (t) => t.data['ancestry_id'] == ancestryId,
          orElse: () => null,
        );

    if (ancestryTraitComponent == null && allTraits.isNotEmpty) {
      return Text(
        SheetStoryAncestrySectionText.noTraitDataAvailable,
        style: TextStyle(color: FormTheme.textSecondary),
      );
    }

    if (ancestryTraitComponent == null) {
      return Text(
        SheetStoryAncestrySectionText.noTraitsAvailable,
        style: TextStyle(color: FormTheme.textSecondary),
      );
    }

    final signatureRaw = ancestryTraitComponent.data['signature'];
    final List<Map<String, dynamic>> signatures;
    if (signatureRaw is List) {
      signatures = signatureRaw.cast<Map>().map((m) => m.cast<String, dynamic>()).toList();
    } else if (signatureRaw is Map) {
      signatures = [signatureRaw.cast<String, dynamic>()];
    } else {
      signatures = [];
    }
    final traitsList = ancestryTraitComponent.data['traits'] as List?;

    final selectedTraits = traitsList
            ?.where((trait) =>
                trait is Map && traitIds.contains(trait['id']?.toString()))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (signatures.isNotEmpty) ...[
          Text(
            SheetStoryAncestrySectionText.signatureAbilityTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: FormTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...signatures.map((signature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade700.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signature['name']?.toString() ??
                        SheetStoryAncestrySectionText.signatureUnknownName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade400,
                    ),
                  ),
                  if (signature['description'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      signature['description'].toString(),
                      style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
        ],
        if (selectedTraits.isNotEmpty) ...[
          Text(
            SheetStoryAncestrySectionText.optionalTraitsTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: FormTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...selectedTraits.map((trait) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectedTraitCard(trait: trait as Map<String, dynamic>),
            );
          }),
        ],
      ],
    );
  }
}
