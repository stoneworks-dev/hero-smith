import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/text/heroes_sheet/story/sheet_story_complication_section_text.dart';
import 'package:hero_smith/core/theme/navigation_theme.dart';
import 'package:hero_smith/core/theme/story_theme.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../widgets/shared/story_display_widgets.dart';
import 'token_tracker_widget.dart';

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

/// Displays the complication section with effects, grants, and tokens.
class ComplicationSection extends ConsumerWidget {
  const ComplicationSection({
    super.key,
    required this.complicationId,
    required this.complicationChoices,
    required this.heroId,
  });

  final String? complicationId;
  final Map<String, String> complicationChoices;
  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (complicationId == null || complicationId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final complicationAsync =
        ref.watch(_componentByIdProvider(complicationId!));

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StoryTheme.storyAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: StoryTheme.storyAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  SheetStoryComplicationSectionText.sectionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            complicationAsync.when(
              loading: () => CircularProgressIndicator(color: StoryTheme.storyAccent),
              error: (e, _) => Text(
                '${SheetStoryComplicationSectionText.errorLoadingComplicationPrefix}$e',
                style: TextStyle(color: Colors.red.shade300),
              ),
              data: (comp) {
                if (comp == null) {
                  return Text(
                    SheetStoryComplicationSectionText.complicationNotFound,
                    style: TextStyle(color: Colors.grey.shade400),
                  );
                }

                return _ComplicationDetails(
                  complication: comp,
                  choices: complicationChoices,
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

class _ComplicationDetails extends ConsumerWidget {
  const _ComplicationDetails({
    required this.complication,
    required this.choices,
    required this.heroId,
  });

  final model.Component complication;
  final Map<String, String> choices;
  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = complication.data;
    final complicationId = complication.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StoryTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            complication.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (data['description'] != null) ...[
            Text(
              data['description'].toString(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
          if (data['effects'] != null) ...[
            _EffectsDisplay(effects: data['effects']),
            const SizedBox(height: 12),
          ],
          TokenTrackerWidget(heroId: heroId),
          const SizedBox(height: 12),
          if (data['grants'] != null) ...[
            _GrantsDisplay(
              grants: data['grants'],
              complicationId: complicationId,
              choices: choices,
            ),
            const SizedBox(height: 12),
          ],
          if (data['ability'] != null) ...[
            AbilityReferenceDisplay(ability: data['ability']),
            const SizedBox(height: 12),
          ],
          if (data['feature'] != null) ...[
            FeatureReferenceDisplay(feature: data['feature']),
          ],
        ],
      ),
    );
  }
}

class _EffectsDisplay extends StatelessWidget {
  const _EffectsDisplay({required this.effects});

  final dynamic effects;

  @override
  Widget build(BuildContext context) {
    final effectsData = effects as Map<String, dynamic>?;
    if (effectsData == null) return const SizedBox.shrink();

    final benefit = effectsData['benefit']?.toString();
    final drawback = effectsData['drawback']?.toString();
    final both = effectsData['both']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SheetStoryComplicationSectionText.effectsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 8),
        if (benefit != null && benefit.isNotEmpty) ...[
          EffectItemDisplay(
            label: SheetStoryComplicationSectionText.effectBenefitLabel,
            text: benefit,
            color: StoryTheme.skillsAccent,
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: 8),
        ],
        if (drawback != null && drawback.isNotEmpty) ...[
          EffectItemDisplay(
            label: SheetStoryComplicationSectionText.effectDrawbackLabel,
            text: drawback,
            color: Colors.red.shade400,
            icon: Icons.remove_circle_outline,
          ),
          const SizedBox(height: 8),
        ],
        if (both != null && both.isNotEmpty) ...[
          EffectItemDisplay(
            label: SheetStoryComplicationSectionText.effectMixedLabel,
            text: both,
            color: Colors.amber.shade400,
            icon: Icons.swap_horiz,
          ),
        ],
      ],
    );
  }
}

class _GrantsDisplay extends ConsumerWidget {
  const _GrantsDisplay({
    required this.grants,
    required this.complicationId,
    required this.choices,
  });

  final dynamic grants;
  final String complicationId;
  final Map<String, String> choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantsData = grants as Map<String, dynamic>?;
    if (grantsData == null || grantsData.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];

    // Treasures
    if (grantsData['treasures'] is List) {
      final treasures = grantsData['treasures'] as List;
      for (final treasure in treasures) {
        if (treasure is Map) {
          final type = treasure['type']?.toString() ?? 'treasure';
          final echelon = treasure['echelon'];
          final choice = treasure['choice'] == true;

          final text = choice
              ? '${type.replaceAll('_', ' ')}${echelon != null ? ' (echelon $echelon)' : ''} of your choice'
              : '${type.replaceAll('_', ' ')}${echelon != null ? ' (echelon $echelon)' : ''}';

          items.add(GrantItemDisplay(text: text, icon: Icons.diamond_outlined));
        }
      }
    }

