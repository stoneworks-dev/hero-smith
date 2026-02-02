import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/class_data.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/models/perks_models.dart';
import '../../../../core/services/perks_service.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_perks_widget_text.dart';
import '../../../../core/utils/selection_guard.dart';
import '../../../../widgets/perks/perks_selection_widget.dart';

typedef PerkSelectionChanged = void Function(
    StartingPerkSelectionResult result);

/// Widget for selecting starting perks based on class levels.
/// Uses the shared PerksSelectionWidget components for consistent UI.
class StartingPerksWidget extends ConsumerStatefulWidget {
  const StartingPerksWidget({
    super.key,
    required this.heroId,
    required this.classData,
    required this.selectedLevel,
    this.selectedPerks = const <String, String?>{},
    this.reservedPerkIds = const <String>{},
    this.reservedLanguageIds = const <String>{},
    this.reservedSkillIds = const <String>{},
    this.onSelectionChanged,
  });

  final String heroId;
  final ClassData classData;
  final int selectedLevel;
  final Map<String, String?> selectedPerks;
  final Set<String> reservedPerkIds;
  final Set<String> reservedLanguageIds;
  final Set<String> reservedSkillIds;
  final PerkSelectionChanged? onSelectionChanged;

  @override
  ConsumerState<StartingPerksWidget> createState() =>
      _StartingPerksWidgetState();
}

