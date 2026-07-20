import 'dart:convert';

class ForgeSteelHeroExport {
  const ForgeSteelHeroExport({
    required this.name,
    this.ancestry,
    this.culture,
    this.career,
    required this.heroClass,
    this.complication,
  });

  final String name;
  final ForgeAncestryExport? ancestry;
  final ForgeCultureExport? culture;
  final ForgeCareerExport? career;
  final ForgeClassExport heroClass;
  final ForgeNamedRef? complication;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (ancestry != null) 'ancestry': ancestry!.toJson(),
        if (culture != null) 'culture': culture!.toJson(),
        if (career != null) 'career': career!.toJson(),
        'class': heroClass.toJson(),
        if (complication != null) 'complication': complication!.toJson(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class ForgeNamedRef {
  const ForgeNamedRef({this.id, required this.name, this.description});

  final String? id;
  final String name;
  final String? description;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

class ForgeNamedSelection {
  const ForgeNamedSelection({
    this.id,
    required this.name,
    this.description,
    this.type,
    this.data,
    this.featuresByLevel,
  });

  final String? id;
  final String name;
  final String? description;
  final String? type;
  final Map<String, dynamic>? data;
  final List<ForgeLevelFeaturesExport>? featuresByLevel;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (type != null && type!.isNotEmpty) 'type': type,
        if (data != null && data!.isNotEmpty) 'data': data,
        if (featuresByLevel != null)
          'featuresByLevel':
              featuresByLevel!.map((level) => level.toJson()).toList(),
      };
}

class ForgeAncestryExport {
  const ForgeAncestryExport({
    this.id,
    required this.name,
    this.description,
    this.features = const [],
  });

  final String? id;
  final String name;
  final String? description;
  final List<ForgeFeatureExport> features;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'features': features.map((feature) => feature.toJson()).toList(),
      };
}

class ForgeCultureExport {
  const ForgeCultureExport({
    this.id,
    this.name,
    this.description,
    this.type,
    this.languages = const [],
    this.language,
    this.environment,
    this.organization,
    this.upbringing,
  });

  final String? id;
  final String? name;
  final String? description;
  final String? type;
  final List<String> languages;
  final ForgeFeatureExport? language;
  final ForgeCultureAspectExport? environment;
  final ForgeCultureAspectExport? organization;
  final ForgeCultureAspectExport? upbringing;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (type != null && type!.isNotEmpty) 'type': type,
        'languages': languages,
        if (language != null) 'language': language!.toJson(),
        if (environment != null) 'environment': environment!.toJson(),
        if (organization != null) 'organization': organization!.toJson(),
        if (upbringing != null) 'upbringing': upbringing!.toJson(),
      };
}

class ForgeCultureAspectExport {
  const ForgeCultureAspectExport({
    this.id,
    required this.name,
    this.description,
    this.options = const [],
    this.listOptions = const [],
    this.count = 1,
    this.selected = const [],
  });

  final String? id;
  final String name;
  final String? description;
  final List<String> options;
  final List<String> listOptions;
  final int count;
  final List<dynamic> selected;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'type': 'Skill Choice',
        'data': {
          'options': options,
          'listOptions': listOptions,
          'count': count,
          'selected': selected,
        },
      };
}

class ForgeCareerExport {
  const ForgeCareerExport({
    this.id,
    required this.name,
    this.description,
    this.features = const [],
    this.incitingIncident,
  });

  final String? id;
  final String name;
  final String? description;
  final List<ForgeFeatureExport> features;
  final ForgeNamedRef? incitingIncident;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'features': features.map((feature) => feature.toJson()).toList(),
        if (incitingIncident != null)
          'incitingIncidents': {
            'selected': incitingIncident!.toJson(),
          },
      };
}

class ForgeClassExport {
  const ForgeClassExport({
    this.id,
    required this.name,
    this.description,
    this.type,
    required this.level,
    required this.characteristics,
    this.primaryCharacteristicsOptions = const [],
    this.primaryCharacteristics = const [],
    this.characteristicArray,
    this.abilities = const [],
    this.featuresByLevel = const [],
    this.subclasses = const [],
  });

  final String? id;
  final String name;
  final String? description;
  final String? type;
  final int level;
  final List<ForgeCharacteristicExport> characteristics;
  final List<List<String>> primaryCharacteristicsOptions;
  final List<String> primaryCharacteristics;
  final Map<String, dynamic>? characteristicArray;
  final List<ForgeAbilityRefExport> abilities;
  final List<ForgeLevelFeaturesExport> featuresByLevel;
  final List<ForgeSubclassExport> subclasses;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (type != null && type!.isNotEmpty) 'type': type,
        if (primaryCharacteristicsOptions.isNotEmpty)
          'primaryCharacteristicsOptions': primaryCharacteristicsOptions,
        if (primaryCharacteristics.isNotEmpty)
          'primaryCharacteristics': primaryCharacteristics,
        'level': level,
        'characteristics':
            characteristics.map((item) => item.toJson()).toList(),
        if (characteristicArray != null && characteristicArray!.isNotEmpty)
          'characteristicArray': characteristicArray,
        'abilities': abilities.map((ability) => ability.toJson()).toList(),
        'featuresByLevel':
            featuresByLevel.map((level) => level.toJson()).toList(),
        'subclasses': subclasses.map((subclass) => subclass.toJson()).toList(),
      };
}

