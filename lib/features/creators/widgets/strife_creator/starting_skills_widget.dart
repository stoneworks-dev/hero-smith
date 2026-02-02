import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/skills_models.dart';
import '../../../../core/services/skill_data_service.dart';
import '../../../../core/services/skills_service.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/starting_skills_widget_text.dart';
import '../../../../core/utils/selection_guard.dart';

typedef SkillSelectionChanged = void Function(
    StartingSkillSelectionResult result);

class StartingSkillsWidget extends StatefulWidget {
  const StartingSkillsWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedSkills = const <String, String?>{},
    this.reservedSkillIds = const <String>{},
    this.onSelectionChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final Map<String, String?> selectedSkills;
  final Set<String> reservedSkillIds;
  final SkillSelectionChanged? onSelectionChanged;

  @override
  State<StartingSkillsWidget> createState() => _StartingSkillsWidgetState();
}

class _StartingSkillsWidgetState extends State<StartingSkillsWidget> {
  static const _accent = CreatorTheme.skillsAccent;
  final StartingSkillsService _service = const StartingSkillsService();
  final SkillDataService _skillDataService = SkillDataService();
  final MapEquality<String, String?> _mapEquality =
      const MapEquality<String, String?>();
  final SetEquality<String> _setEquality = const SetEquality<String>();
  final ListEquality<String> _listEquality = const ListEquality<String>();

  bool _isLoading = true;
  String? _error;

  List<SkillOption> _skillOptions = const [];
  Map<String, SkillOption> _skillById = const {};
  Map<String, String> _skillIdByName = const {};

