import '../storage/hero_storage_contract.dart';
import 'stat_modification_model.dart';

const canonicalGrantSchemaId = 'hero_smith.grants.v1';

enum CanonicalGrantKind {
  entry,
  choice,
  statMod,
  resistance,
  token,
  treasure,
  equipmentBonuses,
}

extension CanonicalGrantKindCodec on CanonicalGrantKind {
  String get jsonValue => switch (this) {
        CanonicalGrantKind.entry => 'entry',
        CanonicalGrantKind.choice => 'choice',
        CanonicalGrantKind.statMod => 'stat_mod',
        CanonicalGrantKind.resistance => 'resistance',
        CanonicalGrantKind.token => 'token',
        CanonicalGrantKind.treasure => 'treasure',
        CanonicalGrantKind.equipmentBonuses => 'equipment_bonuses',
      };

  static CanonicalGrantKind parse(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'entry' => CanonicalGrantKind.entry,
      'choice' => CanonicalGrantKind.choice,
      'stat_mod' || 'statmod' => CanonicalGrantKind.statMod,
      'resistance' => CanonicalGrantKind.resistance,
      'token' => CanonicalGrantKind.token,
      'treasure' => CanonicalGrantKind.treasure,
      'equipment_bonuses' ||
      'equipmentbonuses' =>
        CanonicalGrantKind.equipmentBonuses,
      _ => throw FormatException('Unknown grant kind: $value'),
    };
  }
}

class CanonicalGrantDocument {
  const CanonicalGrantDocument({
    this.schema = canonicalGrantSchemaId,
    required this.grants,
  });

  final String schema;
  final List<CanonicalGrant> grants;

