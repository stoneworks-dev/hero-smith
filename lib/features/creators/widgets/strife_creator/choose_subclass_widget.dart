import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/models/subclass_models.dart';
import '../../../../core/services/subclass_data_service.dart';
import '../../../../core/services/subclass_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icon_data.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_subclass_widget_text.dart';
import '../../../../core/storage/hero_storage_contract.dart';
import '../../../hero_builder/domain/hero_claim.dart';
import '../../../hero_builder/domain/hero_conflict_index.dart';
import '../../../hero_builder/domain/hero_draft_claims.dart';

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
                          child:
                              Icon(Icons.search, color: accentColor, size: 20),
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
                          icon:
                              Icon(Icons.close, color: FormTheme.textSecondary),
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
                      style: TextStyle(color: FormTheme.textBright),
                      decoration: InputDecoration(
                        hintText: ChooseSubclassWidgetText.searchHint,
                        hintStyle: TextStyle(color: FormTheme.textMuted),
                        prefixIcon:
                            Icon(Icons.search, color: FormTheme.textMuted),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: FormTheme.border),
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
                                  color: FormTheme.borderLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ChooseSubclassWidgetText.noMatchesFound,
                                  style: TextStyle(
                                    color: FormTheme.textMuted,
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
                                      ? FormTheme.surfaceMuted
                                      : isSelected
                                          ? accentColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accentColor.withValues(
                                              alpha: 0.4),
                                        )
                                      : isNoneOption
                                          ? Border.all(
                                              color: FormTheme.border,
                                            )
                                          : null,
                                ),
                                child: ListTile(
                                  leading: isNoneOption
                                      ? Icon(Icons.remove_circle_outline,
                                          size: 20, color: FormTheme.textMuted)
                                      : null,
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isNoneOption
                                          ? FormTheme.textSecondary
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
                                            color: FormTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: accentColor, size: 22)
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
                        top: BorderSide(color: FormTheme.borderDim),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: FormTheme.textSecondary,
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
    this.skillConflictIndex = HeroConflictIndex.empty,
    this.skillNameToIdLookup = const {},
  });

  final ClassData classData;
  final int selectedLevel;
  final SubclassSelectionResult? selectedSubclass;
  final SubclassSelectionChanged? onSelectionChanged;

  final HeroConflictIndex skillConflictIndex;

  /// Map of skill name (lowercase) to skill ID for resolving granted skill names
  final Map<String, String> skillNameToIdLookup;

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

  bool _isSkillReserved(String? skillName) {
    if (skillName == null || skillName.isEmpty) return false;
    final normalized = skillName.trim().toLowerCase();
    final skillId =
        widget.skillNameToIdLookup[normalized] ?? 'skill_$normalized';

    return widget.skillConflictIndex.isClaimed(
      HeroEntryKey(
        entryType: HeroEntryTypes.skill,
        canonicalEntryId: skillId,
      ),
      ignoredDraftSlotKey: HeroDraftClaims.subclassSkillSlot,
    );
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
          style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
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
            appIcon: StoryIcons.subclass,
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
            appIcon: StoryIcons.subclass,
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
        ...options.where((option) => !option.isRetired).map(
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
            border: Border.all(color: FormTheme.border),
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
                        color: FormTheme.textSecondary,
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
                            ? FormTheme.textBright
                            : FormTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.search, color: FormTheme.textSecondary),
            ],
          ),
        ),
      ),
      if (selectedOption != null) ...[
        const SizedBox(height: 12),
        if (selectedOption.isRetired) ...[
          _buildRetiredSelectionWarning(selectedOption.name),
          const SizedBox(height: 12),
        ],
        _buildSubclassDetails(selectedOption),
      ] else if (featureData?.featureDescription != null &&
          featureData!.featureDescription!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          featureData.featureDescription!,
          style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
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
      chips.add(_buildInfoChip(
        StoryIcons.skills,
        skillInfo,
        isConflict: skillIsReserved,
      ));
    }
    if (skillGroup != null && skillGroup.isNotEmpty) {
      chips.add(_buildInfoChip(StoryIcons.skills, skillGroup));
    }
    if (option.domain != null && option.domain!.isNotEmpty) {
      chips.add(_buildInfoChip(FeatureIcons.domain, option.domain!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          option.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FormTheme.textBright,
          ),
        ),
        const SizedBox(height: 4),
        if (option.description != null && option.description!.isNotEmpty)
          Text(
            option.description!,
            style: TextStyle(color: FormTheme.textSecondary, fontSize: 14),
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
        ..._deities.where((deity) => !deity.isRetired).map(
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
            border: Border.all(color: FormTheme.border),
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
                        color: FormTheme.textSecondary,
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
                            ? FormTheme.textBright
                            : FormTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.search, color: FormTheme.textSecondary),
            ],
          ),
        ),
      ),
      if (selectedDeity?.isRetired == true) ...[
        const SizedBox(height: 12),
        _buildRetiredSelectionWarning(selectedDeity!.name),
      ],
    ];
  }

  Widget _buildRetiredSelectionWarning(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.orange.shade300,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${ChooseSubclassWidgetText.retiredSelectionPrefix}$name'
              '${ChooseSubclassWidgetText.retiredSelectionSuffix}',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FormTheme.textBright,
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
                color:
                    isSelected ? FormTheme.textBright : FormTheme.textSecondary,
              ),
            ),
            selected: isSelected,
            selectedColor: _accent.withValues(alpha: 0.3),
            backgroundColor: FormTheme.surface,
            checkmarkColor: _accent,
            side: BorderSide(
              color: isSelected ? _accent : FormTheme.border,
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
          style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
        ),
      ],
    ];
  }

  Widget _buildInfoChip(
    AppIconData icon,
    String label, {
    bool isConflict = false,
  }) {
    final color = isConflict ? Colors.orange : _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isConflict ? 0.18 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: color.withValues(alpha: isConflict ? 0.6 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConflict)
            Icon(Icons.warning_amber_rounded,
                size: 16, color: Colors.orange.shade600)
          else
            AppIcon(icon, size: 16, color: _accent),
          const SizedBox(width: 6),
          Text(
            isConflict
                ? '$label (${ChooseSubclassWidgetText.duplicateLabel})'
                : label,
            style: TextStyle(
              fontSize: 13,
              color:
                  isConflict ? Colors.orange.shade200 : FormTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
