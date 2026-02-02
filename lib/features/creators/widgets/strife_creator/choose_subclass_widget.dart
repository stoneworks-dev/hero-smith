import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/subclass_models.dart';
import '../../../../core/services/subclass_data_service.dart';
import '../../../../core/services/subclass_service.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_subclass_widget_text.dart';

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
  final accentColor = accent ?? CreatorTheme.classAccent;
  
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
                        hintText: ChooseSubclassWidgetText.searchHint,
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
                                  ChooseSubclassWidgetText.noMatchesFound,
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
                      child: const Text(ChooseSubclassWidgetText.cancelLabel),
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

typedef SubclassSelectionChanged = void Function(
    SubclassSelectionResult result);

class ChooseSubclassWidget extends StatefulWidget {
  const ChooseSubclassWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedSubclass,
    this.onSelectionChanged,
    this.reservedSkillIds = const {},
    this.skillNameToIdLookup = const {},
    this.savedSubclassSkillId,
  });

  final ClassData classData;
  final int selectedLevel;
  final SubclassSelectionResult? selectedSubclass;
  final SubclassSelectionChanged? onSelectionChanged;
  /// Skill IDs that are already taken (from story page, DB, etc.)
  final Set<String> reservedSkillIds;
  /// Map of skill name (lowercase) to skill ID for resolving granted skill names
  final Map<String, String> skillNameToIdLookup;
  /// The skill ID currently saved in DB as granted by this subclass (to avoid self-flagging)
  final String? savedSubclassSkillId;

  @override
  State<ChooseSubclassWidget> createState() => _ChooseSubclassWidgetState();
}

class _ChooseSubclassWidgetState extends State<ChooseSubclassWidget> {
  static const _accent = CreatorTheme.classAccent;
  
  final SubclassService _planService = const SubclassService();
  final SubclassDataService _dataService = SubclassDataService();
  final ListEquality<String> _listEquality = const ListEquality<String>();

  SubclassPlan? _plan;
  SubclassFeatureData? _featureData;
  Map<String, SubclassOption> _optionsByKey = const {};
  List<DeityOption> _deities = const [];
  Set<String> _allDomains = const {};

  bool _isLoading = true;
  String? _error;

  String? _selectedSubclassKey;
  String? _selectedSubclassName;
  String? _selectedDeityId;
  List<String> _selectedDomains = const [];

  SubclassSelectionResult? _lastNotified;
  int _callbackVersion = 0;
  int _loadRequestId = 0;

  /// Checks if a skill name corresponds to a reserved skill ID
  /// Excludes the skill that was previously saved as granted by this subclass
  bool _isSkillReserved(String? skillName) {
    if (skillName == null || skillName.isEmpty) return false;
    final normalized = skillName.trim().toLowerCase();
    final skillId = widget.skillNameToIdLookup[normalized] ?? 'skill_$normalized';
    
    // If this skill was saved as granted by the subclass itself, don't flag it
    if (widget.savedSubclassSkillId != null && 
        widget.savedSubclassSkillId == skillId) {
      return false;
    }
    
    return widget.reservedSkillIds.contains(skillId);
  }

  @override
  void initState() {
    super.initState();
    _loadData(initialSelection: widget.selectedSubclass);
  }

  @override
  void didUpdateWidget(covariant ChooseSubclassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final classChanged =
        oldWidget.classData.classId != widget.classData.classId;
    final levelChanged = oldWidget.selectedLevel != widget.selectedLevel;
    if (classChanged || levelChanged) {
      _loadData(initialSelection: widget.selectedSubclass);
    } else if (oldWidget.selectedSubclass != widget.selectedSubclass) {
      _applyExternalSelection(widget.selectedSubclass);
    }
  }