  StartingSkillPlan? _plan;
  final Map<String, List<String?>> _selections = {};
  Map<String, String?> _lastSelectionsSnapshot = const {};
  Set<String> _lastGrantedIdsSnapshot = const {};
  List<String> _lastGrantedNamesSnapshot = const [];
  int _selectionCallbackVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void didUpdateWidget(covariant StartingSkillsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final classChanged =
        oldWidget.classData.classId != widget.classData.classId;
    final levelChanged = oldWidget.selectedLevel != widget.selectedLevel;
    final reservedChanged = !_setEquality.equals(
      oldWidget.reservedSkillIds,
      widget.reservedSkillIds,
    );
    if ((classChanged || levelChanged) && !_isLoading && _error == null) {
      _rebuildPlan(
        preserveSelections: !classChanged,
        externalSelections: classChanged ? const {} : widget.selectedSkills,
      );
    } else if (oldWidget.selectedSkills != widget.selectedSkills) {
      _applyExternalSelections(widget.selectedSkills);
    }
    if (reservedChanged && !_isLoading && _error == null) {
      final changed = _applyReservedPruning();
      if (changed) {
        _notifySelectionChanged();
      }
    }
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final skills = await _skillDataService.loadSkills();
      if (!mounted) return;
      _skillOptions = skills;
      _skillById = {
        for (final option in skills) option.id: option,
      };
      _skillIdByName = {
        for (final option in skills) option.name.toLowerCase(): option.id,
      };
      _rebuildPlan(
        preserveSelections: false,
        externalSelections: widget.selectedSkills,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '${StartingSkillsWidgetText.loadErrorPrefix}$e';
      });
    }
  }

  void _rebuildPlan({
    required bool preserveSelections,
    Map<String, String?>? externalSelections,
  }) {
    final plan = _service.buildPlan(
      classData: widget.classData,
      selectedLevel: widget.selectedLevel,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      // via class feature grants (skill_group options in subclass features)
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );

    final newSelections = <String, List<String?>>{};
    final external = externalSelections ?? widget.selectedSkills;

    for (final allowance in plan.allowances) {
      final existing =
          preserveSelections ? (_selections[allowance.id] ?? const []) : const [];
      final updated = List<String?>.filled(allowance.pickCount, null);

      for (var i = 0; i < allowance.pickCount; i++) {
        String? value;
        if (preserveSelections && i < existing.length) {
          value = existing[i];
        }
        final key = _slotKey(allowance.id, i);
        if (external.containsKey(key)) {
          value = external[key];
        }
        updated[i] = _resolveSkillId(value);
      }

      newSelections[allowance.id] = updated;
    }

    setState(() {
      _plan = plan;
      _selections
        ..clear()
        ..addAll(newSelections);
      _isLoading = false;
      _error = null;
    });

    _applyReservedPruning();
    _notifySelectionChanged();
  }

  void _applyExternalSelections(Map<String, String?> selections) {
    var changed = false;
    selections.forEach((key, value) {
      final parts = key.split('#');
      if (parts.length != 2) return;
      final allowanceId = parts.first;
      final slotIndex = int.tryParse(parts.last);
      if (slotIndex == null) return;
      final slots = _selections[allowanceId];
      if (slots == null || slotIndex < 0 || slotIndex >= slots.length) return;
      final resolved = _resolveSkillId(value);
      if (slots[slotIndex] != resolved) {
        slots[slotIndex] = resolved;
        changed = true;
      }
    });
    if (changed) {
      setState(() {});
      _applyReservedPruning();
      _notifySelectionChanged();
    }
  }

  bool _applyReservedPruning() {
    if (widget.reservedSkillIds.isEmpty) return false;
    final allowIds = _selections.values
        .expand((slots) => slots)
        .whereType<String>()
        .toSet();
    final changed = ComponentSelectionGuard.pruneBlockedSelections(
      _selections,
      widget.reservedSkillIds,
      allowIds: allowIds,
    );
    if (changed) {
      setState(() {});
    }
    return changed;
  }

  String? _resolveSkillId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (_skillById.containsKey(trimmed)) {
      return trimmed;
    }
    final lower = trimmed.toLowerCase();
    return _skillIdByName[lower];
  }

  void _handleSkillSelection(
    SkillAllowance allowance,
    int slotIndex,
    String? value,
  ) {
    final resolved = _resolveSkillId(value);
    final slots = _selections[allowance.id];
    if (slots == null || slotIndex < 0 || slotIndex >= slots.length) {
      return;
    }
    if (slots[slotIndex] == resolved) return;

    setState(() {
      slots[slotIndex] = resolved;
      if (resolved != null) {
        _removeDuplicateSelections(
          skillId: resolved,
          exceptAllowanceId: allowance.id,
          exceptSlotIndex: slotIndex,
        );
      }
    });

    _notifySelectionChanged();
  }

  void _removeDuplicateSelections({
    required String skillId,
    required String exceptAllowanceId,
    required int exceptSlotIndex,
  }) {
    for (final entry in _selections.entries) {
      final allowanceId = entry.key;
      final slots = entry.value;
      for (var i = 0; i < slots.length; i++) {
        if (allowanceId == exceptAllowanceId && i == exceptSlotIndex) {
          continue;
        }
        if (slots[i] == skillId) {
          slots[i] = null;
        }
      }
    }
  }

  void _notifySelectionChanged() {
    if (widget.onSelectionChanged == null) return;
    final plan = _plan;
    if (plan == null) return;

    final selectionsBySlot = <String, String?>{};
    for (final entry in _selections.entries) {
      final allowanceId = entry.key;
      final slots = entry.value;
      for (var i = 0; i < slots.length; i++) {
        if (!_skillById.containsKey(slots[i])) {
          selectionsBySlot[_slotKey(allowanceId, i)] = null;
        } else {
          selectionsBySlot[_slotKey(allowanceId, i)] = slots[i];
        }
      }
    }

    final grantedIds = <String>{};
    for (final name in plan.grantedSkillNames) {
      final resolved = _resolveSkillId(name);
      if (resolved != null) {
        grantedIds.add(resolved);
      }
    }

    final grantedNames = List<String>.from(plan.grantedSkillNames);

    if (_mapEquality.equals(_lastSelectionsSnapshot, selectionsBySlot) &&
        _setEquality.equals(_lastGrantedIdsSnapshot, grantedIds) &&
        _listEquality.equals(_lastGrantedNamesSnapshot, grantedNames)) {
      return;
    }

    final selectionsSnapshot = Map<String, String?>.from(selectionsBySlot);
    final grantedIdsSnapshot = Set<String>.from(grantedIds);
    final grantedNamesSnapshot = List<String>.from(grantedNames);

    _lastSelectionsSnapshot = selectionsSnapshot;
    _lastGrantedIdsSnapshot = grantedIdsSnapshot;
    _lastGrantedNamesSnapshot = grantedNamesSnapshot;
    _selectionCallbackVersion += 1;
    final version = _selectionCallbackVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _selectionCallbackVersion) return;
      widget.onSelectionChanged?.call(
        StartingSkillSelectionResult(
          selectionsBySlot:
              Map<String, String?>.from(selectionsSnapshot),
          grantedSkillIds: Set<String>.from(grantedIdsSnapshot),
          grantedSkillNames: List<String>.from(grantedNamesSnapshot),
        ),
      );
    });
  }

  List<SkillOption> _optionsForAllowance(SkillAllowance allowance) {
    if (allowance.allowedGroups.isEmpty) {
      return _skillOptions;
    }
    return _skillOptions
        .where((option) => allowance.allowedGroups.contains(option.group))
        .toList();
  }

  String _slotKey(String allowanceId, int index) => '$allowanceId#$index';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CreatorTheme.loadingIndicator(_accent),
        ),
      );
    }

    if (_error != null) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CreatorTheme.errorMessage(_error!),
        ),
      );
    }

    final plan = _plan;
    if (plan == null || plan.allowances.isEmpty) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            StartingSkillsWidgetText.noSkillsMessage,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      );
    }

    final totalSlots = plan.allowances.fold<int>(
      0,
      (prev, allowance) => prev + allowance.pickCount,
    );
    final assigned =
        _selections.values.expand((slots) => slots).whereType<String>().length;

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: StartingSkillsWidgetText.expansionTitle,
            subtitle: '${StartingSkillsWidgetText.selectionSubtitlePrefix}$assigned${StartingSkillsWidgetText.selectionSubtitleMiddle}$totalSlots${StartingSkillsWidgetText.selectionSubtitleSuffix}',
            icon: Icons.psychology,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.grantedSkillNames.isNotEmpty)
                  _buildGrantedSection(plan.grantedSkillNames),
                if (plan.quickBuildSuggestions.isNotEmpty)
                  _buildQuickBuildSection(plan.quickBuildSuggestions),
                ...plan.allowances.map(_buildAllowanceSection),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: StartingSkillsWidgetText.expansionTitle,
            subtitle: StartingSkillsWidgetText.sectionSubtitle,
            icon: Icons.psychology,
            accent: _accent,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildGrantedSection(List<String> granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StartingSkillsWidgetText.grantedSkillsTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _accent,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: granted.map((skill) {
              // Check if this granted skill is a duplicate (already reserved)
              final skillId = _resolveSkillId(skill);
              final isDuplicate = skillId != null &&
                  widget.reservedSkillIds.contains(skillId);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDuplicate
                      ? Colors.orange.withValues(alpha: 0.15)
                      : _accent.withValues(alpha: 0.15),
                  border: isDuplicate
                      ? Border.all(color: Colors.orange.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDuplicate) ...[
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      skill,
                      style: TextStyle(
                        color: isDuplicate
                            ? Colors.orange.shade300
                            : _accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isDuplicate) ...[
                      const SizedBox(width: 4),
                      Text(
                        StartingSkillsWidgetText.duplicateLabel,
                        style: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBuildSection(List<String> quickBuild) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StartingSkillsWidgetText.quickBuildTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: quickBuild
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _accent.withValues(alpha: 0.15),
                      border: Border.all(color: _accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceSection(SkillAllowance allowance) {
    final options = _optionsForAllowance(allowance);
    final slots = _selections[allowance.id] ?? const [];

    final allowedGroupsText = allowance.allowedGroups.isEmpty
        ? StartingSkillsWidgetText.anySkillLabel
        : allowance.allowedGroups
            .map((group) => group[0].toUpperCase() + group.substring(1))
            .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allowance.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${StartingSkillsWidgetText.allowancePickPrefix}${allowance.pickCount}${allowance.pickCount == 1 ? StartingSkillsWidgetText.allowancePickSingularSuffix : StartingSkillsWidgetText.allowancePickPluralSuffix}${StartingSkillsWidgetText.allowancePickFromPrefix}$allowedGroupsText',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...List.generate(slots.length, (index) {
            final current = slots[index];
            final otherSelected = slots
                .asMap()
                .entries
                .where((entry) => entry.key != index)
                .map((entry) => entry.value)
                .whereType<String>()
                .toSet();
            final reservedIds = <String>{
              ...widget.reservedSkillIds,
              ...otherSelected,
            };
            final availableOptions = ComponentSelectionGuard.filterAllowed(
              options: options,
              reservedIds: reservedIds,
              idSelector: (option) => option.id,
              currentId: current,
            );
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 12),
              child: DropdownButtonFormField<String?>(
                value: current,
                dropdownColor: FormTheme.surface,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText:
                      '${StartingSkillsWidgetText.choiceLabelPrefix}${index + 1}',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                    borderSide: BorderSide(color: _accent),
                  ),
                  filled: true,
                  fillColor: FormTheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(StartingSkillsWidgetText.unassignedLabel),
                  ),
                  ...availableOptions.map(
                    (option) => DropdownMenuItem<String?>(
                      value: option.id,
                      child: Text(
                        '${option.name}${StartingSkillsWidgetText.selectedOptionGroupPrefix}${option.group}${StartingSkillsWidgetText.selectedOptionGroupSuffix}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _handleSkillSelection(allowance, index, value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

