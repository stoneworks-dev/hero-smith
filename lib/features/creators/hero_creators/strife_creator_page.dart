
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart' as app_db;
import '../../../core/db/providers.dart';
import '../../../core/models/abilities_models.dart';
import '../../../core/models/class_data.dart';
import '../../../core/models/characteristics_models.dart';
import '../../../core/models/component.dart';
import '../../../core/models/perks_models.dart';
import '../../../core/models/skills_models.dart';
import '../../../core/models/subclass_models.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/class_feature_data_service.dart';
import '../../../core/services/class_feature_grants_service.dart';
import '../../../core/services/abilities_service.dart';
import '../../../core/services/ability_data_service.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/kit_bonus_service.dart';
import '../../../core/services/kit_grants_service.dart';
import '../../../core/services/perk_data_service.dart';
import '../../../core/services/perks_service.dart';
import '../../../core/services/skill_data_service.dart';
import '../../../core/services/skills_service.dart';
import '../../../core/services/starting_characteristics_service.dart';
import '../../../core/services/subclass_data_service.dart';
import '../../../core/services/subclass_service.dart';
import '../../../core/text/creators/hero_creators/strife_creator_page_text.dart';
import '../../heroes_sheet/main_stats/hero_main_stats_providers.dart';
import '../widgets/strife_creator/choose_abilities_widget.dart';
import '../widgets/strife_creator/choose_equipment_widget.dart';
import '../widgets/strife_creator/choose_perks_widget.dart';
import '../widgets/strife_creator/choose_skills_widget.dart';
import '../widgets/strife_creator/choose_subclass_widget.dart';
import '../widgets/strife_creator/class_selector_widget.dart';
import '../widgets/strife_creator/level_selector_widget.dart';
import '../widgets/strife_creator/starting_characteristics_widget.dart';

/// Demo page for the new Strife Creator (Level, Class, and Starting Characteristics)
class StrifeCreatorPage extends ConsumerStatefulWidget {
  const StrifeCreatorPage({
    super.key,
    required this.heroId,
    this.onDirtyChanged,
    this.onSaveRequested,
  });

  final String heroId;
  final ValueChanged<bool>? onDirtyChanged;
  final VoidCallback? onSaveRequested;

  @override
  ConsumerState<StrifeCreatorPage> createState() => _StrifeCreatorPageState();
}

class _StrifeCreatorPageState extends ConsumerState<StrifeCreatorPage> {
  final ClassDataService _classDataService = ClassDataService();
  final StartingAbilitiesService _startingAbilitiesService =
      const StartingAbilitiesService();
  final AbilityDataService _abilityDataService = AbilityDataService();
  final StartingSkillsService _startingSkillsService =
      const StartingSkillsService();
  final SkillDataService _skillDataService = SkillDataService();
  final SubclassService _subclassPlanService = const SubclassService();
  final SubclassDataService _subclassDataService = SubclassDataService();
  final StartingPerksService _startingPerksService =
      const StartingPerksService();
  final PerkDataService _perkDataService = PerkDataService();

  static const Map<String, List<String>> _kitFeatureTypeMappings = {
    'kit': ['kit'],
    'psionic augmentation': ['psionic_augmentation'],
    'enchantment': ['enchantment'],
    'prayer': ['prayer'],
    'elementalist ward': ['ward'],
    'talent ward': ['ward'],
    'conduit ward': ['ward'],
    'ward': ['ward'],
  };