  Future<void> _loadData({SubclassSelectionResult? initialSelection}) async {
    final requestId = ++_loadRequestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plan = _planService.buildPlan(
        classData: widget.classData,
        selectedLevel: widget.selectedLevel,
      );

      SubclassFeatureData? featureData;
      if (plan.hasSubclassChoice && plan.subclassFeatureName != null) {
        featureData = await _dataService.loadSubclassFeatureData(
          classSlug: plan.classSlug,
          featureName: plan.subclassFeatureName!,
        );
      }

      List<DeityOption> deities = const [];
      if (plan.requiresDeity || plan.requiresDomains) {
        deities = await _dataService.loadDeities();
      }

      Set<String> allDomains = const {};
      if (plan.requiresDomains) {
        if (plan.deityPickCount == 0) {
          allDomains = await _dataService.loadAllDomains();
        } else {
          final domainSet = <String>{};
          for (final deity in deities) {
            domainSet.addAll(deity.domains);
          }
          allDomains = domainSet;
        }
      }

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _plan = plan;
        _featureData = featureData;
        _optionsByKey = {
          for (final option in featureData?.options ?? const <SubclassOption>[])
            option.key: option,
        };
        _deities = deities;
        _allDomains = allDomains;
        _selectedSubclassKey = null;
        _selectedSubclassName = null;
        _selectedDeityId = null;
        _selectedDomains = const [];
        _isLoading = false;
      });

      _applyExternalSelection(initialSelection);
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _error = '${ChooseSubclassWidgetText.loadErrorPrefix}$e';
        _isLoading = false;
      });
    }
  }

  void _applyExternalSelection(SubclassSelectionResult? selection) {
    if (_isLoading) return;
    if (_plan == null) return;

    String? subclassKey;
    String? subclassName;
    String? deityId;
    List<String> domains = _selectedDomains;

    if (selection != null) {
      subclassKey = selection.subclassKey;
      subclassName = selection.subclassName;
      deityId = selection.deityId;
      domains = selection.domainNames;
    }

    if (subclassKey != null && !_optionsByKey.containsKey(subclassKey)) {
      subclassKey = null;
      subclassName = null;
    }

    if (!_plan!.requiresDeity) {
      deityId = null;
    } else if (deityId != null &&
        !_deities.any((deity) => deity.id == deityId)) {
      deityId = null;
    }

    if (!_plan!.requiresDomains) {
      domains = const [];
    }

    if (!_listEquality.equals(_selectedDomains, domains) ||
        _selectedSubclassKey != subclassKey ||
        _selectedSubclassName != subclassName ||
        _selectedDeityId != deityId) {
      setState(() {
        _selectedSubclassKey = subclassKey;
        _selectedSubclassName = subclassName;
        _selectedDeityId = deityId;
        _selectedDomains = List<String>.from(domains);
      });
      _ensureSubclassFromDomains();
      _notifySelectionChanged();
    }
  }

  void _handleSubclassChanged(String? key) {
    if (key == _selectedSubclassKey) return;
    final option = key == null ? null : _optionsByKey[key];
    setState(() {
      _selectedSubclassKey = key;
      _selectedSubclassName = option?.name;
    });
    _notifySelectionChanged();
  }

  void _handleDeityChanged(String? id) {
    if (id == _selectedDeityId) return;
    setState(() {
      _selectedDeityId = id;
      _selectedDomains = const [];
    });
    _ensureSubclassFromDomains();
    _notifySelectionChanged();
  }

  void _toggleDomain(String domain, bool selected) {
    final requiredCount = _plan?.domainPickCount ?? 0;
    final current = List<String>.from(_selectedDomains);

    if (selected) {
      if (!current.contains(domain)) {
        if (requiredCount > 0 && current.length >= requiredCount) {
          return;
        }
        current.add(domain);
      }
    } else {
      current.remove(domain);
    }

    if (!_listEquality.equals(_selectedDomains, current)) {
      setState(() {
        _selectedDomains = current;
      });
      _ensureSubclassFromDomains();
      _notifySelectionChanged();
    }
  }

  void _ensureSubclassFromDomains() {
    final plan = _plan;
    if (plan == null || !plan.combineDomainsAsSubclass) {
      return;
    }

    final requiredCount = plan.domainPickCount;
    String? key;
    String? name;

    if (_selectedDomains.isNotEmpty &&
        (requiredCount == 0 || _selectedDomains.length >= requiredCount)) {
      final sorted = _selectedDomains.toList()..sort((a, b) => a.compareTo(b));
      key = sorted.map((e) => e.toLowerCase().replaceAll(' ', '_')).join('_');
      name = sorted.join(' + ');
    }

    if (_selectedSubclassKey != key || _selectedSubclassName != name) {
      setState(() {
        _selectedSubclassKey = key;
        _selectedSubclassName = name;
      });
    }
  }

  void _notifySelectionChanged() {
    if (widget.onSelectionChanged == null) return;
    final plan = _plan;
    if (plan == null) return;

    final deity = _selectedDeityId == null
        ? null
        : _deities.firstWhere(
            (entry) => entry.id == _selectedDeityId,
          orElse: () => DeityOption(
            id: _selectedDeityId!,
            name: _selectedDeityId!,
            category: ChooseSubclassWidgetText.deityCategoryFallback,
            domains: const [],
          ),
        );

    // Get the skill from the selected subclass option
    final selectedOption = _selectedSubclassKey == null
        ? null
        : _optionsByKey[_selectedSubclassKey];

    final result = SubclassSelectionResult(
      subclassKey: _selectedSubclassKey,
      subclassName: _selectedSubclassName,
      skill: selectedOption?.skill,
      skillGroup: selectedOption?.skillGroup,
      deityId: deity?.id,
      deityName: deity?.name,
      domainNames: List<String>.from(_selectedDomains),
    );

    if (result == _lastNotified) {
      return;
    }

    _lastNotified = result;
    final version = ++_callbackVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _callbackVersion) return;
      widget.onSelectionChanged?.call(result);
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
    if (plan == null) {
      return const SizedBox.shrink();
    }

    if (!plan.hasSubclassChoice &&
        !plan.requiresDeity &&
        !plan.requiresDomains) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    if (plan.hasSubclassChoice && !plan.combineDomainsAsSubclass) {
      children.addAll(_buildSubclassPickerSection());
      children.add(const SizedBox(height: 16));
    } else if (plan.combineDomainsAsSubclass && plan.domainPickCount > 0) {
      children.add(
        Text(
          ChooseSubclassWidgetText.domainsDetermineSubclass,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    if (plan.requiresDeity) {
      children.addAll(_buildDeityPickerSection());
      children.add(const SizedBox(height: 16));
    }

    if (plan.requiresDomains) {
      children.addAll(_buildDomainSection());
    }

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: ChooseSubclassWidgetText.sectionTitle,
            subtitle: ChooseSubclassWidgetText.sectionSubtitle,
            icon: Icons.category,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
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
            title: ChooseSubclassWidgetText.sectionTitle,
            subtitle: ChooseSubclassWidgetText.sectionSubtitle,
            icon: Icons.category,
            accent: _accent,
          ),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildSubclassPickerSection() {
    final featureData = _featureData;
    final options = featureData?.options ?? const <SubclassOption>[];

    final selectedOption = _selectedSubclassKey == null
        ? null
        : _optionsByKey[_selectedSubclassKey!];

    // Only use the selected key if it exists in the options
    final validatedValue = _selectedSubclassKey != null && 
                           _optionsByKey.containsKey(_selectedSubclassKey!)
        ? _selectedSubclassKey
        : null;

    Future<void> openSearch() async {
      final searchOptions = <_SearchOption<String?>>[
        const _SearchOption<String?>(
          label: ChooseSubclassWidgetText.subclassPlaceholderOption,
          value: null,
        ),
        ...options.map(
          (option) => _SearchOption<String?>(
            label: option.name,
            value: option.key,
            subtitle: option.description,
          ),
        ),
      ];

      final result = await _showSearchablePicker<String?>(
        context: context,
        title: ChooseSubclassWidgetText.subclassPickerTitle,
        options: searchOptions,
        selected: validatedValue,
      );

      if (result == null) return;
      _handleSubclassChanged(result.value);
    }

    return [
      InkWell(
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
                      ChooseSubclassWidgetText.subclassLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedOption != null
                          ? selectedOption.name
                          : ChooseSubclassWidgetText.subclassPlaceholderDisplay,
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
      if (selectedOption != null) ...[
        const SizedBox(height: 12),
        _buildSubclassDetails(selectedOption),
      ] else if (featureData?.featureDescription != null &&
          featureData!.featureDescription!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          featureData.featureDescription!,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    ];
  }

  Widget _buildSubclassDetails(SubclassOption option) {
    final skillInfo = option.skill;
    final skillGroup = option.skillGroup;
    final ability = option.abilityName;
    final skillIsReserved = _isSkillReserved(skillInfo);

    final chips = <Widget>[];
    if (skillInfo != null && skillInfo.isNotEmpty) {
      chips.add(_buildInfoChip(Icons.psychology_outlined, skillInfo));
    }
    if (skillGroup != null && skillGroup.isNotEmpty) {
      chips.add(_buildInfoChip(Icons.folder_shared_outlined, skillGroup));
    }
    if (option.domain != null && option.domain!.isNotEmpty) {
      chips.add(_buildInfoChip(Icons.public_outlined, option.domain!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          option.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        if (option.description != null && option.description!.isNotEmpty)
          Text(
            option.description!,
            style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
          ),
        if (ability != null && ability.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${ChooseSubclassWidgetText.grantsAbilityPrefix}$ability',
            style: TextStyle(color: _accent, fontSize: 13),
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
        if (skillIsReserved) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, 
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${ChooseSubclassWidgetText.reservedSkillWarningPrefix}$skillInfo${ChooseSubclassWidgetText.reservedSkillWarningSuffix}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDeityPickerSection() {
    Future<void> openSearch() async {
      final searchOptions = <_SearchOption<String?>>[
        const _SearchOption<String?>(
          label: ChooseSubclassWidgetText.deityPlaceholderOption,
          value: null,
        ),
        ..._deities.map(
          (deity) => _SearchOption<String?>(
            label: deity.name,
            value: deity.id,
            subtitle: deity.category,
          ),
        ),
      ];

      final result = await _showSearchablePicker<String?>(
        context: context,
        title: ChooseSubclassWidgetText.deityPickerTitle,
        options: searchOptions,
        selected: _selectedDeityId,
      );

      if (result == null) return;
      _handleDeityChanged(result.value);
    }

    final selectedDeity = _selectedDeityId != null
        ? _deities.firstWhere(
            (deity) => deity.id == _selectedDeityId,
            orElse: () => DeityOption(
              id: _selectedDeityId!,
              name: ChooseSubclassWidgetText.deityUnknownName,
              category: '',
              domains: const [],
            ),
          )
        : null;

    return [
      InkWell(
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
                      ChooseSubclassWidgetText.deityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDeity != null
                          ? '${selectedDeity.name}${ChooseSubclassWidgetText.deityDisplayPrefix}${selectedDeity.category}${ChooseSubclassWidgetText.deityDisplaySuffix}'
                          : ChooseSubclassWidgetText.deityPlaceholderDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDeity != null
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
    ];
  }

  List<Widget> _buildDomainSection() {
    final plan = _plan;
    if (plan == null) return const [];

    Iterable<String> availableDomains = _allDomains;
    if (plan.deityPickCount > 0 && _selectedDeityId != null) {
      final deity = _deities.firstWhere(
        (element) => element.id == _selectedDeityId,
        orElse: () => DeityOption(
          id: _selectedDeityId!,
          name: _selectedDeityId!,
          category: ChooseSubclassWidgetText.deityCategoryFallback,
          domains: const [],
        ),
      );
      availableDomains = deity.domains;
    }

    final required = plan.domainPickCount;
    final remaining = required > 0 ? required - _selectedDomains.length : 0;

    final chips = availableDomains.toList()..sort((a, b) => a.compareTo(b));

    return [
      Text(
        required > 0
            ? '${ChooseSubclassWidgetText.domainHeaderRequiredPrefix}$required${required == 1 ? ChooseSubclassWidgetText.domainHeaderRequiredSingularSuffix : ChooseSubclassWidgetText.domainHeaderRequiredPluralSuffix}'
            : ChooseSubclassWidgetText.domainHeaderNoRequired,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((domain) {
          final isSelected = _selectedDomains.contains(domain);
          final canSelectMore = !isSelected &&
              required > 0 &&
              _selectedDomains.length >= required;
          return FilterChip(
            label: Text(
              domain,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
              ),
            ),
            selected: isSelected,
            selectedColor: _accent.withValues(alpha: 0.3),
            backgroundColor: FormTheme.surface,
            checkmarkColor: _accent,
            side: BorderSide(
              color: isSelected ? _accent : Colors.grey.shade700,
            ),
            onSelected:
                canSelectMore ? null : (value) => _toggleDomain(domain, value),
          );
        }).toList(),
      ),
      if (remaining > 0) ...[
        const SizedBox(height: 8),
        Text(
          '$remaining${ChooseSubclassWidgetText.remainingPicksPrefix}${remaining == 1 ? ChooseSubclassWidgetText.remainingPicksSingularSuffix : ChooseSubclassWidgetText.remainingPicksPluralSuffix}',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    ];
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}