    // Tokens
    if (grantsData['tokens'] is Map) {
      final tokens = grantsData['tokens'] as Map;
      tokens.forEach((key, value) {
        items.add(
          GrantItemDisplay(
            text:
                '$value ${key.toString().replaceAll('_', ' ')} token${value == 1 ? '' : 's'}',
            icon: Icons.token_outlined,
          ),
        );
      });
    }

    // Languages
    if (grantsData['languages'] != null) {
      final count = grantsData['languages'] as int? ?? 1;
      items.add(_LanguageGrantsDisplay(
        complicationId: complicationId,
        choices: choices,
        count: count,
        isDead: false,
      ));
    }

    // Dead languages
    if (grantsData['dead_language'] != null) {
      final count = grantsData['dead_language'] as int? ?? 1;
      items.add(_LanguageGrantsDisplay(
        complicationId: complicationId,
        choices: choices,
        count: count,
        isDead: true,
      ));
    }

    // Skill from options
    if (grantsData['skill_from_options'] != null) {
      items.add(_SkillChoiceDisplay(
        complicationId: complicationId,
        choices: choices,
        choiceType: 'skill_option',
      ));
    }

    // Skill from group
    if (grantsData['skill_from_group'] != null) {
      items.add(_SkillChoiceDisplay(
        complicationId: complicationId,
        choices: choices,
        choiceType: 'skill_group',
      ));
    }

    // Ancestry traits
    if (grantsData['ancestry_traits'] != null) {
      items.add(_AncestryTraitsDisplay(
        complicationId: complicationId,
        choices: choices,
        ancestryTraitsData: grantsData['ancestry_traits'],
      ));
    }

    // Pick one
    if (grantsData['pick_one'] != null) {
      items.add(_PickOneDisplay(
        complicationId: complicationId,
        choices: choices,
        pickOneData: grantsData['pick_one'],
      ));
    }

    // Increase total
    if (grantsData['increase_total'] is List) {
      final increases = grantsData['increase_total'] as List;
      for (final inc in increases) {
        if (inc is Map) {
          final stat = inc['stat']?.toString() ?? '';
          final value = inc['value'];
          final perEchelon = inc['per_echelon'] == true;
          final text = perEchelon
              ? '+$value ${stat.replaceAll('_', ' ')} per echelon'
              : '+$value ${stat.replaceAll('_', ' ')}';
          items.add(
              GrantItemDisplay(text: text, icon: Icons.trending_up_outlined));
        }
      }
    }

    // Abilities
    if (grantsData['abilities'] is List) {
      final abilities = grantsData['abilities'] as List;
      for (final ability in abilities) {
        items.add(GrantItemDisplay(
          text: 'Ability: $ability',
          icon: Icons.auto_awesome_outlined,
        ));
      }
    }
    if (grantsData['ability'] != null) {
      items.add(GrantItemDisplay(
        text: 'Ability: ${grantsData['ability']}',
        icon: Icons.auto_awesome_outlined,
      ));
    }

