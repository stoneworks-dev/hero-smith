import 'forge_steel_hero_export.dart';
import 'hero_export_models.dart';

/// Checks the stable structural subset expected by the pinned Forge importer.
///
/// This is deliberately a local shape validator, not a rules-content
/// validator: whether a named item exists in a particular Codex rules build is
/// an upstream/catalog concern and must not be guessed here.
class ForgeSteelExportValidator {
  ForgeSteelExportValidator._();

  /// Validates the final JSON object, including serializer output.
  static List<ExportIssue> validate(ForgeSteelHeroExport export) =>
      validateJson(export.toJson());

  static List<ExportIssue> validateJson(Map<String, dynamic> json) {
    final issues = <ExportIssue>[];

    _requiredText(
      issues,
      value: json['name'],
      fieldPath: 'name',
      message: 'Codex exports require a non-empty hero name.',
    );
    final heroClass = json['class'];
    if (heroClass is! Map) {
      issues.add(_error(
        fieldPath: 'class',
        message: 'Codex exports require a class object.',
      ));
      return List.unmodifiable(issues);
    }
    _requiredText(
      issues,
      value: heroClass['name'],
      fieldPath: 'class.name',
      message: 'Codex exports require a non-empty class name.',
    );
    if (heroClass['level'] is! num || (heroClass['level'] as num) < 1) {
      issues.add(_error(
        fieldPath: 'class.level',
        message: 'Codex exports require a positive class level.',
      ));
    }

    const requiredCharacteristics = {
      'Might',
      'Agility',
      'Reason',
      'Intuition',
      'Presence',
    };
    final characteristics = heroClass['characteristics'];
    final actualCharacteristics = characteristics is List
        ? characteristics
            .whereType<Map>()
            .map((item) => item['characteristic'])
            .whereType<String>()
            .toList(growable: false)
        : const <String>[];
    if (actualCharacteristics.length != requiredCharacteristics.length ||
        characteristics is! List ||
        characteristics.length != requiredCharacteristics.length ||
        actualCharacteristics.toSet().length != actualCharacteristics.length ||
        !actualCharacteristics.toSet().containsAll(requiredCharacteristics)) {
      issues.add(_error(
        fieldPath: 'class.characteristics',
        message: 'Codex exports require exactly the five standard characteristics.',
      ));
    }

    _validateAbilities(issues, heroClass['abilities']);
    _validateFeaturesByLevel(
      issues,
      heroClass['featuresByLevel'],
      fieldPath: 'class.featuresByLevel',
    );
    final subclasses = heroClass['subclasses'];
    if (subclasses is! List) {
      issues.add(_error(
        fieldPath: 'class.subclasses',
        message: 'Codex class subclasses must be a list.',
      ));
      return List.unmodifiable(issues);
    }
    for (var index = 0; index < subclasses.length; index++) {
      final subclass = subclasses[index];
      if (subclass is! Map) {
        issues.add(_error(
          fieldPath: 'class.subclasses[$index]',
          message: 'Every subclass must be an object.',
        ));
        continue;
      }
      _requiredText(
        issues,
        value: subclass['name'],
        fieldPath: 'class.subclasses[$index].name',
        message: 'A subclass selection requires a non-empty name.',
      );
      _validateFeaturesByLevel(
        issues,
        subclass['featuresByLevel'],
        fieldPath: 'class.subclasses[$index].featuresByLevel',
      );
    }
    return List.unmodifiable(issues);
  }

  static void _validateAbilities(
    List<ExportIssue> issues,
    dynamic abilities,
  ) {
    if (abilities is! List) {
      issues.add(_error(
        fieldPath: 'class.abilities',
        message: 'Codex class abilities must be a list.',
      ));
      return;
    }
    final ids = <String>{};
    for (var index = 0; index < abilities.length; index++) {
      final ability = abilities[index];
      if (ability is! Map) {
        issues.add(_error(
          fieldPath: 'class.abilities[$index]',
          message: 'Every exported ability reference must be an object.',
        ));
        continue;
      }
      final id = ability['id'];
      _requiredText(
        issues,
        value: id,
        fieldPath: 'class.abilities[$index].id',
        message: 'Every exported ability reference requires an ID.',
      );
      _requiredText(
        issues,
        value: ability['name'],
        fieldPath: 'class.abilities[$index].name',
        message: 'Every exported ability reference requires a display name.',
      );
      if (id is String && !ids.add(id)) {
        issues.add(_error(
          fieldPath: 'class.abilities[$index].id',
          message: 'Ability IDs must not be duplicated in a Codex export.',
        ));
      }
    }
  }

