import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_career_section_text.dart';
import '../../../../core/utils/selection_guard.dart';
import '../../../../widgets/perks/perks_selection_widget.dart';

class StoryCareerSection extends ConsumerWidget {
  const StoryCareerSection({
    super.key,
    required this.heroId,
    required this.careerId,
    required this.chosenSkillIds,
    required this.chosenPerkIds,
    required this.incidentName,
    required this.careerLanguageIds,
    required this.primaryLanguageId,
    required this.selectedLanguageIds,
    required this.selectedSkillIds,
    required this.reservedLanguageIds,
    required this.reservedSkillIds,
    required this.reservedPerkIds,
    required this.onCareerChanged,
    required this.onCareerLanguageSlotsChanged,
    required this.onCareerLanguageChanged,
    required this.onSkillSelectionChanged,
    required this.onPerkSelectionChanged,
    required this.onIncidentChanged,
    required this.onDirty,
  });

  final String heroId;
  final String? careerId;
  final Set<String> chosenSkillIds;
  final Set<String> chosenPerkIds;
  final String? incidentName;
  final List<String?> careerLanguageIds;
  final String? primaryLanguageId;
  final Set<String> selectedLanguageIds;
  final Set<String> selectedSkillIds;
  final Set<String> reservedLanguageIds;
  final Set<String> reservedSkillIds;
  final Set<String> reservedPerkIds;

  final ValueChanged<String?> onCareerChanged;
  final ValueChanged<int> onCareerLanguageSlotsChanged;
  final void Function(int index, String? value) onCareerLanguageChanged;
  final void Function(Set<String> skillIds) onSkillSelectionChanged;
  final void Function(Set<String> perkIds) onPerkSelectionChanged;
  final ValueChanged<String?> onIncidentChanged;
  final VoidCallback onDirty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careersAsync = ref.watch(componentsByTypeProvider('career'));
    final skillsAsync = ref.watch(componentsByTypeProvider('skill'));
    final langsAsync = ref.watch(componentsByTypeProvider('language'));