    // Skills
    if (grantsData['skills'] is List) {
      final skills = grantsData['skills'] as List;
      for (final skill in skills) {
        items.add(GrantItemDisplay(
          text: 'Skill: $skill',
          icon: Icons.psychology_outlined,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SheetStoryComplicationSectionText.grantsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
}

class _LanguageGrantsDisplay extends ConsumerWidget {
  const _LanguageGrantsDisplay({
    required this.complicationId,
    required this.choices,
    required this.count,
    required this.isDead,
  });

  final String complicationId;
  final Map<String, String> choices;
  final int count;
  final bool isDead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(componentsByTypeProvider('language'));
    final label = isDead ? 'Dead Language' : 'Language';
    final icon = isDead ? Icons.history_edu_outlined : Icons.translate_outlined;
    final choicePrefix = isDead ? 'dead_language' : 'language';

    return languagesAsync.when(
      loading: () =>
          GrantItemDisplay(text: '${label}s: Loading...', icon: icon),
      error: (e, _) =>
          GrantItemDisplay(text: '${label}s: Error loading', icon: icon),
      data: (allLanguages) {
        final selectedNames = <String>[];
        for (int i = 0; i < count; i++) {
          final choiceKey = '${complicationId}_${choicePrefix}_$i';
          final selectedId = choices[choiceKey];
          if (selectedId != null && selectedId.isNotEmpty) {
            final lang = allLanguages.firstWhere(
              (l) => l.id == selectedId,
              orElse: () => model.Component(
                  id: '', type: '', name: selectedId, data: const {}),
            );
            selectedNames.add(lang.name);
          }
        }

        if (selectedNames.isEmpty) {
          return GrantItemDisplay(
            text: 'Choose $count $label${count == 1 ? '' : 's'}',
            icon: icon,
          );
        }

        return GrantItemDisplay(
          text:
              '$label${selectedNames.length == 1 ? '' : 's'}: ${selectedNames.join(', ')}',
          icon: icon,
        );
      },
    );
  }
}

class _SkillChoiceDisplay extends ConsumerWidget {
  const _SkillChoiceDisplay({
    required this.complicationId,
    required this.choices,
    required this.choiceType,
  });

  final String complicationId;
  final Map<String, String> choices;
  final String choiceType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(componentsByTypeProvider('skill'));
    final choiceKey = '${complicationId}_$choiceType';
    final selectedId = choices[choiceKey];

    return skillsAsync.when(
      loading: () => const GrantItemDisplay(
        text: SheetStoryComplicationSectionText.skillLoading,
        icon: Icons.psychology_outlined,
      ),
      error: (e, _) => const GrantItemDisplay(
        text: SheetStoryComplicationSectionText.skillErrorLoading,
        icon: Icons.psychology_outlined,
      ),
      data: (allSkills) {
        if (selectedId == null || selectedId.isEmpty) {
          return const GrantItemDisplay(
            text: SheetStoryComplicationSectionText.chooseASkill,
            icon: Icons.psychology_outlined,
          );
        }

        final skill = allSkills.firstWhere(
          (s) => s.id == selectedId,
          orElse: () => model.Component(
              id: '', type: '', name: selectedId, data: const {}),
        );

        return GrantItemDisplay(
          text: '${SheetStoryComplicationSectionText.skillPrefix}${skill.name}',
          icon: Icons.psychology_outlined,
        );
      },
    );
  }
}

class _AncestryTraitsDisplay extends ConsumerWidget {
  const _AncestryTraitsDisplay({
    required this.complicationId,
    required this.choices,
    required this.ancestryTraitsData,
  });

  final String complicationId;
  final Map<String, String> choices;
  final dynamic ancestryTraitsData;

  String _formatAncestryName(String ancestry) {
    return ancestry.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestry = ancestryTraitsData['ancestry'] as String? ?? '';
    final points = ancestryTraitsData['ancestry_points'] as int? ?? 0;
    final ancestryTraitsAsync =
        ref.watch(componentsByTypeProvider('ancestry_trait'));

    final choiceKey = '${complicationId}_ancestry_traits';
    final selectedIdsStr = choices[choiceKey] ?? '';
    final selectedIds = selectedIdsStr.isNotEmpty
        ? selectedIdsStr.split(',').toSet()
        : <String>{};

    if (selectedIds.isEmpty) {
      return GrantItemDisplay(
        text:
            'Choose $points ${_formatAncestryName(ancestry)} ancestry trait point${points == 1 ? '' : 's'}',
        icon: Icons.person_outline,
      );
    }

    return ancestryTraitsAsync.when(
      loading: () => const GrantItemDisplay(
        text: 'Ancestry Traits: Loading...',
        icon: Icons.person_outline,
      ),
      error: (e, _) => GrantItemDisplay(
        text: 'Ancestry Traits: ${selectedIds.length} selected',
        icon: Icons.person_outline,
      ),
      data: (allAncestryTraits) {
        final targetAncestryId = 'ancestry_$ancestry';
        final traitsComp = allAncestryTraits.cast<model.Component>().firstWhere(
              (t) => t.data['ancestry_id'] == targetAncestryId,
              orElse: () =>
                  model.Component(id: '', type: '', name: '', data: const {}),
            );

        final traitsList =
            (traitsComp.data['traits'] as List?)?.cast<Map>() ?? const <Map>[];
        final selectedTraits = <Map<String, dynamic>>[];

        for (final id in selectedIds) {
          final trait = traitsList.firstWhere(
            (t) => (t['id'] ?? t['name']).toString() == id,
            orElse: () => const {},
          );
          if (trait.isNotEmpty) {
            selectedTraits.add(trait.cast<String, dynamic>());
          }
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StoryTheme.storyAccent.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: StoryTheme.storyAccent.withAlpha(77)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: StoryTheme.storyAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatAncestryName(ancestry)} Traits',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...selectedTraits.map((trait) => _buildTraitItem(context, trait)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraitItem(BuildContext context, Map<String, dynamic> trait) {
    final name = trait['name']?.toString() ?? '';
    final description = trait['description']?.toString() ?? '';
    final cost = trait['cost'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: StoryTheme.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StoryTheme.storyAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$cost pt${cost == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: StoryTheme.storyAccent,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickOneDisplay extends StatelessWidget {
  const _PickOneDisplay({
    required this.complicationId,
    required this.choices,
    required this.pickOneData,
  });

  final String complicationId;
  final Map<String, String> choices;
  final dynamic pickOneData;

  @override
  Widget build(BuildContext context) {
    final choiceKey = '${complicationId}_pick_one';
    final selectedIndexStr = choices[choiceKey];
    final selectedIndex =
        selectedIndexStr != null ? int.tryParse(selectedIndexStr) : null;

    if (pickOneData is! List || (pickOneData as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final dataList = pickOneData as List;

    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= dataList.length) {
      return const GrantItemDisplay(
        text: SheetStoryComplicationSectionText.chooseOneOption,
        icon: Icons.check_circle_outline,
      );
    }

    final selectedOption = dataList[selectedIndex] as Map<String, dynamic>;
    final description = selectedOption['description'] as String? ??
        'Option ${selectedIndex + 1}';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StoryTheme.storyAccent.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StoryTheme.storyAccent.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: StoryTheme.storyAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