  static void _validateFeaturesByLevel(
    List<ExportIssue> issues,
    dynamic levels, {
    required String fieldPath,
  }) {
    if (levels is! List) {
      issues.add(_error(
        fieldPath: fieldPath,
        message: 'Leveled features must be a list.',
      ));
      return;
    }
    final seenLevels = <int>{};
    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      final path = '$fieldPath[$index]';
      if (level is! Map) {
        issues.add(_error(
          fieldPath: path,
          message: 'Every leveled feature group must be an object.',
        ));
        continue;
      }
      final levelValue = level['level'];
      if (levelValue is! int || levelValue < 1) {
        issues.add(_error(
          fieldPath: '$path.level',
          message: 'Feature levels must be positive.',
        ));
      }
      if (levelValue is int && !seenLevels.add(levelValue)) {
        issues.add(_error(
          fieldPath: '$path.level',
          message: 'Feature levels must not be duplicated.',
        ));
      }
      final features = level['features'];
      if (features is! List) {
        issues.add(_error(
          fieldPath: '$path.features',
          message: 'Leveled feature groups must contain a features list.',
        ));
        continue;
      }
      for (var featureIndex = 0; featureIndex < features.length; featureIndex++) {
        final feature = features[featureIndex];
        if (feature is! Map) {
          issues.add(_error(
            fieldPath: '$path.features[$featureIndex]',
            message: 'Every feature must be an object.',
          ));
          continue;
        }
        _requiredText(
          issues,
          value: feature['type'],
          fieldPath: '$path.features[$featureIndex].type',
          message: 'Every feature requires a type.',
        );
        final data = feature['data'];
        if (data is! Map) {
          issues.add(_error(
            fieldPath: '$path.features[$featureIndex].data',
            message: 'Every feature requires a data object.',
          ));
          continue;
        }
        _validateSelectedIds(
          issues,
          data['selectedIDs'],
          fieldPath: '$path.features[$featureIndex].data.selectedIDs',
        );
      }
    }
  }

  static void _validateSelectedIds(
    List<ExportIssue> issues,
    dynamic selectedIds, {
    required String fieldPath,
  }) {
    if (selectedIds == null) return;
    if (selectedIds is! List) {
      issues.add(_error(
        fieldPath: fieldPath,
        message: 'selectedIDs must be a list when present.',
      ));
      return;
    }
    final seen = <String>{};
    for (var index = 0; index < selectedIds.length; index++) {
      final id = selectedIds[index];
      if (id is! String || id.trim().isEmpty) {
        issues.add(_error(
          fieldPath: '$fieldPath[$index]',
          message: 'Every selected ability ID must be non-empty text.',
        ));
      } else if (!seen.add(id)) {
        issues.add(_error(
          fieldPath: '$fieldPath[$index]',
          message: 'selectedIDs must not contain duplicates.',
        ));
      }
    }
  }

  static void _requiredText(
    List<ExportIssue> issues, {
    required dynamic value,
    required String fieldPath,
    required String message,
  }) {
    if (value is! String || value.trim().isEmpty) {
      issues.add(_error(fieldPath: fieldPath, message: message));
    }
  }

  static ExportIssue _error({
    required String fieldPath,
    required String message,
  }) =>
      ExportIssue(
        code: 'codex.schema_invalid',
        severity: ExportIssueSeverity.error,
        origin: ExportIssueOrigin.heroSmith,
        fieldPath: fieldPath,
        message: message,
      );
}