  static const List<String> _kitTypePriority = [
    'kit',
    'psionic_augmentation',
    'enchantment',
    'prayer',
    'ward',
    'stormwight_kit',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  bool _isDirty = false;
  bool _initialLoadComplete = false;
  Map<String, dynamic> _lastSavedSnapshot = const {};

  // Utility for deep map/set equality checks to avoid false dirty states
  static const _deepEq = DeepCollectionEquality();

  // State variables
  int _selectedLevel = 1;
  ClassData? _selectedClass;
  CharacteristicArray? _selectedArray;
  Map<String, int> _assignedCharacteristics = {};
  // ignore: unused_field
  Map<String, int> _finalCharacteristics = {};
  Map<String, String?> _levelChoiceSelections = {};
  Map<String, String?> _selectedSkills = {};
  Map<String, String?> _selectedAbilities = {};
  Map<String, String?> _selectedPerks = {};
  Set<String> _baseSkillIds = {};
  Set<String> _skillGrantIds = {};
  Map<String, String> _skillIdLookup = {};
  Set<String> _reservedSkillIds = {};
  Set<String> _reservedAbilityIds = {};
  Set<String> _reservedPerkIds = {};
  Set<String> _reservedLanguageIds = {};
  SubclassSelectionResult? _selectedSubclass;
  List<String?> _selectedKitIds = [];

  /// The skill ID saved in config as granted by the current subclass (to avoid self-flagging)
  String? _savedSubclassSkillId;

  /// The class ID that was loaded from the database (to detect class changes on save)
  String? _savedClassId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Map<String, dynamic> _currentSnapshot() {
    // Build a stable snapshot for dirty detection; keep ordering deterministic where possible
    return {
      'level': _selectedLevel,
      'class': _selectedClass?.classId,
      'array': _selectedArray?.description,
      'arrayValues': _selectedArray?.values,
      'assigned': Map<String, int>.from(_assignedCharacteristics),
      'levelChoices': Map<String, String?>.from(_levelChoiceSelections),
      'skills': Map<String, String?>.from(_selectedSkills),
      'skillGrants': (_skillGrantIds.toList()..sort()),
      'abilities': Map<String, String?>.from(_selectedAbilities),
      'perks': Map<String, String?>.from(_selectedPerks),
      'subclass': _selectedSubclass == null
          ? null
          : {
              'key': _selectedSubclass!.subclassKey,
              'name': _selectedSubclass!.subclassName,
              'deity': _selectedSubclass!.deityId,
              'domains': List<String>.from(_selectedSubclass!.domainNames),
            },
      'kits': List<String?>.from(_selectedKitIds),
    };
  }

  void _syncSnapshot() {
    _lastSavedSnapshot = _currentSnapshot();
  }

  Future<void> _initializeData() async {
    try {
      await _classDataService.initialize();
      if (!mounted) return;

      // Load existing hero data from database
      await _loadHeroData();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _syncSnapshot();

      // Mark initial load complete after first frame to prevent false dirty detection
      // Widgets may fire onChange callbacks during their first build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initialLoadComplete = true;
        if (_isDirty) {
          setState(() {
            _isDirty = false;
          });
          widget.onDirtyChanged?.call(false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            '${StrifeCreatorPageText.failedToLoadClassDataPrefix}$e';
      });
    }
  }

  Future<void> _loadHeroData() async {
    try {
      final repo = ref.read(heroRepositoryProvider);
      final db = ref.read(appDatabaseProvider);
      final hero = await repo.load(widget.heroId);

      if (hero == null) return;

      // Load level
      _selectedLevel = hero.level;

      // Load skill lookup for resolving names to IDs
      final skillOptions = await _skillDataService.loadSkills();
      _skillIdLookup = {
        for (final option in skillOptions) option.name.toLowerCase(): option.id,
        for (final option in skillOptions) option.id.toLowerCase(): option.id,
      };

      // Load characteristics (assigned values from stored assignments)
      final savedAssignments =
          await repo.getCharacteristicAssignments(widget.heroId);
      if (savedAssignments.isNotEmpty) {
        _assignedCharacteristics = savedAssignments;
      } else if (hero.might != 0 ||
          hero.agility != 0 ||
          hero.reason != 0 ||
          hero.intuition != 0 ||
          hero.presence != 0) {
        // Fallback: use hero base values if no assignments saved
        _assignedCharacteristics = {
          'Might': hero.might,
          'Agility': hero.agility,
          'Reason': hero.reason,
          'Intuition': hero.intuition,
          'Presence': hero.presence,
        };
      }

      // Load class
      if (hero.className != null) {
        final classData = _classDataService.getAllClasses().firstWhere(
            (c) => c.classId == hero.className,
            orElse: () => _classDataService.getAllClasses().first);
        _selectedClass = classData;
        _savedClassId =
            classData.classId; // Track the saved class for change detection

        // Load characteristic array if available
        final arrayConfig = await db.getHeroConfigValue(
            widget.heroId, 'strife.characteristic_array');
        final arrayDescription = arrayConfig?['name']?.toString();

        final savedArrayValues =
            await repo.getCharacteristicArrayValues(widget.heroId);

        final matchingArray = _findSavedArraySelection(
          classData: classData,
          savedDescription: arrayDescription,
          savedValues: savedArrayValues,
        );

        if (matchingArray != null) {
          _selectedArray = matchingArray;
        }

        // Load level choice selections (for "Any" characteristic improvements)
        final savedLevelChoiceSelections =
            await repo.getLevelChoiceSelections(widget.heroId);
        if (savedLevelChoiceSelections.isNotEmpty) {
          _levelChoiceSelections = savedLevelChoiceSelections;
        }

        // Load subclass / deity / domain selections
        final domainNames = hero.domain == null
            ? <String>[]
            : hero.domain!
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
        final savedSubclassKey = await repo.getSubclassKey(widget.heroId);
        final subclassName = hero.subclass?.trim();
        final subclassKey = savedSubclassKey ??
            (subclassName != null && subclassName.isNotEmpty
                ? ClassFeatureDataService.slugify(subclassName)
                : null);
        if ((subclassName?.isNotEmpty ?? false) ||
            (hero.deityId?.trim().isNotEmpty ?? false) ||
            domainNames.isNotEmpty) {
          _selectedSubclass = SubclassSelectionResult(
            subclassKey: subclassKey,
            subclassName: subclassName,
            deityId: hero.deityId?.trim().isNotEmpty == true
                ? hero.deityId!.trim()
                : null,
            deityName: hero.deityId?.trim().isNotEmpty == true
                ? hero.deityId!.trim()
                : null,
            domainNames: domainNames,
          );
        } else {
          _selectedSubclass = null;
        }

        if (_selectedSubclass != null) {
          _selectedSubclass = await _hydrateSubclassSelection(
            classData: classData,
            selection: _selectedSubclass!,
          );
        }

        // Load saved subclass skill ID to avoid self-flagging as duplicate
        final savedSubclassSkillConfig = await db.getHeroConfigValue(
          widget.heroId,
          'strife.subclass_skill_id',
        );
        _savedSubclassSkillId = savedSubclassSkillConfig?['id']?.toString();

        // Load equipment / modifications selections
        final equipmentIds = await repo.getEquipmentIds(widget.heroId);
        if (equipmentIds.isNotEmpty) {
          final matched = await _matchEquipmentToSlots(
            classData: classData,
            equipmentIds: equipmentIds,
            db: db,
          );
          _selectedKitIds = matched;
        } else {
          _selectedKitIds = <String?>[];
        }
      }

      // Load abilities
      if (_selectedClass != null) {
        var abilityIds =
            await db.getHeroComponentIds(widget.heroId, 'ability');
        if (abilityIds.isEmpty) {
          final importedConfig = await db.getHeroConfigValue(
            widget.heroId,
            'strife.import_ability_ids',
          );
          final importedList = importedConfig?['list'] as List?;
          if (importedList != null && importedList.isNotEmpty) {
            abilityIds =
                importedList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
          }
        }
        if (kDebugMode) {
          debugPrint('[StrifeCreatorPage] _loadHeroData: All abilityIds from DB: $abilityIds');
        }

        final languageIds =
            await db.getHeroComponentIds(widget.heroId, 'language');
        final skillIds = await db.getHeroComponentIds(widget.heroId, 'skill');
        final perkIds = await db.getHeroComponentIds(widget.heroId, 'perk');
        _baseSkillIds = _normalizeSkillIds(skillIds);

        // First try to load saved strife ability selections directly
        final savedStrifeAbilitySelections =
            await _loadStrifeSelections('strife.ability_selections');
        if (kDebugMode) {
          debugPrint('[StrifeCreatorPage] _loadHeroData: savedStrifeAbilitySelections: $savedStrifeAbilitySelections');
        }

        if (savedStrifeAbilitySelections.isNotEmpty) {
          _selectedAbilities = savedStrifeAbilitySelections;
        } else {
          // Fallback to inference (for legacy data or first-time setup)
          _selectedAbilities = await _restoreAbilitySelections(
            classData: _selectedClass!,
            selectedLevel: _selectedLevel,
            abilityIds: abilityIds,
          );
        }
        if (kDebugMode) {
          debugPrint('[StrifeCreatorPage] _loadHeroData: _selectedAbilities after load: $_selectedAbilities');
        }

        // ignore: unused_local_variable
        final assignedAbilityIds =
            _selectedAbilities.values.whereType<String>().toSet();
        _reservedAbilityIds = abilityIds.toSet();
        _reservedLanguageIds = languageIds.toSet();

        // First try to load saved strife skill selections directly
        final savedStrifeSkillSelections =
            await _loadStrifeSelections('strife.skill_selections');
        if (savedStrifeSkillSelections.isNotEmpty) {
          _selectedSkills = savedStrifeSkillSelections;
        } else {
          // Fallback to inference (for legacy data or first-time setup)
          _selectedSkills = await _restoreSkillSelections(
            classData: _selectedClass!,
            selectedLevel: _selectedLevel,
            skillIds: skillIds,
          );
        }
        _reservedSkillIds = _baseSkillIds;

        // First try to load saved strife perk selections directly
        final savedStrifePerkSelections =
            await _loadStrifeSelections('strife.perk_selections');
        if (savedStrifePerkSelections.isNotEmpty) {
          _selectedPerks = savedStrifePerkSelections;
        } else {
          // Fallback to inference (for legacy data or first-time setup)
          _selectedPerks = await _restorePerkSelections(
            classData: _selectedClass!,
            selectedLevel: _selectedLevel,
            perkIds: perkIds,
          );
        }
        _reservedPerkIds = perkIds.toSet();

        _updateGrantIdsForCurrentPlan();
      } else {
        _selectedAbilities = const <String, String?>{};
        _selectedSkills = const <String, String?>{};
        _selectedPerks = const <String, String?>{};
        _reservedAbilityIds = {};
        _reservedSkillIds = {};
        _reservedPerkIds = {};
        _reservedLanguageIds = {};
      }

      _refreshReservedSkills();
      _refreshReservedPerks();
    } catch (e) {
      debugPrint('Failed to load hero data: $e');
      // Don't fail the whole initialization if hero data can't be loaded
    }
  }

  CharacteristicArray? _findSavedArraySelection({
    required ClassData classData,
    String? savedDescription,
    required List<int> savedValues,
  }) {
    final arrays =
        classData.startingCharacteristics.startingCharacteristicsArrays;

    if (savedDescription != null && savedDescription.isNotEmpty) {
      final byDescription = arrays.firstWhereOrNull(
        (arr) => arr.description == savedDescription,
      );
      if (byDescription != null) {
        return byDescription;
      }
    }

    final valueCandidates = savedValues.isNotEmpty
        ? savedValues
        : _assignedCharacteristics.values.toList();

    if (valueCandidates.isEmpty) return null;

    final target = List<int>.from(valueCandidates)..sort();
    return arrays.firstWhereOrNull((arr) {
      final arrValues = List<int>.from(arr.values)..sort();
      if (arrValues.length != target.length) return false;
      for (var i = 0; i < arrValues.length; i++) {
        if (arrValues[i] != target[i]) return false;
      }
      return true;
    });
  }

  Future<Map<String, String?>> _restoreAbilitySelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> abilityIds,
  }) async {
    if (abilityIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingAbilitiesService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final classSlug = _classSlug(classData.classId);
    final components = await _abilityDataService.loadClassAbilities(classSlug);
    final options = components.map(_mapComponentToAbilityOption).toList();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};
    final unmatched = <AbilityOption>[];

    for (final abilityId in abilityIds) {
      final option = optionById[abilityId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignAbility(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        unmatched.add(option);
      }
    }

    for (final option in unmatched) {
      _tryAssignAbility(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: true,
      );
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  Future<Map<String, String?>> _restoreSkillSelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> skillIds,
  }) async {
    if (skillIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingSkillsService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
      subclassSelection: _selectedSubclass,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final options = await _skillDataService.loadSkills();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};

    for (final skillId in skillIds) {
      final option = optionById[skillId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignSkill(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        _tryAssignSkill(
          allowanceList: plan.allowances,
          filledCounts: filledCounts,
          selections: selections,
          option: option,
          ignoreConstraints: true,
        );
      }
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  /// Load saved strife selections from hero_config
  Future<Map<String, String?>> _loadStrifeSelections(String key) async {
    final db = ref.read(appDatabaseProvider);
    final config = await db.getHeroConfigValue(widget.heroId, key);
    if (config != null) {
      return config.map((k, v) => MapEntry(k.toString(), v?.toString()));
    }
    return const <String, String?>{};
  }

  String? _resolveSkillId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    return _skillIdLookup[lower] ?? _skillIdLookup[trimmed] ?? trimmed;
  }

  Set<String> _normalizeSkillIds(Iterable<String> values) {
    final result = <String>{};
    for (final value in values) {
      final resolved = _resolveSkillId(value) ?? value.trim();
      if (resolved.isNotEmpty) {
        result.add(resolved);
      }
    }
    return result;
  }

  /// Gets skill IDs saved in the database from other sources (story, ancestry, etc.)
  Set<String> get _dbSavedSkillIds => ref.watch(
        heroEntryIdsByTypeProvider((heroId: widget.heroId, entryType: 'skill')),
      );

  /// Gets perk IDs saved in the database from other sources.
  Set<String> get _dbSavedPerkIds => ref.watch(
        heroEntryIdsByTypeProvider((heroId: widget.heroId, entryType: 'perk')),
      );

  /// Gets language IDs saved in the database from other sources.
  Set<String> get _dbSavedLanguageIds => ref.watch(
        heroEntryIdsByTypeProvider(
            (heroId: widget.heroId, entryType: 'language')),
      );

  void _refreshReservedSkills() {
    final normalizedSelections =
        _normalizeSkillIds(_selectedSkills.values.whereType<String>());
    final reserved = <String>{
      ..._baseSkillIds,
      ..._dbSavedSkillIds, // Include DB-saved skills from other sources
    };
    // Only remove picks that are NEW this session; keep anything already in DB
    for (final id in normalizedSelections) {
      if (!_dbSavedSkillIds.contains(id)) {
        reserved.remove(id);
      }
    }
    final subclassSkillId = _resolveSkillId(_selectedSubclass?.skill);
    if (subclassSkillId != null) {
      reserved.add(subclassSkillId);
    }

    const equality = SetEquality<String>();
    if (!equality.equals(reserved, _reservedSkillIds)) {
      setState(() {
        _reservedSkillIds = reserved;
      });
    }
  }

  void _refreshReservedPerks() {
    final currentSelections = _selectedPerks.values.whereType<String>().toSet();
    final reserved = <String>{
      ..._dbSavedPerkIds, // Include DB-saved perks from other sources (e.g., Story page)
    };
    for (final id in currentSelections) {
      if (!_dbSavedPerkIds.contains(id)) {
        reserved.remove(id);
      }
    }

    const equality = SetEquality<String>();
    if (!equality.equals(reserved, _reservedPerkIds)) {
      setState(() {
        _reservedPerkIds = reserved;
      });
    }
  }

  void _updateGrantIdsForCurrentPlan() {
    if (_selectedClass == null) {
      _skillGrantIds = {};
      return;
    }

    final plan = _startingSkillsService.buildPlan(
      classData: _selectedClass!,
      selectedLevel: _selectedLevel,
      subclassSelection: _selectedSubclass,
      // Exclude level-based and subclass skill allowances - those are handled in Strength tab
      excludeLevelAllowances: true,
      excludeSubclassSkillAllowances: true,
    );
    _skillGrantIds =
        plan.grantedSkillNames.map(_resolveSkillId).whereType<String>().toSet();
    _refreshReservedSkills();
  }

  Future<Map<String, String?>> _restorePerkSelections({
    required ClassData classData,
    required int selectedLevel,
    required List<String> perkIds,
  }) async {
    if (perkIds.isEmpty) {
      return const <String, String?>{};
    }

    final plan = _startingPerksService.buildPlan(
      classData: classData,
      selectedLevel: selectedLevel,
    );
    if (plan.allowances.isEmpty) {
      return const <String, String?>{};
    }

    final options = await _perkDataService.loadPerks();
    final optionById = {
      for (final option in options) option.id: option,
    };

    final filledCounts = <String, int>{
      for (final allowance in plan.allowances) allowance.id: 0,
    };
    final selections = <String, String?>{};

    for (final perkId in perkIds) {
      final option = optionById[perkId];
      if (option == null) {
        continue;
      }
      final assigned = _tryAssignPerk(
        allowanceList: plan.allowances,
        filledCounts: filledCounts,
        selections: selections,
        option: option,
        ignoreConstraints: false,
      );
      if (!assigned) {
        _tryAssignPerk(
          allowanceList: plan.allowances,
          filledCounts: filledCounts,
          selections: selections,
          option: option,
          ignoreConstraints: true,
        );
      }
    }

    return selections.isEmpty ? const <String, String?>{} : selections;
  }

  bool _tryAssignAbility({
    required List<AbilityAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required AbilityOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsAbility(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsAbility({
    required AbilityAllowance allowance,
    required AbilityOption option,
  }) {
    if (allowance.isSignature != option.isSignature) {
      return false;
    }
    if (allowance.costAmount != null &&
        allowance.costAmount != option.costAmount) {
      return false;
    }
    final hasSubclass = option.subclass != null && option.subclass!.isNotEmpty;
    if (allowance.requiresSubclass && !hasSubclass) {
      return false;
    }
    if (!allowance.requiresSubclass && hasSubclass) {
      return false;
    }
    if (allowance.includePreviousLevels) {
      if (option.level > allowance.level) {
        return false;
      }
    } else {
      if (option.level != 0 && option.level != allowance.level) {
        return false;
      }
    }
    return true;
  }

  bool _tryAssignSkill({
    required List<SkillAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required SkillOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsSkill(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsSkill({
    required SkillAllowance allowance,
    required SkillOption option,
  }) {
    if (allowance.allowedGroups.isEmpty) {
      return true;
    }
    return allowance.allowedGroups.contains(option.group.toLowerCase());
  }

  bool _tryAssignPerk({
    required List<PerkAllowance> allowanceList,
    required Map<String, int> filledCounts,
    required Map<String, String?> selections,
    required PerkOption option,
    required bool ignoreConstraints,
  }) {
    for (final allowance in allowanceList) {
      final filled = filledCounts[allowance.id] ?? 0;
      if (filled >= allowance.pickCount) {
        continue;
      }
      if (ignoreConstraints ||
          _allowanceAcceptsPerk(allowance: allowance, option: option)) {
        final slotKey = '${allowance.id}#$filled';
        selections[slotKey] = option.id;
        filledCounts[allowance.id] = filled + 1;
        return true;
      }
    }
    return false;
  }

  bool _allowanceAcceptsPerk({
    required PerkAllowance allowance,
    required PerkOption option,
  }) {
    if (allowance.allowedGroups.isEmpty) {
      return true;
    }
    return allowance.allowedGroups.contains(option.group.toLowerCase());
  }

  AbilityOption _mapComponentToAbilityOption(Component component) {
    final data = component.data;
    final costsRaw = data['costs'];

    final bool isSignature;
    if (costsRaw is String) {
      isSignature = costsRaw.toLowerCase() == 'signature';
    } else if (costsRaw is Map) {
      isSignature = costsRaw['signature'] == true;
    } else {
      isSignature = false;
    }

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
  }

  String _classSlug(String classId) {
    final normalized = classId.trim().toLowerCase();
    if (normalized.startsWith('class_')) {
      return normalized.substring('class_'.length);
    }
    return normalized;
  }

  Future<SubclassSelectionResult?> _hydrateSubclassSelection({
    required ClassData classData,
    required SubclassSelectionResult selection,
  }) async {
    try {
      final plan = _subclassPlanService.buildPlan(
        classData: classData,
        selectedLevel: _selectedLevel,
      );
      if (!plan.hasSubclassChoice || plan.subclassFeatureName == null) {
        return selection;
      }

      final data = await _subclassDataService.loadSubclassFeatureData(
        classSlug: _classSlug(classData.classId),
        featureName: plan.subclassFeatureName!,
      );
      final options = data?.options ?? const <SubclassOption>[];
      SubclassOption? option;
      if (selection.subclassKey != null) {
        option = options.firstWhereOrNull(
          (opt) => opt.key == selection.subclassKey,
        );
      }
      option ??= options.firstWhereOrNull(
        (opt) =>
            opt.name.toLowerCase() ==
            (selection.subclassName ?? '').toLowerCase(),
      );
      if (option == null) return selection;
      return selection.copyWith(
        subclassName: selection.subclassName ?? option.name,
        skill: option.skill ?? selection.skill,
        skillGroup: option.skillGroup ?? selection.skillGroup,
      );
    } catch (_) {
      return selection;
    }
  }



  void _markDirty() {
    // Don't mark dirty during initial data loading or before first frame completes
    if (_isLoading || !_initialLoadComplete) return;

    const deepEq = DeepCollectionEquality();
    final changed = !deepEq.equals(_lastSavedSnapshot, _currentSnapshot());

    if (changed && !_isDirty) {
      setState(() {
        _isDirty = true;
      });
      widget.onDirtyChanged?.call(true);
    } else if (!changed && _isDirty) {
      setState(() {
        _isDirty = false;
      });
      widget.onDirtyChanged?.call(false);
    }
  }

  void _handleLevelChanged(int level) {
    if (level == _selectedLevel) return;
    setState(() {
      _selectedLevel = level;
    });
    _updateGrantIdsForCurrentPlan();
    _refreshReservedSkills();
    _refreshReservedPerks();
    _markDirty();
  }

  void _handleClassChanged(ClassData classData) {
    if (_selectedClass?.classId == classData.classId) return;
    setState(() {
      _selectedClass = classData;
      // Reset characteristic and skill selections when class changes
      _selectedArray = null;
      _assignedCharacteristics = {};
      _levelChoiceSelections = {};
      _selectedSkills = {};
      _skillGrantIds = {};
      _selectedAbilities = {};
      _selectedPerks = {};
      _reservedSkillIds = _baseSkillIds;
      _reservedAbilityIds = {};
      _reservedPerkIds = {};
      _reservedLanguageIds = {};
      _selectedSubclass = null;
      _selectedKitIds = <String?>[];
    });
    _updateGrantIdsForCurrentPlan();
    _refreshReservedSkills();
    _refreshReservedPerks();
    _markDirty();
  }

  void _handleArrayChanged(CharacteristicArray? array) {
    if (_selectedArray == array) return;
    setState(() {
      _selectedArray = array;
      _assignedCharacteristics = {};
    });
    _markDirty();
  }

  void _handleAssignmentsChanged(Map<String, int> assignments) {
    if (_deepEq.equals(_assignedCharacteristics, assignments)) return;
    setState(() {
      _assignedCharacteristics = assignments;
    });
    _markDirty();
  }

  void _handleFinalTotalsChanged(Map<String, int> totals) {
    if (_deepEq.equals(_finalCharacteristics, totals)) return;
    setState(() {
      _finalCharacteristics = totals;
    });
    _markDirty();
  }

  void _handleLevelChoiceSelectionsChanged(Map<String, String?> selections) {
    if (_deepEq.equals(_levelChoiceSelections, selections)) return;
    setState(() {
      _levelChoiceSelections = selections;
    });
    _markDirty();
  }

  void _handleSkillSelectionsChanged(StartingSkillSelectionResult result) {
    final sameSlots = _deepEq.equals(_selectedSkills, result.selectionsBySlot);
    final sameGrants =
        _deepEq.equals(_skillGrantIds, result.grantedSkillIds.toSet());
    if (sameSlots && sameGrants) return;
    setState(() {
      _selectedSkills = result.selectionsBySlot;
      _skillGrantIds = Set<String>.from(result.grantedSkillIds);
    });
    _refreshReservedSkills();
    _markDirty();
  }

  void _handlePerkSelectionsChanged(StartingPerkSelectionResult result) {
    if (_deepEq.equals(_selectedPerks, result.selectionsBySlot)) return;
    setState(() {
      _selectedPerks = result.selectionsBySlot;
    });
    _refreshReservedPerks();
    _markDirty();
  }

  void _handleAbilitySelectionsChanged(StartingAbilitySelectionResult result) {
    if (_deepEq.equals(_selectedAbilities, result.selectionsBySlot)) return;
    setState(() {
      _selectedAbilities = result.selectionsBySlot;
    });
    _markDirty();
  }

  void _handleSubclassSelectionChanged(SubclassSelectionResult result) {
    final sameDeity = _selectedSubclass?.deityId == result.deityId;
    final sameSubclass =
        _selectedSubclass?.subclassName == result.subclassName &&
            _selectedSubclass?.subclassKey == result.subclassKey;
    final sameDomains = _deepEq.equals(
        _selectedSubclass?.domainNames ?? const <String>[], result.domainNames);
    if (sameDeity && sameSubclass && sameDomains) return;
    setState(() {
      _selectedSubclass = result;
    });
    _updateGrantIdsForCurrentPlan();
    _refreshReservedSkills();
    _refreshReservedPerks();
    _markDirty();
  }

  void _handleKitChangedAtSlot(int slotIndex, String? kitId) {
    if (_selectedKitIds.length > slotIndex &&
        _selectedKitIds[slotIndex] == kitId) {
      return;
    }
    setState(() {
      while (_selectedKitIds.length <= slotIndex) {
        _selectedKitIds.add(null);
      }
      _selectedKitIds[slotIndex] = kitId;
    });
    _markDirty();
  }

  List<Widget> _buildKitWidgets() {
    if (_selectedClass == null) return [];

    final slots = _determineKitSlots(_selectedClass!);
    if (slots.isEmpty) return [];

    final totalSlots = slots.fold<int>(0, (sum, slot) => sum + slot.count);
    while (_selectedKitIds.length < totalSlots) {
      _selectedKitIds.add(null);
    }

    final equipmentSlots = <EquipmentSlot>[];
    var kitIndex = 0;

    for (final slot in slots) {
      for (var i = 0; i < slot.count; i++) {
        final currentIndex = kitIndex;
        final label = _buildEquipmentSlotLabel(
          allowedTypes: slot.allowedTypes,
          groupCount: slot.count,
          indexWithinGroup: i,
          globalIndex: kitIndex,
        );
        final helperText = slot.allowedTypes.length > 1
            ? 'Allowed types: ${slot.allowedTypes.map(_formatKitTypeName).join(', ')}'
            : null;

        // Collect IDs of kits selected in OTHER slots to prevent duplicates
        final excludeIds = <String>[];
        for (var j = 0; j < _selectedKitIds.length; j++) {
          if (j != currentIndex && _selectedKitIds[j] != null) {
            excludeIds.add(_selectedKitIds[j]!);
          }
        }

        equipmentSlots.add(
          EquipmentSlot(
            label: label,
            allowedTypes: slot.allowedTypes,
            selectedItemId: currentIndex < _selectedKitIds.length
                ? _selectedKitIds[currentIndex]
                : null,
            onChanged: (kitId) => _handleKitChangedAtSlot(currentIndex, kitId),
            helperText: helperText,
            classId: _selectedClass?.classId,
            excludeItemIds: excludeIds,
          ),
        );
        kitIndex++;
      }
    }

    return [
      EquipmentAndModificationsWidget(
        key: const ValueKey('equipment_and_modifications'),
        slots: equipmentSlots,
      ),
    ];
  }

  String _buildEquipmentSlotLabel({
    required List<String> allowedTypes,
    required int groupCount,
    required int indexWithinGroup,
    required int globalIndex,
  }) {
    if (allowedTypes.length == 1) {
      final base = _formatKitTypeName(allowedTypes.first);
      if (groupCount > 1) {
        return '$base ${indexWithinGroup + 1}';
      }
      return base;
    }
    return 'Equipment ${globalIndex + 1}';
  }

  String _formatKitTypeName(String type) {
    switch (type) {
      case 'psionic_augmentation':
        return 'Psionic Augmentation';
      case 'stormwight_kit':
        return 'Stormwight Kit';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  /// Match loaded equipment IDs to the correct slots based on their types
  Future<List<String?>> _matchEquipmentToSlots({
    required ClassData classData,
    required List<String?> equipmentIds,
    required dynamic db,
  }) async {
    final slots = _determineKitSlots(classData);
    if (slots.isEmpty) return <String?>[];

    // Build flat list of slot allowed types
    final slotTypes = <List<String>>[];
    for (final slot in slots) {
      for (var i = 0; i < slot.count; i++) {
        slotTypes.add(slot.allowedTypes);
      }
    }

    // Initialize result with nulls
    final result = List<String?>.filled(slotTypes.length, null);
    final usedIds = <String>{};

    // Load equipment types for each ID
    final equipmentTypes = <String, String>{};
    for (final id in equipmentIds) {
      if (id == null || id.isEmpty) {
        continue;
      }
      final component = await db.getComponentById(id);
      if (component != null) {
        equipmentTypes[id] = component.type;
      }
    }

    // First pass: match equipment to slots where type exactly matches
    for (var slotIndex = 0; slotIndex < slotTypes.length; slotIndex++) {
      final allowedTypes = slotTypes[slotIndex];
      for (final id in equipmentIds) {
        if (id == null || id.isEmpty) continue;
        if (usedIds.contains(id)) continue;
        final type = equipmentTypes[id];
        if (type != null && allowedTypes.contains(type)) {
          result[slotIndex] = id;
          usedIds.add(id);
          break;
        }
      }
    }

    // Second pass: fill remaining slots with any remaining equipment
    for (var slotIndex = 0; slotIndex < result.length; slotIndex++) {
      if (result[slotIndex] != null) continue;
      for (final id in equipmentIds) {
        if (id == null || id.isEmpty) continue;
        if (usedIds.contains(id)) continue;
        result[slotIndex] = id;
        usedIds.add(id);
        break;
      }
    }

    return result;
  }

  /// Determines kit slots and allowed types for each slot
  /// Returns list of (count, [allowed types]) pairs
  List<({int count, List<String> allowedTypes})> _determineKitSlots(
    ClassData classData,
  ) {
    // Special case: Stormwight Fury - only stormwight kits
    final subclassName = _selectedSubclass?.subclassName?.toLowerCase() ?? '';
    if (classData.classId == 'class_fury' && subclassName == 'stormwight') {
      return [
        (count: 1, allowedTypes: ['stormwight_kit'])
      ];
    }

    final kitFeatures = <Map<String, dynamic>>[];
    final typesList = <String>[];

    // Collect all kit-related features
    for (final level in classData.levels) {
      for (final feature in level.features) {
        final name = feature.name.trim().toLowerCase();
        if (name == 'kit' || _kitFeatureTypeMappings.containsKey(name)) {
          kitFeatures.add({
            'name': name,
            'count': feature.count ?? 1,
          });

          final mapped = _kitFeatureTypeMappings[name];
          if (mapped != null) {
            typesList.addAll(mapped);
          } else if (name == 'kit') {
            typesList.add('kit');
          }
        }
      }
    }

    if (kitFeatures.isEmpty) {
      return [];
    }

    // Remove duplicates while preserving order
    final uniqueTypes = <String>[];
    final seen = <String>{};
    for (final type in typesList) {
      if (seen.add(type)) {
        uniqueTypes.add(type);
      }
    }

    // Calculate total count needed
    var totalCount = 0;
    for (final feature in kitFeatures) {
      totalCount += feature['count'] as int;
    }

    // If we have multiple types and count > 1, create one slot per type
    if (uniqueTypes.length > 1 && totalCount >= uniqueTypes.length) {
      return uniqueTypes
          .map((type) => (count: 1, allowedTypes: [type]))
          .toList();
    }

    // Otherwise, create slots of the same type
    final sortedTypes = _sortKitTypesByPriority(uniqueTypes);
    return [
      (count: totalCount, allowedTypes: sortedTypes),
    ];
  }

  List<String> _sortKitTypesByPriority(Iterable<String> types) {
    final seen = <String>{};
    final sorted = <String>[];

    for (final type in _kitTypePriority) {
      if (types.contains(type) && seen.add(type)) {
        sorted.add(type);
      }
    }

    for (final type in types) {
      if (seen.add(type)) {
        sorted.add(type);
      }
    }

    return sorted;
  }

  bool _validateSelections() {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StrifeCreatorPageText.pleaseSelectClassSnackBar),
        ),
      );
      return false;
    }

    return true;
  }

  /// Applies a characteristic payload (setTo, increaseBy, max) to a stat value
  void _applyCharacteristicPayload(
    String stat,
    AdjustmentPayload payload,
    Map<String, int> characteristics,
  ) {
    var value = characteristics[stat] ?? 0;

    // Apply increaseBy
    final increase = payload.increaseBy;
    if (increase != null) {
      value += increase;
    }

    // Apply setTo (only if current value is lower)
    final setTo = payload.setTo;
    if (setTo != null && value < setTo) {
      value = setTo;
    }

    // Apply max cap
    final maxValue = payload.max;
    if (maxValue != null && value > maxValue) {
      value = maxValue;
    }

    characteristics[stat] = value;
  }

  Future<EquipmentBonuses> _applyEquipmentSelectionAndBonuses(
    List<String?> equipmentSlotIds,
    HeroRepository repo,
    app_db.AppDatabase db,
  ) async {
    if (kDebugMode) {
      debugPrint('[StrifeCreator] _applyEquipmentSelectionAndBonuses called with: $equipmentSlotIds');
    }
    
    // EXACT copy of Kits tab flow - do not add extra logic here
    await repo.saveEquipmentIds(widget.heroId, equipmentSlotIds);
    await db.upsertHeroValue(
      heroId: widget.heroId,
      key: 'basics.equipment',
      jsonMap: {'ids': equipmentSlotIds},
    );

    final level = _selectedLevel;
    if (kDebugMode) {
      debugPrint('[StrifeCreator] Calling applyKitGrants with heroLevel: $level');
    }

    // Use KitGrantsService to apply all kit grants (including stat mods like decrease_total)
    // This is the ONLY thing that saves to hero_entries - do not duplicate or interfere
    final kitGrantsService = KitGrantsService(db);
    final bonuses = await kitGrantsService.applyKitGrants(
      heroId: widget.heroId,
      equipmentIds: equipmentSlotIds,
      heroLevel: level,
    );
    
    if (kDebugMode) {
      debugPrint('[StrifeCreator] applyKitGrants returned bonuses: stamina=${bonuses.staminaBonus}, speed=${bonuses.speedBonus}, stability=${bonuses.stabilityBonus}, disengage=${bonuses.disengageBonus}');
    }

    // KitGrantsService now saves to both hero_entries AND hero_values.strife.equipment_bonuses
    // No need to save separately here

    // Also invalidate hero assembly to reload stat mods
    ref.invalidate(heroAssemblyProvider(widget.heroId));
    
    return bonuses;
  }

  Future<void> handleSave() async {
    await _handleSave();
  }

  Future<void> _handleSave() async {
    if (!_validateSelections()) return;

    final repo = ref.read(heroRepositoryProvider);
    final db = ref.read(appDatabaseProvider);
    final classData = _selectedClass!;
    final startingChars = classData.startingCharacteristics;

    try {
      // Check if the class has changed - if so, clear all previous strife data first
      final classChanged =
          _savedClassId != null && _savedClassId != classData.classId;
      if (classChanged) {
        if (kDebugMode) {
          debugPrint('Class changed from $_savedClassId to ${classData.classId} - clearing old strife data');
        }
        await repo.clearStrifeData(widget.heroId);
      }

      final updates = <Future>[];

      // 1. Save level
      await repo.updateMainStats(widget.heroId, level: _selectedLevel);

      // 2. Save class name
      await repo.updateClassName(widget.heroId, classData.classId);

      // 3. Save subclass
      if (_selectedSubclass != null) {
        // Execute immediately to reduce batch size
        await repo.updateSubclass(
          widget.heroId,
          _selectedSubclass!.subclassName,
        );

        // Save subclass key for proper restoration
        if (_selectedSubclass!.subclassKey != null) {
          await repo.saveSubclassKey(
            widget.heroId,
            _selectedSubclass!.subclassKey,
          );
        }

        // Save deity if selected
        if (_selectedSubclass!.deityId != null) {
          await repo.updateDeity(
            widget.heroId,
            _selectedSubclass!.deityId,
          );
        }

        // Save domain if selected (join multiple domains with comma)
        if (_selectedSubclass!.domainNames.isNotEmpty) {
          await repo.updateDomain(
            widget.heroId,
            _selectedSubclass!.domainNames.join(', '),
          );
        }
      }

      // 3.5. Apply kit grants (bonuses, abilities, stat mods like decrease_total) from selected equipment
      final slotOrderedEquipmentIds = List<String?>.from(_selectedKitIds);
      if (kDebugMode) {
        debugPrint('[StrifeCreatorPage] _handleSave: Saving kits: $slotOrderedEquipmentIds');
      }

      // Persist equipment selection and recalc bonuses using the same flow as KitsTab
      final equipmentBonuses = await _applyEquipmentSelectionAndBonuses(
        slotOrderedEquipmentIds,
        repo,
        db,
      );
      if (kDebugMode) {
        debugPrint('[StrifeCreatorPage] _handleSave: Calculated bonuses: $equipmentBonuses');
      }

      // Auto-favorite the selected equipment so it shows up in the gear page favorites
      final equipmentIdsToFavorite =
          slotOrderedEquipmentIds.whereType<String>().toList();
      if (equipmentIdsToFavorite.isNotEmpty) {
        // Get existing favorites and merge with new equipment
        final existingFavorites = await repo.getFavoriteKitIds(widget.heroId);
        final mergedFavorites =
            <String>{...existingFavorites, ...equipmentIdsToFavorite}.toList();
        await repo.saveFavoriteKitIds(widget.heroId, mergedFavorites);
      }

      // 4. Save selected characteristic array name
      if (_selectedArray != null) {
        updates.add(repo.updateCharacteristicArray(
          widget.heroId,
          arrayName: _selectedArray!.description,
          arrayValues: _selectedArray!.values,
        ));
      }

      // 4.5. Save characteristic assignments (the mapping of stat to value)
      if (_assignedCharacteristics.isNotEmpty) {
        updates.add(repo.saveCharacteristicAssignments(
          widget.heroId,
          _assignedCharacteristics,
        ));
      }

      // 4.6. Save level choice selections (which characteristic to boost at each level)
      if (_levelChoiceSelections.isNotEmpty) {
        updates.add(repo.saveLevelChoiceSelections(
          widget.heroId,
          _levelChoiceSelections,
        ));
      }

      // 5. Calculate and save characteristics (base values = fixed + array + level improvements)
      // Use the service to calculate final characteristic values
      const charService = StartingCharacteristicsService();
      final adjustmentEntries = charService.collectAdjustmentEntries(
        classData: classData,
        selectedLevel: _selectedLevel,
      );

      // Build initial values from fixed starting characteristics
      final baseCharacteristics = <String, int>{
        for (final stat in CharacteristicUtils.characteristicOrder) stat: 0,
      };

      // Apply fixed values
      startingChars.fixedStartingCharacteristics.forEach((key, value) {
        final normalizedKey = CharacteristicUtils.normalizeKey(key);
        if (normalizedKey != null) {
          baseCharacteristics[normalizedKey] = value;
        }
      });

      // Apply array assignments
      _assignedCharacteristics.forEach((characteristic, value) {
        final charLower = characteristic.toLowerCase();
        if (baseCharacteristics.containsKey(charLower)) {
          baseCharacteristics[charLower] =
              (baseCharacteristics[charLower] ?? 0) + value;
        }
      });

      // Apply level-based improvements
      for (final entry in adjustmentEntries) {
        final payload = entry.payload;
        if (entry.target == 'all') {
          // Apply to all characteristics
          for (final stat in CharacteristicUtils.characteristicOrder) {
            _applyCharacteristicPayload(stat, payload, baseCharacteristics);
          }
        } else if (entry.target == 'any') {
          // Apply to the user's chosen characteristic
          final choiceId = entry.choiceId;
          if (choiceId != null) {
            final chosenStat = _levelChoiceSelections[choiceId];
            if (chosenStat != null) {
              _applyCharacteristicPayload(
                  chosenStat, payload, baseCharacteristics);
            }
          }
        } else if (CharacteristicUtils.characteristicOrder
            .contains(entry.target)) {
          // Apply to specific characteristic
          _applyCharacteristicPayload(
              entry.target, payload, baseCharacteristics);
        }
      }

      // Save the final base characteristics
      for (final entry in baseCharacteristics.entries) {
        updates.add(
          repo.setCharacteristicBase(widget.heroId,
              characteristic: entry.key, value: entry.value),
        );
      }

      // 5.5. Load feature stat bonuses (from class features like "stamina_increase: 21")
      // Note: speed/disengage bonuses may be characteristic-based ("Agility") so they're
      // computed at runtime via dynamicModifiers, not added here.
      final featureStatBonuses =
          await repo.getFeatureStatBonuses(widget.heroId);
      final featureStaminaBonus = featureStatBonuses['stamina'] ?? 0;

      // 6. Calculate and save Stamina (class base + level scaling + equipment bonus + feature bonus)
      final baseMaxStamina = startingChars.baseStamina +
          (startingChars.staminaPerLevel * (_selectedLevel - 1));
      final effectiveMaxStamina =
          baseMaxStamina + equipmentBonuses.staminaBonus + featureStaminaBonus;
      updates.add(repo.updateVitals(
        widget.heroId,
        staminaMax: baseMaxStamina,
        staminaCurrent: effectiveMaxStamina, // Start at full health
      ));

      // 7. Calculate winded and dying values (based on effective max stamina)
      final windedValue = effectiveMaxStamina ~/ 2; // Half of max stamina
      final dyingValue =
          -(effectiveMaxStamina ~/ 2); // Negative half of max stamina
      updates.add(repo.updateVitals(
        widget.heroId,
        windedValue: windedValue,
        dyingValue: dyingValue,
      ));

      // 8. Save Recoveries
      final recoveriesMax = startingChars.baseRecoveries;
      final recoveryValue =
          (effectiveMaxStamina / 3).ceil(); // 1/3 of max HP, rounded up
      updates.add(repo.updateVitals(
        widget.heroId,
        recoveriesMax: recoveriesMax,
        recoveriesCurrent: recoveriesMax, // Start with all recoveries available
      ));
      updates.add(repo.updateRecoveryValue(widget.heroId, recoveryValue));

      // 9. Save stats from class (equipment bonuses are stored separately)
      updates.add(repo.updateCoreStats(
        widget.heroId,
        speed: startingChars.baseSpeed,
        stability: startingChars.baseStability,
        disengage: startingChars.baseDisengage,
      ));

      // 10. Save Heroic Resource name
      updates.add(repo.updateHeroicResourceName(
        widget.heroId,
        startingChars.heroicResourceName,
      ));

      // 11. Calculate and save potencies based on class progression
      final potencyChar = startingChars.potencyProgression.characteristic;
      final potencyModifiers = startingChars.potencyProgression.modifiers;

      // Get the characteristic value for potency calculation
      final potencyCharValue = _assignedCharacteristics[potencyChar] ??
          startingChars
              .fixedStartingCharacteristics[potencyChar.toLowerCase()] ??
          0;

      // Calculate potency values (characteristic + modifier)
      final strongPotency =
          potencyCharValue + (potencyModifiers['strong'] ?? 0);
      final averagePotency =
          potencyCharValue + (potencyModifiers['average'] ?? 0);
      final weakPotency = potencyCharValue + (potencyModifiers['weak'] ?? 0);

      updates.add(repo.updatePotencies(
        widget.heroId,
        strong: '$strongPotency',
        average: '$averagePotency',
        weak: '$weakPotency',
      ));

      // 10. Save selected abilities to database (replaces all previous abilities)
      final selectedAbilityIds = _selectedAbilities.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (kDebugMode) {
        debugPrint('[StrifeCreatorPage] _handleSave: Saving abilities: $selectedAbilityIds');
        debugPrint('[StrifeCreatorPage] _handleSave: _selectedAbilities map: $_selectedAbilities');
      }

      // Save ONLY user-selected abilities from strife creator UI (not from other sources)
      // Abilities from kits, class features, ancestry, etc. are already saved by their respective services
      // We only need to save abilities that the user explicitly chose in the strife UI slots
      updates.add(
        ref.read(appDatabaseProvider).setHeroComponentIds(
              heroId: widget.heroId,
              category: 'ability',
              componentIds: selectedAbilityIds,
            ),
      );

      // 10b. Save strife ability slot selections separately for proper restoration
      updates.add(db.setHeroConfig(
        heroId: widget.heroId,
        configKey: 'strife.ability_selections',
        value: _selectedAbilities.map((k, v) => MapEntry(k, v)),
      ));
      updates.add(db.deleteHeroConfig(widget.heroId, 'strife.import_ability_ids'));

      // 11. Save subclass skill via hero_entries (properly tracks source for removal on change)
      final subclassSkillId = _resolveSkillId(_selectedSubclass?.skill);
      updates.add(repo.saveSubclassSkill(widget.heroId, subclassSkillId));

      // Save the new subclass skill ID for future reference
      if (subclassSkillId != null && subclassSkillId.isNotEmpty) {
        updates.add(db.setHeroConfig(
          heroId: widget.heroId,
          configKey: 'strife.subclass_skill_id',
          value: {'id': subclassSkillId},
        ));
      } else {
        updates.add(
            db.deleteHeroConfig(widget.heroId, 'strife.subclass_skill_id'));
      }

      // 12. Save selected skills to database
      // After clearStrifeData, only story-sourced skills remain - we add new strife selections
      // Collect strife-selected skills (NOT including subclass skill - that's tracked via entries)
      final strifeSkillIds = _selectedSkills.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      final grantSkillIds = Set<String>.from(_skillGrantIds);

      // Get story-sourced skills (from ancestry, career, complication, culture)
      // These are preserved across class changes
      final storySkillIds = _dbSavedSkillIds;

      // Save ONLY user-selected skills from strife creator UI slots
      // (not including story skills from career/culture or class feature grants)
      // Story skills and grants are already saved by their respective services
      final strifeOnlySkills = strifeSkillIds.difference(storySkillIds).difference(grantSkillIds);
      
      updates.add(
        db.setHeroComponentIds(
          heroId: widget.heroId,
          category: 'skill',
          componentIds: strifeOnlySkills.toList(),
        ),
      );

      // 12b. Save strife skill slot selections separately for proper restoration
      updates.add(db.setHeroConfig(
        heroId: widget.heroId,
        configKey: 'strife.skill_selections',
        value: _selectedSkills.map((k, v) => MapEntry(k, v)),
      ));

      // 13. Save selected perks to database
      // After clearStrifeData, only story-sourced perks remain
      final strifePerkIds = _selectedPerks.values
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      // Get story-sourced perks (from ancestry, career, complication, culture)
      final storyPerkIds = _dbSavedPerkIds;

      // Save ONLY user-selected perks from strife creator UI
      // (not including story perks from career/complication)
      // Story perks are already saved by their respective services
      final strifeOnlyPerks = strifePerkIds.difference(storyPerkIds);
      
      updates.add(
        db.setHeroComponentIds(
          heroId: widget.heroId,
          category: 'perk',
          componentIds: strifeOnlyPerks.toList(),
        ),
      );

      // 13b. Save strife perk slot selections separately for proper restoration
      updates.add(db.setHeroConfig(
        heroId: widget.heroId,
        configKey: 'strife.perk_selections',
        value: _selectedPerks.map((k, v) => MapEntry(k, v)),
      ));

      // Execute all updates
      await Future.wait(updates);

      if (!mounted) return;

      // 14. Apply class feature grants so bonuses apply even without visiting the Strength page
      // Load any existing feature selections and apply the grants
      try {
        final savedFeatureSelections =
            await repo.getFeatureSelections(widget.heroId);
        final grantService = ClassFeatureGrantsService(db);
        await grantService.applyClassFeatureSelections(
          heroId: widget.heroId,
          classData: classData,
          level: _selectedLevel,
          selections: savedFeatureSelections,
          subclassSelection: _selectedSubclass,
        );
      } catch (e) {
        // Best-effort: class feature grants are non-critical for the main save
        debugPrint('Failed to apply class feature grants: $e');
      }

      if (!mounted) return;

      // Invalidate providers so UI reflects the saved data (same as Kits tab)
      ref.invalidate(heroRepositoryProvider);
      ref.invalidate(heroEquipmentBonusesProvider(widget.heroId));
      ref.invalidate(heroValuesProvider(widget.heroId));
      ref.invalidate(heroAssemblyProvider(widget.heroId));

      // Update local state with the new saved IDs
      _savedSubclassSkillId = subclassSkillId;
      _savedClassId =
          classData.classId; // Update saved class ID after successful save

      setState(() {
        _isDirty = false;
      });
      widget.onDirtyChanged?.call(false);
      _syncSnapshot();
      widget.onSaveRequested?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved!'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${StrifeCreatorPageText.failedToSavePrefix}$e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeData();
                },
                child: const Text(StrifeCreatorPageText.retryLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('strife_creator_scroll_view'),
        child: Column(
          children: [
            // Level Selector
            LevelSelectorWidget(
              key: const ValueKey('level_selector'),
              selectedLevel: _selectedLevel,
              onLevelChanged: _handleLevelChanged,
            ),

            // Class Selector
            ClassSelectorWidget(
              key: const ValueKey('class_selector'),
              availableClasses: _classDataService.getAllClasses(),
              selectedClass: _selectedClass,
              selectedLevel: _selectedLevel,
              onClassChanged: _handleClassChanged,
            ),

            if (_selectedClass != null) ...[
              ChooseSubclassWidget(
                key: const ValueKey('choose_subclass'),
                classData: _selectedClass!,
                selectedLevel: _selectedLevel,
                selectedSubclass: _selectedSubclass,
                onSelectionChanged: _handleSubclassSelectionChanged,
                // Pass reserved skills excluding the current subclass's own skill
                // so it doesn't flag itself as a duplicate
                reservedSkillIds: {
                  ..._baseSkillIds,
                  ..._normalizeSkillIds(
                      _selectedSkills.values.whereType<String>()),
                  ..._dbSavedSkillIds,
                },
                skillNameToIdLookup: _skillIdLookup,
                // Pass the saved subclass skill ID to avoid self-flagging
                savedSubclassSkillId: _savedSubclassSkillId,
              ),
              StartingCharacteristicsWidget(
                key: const ValueKey('starting_characteristics'),
                classData: _selectedClass!,
                selectedLevel: _selectedLevel,
                selectedArray: _selectedArray,
                assignedCharacteristics: _assignedCharacteristics,
                initialLevelChoiceSelections: _levelChoiceSelections,
                onArrayChanged: _handleArrayChanged,
                onAssignmentsChanged: _handleAssignmentsChanged,
                onFinalTotalsChanged: _handleFinalTotalsChanged,
                onLevelChoiceSelectionsChanged:
                    _handleLevelChoiceSelectionsChanged,
              ),
              ..._buildKitWidgets(),
              StartingAbilitiesWidget(
                key: const ValueKey('starting_abilities'),
                classData: _selectedClass!,
                selectedLevel: _selectedLevel,
                selectedSubclassName: _selectedSubclass?.subclassName,
                selectedDomainNames: _selectedSubclass?.domainNames ?? const [],
                selectedAbilities: _selectedAbilities,
                reservedAbilityIds: _reservedAbilityIds,
                onSelectionChanged: _handleAbilitySelectionsChanged,
              ),
              StartingSkillsWidget(
                key: const ValueKey('starting_skills'),
                classData: _selectedClass!,
                selectedLevel: _selectedLevel,
                selectedSubclass: _selectedSubclass,
                selectedSkills: _selectedSkills,
                reservedSkillIds: _reservedSkillIds,
                onSelectionChanged: _handleSkillSelectionsChanged,
              ),
              StartingPerksWidget(
                key: const ValueKey('starting_perks'),
                heroId: widget.heroId,
                classData: _selectedClass!,
                selectedLevel: _selectedLevel,
                selectedPerks: _selectedPerks,
                reservedPerkIds: _reservedPerkIds,
                reservedLanguageIds: {
                  ..._reservedLanguageIds,
                  ..._dbSavedLanguageIds
                },
                reservedSkillIds: _reservedSkillIds,
                onSelectionChanged: _handlePerkSelectionsChanged,
              ),
            ],

            // Bottom padding
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Public type alias for accessing the internal state from parent widgets.
typedef StrifeCreatorPageState = _StrifeCreatorPageState;
