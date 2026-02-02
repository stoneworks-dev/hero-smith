import 'dart:convert';

/// Domain aggregate for a Hero. Backed by DB tables Heroes, HeroValues, HeroComponents.
/// This model is shaped for easy read/write in UI and maps to DB via repository.
class HeroModel {
  // Identity
  final String id;
  String name;

  // Basics
  String? className; // class component id
  String? subclass; // subclass component id
  int level;
  String? ancestry; // ancestry component id
  String? career; // career component id
  String? deityId; // chosen deity component id
  String? domain; // primary domain name

  // Victories & exp
  int victories;
  int exp;
  int wealth;
  int renown;

  // Stats
  int might;
  int agility;
  int reason;
  int intuition;
  int presence;
  int size;
  int speed;
  int disengage;
  int stability;

  // Stamina and recoveries
  int staminaCurrent;
  int staminaMax;
  int staminaTemp;
  int windedValue;
  int dyingValue;
  int recoveriesCurrent;
  int recoveriesValue;
  int recoveriesMax;

  // Heroic resource
  String? heroicResource; // name/type of the resource (varies by class)
  int heroicResourceCurrent;

  // Surges
  int surgesCurrent;

  // Damage immunities and weaknesses
  List<String> immunities; // component ids or strings
  List<String> weaknesses;

  // Potencies
  String? potencyStrong;
  String? potencyAverage;
  String? potencyWeak;

  // Conditions
  List<String> conditions; // list of condition ids

  // Features (component ids by category)
  List<String> classFeatures;
  List<String> ancestryTraits;
  List<String> languages;
  List<String> skills;
  List<String> perks;
  List<String> projects;
  int projectPoints;
  List<String> titles;
  List<String> abilities; // known abilities

  // Modifications: arbitrary stat modifiers outside of components
  // Represented as key -> delta (can be negative). E.g. { 'might': +1 }
  Map<String, int> modifications;

  HeroModel({
    required this.id,
    required this.name,
    this.className,
    this.subclass,
    this.level = 1,
    this.ancestry,
    this.career,
    this.deityId,
    this.domain,
    this.victories = 0,
    this.exp = 0,
    this.wealth = 0,
    this.renown = 0,
    this.might = 0,
    this.agility = 0,
    this.reason = 0,
    this.intuition = 0,
    this.presence = 0,
    this.size = 0,
    this.speed = 0,
    this.disengage = 0,
    this.stability = 0,
    this.staminaCurrent = 0,
    this.staminaMax = 0,
    this.staminaTemp = 0,
    this.windedValue = 0,
    this.dyingValue = 0,
    this.recoveriesCurrent = 0,
    this.recoveriesValue = 0,
    this.recoveriesMax = 0,
    this.heroicResource,
    this.heroicResourceCurrent = 0,
    this.surgesCurrent = 0,
    List<String>? immunities,
    List<String>? weaknesses,
    this.potencyStrong,
    this.potencyAverage,
    this.potencyWeak,
    List<String>? conditions,
    List<String>? classFeatures,
    List<String>? ancestryTraits,
    List<String>? languages,
    List<String>? skills,
    List<String>? perks,
    List<String>? projects,
    this.projectPoints = 0,
    List<String>? titles,
    List<String>? abilities,
    Map<String, int>? modifications,
  })  : immunities = immunities ?? <String>[],
        weaknesses = weaknesses ?? <String>[],
        conditions = conditions ?? <String>[],
        classFeatures = classFeatures ?? <String>[],
        ancestryTraits = ancestryTraits ?? <String>[],
        languages = languages ?? <String>[],
        skills = skills ?? <String>[],
        perks = perks ?? <String>[],
        projects = projects ?? <String>[],
        titles = titles ?? <String>[],
        abilities = abilities ?? <String>[],
        modifications = modifications ?? <String, int>{};

