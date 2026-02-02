import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_name_section_text.dart';

class StoryNameSection extends ConsumerStatefulWidget {
  const StoryNameSection({
    super.key,
    required this.nameController,
    required this.selectedAncestryId,
    required this.onDirty,
  });

  final TextEditingController nameController;
  final String? selectedAncestryId;
  final VoidCallback onDirty;

  @override
  ConsumerState<StoryNameSection> createState() => _StoryNameSectionState();
}

class _StoryNameSectionState extends ConsumerState<StoryNameSection> {
  late final FocusNode _focusNode;

  static const _accent = CreatorTheme.nameAccent;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _focusNode.unfocus(),
      child: Container(
        margin: CreatorTheme.sectionMargin,
        decoration: CreatorTheme.sectionDecoration(_accent),
        child: Column(
          children: [
            CreatorTheme.sectionHeader(
              title: StoryNameSectionText.heroNameLabel,
              subtitle: 'Give your hero an identity',
              icon: Icons.person_outline,
              accent: _accent,
            ),
            Padding(
              padding: CreatorTheme.sectionPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: widget.nameController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: CreatorTheme.inputDecoration(
                      label: StoryNameSectionText.heroNameLabel,
                      hint: StoryNameSectionText.heroNameHint,
                      prefixIcon: Icons.badge_outlined,
                      accent: _accent,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.casino_outlined),
                        color: _accent,
                        tooltip: StoryNameSectionText.randomNameTooltip,
                        onPressed: _pickRandomName,
                      ),
                    ),
                    onChanged: (_) => widget.onDirty(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    StoryNameSectionText.ancestrySuggestionPrompt,
                    style: CreatorTheme.infoTextStyle,
                  ),
                  if (widget.selectedAncestryId != null) ...[
                    const SizedBox(height: 16),
                    _buildNameSuggestions(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickRandomName() {
    final ancestriesAsync = ref.read(componentsByTypeProvider('ancestry'));
    final ancestries = ancestriesAsync.valueOrNull;
    if (ancestries == null || ancestries.isEmpty) return;

    // Collect all names from all ancestries
    final allNames = <String>[];
    for (final ancestry in ancestries) {
      final data = ancestry.data;
      final exampleNames =
          (data['exampleNames'] as Map?)?.cast<String, dynamic>();
      if (exampleNames == null) continue;

      for (final key in [
        'examples',
        'feminine',
        'masculine',
        'genderNeutral',
      ]) {
        final list = (exampleNames[key] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list != null) allNames.addAll(list);
      }
    }

    if (allNames.isEmpty) return;

    final random = Random();
    final randomName = allNames[random.nextInt(allNames.length)];
    widget.nameController.text = randomName;
    widget.nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: randomName.length),
    );
    widget.onDirty();
  }

  Widget _buildNameSuggestions(BuildContext context) {
    final ancestriesAsync = ref.watch(componentsByTypeProvider('ancestry'));
    return ancestriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ancestries) {
        final selected = ancestries.firstWhere(
          (a) => a.id == widget.selectedAncestryId,
          orElse: () => const model.Component(
            id: '',
            type: 'ancestry',
            name: StoryNameSectionText.unknownAncestryName,
          ),
        );
        if (selected.id.isEmpty) {
          return const SizedBox.shrink();
        }
        return _ExampleNameGroups(
          ancestry: selected,
          controller: widget.nameController,
          onDirty: widget.onDirty,
        );
      },
    );
  }
}

class _ExampleNameGroups extends StatelessWidget {
  const _ExampleNameGroups({
    required this.ancestry,
    required this.controller,
    required this.onDirty,
  });

  final model.Component ancestry;
  final TextEditingController controller;
  final VoidCallback onDirty;

  static const _accent = CreatorTheme.nameAccent;

  @override
  Widget build(BuildContext context) {
    final data = ancestry.data;
    final exampleNames = (data['exampleNames'] as Map?)?.cast<String, dynamic>();
    if (exampleNames == null || exampleNames.isEmpty) {
      return const SizedBox.shrink();
    }

    // Special handling for Revenant notes
    if (ancestry.name.toLowerCase() == 'revenant') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _accent.withValues(alpha: 0.1),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: _accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                StoryNameSectionText.revenantNote,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final exampleLists = <String, List<String>>{};
    const groupLabels = <String, String>{
      'examples': StoryNameSectionText.groupLabelExamples,
      'feminine': StoryNameSectionText.groupLabelFeminine,
      'masculine': StoryNameSectionText.groupLabelMasculine,
      'genderNeutral': StoryNameSectionText.groupLabelGenderNeutral,
      'epithets': StoryNameSectionText.groupLabelEpithets,
      'surnames': StoryNameSectionText.groupLabelSurnames,
    };

    for (final key in groupLabels.keys) {
      final list = (exampleNames[key] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .map((e) => e.trim())
              .toList() ??
          const <String>[];
      if (list.isNotEmpty) {
        exampleLists[key] = list.cast<String>();
      }
    }

    if (exampleLists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: CreatorTheme.subSectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryNameSectionText.exampleNamesTitlePrefix}${ancestry.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _accent,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...exampleLists.entries.map((entry) {
            final groupLabel = groupLabels[entry.key] ?? entry.key;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in entry.value.take(8))
                      CreatorTheme.actionChip(
                        label: name,
                        onPressed: () => _applySuggestion(entry.key, name),
                        accent: _accent,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _applySuggestion(String groupKey, String suggestion) {
    final current = controller.text.trim();
    final isSurname = groupKey == 'surnames';
    final isTimeRaiderEpithet =
        ancestry.name.toLowerCase() == 'time raider' && groupKey == 'epithets';

    if ((isSurname || isTimeRaiderEpithet) && current.isNotEmpty) {
      controller.text = '$current $suggestion';
    } else {
      controller.text = suggestion;
    }
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    onDirty();
  }
}
