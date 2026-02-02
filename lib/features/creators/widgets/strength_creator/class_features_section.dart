import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/subclass_models.dart';
import '../../../../core/services/class_feature_data_service.dart';
import '../../../../core/text/creators/widgets/strength_creator/class_features_section_text.dart';
import '../../../../core/theme/creator_theme.dart';
import 'class_features_widget.dart';

class ClassFeaturesSection extends StatefulWidget {
  const ClassFeaturesSection({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedSubclass,
    this.initialSelections = const {},
    this.onSelectionsChanged,
    this.equipmentIds = const [],
    this.skillGroupSelections = const {},
    this.onSkillGroupSelectionChanged,
    this.reservedSkillIds = const {},
    this.onPendingChoicesChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final SubclassSelectionResult? selectedSubclass;
  final Map<String, Set<String>> initialSelections;
  final ValueChanged<Map<String, Set<String>>>? onSelectionsChanged;
  
  /// Equipment IDs for determining kit (used for Stormwight progression)
  final List<String?> equipmentIds;
  
  /// skill_group skill selections: Map<featureId, Map<grantKey, skillId>>
  final Map<String, Map<String, String>> skillGroupSelections;
  
  /// Callback when a skill_group skill selection changes
  final SkillGroupSelectionChanged? onSkillGroupSelectionChanged;
  
  /// Set of skill IDs that are already selected elsewhere (for duplicate prevention)
  final Set<String> reservedSkillIds;
  
  /// Callback when the number of pending choices changes
  final ValueChanged<int>? onPendingChoicesChanged;

  @override
  State<ClassFeaturesSection> createState() => _ClassFeaturesSectionState();
}

class _ClassFeaturesSectionState extends State<ClassFeaturesSection>
    with AutomaticKeepAliveClientMixin {
  final ClassFeatureDataService _service = ClassFeatureDataService();

  bool _isLoading = true;
  String? _error;
  ClassFeatureDataResult? _data;
  Map<String, Set<String>> _selections = const {};
  int _loadRequestId = 0;
  int _lastPendingChoicesCount = -1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selections = _normalizeSelections(widget.initialSelections);
    _load();
  }

  @override
  void didUpdateWidget(covariant ClassFeaturesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final classChanged =
        oldWidget.classData.classId != widget.classData.classId;
    final levelChanged = oldWidget.selectedLevel != widget.selectedLevel;
    final subclassChanged =
        oldWidget.selectedSubclass != widget.selectedSubclass;
    final initialSelectionsChanged =
        !_mapsEqual(oldWidget.initialSelections, widget.initialSelections);
    final skillGroupSelectionsChanged = 
        oldWidget.skillGroupSelections != widget.skillGroupSelections;

    if (classChanged) {
      _selections = _normalizeSelections(widget.initialSelections);
      _load();
      return;
    }

    if (levelChanged || subclassChanged) {
      _load();
      return;
    }

    if (initialSelectionsChanged) {
      setState(() {
        _selections = _normalizeSelections(widget.initialSelections);
      });
      _notifyPendingChoicesIfChanged();
    }
    
    if (skillGroupSelectionsChanged) {
      _notifyPendingChoicesIfChanged();
    }
  }
  
  void _notifyPendingChoicesIfChanged() {
    if (widget.onPendingChoicesChanged == null) return;
    final data = _data;
    if (data == null) return;
    
    // Compute active slugs for filtering
    final activeSubclassSlugs =
        ClassFeatureDataService.activeSubclassSlugs(widget.selectedSubclass);
    final domainSlugs =
        ClassFeatureDataService.selectedDomainSlugs(widget.selectedSubclass);
    final deitySlugs =
        ClassFeatureDataService.selectedDeitySlugs(widget.selectedSubclass);
    
    final count = ClassFeatureDataService.countPendingChoices(
      featureDetailsById: data.featureDetailsById,
      featureIds: data.features.map((f) => f.id),
      selectedOptions: _selections,
      skillGroupSelections: widget.skillGroupSelections,
      activeSubclassSlugs: activeSubclassSlugs,
      selectedDomainSlugs: domainSlugs,
      selectedDeitySlugs: deitySlugs,
    );
    
    if (count != _lastPendingChoicesCount) {
      _lastPendingChoicesCount = count;
      widget.onPendingChoicesChanged!(count);
    }
  }

  void _load() async {
    final requestId = ++_loadRequestId;
    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });

