import '../models/class_data.dart';
import '../models/characteristics_models.dart';
import '../models/perks_models.dart';

/// Business helper for translating class data into perk allowances.
class StartingPerksService {
  const StartingPerksService();

  StartingPerkPlan buildPlan({
    required ClassData classData,
    required int selectedLevel,
  }) {
    final allowances = <PerkAllowance>[];

    for (final levelData in classData.levels) {
      if (levelData.level > selectedLevel) continue;
      final perks = levelData.perks;
      if (perks == null || perks.isEmpty) continue;

      var allowanceIndex = 0;
      for (final entry in perks) {
        final count = CharacteristicUtils.toIntOrNull(entry['count']) ?? 0;
        final effectiveCount = count > 0 ? count : 1;

        final groups = _extractGroups(entry);
        final allowAny = groups == null || groups.isEmpty;
        final Set<String> allowedGroups;
        if (allowAny) {
          allowedGroups = <String>{};
        } else {
          allowedGroups = Set<String>.from(groups);
        }

        final label = allowanceIndex == 0
            ? 'Level ${levelData.level} Perks'
            : 'Level ${levelData.level} Perks (${allowanceIndex + 1})';

        allowances.add(
          PerkAllowance(
            id: 'perk-${levelData.level}-$allowanceIndex',
            level: levelData.level,
            label: label,
            pickCount: effectiveCount,
            allowedGroups: allowedGroups,
          ),
        );
        allowanceIndex++;
      }
    }

    return StartingPerkPlan(allowances: allowances);
  }

  Set<String>? _extractGroups(Map<String, dynamic> entry) {
    final collected = <String>{};
    var foundGroupKey = false;

    for (final mapEntry in entry.entries) {
      final key = mapEntry.key.toString().toLowerCase();
      if (!key.contains('group')) continue;
      final parsed = _extractStringList(mapEntry.value);
      if (parsed.isEmpty) {
        continue;
      }
      foundGroupKey = true;
      for (final value in parsed) {
        final normalized = value.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        if (normalized == 'any' ||
            normalized == 'all' ||
            normalized.contains('any')) {
          return null;
        }
        collected.add(normalized);
      }
    }

    if (!foundGroupKey || collected.isEmpty) {
      return null;
    }
    return collected;
  }

  List<String> _extractStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      final tokens =
          value.split(RegExp(r',|/|\\bor\\b', caseSensitive: false));
      return tokens.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }
}