  factory CanonicalGrantDocument.fromJson(
    Map<String, dynamic> json, {
    String defaultSource = 'Grant',
  }) {
    return CanonicalGrantDocument(
      schema: json['schema']?.toString() ?? canonicalGrantSchemaId,
      grants: CanonicalGrant.parseList(
        json['grants'] ?? const [],
        defaultSource: defaultSource,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'grants': grants.map((grant) => grant.toJson()).toList(),
      };
}

sealed class CanonicalGrant {
  const CanonicalGrant({
    required this.kind,
    this.id,
    this.label,
  });

  final CanonicalGrantKind kind;
  final String? id;
  final String? label;

  static List<CanonicalGrant> parseList(
    dynamic value, {
    String defaultSource = 'Grant',
  }) {
    if (value == null) return const [];
    if (value is Map) {
      final map = _stringKeyedMap(value);
      if (map.containsKey('grants')) {
        return parseList(map['grants'], defaultSource: defaultSource);
      }
      return [CanonicalGrant.fromJson(map, defaultSource: defaultSource)];
    }
    if (value is! List) {
      throw FormatException('Expected grant list, got ${value.runtimeType}');
    }
    return value.map((item) {
      if (item is! Map) {
        throw FormatException(
          'Expected grant object, got ${item.runtimeType}',
        );
      }
      return CanonicalGrant.fromJson(
        _stringKeyedMap(item),
        defaultSource: defaultSource,
      );
    }).toList(growable: false);
  }

  factory CanonicalGrant.fromJson(
    Map<String, dynamic> json, {
    String defaultSource = 'Grant',
  }) {
    final kind = CanonicalGrantKindCodec.parse(
      _requireString(json, 'kind'),
    );

    return switch (kind) {
      CanonicalGrantKind.entry => CanonicalEntryGrant.fromJson(json),
      CanonicalGrantKind.choice => CanonicalChoiceGrant.fromJson(json),
      CanonicalGrantKind.statMod => CanonicalStatModGrant.fromJson(
          json,
          defaultSource: defaultSource,
        ),
      CanonicalGrantKind.resistance => CanonicalResistanceGrant.fromJson(json),
      CanonicalGrantKind.token => CanonicalTokenGrant.fromJson(json),
      CanonicalGrantKind.treasure => CanonicalTreasureGrant.fromJson(json),
      CanonicalGrantKind.equipmentBonuses =>
        CanonicalEquipmentBonusesGrant.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() => {
        'kind': kind.jsonValue,
        if (id != null) 'id': id,
        if (label != null) 'label': label,
      };
}

class CanonicalEntryGrant extends CanonicalGrant {
  const CanonicalEntryGrant({
    super.id,
    super.label,
    required this.entryType,
    required this.entryId,
    this.gainedBy = HeroEntryGainedBy.grant,
    this.payload,
  }) : super(kind: CanonicalGrantKind.entry);

  final String entryType;
  final String entryId;
  final String gainedBy;
  final Map<String, dynamic>? payload;

  factory CanonicalEntryGrant.fromJson(Map<String, dynamic> json) {
    final entryType = _readString(json, 'entry_type', aliases: ['entryType']);
    if (!HeroEntryTypes.isValid(entryType)) {
      throw FormatException('Invalid entry_type: $entryType');
    }

    final gainedBy = _readString(
      json,
      'gained_by',
      aliases: ['gainedBy'],
      fallback: HeroEntryGainedBy.grant,
    );
    if (!HeroEntryGainedBy.isValid(gainedBy)) {
      throw FormatException('Invalid gained_by: $gainedBy');
    }

    return CanonicalEntryGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      entryType: entryType,
      entryId: _readString(json, 'entry_id', aliases: ['entryId']),
      gainedBy: gainedBy,
      payload: _optionalMap(json['payload']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'entry_type': entryType,
        'entry_id': entryId,
        if (gainedBy != HeroEntryGainedBy.grant) 'gained_by': gainedBy,
        if (payload != null) 'payload': payload,
      };
}

class CanonicalChoiceGrant extends CanonicalGrant {
  const CanonicalChoiceGrant({
    super.id,
    super.label,
    required this.choiceKey,
    required this.choiceType,
    this.configKey,
    this.entryType,
    this.count = 1,
    this.groups = const [],
    this.options = const [],
    this.allowOwned = false,
    this.payload,
  }) : super(kind: CanonicalGrantKind.choice);

  final String choiceKey;
  final String choiceType;
  final String? configKey;
  final String? entryType;
  final int count;
  final List<String> groups;
  final List<String> options;
  final bool allowOwned;
  final Map<String, dynamic>? payload;

  factory CanonicalChoiceGrant.fromJson(Map<String, dynamic> json) {
    final entryType =
        _optionalString(json, 'entry_type', aliases: ['entryType']);
    if (entryType != null && !HeroEntryTypes.isValid(entryType)) {
      throw FormatException('Invalid entry_type: $entryType');
    }

    return CanonicalChoiceGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      choiceKey: _readString(json, 'choice_key', aliases: ['choiceKey']),
      choiceType: _readString(
        json,
        'choice_type',
        aliases: ['choiceType'],
      ),
      configKey: _optionalString(json, 'config_key', aliases: ['configKey']),
      entryType: entryType,
      count: _readInt(json, 'count', fallback: 1),
      groups: _stringList(json['groups'] ?? json['group']),
      options: _stringList(json['options']),
      allowOwned: _readBool(
        json,
        'allow_owned',
        aliases: ['allowOwned'],
      ),
      payload: _optionalMap(json['payload']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'choice_key': choiceKey,
        'choice_type': choiceType,
        if (configKey != null) 'config_key': configKey,
        if (entryType != null) 'entry_type': entryType,
        if (count != 1) 'count': count,
        if (groups.isNotEmpty) 'groups': groups,
        if (options.isNotEmpty) 'options': options,
        if (allowOwned) 'allow_owned': true,
        if (payload != null) 'payload': payload,
      };
}

class CanonicalStatModGrant extends CanonicalGrant {
  const CanonicalStatModGrant({
    super.id,
    super.label,
    required this.stat,
    required this.modifications,
    this.entryId,
    this.payload,
  }) : super(kind: CanonicalGrantKind.statMod);

  final String stat;
  final List<StatModification> modifications;
  final String? entryId;
  final Map<String, dynamic>? payload;

  factory CanonicalStatModGrant.fromJson(
    Map<String, dynamic> json, {
    String defaultSource = 'Grant',
  }) {
    final modifications = _parseStatModifications(
      json,
      defaultSource: defaultSource,
    );
    if (modifications.isEmpty) {
      throw const FormatException('stat_mod grant requires at least one mod');
    }

    return CanonicalStatModGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      stat: _readString(json, 'stat'),
      entryId: _optionalString(json, 'entry_id', aliases: ['entryId']),
      modifications: modifications,
      payload: _optionalMap(json['payload']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'stat': stat,
        if (entryId != null) 'entry_id': entryId,
        'mods':
            modifications.map((modification) => modification.toJson()).toList(),
        if (payload != null) 'payload': payload,
      };
}

class CanonicalResistanceGrant extends CanonicalGrant {
  const CanonicalResistanceGrant({
    super.id,
    super.label,
    required this.damageType,
    this.immunity = 0,
    this.weakness = 0,
    this.dynamicImmunity,
    this.dynamicWeakness,
    this.immunityPerEchelon = 0,
    this.weaknessPerEchelon = 0,
  }) : super(kind: CanonicalGrantKind.resistance);

  final String damageType;
  final int immunity;
  final int weakness;
  final String? dynamicImmunity;
  final String? dynamicWeakness;
  final int immunityPerEchelon;
  final int weaknessPerEchelon;

  factory CanonicalResistanceGrant.fromJson(Map<String, dynamic> json) {
    return CanonicalResistanceGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      damageType: _readString(json, 'damage_type', aliases: ['damageType']),
      immunity: _readInt(json, 'immunity'),
      weakness: _readInt(json, 'weakness'),
      dynamicImmunity: _optionalString(
        json,
        'dynamic_immunity',
        aliases: ['dynamicImmunity'],
      ),
      dynamicWeakness: _optionalString(
        json,
        'dynamic_weakness',
        aliases: ['dynamicWeakness'],
      ),
      immunityPerEchelon: _readInt(
        json,
        'immunity_per_echelon',
        aliases: ['immunityPerEchelon'],
      ),
      weaknessPerEchelon: _readInt(
        json,
        'weakness_per_echelon',
        aliases: ['weaknessPerEchelon'],
      ),
    );
  }

  bool get hasEffect =>
      immunity != 0 ||
      weakness != 0 ||
      dynamicImmunity != null ||
      dynamicWeakness != null ||
      immunityPerEchelon != 0 ||
      weaknessPerEchelon != 0;

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'damage_type': damageType,
        if (immunity != 0) 'immunity': immunity,
        if (weakness != 0) 'weakness': weakness,
        if (dynamicImmunity != null) 'dynamic_immunity': dynamicImmunity,
        if (dynamicWeakness != null) 'dynamic_weakness': dynamicWeakness,
        if (immunityPerEchelon != 0) 'immunity_per_echelon': immunityPerEchelon,
        if (weaknessPerEchelon != 0) 'weakness_per_echelon': weaknessPerEchelon,
      };
}

class CanonicalTokenGrant extends CanonicalGrant {
  const CanonicalTokenGrant({
    super.id,
    super.label,
    required this.token,
    this.maxValue = 0,
    this.currentValue,
  }) : super(kind: CanonicalGrantKind.token);

  final String token;
  final int maxValue;
  final int? currentValue;

  factory CanonicalTokenGrant.fromJson(Map<String, dynamic> json) {
    return CanonicalTokenGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      token: _readString(json, 'token'),
      maxValue: _readInt(
        json,
        'max_value',
        aliases: ['maxValue', 'value', 'count'],
      ),
      currentValue: _optionalInt(
        json,
        'current_value',
        aliases: ['currentValue'],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'token': token,
        'max_value': maxValue,
        if (currentValue != null) 'current_value': currentValue,
      };
}

class CanonicalTreasureGrant extends CanonicalGrant {
  const CanonicalTreasureGrant({
    super.id,
    super.label,
    required this.treasureId,
    this.quantity = 1,
    this.level,
    this.payload,
  }) : super(kind: CanonicalGrantKind.treasure);

  final String treasureId;
  final int quantity;
  final int? level;
  final Map<String, dynamic>? payload;

  factory CanonicalTreasureGrant.fromJson(Map<String, dynamic> json) {
    return CanonicalTreasureGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      treasureId: _readString(
        json,
        'treasure_id',
        aliases: ['treasureId', 'entry_id', 'entryId'],
      ),
      quantity: _readInt(json, 'quantity', aliases: ['count'], fallback: 1),
      level: _optionalInt(json, 'level'),
      payload: _optionalMap(json['payload']),
    );
  }

  Map<String, dynamic> get entryPayload => {
        'quantity': quantity,
        if (level != null) 'level': level,
        ...?payload,
      };

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'treasure_id': treasureId,
        if (quantity != 1) 'quantity': quantity,
        if (level != null) 'level': level,
        if (payload != null) 'payload': payload,
      };
}

class CanonicalEquipmentBonusesGrant extends CanonicalGrant {
  const CanonicalEquipmentBonusesGrant({
    super.id,
    super.label,
    this.entryId = 'combined_equipment_bonuses',
    required this.bonuses,
    this.tieredBonuses = const {},
    this.echelonBonuses = const {},
    this.leveledBonuses = const {},
    this.leveledImmunities = const {},
    this.payload,
  }) : super(kind: CanonicalGrantKind.equipmentBonuses);

  final String entryId;
  final Map<String, int> bonuses;
  final Map<String, Map<String, int>> tieredBonuses;
  final Map<String, Map<String, int>> echelonBonuses;
  final Map<String, Map<String, dynamic>> leveledBonuses;
  final Map<String, Map<String, dynamic>> leveledImmunities;
  final Map<String, dynamic>? payload;

  factory CanonicalEquipmentBonusesGrant.fromJson(Map<String, dynamic> json) {
    return CanonicalEquipmentBonusesGrant(
      id: _optionalString(json, 'id'),
      label: _optionalString(json, 'label'),
      entryId: _readString(
        json,
        'entry_id',
        aliases: ['entryId'],
        fallback: 'combined_equipment_bonuses',
      ),
      bonuses: _intMap(json['bonuses'] ?? _knownEquipmentBonusFields(json)),
      tieredBonuses: _nestedIntMap(
        _readRaw(
          json,
          'tiered_bonuses',
          aliases: ['tieredBonuses'],
        ),
      ),
      echelonBonuses: _nestedIntMap(
        _readRaw(
          json,
          'echelon_bonuses',
          aliases: ['echelonBonuses'],
        ),
      ),
      leveledBonuses: _nestedDynamicMap(
        _readRaw(
          json,
          'leveled_bonuses',
          aliases: ['leveledBonuses'],
        ),
      ),
      leveledImmunities: _nestedDynamicMap(
        _readRaw(
          json,
          'leveled_immunities',
          aliases: ['leveledImmunities'],
        ),
      ),
      payload: _optionalMap(json['payload']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        if (entryId != 'combined_equipment_bonuses') 'entry_id': entryId,
        'bonuses': bonuses,
        if (tieredBonuses.isNotEmpty) 'tiered_bonuses': tieredBonuses,
        if (echelonBonuses.isNotEmpty) 'echelon_bonuses': echelonBonuses,
        if (leveledBonuses.isNotEmpty) 'leveled_bonuses': leveledBonuses,
        if (leveledImmunities.isNotEmpty)
          'leveled_immunities': leveledImmunities,
        if (payload != null) 'payload': payload,
      };
}

List<StatModification> _parseStatModifications(
  Map<String, dynamic> json, {
  required String defaultSource,
}) {
  final rawMods = json['mods'] ?? json['mod'];
  if (rawMods is List) {
    return rawMods
        .whereType<Map>()
        .map(
          (modification) => StatModification.fromJson(
            _stringKeyedMap(modification),
            defaultSource: defaultSource,
          ),
        )
        .toList(growable: false);
  }
  if (rawMods is Map) {
    return [
      StatModification.fromJson(
        _stringKeyedMap(rawMods),
        defaultSource: defaultSource,
      ),
    ];
  }

  if (json.containsKey('value') ||
      json.containsKey('dynamicValue') ||
      json.containsKey('perEchelon')) {
    return [StatModification.fromJson(json, defaultSource: defaultSource)];
  }
  return const [];
}

Map<String, dynamic> _knownEquipmentBonusFields(Map<String, dynamic> json) {
  const keys = {
    'stamina',
    'speed',
    'stability',
    'disengage',
    'melee_damage',
    'ranged_damage',
    'melee_distance',
    'ranged_distance',
  };
  return {
    for (final key in keys)
      if (json.containsKey(key)) key: json[key],
  };
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> map) {
  return {for (final entry in map.entries) entry.key.toString(): entry.value};
}

Map<String, dynamic>? _optionalMap(dynamic value) {
  if (value is! Map) return null;
  return _stringKeyedMap(value);
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (_toInt(entry.value) != 0) entry.key.toString(): _toInt(entry.value),
  };
}

Map<String, Map<String, int>> _nestedIntMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, Map<String, int>>{};
  for (final entry in value.entries) {
    final nested = _intMapKeepingZero(entry.value);
    if (nested.isNotEmpty) {
      result[entry.key.toString()] = nested;
    }
  }
  return result;
}

Map<String, int> _intMapKeepingZero(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.value != null) entry.key.toString(): _toInt(entry.value),
  };
}

Map<String, Map<String, dynamic>> _nestedDynamicMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, Map<String, dynamic>>{};
  for (final entry in value.entries) {
    final nested = _optionalMap(entry.value);
    if (nested != null && nested.isNotEmpty) {
      result[entry.key.toString()] = nested;
    }
  }
  return result;
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final single = value.toString().trim();
  return single.isEmpty ? const [] : [single];
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) {
    throw FormatException('Missing required field: $key');
  }
  return value;
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
  String? fallback,
}) {
  final value = _readRaw(json, key, aliases: aliases);
  final text = value?.toString().trim() ?? fallback;
  if (text == null || text.isEmpty) {
    throw FormatException('Missing required field: $key');
  }
  return text;
}

String? _optionalString(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
}) {
  final value = _readRaw(json, key, aliases: aliases)?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
  int fallback = 0,
}) {
  final value = _readRaw(json, key, aliases: aliases);
  return value == null ? fallback : _toInt(value);
}

int? _optionalInt(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
}) {
  final value = _readRaw(json, key, aliases: aliases);
  return value == null ? null : _toInt(value);
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
}) {
  final value = _readRaw(json, key, aliases: aliases);
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

dynamic _readRaw(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
}) {
  if (json.containsKey(key)) return json[key];
  for (final alias in aliases) {
    if (json.containsKey(alias)) return json[alias];
  }
  return null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
