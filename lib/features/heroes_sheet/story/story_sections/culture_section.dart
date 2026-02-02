import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/text/heroes_sheet/story/sheet_story_culture_section_text.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/core/theme/story_theme.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../widgets/shared/story_display_widgets.dart';

// Provider to fetch a single component by ID
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

/// Data class for culture selection.
class CultureSelectionData {
  const CultureSelectionData({
    this.environmentId,
    this.organisationId,
    this.upbringingId,
    this.environmentSkillId,
    this.organisationSkillId,
    this.upbringingSkillId,
  });

  final String? environmentId;
  final String? organisationId;
  final String? upbringingId;
  final String? environmentSkillId;
  final String? organisationSkillId;
  final String? upbringingSkillId;

  bool get hasAnySelection =>
      (environmentId != null && environmentId!.isNotEmpty) ||
      (organisationId != null && organisationId!.isNotEmpty) ||
      (upbringingId != null && upbringingId!.isNotEmpty);
}

/// Displays the culture section with environment, organization, and upbringing.
class CultureSection extends ConsumerWidget {
  const CultureSection({
    super.key,
    required this.culture,
  });

  final CultureSelectionData culture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!culture.hasAnySelection) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
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
                  child: const Icon(Icons.public, color: StoryTheme.storyAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  SheetStoryCultureSectionText.sectionTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (culture.environmentId != null &&
                culture.environmentId!.isNotEmpty)
              _ComponentDisplay(
                label: SheetStoryCultureSectionText.environmentLabel,
                componentId: culture.environmentId!,
                icon: Icons.terrain,
              ),
            if (culture.organisationId != null &&
                culture.organisationId!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ComponentDisplay(
                label: SheetStoryCultureSectionText.organizationLabel,
                componentId: culture.organisationId!,
                icon: Icons.groups,
              ),
            ],
            if (culture.upbringingId != null &&
                culture.upbringingId!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ComponentDisplay(
                label: SheetStoryCultureSectionText.upbringingLabel,
                componentId: culture.upbringingId!,
                icon: Icons.home,
              ),
            ],
            if (culture.environmentSkillId != null ||
                culture.organisationSkillId != null ||
                culture.upbringingSkillId != null) ...[
              const SizedBox(height: 16),
              Text(
                SheetStoryCultureSectionText.cultureSkillsTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (culture.environmentSkillId != null)
                _ComponentDisplay(
                  label: SheetStoryCultureSectionText.environmentSkillLabel,
                  componentId: culture.environmentSkillId!,
                  icon: Icons.school,
                ),
              if (culture.organisationSkillId != null) ...[
                const SizedBox(height: 4),
                _ComponentDisplay(
                  label: SheetStoryCultureSectionText.organizationSkillLabel,
                  componentId: culture.organisationSkillId!,
                  icon: Icons.school,
                ),
              ],
              if (culture.upbringingSkillId != null) ...[
                const SizedBox(height: 4),
                _ComponentDisplay(
                  label: SheetStoryCultureSectionText.upbringingSkillLabel,
                  componentId: culture.upbringingSkillId!,
                  icon: Icons.school,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal widget to display a component by ID with async loading.
class _ComponentDisplay extends ConsumerWidget {
  const _ComponentDisplay({
    required this.label,
    required this.componentId,
    required this.icon,
  });

  final String label;
  final String componentId;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentAsync = ref.watch(_componentByIdProvider(componentId));

    return componentAsync.when(
      loading: () => SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent),
      ),
      error: (e, _) =>
          Text('Error: $e', style: TextStyle(color: Colors.red.shade300)),
      data: (component) {
        if (component == null) {
          return Text('$label not found', style: TextStyle(color: Colors.grey.shade400));
        }

        final description = component.data['description']?.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isEmpty)
              InfoRow(label: '', value: component.name, icon: icon)
            else
              InfoRow(label: label, value: component.name, icon: icon),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
