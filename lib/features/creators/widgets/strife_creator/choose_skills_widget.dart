import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/skills_models.dart';
import '../../../../core/models/subclass_models.dart';
import '../../../../core/services/skill_data_service.dart';
import '../../../../core/services/skills_service.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_skills_widget_text.dart';
import '../../../../core/utils/selection_guard.dart';

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
}) {
  const accent = CreatorTheme.skillsAccent;
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
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.2),
                          accent.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: accent.withValues(alpha: 0.3),
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
                            color: accent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(Icons.psychology, color: accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: accent,
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
                        hintText: ChooseSkillsWidgetText.searchHint,
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
                          borderSide: BorderSide(color: accent, width: 2),
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
                                  ChooseSkillsWidgetText.noMatchesFound,
                                  style: TextStyle(color: Colors.grey.shade500),
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
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accent.withValues(alpha: 0.4),
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected ? accent : Colors.grey.shade200,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                                      ? Icon(Icons.check_circle, color: accent, size: 22)
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
                      child: const Text(ChooseSkillsWidgetText.cancelLabel),
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

typedef SkillSelectionChanged = void Function(
    StartingSkillSelectionResult result);

class StartingSkillsWidget extends StatefulWidget {
  const StartingSkillsWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedSubclass,
    this.selectedSkills = const <String, String?>{},
    this.reservedSkillIds = const <String>{},
    this.onSelectionChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final SubclassSelectionResult? selectedSubclass;
  final Map<String, String?> selectedSkills;
  final Set<String> reservedSkillIds;
  final SkillSelectionChanged? onSelectionChanged;

  @override
  State<StartingSkillsWidget> createState() => _StartingSkillsWidgetState();
}

class _StartingSkillsWidgetState extends State<StartingSkillsWidget>
    with AutomaticKeepAliveClientMixin {
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
  Set<String> _resolvedExternalReservedSkillIds = const {};
  Set<String> _resolvedGrantedSkillIds = const {};

  StartingSkillPlan? _plan;
  final Map<String, List<String?>> _selections = {};
  Map<String, String?> _lastSelectionsSnapshot = const {};
  Set<String> _lastGrantedIdsSnapshot = const {};
  List<String> _lastGrantedNamesSnapshot = const [];
  int _selectionCallbackVersion = 0;

  @override
  bool get wantKeepAlive => true;

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
    final subclassChanged =
        oldWidget.selectedSubclass != widget.selectedSubclass;
    final reservedChanged = !_setEquality.equals(
      oldWidget.reservedSkillIds,
      widget.reservedSkillIds,
    );
    if ((classChanged || levelChanged || subclassChanged) &&
        !_isLoading &&
        _error == null) {
      _rebuildPlan(
        preserveSelections: !classChanged,
        externalSelections:
            classChanged ? const {} : widget.selectedSkills,
      );
    } else if (oldWidget.selectedSkills != widget.selectedSkills) {
      _applyExternalSelections(widget.selectedSkills);
    }
    if (reservedChanged && !_isLoading && _error == null) {
      setState(() {
        _resolvedExternalReservedSkillIds =
            _resolveReservedSkillIds(widget.reservedSkillIds);
      });
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
        for (final option in skills) option.id.toLowerCase(): option.id,
      };
      _resolvedExternalReservedSkillIds =
          _resolveReservedSkillIds(widget.reservedSkillIds);
      _rebuildPlan(
        preserveSelections: false,
        externalSelections: widget.selectedSkills,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '${ChooseSkillsWidgetText.loadErrorPrefix}$e';
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
      subclassSelection: widget.selectedSubclass,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      // via class feature grants (skill_group options in subclass features)
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );

    final newSelections = <String, List<String?>>{};
    final external = externalSelections ?? widget.selectedSkills;
    final resolvedReserved =
        _resolveReservedSkillIds(widget.reservedSkillIds);
    final resolvedGranted =
        _resolveGrantedSkillIds(plan.grantedSkillNames);

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
      _resolvedExternalReservedSkillIds = resolvedReserved;
      _resolvedGrantedSkillIds = resolvedGranted;
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

  Set<String> get _effectiveReservedSkillIds => {
        ..._resolvedExternalReservedSkillIds,
        ..._resolvedGrantedSkillIds,
      };

  bool _applyReservedPruning() {
    final reserved = _effectiveReservedSkillIds;
    if (reserved.isEmpty) return false;
    final allowIds = _selections.values
        .expand((slots) => slots)
        .whereType<String>()
        .toSet();
    final changed = ComponentSelectionGuard.pruneBlockedSelections(
      _selections,
      reserved,
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

  Set<String> _resolveReservedSkillIds(Iterable<String> values) {
    final resolved = <String>{};
    for (final value in values) {
      final normalized = _resolveSkillId(value) ?? value.trim();
      if (normalized.isNotEmpty) {
        resolved.add(normalized);
      }
    }
    return resolved;
  }

  Set<String> _resolveGrantedSkillIds(Iterable<String> names) {
    final resolved = <String>{};
    for (final name in names) {
      final id = _resolveSkillId(name);
      if (id != null) {
        resolved.add(id);
      }
    }
    return resolved;
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
    grantedIds.addAll(_resolvedGrantedSkillIds);

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
    // If no restrictions, allow all skills
    if (allowance.allowedGroups.isEmpty && 
        allowance.individualSkillChoices.isEmpty) {
      return _skillOptions;
    }

    final options = <SkillOption>[];
    
    // Add skills from allowed groups
    if (allowance.allowedGroups.isNotEmpty) {
      options.addAll(
        _skillOptions.where(
          (option) => allowance.allowedGroups.contains(option.group),
        ),
      );
    }
    
    // Add individual skill choices by name
    if (allowance.individualSkillChoices.isNotEmpty) {
      for (final skillName in allowance.individualSkillChoices) {
        final normalizedName = skillName.trim().toLowerCase();
        final matchingSkill = _skillOptions.firstWhereOrNull(
          (option) => option.name.toLowerCase() == normalizedName,
        );
        if (matchingSkill != null && !options.contains(matchingSkill)) {
          options.add(matchingSkill);
        }
      }
    }
    
    // If only individual choices (no groups), return just those
    if (allowance.allowedGroups.isEmpty) {
      return options;
    }
    
    return options;
  }

  Set<String> _grantedConflictIds() {
    final grantList = (_plan?.grantedSkillNames ?? const <String>[])
        .map(_resolveSkillId)
        .whereType<String>()
        .toList();
    final internalDupes = _findDuplicateIds(grantList);
    final selectedIds = _selections.values
        .expand((slots) => slots)
        .whereType<String>()
        .toSet();
    // Ignore reserves that come from the grants themselves; only flag when
    // another picker or DB entry holds the same skill.
    final externalReserved = _resolvedExternalReservedSkillIds
        .difference(_resolvedGrantedSkillIds);
    final conflicts = _resolvedGrantedSkillIds
        .intersection({...externalReserved, ...selectedIds});
    return {...internalDupes, ...conflicts};
  }

  List<String> _namesForIds(Iterable<String> ids) {
    final names = <String>[];
    for (final id in ids) {
      final option = _skillById[id];
      if (option != null && option.name.isNotEmpty) {
        names.add(option.name);
      } else if (id.isNotEmpty) {
        names.add(id);
      }
    }
    return names;
  }

  Set<String> _findDuplicateIds(Iterable<String> values) {
    final seen = <String>{};
    final dupes = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        dupes.add(value);
      }
    }
    return dupes;
  }

  String _slotKey(String allowanceId, int index) => '$allowanceId#$index';

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            ChooseSkillsWidgetText.noSkillsMessage,
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
            title: ChooseSkillsWidgetText.expansionTitle,
            subtitle: '${ChooseSkillsWidgetText.selectionSubtitlePrefix}$assigned${ChooseSkillsWidgetText.selectionSubtitleMiddle}$totalSlots${ChooseSkillsWidgetText.selectionSubtitleSuffix}',
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
            title: ChooseSkillsWidgetText.expansionTitle,
            subtitle: ChooseSkillsWidgetText.sectionSubtitle,
            icon: Icons.psychology,
            accent: _accent,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildGrantedSection(List<String> granted) {
    final duplicateGrantNames = _namesForIds(_grantedConflictIds()).toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChooseSkillsWidgetText.grantedSkillsTitle,
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
            children: granted
                .map(
                  (skill) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _accent.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (duplicateGrantNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${ChooseSkillsWidgetText.duplicateGrantPrefix}${duplicateGrantNames.join(', ')}${ChooseSkillsWidgetText.duplicateGrantSuffix}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ],
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
            ChooseSkillsWidgetText.quickBuildTitle,
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
        ? ChooseSkillsWidgetText.anySkillLabel
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
            '${ChooseSkillsWidgetText.allowancePickPrefix}${allowance.pickCount}${allowance.pickCount == 1 ? ChooseSkillsWidgetText.allowancePickSingularSuffix : ChooseSkillsWidgetText.allowancePickPluralSuffix}${ChooseSkillsWidgetText.allowancePickFromPrefix}$allowedGroupsText',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...List.generate(slots.length, (index) {
            final current = slots[index];
            final otherSelectedSameAllowance = slots
                .asMap()
                .entries
                .where((entry) => entry.key != index)
                .map((entry) => entry.value)
                .whereType<String>()
                .toSet();
            final selectedInOtherAllowances = _selections.entries
                .where((entry) => entry.key != allowance.id)
                .expand((entry) => entry.value)
                .whereType<String>()
                .toSet();
            final reservedIds = <String>{
              ..._effectiveReservedSkillIds,
              ...otherSelectedSameAllowance,
              ...selectedInOtherAllowances,
            };
            final availableOptions = ComponentSelectionGuard.filterAllowed(
              options: options,
              reservedIds: reservedIds,
              idSelector: (option) => option.id,
              currentId: current,
            );
            final selectedOption = current != null
                ? availableOptions.firstWhere(
                    (opt) => opt.id == current,
                    orElse: () => availableOptions.firstOrNull ??
                        SkillOption(
                          id: current,
                          name: ChooseSkillsWidgetText.unassignedFallbackName,
                          group: '',
                          description: '',
                        ),
                  )
                : null;

            Future<void> openSearch() async {
              final searchOptions = <_SearchOption<String?>>[
                const _SearchOption<String?>(
                  label: ChooseSkillsWidgetText.unassignedSearchOptionLabel,
                  value: null,
                ),
                ...availableOptions.map(
                  (option) => _SearchOption<String?>(
                    label: option.name,
                    value: option.id,
                    subtitle: option.group,
                  ),
                ),
              ];

              final result = await _showSearchablePicker<String?>(
                context: context,
                title: '${allowance.label}${ChooseSkillsWidgetText.searchTitleSeparator}${index + 1}',
                options: searchOptions,
                selected: current,
              );

              if (result == null) return;
              _handleSkillSelection(allowance, index, result.value);
            }

            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 12),
              child: InkWell(
                onTap: openSearch,
                borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: FormTheme.surface,
                    borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ChooseSkillsWidgetText.choiceLabelPrefix}${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedOption != null
                                  ? '${selectedOption.name}${ChooseSkillsWidgetText.selectedOptionGroupPrefix}${selectedOption.group}${ChooseSkillsWidgetText.selectedOptionGroupSuffix}'
                                  : ChooseSkillsWidgetText.unassignedDisplayLabel,
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedOption != null
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.search, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