    const accent = CreatorTheme.careerAccent;

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(accent),
      child: Column(
        children: [
          CreatorTheme.sectionHeader(
            title: StoryCareerSectionText.sectionTitle,
            subtitle: StoryCareerSectionText.sectionSubtitle,
            icon: Icons.work,
            accent: accent,
          ),
          Padding(
            padding: CreatorTheme.sectionPadding,
            child: careersAsync.when(
              loading: () => CreatorTheme.loadingIndicator(accent),
              error: (e, _) => CreatorTheme.errorMessage(
                '${StoryCareerSectionText.failedToLoadCareersPrefix}$e',
                accent: accent,
              ),
              data: (careers) => _CareerContent(
                heroId: heroId,
                careers: careers,
                careerId: careerId,
                chosenSkillIds: chosenSkillIds,
                chosenPerkIds: chosenPerkIds,
                incidentName: incidentName,
                careerLanguageIds: careerLanguageIds,
                primaryLanguageId: primaryLanguageId,
                selectedLanguageIds: selectedLanguageIds,
                selectedSkillIds: selectedSkillIds,
                reservedLanguageIds: reservedLanguageIds,
                reservedSkillIds: reservedSkillIds,
                reservedPerkIds: reservedPerkIds,
                skillsAsync: skillsAsync,
                langsAsync: langsAsync,
                onCareerChanged: onCareerChanged,
                onCareerLanguageSlotsChanged: onCareerLanguageSlotsChanged,
                onCareerLanguageChanged: onCareerLanguageChanged,
                onSkillSelectionChanged: onSkillSelectionChanged,
                onPerkSelectionChanged: onPerkSelectionChanged,
                onIncidentChanged: onIncidentChanged,
                onDirty: onDirty,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerContent extends StatefulWidget {
  const _CareerContent({
    required this.heroId,
    required this.careers,
    required this.careerId,
    required this.chosenSkillIds,
    required this.chosenPerkIds,
    required this.incidentName,
    required this.careerLanguageIds,
    required this.primaryLanguageId,
    required this.selectedLanguageIds,
    required this.selectedSkillIds,
    required this.reservedLanguageIds,
    required this.reservedSkillIds,
    required this.reservedPerkIds,
    required this.skillsAsync,
    required this.langsAsync,
    required this.onCareerChanged,
    required this.onCareerLanguageSlotsChanged,
    required this.onCareerLanguageChanged,
    required this.onSkillSelectionChanged,
    required this.onPerkSelectionChanged,
    required this.onIncidentChanged,
    required this.onDirty,
  });

  final String heroId;
  final List<model.Component> careers;
  final String? careerId;
  final Set<String> chosenSkillIds;
  final Set<String> chosenPerkIds;
  final String? incidentName;
  final List<String?> careerLanguageIds;
  final String? primaryLanguageId;
  final Set<String> selectedLanguageIds;
  final Set<String> selectedSkillIds;
  final Set<String> reservedLanguageIds;
  final Set<String> reservedSkillIds;
  final Set<String> reservedPerkIds;

  final AsyncValue<List<model.Component>> skillsAsync;
  final AsyncValue<List<model.Component>> langsAsync;

  final ValueChanged<String?> onCareerChanged;
  final ValueChanged<int> onCareerLanguageSlotsChanged;
  final void Function(int index, String? value) onCareerLanguageChanged;
  final void Function(Set<String> skillIds) onSkillSelectionChanged;
  final void Function(Set<String> perkIds) onPerkSelectionChanged;
  final ValueChanged<String?> onIncidentChanged;
  final VoidCallback onDirty;

  @override
  State<_CareerContent> createState() => _CareerContentState();
}

class _CareerContentState extends State<_CareerContent> {
  late List<model.Component> _careers;
  int? _lastEmittedLanguageSlots;
  /// Internal slot assignments to preserve position when user picks skill for slot 2 before slot 1
  List<String?> _skillSlots = [];

  @override
  void initState() {
    super.initState();
    _careers = List.of(widget.careers)
      ..sort((a, b) => a.name.compareTo(b.name));
    _syncSkillSlots();
  }

  @override
  void didUpdateWidget(covariant _CareerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.careers, widget.careers)) {
      _careers = List.of(widget.careers)
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    // If external chosenSkillIds changed (e.g., career changed), resync slots
    if (!setEquals(oldWidget.chosenSkillIds, widget.chosenSkillIds)) {
      _syncSkillSlots();
    }
  }

  /// Sync internal slot list from widget's chosenSkillIds set
  void _syncSkillSlots() {
    // Only sync if our internal slots don't match the external set
    final currentSet = _skillSlots.whereType<String>().toSet();
    if (!setEquals(currentSet, widget.chosenSkillIds)) {
      // External state changed, rebuild slots from the set
      // Use List<String?>.from to ensure the list can hold nulls
      _skillSlots = List<String?>.from(widget.chosenSkillIds);
    }
  }

  List<String> _extractSkillGroups(Map<String, dynamic> data) {
    final results = <String>[];

    void addAll(dynamic value) {
      final parsed = _parseStringList(value);
      if (parsed.isEmpty) return;
      results.addAll(parsed);
    }

    addAll(data['skill_groups']);
    for (final entry in data.entries) {
      final key = entry.key.toString().toLowerCase();
      if (key.startsWith('skill_groups') && key != 'skill_groups') {
        addAll(entry.value);
      }
    }

    return results;
  }

  List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      final tokens = value.split(RegExp(r',|/|\bor\b', caseSensitive: false));
      return tokens.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    const accent = CreatorTheme.careerAccent;
    final selectedCareer = _careers.firstWhere(
      (c) => c.id == widget.careerId,
      orElse: () => _careers.isNotEmpty
          ? _careers.first
          : const model.Component(id: '', type: 'career', name: ''),
    );

    final data = selectedCareer.data;
    final skillsNumber = (data['skills_number'] as int?) ?? 0;
    final skillGroups = _extractSkillGroups(data);
    final normalizedSkillGroups = skillGroups
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final grantedSkills =
        ((data['granted_skills'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final skillGrantDescription =
        (data['skill_grant_description'] as String?) ?? '';
    final languagesGrant = (data['languages'] as int?) ?? 0;
    if (_lastEmittedLanguageSlots != languagesGrant) {
      _lastEmittedLanguageSlots = languagesGrant;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onCareerLanguageSlotsChanged(languagesGrant);
      });
    }
    final renown = (data['renown'] as int?) ?? 0;
    final wealth = (data['wealth'] as int?) ?? 0;
    final projectPoints = (data['project_points'] as int?) ?? 0;
    final perkType = (data['perk_type'] as String?) ?? '';
    final perksNumber = (data['perks_number'] as int?) ?? 0;
    final incidents =
        ((data['inciting_incidents'] as List?) ?? const <dynamic>[])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final neededFromGroups = (skillsNumber - grantedSkills.length).clamp(0, 99);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final options = <_SearchOption<String?>>[
              const _SearchOption<String?>(
                label: StoryCareerSectionText.chooseCareerOption,
                value: null,
              ),
              ..._careers.map(
                (c) => _SearchOption<String?>(
                  label: c.name,
                  value: c.id,
                ),
              ),
            ];
            final result = await _showSearchablePicker<String?>(
              context: context,
              title: StoryCareerSectionText.selectCareerTitle,
              options: options,
              selected: widget.careerId,
            );
            if (result == null) return;
            widget.onCareerChanged(result.value);
            widget.onDirty();
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: StoryCareerSectionText.careerLabel,
              prefixIcon: Icon(Icons.work_outline),
              suffixIcon: Icon(Icons.search),
            ),
            child: Text(
              widget.careerId != null
                  ? selectedCareer.name
                  : StoryCareerSectionText.chooseCareerPlaceholder,
              style: TextStyle(
                fontSize: 16,
                color: widget.careerId != null
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ),
        if (widget.careerId != null && selectedCareer.id.isNotEmpty) ...[
          const SizedBox(height: 8),
          if ((data['description'] as String?)?.isNotEmpty == true) ...[
            Text(
              data['description'] as String,
              style: TextStyle(color: Colors.grey.shade300, height: 1.3),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (renown > 0)
                _buildStatChip(
                  '${StoryCareerSectionText.renownChipPrefix}${renown.toString()}${StoryCareerSectionText.renownChipSuffix}',
                  Icons.stars,
                  accent,
                ),
              if (wealth > 0)
                _buildStatChip(
                  '${StoryCareerSectionText.wealthChipPrefix}${wealth.toString()}${StoryCareerSectionText.wealthChipSuffix}',
                  Icons.attach_money,
                  accent,
                ),
              if (projectPoints > 0)
                _buildStatChip(
                  '${StoryCareerSectionText.projectPointsChipPrefix}${projectPoints.toString()}${StoryCareerSectionText.projectPointsChipSuffix}',
                  Icons.engineering,
                  accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (languagesGrant > 0)
            widget.langsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                  '${StoryCareerSectionText.failedToLoadLanguagesPrefix}$e'),
              data: (languages) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < languagesGrant; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CareerLanguageDropdown(
                        languages: languages,
                        value: i < widget.careerLanguageIds.length
                            ? widget.careerLanguageIds[i]
                            : null,
                        exclude: {
                          ...widget.reservedLanguageIds,
                          if (widget.primaryLanguageId != null)
                            widget.primaryLanguageId,
                          for (var j = 0;
                              j < widget.careerLanguageIds.length;
                              j++)
                            if (j != i) widget.careerLanguageIds[j],
                        },
                        label:
                            '${StoryCareerSectionText.bonusLanguageLabelPrefix}${i + 1}',
                        onChanged: (val) {
                          widget.onCareerLanguageChanged(i, val);
                          widget.onDirty();
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (skillGrantDescription.isNotEmpty) ...[
            Text(
              skillGrantDescription,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (grantedSkills.isNotEmpty)
            Text(
                '${StoryCareerSectionText.grantedSkillsPrefix}${grantedSkills.join(', ')}'),
          const SizedBox(height: 8),
          widget.skillsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
                '${StoryCareerSectionText.failedToLoadSkillsPrefix}$e'),
            data: (skills) {
              // Resolve granted skill names to IDs for exclusion
              final grantedSkillIds = <String>{};
              for (final grantedName in grantedSkills) {
                final normalizedGranted = grantedName.trim().toLowerCase();
                final matchingSkill = skills.firstWhere(
                  (s) => s.name.trim().toLowerCase() == normalizedGranted,
                  orElse: () => const model.Component(id: '', type: '', name: ''),
                );
                if (matchingSkill.id.isNotEmpty) {
                  grantedSkillIds.add(matchingSkill.id);
                }
              }

              final eligible = skills.where((skill) {
                if (normalizedSkillGroups.isEmpty) return true;
                final group =
                    skill.data['group']?.toString().trim().toLowerCase();
                final nameKey = skill.name.trim().toLowerCase();
                return normalizedSkillGroups.contains(group) ||
                    normalizedSkillGroups.contains(nameKey);
              }).toList();
              eligible.sort((a, b) => a.name.compareTo(b.name));

              final picksNeeded = neededFromGroups;
              if (picksNeeded <= 0) {
                return const SizedBox.shrink();
              }

              final skillMap = {
                for (final skill in eligible) skill.id: skill,
              };
              final grantedSkillConflicts = grantedSkillIds.intersection({
                ...widget.reservedSkillIds,
                ...widget.selectedSkillIds,
              });
              final grantedConflictNames = grantedSkillConflicts
                  .map((id) => skillMap[id]?.name ?? id)
                  .where((name) => name.isNotEmpty)
                  .toList();
              
              // Ensure _skillSlots has correct size and only valid skills
              while (_skillSlots.length < picksNeeded) {
                _skillSlots.add(null);
              }
              if (_skillSlots.length > picksNeeded) {
                _skillSlots = _skillSlots.sublist(0, picksNeeded);
              }
              // Validate that all slots contain eligible skills
              for (var i = 0; i < _skillSlots.length; i++) {
                final slot = _skillSlots[i];
                if (slot != null && !skillMap.containsKey(slot)) {
                  _skillSlots[i] = null;
                }
              }

              final grouped = <String, List<model.Component>>{};
              final ungrouped = <model.Component>[];
              for (final skill in eligible) {
                final group = skill.data['group']?.toString();
                if (group != null && group.isNotEmpty) {
                  grouped.putIfAbsent(group, () => []).add(skill);
                } else {
                  ungrouped.add(skill);
                }
              }
              final sortedGroups = grouped.keys.toList()..sort();
              for (final list in grouped.values) {
                list.sort((a, b) => a.name.compareTo(b.name));
              }
              ungrouped.sort((a, b) => a.name.compareTo(b.name));

              List<String?> currentSlots() {
                // Use the state-tracked _skillSlots to preserve positions
                return List<String?>.from(_skillSlots);
              }

              void applySelection(int index, String? value) {
                // Update the slot at the specific index
                _skillSlots[index] = value;
                // Remove duplicates if the same skill was selected elsewhere
                if (value != null) {
                  for (var i = 0; i < _skillSlots.length; i++) {
                    if (i != index && _skillSlots[i] == value) {
                      _skillSlots[i] = null;
                    }
                  }
                }
                // Build a new selection set preserving slot positions
                final next = LinkedHashSet<String>();
                for (var i = 0; i < _skillSlots.length; i++) {
                  final pick = _skillSlots[i];
                  if (pick != null) {
                    next.add(pick);
                  }
                }
                widget.onSkillSelectionChanged(next);
                widget.onDirty();
                // Trigger rebuild to reflect the new slot state
                setState(() {});
              }

              List<_SearchOption<String?>> buildSearchOptionsForIndex(
                  int currentIndex, List<String?> slots) {
                final options = <_SearchOption<String?>>[
                  const _SearchOption<String?>(
                    label: StoryCareerSectionText.chooseSkillOption,
                    value: null,
                  ),
                ];

                final excludedIds = <String>{
                  ...widget.reservedSkillIds,
                  ...grantedSkillIds,
                };
                for (var i = 0; i < slots.length; i++) {
                  if (i == currentIndex) continue;
                  final pick = slots[i];
                  if (pick != null) {
                    excludedIds.add(pick);
                  }
                }
                final currentValue = slots[currentIndex];

                for (final groupKey in sortedGroups) {
                  for (final skill in grouped[groupKey]!) {
                    if (ComponentSelectionGuard.isBlocked(
                      skill.id,
                      excludedIds,
                      currentId: currentValue,
                    )) {
                      continue;
                    }
                    options.add(
                      _SearchOption<String?>(
                        label: skill.name,
                        value: skill.id,
                        subtitle: groupKey,
                      ),
                    );
                  }
                }

                for (final skill in ungrouped) {
                  if (ComponentSelectionGuard.isBlocked(
                    skill.id,
                    excludedIds,
                    currentId: currentValue,
                  )) {
                    continue;
                  }
                  options.add(
                    _SearchOption<String?>(
                      label: skill.name,
                      value: skill.id,
                      subtitle: StoryCareerSectionText.otherGroupLabel,
                    ),
                  );
                }

                return options;
              }

              Future<void> openSearchForIndex(int index) async {
                final latestSlots = currentSlots();
                final result = await _showSearchablePicker<String?>(
                  context: context,
                  title: 'Select Skill',
                  options: buildSearchOptionsForIndex(index, latestSlots),
                  selected: latestSlots[index],
                );
                if (result == null) return;
                applySelection(index, result.value);
              }

              final border = OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: accent.withValues(alpha: 0.6), width: 1.4),
              );

              final slots = currentSlots();
              final remaining = slots.where((value) => value == null).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (grantedSkillConflicts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Career grants already assigned elsewhere: ${grantedConflictNames.join(', ')}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    '${StoryCareerSectionText.skillPickInstructionPrefix}$picksNeeded'
                    '${picksNeeded == 1 ? StoryCareerSectionText.skillPickInstructionSingularSuffix : StoryCareerSectionText.skillPickInstructionPluralSuffix}'
                    '${StoryCareerSectionText.skillPickInstructionSuffix}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  for (var index = 0; index < picksNeeded; index++) ...[
                    InkWell(
                      onTap: () => openSearchForIndex(index),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText:
                              '${StoryCareerSectionText.skillPickLabelPrefix}${index + 1}',
                          border: border,
                          enabledBorder: border,
                          suffixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          slots[index] != null
                              ? skillMap[slots[index]]!.name
                              : StoryCareerSectionText.chooseSkillPlaceholder,
                          style: TextStyle(
                            fontSize: 16,
                            color: slots[index] != null
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (remaining > 0)
                    Text(
                        '${StoryCareerSectionText.remainingPicksPrefix}$remaining'
                        '${remaining == 1 ? StoryCareerSectionText.remainingPicksSingularSuffix : StoryCareerSectionText.remainingPicksPluralSuffix}'
                        '${StoryCareerSectionText.remainingPicksSuffix}',
                        style: TextStyle(color: Colors.grey.shade400)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (perksNumber > 0)
            widget.langsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                  '${StoryCareerSectionText.failedToLoadLanguagesPrefix}$e'),
              data: (languages) => widget.skillsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                    '${StoryCareerSectionText.failedToLoadSkillsPrefix}$e'),
                data: (skills) {
                  final hasPerkType = perkType.trim().isNotEmpty;
                  final allowedGroups =
                      hasPerkType ? {perkType.trim()} : const <String>{};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PerksSelectionWidget(
                        heroId: widget.heroId,
                        selectedPerkIds: widget.chosenPerkIds,
                        reservedPerkIds: widget.reservedPerkIds,
                        perkType: hasPerkType ? perkType : null,
                        allowedGroups: allowedGroups.isNotEmpty ? allowedGroups : null,
                        pickCount: perksNumber,
                        languages: languages,
                        skills: skills,
                        reservedLanguageIds: {
                          ...widget.reservedLanguageIds,
                          ...widget.selectedLanguageIds,
                        },
                        reservedSkillIds: {
                          ...widget.reservedSkillIds,
                          ...widget.selectedSkillIds,
                        },
                        onSelectionChanged: widget.onPerkSelectionChanged,
                        onDirty: widget.onDirty,
                        showHeader: true,
                        headerTitle: StoryCareerSectionText.careerPerksTitle,
                        headerSubtitle:
                            hasPerkType
                                ? '${StoryCareerSectionText.allowedTypePrefix}$perkType'
                                : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          if (incidents.isNotEmpty)
            InkWell(
              onTap: () async {
                final options = <_SearchOption<String?>>[
                  const _SearchOption<String?>(
                    label: StoryCareerSectionText.chooseIncidentOption,
                    value: null,
                  ),
                  ...incidents.map(
                    (incident) => _SearchOption<String?>(
                      label: incident['name']?.toString() ??
                          StoryCareerSectionText.unknownIncidentLabel,
                      value: incident['name']?.toString(),
                    ),
                  ),
                ];
                final result = await _showSearchablePicker<String?>(
                  context: context,
                  title: StoryCareerSectionText.selectIncitingIncidentTitle,
                  options: options,
                  selected: widget.incidentName,
                );
                if (result == null) return;
                widget.onIncidentChanged(result.value);
                widget.onDirty();
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: StoryCareerSectionText.incitingIncidentLabel,
                  prefixIcon: Icon(Icons.auto_fix_high_outlined),
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  widget.incidentName ??
                      StoryCareerSectionText.chooseIncidentPlaceholder,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.incidentName != null
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          if (widget.incidentName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                incidents
                        .firstWhere(
                          (incident) => incident['name'] == widget.incidentName,
                          orElse: () => const <String, dynamic>{},
                        )['description']
                        ?.toString() ??
                    '',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerLanguageDropdown extends StatelessWidget {
  const _CareerLanguageDropdown({
    required this.languages,
    required this.value,
    required this.exclude,
    required this.label,
    required this.onChanged,
  });

  final List<model.Component> languages;
  final String? value;
  final Set<String?> exclude;
  final String label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<model.Component>>{
      'human': [],
      'ancestral': [],
      'dead': [],
    };
    for (final lang in languages) {
      final type = lang.data['language_type'] as String? ?? 'human';
      if (groups.containsKey(type)) {
        groups[type]!.add(lang);
      }
    }
    for (final group in groups.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    final validValue =
        value != null && languages.any((language) => language.id == value)
            ? value
            : null;

    Future<void> openSearch() async {
      final options = <_SearchOption<String?>>[
        _SearchOption<String?>(
          label: StoryCareerSectionText.chooseLanguageOption,
          value: null,
          subtitle: 'None selected',
        ),
      ];

      for (final key in ['human', 'ancestral', 'dead']) {
        for (final lang in groups[key]!) {
          final isCurrent = lang.id == validValue;
          if (!isCurrent && exclude.contains(lang.id)) continue;
          options.add(
            _SearchOption<String?>(
              label: lang.name,
              value: lang.id,
              subtitle: _buildLanguageSubtitle(lang, key),
            ),
          );
        }
      }

      final selected = await _showSearchablePicker<String?>(
        context: context,
        title: label,
        options: options,
        selected: validValue,
      );

      if (selected == null) return;
      onChanged(selected.value);
    }

    return InkWell(
      onTap: openSearch,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          validValue != null
              ? languages.firstWhere((l) => l.id == validValue).name
              : StoryCareerSectionText.chooseLanguagePlaceholder,
          style: TextStyle(
            fontSize: 16,
            color: validValue != null
                ? Colors.white
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  String _titleForGroup(String key) {
    switch (key) {
      case 'ancestral':
        return StoryCareerSectionText.ancestralLanguagesGroup;
      case 'dead':
        return StoryCareerSectionText.deadLanguagesGroup;
      default:
        return StoryCareerSectionText.humanLanguagesGroup;
    }
  }

  String _buildLanguageSubtitle(model.Component lang, String groupKey) {
    final data = lang.data;
    final parts = <String>[];
    
    // Add language type/group
    parts.add(_titleForGroup(groupKey));
    
    // Add region if available
    final region = data['region'] as String?;
    if (region != null && region.isNotEmpty) {
      parts.add('Region: $region');
    }
    
    // Add ancestry if available
    final ancestry = data['ancestry'] as String?;
    if (ancestry != null && ancestry.isNotEmpty) {
      parts.add('Ancestry: $ancestry');
    }
    
    // Add common topics if available
    final topics = (data['common_topics'] as List?)?.cast<String>();
    if (topics != null && topics.isNotEmpty) {
      parts.add('Topics: ${topics.take(3).join(', ')}${topics.length > 3 ? '...' : ''}');
    }
    
    return parts.join(' • ');
  }
}

class _SearchOption<T> {
  const _SearchOption({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final T? value;
  final String? subtitle;
}

class _PickerSelection<T> {
  const _PickerSelection({required this.value});

  final T? value;
}

Future<_PickerSelection<T>?> _showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<_SearchOption<T>> options,
  T? selected,
  Color? accent,
}) {
  final accentColor = accent ?? CreatorTheme.careerAccent;
  
  return showDialog<_PickerSelection<T>>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = query.trim().toLowerCase();
          final List<_SearchOption<T>> filtered = normalizedQuery.isEmpty
              ? options
              : options
                  .where(
                    (option) =>
                        option.label.toLowerCase().contains(normalizedQuery) ||
                        (option.subtitle?.toLowerCase().contains(
                              normalizedQuery,
                            ) ??
                            false),
                  )
                  .toList();

          return Dialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: accentColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(Icons.search, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: controller,
                      autofocus: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: StoryCareerSectionText.searchHint,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: Colors.grey.shade600,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  StoryCareerSectionText.noMatchesFound,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final isNoneOption = option.value == null;
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isNoneOption
                                      ? Colors.grey.shade800.withValues(alpha: 0.4)
                                      : isSelected
                                          ? accentColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accentColor.withValues(alpha: 0.4),
                                        )
                                      : isNoneOption
                                          ? Border.all(
                                              color: Colors.grey.shade700,
                                            )
                                          : null,
                                ),
                                child: ListTile(
                                  leading: isNoneOption
                                      ? Icon(Icons.remove_circle_outline,
                                          size: 20, color: Colors.grey.shade500)
                                      : null,
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isNoneOption
                                          ? Colors.grey.shade400
                                          : isSelected
                                              ? accentColor
                                              : Colors.grey.shade200,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontStyle: isNoneOption
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                  subtitle: option.subtitle != null
                                      ? Text(
                                          option.subtitle!,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle, color: accentColor, size: 22)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    _PickerSelection<T>(value: option.value),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Cancel button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                      ),
                      child: const Text(StoryCareerSectionText.cancelLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

