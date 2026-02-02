class PerkOption {
  const PerkOption({
    required this.id,
    required this.name,
    required this.group,
    required this.description,
    this.grantedAbilities = const [],
  });

  final String id;
  final String name;
  final String group;
  final String description;
  final List<String> grantedAbilities;
}

class PerkAllowance {
  const PerkAllowance({
    required this.id,
    required this.level,
    required this.label,
    required this.pickCount,
    required this.allowedGroups,
  });

  final String id;
  final int level;
  final String label;
  final int pickCount;
  final Set<String> allowedGroups;
}

class StartingPerkPlan {
  const StartingPerkPlan({
    required this.allowances,
  });

  final List<PerkAllowance> allowances;
}

class StartingPerkSelectionResult {
  const StartingPerkSelectionResult({
    required this.selectionsBySlot,
    required this.selectedPerkIds,
  });

  final Map<String, String?> selectionsBySlot;
  final Set<String> selectedPerkIds;
}
