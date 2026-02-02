import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/text/heroes_sheet/story/sheet_story_career_section_text.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/core/theme/story_theme.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../widgets/perks/perk_card.dart';
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



/// Data class for career selection.
class CareerSelectionData {
  const CareerSelectionData({
    this.careerId,
    this.incitingIncidentName,
    this.chosenSkillIds = const [],
    this.chosenPerkIds = const [],
  });

  final String? careerId;
  final String? incitingIncidentName;
  final List<String> chosenSkillIds;
  final List<String> chosenPerkIds;
}

/// Displays the career section with skills, perks, and inciting incident.
class CareerSection extends ConsumerWidget {
  const CareerSection({
    super.key,
    required this.career,
    required this.heroId,
  });

  final CareerSelectionData career;
  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerId = career.careerId;

    if (careerId == null || careerId.isEmpty) {
      return const SizedBox.shrink();
    }

    final careerAsync = ref.watch(_componentByIdProvider(careerId));

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
                  child: const Icon(Icons.work, color: StoryTheme.storyAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  SheetStoryCareerSectionText.sectionTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            careerAsync.when(
              loading: () => const CircularProgressIndicator(color: StoryTheme.storyAccent),
              error: (e, _) => Text(
                '${SheetStoryCareerSectionText.errorLoadingCareerPrefix}$e',
                style: TextStyle(color: Colors.red.shade300),
              ),
              data: (careerComp) {
                if (careerComp == null) {
                  return Text(
                    SheetStoryCareerSectionText.careerNotFound,
                    style: TextStyle(color: Colors.grey.shade400),
                  );
                }

                return _CareerContent(
                  career: career,
                  careerComponent: careerComp,
                  heroId: heroId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerContent extends ConsumerWidget {
  const _CareerContent({
    required this.career,
    required this.careerComponent,
    required this.heroId,
  });

  final CareerSelectionData career;
  final model.Component careerComponent;
  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectPoints = careerComponent.data['project_points'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(
          label: SheetStoryCareerSectionText.careerLabel,
          value: careerComponent.name,
          icon: Icons.work,
        ),
        if (careerComponent.data['description'] != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              careerComponent.data['description'].toString(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ),
        ],
        if (projectPoints > 0) ...[
          const SizedBox(height: 16),
          _ProjectPointsDisplay(
            projectPoints: projectPoints,
            heroId: heroId,
          ),
        ],
        if (career.incitingIncidentName != null &&
            career.incitingIncidentName!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            SheetStoryCareerSectionText.incitingIncidentTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          IncitingIncidentDisplay(
            careerData: careerComponent.data,
            incidentName: career.incitingIncidentName!,
          ),
        ],
        if (career.chosenSkillIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            SheetStoryCareerSectionText.careerSkillsTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...career.chosenSkillIds.map(
            (skillId) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ComponentDisplay(
                label: '',
                componentId: skillId,
                icon: Icons.school,
              ),
            ),
          ),
        ],
        if (career.chosenPerkIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            SheetStoryCareerSectionText.careerPerksTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...career.chosenPerkIds.map(
            (perkId) => _HeroPerkCard(perkId: perkId, heroId: heroId),
          ),
        ],
      ],
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

/// Internal widget to display a perk card by ID.
class _HeroPerkCard extends ConsumerWidget {
  const _HeroPerkCard({
    required this.perkId,
    required this.heroId,
  });

  final String perkId;
  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentAsync = ref.watch(_componentByIdProvider(perkId));
    // Get reserved skills/languages from DB
    final reservedSkillIds = ref.watch(
      heroEntryIdsByTypeProvider((heroId: heroId, entryType: 'skill')),
    );
    final reservedLanguageIds = ref.watch(
      heroEntryIdsByTypeProvider((heroId: heroId, entryType: 'language')),
    );

    return componentAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent)),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${SheetStoryCareerSectionText.errorLoadingPerkPrefix}$e',
          style: TextStyle(color: Colors.red.shade300),
        ),
      ),
      data: (component) {
        if (component == null || component.id.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                '${SheetStoryCareerSectionText.perkNotFoundPrefix}$perkId',
                style: TextStyle(color: Colors.grey.shade400)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PerkCard(
            perk: component,
            heroId: heroId,
            reservedSkillIds: reservedSkillIds,
            reservedLanguageIds: reservedLanguageIds,
          ),
        );
      },
    );
  }
}

/// Widget to display project points from career with used toggle.
class _ProjectPointsDisplay extends ConsumerStatefulWidget {
  const _ProjectPointsDisplay({
    required this.projectPoints,
    required this.heroId,
  });

  final int projectPoints;
  final String heroId;

  @override
  ConsumerState<_ProjectPointsDisplay> createState() =>
      _ProjectPointsDisplayState();
}

class _ProjectPointsDisplayState extends ConsumerState<_ProjectPointsDisplay> {
  bool _isUsed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsedState();
  }

  Future<void> _loadUsedState() async {
    final db = ref.read(appDatabaseProvider);
    final values = await db.getHeroValues(widget.heroId);
    final value =
        values.where((v) => v.key == 'career.project_points_used').firstOrNull;
    if (mounted) {
      setState(() {
        _isUsed = value?.value == 1;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUsed() async {
    final newValue = !_isUsed;
    setState(() => _isUsed = newValue);

    final db = ref.read(appDatabaseProvider);
    await db.upsertHeroValue(
      heroId: widget.heroId,
      key: 'career.project_points_used',
      value: newValue ? 1 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isUsed
            ? StoryTheme.cardBackground
            : StoryTheme.storyAccent.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isUsed
              ? Colors.grey.shade700
              : StoryTheme.storyAccent.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.build_circle,
            size: 24,
            color: _isUsed
                ? Colors.grey.shade600
                : StoryTheme.storyAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SheetStoryCareerSectionText.projectPointsTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isUsed
                        ? Colors.grey.shade500
                        : Colors.white,
                    decoration: _isUsed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${widget.projectPoints}${SheetStoryCareerSectionText.projectPointsDescriptionSuffix}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isUsed
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent),
            )
          else
            Checkbox(
              value: _isUsed,
              onChanged: (_) => _toggleUsed(),
              activeColor: StoryTheme.storyAccent,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade600),
            ),
          Text(
            _isUsed
                ? SheetStoryCareerSectionText.usedLabel
                : SheetStoryCareerSectionText.availableLabel,
            style: TextStyle(
              fontSize: 12,
              color: _isUsed
                  ? Colors.grey.shade500
                  : StoryTheme.storyAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


