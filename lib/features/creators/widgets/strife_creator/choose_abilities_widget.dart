import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/component.dart';
import '../../../../core/models/abilities_models.dart';
import '../../../../core/models/characteristics_models.dart';
import '../../../../core/services/ability_data_service.dart';
import '../../../../core/services/abilities_service.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_abilities_widget_text.dart';
import '../../../../core/utils/selection_guard.dart';
import '../../../../widgets/abilities/ability_expandable_item.dart';
import '../../../../widgets/abilities/abilities_shared.dart';

// Helper classes for picker


class _PickerSelection {
  final String? value;
  final String? label;

  const _PickerSelection({
    this.value,
    this.label,
  });
}

typedef AbilitySelectionChanged = void Function(
    StartingAbilitySelectionResult result);

class StartingAbilitiesWidget extends StatefulWidget {
  const StartingAbilitiesWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedSubclassName,
    this.selectedDomainNames = const <String>[],
    this.selectedAbilities = const <String, String?>{},
    this.reservedAbilityIds = const <String>{},
    this.onSelectionChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final String? selectedSubclassName;
  final List<String> selectedDomainNames;
  final Map<String, String?> selectedAbilities;
  final Set<String> reservedAbilityIds;
  final AbilitySelectionChanged? onSelectionChanged;

  @override
  State<StartingAbilitiesWidget> createState() =>
      _StartingAbilitiesWidgetState();
}

