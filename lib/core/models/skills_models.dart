class SkillOption {
  const SkillOption({
    required this.id,
    required this.name,
    required this.group,
    required this.description,
  });

  final String id;
  final String name;
  final String group;
  final String description;
}

class SkillAllowance {
  const SkillAllowance({
    required this.id,
    required this.level,
    required this.label,
    required this.pickCount,
    required this.allowedGroups,
    this.individualSkillChoices = const <String>[],
    this.isStarting = false,
    this.grantedSkillNames = const <String>[],
  });

  final String id;
  final int level;
  final String label;
  final int pickCount;
  final Set<String> allowedGroups;
  final List<String> individualSkillChoices;
  final bool isStarting;
  final List<String> grantedSkillNames;
}

class StartingSkillPlan {
  const StartingSkillPlan({
    required this.allowances,
    required this.grantedSkillNames,
    required this.quickBuildSuggestions,
  });

  final List<SkillAllowance> allowances;
  final List<String> grantedSkillNames;
  final List<String> quickBuildSuggestions;
}

class StartingSkillSelectionResult {
  const StartingSkillSelectionResult({
    required this.selectionsBySlot,
    required this.grantedSkillIds,
    required this.grantedSkillNames,
  });

  final Map<String, String?> selectionsBySlot;
  final Set<String> grantedSkillIds;
  final List<String> grantedSkillNames;

  Set<String> get selectedSkillIds =>
      selectionsBySlot.values.whereType<String>().toSet();
}
