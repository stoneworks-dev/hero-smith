import '../models/class_data.dart';
import '../models/characteristics_models.dart';
import '../models/skills_models.dart';
import '../models/subclass_models.dart';

/// Business helper for translating class data into skill allowances.
class StartingSkillsService {
  const StartingSkillsService();

  static const Set<String> _knownGroups = {
    'crafting',
    'exploration',
    'interpersonal',
    'intrigue',
    'lore',
  };

  StartingSkillPlan buildPlan({
    required ClassData classData,
    required int selectedLevel,
    SubclassSelectionResult? subclassSelection,
    List<SkillAllowance> additionalAllowances = const <SkillAllowance>[],
    List<String> additionalGrantedSkillNames = const <String>[],

    /// When true, excludes level-based skill allowances (from class level progression).
    /// These are handled in the Strength tab via class feature grants instead.
    bool excludeLevelAllowances = false,

    /// When true, excludes subclass skill_group allowances (from class features).
    /// These are handled in the Strength tab via the subclass feature's skill_group option.
    bool excludeSubclassSkillAllowances = false,
  }) {
    final startingSkills = classData.startingCharacteristics.startingSkills;
    final startingAllowances =
        _buildStartingAllowances(startingSkills: startingSkills);

    final levelAllowances = excludeLevelAllowances
        ? <SkillAllowance>[]
        : _buildLevelAllowances(
            classData: classData,
            selectedLevel: selectedLevel,
          );

    final subclassAllowances = excludeSubclassSkillAllowances
        ? const _StartingAllowanceBundle(
            allowances: <SkillAllowance>[],
            grantedSkills: <String>[],
          )
        : _buildSubclassAllowances(subclassSelection: subclassSelection);

    final combined = <SkillAllowance>[
      ...startingAllowances.allowances,
      ...levelAllowances,
      ...subclassAllowances.allowances,
      ...additionalAllowances,
    ];

    combined.sort((a, b) {
      if (a.level != b.level) {
        return a.level.compareTo(b.level);
      }
      return a.id.compareTo(b.id);
    });

    return StartingSkillPlan(
      allowances: combined,
      grantedSkillNames: [
        ...startingAllowances.grantedSkills,
        ...subclassAllowances.grantedSkills,
        ...additionalGrantedSkillNames,
      ],
      quickBuildSuggestions: startingSkills.quickBuild,
    );
  }

  _StartingAllowanceBundle _buildStartingAllowances({
    required StartingSkills startingSkills,
  }) {
    final allowances = <SkillAllowance>[];
    final granted = startingSkills.grantedSkills;

    var allowanceIndex = 0;

    void addAllowance({
      required int count,
      required Iterable<String> groups,
      List<String> individualChoices = const <String>[],
      bool includeGranted = false,
    }) {
      if (count <= 0) return;
      final normalizedGroups = _normalizeGroups(groups);
      final label = allowanceIndex == 0
          ? 'Starting Skills'
          : 'Starting Skills ${allowanceIndex + 1}';
      allowances.add(
        SkillAllowance(
          id: 'start-$allowanceIndex',
          level: 0,
          label: label,
          pickCount: count,
          allowedGroups: normalizedGroups,
          individualSkillChoices: individualChoices,
          isStarting: true,
          grantedSkillNames: includeGranted ? granted : const <String>[],
        ),
      );
      allowanceIndex++;
    }

    for (final allowance in startingSkills.allowances) {
      addAllowance(
        count: allowance.count,
        groups: allowance.groups,
        individualChoices: allowance.individualSkillChoices,
        includeGranted: allowanceIndex == 0,
      );
    }

    return _StartingAllowanceBundle(
      allowances: allowances,
      grantedSkills: granted,
    );
  }

  _StartingAllowanceBundle _buildSubclassAllowances({
    required SubclassSelectionResult? subclassSelection,
  }) {
    if (subclassSelection == null) {
      return const _StartingAllowanceBundle(
        allowances: <SkillAllowance>[],
        grantedSkills: <String>[],
      );
    }

    final allowances = <SkillAllowance>[];
    final granted = <String>[];

    final grantedSkill = subclassSelection.skill?.trim();
    if (grantedSkill != null && grantedSkill.isNotEmpty) {
      granted.add(grantedSkill);
    }

    final skillGroup = subclassSelection.skillGroup?.trim();
    if (skillGroup != null && skillGroup.isNotEmpty) {
      final normalizedGroups = _normalizeGroups([skillGroup]);
      final label = subclassSelection.subclassName != null &&
              subclassSelection.subclassName!.isNotEmpty
          ? '${subclassSelection.subclassName} Skill'
          : 'Subclass Skill';

      allowances.add(
        SkillAllowance(
          id: 'subclass-${subclassSelection.subclassKey ?? 'skill'}',
          level: 0,
          label: label,
          pickCount: 1,
          allowedGroups: normalizedGroups,
          isStarting: true,
        ),
      );
    }

    return _StartingAllowanceBundle(
      allowances: allowances,
      grantedSkills: granted,
    );
  }

  List<SkillAllowance> _buildLevelAllowances({
    required ClassData classData,
    required int selectedLevel,
  }) {
    final allowances = <SkillAllowance>[];

    for (final levelData in classData.levels) {
      if (levelData.level > selectedLevel) continue;
      final skills = levelData.skills;
      if (skills == null || skills.isEmpty) continue;

      var allowanceIndex = 0;
      for (final entry in skills) {
        final count = CharacteristicUtils.toIntOrNull(entry['count']) ?? 0;
        if (count <= 0) continue;

        final groups = <String>{};
        var allowAny = false;
        for (final mapEntry in entry.entries) {
          final key = mapEntry.key.toString().toLowerCase();
          if (!key.contains('group')) continue;
          final parsed = _extractStringList(mapEntry.value);
          final normalized = _normalizeGroups(parsed);
          if (normalized.isEmpty &&
              parsed.any(
                  (value) => value.toString().toLowerCase().contains('any'))) {
            allowAny = true;
            break;
          }
          groups.addAll(normalized);
        }

        final label = allowanceIndex == 0
            ? 'Level ${levelData.level} Skills'
            : 'Level ${levelData.level} Skills (${allowanceIndex + 1})';
        allowances.add(
          SkillAllowance(
            id: 'level-${levelData.level}-$allowanceIndex',
            level: levelData.level,
            label: label,
            pickCount: count,
            allowedGroups: allowAny ? <String>{} : groups,
          ),
        );
        allowanceIndex++;
      }
    }

    return allowances;
  }

  Set<String> _normalizeGroups(Iterable<String> groups) {
    var allowAny = false;
    final normalized = <String>{};
    for (final group in groups) {
      final lower = group.trim().toLowerCase();
      if (lower.isEmpty) continue;
      if (lower == 'any' || lower == 'all') {
        allowAny = true;
        continue;
      }
      var matched = false;
      for (final known in _knownGroups) {
        if (lower == known || lower.contains(known)) {
          normalized.add(known);
          matched = true;
        }
      }
      if (!matched && lower.contains('any')) {
        allowAny = true;
      }
    }
    return allowAny ? <String>{} : normalized;
  }

  List<String> _extractStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      final tokens = value.split(RegExp(r',|/|\\bor\\b', caseSensitive: false));
      return tokens.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }
}

class _StartingAllowanceBundle {
  const _StartingAllowanceBundle({
    required this.allowances,
    required this.grantedSkills,
  });

  final List<SkillAllowance> allowances;
  final List<String> grantedSkills;
}
