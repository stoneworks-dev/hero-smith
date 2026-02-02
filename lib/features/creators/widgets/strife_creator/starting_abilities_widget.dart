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
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/starting_abilities_widget_text.dart';
import '../../../../core/utils/selection_guard.dart';
import '../../../../widgets/abilities/ability_expandable_item.dart';

typedef AbilitySelectionChanged = void Function(
    StartingAbilitySelectionResult result);

class StartingAbilitiesWidget extends StatefulWidget {
  const StartingAbilitiesWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedAbilities = const <String, String?>{},
    this.reservedAbilityIds = const <String>{},
    this.onSelectionChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final Map<String, String?> selectedAbilities;
  final Set<String> reservedAbilityIds;
  final AbilitySelectionChanged? onSelectionChanged;

  @override
  State<StartingAbilitiesWidget> createState() =>
      _StartingAbilitiesWidgetState();
}

class _StartingAbilitiesWidgetState extends State<StartingAbilitiesWidget> {
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
    final reservedChanged = !_setEquality.equals(
      oldWidget.reservedAbilityIds,
      widget.reservedAbilityIds,
    );
    if (classChanged) {
      _loadAbilities();
      return;
    }
    if (levelChanged && !_isLoading && _error == null) {
      _rebuildPlan(
        preserveSelections: true,
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
        _error = '${StartingAbilitiesWidgetText.loadErrorPrefix}$e';
      });
    }
  }

  AbilityOption _mapComponentToOption(Component component) {
    try {
      final data = component.data;
      final costsRaw = data['costs'];
      
      // Check if this is a signature ability
      // New format: costs == "signature" (string)
      // Old format: costs['signature'] == true (boolean in map)
      final bool isSignature;
      if (costsRaw is String) {
        isSignature = costsRaw.toLowerCase() == 'signature';
      } else if (costsRaw is Map) {
        isSignature = costsRaw['signature'] == true;
      } else {
        isSignature = false;
      }
      
      // Extract cost amount and resource (only applicable for non-signature abilities)
      final int? costAmount;
      final String? resource;
      if (costsRaw is Map) {
        final amountRaw = costsRaw['amount'];
        costAmount = amountRaw is num ? amountRaw.toInt() : null;
        resource = costsRaw['resource']?.toString();
      } else {
        costAmount = null;
        resource = null;
      }
      final level = data['level'] is num
          ? (data['level'] as num).toInt()
          : CharacteristicUtils.toIntOrNull(data['level']) ?? 0;
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

  List<AbilityOption> _optionsForAllowance(AbilityAllowance allowance) {
    return _abilityOptions.where((option) {
      if (allowance.isSignature && !option.isSignature) return false;
      if (!allowance.isSignature && option.isSignature) return false;
      if (allowance.costAmount != null &&
          option.costAmount != allowance.costAmount) {
        return false;
      }
      if (allowance.requiresSubclass) {
        if (option.subclass == null || option.subclass!.isEmpty) {
          return false;
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
            StartingAbilitiesWidgetText.noAbilitiesMessage,
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
            title: StartingAbilitiesWidgetText.expansionTitle,
            subtitle: '${StartingAbilitiesWidgetText.selectionSubtitlePrefix}$selectedCount${StartingAbilitiesWidgetText.selectionSubtitleMiddle}$totalSlots${StartingAbilitiesWidgetText.selectionSubtitleSuffix}',
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
            title: StartingAbilitiesWidgetText.expansionTitle,
            subtitle: StartingAbilitiesWidgetText.sectionSubtitle,
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
              StartingAbilitiesWidgetText.noAllowanceOptionsMessage,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            )
          else
            ...List.generate(slots.length, (index) {
              final current = slots[index];
              final selectedOption =
                  current != null ? _abilityById[current] : null;
              final availableOptions = ComponentSelectionGuard.filterAllowed(
                options: options,
                reservedIds: widget.reservedAbilityIds,
                idSelector: (option) => option.id,
                currentId: current,
              );
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String?>(
                      value: current,
                      dropdownColor: FormTheme.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText:
                            '${StartingAbilitiesWidgetText.choiceLabelPrefix}${index + 1}',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child:
                              Text(StartingAbilitiesWidgetText.unassignedLabel),
                        ),
                        ...availableOptions.map(
                          (option) => DropdownMenuItem<String?>(
                            value: option.id,
                            child: Text(_abilityOptionLabel(option)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          _handleAbilitySelection(allowance, index, value),
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

  String _abilityOptionLabel(AbilityOption option) {
    final buffer = StringBuffer(option.name);
    if (option.costAmount != null) {
      buffer.write(
        '${StartingAbilitiesWidgetText.costPrefix}${option.costAmount}',
      );
      if (option.resource != null && option.resource!.isNotEmpty) {
        buffer.write(
          '${StartingAbilitiesWidgetText.costResourcePrefix}${option.resource}',
        );
      }
      buffer.write(StartingAbilitiesWidgetText.costSuffix);
    } else if (option.isSignature) {
      buffer.write(StartingAbilitiesWidgetText.signatureSuffix);
    }
    if (option.subclass != null && option.subclass!.isNotEmpty) {
      buffer.write(
        '${StartingAbilitiesWidgetText.subclassSuffixPrefix}${option.subclass}',
      );
    }
    return buffer.toString();
  }

  String _buildAllowanceHelperText(AbilityAllowance allowance) {
    final buffer = StringBuffer();
    buffer.write(
      '${StartingAbilitiesWidgetText.helperPickPrefix}${allowance.pickCount}${allowance.pickCount == 1 ? StartingAbilitiesWidgetText.helperPickSingularSuffix : StartingAbilitiesWidgetText.helperPickPluralSuffix}',
    );
    if (allowance.isSignature) {
      buffer.write(StartingAbilitiesWidgetText.helperSignatureSuffix);
    } else if (allowance.costAmount != null) {
      buffer.write(
        '${StartingAbilitiesWidgetText.helperCostPrefix}${allowance.costAmount}',
      );
      if (allowance.resource != null && allowance.resource!.isNotEmpty) {
        buffer.write(
          '${StartingAbilitiesWidgetText.helperCostResourcePrefix}${allowance.resource}',
        );
      }
      buffer.write(StartingAbilitiesWidgetText.helperCostSuffix);
    } else {
      buffer.write(StartingAbilitiesWidgetText.helperDefaultSuffix);
    }

    if (allowance.requiresSubclass) {
      buffer.write(StartingAbilitiesWidgetText.helperIncludeSubclassAbilities);
    }
    if (allowance.includePreviousLevels) {
      buffer.write(StartingAbilitiesWidgetText.helperIncludePreviousLevels);
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
}