class _StartingAbilitiesWidgetState extends State<StartingAbilitiesWidget>
    with AutomaticKeepAliveClientMixin {
  static const _accent = CreatorTheme.abilitiesAccent;
  
  final StartingAbilitiesService _service = const StartingAbilitiesService();
  final AbilityDataService _abilityDataService = AbilityDataService();
  final MapEquality<String, String?> _mapEquality =
      const MapEquality<String, String?>();
  final SetEquality<String> _setEquality = const SetEquality<String>();

  bool _isLoading = true;
  String? _error;

  StartingAbilityPlan? _plan;
  final Map<String, List<String?>> _selections = {};
  Map<String, String?> _lastSelectionsSnapshot = const {};
  Set<String> _lastSelectedIdsSnapshot = const {};
  int _selectionCallbackVersion = 0;

  List<AbilityOption> _abilityOptions = const [];
  Map<String, AbilityOption> _abilityById = const {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAbilities();
  }

  @override
  void didUpdateWidget(covariant StartingAbilitiesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final classChanged =
        oldWidget.classData.classId != widget.classData.classId;
    final levelChanged = oldWidget.selectedLevel != widget.selectedLevel;
    final subclassChanged =
        oldWidget.selectedSubclassName != widget.selectedSubclassName;
    final domainsChanged = !_setEquality.equals(
      _normalizedDomainNames(oldWidget.selectedDomainNames),
      _normalizedDomainNames(widget.selectedDomainNames),
    );
    final reservedChanged = !_setEquality.equals(
      oldWidget.reservedAbilityIds,
      widget.reservedAbilityIds,
    );
    if (classChanged) {
      _loadAbilities();
      return;
    }
    if ((levelChanged || subclassChanged || domainsChanged) &&
        !_isLoading &&
        _error == null) {
      _rebuildPlan(
        preserveSelections: !(subclassChanged || domainsChanged),
        externalSelections: widget.selectedAbilities,
      );
    } else if (!_mapEquality.equals(
        oldWidget.selectedAbilities, widget.selectedAbilities)) {
      _applyExternalSelections(widget.selectedAbilities);
    }
    if (reservedChanged && !_isLoading && _error == null) {
      final changed = _applyReservedPruning();
      if (changed) {
        _notifySelectionChanged();
      }
    }
  }

  Future<void> _loadAbilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classSlug = _classSlug(widget.classData.classId);
      final components =
          await _abilityDataService.loadClassAbilities(classSlug);
      if (!mounted) return;
      final options = components.map(_mapComponentToOption).toList();
      final byId = {
        for (final option in options) option.id: option,
      };
      _abilityOptions = options;
      _abilityById = byId;
      _rebuildPlan(
        preserveSelections: false,
        externalSelections: widget.selectedAbilities,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '${ChooseAbilitiesWidgetText.loadErrorPrefix}$e';
      });
    }
  }

  AbilityOption _mapComponentToOption(Component component) {
    try {
      final data = component.data;
      final abilityData = AbilityData.fromComponent(component);

      final bool isSignature = abilityData.isSignature;
      final int? costAmount = abilityData.costAmount;
      final String? resource = abilityData.resourceLabel ?? abilityData.resourceType;

      final level = _resolveAbilityLevel(component);
      final subclassRaw = data['subclass']?.toString().trim();
      final subclass =
          subclassRaw == null || subclassRaw.isEmpty ? null : subclassRaw;

      return AbilityOption(
        id: component.id,
        name: component.name,
        component: component,
        level: level,
        isSignature: isSignature,
        costAmount: costAmount,
        resource: resource,
        subclass: subclass,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error mapping component to option:');
        debugPrint('Component ID: ${component.id}');
        debugPrint('Component Name: ${component.name}');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
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
    final external = externalSelections ?? widget.selectedAbilities;

    for (final allowance in plan.allowances) {
      final existing = preserveSelections
          ? (_selections[allowance.id] ?? const [])
          : const [];
      final updated = List<String?>.filled(allowance.pickCount, null);

      for (var i = 0; i < allowance.pickCount; i++) {
        String? value;
        if (i < existing.length) {
          value = existing[i];
        }
        final key = _slotKey(allowance.id, i);
        if (external.containsKey(key)) {
          value = external[key];
        }
        updated[i] = _resolveAbilityId(value);
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
      _lastSelectionsSnapshot = const {};
      _lastSelectedIdsSnapshot = const {};
      _selectionCallbackVersion += 1;
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
      final resolved = _resolveAbilityId(value);
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
    if (widget.reservedAbilityIds.isEmpty) return false;
    final allowIds = _selections.values
        .expand((slots) => slots)
        .whereType<String>()
        .toSet();
    final changed = ComponentSelectionGuard.pruneBlockedSelections(
      _selections,
      widget.reservedAbilityIds,
      allowIds: allowIds,
    );
    if (changed) {
      setState(() {});
    }
    return changed;
  }

  String? _resolveAbilityId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (_abilityById.containsKey(trimmed)) {
      return trimmed;
    }
    final lowered = trimmed.toLowerCase();
    try {
      return _abilityById.keys.firstWhere((id) => id.toLowerCase() == lowered);
    } catch (_) {
      return null;
    }
  }

  void _handleAbilitySelection(
    AbilityAllowance allowance,
    int slotIndex,
    String? value,
  ) {
    final resolved = _resolveAbilityId(value);
    final slots = _selections[allowance.id];
    if (slots == null || slotIndex < 0 || slotIndex >= slots.length) return;
    if (slots[slotIndex] == resolved) return;

    setState(() {
      slots[slotIndex] = resolved;
      if (resolved != null) {
        _removeDuplicateSelections(
          abilityId: resolved,
          exceptAllowanceId: allowance.id,
          exceptSlotIndex: slotIndex,
        );
      }
    });

    _notifySelectionChanged();
  }

  void _removeDuplicateSelections({
    required String abilityId,
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
        if (slots[i] == abilityId) {
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
    final selectedIds = <String>{};

    for (final entry in _selections.entries) {
      final allowanceId = entry.key;
      final slots = entry.value;
      for (var i = 0; i < slots.length; i++) {
        final value = slots[i];
        final key = _slotKey(allowanceId, i);
        final normalized =
            value != null && _abilityById.containsKey(value) ? value : null;
        selectionsBySlot[key] = normalized;
        if (normalized != null) {
          selectedIds.add(normalized);
        }
      }
    }

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
        StartingAbilitySelectionResult(
          selectionsBySlot: Map<String, String?>.from(selectionsSnapshot),
          selectedAbilityIds: Set<String>.from(selectedIdsSnapshot),
        ),
      );
    });
  }

  Set<String> _selectedAbilityIds({
    String? exceptAllowanceId,
    int? exceptSlotIndex,
  }) {
    final ids = <String>{};
    for (final entry in _selections.entries) {
      final allowanceId = entry.key;
      final slots = entry.value;
      for (var i = 0; i < slots.length; i++) {
        if (allowanceId == exceptAllowanceId && i == exceptSlotIndex) {
          continue;
        }
        final value = slots[i];
        if (value != null && value.isNotEmpty) {
          ids.add(value);
        }
      }
    }
    return ids;
  }

  List<AbilityOption> _optionsForAllowance(AbilityAllowance allowance) {
    return _abilityOptions.where((option) {
      if (allowance.isSignature && !option.isSignature) return false;
      if (!allowance.isSignature && option.isSignature) return false;
      if (allowance.costAmount != null &&
          option.costAmount != allowance.costAmount) {
        return false;
      }
      if (allowance.requiresSubclass) {
        // Subclass abilities must have a subclass field
        if (option.subclass == null || option.subclass!.isEmpty) {
          return false;
        }
        if (_isConduitClass) {
          final selectedDomains =
              _normalizedDomainNames(widget.selectedDomainNames);
          if (selectedDomains.isEmpty) {
            return false;
          }
          if (!selectedDomains.contains(option.subclass!.toLowerCase())) {
            return false;
          }
        } else {
          // Only show abilities matching the hero's selected subclass
          final selectedSubclass = widget.selectedSubclassName;
          if (selectedSubclass == null || selectedSubclass.isEmpty) {
            // No subclass selected, don't show any subclass abilities
            return false;
          }
          // Case-insensitive comparison for subclass matching
          if (option.subclass!.toLowerCase() != selectedSubclass.toLowerCase()) {
            return false;
          }
        }
      } else {
        if (option.subclass != null && option.subclass!.isNotEmpty) {
          return false;
        }
      }
      if (allowance.includePreviousLevels) {
        if (option.level > allowance.level) return false;
      } else {
        if (option.level != 0 && option.level != allowance.level) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.level != b.level) {
          return a.level.compareTo(b.level);
        }
        return a.name.compareTo(b.name);
      });
  }

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
            ChooseAbilitiesWidgetText.noAbilitiesMessage,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      );
    }

    final totalSlots = plan.allowances.fold<int>(
      0,
      (prev, element) => prev + element.pickCount,
    );
    final selectedCount =
        _selections.values.expand((slots) => slots).whereType<String>().length;

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: ChooseAbilitiesWidgetText.expansionTitle,
            subtitle: '${ChooseAbilitiesWidgetText.selectionSubtitlePrefix}$selectedCount${ChooseAbilitiesWidgetText.selectionSubtitleMiddle}$totalSlots${ChooseAbilitiesWidgetText.selectionSubtitleSuffix}',
            icon: Icons.auto_awesome,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan.allowances.map(_buildAllowanceSection).toList(),
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
            title: ChooseAbilitiesWidgetText.expansionTitle,
            subtitle: ChooseAbilitiesWidgetText.sectionSubtitle,
            icon: Icons.auto_awesome,
            accent: _accent,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildAllowanceSection(AbilityAllowance allowance) {
    final options = _optionsForAllowance(allowance);
    final slots = _selections[allowance.id] ?? const [];
    final helper = _buildAllowanceHelperText(allowance);

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
            helper,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (options.isEmpty)
            Text(
              ChooseAbilitiesWidgetText.noAllowanceOptionsMessage,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            )
          else
            ...List.generate(slots.length, (index) {
              final current = slots[index];
              final reservedIds = <String>{
                ...widget.reservedAbilityIds,
                ..._selectedAbilityIds(
                  exceptAllowanceId: allowance.id,
                  exceptSlotIndex: index,
                ),
              };
              final availableOptions = ComponentSelectionGuard.filterAllowed(
                options: options,
                reservedIds: reservedIds,
                idSelector: (option) => option.id,
                currentId: current,
              );
              final selectedOption =
                  current != null ? _abilityById[current] : null;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showAbilityPicker(
                        context: context,
                        allowance: allowance,
                        slotIndex: index,
                        currentValue: current,
                        availableOptions: availableOptions,
                      ),
                      borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText:
                              '${ChooseAbilitiesWidgetText.choiceLabelPrefix}${index + 1}',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: FormTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                            borderSide: const BorderSide(color: _accent),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedOption != null
                                    ? _abilityOptionLabel(selectedOption)
                                    : ChooseAbilitiesWidgetText.unassignedLabel,
                                style: TextStyle(
                                  color: selectedOption != null
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedOption != null) ...[
                      const SizedBox(height: 8),
                      AbilityExpandableItem(
                          component: selectedOption.component),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAbilityPicker({
    required BuildContext context,
    required AbilityAllowance allowance,
    required int slotIndex,
    required String? currentValue,
    required List<AbilityOption> availableOptions,
  }) async {
    String searchQuery = '';

    final result = await showDialog<_PickerSelection>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredOptions = availableOptions.where((option) {
              final query = searchQuery.toLowerCase();
              return option.name.toLowerCase().contains(query) ||
                  (option.subclass?.toLowerCase().contains(query) ?? false) ||
                  (option.resource?.toLowerCase().contains(query) ?? false);
            }).toList();

            return Dialog(
              backgroundColor: NavigationTheme.cardBackgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _accent.withValues(alpha: 0.2),
                            _accent.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: _accent.withValues(alpha: 0.3),
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
                              color: _accent.withValues(alpha: 0.2),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ChooseAbilitiesWidgetText.selectAbilityTitle,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Search field
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: false,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: ChooseAbilitiesWidgetText.searchHint,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          filled: true,
                          fillColor: FormTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _accent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    // Options list
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Unassigned option
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(
                                    dialogContext,
                                    const _PickerSelection(value: null),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: currentValue == null
                                        ? _accent.withValues(alpha: 0.15)
                                        : FormTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: currentValue == null
                                          ? _accent.withValues(alpha: 0.5)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ChooseAbilitiesWidgetText.unassignedLabel,
                                          style: TextStyle(
                                            color: currentValue == null
                                                ? _accent
                                                : Colors.grey.shade400,
                                            fontSize: 14,
                                            fontWeight: currentValue == null
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (currentValue == null)
                                        Icon(
                                          Icons.check_circle,
                                          color: _accent,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Ability options
                          if (filteredOptions.isEmpty && searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  ChooseAbilitiesWidgetText.noMatchesFound,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...filteredOptions.map((option) {
                              final isSelected = option.id == currentValue;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(
                                        dialogContext,
                                        _PickerSelection(
                                          value: option.id,
                                          label: option.name,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _accent.withValues(alpha: 0.15)
                                            : FormTheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? _accent.withValues(alpha: 0.5)
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _abilityOptionLabel(option),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? _accent
                                                        : Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (option.subclass != null &&
                                                    option.subclass!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    option.subclass!,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade400,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: _accent,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    // Cancel button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade800),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          ChooseAbilitiesWidgetText.cancelButton,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
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

    if (result != null) {
      _handleAbilitySelection(allowance, slotIndex, result.value);
    }
  }

  String _abilityOptionLabel(AbilityOption option) {
    final buffer = StringBuffer(option.name);
    if (option.isSignature) {
      buffer.write(ChooseAbilitiesWidgetText.signatureSuffix);
    } else if (option.costAmount != null && option.costAmount! > 0) {
      final resource = option.resource;
      if (resource != null && resource.isNotEmpty) {
        buffer.write(
          '${ChooseAbilitiesWidgetText.resourceCostPrefix}$resource${ChooseAbilitiesWidgetText.resourceCostMiddle}${option.costAmount}${ChooseAbilitiesWidgetText.resourceCostSuffix}',
        );
      } else {
        buffer.write(
          '${ChooseAbilitiesWidgetText.costPrefix}${option.costAmount}${ChooseAbilitiesWidgetText.costSuffix}',
        );
      }
    } else if (option.resource != null && option.resource!.isNotEmpty) {
      buffer.write(
        '${ChooseAbilitiesWidgetText.resourceOnlyPrefix}${option.resource}${ChooseAbilitiesWidgetText.resourceOnlySuffix}',
      );
    }
    if (option.subclass != null && option.subclass!.isNotEmpty) {
      buffer.write(
        '${ChooseAbilitiesWidgetText.subclassSuffixPrefix}${option.subclass}',
      );
    }
    return buffer.toString();
  }

  String _buildAllowanceHelperText(AbilityAllowance allowance) {
    final buffer = StringBuffer();
    buffer.write(
      '${ChooseAbilitiesWidgetText.helperPickPrefix}${allowance.pickCount}${allowance.pickCount == 1 ? ChooseAbilitiesWidgetText.helperPickSingularSuffix : ChooseAbilitiesWidgetText.helperPickPluralSuffix}',
    );
    if (allowance.isSignature) {
      buffer.write(ChooseAbilitiesWidgetText.helperSignatureSuffix);
    } else if (allowance.costAmount != null) {
      buffer.write(
        '${ChooseAbilitiesWidgetText.helperCostPrefix}${allowance.costAmount}',
      );
      if (allowance.resource != null && allowance.resource!.isNotEmpty) {
        buffer.write(
          '${ChooseAbilitiesWidgetText.helperCostResourcePrefix}${allowance.resource}',
        );
      }
      buffer.write(ChooseAbilitiesWidgetText.helperCostSuffix);
    } else {
      buffer.write(ChooseAbilitiesWidgetText.helperDefaultSuffix);
    }

    if (allowance.requiresSubclass) {
      buffer.write(
        _isConduitClass
            ? ChooseAbilitiesWidgetText.helperIncludeDomainAbilities
            : ChooseAbilitiesWidgetText.helperIncludeSubclassAbilities,
      );
    }
    if (allowance.includePreviousLevels) {
      buffer.write(
        ChooseAbilitiesWidgetText.helperIncludePreviousLevels,
      );
    }
    return buffer.toString();
  }

  String _slotKey(String allowanceId, int index) => '$allowanceId#$index';

  String _classSlug(String classId) {
    final normalized = classId.trim().toLowerCase();
    if (normalized.startsWith('class_')) {
      return normalized.substring('class_'.length);
    }
    return normalized;
  }

  bool get _isConduitClass => _classSlug(widget.classData.classId) == 'conduit';

  Set<String> _normalizedDomainNames(Iterable<String> domains) {
    return domains
        .map((domain) => domain.trim().toLowerCase())
        .where((domain) => domain.isNotEmpty)
        .toSet();
  }

  int _resolveAbilityLevel(Component component) {
    final data = component.data;
    final level = CharacteristicUtils.toIntOrNull(data['level']);
    if (level != null && level > 0) {
      return level;
    }

    final levelBand = data['level_band'];
    final levelFromBand = _parseLevel(dynamicValue: levelBand);
    if (levelFromBand != null) {
      return levelFromBand;
    }

    final path = data['ability_source_path'];
    final levelFromPath = _parseLevelFromPath(path);
    if (levelFromPath != null) {
      return levelFromPath;
    }

    return 0;
  }

  int? _parseLevel({dynamic dynamicValue}) {
    if (dynamicValue == null) return null;
    if (dynamicValue is num) {
      final numeric = dynamicValue.toInt();
      return numeric > 0 ? numeric : null;
    }
    final value = dynamicValue.toString().trim();
    if (value.isEmpty) return null;

    final normalized = value.toLowerCase();
    final levelMatch =
        RegExp(r'(?:level|lvl)[\s_:-]*([0-9]{1,2})').firstMatch(normalized);
    if (levelMatch != null) {
      return int.tryParse(levelMatch.group(1)!);
    }

    if (RegExp(r'^[0-9]{1,2}$').hasMatch(value)) {
      return int.tryParse(value);
    }

    return null;
  }

  int? _parseLevelFromPath(dynamic pathValue) {
    if (pathValue == null) return null;
    final path = pathValue.toString().trim();
    if (path.isEmpty) return null;

    final segments = path
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();

    for (final segment in segments) {
      final normalizedSegment = segment.toLowerCase();
      if (normalizedSegment.contains('level') ||
          normalizedSegment.contains('lvl')) {
        final level = _parseLevel(dynamicValue: normalizedSegment);
        if (level != null) {
          return level;
        }
      }
    }

    return null;
  }
}

