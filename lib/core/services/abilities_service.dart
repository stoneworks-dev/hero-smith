import '../models/class_data.dart';
import '../models/abilities_models.dart';
import '../models/characteristics_models.dart';

/// Business helper for translating class data into ability allowances.
class StartingAbilitiesService {
  const StartingAbilitiesService();

  StartingAbilityPlan buildPlan({
    required ClassData classData,
    required int selectedLevel,
  }) {
    final allowances = <AbilityAllowance>[];

    for (final levelData in classData.levels) {
      if (levelData.level > selectedLevel) continue;
      allowances.addAll(
        _buildAllowances(
          level: levelData.level,
          grantMap: levelData.newAbilities,
          requiresSubclass: false,
          resourceName: classData.startingCharacteristics.heroicResourceName,
        ),
      );
      allowances.addAll(
        _buildAllowances(
          level: levelData.level,
          grantMap: levelData.newSubclassAbilities,
          requiresSubclass: true,
          resourceName: classData.startingCharacteristics.heroicResourceName,
        ),
      );
    }

    allowances.sort((a, b) {
      if (a.level != b.level) {
        return a.level.compareTo(b.level);
      }
      return a.id.compareTo(b.id);
    });

    return StartingAbilityPlan(allowances: allowances);
  }

  List<AbilityAllowance> _buildAllowances({
    required int level,
    required Map<String, dynamic>? grantMap,
    required bool requiresSubclass,
    required String resourceName,
  }) {
    if (grantMap == null || grantMap.isEmpty) {
      return const [];
    }

    final mapCopy = Map<String, dynamic>.from(grantMap);
    final includePreviousLevels =
        mapCopy.remove('grant_previous_levels') == true ||
        mapCopy.remove('grants_previous_levels') == true;

    final allowances = <AbilityAllowance>[];
    var allowanceIndex = 0;

    for (final entry in mapCopy.entries) {
      final key = entry.key.toString();
      final count = CharacteristicUtils.toIntOrNull(entry.value) ?? 0;
      if (count <= 0) continue;

      final parsed = _parseCostKey(key, resourceName: resourceName);
      allowances.add(
        AbilityAllowance(
          id: '${requiresSubclass ? 'sub' : 'base'}-$level-$allowanceIndex',
          level: level,
          pickCount: count,
          label: parsed.label,
          isSignature: parsed.isSignature,
          requiresSubclass: requiresSubclass,
          includePreviousLevels: includePreviousLevels,
          costAmount: parsed.costAmount,
          resource: parsed.resource,
        ),
      );
      allowanceIndex++;
    }

    return allowances;
  }

  _CostParseResult _parseCostKey(
    String key, {
    required String resourceName,
  }) {
    final normalized = key.trim().toLowerCase();
    if (normalized == 'signature') {
      return const _CostParseResult(
        label: 'Signature abilities',
        isSignature: true,
      );
    }

    final match = RegExp(r'^(\d+)_cost').firstMatch(normalized);
    if (match != null) {
      final amount = int.tryParse(match.group(1)!);
      final displayResource = resourceName.trim();
      final resourceLabel =
          displayResource.isEmpty ? '' : ' ${displayResource}';
      final label =
          amount != null ? 'Cost $amount$resourceLabel abilities' : key;
      return _CostParseResult(
        label: label,
        costAmount: amount,
        resource: displayResource.isEmpty ? null : displayResource,
      );
    }

    final fallbackLabel = key.isEmpty
        ? 'Abilities'
        : key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');
    return _CostParseResult(label: fallbackLabel);
  }
}

class _CostParseResult {
  const _CostParseResult({
    required this.label,
    this.isSignature = false,
    this.costAmount,
    this.resource,
  });

  final String label;
  final bool isSignature;
  final int? costAmount;
  final String? resource;
}