class _StartingPerksWidgetState extends ConsumerState<StartingPerksWidget>
    with AutomaticKeepAliveClientMixin {
  static const _accent = CreatorTheme.perksAccent;
  final StartingPerksService _service = const StartingPerksService();
  final MapEquality<String, String?> _mapEquality =
      const MapEquality<String, String?>();
  final SetEquality<String> _setEquality = const SetEquality<String>();


  StartingPerkPlan? _plan;
  final Map<String, List<String?>> _selections = {};

  Map<String, String?> _lastSelectionsSnapshot = const {};
  Set<String> _lastSelectedIdsSnapshot = const {};
  int _selectionCallbackVersion = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rebuildPlan(
      preserveSelections: false,
      externalSelections: widget.selectedPerks,
    );
  }

  @override
  void didUpdateWidget(covariant StartingPerksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final classChanged =
        oldWidget.classData.classId != widget.classData.classId;
    final levelChanged = oldWidget.selectedLevel != widget.selectedLevel;
    final reservedChanged = !_setEquality.equals(
      oldWidget.reservedPerkIds,
      widget.reservedPerkIds,
    );
    if (classChanged || levelChanged) {
      _rebuildPlan(
        preserveSelections: !classChanged,
        externalSelections: classChanged ? const {} : widget.selectedPerks,
      );
    } else if (!_mapEquality.equals(
        oldWidget.selectedPerks, widget.selectedPerks)) {
      _applyExternalSelections(widget.selectedPerks);
    }
    if (reservedChanged) {
      final changed = _applyReservedPruning();
      if (changed) {
        _notifySelectionChanged();
      }
    }
  }

  void _rebuildPlan({
    required bool preserveSelections,
    Map<String, String?>? externalSelections,
  }) {
    final plan = _service.buildPlan(
      classData: widget.classData,
      selectedLevel: widget.selectedLevel,
    );

    final newSelections = <String, List<String?>>{};
    final external = externalSelections ?? widget.selectedPerks;

    for (final allowance in plan.allowances) {
      final existing = preserveSelections
          ? (_selections[allowance.id] ?? const [])
          : const [];
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
        updated[i] = value;
      }

      newSelections[allowance.id] = updated;
    }

    setState(() {
      _plan = plan;
      _selections
        ..clear()
        ..addAll(newSelections);
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
      if (slots[slotIndex] != value) {
        slots[slotIndex] = value;
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
    if (widget.reservedPerkIds.isEmpty) return false;
    final allowIds =
        _selections.values.expand((slots) => slots).whereType<String>().toSet();
    final changed = ComponentSelectionGuard.pruneBlockedSelections(
      _selections,
      widget.reservedPerkIds,
      allowIds: allowIds,
    );
    if (changed) {
      setState(() {});
    }
    return changed;
  }

  void _handleAllowanceSelectionChanged(
    PerkAllowance allowance,
    Set<String> selection,
  ) {
    final slots = List<String?>.filled(allowance.pickCount, null);
    var index = 0;
    for (final id in selection) {
      if (index >= slots.length) break;
      slots[index] = id;
      index++;
    }

    setState(() {
      _selections[allowance.id] = slots;
      _removeDuplicatesFromOtherAllowances(
        currentAllowanceId: allowance.id,
        keep: selection,
      );
    });

    _notifySelectionChanged();
  }

  void _removeDuplicatesFromOtherAllowances({
    required String currentAllowanceId,
    required Set<String> keep,
  }) {
    for (final entry in _selections.entries) {
      if (entry.key == currentAllowanceId) continue;
      final slots = entry.value;
      for (var i = 0; i < slots.length; i++) {
        if (slots[i] != null && keep.contains(slots[i])) {
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
        selectionsBySlot[_slotKey(allowanceId, i)] = slots[i];
      }
    }

    final selectedIds = selectionsBySlot.values.whereType<String>().toSet();

    if (_mapEquality.equals(_lastSelectionsSnapshot, selectionsBySlot) &&
        _setEquality.equals(_lastSelectedIdsSnapshot, selectedIds)) {
      return;
    }

    final selectionsSnapshot = Map<String, String?>.from(selectionsBySlot);
    final selectedIdsSnapshot = Set<String>.from(selectedIds);

    _lastSelectionsSnapshot = selectionsSnapshot;
    _lastSelectedIdsSnapshot = selectedIdsSnapshot;
    _selectionCallbackVersion += 1;
    final version = _selectionCallbackVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _selectionCallbackVersion) return;
      widget.onSelectionChanged?.call(
        StartingPerkSelectionResult(
          selectionsBySlot: Map<String, String?>.from(selectionsSnapshot),
          selectedPerkIds: Set<String>.from(selectedIdsSnapshot),
        ),
      );
    });
  }

  String _slotKey(String allowanceId, int index) => '$allowanceId#$index';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final languagesAsync = ref.watch(componentsByTypeProvider('language'));
    final skillsAsync = ref.watch(componentsByTypeProvider('skill'));

    return languagesAsync.when(
      loading: () => _buildLoadingCard(),
      error: (e, _) => _buildErrorCard(
        ChoosePerksWidgetText.loadLanguagesErrorTitle,
        e.toString(),
      ),
      data: (languages) => skillsAsync.when(
        loading: () => _buildLoadingCard(),
        error: (e, _) => _buildErrorCard(
          ChoosePerksWidgetText.loadSkillsErrorTitle,
          e.toString(),
        ),
        data: (skills) => _buildContent(
          context,
          languages,
          skills,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return _buildContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CreatorTheme.loadingIndicator(_accent),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message) {
    return _buildContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CreatorTheme.errorMessage('$title: $message'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<model.Component> languages,
    List<model.Component> skills,
  ) {
    final plan = _plan;
    if (plan == null || plan.allowances.isEmpty) {
      return const SizedBox.shrink();
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
            title: ChoosePerksWidgetText.expansionTitle,
            subtitle: '${ChoosePerksWidgetText.selectionSubtitlePrefix}$assigned${ChoosePerksWidgetText.selectionSubtitleMiddle}$totalSlots${ChoosePerksWidgetText.selectionSubtitleSuffix}',
            icon: Icons.star,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan.allowances
                  .map((allowance) => _buildAllowanceSection(
                        context,
                        allowance,
                        languages,
                        skills,
                      ))
                  .toList(),
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
            title: ChoosePerksWidgetText.expansionTitle,
            subtitle: ChoosePerksWidgetText.sectionSubtitle,
            icon: Icons.star,
            accent: _accent,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildAllowanceSection(
    BuildContext context,
    PerkAllowance allowance,
    List<model.Component> languages,
    List<model.Component> skills,
  ) {
    final slots = _selections[allowance.id] ?? const [];
    final selected = LinkedHashSet<String>.from(slots.whereType<String>());
    final otherSelected = _selections.entries
        .where((entry) => entry.key != allowance.id)
        .expand((entry) => entry.value)
        .whereType<String>()
        .toSet();

    final allowedGroups = allowance.allowedGroups
        .map((group) => group.trim())
        .where((group) => group.isNotEmpty)
        .toSet();

    final allowedGroupsText =
        allowedGroups.isEmpty
            ? ChoosePerksWidgetText.anyPerkLabel
            : allowedGroups.map(_formatGroupLabel).join(', ');

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
            '${ChoosePerksWidgetText.allowancePickPrefix}${allowance.pickCount}${allowance.pickCount == 1 ? ChoosePerksWidgetText.allowancePickSingularSuffix : ChoosePerksWidgetText.allowancePickPluralSuffix}${ChoosePerksWidgetText.allowancePickFromPrefix}$allowedGroupsText',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 8),
          PerksSelectionWidget(
            heroId: widget.heroId,
            selectedPerkIds: selected,
            reservedPerkIds: {
              ...widget.reservedPerkIds,
              ...otherSelected,
            },
            perkType: allowedGroups.length == 1 ? allowedGroups.first : null,
            allowedGroups: allowedGroups.isNotEmpty ? allowedGroups : null,
            pickCount: allowance.pickCount,
            languages: languages,
            skills: skills,
            reservedLanguageIds: widget.reservedLanguageIds,
            reservedSkillIds: widget.reservedSkillIds,
            onSelectionChanged: (selection) =>
                _handleAllowanceSelectionChanged(allowance, selection),
            onDirty: () => setState(() {}),
            showHeader: true,
            headerTitle: ChoosePerksWidgetText.headerTitle,
          ),
        ],
      ),
    );
  }

  String _formatGroupLabel(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return ChoosePerksWidgetText.generalLabel;
    }
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}')
        .join(' ');
  }
}
