import 'package:flutter/foundation.dart';

@immutable
class SubclassOption {
  const SubclassOption({
    required this.key,
    required this.name,
    this.description,
    this.skill,
    this.skillGroup,
    this.domain,
    this.abilityName,
    this.raw = const <String, dynamic>{},
  });

  final String key;
  final String name;
  final String? description;
  final String? skill;
  final String? skillGroup;
  final String? domain;
  final String? abilityName;
  final Map<String, dynamic> raw;
}

@immutable
class SubclassFeatureData {
  const SubclassFeatureData({
    required this.featureName,
    this.featureDescription,
    this.options = const <SubclassOption>[],
  });

  final String featureName;
  final String? featureDescription;
  final List<SubclassOption> options;
}

@immutable
class DeityOption {
  const DeityOption({
    required this.id,
    required this.name,
    required this.category,
    required this.domains,
  });

  final String id;
  final String name;
  final String category;
  final List<String> domains;
}

@immutable
class SubclassPlan {
  const SubclassPlan({
    required this.classSlug,
    this.subclassFeatureName,
    this.subclassPickCount = 0,
    this.deityPickCount = 0,
    this.domainPickCount = 0,
    this.combineDomainsAsSubclass = false,
  });

  final String classSlug;
  final String? subclassFeatureName;
  final int subclassPickCount;
  final int deityPickCount;
  final int domainPickCount;
  final bool combineDomainsAsSubclass;

  bool get hasSubclassChoice =>
      (subclassFeatureName != null && subclassFeatureName!.isNotEmpty);

  bool get requiresDeity => deityPickCount > 0;

  bool get requiresDomains => domainPickCount > 0;
}

@immutable
class SubclassSelectionResult {
  const SubclassSelectionResult({
    this.subclassKey,
    this.subclassName,
    this.skill,
    this.skillGroup,
    this.deityId,
    this.deityName,
    this.domainNames = const <String>[],
  });

  final String? subclassKey;
  final String? subclassName;
  final String? skill;
  final String? skillGroup;
  final String? deityId;
  final String? deityName;
  final List<String> domainNames;

  SubclassSelectionResult copyWith({
    String? subclassKey,
    String? subclassName,
    String? skill,
    String? skillGroup,
    String? deityId,
    String? deityName,
    List<String>? domainNames,
  }) {
    return SubclassSelectionResult(
      subclassKey: subclassKey ?? this.subclassKey,
      subclassName: subclassName ?? this.subclassName,
      skill: skill ?? this.skill,
      skillGroup: skillGroup ?? this.skillGroup,
      deityId: deityId ?? this.deityId,
      deityName: deityName ?? this.deityName,
      domainNames: domainNames ?? this.domainNames,
    );
  }

  @override
  int get hashCode => Object.hash(
        subclassKey,
        subclassName,
        skill,
        skillGroup,
        deityId,
        deityName,
        Object.hashAll(domainNames),
      );

  @override
  bool operator ==(Object other) {
    return other is SubclassSelectionResult &&
        listEquals(other.domainNames, domainNames) &&
        other.subclassKey == subclassKey &&
        other.subclassName == subclassName &&
        other.skill == skill &&
        other.skillGroup == skillGroup &&
        other.deityId == deityId &&
        other.deityName == deityName;
  }
}