class ForgeCharacteristicExport {
  const ForgeCharacteristicExport({
    required this.characteristic,
    required this.value,
  });

  final String characteristic;
  final int value;

  Map<String, dynamic> toJson() => {
        'characteristic': characteristic,
        'value': value,
      };
}

class ForgeAbilityRefExport {
  const ForgeAbilityRefExport({
    required this.id,
    required this.name,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

class ForgeLevelFeaturesExport {
  const ForgeLevelFeaturesExport(
      {required this.level, this.features = const []});

  final int level;
  final List<ForgeFeatureExport> features;

  Map<String, dynamic> toJson() => {
        'level': level,
        'features': features.map((feature) => feature.toJson()).toList(),
      };
}

class ForgeSubclassExport {
  const ForgeSubclassExport({
    this.id,
    required this.name,
    this.description,
    this.selected = true,
    this.featuresByLevel = const [],
  });

  final String? id;
  final String name;
  final String? description;
  final bool selected;
  final List<ForgeLevelFeaturesExport> featuresByLevel;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'selected': selected,
        'featuresByLevel':
            featuresByLevel.map((level) => level.toJson()).toList(),
      };
}

class ForgeFeatureExport {
  const ForgeFeatureExport(
    this.type,
    this.data, {
    this.id,
    this.name,
    this.description,
  });

  final String type;
  final String? id;
  final String? name;
  final String? description;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'type': type,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'data': data,
      };

  static ForgeFeatureExport kit(
    List<ForgeNamedSelection> kits, {
    String? id,
    String? name,
  }) =>
      ForgeFeatureExport(
        'Kit',
        {
          'selected': kits.map((kit) => kit.toJson()).toList(),
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport classAbility(
    List<String> selectedAbilityIds, {
    String? id,
    String? name,
    int? cost,
    String? source,
    int? minLevel,
  }) =>
      ForgeFeatureExport(
        'Class Ability',
        {
          if (cost != null) 'cost': cost,
          if (source != null && source.isNotEmpty) 'source': source,
          if (minLevel != null) 'minLevel': minLevel,
          'count': selectedAbilityIds.length,
          'selectedIDs': selectedAbilityIds,
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport skillChoice(
    List<String> skillNames, {
    String? id,
    String? name,
    List<String> options = const [],
    List<String> listOptions = const [],
    int? count,
  }) =>
      ForgeFeatureExport(
        'Skill Choice',
        {
          'options': options,
          'listOptions': listOptions,
          'count': count ?? skillNames.length,
          'selected': skillNames,
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport languageChoice(
    List<String> languageNames, {
    String? id,
    String? name,
    int? count,
  }) =>
      ForgeFeatureExport(
        'Language Choice',
        {
          'options': const <String>[],
          'count': count ?? languageNames.length,
          'selected': languageNames,
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport perk(
    List<ForgeNamedSelection> perks, {
    String? id,
    String? name,
    List<String> lists = const [],
    int? count,
  }) =>
      ForgeFeatureExport(
        'Perk',
        {
          if (lists.isNotEmpty) 'lists': lists,
          if (count != null) 'count': count,
          'selected': perks.map((perk) => perk.toJson()).toList(),
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport domain(
    List<ForgeNamedSelection> domains, {
    String? id,
    String? name,
    int? count,
  }) =>
      ForgeFeatureExport(
        'Domain',
        {
          if (count != null) 'count': count,
          'selected': domains.map((domain) => domain.toJson()).toList(),
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport choice(
    List<ForgeNamedSelection> selections, {
    String? id,
    String? name,
  }) =>
      ForgeFeatureExport(
        'Choice',
        {
          'selected':
              selections.map((selection) => selection.toJson()).toList(),
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport ability(
    List<ForgeNamedSelection> selections, {
    String? id,
    String? name,
  }) =>
      ForgeFeatureExport(
        'Ability',
        {
          'selected':
              selections.map((selection) => selection.toJson()).toList(),
        },
        id: id,
        name: name,
      );

  static ForgeFeatureExport bonus(
          {required String field, required int value, String? id}) =>
      ForgeFeatureExport(
        'Bonus',
        {
          'field': field,
          'value': value,
          'valueFromController': null,
          'valueCharacteristics': const <String>[],
          'valueCharacteristicMultiplier': 1,
          'valuePerLevel': 0,
          'valuePerEchelon': 0,
        },
        id: id,
        name: field,
      );
}