    final activeSubclassSlugs =
        ClassFeatureDataService.activeSubclassSlugs(widget.selectedSubclass);

    try {
      final result = await _service.loadFeatures(
        classData: widget.classData,
        level: widget.selectedLevel,
        activeSubclassSlugs: activeSubclassSlugs,
      );
      if (!mounted || requestId != _loadRequestId) return;

      final allowedOptionKeys = <String, Set<String>>{};
      result.featureDetailsById.forEach((featureId, details) {
        allowedOptionKeys[featureId] =
            ClassFeatureDataService.extractOptionKeys(details);
      });

      final baseSelections = Map<String, Set<String>>.from(_selections);
      if (baseSelections.isEmpty) {
        baseSelections.addAll(_normalizeSelections(widget.initialSelections));
      }

      final cleanedSelections = <String, Set<String>>{};
      baseSelections.forEach((featureId, values) {
        final allowed = allowedOptionKeys[featureId] ?? const <String>{};
        final filtered = values.where(allowed.contains).toSet();
        if (filtered.isNotEmpty) {
          cleanedSelections[featureId] = filtered;
        }
      });

      final workingSelections =
          Map<String, Set<String>>.from(cleanedSelections);
      final domainSlugs =
          ClassFeatureDataService.selectedDomainSlugs(widget.selectedSubclass);
      final deitySlugs =
          ClassFeatureDataService.selectedDeitySlugs(widget.selectedSubclass);
      ClassFeatureDataService.applyDomainSelectionToFeatures(
        selections: workingSelections,
        featureDetailsById: result.featureDetailsById,
        domainLinkedFeatureIds: result.domainLinkedFeatureIds,
        domainSlugs: domainSlugs,
      );
      ClassFeatureDataService.applySubclassSelectionToFeatures(
        selections: workingSelections,
        features: result.features,
        featureDetailsById: result.featureDetailsById,
        subclassSlugs: activeSubclassSlugs,
      );
      ClassFeatureDataService.applyDeitySelectionToFeatures(
        selections: workingSelections,
        featureDetailsById: result.featureDetailsById,
        deityLinkedFeatureIds: result.deityLinkedFeatureIds,
        deitySlugs: deitySlugs,
      );

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _isLoading = false;
        _error = null;
        _data = result;
        _selections = workingSelections;
      });
      _notifySelectionsChanged();
      _notifyPendingChoicesIfChanged();
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _error = '${ClassFeaturesSectionText.loadErrorPrefix}$e';
        _data = null;
        _selections = const {};
      });
      _notifySelectionsChanged();
    }
  }

  Map<String, Set<String>> _normalizeSelections(
    Map<String, Set<String>> selections,
  ) {
    final normalized = <String, Set<String>>{};
    selections.forEach((featureId, values) {
      final trimmedId = featureId.trim();
      if (trimmedId.isEmpty) return;
      final valueSet = values;
      final cleanedValues = valueSet
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      if (cleanedValues.isNotEmpty) {
        normalized[trimmedId] = cleanedValues;
      }
    });
    return normalized;
  }

  void _handleSelectionChanged(String featureId, Set<String> selections) {
    final trimmedId = featureId.trim();
    if (trimmedId.isEmpty) return;

    final updated = Map<String, Set<String>>.from(_selections);
    final selectionSet = selections;
    final cleanedSelections = selectionSet
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (cleanedSelections.isEmpty) {
      updated.remove(trimmedId);
    } else {
      updated[trimmedId] = cleanedSelections;
    }

    final data = _data;
    if (data != null) {
      final domainSlugs =
          ClassFeatureDataService.selectedDomainSlugs(widget.selectedSubclass);
      final subclassSlugs =
          ClassFeatureDataService.activeSubclassSlugs(widget.selectedSubclass);
      final deitySlugs =
          ClassFeatureDataService.selectedDeitySlugs(widget.selectedSubclass);
      ClassFeatureDataService.applyDomainSelectionToFeatures(
        selections: updated,
        featureDetailsById: data.featureDetailsById,
        domainLinkedFeatureIds: data.domainLinkedFeatureIds,
        domainSlugs: domainSlugs,
      );
      ClassFeatureDataService.applySubclassSelectionToFeatures(
        selections: updated,
        features: data.features,
        featureDetailsById: data.featureDetailsById,
        subclassSlugs: subclassSlugs,
      );
      ClassFeatureDataService.applyDeitySelectionToFeatures(
        selections: updated,
        featureDetailsById: data.featureDetailsById,
        deityLinkedFeatureIds: data.deityLinkedFeatureIds,
        deitySlugs: deitySlugs,
      );
    }

    setState(() {
      _selections = updated;
    });
    _notifySelectionsChanged();
    _notifyPendingChoicesIfChanged();
  }

  void _notifySelectionsChanged() {
    if (widget.onSelectionsChanged == null) return;
    widget.onSelectionsChanged!(
      Map<String, Set<String>>.unmodifiable(_selections),
    );
  }

  bool _mapsEqual(
    Map<String, Set<String>> a,
    Map<String, Set<String>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) {
        if (!b.containsKey(entry.key)) {
          return false;
        }
        if (entry.value.isNotEmpty) {
          return false;
        }
        continue;
      }
      if (!setEquals(entry.value, other)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return Padding(
        padding: CreatorTheme.sectionMargin,
        child: Container(
          decoration: CreatorTheme.sectionDecoration(CreatorTheme.strengthAccent),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: CreatorTheme.strengthAccent,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                ClassFeaturesSectionText.loadingMessage,
                style: TextStyle(color: CreatorTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: CreatorTheme.sectionMargin,
        child: Container(
          decoration: CreatorTheme.sectionDecoration(CreatorTheme.errorColor),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CreatorTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: CreatorTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(color: CreatorTheme.errorColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null || data.features.isEmpty) {
      return const SizedBox.shrink();
    }

    final domainSlugs =
        ClassFeatureDataService.selectedDomainSlugs(widget.selectedSubclass);
    final subclassSlugs =
        ClassFeatureDataService.activeSubclassSlugs(widget.selectedSubclass);
    final subclassLabel =
        ClassFeatureDataService.subclassLabel(widget.selectedSubclass);
    final deitySlugs =
        ClassFeatureDataService.selectedDeitySlugs(widget.selectedSubclass);

    // Extract grant_type metadata from class levels
    final grantTypeMap = _buildGrantTypeMap();

    // Create a key that changes when subclass/domain selection changes
    // This prevents scroll position restoration crashes when content changes significantly
    final widgetKey = ValueKey(
      '${widget.classData.classId}_'
      '${widget.selectedLevel}_'
      '${subclassSlugs.join(",")}_'
      '${domainSlugs.join(",")}_'
      '${deitySlugs.join(",")}',
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: ClassFeaturesWidget(
        key: widgetKey,
        level: widget.selectedLevel,
        features: data.features,
        featureDetailsById: data.featureDetailsById,
        selectedOptions: _selections,
        onSelectionChanged: _handleSelectionChanged,
        domainLinkedFeatureIds: data.domainLinkedFeatureIds,
        selectedDomainSlugs: domainSlugs,
        deityLinkedFeatureIds: data.deityLinkedFeatureIds,
        selectedDeitySlugs: deitySlugs,
        abilityDetailsById: data.abilityDetailsById,
        abilityIdByName: data.abilityIdByName,
        activeSubclassSlugs: subclassSlugs,
        subclassLabel: subclassLabel,
        subclassSelection: widget.selectedSubclass,
        grantTypeByFeatureName: grantTypeMap,
        className: widget.classData.name,
        equipmentIds: widget.equipmentIds,
        skillGroupSelections: widget.skillGroupSelections,
        onSkillGroupSelectionChanged: widget.onSkillGroupSelectionChanged,
        reservedSkillIds: widget.reservedSkillIds,
      ),
    );
  }

  Map<String, String> _buildGrantTypeMap() {
    final map = <String, String>{};
    for (final levelData in widget.classData.levels) {
      if (levelData.level > widget.selectedLevel) continue;
      for (final feature in levelData.features) {
        if (feature.grantType != null && feature.grantType!.isNotEmpty) {
          map[feature.name.toLowerCase().trim()] = feature.grantType!;
        }
      }
    }
    return map;
  }
}