  // Export/Import helpers (for backup)
  Map<String, dynamic> toExportJson() => {
        'id': id,
        'name': name,
        'basics': {
          'className': className,
          'subclass': subclass,
          'level': level,
          'ancestry': ancestry,
          'career': career,
        },
        'faith': {
          'deity': deityId,
          'domain': domain,
        },
        'victories': victories,
        'exp': exp,
        'wealth': wealth,
        'renown': renown,
        'stats': {
          'might': might,
          'agility': agility,
          'reason': reason,
          'intuition': intuition,
          'presence': presence,
          'size': size,
          'speed': speed,
          'disengage': disengage,
          'stability': stability,
        },
        'stamina': {
          'stamina_current': staminaCurrent,
          'stamina_max': staminaMax,
          'stamina_temp': staminaTemp,
          'winded_value': windedValue,
          'dying_value': dyingValue,
          'recoveries_current': recoveriesCurrent,
          'recoveries_value': recoveriesValue,
          'recoveries_max': recoveriesMax,
        },
        'heroic_resource': {
          'type': heroicResource,
          'current': heroicResourceCurrent,
        },
        'surges_current': surgesCurrent,
        'immunities': immunities,
        'weaknesses': weaknesses,
        'potencies': {
          'strong': potencyStrong,
          'average': potencyAverage,
          'weak': potencyWeak,
        },
        'conditions': conditions,
        'features': {
          'class_features': classFeatures,
          'ancestry_traits': ancestryTraits,
          'languages': languages,
          'skills': skills,
          'perks': perks,
          'projects': projects,
          'project_points': projectPoints,
          'titles': titles,
          'abilities': abilities,
        },
        'modifications': modifications,
      };

  String toExportString() => jsonEncode(toExportJson());

  factory HeroModel.fromExportJson(Map<String, dynamic> j) {
    final basics = (j['basics'] as Map<String, dynamic>? ?? {});
    final faith = (j['faith'] as Map<String, dynamic>? ?? {});
    final stats = (j['stats'] as Map<String, dynamic>? ?? {});
    final stamina = (j['stamina'] as Map<String, dynamic>? ?? {});
    final heroic = (j['heroic_resource'] as Map<String, dynamic>? ?? {});
    final pots = (j['potencies'] as Map<String, dynamic>? ?? {});
    final feats = (j['features'] as Map<String, dynamic>? ?? {});
    return HeroModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      className: basics['className'] as String?,
      subclass: basics['subclass'] as String?,
      level: _toInt(basics['level']) ?? 1,
      ancestry: basics['ancestry'] as String?,
      career: basics['career'] as String?,
      deityId: faith['deity'] as String?,
      domain: faith['domain'] as String?,
      victories: _toInt(j['victories']) ?? 0,
      exp: _toInt(j['exp']) ?? 0,
      wealth: _toInt(j['wealth']) ?? 0,
      renown: _toInt(j['renown']) ?? 0,
      might: _toInt(stats['might']) ?? 0,
      agility: _toInt(stats['agility']) ?? 0,
      reason: _toInt(stats['reason']) ?? 0,
      intuition: _toInt(stats['intuition']) ?? 0,
      presence: _toInt(stats['presence']) ?? 0,
      size: _toInt(stats['size']) ?? 0,
      speed: _toInt(stats['speed']) ?? 0,
      disengage: _toInt(stats['disengage']) ?? 0,
      stability: _toInt(stats['stability']) ?? 0,
      staminaCurrent: _toInt(stamina['stamina_current']) ?? 0,
      staminaMax: _toInt(stamina['stamina_max']) ?? 0,
      staminaTemp: _toInt(stamina['stamina_temp']) ?? 0,
      windedValue: _toInt(stamina['winded_value']) ?? 0,
      dyingValue: _toInt(stamina['dying_value']) ?? 0,
      recoveriesCurrent: _toInt(stamina['recoveries_current']) ?? 0,
      recoveriesValue: _toInt(stamina['recoveries_value']) ?? 0,
      recoveriesMax: _toInt(stamina['recoveries_max']) ?? 0,
      heroicResource: heroic['type'] as String?,
      heroicResourceCurrent: _toInt(heroic['current']) ?? 0,
      surgesCurrent: _toInt(j['surges_current']) ?? 0,
      immunities: (j['immunities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      weaknesses: (j['weaknesses'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      potencyStrong: pots['strong'] as String?,
      potencyAverage: pots['average'] as String?,
      potencyWeak: pots['weak'] as String?,
      conditions: (j['conditions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      classFeatures: (feats['class_features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ancestryTraits: (feats['ancestry_traits'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      languages: (feats['languages'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: (feats['skills'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      perks: (feats['perks'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      projects: (feats['projects'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      projectPoints: _toInt(feats['project_points']) ?? 0,
      titles: (feats['titles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      abilities: (feats['abilities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      modifications: (j['modifications'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, _toInt(v) ?? 0)),
    );
  }

  static int? _toInt(dynamic v) => switch (v) {
        int i => i,
        double d => d.round(),
        String s => int.tryParse(s),
        _ => null,
      };
}
