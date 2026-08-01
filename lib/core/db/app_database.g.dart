// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ComponentsTable extends Components
    with TableInfo<$ComponentsTable, Component> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataJsonMeta =
      const VerificationMeta('dataJson');
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
      'data_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('seed'));
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES components (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, name, dataJson, source, parentId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'components';
  @override
  VerificationContext validateIntegrity(Insertable<Component> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(_dataJsonMeta,
          dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Component map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Component(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_json'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ComponentsTable createAlias(String alias) {
    return $ComponentsTable(attachedDatabase, alias);
  }
}

class Component extends DataClass implements Insertable<Component> {
  final String id;
  final String type;
  final String name;
  final String dataJson;
  final String source;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Component(
      {required this.id,
      required this.type,
      required this.name,
      required this.dataJson,
      required this.source,
      this.parentId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['data_json'] = Variable<String>(dataJson);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ComponentsCompanion toCompanion(bool nullToAbsent) {
    return ComponentsCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      dataJson: Value(dataJson),
      source: Value(source),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Component.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Component(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      source: serializer.fromJson<String>(json['source']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'dataJson': serializer.toJson<String>(dataJson),
      'source': serializer.toJson<String>(source),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Component copyWith(
          {String? id,
          String? type,
          String? name,
          String? dataJson,
          String? source,
          Value<String?> parentId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Component(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        dataJson: dataJson ?? this.dataJson,
        source: source ?? this.source,
        parentId: parentId.present ? parentId.value : this.parentId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Component copyWithCompanion(ComponentsCompanion data) {
    return Component(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      source: data.source.present ? data.source.value : this.source,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Component(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('dataJson: $dataJson, ')
          ..write('source: $source, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, type, name, dataJson, source, parentId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Component &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.dataJson == this.dataJson &&
          other.source == this.source &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ComponentsCompanion extends UpdateCompanion<Component> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String> dataJson;
  final Value<String> source;
  final Value<String?> parentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ComponentsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.source = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentsCompanion.insert({
    required String id,
    required String type,
    required String name,
    this.dataJson = const Value.absent(),
    this.source = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        name = Value(name);
  static Insertable<Component> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? dataJson,
    Expression<String>? source,
    Expression<String>? parentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (dataJson != null) 'data_json': dataJson,
      if (source != null) 'source': source,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? name,
      Value<String>? dataJson,
      Value<String>? source,
      Value<String?>? parentId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ComponentsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      dataJson: dataJson ?? this.dataJson,
      source: source ?? this.source,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('dataJson: $dataJson, ')
          ..write('source: $source, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroesTable extends Heroes with TableInfo<$HeroesTable, Heroe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classComponentIdMeta =
      const VerificationMeta('classComponentId');
  @override
  late final GeneratedColumn<String> classComponentId = GeneratedColumn<String>(
      'class_component_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES components (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, classComponentId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heroes';
  @override
  VerificationContext validateIntegrity(Insertable<Heroe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('class_component_id')) {
      context.handle(
          _classComponentIdMeta,
          classComponentId.isAcceptableOrUnknown(
              data['class_component_id']!, _classComponentIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Heroe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Heroe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      classComponentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}class_component_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroesTable createAlias(String alias) {
    return $HeroesTable(attachedDatabase, alias);
  }
}

class Heroe extends DataClass implements Insertable<Heroe> {
  final String id;
  final String name;
  final String? classComponentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Heroe(
      {required this.id,
      required this.name,
      this.classComponentId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || classComponentId != null) {
      map['class_component_id'] = Variable<String>(classComponentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroesCompanion toCompanion(bool nullToAbsent) {
    return HeroesCompanion(
      id: Value(id),
      name: Value(name),
      classComponentId: classComponentId == null && nullToAbsent
          ? const Value.absent()
          : Value(classComponentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Heroe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Heroe(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      classComponentId: serializer.fromJson<String?>(json['classComponentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'classComponentId': serializer.toJson<String?>(classComponentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Heroe copyWith(
          {String? id,
          String? name,
          Value<String?> classComponentId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Heroe(
        id: id ?? this.id,
        name: name ?? this.name,
        classComponentId: classComponentId.present
            ? classComponentId.value
            : this.classComponentId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Heroe copyWithCompanion(HeroesCompanion data) {
    return Heroe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      classComponentId: data.classComponentId.present
          ? data.classComponentId.value
          : this.classComponentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Heroe(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('classComponentId: $classComponentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, classComponentId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Heroe &&
          other.id == this.id &&
          other.name == this.name &&
          other.classComponentId == this.classComponentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroesCompanion extends UpdateCompanion<Heroe> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> classComponentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.classComponentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroesCompanion.insert({
    required String id,
    required String name,
    this.classComponentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Heroe> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? classComponentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (classComponentId != null) 'class_component_id': classComponentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? classComponentId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      classComponentId: classComponentId ?? this.classComponentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (classComponentId.present) {
      map['class_component_id'] = Variable<String>(classComponentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('classComponentId: $classComponentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroValuesTable extends HeroValues
    with TableInfo<$HeroValuesTable, HeroValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxValueMeta =
      const VerificationMeta('maxValue');
  @override
  late final GeneratedColumn<int> maxValue = GeneratedColumn<int>(
      'max_value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _doubleValueMeta =
      const VerificationMeta('doubleValue');
  @override
  late final GeneratedColumn<double> doubleValue = GeneratedColumn<double>(
      'double_value', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _textValueMeta =
      const VerificationMeta('textValue');
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
      'text_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jsonValueMeta =
      const VerificationMeta('jsonValue');
  @override
  late final GeneratedColumn<String> jsonValue = GeneratedColumn<String>(
      'json_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        key,
        value,
        maxValue,
        doubleValue,
        textValue,
        jsonValue,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_values';
  @override
  VerificationContext validateIntegrity(Insertable<HeroValue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('max_value')) {
      context.handle(_maxValueMeta,
          maxValue.isAcceptableOrUnknown(data['max_value']!, _maxValueMeta));
    }
    if (data.containsKey('double_value')) {
      context.handle(
          _doubleValueMeta,
          doubleValue.isAcceptableOrUnknown(
              data['double_value']!, _doubleValueMeta));
    }
    if (data.containsKey('text_value')) {
      context.handle(_textValueMeta,
          textValue.isAcceptableOrUnknown(data['text_value']!, _textValueMeta));
    }
    if (data.containsKey('json_value')) {
      context.handle(_jsonValueMeta,
          jsonValue.isAcceptableOrUnknown(data['json_value']!, _jsonValueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroValue(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value']),
      maxValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_value']),
      doubleValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}double_value']),
      textValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_value']),
      jsonValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_value']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroValuesTable createAlias(String alias) {
    return $HeroValuesTable(attachedDatabase, alias);
  }
}

class HeroValue extends DataClass implements Insertable<HeroValue> {
  final int id;
  final String heroId;
  final String key;
  final int? value;
  final int? maxValue;
  final double? doubleValue;
  final String? textValue;
  final String? jsonValue;
  final DateTime updatedAt;
  const HeroValue(
      {required this.id,
      required this.heroId,
      required this.key,
      this.value,
      this.maxValue,
      this.doubleValue,
      this.textValue,
      this.jsonValue,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<int>(value);
    }
    if (!nullToAbsent || maxValue != null) {
      map['max_value'] = Variable<int>(maxValue);
    }
    if (!nullToAbsent || doubleValue != null) {
      map['double_value'] = Variable<double>(doubleValue);
    }
    if (!nullToAbsent || textValue != null) {
      map['text_value'] = Variable<String>(textValue);
    }
    if (!nullToAbsent || jsonValue != null) {
      map['json_value'] = Variable<String>(jsonValue);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroValuesCompanion toCompanion(bool nullToAbsent) {
    return HeroValuesCompanion(
      id: Value(id),
      heroId: Value(heroId),
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      maxValue: maxValue == null && nullToAbsent
          ? const Value.absent()
          : Value(maxValue),
      doubleValue: doubleValue == null && nullToAbsent
          ? const Value.absent()
          : Value(doubleValue),
      textValue: textValue == null && nullToAbsent
          ? const Value.absent()
          : Value(textValue),
      jsonValue: jsonValue == null && nullToAbsent
          ? const Value.absent()
          : Value(jsonValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroValue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroValue(
      id: serializer.fromJson<int>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<int?>(json['value']),
      maxValue: serializer.fromJson<int?>(json['maxValue']),
      doubleValue: serializer.fromJson<double?>(json['doubleValue']),
      textValue: serializer.fromJson<String?>(json['textValue']),
      jsonValue: serializer.fromJson<String?>(json['jsonValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'heroId': serializer.toJson<String>(heroId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<int?>(value),
      'maxValue': serializer.toJson<int?>(maxValue),
      'doubleValue': serializer.toJson<double?>(doubleValue),
      'textValue': serializer.toJson<String?>(textValue),
      'jsonValue': serializer.toJson<String?>(jsonValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroValue copyWith(
          {int? id,
          String? heroId,
          String? key,
          Value<int?> value = const Value.absent(),
          Value<int?> maxValue = const Value.absent(),
          Value<double?> doubleValue = const Value.absent(),
          Value<String?> textValue = const Value.absent(),
          Value<String?> jsonValue = const Value.absent(),
          DateTime? updatedAt}) =>
      HeroValue(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
        maxValue: maxValue.present ? maxValue.value : this.maxValue,
        doubleValue: doubleValue.present ? doubleValue.value : this.doubleValue,
        textValue: textValue.present ? textValue.value : this.textValue,
        jsonValue: jsonValue.present ? jsonValue.value : this.jsonValue,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroValue copyWithCompanion(HeroValuesCompanion data) {
    return HeroValue(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      maxValue: data.maxValue.present ? data.maxValue.value : this.maxValue,
      doubleValue:
          data.doubleValue.present ? data.doubleValue.value : this.doubleValue,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
      jsonValue: data.jsonValue.present ? data.jsonValue.value : this.jsonValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroValue(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('maxValue: $maxValue, ')
          ..write('doubleValue: $doubleValue, ')
          ..write('textValue: $textValue, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, heroId, key, value, maxValue, doubleValue,
      textValue, jsonValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroValue &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.key == this.key &&
          other.value == this.value &&
          other.maxValue == this.maxValue &&
          other.doubleValue == this.doubleValue &&
          other.textValue == this.textValue &&
          other.jsonValue == this.jsonValue &&
          other.updatedAt == this.updatedAt);
}

class HeroValuesCompanion extends UpdateCompanion<HeroValue> {
  final Value<int> id;
  final Value<String> heroId;
  final Value<String> key;
  final Value<int?> value;
  final Value<int?> maxValue;
  final Value<double?> doubleValue;
  final Value<String?> textValue;
  final Value<String?> jsonValue;
  final Value<DateTime> updatedAt;
  const HeroValuesCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.doubleValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.jsonValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HeroValuesCompanion.insert({
    this.id = const Value.absent(),
    required String heroId,
    required String key,
    this.value = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.doubleValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.jsonValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : heroId = Value(heroId),
        key = Value(key);
  static Insertable<HeroValue> custom({
    Expression<int>? id,
    Expression<String>? heroId,
    Expression<String>? key,
    Expression<int>? value,
    Expression<int>? maxValue,
    Expression<double>? doubleValue,
    Expression<String>? textValue,
    Expression<String>? jsonValue,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (maxValue != null) 'max_value': maxValue,
      if (doubleValue != null) 'double_value': doubleValue,
      if (textValue != null) 'text_value': textValue,
      if (jsonValue != null) 'json_value': jsonValue,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HeroValuesCompanion copyWith(
      {Value<int>? id,
      Value<String>? heroId,
      Value<String>? key,
      Value<int?>? value,
      Value<int?>? maxValue,
      Value<double?>? doubleValue,
      Value<String?>? textValue,
      Value<String?>? jsonValue,
      Value<DateTime>? updatedAt}) {
    return HeroValuesCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      key: key ?? this.key,
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      doubleValue: doubleValue ?? this.doubleValue,
      textValue: textValue ?? this.textValue,
      jsonValue: jsonValue ?? this.jsonValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (maxValue.present) {
      map['max_value'] = Variable<int>(maxValue.value);
    }
    if (doubleValue.present) {
      map['double_value'] = Variable<double>(doubleValue.value);
    }
    if (textValue.present) {
      map['text_value'] = Variable<String>(textValue.value);
    }
    if (jsonValue.present) {
      map['json_value'] = Variable<String>(jsonValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroValuesCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('maxValue: $maxValue, ')
          ..write('doubleValue: $doubleValue, ')
          ..write('textValue: $textValue, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MetaEntriesTable extends MetaEntries
    with TableInfo<$MetaEntriesTable, MetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_entries';
  @override
  VerificationContext validateIntegrity(Insertable<MetaEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $MetaEntriesTable createAlias(String alias) {
    return $MetaEntriesTable(attachedDatabase, alias);
  }
}

class MetaEntry extends DataClass implements Insertable<MetaEntry> {
  final String key;
  final String value;
  const MetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaEntriesCompanion toCompanion(bool nullToAbsent) {
    return MetaEntriesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory MetaEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaEntry copyWith({String? key, String? value}) => MetaEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  MetaEntry copyWithCompanion(MetaEntriesCompanion data) {
    return MetaEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MetaEntriesCompanion extends UpdateCompanion<MetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<MetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaEntriesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return MetaEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroDowntimeProjectsTable extends HeroDowntimeProjects
    with TableInfo<$HeroDowntimeProjectsTable, HeroDowntimeProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroDowntimeProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _templateProjectIdMeta =
      const VerificationMeta('templateProjectId');
  @override
  late final GeneratedColumn<String> templateProjectId =
      GeneratedColumn<String>('template_project_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _projectGoalMeta =
      const VerificationMeta('projectGoal');
  @override
  late final GeneratedColumn<int> projectGoal = GeneratedColumn<int>(
      'project_goal', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentPointsMeta =
      const VerificationMeta('currentPoints');
  @override
  late final GeneratedColumn<int> currentPoints = GeneratedColumn<int>(
      'current_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _prerequisitesJsonMeta =
      const VerificationMeta('prerequisitesJson');
  @override
  late final GeneratedColumn<String> prerequisitesJson =
      GeneratedColumn<String>('prerequisites_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _projectSourceMeta =
      const VerificationMeta('projectSource');
  @override
  late final GeneratedColumn<String> projectSource = GeneratedColumn<String>(
      'project_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceLanguageMeta =
      const VerificationMeta('sourceLanguage');
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
      'source_language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _guidesJsonMeta =
      const VerificationMeta('guidesJson');
  @override
  late final GeneratedColumn<String> guidesJson = GeneratedColumn<String>(
      'guides_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _rollCharacteristicsJsonMeta =
      const VerificationMeta('rollCharacteristicsJson');
  @override
  late final GeneratedColumn<String> rollCharacteristicsJson =
      GeneratedColumn<String>('roll_characteristics_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _eventsJsonMeta =
      const VerificationMeta('eventsJson');
  @override
  late final GeneratedColumn<String> eventsJson = GeneratedColumn<String>(
      'events_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        templateProjectId,
        name,
        description,
        projectGoal,
        currentPoints,
        prerequisitesJson,
        projectSource,
        sourceLanguage,
        guidesJson,
        rollCharacteristicsJson,
        eventsJson,
        notes,
        isCustom,
        isCompleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_downtime_projects';
  @override
  VerificationContext validateIntegrity(
      Insertable<HeroDowntimeProject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('template_project_id')) {
      context.handle(
          _templateProjectIdMeta,
          templateProjectId.isAcceptableOrUnknown(
              data['template_project_id']!, _templateProjectIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('project_goal')) {
      context.handle(
          _projectGoalMeta,
          projectGoal.isAcceptableOrUnknown(
              data['project_goal']!, _projectGoalMeta));
    } else if (isInserting) {
      context.missing(_projectGoalMeta);
    }
    if (data.containsKey('current_points')) {
      context.handle(
          _currentPointsMeta,
          currentPoints.isAcceptableOrUnknown(
              data['current_points']!, _currentPointsMeta));
    }
    if (data.containsKey('prerequisites_json')) {
      context.handle(
          _prerequisitesJsonMeta,
          prerequisitesJson.isAcceptableOrUnknown(
              data['prerequisites_json']!, _prerequisitesJsonMeta));
    }
    if (data.containsKey('project_source')) {
      context.handle(
          _projectSourceMeta,
          projectSource.isAcceptableOrUnknown(
              data['project_source']!, _projectSourceMeta));
    }
    if (data.containsKey('source_language')) {
      context.handle(
          _sourceLanguageMeta,
          sourceLanguage.isAcceptableOrUnknown(
              data['source_language']!, _sourceLanguageMeta));
    }
    if (data.containsKey('guides_json')) {
      context.handle(
          _guidesJsonMeta,
          guidesJson.isAcceptableOrUnknown(
              data['guides_json']!, _guidesJsonMeta));
    }
    if (data.containsKey('roll_characteristics_json')) {
      context.handle(
          _rollCharacteristicsJsonMeta,
          rollCharacteristicsJson.isAcceptableOrUnknown(
              data['roll_characteristics_json']!,
              _rollCharacteristicsJsonMeta));
    }
    if (data.containsKey('events_json')) {
      context.handle(
          _eventsJsonMeta,
          eventsJson.isAcceptableOrUnknown(
              data['events_json']!, _eventsJsonMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroDowntimeProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroDowntimeProject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      templateProjectId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}template_project_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      projectGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_goal'])!,
      currentPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_points'])!,
      prerequisitesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}prerequisites_json'])!,
      projectSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_source']),
      sourceLanguage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_language']),
      guidesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guides_json'])!,
      rollCharacteristicsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}roll_characteristics_json'])!,
      eventsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}events_json'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroDowntimeProjectsTable createAlias(String alias) {
    return $HeroDowntimeProjectsTable(attachedDatabase, alias);
  }
}

class HeroDowntimeProject extends DataClass
    implements Insertable<HeroDowntimeProject> {
  final String id;
  final String heroId;
  final String? templateProjectId;
  final String name;
  final String description;
  final int projectGoal;
  final int currentPoints;
  final String prerequisitesJson;
  final String? projectSource;
  final String? sourceLanguage;
  final String guidesJson;
  final String rollCharacteristicsJson;
  final String eventsJson;
  final String notes;
  final bool isCustom;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroDowntimeProject(
      {required this.id,
      required this.heroId,
      this.templateProjectId,
      required this.name,
      required this.description,
      required this.projectGoal,
      required this.currentPoints,
      required this.prerequisitesJson,
      this.projectSource,
      this.sourceLanguage,
      required this.guidesJson,
      required this.rollCharacteristicsJson,
      required this.eventsJson,
      required this.notes,
      required this.isCustom,
      required this.isCompleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    if (!nullToAbsent || templateProjectId != null) {
      map['template_project_id'] = Variable<String>(templateProjectId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['project_goal'] = Variable<int>(projectGoal);
    map['current_points'] = Variable<int>(currentPoints);
    map['prerequisites_json'] = Variable<String>(prerequisitesJson);
    if (!nullToAbsent || projectSource != null) {
      map['project_source'] = Variable<String>(projectSource);
    }
    if (!nullToAbsent || sourceLanguage != null) {
      map['source_language'] = Variable<String>(sourceLanguage);
    }
    map['guides_json'] = Variable<String>(guidesJson);
    map['roll_characteristics_json'] =
        Variable<String>(rollCharacteristicsJson);
    map['events_json'] = Variable<String>(eventsJson);
    map['notes'] = Variable<String>(notes);
    map['is_custom'] = Variable<bool>(isCustom);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroDowntimeProjectsCompanion toCompanion(bool nullToAbsent) {
    return HeroDowntimeProjectsCompanion(
      id: Value(id),
      heroId: Value(heroId),
      templateProjectId: templateProjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateProjectId),
      name: Value(name),
      description: Value(description),
      projectGoal: Value(projectGoal),
      currentPoints: Value(currentPoints),
      prerequisitesJson: Value(prerequisitesJson),
      projectSource: projectSource == null && nullToAbsent
          ? const Value.absent()
          : Value(projectSource),
      sourceLanguage: sourceLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLanguage),
      guidesJson: Value(guidesJson),
      rollCharacteristicsJson: Value(rollCharacteristicsJson),
      eventsJson: Value(eventsJson),
      notes: Value(notes),
      isCustom: Value(isCustom),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroDowntimeProject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroDowntimeProject(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      templateProjectId:
          serializer.fromJson<String?>(json['templateProjectId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      projectGoal: serializer.fromJson<int>(json['projectGoal']),
      currentPoints: serializer.fromJson<int>(json['currentPoints']),
      prerequisitesJson: serializer.fromJson<String>(json['prerequisitesJson']),
      projectSource: serializer.fromJson<String?>(json['projectSource']),
      sourceLanguage: serializer.fromJson<String?>(json['sourceLanguage']),
      guidesJson: serializer.fromJson<String>(json['guidesJson']),
      rollCharacteristicsJson:
          serializer.fromJson<String>(json['rollCharacteristicsJson']),
      eventsJson: serializer.fromJson<String>(json['eventsJson']),
      notes: serializer.fromJson<String>(json['notes']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'templateProjectId': serializer.toJson<String?>(templateProjectId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'projectGoal': serializer.toJson<int>(projectGoal),
      'currentPoints': serializer.toJson<int>(currentPoints),
      'prerequisitesJson': serializer.toJson<String>(prerequisitesJson),
      'projectSource': serializer.toJson<String?>(projectSource),
      'sourceLanguage': serializer.toJson<String?>(sourceLanguage),
      'guidesJson': serializer.toJson<String>(guidesJson),
      'rollCharacteristicsJson':
          serializer.toJson<String>(rollCharacteristicsJson),
      'eventsJson': serializer.toJson<String>(eventsJson),
      'notes': serializer.toJson<String>(notes),
      'isCustom': serializer.toJson<bool>(isCustom),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroDowntimeProject copyWith(
          {String? id,
          String? heroId,
          Value<String?> templateProjectId = const Value.absent(),
          String? name,
          String? description,
          int? projectGoal,
          int? currentPoints,
          String? prerequisitesJson,
          Value<String?> projectSource = const Value.absent(),
          Value<String?> sourceLanguage = const Value.absent(),
          String? guidesJson,
          String? rollCharacteristicsJson,
          String? eventsJson,
          String? notes,
          bool? isCustom,
          bool? isCompleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroDowntimeProject(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        templateProjectId: templateProjectId.present
            ? templateProjectId.value
            : this.templateProjectId,
        name: name ?? this.name,
        description: description ?? this.description,
        projectGoal: projectGoal ?? this.projectGoal,
        currentPoints: currentPoints ?? this.currentPoints,
        prerequisitesJson: prerequisitesJson ?? this.prerequisitesJson,
        projectSource:
            projectSource.present ? projectSource.value : this.projectSource,
        sourceLanguage:
            sourceLanguage.present ? sourceLanguage.value : this.sourceLanguage,
        guidesJson: guidesJson ?? this.guidesJson,
        rollCharacteristicsJson:
            rollCharacteristicsJson ?? this.rollCharacteristicsJson,
        eventsJson: eventsJson ?? this.eventsJson,
        notes: notes ?? this.notes,
        isCustom: isCustom ?? this.isCustom,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroDowntimeProject copyWithCompanion(HeroDowntimeProjectsCompanion data) {
    return HeroDowntimeProject(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      templateProjectId: data.templateProjectId.present
          ? data.templateProjectId.value
          : this.templateProjectId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      projectGoal:
          data.projectGoal.present ? data.projectGoal.value : this.projectGoal,
      currentPoints: data.currentPoints.present
          ? data.currentPoints.value
          : this.currentPoints,
      prerequisitesJson: data.prerequisitesJson.present
          ? data.prerequisitesJson.value
          : this.prerequisitesJson,
      projectSource: data.projectSource.present
          ? data.projectSource.value
          : this.projectSource,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      guidesJson:
          data.guidesJson.present ? data.guidesJson.value : this.guidesJson,
      rollCharacteristicsJson: data.rollCharacteristicsJson.present
          ? data.rollCharacteristicsJson.value
          : this.rollCharacteristicsJson,
      eventsJson:
          data.eventsJson.present ? data.eventsJson.value : this.eventsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroDowntimeProject(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('templateProjectId: $templateProjectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('projectGoal: $projectGoal, ')
          ..write('currentPoints: $currentPoints, ')
          ..write('prerequisitesJson: $prerequisitesJson, ')
          ..write('projectSource: $projectSource, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('guidesJson: $guidesJson, ')
          ..write('rollCharacteristicsJson: $rollCharacteristicsJson, ')
          ..write('eventsJson: $eventsJson, ')
          ..write('notes: $notes, ')
          ..write('isCustom: $isCustom, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      heroId,
      templateProjectId,
      name,
      description,
      projectGoal,
      currentPoints,
      prerequisitesJson,
      projectSource,
      sourceLanguage,
      guidesJson,
      rollCharacteristicsJson,
      eventsJson,
      notes,
      isCustom,
      isCompleted,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroDowntimeProject &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.templateProjectId == this.templateProjectId &&
          other.name == this.name &&
          other.description == this.description &&
          other.projectGoal == this.projectGoal &&
          other.currentPoints == this.currentPoints &&
          other.prerequisitesJson == this.prerequisitesJson &&
          other.projectSource == this.projectSource &&
          other.sourceLanguage == this.sourceLanguage &&
          other.guidesJson == this.guidesJson &&
          other.rollCharacteristicsJson == this.rollCharacteristicsJson &&
          other.eventsJson == this.eventsJson &&
          other.notes == this.notes &&
          other.isCustom == this.isCustom &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroDowntimeProjectsCompanion
    extends UpdateCompanion<HeroDowntimeProject> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String?> templateProjectId;
  final Value<String> name;
  final Value<String> description;
  final Value<int> projectGoal;
  final Value<int> currentPoints;
  final Value<String> prerequisitesJson;
  final Value<String?> projectSource;
  final Value<String?> sourceLanguage;
  final Value<String> guidesJson;
  final Value<String> rollCharacteristicsJson;
  final Value<String> eventsJson;
  final Value<String> notes;
  final Value<bool> isCustom;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroDowntimeProjectsCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.templateProjectId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.projectGoal = const Value.absent(),
    this.currentPoints = const Value.absent(),
    this.prerequisitesJson = const Value.absent(),
    this.projectSource = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.guidesJson = const Value.absent(),
    this.rollCharacteristicsJson = const Value.absent(),
    this.eventsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroDowntimeProjectsCompanion.insert({
    required String id,
    required String heroId,
    this.templateProjectId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int projectGoal,
    this.currentPoints = const Value.absent(),
    this.prerequisitesJson = const Value.absent(),
    this.projectSource = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.guidesJson = const Value.absent(),
    this.rollCharacteristicsJson = const Value.absent(),
    this.eventsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        name = Value(name),
        projectGoal = Value(projectGoal);
  static Insertable<HeroDowntimeProject> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? templateProjectId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? projectGoal,
    Expression<int>? currentPoints,
    Expression<String>? prerequisitesJson,
    Expression<String>? projectSource,
    Expression<String>? sourceLanguage,
    Expression<String>? guidesJson,
    Expression<String>? rollCharacteristicsJson,
    Expression<String>? eventsJson,
    Expression<String>? notes,
    Expression<bool>? isCustom,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (templateProjectId != null) 'template_project_id': templateProjectId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (projectGoal != null) 'project_goal': projectGoal,
      if (currentPoints != null) 'current_points': currentPoints,
      if (prerequisitesJson != null) 'prerequisites_json': prerequisitesJson,
      if (projectSource != null) 'project_source': projectSource,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (guidesJson != null) 'guides_json': guidesJson,
      if (rollCharacteristicsJson != null)
        'roll_characteristics_json': rollCharacteristicsJson,
      if (eventsJson != null) 'events_json': eventsJson,
      if (notes != null) 'notes': notes,
      if (isCustom != null) 'is_custom': isCustom,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroDowntimeProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String?>? templateProjectId,
      Value<String>? name,
      Value<String>? description,
      Value<int>? projectGoal,
      Value<int>? currentPoints,
      Value<String>? prerequisitesJson,
      Value<String?>? projectSource,
      Value<String?>? sourceLanguage,
      Value<String>? guidesJson,
      Value<String>? rollCharacteristicsJson,
      Value<String>? eventsJson,
      Value<String>? notes,
      Value<bool>? isCustom,
      Value<bool>? isCompleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroDowntimeProjectsCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      templateProjectId: templateProjectId ?? this.templateProjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      projectGoal: projectGoal ?? this.projectGoal,
      currentPoints: currentPoints ?? this.currentPoints,
      prerequisitesJson: prerequisitesJson ?? this.prerequisitesJson,
      projectSource: projectSource ?? this.projectSource,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      guidesJson: guidesJson ?? this.guidesJson,
      rollCharacteristicsJson:
          rollCharacteristicsJson ?? this.rollCharacteristicsJson,
      eventsJson: eventsJson ?? this.eventsJson,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (templateProjectId.present) {
      map['template_project_id'] = Variable<String>(templateProjectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (projectGoal.present) {
      map['project_goal'] = Variable<int>(projectGoal.value);
    }
    if (currentPoints.present) {
      map['current_points'] = Variable<int>(currentPoints.value);
    }
    if (prerequisitesJson.present) {
      map['prerequisites_json'] = Variable<String>(prerequisitesJson.value);
    }
    if (projectSource.present) {
      map['project_source'] = Variable<String>(projectSource.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (guidesJson.present) {
      map['guides_json'] = Variable<String>(guidesJson.value);
    }
    if (rollCharacteristicsJson.present) {
      map['roll_characteristics_json'] =
          Variable<String>(rollCharacteristicsJson.value);
    }
    if (eventsJson.present) {
      map['events_json'] = Variable<String>(eventsJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroDowntimeProjectsCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('templateProjectId: $templateProjectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('projectGoal: $projectGoal, ')
          ..write('currentPoints: $currentPoints, ')
          ..write('prerequisitesJson: $prerequisitesJson, ')
          ..write('projectSource: $projectSource, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('guidesJson: $guidesJson, ')
          ..write('rollCharacteristicsJson: $rollCharacteristicsJson, ')
          ..write('eventsJson: $eventsJson, ')
          ..write('notes: $notes, ')
          ..write('isCustom: $isCustom, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroFollowersTable extends HeroFollowers
    with TableInfo<$HeroFollowersTable, HeroFollower> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroFollowersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _followerTypeMeta =
      const VerificationMeta('followerType');
  @override
  late final GeneratedColumn<String> followerType = GeneratedColumn<String>(
      'follower_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mightMeta = const VerificationMeta('might');
  @override
  late final GeneratedColumn<int> might = GeneratedColumn<int>(
      'might', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _agilityMeta =
      const VerificationMeta('agility');
  @override
  late final GeneratedColumn<int> agility = GeneratedColumn<int>(
      'agility', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<int> reason = GeneratedColumn<int>(
      'reason', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _intuitionMeta =
      const VerificationMeta('intuition');
  @override
  late final GeneratedColumn<int> intuition = GeneratedColumn<int>(
      'intuition', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _presenceMeta =
      const VerificationMeta('presence');
  @override
  late final GeneratedColumn<int> presence = GeneratedColumn<int>(
      'presence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _skillsJsonMeta =
      const VerificationMeta('skillsJson');
  @override
  late final GeneratedColumn<String> skillsJson = GeneratedColumn<String>(
      'skills_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _languagesJsonMeta =
      const VerificationMeta('languagesJson');
  @override
  late final GeneratedColumn<String> languagesJson = GeneratedColumn<String>(
      'languages_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        name,
        followerType,
        might,
        agility,
        reason,
        intuition,
        presence,
        skillsJson,
        languagesJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_followers';
  @override
  VerificationContext validateIntegrity(Insertable<HeroFollower> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('follower_type')) {
      context.handle(
          _followerTypeMeta,
          followerType.isAcceptableOrUnknown(
              data['follower_type']!, _followerTypeMeta));
    } else if (isInserting) {
      context.missing(_followerTypeMeta);
    }
    if (data.containsKey('might')) {
      context.handle(
          _mightMeta, might.isAcceptableOrUnknown(data['might']!, _mightMeta));
    }
    if (data.containsKey('agility')) {
      context.handle(_agilityMeta,
          agility.isAcceptableOrUnknown(data['agility']!, _agilityMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('intuition')) {
      context.handle(_intuitionMeta,
          intuition.isAcceptableOrUnknown(data['intuition']!, _intuitionMeta));
    }
    if (data.containsKey('presence')) {
      context.handle(_presenceMeta,
          presence.isAcceptableOrUnknown(data['presence']!, _presenceMeta));
    }
    if (data.containsKey('skills_json')) {
      context.handle(
          _skillsJsonMeta,
          skillsJson.isAcceptableOrUnknown(
              data['skills_json']!, _skillsJsonMeta));
    }
    if (data.containsKey('languages_json')) {
      context.handle(
          _languagesJsonMeta,
          languagesJson.isAcceptableOrUnknown(
              data['languages_json']!, _languagesJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroFollower map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroFollower(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      followerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}follower_type'])!,
      might: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}might'])!,
      agility: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}agility'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reason'])!,
      intuition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}intuition'])!,
      presence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}presence'])!,
      skillsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}skills_json'])!,
      languagesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}languages_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HeroFollowersTable createAlias(String alias) {
    return $HeroFollowersTable(attachedDatabase, alias);
  }
}

class HeroFollower extends DataClass implements Insertable<HeroFollower> {
  final String id;
  final String heroId;
  final String name;
  final String followerType;
  final int might;
  final int agility;
  final int reason;
  final int intuition;
  final int presence;
  final String skillsJson;
  final String languagesJson;
  final DateTime createdAt;
  const HeroFollower(
      {required this.id,
      required this.heroId,
      required this.name,
      required this.followerType,
      required this.might,
      required this.agility,
      required this.reason,
      required this.intuition,
      required this.presence,
      required this.skillsJson,
      required this.languagesJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['name'] = Variable<String>(name);
    map['follower_type'] = Variable<String>(followerType);
    map['might'] = Variable<int>(might);
    map['agility'] = Variable<int>(agility);
    map['reason'] = Variable<int>(reason);
    map['intuition'] = Variable<int>(intuition);
    map['presence'] = Variable<int>(presence);
    map['skills_json'] = Variable<String>(skillsJson);
    map['languages_json'] = Variable<String>(languagesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HeroFollowersCompanion toCompanion(bool nullToAbsent) {
    return HeroFollowersCompanion(
      id: Value(id),
      heroId: Value(heroId),
      name: Value(name),
      followerType: Value(followerType),
      might: Value(might),
      agility: Value(agility),
      reason: Value(reason),
      intuition: Value(intuition),
      presence: Value(presence),
      skillsJson: Value(skillsJson),
      languagesJson: Value(languagesJson),
      createdAt: Value(createdAt),
    );
  }

  factory HeroFollower.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroFollower(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      name: serializer.fromJson<String>(json['name']),
      followerType: serializer.fromJson<String>(json['followerType']),
      might: serializer.fromJson<int>(json['might']),
      agility: serializer.fromJson<int>(json['agility']),
      reason: serializer.fromJson<int>(json['reason']),
      intuition: serializer.fromJson<int>(json['intuition']),
      presence: serializer.fromJson<int>(json['presence']),
      skillsJson: serializer.fromJson<String>(json['skillsJson']),
      languagesJson: serializer.fromJson<String>(json['languagesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'name': serializer.toJson<String>(name),
      'followerType': serializer.toJson<String>(followerType),
      'might': serializer.toJson<int>(might),
      'agility': serializer.toJson<int>(agility),
      'reason': serializer.toJson<int>(reason),
      'intuition': serializer.toJson<int>(intuition),
      'presence': serializer.toJson<int>(presence),
      'skillsJson': serializer.toJson<String>(skillsJson),
      'languagesJson': serializer.toJson<String>(languagesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HeroFollower copyWith(
          {String? id,
          String? heroId,
          String? name,
          String? followerType,
          int? might,
          int? agility,
          int? reason,
          int? intuition,
          int? presence,
          String? skillsJson,
          String? languagesJson,
          DateTime? createdAt}) =>
      HeroFollower(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        name: name ?? this.name,
        followerType: followerType ?? this.followerType,
        might: might ?? this.might,
        agility: agility ?? this.agility,
        reason: reason ?? this.reason,
        intuition: intuition ?? this.intuition,
        presence: presence ?? this.presence,
        skillsJson: skillsJson ?? this.skillsJson,
        languagesJson: languagesJson ?? this.languagesJson,
        createdAt: createdAt ?? this.createdAt,
      );
  HeroFollower copyWithCompanion(HeroFollowersCompanion data) {
    return HeroFollower(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      name: data.name.present ? data.name.value : this.name,
      followerType: data.followerType.present
          ? data.followerType.value
          : this.followerType,
      might: data.might.present ? data.might.value : this.might,
      agility: data.agility.present ? data.agility.value : this.agility,
      reason: data.reason.present ? data.reason.value : this.reason,
      intuition: data.intuition.present ? data.intuition.value : this.intuition,
      presence: data.presence.present ? data.presence.value : this.presence,
      skillsJson:
          data.skillsJson.present ? data.skillsJson.value : this.skillsJson,
      languagesJson: data.languagesJson.present
          ? data.languagesJson.value
          : this.languagesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroFollower(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('name: $name, ')
          ..write('followerType: $followerType, ')
          ..write('might: $might, ')
          ..write('agility: $agility, ')
          ..write('reason: $reason, ')
          ..write('intuition: $intuition, ')
          ..write('presence: $presence, ')
          ..write('skillsJson: $skillsJson, ')
          ..write('languagesJson: $languagesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      heroId,
      name,
      followerType,
      might,
      agility,
      reason,
      intuition,
      presence,
      skillsJson,
      languagesJson,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroFollower &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.name == this.name &&
          other.followerType == this.followerType &&
          other.might == this.might &&
          other.agility == this.agility &&
          other.reason == this.reason &&
          other.intuition == this.intuition &&
          other.presence == this.presence &&
          other.skillsJson == this.skillsJson &&
          other.languagesJson == this.languagesJson &&
          other.createdAt == this.createdAt);
}

class HeroFollowersCompanion extends UpdateCompanion<HeroFollower> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> name;
  final Value<String> followerType;
  final Value<int> might;
  final Value<int> agility;
  final Value<int> reason;
  final Value<int> intuition;
  final Value<int> presence;
  final Value<String> skillsJson;
  final Value<String> languagesJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HeroFollowersCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.name = const Value.absent(),
    this.followerType = const Value.absent(),
    this.might = const Value.absent(),
    this.agility = const Value.absent(),
    this.reason = const Value.absent(),
    this.intuition = const Value.absent(),
    this.presence = const Value.absent(),
    this.skillsJson = const Value.absent(),
    this.languagesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroFollowersCompanion.insert({
    required String id,
    required String heroId,
    required String name,
    required String followerType,
    this.might = const Value.absent(),
    this.agility = const Value.absent(),
    this.reason = const Value.absent(),
    this.intuition = const Value.absent(),
    this.presence = const Value.absent(),
    this.skillsJson = const Value.absent(),
    this.languagesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        name = Value(name),
        followerType = Value(followerType);
  static Insertable<HeroFollower> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? name,
    Expression<String>? followerType,
    Expression<int>? might,
    Expression<int>? agility,
    Expression<int>? reason,
    Expression<int>? intuition,
    Expression<int>? presence,
    Expression<String>? skillsJson,
    Expression<String>? languagesJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (name != null) 'name': name,
      if (followerType != null) 'follower_type': followerType,
      if (might != null) 'might': might,
      if (agility != null) 'agility': agility,
      if (reason != null) 'reason': reason,
      if (intuition != null) 'intuition': intuition,
      if (presence != null) 'presence': presence,
      if (skillsJson != null) 'skills_json': skillsJson,
      if (languagesJson != null) 'languages_json': languagesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroFollowersCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? name,
      Value<String>? followerType,
      Value<int>? might,
      Value<int>? agility,
      Value<int>? reason,
      Value<int>? intuition,
      Value<int>? presence,
      Value<String>? skillsJson,
      Value<String>? languagesJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return HeroFollowersCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      name: name ?? this.name,
      followerType: followerType ?? this.followerType,
      might: might ?? this.might,
      agility: agility ?? this.agility,
      reason: reason ?? this.reason,
      intuition: intuition ?? this.intuition,
      presence: presence ?? this.presence,
      skillsJson: skillsJson ?? this.skillsJson,
      languagesJson: languagesJson ?? this.languagesJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (followerType.present) {
      map['follower_type'] = Variable<String>(followerType.value);
    }
    if (might.present) {
      map['might'] = Variable<int>(might.value);
    }
    if (agility.present) {
      map['agility'] = Variable<int>(agility.value);
    }
    if (reason.present) {
      map['reason'] = Variable<int>(reason.value);
    }
    if (intuition.present) {
      map['intuition'] = Variable<int>(intuition.value);
    }
    if (presence.present) {
      map['presence'] = Variable<int>(presence.value);
    }
    if (skillsJson.present) {
      map['skills_json'] = Variable<String>(skillsJson.value);
    }
    if (languagesJson.present) {
      map['languages_json'] = Variable<String>(languagesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroFollowersCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('name: $name, ')
          ..write('followerType: $followerType, ')
          ..write('might: $might, ')
          ..write('agility: $agility, ')
          ..write('reason: $reason, ')
          ..write('intuition: $intuition, ')
          ..write('presence: $presence, ')
          ..write('skillsJson: $skillsJson, ')
          ..write('languagesJson: $languagesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroProjectSourcesTable extends HeroProjectSources
    with TableInfo<$HeroProjectSourcesTable, HeroProjectSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroProjectSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, heroId, name, type, language, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_project_sources';
  @override
  VerificationContext validateIntegrity(Insertable<HeroProjectSource> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroProjectSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroProjectSource(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HeroProjectSourcesTable createAlias(String alias) {
    return $HeroProjectSourcesTable(attachedDatabase, alias);
  }
}

class HeroProjectSource extends DataClass
    implements Insertable<HeroProjectSource> {
  final String id;
  final String heroId;
  final String name;
  final String type;
  final String? language;
  final String? description;
  final DateTime createdAt;
  const HeroProjectSource(
      {required this.id,
      required this.heroId,
      required this.name,
      required this.type,
      this.language,
      this.description,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HeroProjectSourcesCompanion toCompanion(bool nullToAbsent) {
    return HeroProjectSourcesCompanion(
      id: Value(id),
      heroId: Value(heroId),
      name: Value(name),
      type: Value(type),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory HeroProjectSource.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroProjectSource(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      language: serializer.fromJson<String?>(json['language']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'language': serializer.toJson<String?>(language),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HeroProjectSource copyWith(
          {String? id,
          String? heroId,
          String? name,
          String? type,
          Value<String?> language = const Value.absent(),
          Value<String?> description = const Value.absent(),
          DateTime? createdAt}) =>
      HeroProjectSource(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        name: name ?? this.name,
        type: type ?? this.type,
        language: language.present ? language.value : this.language,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
      );
  HeroProjectSource copyWithCompanion(HeroProjectSourcesCompanion data) {
    return HeroProjectSource(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      language: data.language.present ? data.language.value : this.language,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroProjectSource(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('language: $language, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, heroId, name, type, language, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroProjectSource &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.name == this.name &&
          other.type == this.type &&
          other.language == this.language &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class HeroProjectSourcesCompanion extends UpdateCompanion<HeroProjectSource> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> language;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HeroProjectSourcesCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.language = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroProjectSourcesCompanion.insert({
    required String id,
    required String heroId,
    required String name,
    required String type,
    this.language = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        name = Value(name),
        type = Value(type);
  static Insertable<HeroProjectSource> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? language,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (language != null) 'language': language,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroProjectSourcesCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? language,
      Value<String?>? description,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return HeroProjectSourcesCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      name: name ?? this.name,
      type: type ?? this.type,
      language: language ?? this.language,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroProjectSourcesCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('language: $language, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroNotesTable extends HeroNotes
    with TableInfo<$HeroNotesTable, HeroNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFolderMeta =
      const VerificationMeta('isFolder');
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
      'is_folder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_folder" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        title,
        content,
        folderId,
        isFolder,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_notes';
  @override
  VerificationContext validateIntegrity(Insertable<HeroNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('is_folder')) {
      context.handle(_isFolderMeta,
          isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      isFolder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_folder'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroNotesTable createAlias(String alias) {
    return $HeroNotesTable(attachedDatabase, alias);
  }
}

class HeroNote extends DataClass implements Insertable<HeroNote> {
  final String id;
  final String heroId;
  final String title;
  final String content;
  final String? folderId;
  final bool isFolder;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroNote(
      {required this.id,
      required this.heroId,
      required this.title,
      required this.content,
      this.folderId,
      required this.isFolder,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['is_folder'] = Variable<bool>(isFolder);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroNotesCompanion toCompanion(bool nullToAbsent) {
    return HeroNotesCompanion(
      id: Value(id),
      heroId: Value(heroId),
      title: Value(title),
      content: Value(content),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      isFolder: Value(isFolder),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroNote(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'folderId': serializer.toJson<String?>(folderId),
      'isFolder': serializer.toJson<bool>(isFolder),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroNote copyWith(
          {String? id,
          String? heroId,
          String? title,
          String? content,
          Value<String?> folderId = const Value.absent(),
          bool? isFolder,
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroNote(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        title: title ?? this.title,
        content: content ?? this.content,
        folderId: folderId.present ? folderId.value : this.folderId,
        isFolder: isFolder ?? this.isFolder,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroNote copyWithCompanion(HeroNotesCompanion data) {
    return HeroNote(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroNote(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('folderId: $folderId, ')
          ..write('isFolder: $isFolder, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, heroId, title, content, folderId,
      isFolder, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroNote &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.title == this.title &&
          other.content == this.content &&
          other.folderId == this.folderId &&
          other.isFolder == this.isFolder &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroNotesCompanion extends UpdateCompanion<HeroNote> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> folderId;
  final Value<bool> isFolder;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroNotesCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.folderId = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroNotesCompanion.insert({
    required String id,
    required String heroId,
    required String title,
    this.content = const Value.absent(),
    this.folderId = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        title = Value(title);
  static Insertable<HeroNote> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? folderId,
    Expression<bool>? isFolder,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (folderId != null) 'folder_id': folderId,
      if (isFolder != null) 'is_folder': isFolder,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroNotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? title,
      Value<String>? content,
      Value<String?>? folderId,
      Value<bool>? isFolder,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroNotesCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      isFolder: isFolder ?? this.isFolder,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroNotesCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('folderId: $folderId, ')
          ..write('isFolder: $isFolder, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroEntriesTable extends HeroEntries
    with TableInfo<$HeroEntriesTable, HeroEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _entryTypeMeta =
      const VerificationMeta('entryType');
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
      'entry_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('legacy'));
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _gainedByMeta =
      const VerificationMeta('gainedBy');
  @override
  late final GeneratedColumn<String> gainedBy = GeneratedColumn<String>(
      'gained_by', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('grant'));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        entryType,
        entryId,
        sourceType,
        sourceId,
        gainedBy,
        payload,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_entries';
  @override
  VerificationContext validateIntegrity(Insertable<HeroEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('entry_type')) {
      context.handle(_entryTypeMeta,
          entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta));
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('gained_by')) {
      context.handle(_gainedByMeta,
          gainedBy.isAcceptableOrUnknown(data['gained_by']!, _gainedByMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      entryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_type'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      gainedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gained_by'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroEntriesTable createAlias(String alias) {
    return $HeroEntriesTable(attachedDatabase, alias);
  }
}

class HeroEntry extends DataClass implements Insertable<HeroEntry> {
  final int id;
  final String heroId;
  final String entryType;
  final String entryId;
  final String sourceType;
  final String sourceId;
  final String gainedBy;
  final String? payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroEntry(
      {required this.id,
      required this.heroId,
      required this.entryType,
      required this.entryId,
      required this.sourceType,
      required this.sourceId,
      required this.gainedBy,
      this.payload,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['entry_type'] = Variable<String>(entryType);
    map['entry_id'] = Variable<String>(entryId);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    map['gained_by'] = Variable<String>(gainedBy);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroEntriesCompanion toCompanion(bool nullToAbsent) {
    return HeroEntriesCompanion(
      id: Value(id),
      heroId: Value(heroId),
      entryType: Value(entryType),
      entryId: Value(entryId),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      gainedBy: Value(gainedBy),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroEntry(
      id: serializer.fromJson<int>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      entryId: serializer.fromJson<String>(json['entryId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      gainedBy: serializer.fromJson<String>(json['gainedBy']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'heroId': serializer.toJson<String>(heroId),
      'entryType': serializer.toJson<String>(entryType),
      'entryId': serializer.toJson<String>(entryId),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'gainedBy': serializer.toJson<String>(gainedBy),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroEntry copyWith(
          {int? id,
          String? heroId,
          String? entryType,
          String? entryId,
          String? sourceType,
          String? sourceId,
          String? gainedBy,
          Value<String?> payload = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroEntry(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        entryType: entryType ?? this.entryType,
        entryId: entryId ?? this.entryId,
        sourceType: sourceType ?? this.sourceType,
        sourceId: sourceId ?? this.sourceId,
        gainedBy: gainedBy ?? this.gainedBy,
        payload: payload.present ? payload.value : this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroEntry copyWithCompanion(HeroEntriesCompanion data) {
    return HeroEntry(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      gainedBy: data.gainedBy.present ? data.gainedBy.value : this.gainedBy,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroEntry(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('entryType: $entryType, ')
          ..write('entryId: $entryId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('gainedBy: $gainedBy, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, heroId, entryType, entryId, sourceType,
      sourceId, gainedBy, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroEntry &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.entryType == this.entryType &&
          other.entryId == this.entryId &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.gainedBy == this.gainedBy &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroEntriesCompanion extends UpdateCompanion<HeroEntry> {
  final Value<int> id;
  final Value<String> heroId;
  final Value<String> entryType;
  final Value<String> entryId;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String> gainedBy;
  final Value<String?> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HeroEntriesCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.entryId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.gainedBy = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HeroEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String heroId,
    required String entryType,
    required String entryId,
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.gainedBy = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : heroId = Value(heroId),
        entryType = Value(entryType),
        entryId = Value(entryId);
  static Insertable<HeroEntry> custom({
    Expression<int>? id,
    Expression<String>? heroId,
    Expression<String>? entryType,
    Expression<String>? entryId,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? gainedBy,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (entryType != null) 'entry_type': entryType,
      if (entryId != null) 'entry_id': entryId,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (gainedBy != null) 'gained_by': gainedBy,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HeroEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? heroId,
      Value<String>? entryType,
      Value<String>? entryId,
      Value<String>? sourceType,
      Value<String>? sourceId,
      Value<String>? gainedBy,
      Value<String?>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return HeroEntriesCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      entryType: entryType ?? this.entryType,
      entryId: entryId ?? this.entryId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      gainedBy: gainedBy ?? this.gainedBy,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (gainedBy.present) {
      map['gained_by'] = Variable<String>(gainedBy.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroEntriesCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('entryType: $entryType, ')
          ..write('entryId: $entryId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('gainedBy: $gainedBy, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HeroConfigTable extends HeroConfig
    with TableInfo<$HeroConfigTable, HeroConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _configKeyMeta =
      const VerificationMeta('configKey');
  @override
  late final GeneratedColumn<String> configKey = GeneratedColumn<String>(
      'config_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueJsonMeta =
      const VerificationMeta('valueJson');
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
      'value_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, heroId, configKey, valueJson, metadata, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_config';
  @override
  VerificationContext validateIntegrity(Insertable<HeroConfigData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('config_key')) {
      context.handle(_configKeyMeta,
          configKey.isAcceptableOrUnknown(data['config_key']!, _configKeyMeta));
    } else if (isInserting) {
      context.missing(_configKeyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(_valueJsonMeta,
          valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta));
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroConfigData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      configKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_key'])!,
      valueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_json'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroConfigTable createAlias(String alias) {
    return $HeroConfigTable(attachedDatabase, alias);
  }
}

class HeroConfigData extends DataClass implements Insertable<HeroConfigData> {
  final int id;
  final String heroId;
  final String configKey;
  final String valueJson;
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroConfigData(
      {required this.id,
      required this.heroId,
      required this.configKey,
      required this.valueJson,
      this.metadata,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['config_key'] = Variable<String>(configKey);
    map['value_json'] = Variable<String>(valueJson);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroConfigCompanion toCompanion(bool nullToAbsent) {
    return HeroConfigCompanion(
      id: Value(id),
      heroId: Value(heroId),
      configKey: Value(configKey),
      valueJson: Value(valueJson),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroConfigData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroConfigData(
      id: serializer.fromJson<int>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      configKey: serializer.fromJson<String>(json['configKey']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'heroId': serializer.toJson<String>(heroId),
      'configKey': serializer.toJson<String>(configKey),
      'valueJson': serializer.toJson<String>(valueJson),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroConfigData copyWith(
          {int? id,
          String? heroId,
          String? configKey,
          String? valueJson,
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroConfigData(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        configKey: configKey ?? this.configKey,
        valueJson: valueJson ?? this.valueJson,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroConfigData copyWithCompanion(HeroConfigCompanion data) {
    return HeroConfigData(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      configKey: data.configKey.present ? data.configKey.value : this.configKey,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroConfigData(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('configKey: $configKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, heroId, configKey, valueJson, metadata, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroConfigData &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.configKey == this.configKey &&
          other.valueJson == this.valueJson &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroConfigCompanion extends UpdateCompanion<HeroConfigData> {
  final Value<int> id;
  final Value<String> heroId;
  final Value<String> configKey;
  final Value<String> valueJson;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HeroConfigCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.configKey = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HeroConfigCompanion.insert({
    this.id = const Value.absent(),
    required String heroId,
    required String configKey,
    required String valueJson,
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : heroId = Value(heroId),
        configKey = Value(configKey),
        valueJson = Value(valueJson);
  static Insertable<HeroConfigData> custom({
    Expression<int>? id,
    Expression<String>? heroId,
    Expression<String>? configKey,
    Expression<String>? valueJson,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (configKey != null) 'config_key': configKey,
      if (valueJson != null) 'value_json': valueJson,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HeroConfigCompanion copyWith(
      {Value<int>? id,
      Value<String>? heroId,
      Value<String>? configKey,
      Value<String>? valueJson,
      Value<String?>? metadata,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return HeroConfigCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      configKey: configKey ?? this.configKey,
      valueJson: valueJson ?? this.valueJson,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (configKey.present) {
      map['config_key'] = Variable<String>(configKey.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroConfigCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('configKey: $configKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HeroRetainersTable extends HeroRetainers
    with TableInfo<$HeroRetainersTable, HeroRetainer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroRetainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _retainerComponentIdMeta =
      const VerificationMeta('retainerComponentId');
  @override
  late final GeneratedColumn<String> retainerComponentId =
      GeneratedColumn<String>('retainer_component_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customDataJsonMeta =
      const VerificationMeta('customDataJson');
  @override
  late final GeneratedColumn<String> customDataJson = GeneratedColumn<String>(
      'custom_data_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _advancementChoicesJsonMeta =
      const VerificationMeta('advancementChoicesJson');
  @override
  late final GeneratedColumn<String> advancementChoicesJson =
      GeneratedColumn<String>('advancement_choices_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _characteristicChoicesJsonMeta =
      const VerificationMeta('characteristicChoicesJson');
  @override
  late final GeneratedColumn<String> characteristicChoicesJson =
      GeneratedColumn<String>('characteristic_choices_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currentStaminaMeta =
      const VerificationMeta('currentStamina');
  @override
  late final GeneratedColumn<int> currentStamina = GeneratedColumn<int>(
      'current_stamina', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tempStaminaMeta =
      const VerificationMeta('tempStamina');
  @override
  late final GeneratedColumn<int> tempStamina = GeneratedColumn<int>(
      'temp_stamina', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentRecoveriesMeta =
      const VerificationMeta('currentRecoveries');
  @override
  late final GeneratedColumn<int> currentRecoveries = GeneratedColumn<int>(
      'current_recoveries', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(6));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        retainerComponentId,
        name,
        role,
        isCustom,
        customDataJson,
        advancementChoicesJson,
        characteristicChoicesJson,
        level,
        currentStamina,
        tempStamina,
        currentRecoveries,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_retainers';
  @override
  VerificationContext validateIntegrity(Insertable<HeroRetainer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('retainer_component_id')) {
      context.handle(
          _retainerComponentIdMeta,
          retainerComponentId.isAcceptableOrUnknown(
              data['retainer_component_id']!, _retainerComponentIdMeta));
    } else if (isInserting) {
      context.missing(_retainerComponentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('custom_data_json')) {
      context.handle(
          _customDataJsonMeta,
          customDataJson.isAcceptableOrUnknown(
              data['custom_data_json']!, _customDataJsonMeta));
    }
    if (data.containsKey('advancement_choices_json')) {
      context.handle(
          _advancementChoicesJsonMeta,
          advancementChoicesJson.isAcceptableOrUnknown(
              data['advancement_choices_json']!, _advancementChoicesJsonMeta));
    }
    if (data.containsKey('characteristic_choices_json')) {
      context.handle(
          _characteristicChoicesJsonMeta,
          characteristicChoicesJson.isAcceptableOrUnknown(
              data['characteristic_choices_json']!,
              _characteristicChoicesJsonMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('current_stamina')) {
      context.handle(
          _currentStaminaMeta,
          currentStamina.isAcceptableOrUnknown(
              data['current_stamina']!, _currentStaminaMeta));
    }
    if (data.containsKey('temp_stamina')) {
      context.handle(
          _tempStaminaMeta,
          tempStamina.isAcceptableOrUnknown(
              data['temp_stamina']!, _tempStaminaMeta));
    }
    if (data.containsKey('current_recoveries')) {
      context.handle(
          _currentRecoveriesMeta,
          currentRecoveries.isAcceptableOrUnknown(
              data['current_recoveries']!, _currentRecoveriesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroRetainer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroRetainer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      retainerComponentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}retainer_component_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      customDataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_data_json']),
      advancementChoicesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}advancement_choices_json'])!,
      characteristicChoicesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}characteristic_choices_json'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      currentStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_stamina']),
      tempStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}temp_stamina'])!,
      currentRecoveries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_recoveries']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroRetainersTable createAlias(String alias) {
    return $HeroRetainersTable(attachedDatabase, alias);
  }
}

class HeroRetainer extends DataClass implements Insertable<HeroRetainer> {
  final String id;
  final String heroId;

  /// Component ID of the retainer template (from Components with type='retainer').
  final String retainerComponentId;
  final String name;

  /// Role slug: ambusher, brute, artillery, controller, defender, harrier,
  /// hexer, mount, support.
  final String role;
  final bool isCustom;

  /// Full stat block JSON for custom retainers built from monster stat blocks.
  final String? customDataJson;

  /// JSON map of level (int) → chosen ability component ID at levels 4/7/10.
  final String advancementChoicesJson;

  /// JSON map of level (int) → characteristic name at levels 2/8.
  final String characteristicChoicesJson;

  /// The retainer's own tracked level (1-10). Retainers level up
  /// independently of their hero — this does not auto-follow the hero's
  /// level, though the UI prompts to level up once the hero outpaces it.
  final int level;
  final int? currentStamina;
  final int tempStamina;
  final int? currentRecoveries;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroRetainer(
      {required this.id,
      required this.heroId,
      required this.retainerComponentId,
      required this.name,
      required this.role,
      required this.isCustom,
      this.customDataJson,
      required this.advancementChoicesJson,
      required this.characteristicChoicesJson,
      required this.level,
      this.currentStamina,
      required this.tempStamina,
      this.currentRecoveries,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['retainer_component_id'] = Variable<String>(retainerComponentId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || customDataJson != null) {
      map['custom_data_json'] = Variable<String>(customDataJson);
    }
    map['advancement_choices_json'] = Variable<String>(advancementChoicesJson);
    map['characteristic_choices_json'] =
        Variable<String>(characteristicChoicesJson);
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || currentStamina != null) {
      map['current_stamina'] = Variable<int>(currentStamina);
    }
    map['temp_stamina'] = Variable<int>(tempStamina);
    if (!nullToAbsent || currentRecoveries != null) {
      map['current_recoveries'] = Variable<int>(currentRecoveries);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroRetainersCompanion toCompanion(bool nullToAbsent) {
    return HeroRetainersCompanion(
      id: Value(id),
      heroId: Value(heroId),
      retainerComponentId: Value(retainerComponentId),
      name: Value(name),
      role: Value(role),
      isCustom: Value(isCustom),
      customDataJson: customDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customDataJson),
      advancementChoicesJson: Value(advancementChoicesJson),
      characteristicChoicesJson: Value(characteristicChoicesJson),
      level: Value(level),
      currentStamina: currentStamina == null && nullToAbsent
          ? const Value.absent()
          : Value(currentStamina),
      tempStamina: Value(tempStamina),
      currentRecoveries: currentRecoveries == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRecoveries),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroRetainer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroRetainer(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      retainerComponentId:
          serializer.fromJson<String>(json['retainerComponentId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      customDataJson: serializer.fromJson<String?>(json['customDataJson']),
      advancementChoicesJson:
          serializer.fromJson<String>(json['advancementChoicesJson']),
      characteristicChoicesJson:
          serializer.fromJson<String>(json['characteristicChoicesJson']),
      level: serializer.fromJson<int>(json['level']),
      currentStamina: serializer.fromJson<int?>(json['currentStamina']),
      tempStamina: serializer.fromJson<int>(json['tempStamina']),
      currentRecoveries: serializer.fromJson<int?>(json['currentRecoveries']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'retainerComponentId': serializer.toJson<String>(retainerComponentId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'isCustom': serializer.toJson<bool>(isCustom),
      'customDataJson': serializer.toJson<String?>(customDataJson),
      'advancementChoicesJson':
          serializer.toJson<String>(advancementChoicesJson),
      'characteristicChoicesJson':
          serializer.toJson<String>(characteristicChoicesJson),
      'level': serializer.toJson<int>(level),
      'currentStamina': serializer.toJson<int?>(currentStamina),
      'tempStamina': serializer.toJson<int>(tempStamina),
      'currentRecoveries': serializer.toJson<int?>(currentRecoveries),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroRetainer copyWith(
          {String? id,
          String? heroId,
          String? retainerComponentId,
          String? name,
          String? role,
          bool? isCustom,
          Value<String?> customDataJson = const Value.absent(),
          String? advancementChoicesJson,
          String? characteristicChoicesJson,
          int? level,
          Value<int?> currentStamina = const Value.absent(),
          int? tempStamina,
          Value<int?> currentRecoveries = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroRetainer(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        retainerComponentId: retainerComponentId ?? this.retainerComponentId,
        name: name ?? this.name,
        role: role ?? this.role,
        isCustom: isCustom ?? this.isCustom,
        customDataJson:
            customDataJson.present ? customDataJson.value : this.customDataJson,
        advancementChoicesJson:
            advancementChoicesJson ?? this.advancementChoicesJson,
        characteristicChoicesJson:
            characteristicChoicesJson ?? this.characteristicChoicesJson,
        level: level ?? this.level,
        currentStamina:
            currentStamina.present ? currentStamina.value : this.currentStamina,
        tempStamina: tempStamina ?? this.tempStamina,
        currentRecoveries: currentRecoveries.present
            ? currentRecoveries.value
            : this.currentRecoveries,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroRetainer copyWithCompanion(HeroRetainersCompanion data) {
    return HeroRetainer(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      retainerComponentId: data.retainerComponentId.present
          ? data.retainerComponentId.value
          : this.retainerComponentId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      customDataJson: data.customDataJson.present
          ? data.customDataJson.value
          : this.customDataJson,
      advancementChoicesJson: data.advancementChoicesJson.present
          ? data.advancementChoicesJson.value
          : this.advancementChoicesJson,
      characteristicChoicesJson: data.characteristicChoicesJson.present
          ? data.characteristicChoicesJson.value
          : this.characteristicChoicesJson,
      level: data.level.present ? data.level.value : this.level,
      currentStamina: data.currentStamina.present
          ? data.currentStamina.value
          : this.currentStamina,
      tempStamina:
          data.tempStamina.present ? data.tempStamina.value : this.tempStamina,
      currentRecoveries: data.currentRecoveries.present
          ? data.currentRecoveries.value
          : this.currentRecoveries,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroRetainer(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('retainerComponentId: $retainerComponentId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('isCustom: $isCustom, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('advancementChoicesJson: $advancementChoicesJson, ')
          ..write('characteristicChoicesJson: $characteristicChoicesJson, ')
          ..write('level: $level, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('currentRecoveries: $currentRecoveries, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      heroId,
      retainerComponentId,
      name,
      role,
      isCustom,
      customDataJson,
      advancementChoicesJson,
      characteristicChoicesJson,
      level,
      currentStamina,
      tempStamina,
      currentRecoveries,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroRetainer &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.retainerComponentId == this.retainerComponentId &&
          other.name == this.name &&
          other.role == this.role &&
          other.isCustom == this.isCustom &&
          other.customDataJson == this.customDataJson &&
          other.advancementChoicesJson == this.advancementChoicesJson &&
          other.characteristicChoicesJson == this.characteristicChoicesJson &&
          other.level == this.level &&
          other.currentStamina == this.currentStamina &&
          other.tempStamina == this.tempStamina &&
          other.currentRecoveries == this.currentRecoveries &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroRetainersCompanion extends UpdateCompanion<HeroRetainer> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> retainerComponentId;
  final Value<String> name;
  final Value<String> role;
  final Value<bool> isCustom;
  final Value<String?> customDataJson;
  final Value<String> advancementChoicesJson;
  final Value<String> characteristicChoicesJson;
  final Value<int> level;
  final Value<int?> currentStamina;
  final Value<int> tempStamina;
  final Value<int?> currentRecoveries;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroRetainersCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.retainerComponentId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.customDataJson = const Value.absent(),
    this.advancementChoicesJson = const Value.absent(),
    this.characteristicChoicesJson = const Value.absent(),
    this.level = const Value.absent(),
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.currentRecoveries = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroRetainersCompanion.insert({
    required String id,
    required String heroId,
    required String retainerComponentId,
    required String name,
    required String role,
    this.isCustom = const Value.absent(),
    this.customDataJson = const Value.absent(),
    this.advancementChoicesJson = const Value.absent(),
    this.characteristicChoicesJson = const Value.absent(),
    this.level = const Value.absent(),
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.currentRecoveries = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        retainerComponentId = Value(retainerComponentId),
        name = Value(name),
        role = Value(role);
  static Insertable<HeroRetainer> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? retainerComponentId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<bool>? isCustom,
    Expression<String>? customDataJson,
    Expression<String>? advancementChoicesJson,
    Expression<String>? characteristicChoicesJson,
    Expression<int>? level,
    Expression<int>? currentStamina,
    Expression<int>? tempStamina,
    Expression<int>? currentRecoveries,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (retainerComponentId != null)
        'retainer_component_id': retainerComponentId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (isCustom != null) 'is_custom': isCustom,
      if (customDataJson != null) 'custom_data_json': customDataJson,
      if (advancementChoicesJson != null)
        'advancement_choices_json': advancementChoicesJson,
      if (characteristicChoicesJson != null)
        'characteristic_choices_json': characteristicChoicesJson,
      if (level != null) 'level': level,
      if (currentStamina != null) 'current_stamina': currentStamina,
      if (tempStamina != null) 'temp_stamina': tempStamina,
      if (currentRecoveries != null) 'current_recoveries': currentRecoveries,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroRetainersCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? retainerComponentId,
      Value<String>? name,
      Value<String>? role,
      Value<bool>? isCustom,
      Value<String?>? customDataJson,
      Value<String>? advancementChoicesJson,
      Value<String>? characteristicChoicesJson,
      Value<int>? level,
      Value<int?>? currentStamina,
      Value<int>? tempStamina,
      Value<int?>? currentRecoveries,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroRetainersCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      retainerComponentId: retainerComponentId ?? this.retainerComponentId,
      name: name ?? this.name,
      role: role ?? this.role,
      isCustom: isCustom ?? this.isCustom,
      customDataJson: customDataJson ?? this.customDataJson,
      advancementChoicesJson:
          advancementChoicesJson ?? this.advancementChoicesJson,
      characteristicChoicesJson:
          characteristicChoicesJson ?? this.characteristicChoicesJson,
      level: level ?? this.level,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      currentRecoveries: currentRecoveries ?? this.currentRecoveries,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (retainerComponentId.present) {
      map['retainer_component_id'] =
          Variable<String>(retainerComponentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (customDataJson.present) {
      map['custom_data_json'] = Variable<String>(customDataJson.value);
    }
    if (advancementChoicesJson.present) {
      map['advancement_choices_json'] =
          Variable<String>(advancementChoicesJson.value);
    }
    if (characteristicChoicesJson.present) {
      map['characteristic_choices_json'] =
          Variable<String>(characteristicChoicesJson.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (currentStamina.present) {
      map['current_stamina'] = Variable<int>(currentStamina.value);
    }
    if (tempStamina.present) {
      map['temp_stamina'] = Variable<int>(tempStamina.value);
    }
    if (currentRecoveries.present) {
      map['current_recoveries'] = Variable<int>(currentRecoveries.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroRetainersCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('retainerComponentId: $retainerComponentId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('isCustom: $isCustom, ')
          ..write('customDataJson: $customDataJson, ')
          ..write('advancementChoicesJson: $advancementChoicesJson, ')
          ..write('characteristicChoicesJson: $characteristicChoicesJson, ')
          ..write('level: $level, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('currentRecoveries: $currentRecoveries, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroCompanionsTable extends HeroCompanions
    with TableInfo<$HeroCompanionsTable, HeroCompanion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroCompanionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _companionComponentIdMeta =
      const VerificationMeta('companionComponentId');
  @override
  late final GeneratedColumn<String> companionComponentId =
      GeneratedColumn<String>('companion_component_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentStaminaMeta =
      const VerificationMeta('currentStamina');
  @override
  late final GeneratedColumn<int> currentStamina = GeneratedColumn<int>(
      'current_stamina', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tempStaminaMeta =
      const VerificationMeta('tempStamina');
  @override
  late final GeneratedColumn<int> tempStamina = GeneratedColumn<int>(
      'temp_stamina', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentRampageMeta =
      const VerificationMeta('currentRampage');
  @override
  late final GeneratedColumn<int> currentRampage = GeneratedColumn<int>(
      'current_rampage', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        companionComponentId,
        name,
        currentStamina,
        tempStamina,
        currentRampage,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_companions';
  @override
  VerificationContext validateIntegrity(Insertable<HeroCompanion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('companion_component_id')) {
      context.handle(
          _companionComponentIdMeta,
          companionComponentId.isAcceptableOrUnknown(
              data['companion_component_id']!, _companionComponentIdMeta));
    } else if (isInserting) {
      context.missing(_companionComponentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('current_stamina')) {
      context.handle(
          _currentStaminaMeta,
          currentStamina.isAcceptableOrUnknown(
              data['current_stamina']!, _currentStaminaMeta));
    }
    if (data.containsKey('temp_stamina')) {
      context.handle(
          _tempStaminaMeta,
          tempStamina.isAcceptableOrUnknown(
              data['temp_stamina']!, _tempStaminaMeta));
    }
    if (data.containsKey('current_rampage')) {
      context.handle(
          _currentRampageMeta,
          currentRampage.isAcceptableOrUnknown(
              data['current_rampage']!, _currentRampageMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroCompanion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroCompanion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      companionComponentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}companion_component_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      currentStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_stamina']),
      tempStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}temp_stamina'])!,
      currentRampage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_rampage'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroCompanionsTable createAlias(String alias) {
    return $HeroCompanionsTable(attachedDatabase, alias);
  }
}

class HeroCompanion extends DataClass implements Insertable<HeroCompanion> {
  final String id;
  final String heroId;

  /// Component ID of the companion template (from Components with type='companion').
  final String companionComponentId;
  final String name;
  final int? currentStamina;
  final int tempStamina;

  /// The companion's current rampage stacks (Beastheart "Rampage" resource).
  /// Tracked on the companion, not the hero, and adjusted manually — it isn't
  /// tied to the class heroic resource generation. Lost at end of encounter.
  final int currentRampage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroCompanion(
      {required this.id,
      required this.heroId,
      required this.companionComponentId,
      required this.name,
      this.currentStamina,
      required this.tempStamina,
      required this.currentRampage,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['companion_component_id'] = Variable<String>(companionComponentId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || currentStamina != null) {
      map['current_stamina'] = Variable<int>(currentStamina);
    }
    map['temp_stamina'] = Variable<int>(tempStamina);
    map['current_rampage'] = Variable<int>(currentRampage);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroCompanionsCompanion toCompanion(bool nullToAbsent) {
    return HeroCompanionsCompanion(
      id: Value(id),
      heroId: Value(heroId),
      companionComponentId: Value(companionComponentId),
      name: Value(name),
      currentStamina: currentStamina == null && nullToAbsent
          ? const Value.absent()
          : Value(currentStamina),
      tempStamina: Value(tempStamina),
      currentRampage: Value(currentRampage),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroCompanion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroCompanion(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      companionComponentId:
          serializer.fromJson<String>(json['companionComponentId']),
      name: serializer.fromJson<String>(json['name']),
      currentStamina: serializer.fromJson<int?>(json['currentStamina']),
      tempStamina: serializer.fromJson<int>(json['tempStamina']),
      currentRampage: serializer.fromJson<int>(json['currentRampage']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'companionComponentId': serializer.toJson<String>(companionComponentId),
      'name': serializer.toJson<String>(name),
      'currentStamina': serializer.toJson<int?>(currentStamina),
      'tempStamina': serializer.toJson<int>(tempStamina),
      'currentRampage': serializer.toJson<int>(currentRampage),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroCompanion copyWith(
          {String? id,
          String? heroId,
          String? companionComponentId,
          String? name,
          Value<int?> currentStamina = const Value.absent(),
          int? tempStamina,
          int? currentRampage,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroCompanion(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        companionComponentId: companionComponentId ?? this.companionComponentId,
        name: name ?? this.name,
        currentStamina:
            currentStamina.present ? currentStamina.value : this.currentStamina,
        tempStamina: tempStamina ?? this.tempStamina,
        currentRampage: currentRampage ?? this.currentRampage,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroCompanion copyWithCompanion(HeroCompanionsCompanion data) {
    return HeroCompanion(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      companionComponentId: data.companionComponentId.present
          ? data.companionComponentId.value
          : this.companionComponentId,
      name: data.name.present ? data.name.value : this.name,
      currentStamina: data.currentStamina.present
          ? data.currentStamina.value
          : this.currentStamina,
      tempStamina:
          data.tempStamina.present ? data.tempStamina.value : this.tempStamina,
      currentRampage: data.currentRampage.present
          ? data.currentRampage.value
          : this.currentRampage,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('companionComponentId: $companionComponentId, ')
          ..write('name: $name, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('currentRampage: $currentRampage, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      heroId,
      companionComponentId,
      name,
      currentStamina,
      tempStamina,
      currentRampage,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroCompanion &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.companionComponentId == this.companionComponentId &&
          other.name == this.name &&
          other.currentStamina == this.currentStamina &&
          other.tempStamina == this.tempStamina &&
          other.currentRampage == this.currentRampage &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroCompanionsCompanion extends UpdateCompanion<HeroCompanion> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> companionComponentId;
  final Value<String> name;
  final Value<int?> currentStamina;
  final Value<int> tempStamina;
  final Value<int> currentRampage;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroCompanionsCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.companionComponentId = const Value.absent(),
    this.name = const Value.absent(),
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.currentRampage = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroCompanionsCompanion.insert({
    required String id,
    required String heroId,
    required String companionComponentId,
    required String name,
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.currentRampage = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        companionComponentId = Value(companionComponentId),
        name = Value(name);
  static Insertable<HeroCompanion> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? companionComponentId,
    Expression<String>? name,
    Expression<int>? currentStamina,
    Expression<int>? tempStamina,
    Expression<int>? currentRampage,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (companionComponentId != null)
        'companion_component_id': companionComponentId,
      if (name != null) 'name': name,
      if (currentStamina != null) 'current_stamina': currentStamina,
      if (tempStamina != null) 'temp_stamina': tempStamina,
      if (currentRampage != null) 'current_rampage': currentRampage,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroCompanionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? companionComponentId,
      Value<String>? name,
      Value<int?>? currentStamina,
      Value<int>? tempStamina,
      Value<int>? currentRampage,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroCompanionsCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      companionComponentId: companionComponentId ?? this.companionComponentId,
      name: name ?? this.name,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      currentRampage: currentRampage ?? this.currentRampage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (companionComponentId.present) {
      map['companion_component_id'] =
          Variable<String>(companionComponentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currentStamina.present) {
      map['current_stamina'] = Variable<int>(currentStamina.value);
    }
    if (tempStamina.present) {
      map['temp_stamina'] = Variable<int>(tempStamina.value);
    }
    if (currentRampage.present) {
      map['current_rampage'] = Variable<int>(currentRampage.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroCompanionsCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('companionComponentId: $companionComponentId, ')
          ..write('name: $name, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('currentRampage: $currentRampage, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeroMinionSquadsTable extends HeroMinionSquads
    with TableInfo<$HeroMinionSquadsTable, HeroMinionSquad> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeroMinionSquadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heroIdMeta = const VerificationMeta('heroId');
  @override
  late final GeneratedColumn<String> heroId = GeneratedColumn<String>(
      'hero_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES heroes (id)'));
  static const VerificationMeta _minionComponentIdMeta =
      const VerificationMeta('minionComponentId');
  @override
  late final GeneratedColumn<String> minionComponentId =
      GeneratedColumn<String>('minion_component_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _squadNameMeta =
      const VerificationMeta('squadName');
  @override
  late final GeneratedColumn<String> squadName = GeneratedColumn<String>(
      'squad_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberCountMeta =
      const VerificationMeta('memberCount');
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
      'member_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currentStaminaMeta =
      const VerificationMeta('currentStamina');
  @override
  late final GeneratedColumn<int> currentStamina = GeneratedColumn<int>(
      'current_stamina', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tempStaminaMeta =
      const VerificationMeta('tempStamina');
  @override
  late final GeneratedColumn<int> tempStamina = GeneratedColumn<int>(
      'temp_stamina', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        heroId,
        minionComponentId,
        squadName,
        memberCount,
        currentStamina,
        tempStamina,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hero_minion_squads';
  @override
  VerificationContext validateIntegrity(Insertable<HeroMinionSquad> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hero_id')) {
      context.handle(_heroIdMeta,
          heroId.isAcceptableOrUnknown(data['hero_id']!, _heroIdMeta));
    } else if (isInserting) {
      context.missing(_heroIdMeta);
    }
    if (data.containsKey('minion_component_id')) {
      context.handle(
          _minionComponentIdMeta,
          minionComponentId.isAcceptableOrUnknown(
              data['minion_component_id']!, _minionComponentIdMeta));
    } else if (isInserting) {
      context.missing(_minionComponentIdMeta);
    }
    if (data.containsKey('squad_name')) {
      context.handle(_squadNameMeta,
          squadName.isAcceptableOrUnknown(data['squad_name']!, _squadNameMeta));
    } else if (isInserting) {
      context.missing(_squadNameMeta);
    }
    if (data.containsKey('member_count')) {
      context.handle(
          _memberCountMeta,
          memberCount.isAcceptableOrUnknown(
              data['member_count']!, _memberCountMeta));
    }
    if (data.containsKey('current_stamina')) {
      context.handle(
          _currentStaminaMeta,
          currentStamina.isAcceptableOrUnknown(
              data['current_stamina']!, _currentStaminaMeta));
    }
    if (data.containsKey('temp_stamina')) {
      context.handle(
          _tempStaminaMeta,
          tempStamina.isAcceptableOrUnknown(
              data['temp_stamina']!, _tempStaminaMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeroMinionSquad map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeroMinionSquad(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      heroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hero_id'])!,
      minionComponentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}minion_component_id'])!,
      squadName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}squad_name'])!,
      memberCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}member_count'])!,
      currentStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_stamina']),
      tempStamina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}temp_stamina'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HeroMinionSquadsTable createAlias(String alias) {
    return $HeroMinionSquadsTable(attachedDatabase, alias);
  }
}

class HeroMinionSquad extends DataClass implements Insertable<HeroMinionSquad> {
  final String id;
  final String heroId;

  /// Component ID of the minion template (from Components with type='minion').
  final String minionComponentId;
  final String squadName;
  final int memberCount;
  final int? currentStamina;
  final int tempStamina;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HeroMinionSquad(
      {required this.id,
      required this.heroId,
      required this.minionComponentId,
      required this.squadName,
      required this.memberCount,
      this.currentStamina,
      required this.tempStamina,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hero_id'] = Variable<String>(heroId);
    map['minion_component_id'] = Variable<String>(minionComponentId);
    map['squad_name'] = Variable<String>(squadName);
    map['member_count'] = Variable<int>(memberCount);
    if (!nullToAbsent || currentStamina != null) {
      map['current_stamina'] = Variable<int>(currentStamina);
    }
    map['temp_stamina'] = Variable<int>(tempStamina);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HeroMinionSquadsCompanion toCompanion(bool nullToAbsent) {
    return HeroMinionSquadsCompanion(
      id: Value(id),
      heroId: Value(heroId),
      minionComponentId: Value(minionComponentId),
      squadName: Value(squadName),
      memberCount: Value(memberCount),
      currentStamina: currentStamina == null && nullToAbsent
          ? const Value.absent()
          : Value(currentStamina),
      tempStamina: Value(tempStamina),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HeroMinionSquad.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeroMinionSquad(
      id: serializer.fromJson<String>(json['id']),
      heroId: serializer.fromJson<String>(json['heroId']),
      minionComponentId: serializer.fromJson<String>(json['minionComponentId']),
      squadName: serializer.fromJson<String>(json['squadName']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      currentStamina: serializer.fromJson<int?>(json['currentStamina']),
      tempStamina: serializer.fromJson<int>(json['tempStamina']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'heroId': serializer.toJson<String>(heroId),
      'minionComponentId': serializer.toJson<String>(minionComponentId),
      'squadName': serializer.toJson<String>(squadName),
      'memberCount': serializer.toJson<int>(memberCount),
      'currentStamina': serializer.toJson<int?>(currentStamina),
      'tempStamina': serializer.toJson<int>(tempStamina),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HeroMinionSquad copyWith(
          {String? id,
          String? heroId,
          String? minionComponentId,
          String? squadName,
          int? memberCount,
          Value<int?> currentStamina = const Value.absent(),
          int? tempStamina,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HeroMinionSquad(
        id: id ?? this.id,
        heroId: heroId ?? this.heroId,
        minionComponentId: minionComponentId ?? this.minionComponentId,
        squadName: squadName ?? this.squadName,
        memberCount: memberCount ?? this.memberCount,
        currentStamina:
            currentStamina.present ? currentStamina.value : this.currentStamina,
        tempStamina: tempStamina ?? this.tempStamina,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HeroMinionSquad copyWithCompanion(HeroMinionSquadsCompanion data) {
    return HeroMinionSquad(
      id: data.id.present ? data.id.value : this.id,
      heroId: data.heroId.present ? data.heroId.value : this.heroId,
      minionComponentId: data.minionComponentId.present
          ? data.minionComponentId.value
          : this.minionComponentId,
      squadName: data.squadName.present ? data.squadName.value : this.squadName,
      memberCount:
          data.memberCount.present ? data.memberCount.value : this.memberCount,
      currentStamina: data.currentStamina.present
          ? data.currentStamina.value
          : this.currentStamina,
      tempStamina:
          data.tempStamina.present ? data.tempStamina.value : this.tempStamina,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeroMinionSquad(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('minionComponentId: $minionComponentId, ')
          ..write('squadName: $squadName, ')
          ..write('memberCount: $memberCount, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, heroId, minionComponentId, squadName,
      memberCount, currentStamina, tempStamina, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeroMinionSquad &&
          other.id == this.id &&
          other.heroId == this.heroId &&
          other.minionComponentId == this.minionComponentId &&
          other.squadName == this.squadName &&
          other.memberCount == this.memberCount &&
          other.currentStamina == this.currentStamina &&
          other.tempStamina == this.tempStamina &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HeroMinionSquadsCompanion extends UpdateCompanion<HeroMinionSquad> {
  final Value<String> id;
  final Value<String> heroId;
  final Value<String> minionComponentId;
  final Value<String> squadName;
  final Value<int> memberCount;
  final Value<int?> currentStamina;
  final Value<int> tempStamina;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HeroMinionSquadsCompanion({
    this.id = const Value.absent(),
    this.heroId = const Value.absent(),
    this.minionComponentId = const Value.absent(),
    this.squadName = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeroMinionSquadsCompanion.insert({
    required String id,
    required String heroId,
    required String minionComponentId,
    required String squadName,
    this.memberCount = const Value.absent(),
    this.currentStamina = const Value.absent(),
    this.tempStamina = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        heroId = Value(heroId),
        minionComponentId = Value(minionComponentId),
        squadName = Value(squadName);
  static Insertable<HeroMinionSquad> custom({
    Expression<String>? id,
    Expression<String>? heroId,
    Expression<String>? minionComponentId,
    Expression<String>? squadName,
    Expression<int>? memberCount,
    Expression<int>? currentStamina,
    Expression<int>? tempStamina,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heroId != null) 'hero_id': heroId,
      if (minionComponentId != null) 'minion_component_id': minionComponentId,
      if (squadName != null) 'squad_name': squadName,
      if (memberCount != null) 'member_count': memberCount,
      if (currentStamina != null) 'current_stamina': currentStamina,
      if (tempStamina != null) 'temp_stamina': tempStamina,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeroMinionSquadsCompanion copyWith(
      {Value<String>? id,
      Value<String>? heroId,
      Value<String>? minionComponentId,
      Value<String>? squadName,
      Value<int>? memberCount,
      Value<int?>? currentStamina,
      Value<int>? tempStamina,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HeroMinionSquadsCompanion(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      minionComponentId: minionComponentId ?? this.minionComponentId,
      squadName: squadName ?? this.squadName,
      memberCount: memberCount ?? this.memberCount,
      currentStamina: currentStamina ?? this.currentStamina,
      tempStamina: tempStamina ?? this.tempStamina,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (heroId.present) {
      map['hero_id'] = Variable<String>(heroId.value);
    }
    if (minionComponentId.present) {
      map['minion_component_id'] = Variable<String>(minionComponentId.value);
    }
    if (squadName.present) {
      map['squad_name'] = Variable<String>(squadName.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (currentStamina.present) {
      map['current_stamina'] = Variable<int>(currentStamina.value);
    }
    if (tempStamina.present) {
      map['temp_stamina'] = Variable<int>(tempStamina.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeroMinionSquadsCompanion(')
          ..write('id: $id, ')
          ..write('heroId: $heroId, ')
          ..write('minionComponentId: $minionComponentId, ')
          ..write('squadName: $squadName, ')
          ..write('memberCount: $memberCount, ')
          ..write('currentStamina: $currentStamina, ')
          ..write('tempStamina: $tempStamina, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ComponentsTable components = $ComponentsTable(this);
  late final $HeroesTable heroes = $HeroesTable(this);
  late final $HeroValuesTable heroValues = $HeroValuesTable(this);
  late final $MetaEntriesTable metaEntries = $MetaEntriesTable(this);
  late final $HeroDowntimeProjectsTable heroDowntimeProjects =
      $HeroDowntimeProjectsTable(this);
  late final $HeroFollowersTable heroFollowers = $HeroFollowersTable(this);
  late final $HeroProjectSourcesTable heroProjectSources =
      $HeroProjectSourcesTable(this);
  late final $HeroNotesTable heroNotes = $HeroNotesTable(this);
  late final $HeroEntriesTable heroEntries = $HeroEntriesTable(this);
  late final $HeroConfigTable heroConfig = $HeroConfigTable(this);
  late final $HeroRetainersTable heroRetainers = $HeroRetainersTable(this);
  late final $HeroCompanionsTable heroCompanions = $HeroCompanionsTable(this);
  late final $HeroMinionSquadsTable heroMinionSquads =
      $HeroMinionSquadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        components,
        heroes,
        heroValues,
        metaEntries,
        heroDowntimeProjects,
        heroFollowers,
        heroProjectSources,
        heroNotes,
        heroEntries,
        heroConfig,
        heroRetainers,
        heroCompanions,
        heroMinionSquads
      ];
}

typedef $$ComponentsTableCreateCompanionBuilder = ComponentsCompanion Function({
  required String id,
  required String type,
  required String name,
  Value<String> dataJson,
  Value<String> source,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ComponentsTableUpdateCompanionBuilder = ComponentsCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<String> name,
  Value<String> dataJson,
  Value<String> source,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ComponentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ComponentsTable,
    Component,
    $$ComponentsTableFilterComposer,
    $$ComponentsTableOrderingComposer,
    $$ComponentsTableCreateCompanionBuilder,
    $$ComponentsTableUpdateCompanionBuilder> {
  $$ComponentsTableTableManager(_$AppDatabase db, $ComponentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ComponentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ComponentsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dataJson = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ComponentsCompanion(
            id: id,
            type: type,
            name: name,
            dataJson: dataJson,
            source: source,
            parentId: parentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String name,
            Value<String> dataJson = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ComponentsCompanion.insert(
            id: id,
            type: type,
            name: name,
            dataJson: dataJson,
            source: source,
            parentId: parentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$ComponentsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dataJson => $state.composableBuilder(
      column: $state.table.dataJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ComponentsTableFilterComposer get parentId {
    final $$ComponentsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $state.db.components,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ComponentsTableFilterComposer(ComposerState($state.db,
                $state.db.components, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter heroesRefs(
      ComposableFilter Function($$HeroesTableFilterComposer f) f) {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.classComponentId,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ComponentsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dataJson => $state.composableBuilder(
      column: $state.table.dataJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ComponentsTableOrderingComposer get parentId {
    final $$ComponentsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $state.db.components,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ComponentsTableOrderingComposer(ComposerState($state.db,
                $state.db.components, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroesTableCreateCompanionBuilder = HeroesCompanion Function({
  required String id,
  required String name,
  Value<String?> classComponentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroesTableUpdateCompanionBuilder = HeroesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> classComponentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroesTable,
    Heroe,
    $$HeroesTableFilterComposer,
    $$HeroesTableOrderingComposer,
    $$HeroesTableCreateCompanionBuilder,
    $$HeroesTableUpdateCompanionBuilder> {
  $$HeroesTableTableManager(_$AppDatabase db, $HeroesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> classComponentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroesCompanion(
            id: id,
            name: name,
            classComponentId: classComponentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> classComponentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroesCompanion.insert(
            id: id,
            name: name,
            classComponentId: classComponentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroesTable> {
  $$HeroesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ComponentsTableFilterComposer get classComponentId {
    final $$ComponentsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classComponentId,
        referencedTable: $state.db.components,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ComponentsTableFilterComposer(ComposerState($state.db,
                $state.db.components, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter heroValuesRefs(
      ComposableFilter Function($$HeroValuesTableFilterComposer f) f) {
    final $$HeroValuesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroValues,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroValuesTableFilterComposer(ComposerState($state.db,
                $state.db.heroValues, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroDowntimeProjectsRefs(
      ComposableFilter Function($$HeroDowntimeProjectsTableFilterComposer f)
          f) {
    final $$HeroDowntimeProjectsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.heroDowntimeProjects,
            getReferencedColumn: (t) => t.heroId,
            builder: (joinBuilder, parentComposers) =>
                $$HeroDowntimeProjectsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.heroDowntimeProjects,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter heroFollowersRefs(
      ComposableFilter Function($$HeroFollowersTableFilterComposer f) f) {
    final $$HeroFollowersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroFollowers,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroFollowersTableFilterComposer(ComposerState($state.db,
                $state.db.heroFollowers, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroProjectSourcesRefs(
      ComposableFilter Function($$HeroProjectSourcesTableFilterComposer f) f) {
    final $$HeroProjectSourcesTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.heroProjectSources,
            getReferencedColumn: (t) => t.heroId,
            builder: (joinBuilder, parentComposers) =>
                $$HeroProjectSourcesTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.heroProjectSources,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter heroNotesRefs(
      ComposableFilter Function($$HeroNotesTableFilterComposer f) f) {
    final $$HeroNotesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroNotes,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroNotesTableFilterComposer(ComposerState(
                $state.db, $state.db.heroNotes, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroEntriesRefs(
      ComposableFilter Function($$HeroEntriesTableFilterComposer f) f) {
    final $$HeroEntriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroEntries,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroEntriesTableFilterComposer(ComposerState($state.db,
                $state.db.heroEntries, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroConfigRefs(
      ComposableFilter Function($$HeroConfigTableFilterComposer f) f) {
    final $$HeroConfigTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroConfig,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroConfigTableFilterComposer(ComposerState($state.db,
                $state.db.heroConfig, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroRetainersRefs(
      ComposableFilter Function($$HeroRetainersTableFilterComposer f) f) {
    final $$HeroRetainersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroRetainers,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroRetainersTableFilterComposer(ComposerState($state.db,
                $state.db.heroRetainers, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroCompanionsRefs(
      ComposableFilter Function($$HeroCompanionsTableFilterComposer f) f) {
    final $$HeroCompanionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.heroCompanions,
        getReferencedColumn: (t) => t.heroId,
        builder: (joinBuilder, parentComposers) =>
            $$HeroCompanionsTableFilterComposer(ComposerState($state.db,
                $state.db.heroCompanions, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter heroMinionSquadsRefs(
      ComposableFilter Function($$HeroMinionSquadsTableFilterComposer f) f) {
    final $$HeroMinionSquadsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.heroMinionSquads,
            getReferencedColumn: (t) => t.heroId,
            builder: (joinBuilder, parentComposers) =>
                $$HeroMinionSquadsTableFilterComposer(ComposerState($state.db,
                    $state.db.heroMinionSquads, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$HeroesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroesTable> {
  $$HeroesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ComponentsTableOrderingComposer get classComponentId {
    final $$ComponentsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classComponentId,
        referencedTable: $state.db.components,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ComponentsTableOrderingComposer(ComposerState($state.db,
                $state.db.components, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroValuesTableCreateCompanionBuilder = HeroValuesCompanion Function({
  Value<int> id,
  required String heroId,
  required String key,
  Value<int?> value,
  Value<int?> maxValue,
  Value<double?> doubleValue,
  Value<String?> textValue,
  Value<String?> jsonValue,
  Value<DateTime> updatedAt,
});
typedef $$HeroValuesTableUpdateCompanionBuilder = HeroValuesCompanion Function({
  Value<int> id,
  Value<String> heroId,
  Value<String> key,
  Value<int?> value,
  Value<int?> maxValue,
  Value<double?> doubleValue,
  Value<String?> textValue,
  Value<String?> jsonValue,
  Value<DateTime> updatedAt,
});

class $$HeroValuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroValuesTable,
    HeroValue,
    $$HeroValuesTableFilterComposer,
    $$HeroValuesTableOrderingComposer,
    $$HeroValuesTableCreateCompanionBuilder,
    $$HeroValuesTableUpdateCompanionBuilder> {
  $$HeroValuesTableTableManager(_$AppDatabase db, $HeroValuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroValuesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroValuesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<int?> value = const Value.absent(),
            Value<int?> maxValue = const Value.absent(),
            Value<double?> doubleValue = const Value.absent(),
            Value<String?> textValue = const Value.absent(),
            Value<String?> jsonValue = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroValuesCompanion(
            id: id,
            heroId: heroId,
            key: key,
            value: value,
            maxValue: maxValue,
            doubleValue: doubleValue,
            textValue: textValue,
            jsonValue: jsonValue,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String heroId,
            required String key,
            Value<int?> value = const Value.absent(),
            Value<int?> maxValue = const Value.absent(),
            Value<double?> doubleValue = const Value.absent(),
            Value<String?> textValue = const Value.absent(),
            Value<String?> jsonValue = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroValuesCompanion.insert(
            id: id,
            heroId: heroId,
            key: key,
            value: value,
            maxValue: maxValue,
            doubleValue: doubleValue,
            textValue: textValue,
            jsonValue: jsonValue,
            updatedAt: updatedAt,
          ),
        ));
}

class $$HeroValuesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroValuesTable> {
  $$HeroValuesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get maxValue => $state.composableBuilder(
      column: $state.table.maxValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get doubleValue => $state.composableBuilder(
      column: $state.table.doubleValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get textValue => $state.composableBuilder(
      column: $state.table.textValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get jsonValue => $state.composableBuilder(
      column: $state.table.jsonValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroValuesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroValuesTable> {
  $$HeroValuesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get maxValue => $state.composableBuilder(
      column: $state.table.maxValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get doubleValue => $state.composableBuilder(
      column: $state.table.doubleValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get textValue => $state.composableBuilder(
      column: $state.table.textValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get jsonValue => $state.composableBuilder(
      column: $state.table.jsonValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$MetaEntriesTableCreateCompanionBuilder = MetaEntriesCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaEntriesTableUpdateCompanionBuilder = MetaEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MetaEntriesTable,
    MetaEntry,
    $$MetaEntriesTableFilterComposer,
    $$MetaEntriesTableOrderingComposer,
    $$MetaEntriesTableCreateCompanionBuilder,
    $$MetaEntriesTableUpdateCompanionBuilder> {
  $$MetaEntriesTableTableManager(_$AppDatabase db, $MetaEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MetaEntriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MetaEntriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaEntriesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaEntriesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
        ));
}

class $$MetaEntriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MetaEntriesTable> {
  $$MetaEntriesTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MetaEntriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MetaEntriesTable> {
  $$MetaEntriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$HeroDowntimeProjectsTableCreateCompanionBuilder
    = HeroDowntimeProjectsCompanion Function({
  required String id,
  required String heroId,
  Value<String?> templateProjectId,
  required String name,
  Value<String> description,
  required int projectGoal,
  Value<int> currentPoints,
  Value<String> prerequisitesJson,
  Value<String?> projectSource,
  Value<String?> sourceLanguage,
  Value<String> guidesJson,
  Value<String> rollCharacteristicsJson,
  Value<String> eventsJson,
  Value<String> notes,
  Value<bool> isCustom,
  Value<bool> isCompleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroDowntimeProjectsTableUpdateCompanionBuilder
    = HeroDowntimeProjectsCompanion Function({
  Value<String> id,
  Value<String> heroId,
  Value<String?> templateProjectId,
  Value<String> name,
  Value<String> description,
  Value<int> projectGoal,
  Value<int> currentPoints,
  Value<String> prerequisitesJson,
  Value<String?> projectSource,
  Value<String?> sourceLanguage,
  Value<String> guidesJson,
  Value<String> rollCharacteristicsJson,
  Value<String> eventsJson,
  Value<String> notes,
  Value<bool> isCustom,
  Value<bool> isCompleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroDowntimeProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroDowntimeProjectsTable,
    HeroDowntimeProject,
    $$HeroDowntimeProjectsTableFilterComposer,
    $$HeroDowntimeProjectsTableOrderingComposer,
    $$HeroDowntimeProjectsTableCreateCompanionBuilder,
    $$HeroDowntimeProjectsTableUpdateCompanionBuilder> {
  $$HeroDowntimeProjectsTableTableManager(
      _$AppDatabase db, $HeroDowntimeProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$HeroDowntimeProjectsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$HeroDowntimeProjectsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String?> templateProjectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> projectGoal = const Value.absent(),
            Value<int> currentPoints = const Value.absent(),
            Value<String> prerequisitesJson = const Value.absent(),
            Value<String?> projectSource = const Value.absent(),
            Value<String?> sourceLanguage = const Value.absent(),
            Value<String> guidesJson = const Value.absent(),
            Value<String> rollCharacteristicsJson = const Value.absent(),
            Value<String> eventsJson = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroDowntimeProjectsCompanion(
            id: id,
            heroId: heroId,
            templateProjectId: templateProjectId,
            name: name,
            description: description,
            projectGoal: projectGoal,
            currentPoints: currentPoints,
            prerequisitesJson: prerequisitesJson,
            projectSource: projectSource,
            sourceLanguage: sourceLanguage,
            guidesJson: guidesJson,
            rollCharacteristicsJson: rollCharacteristicsJson,
            eventsJson: eventsJson,
            notes: notes,
            isCustom: isCustom,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            Value<String?> templateProjectId = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            required int projectGoal,
            Value<int> currentPoints = const Value.absent(),
            Value<String> prerequisitesJson = const Value.absent(),
            Value<String?> projectSource = const Value.absent(),
            Value<String?> sourceLanguage = const Value.absent(),
            Value<String> guidesJson = const Value.absent(),
            Value<String> rollCharacteristicsJson = const Value.absent(),
            Value<String> eventsJson = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroDowntimeProjectsCompanion.insert(
            id: id,
            heroId: heroId,
            templateProjectId: templateProjectId,
            name: name,
            description: description,
            projectGoal: projectGoal,
            currentPoints: currentPoints,
            prerequisitesJson: prerequisitesJson,
            projectSource: projectSource,
            sourceLanguage: sourceLanguage,
            guidesJson: guidesJson,
            rollCharacteristicsJson: rollCharacteristicsJson,
            eventsJson: eventsJson,
            notes: notes,
            isCustom: isCustom,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroDowntimeProjectsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroDowntimeProjectsTable> {
  $$HeroDowntimeProjectsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get templateProjectId => $state.composableBuilder(
      column: $state.table.templateProjectId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get projectGoal => $state.composableBuilder(
      column: $state.table.projectGoal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentPoints => $state.composableBuilder(
      column: $state.table.currentPoints,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get prerequisitesJson => $state.composableBuilder(
      column: $state.table.prerequisitesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get projectSource => $state.composableBuilder(
      column: $state.table.projectSource,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get guidesJson => $state.composableBuilder(
      column: $state.table.guidesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get rollCharacteristicsJson => $state.composableBuilder(
      column: $state.table.rollCharacteristicsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get eventsJson => $state.composableBuilder(
      column: $state.table.eventsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCustom => $state.composableBuilder(
      column: $state.table.isCustom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCompleted => $state.composableBuilder(
      column: $state.table.isCompleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroDowntimeProjectsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroDowntimeProjectsTable> {
  $$HeroDowntimeProjectsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get templateProjectId => $state.composableBuilder(
      column: $state.table.templateProjectId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get projectGoal => $state.composableBuilder(
      column: $state.table.projectGoal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentPoints => $state.composableBuilder(
      column: $state.table.currentPoints,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get prerequisitesJson => $state.composableBuilder(
      column: $state.table.prerequisitesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get projectSource => $state.composableBuilder(
      column: $state.table.projectSource,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get guidesJson => $state.composableBuilder(
      column: $state.table.guidesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get rollCharacteristicsJson =>
      $state.composableBuilder(
          column: $state.table.rollCharacteristicsJson,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get eventsJson => $state.composableBuilder(
      column: $state.table.eventsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCustom => $state.composableBuilder(
      column: $state.table.isCustom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCompleted => $state.composableBuilder(
      column: $state.table.isCompleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroFollowersTableCreateCompanionBuilder = HeroFollowersCompanion
    Function({
  required String id,
  required String heroId,
  required String name,
  required String followerType,
  Value<int> might,
  Value<int> agility,
  Value<int> reason,
  Value<int> intuition,
  Value<int> presence,
  Value<String> skillsJson,
  Value<String> languagesJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$HeroFollowersTableUpdateCompanionBuilder = HeroFollowersCompanion
    Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> name,
  Value<String> followerType,
  Value<int> might,
  Value<int> agility,
  Value<int> reason,
  Value<int> intuition,
  Value<int> presence,
  Value<String> skillsJson,
  Value<String> languagesJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$HeroFollowersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroFollowersTable,
    HeroFollower,
    $$HeroFollowersTableFilterComposer,
    $$HeroFollowersTableOrderingComposer,
    $$HeroFollowersTableCreateCompanionBuilder,
    $$HeroFollowersTableUpdateCompanionBuilder> {
  $$HeroFollowersTableTableManager(_$AppDatabase db, $HeroFollowersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroFollowersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroFollowersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> followerType = const Value.absent(),
            Value<int> might = const Value.absent(),
            Value<int> agility = const Value.absent(),
            Value<int> reason = const Value.absent(),
            Value<int> intuition = const Value.absent(),
            Value<int> presence = const Value.absent(),
            Value<String> skillsJson = const Value.absent(),
            Value<String> languagesJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroFollowersCompanion(
            id: id,
            heroId: heroId,
            name: name,
            followerType: followerType,
            might: might,
            agility: agility,
            reason: reason,
            intuition: intuition,
            presence: presence,
            skillsJson: skillsJson,
            languagesJson: languagesJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String name,
            required String followerType,
            Value<int> might = const Value.absent(),
            Value<int> agility = const Value.absent(),
            Value<int> reason = const Value.absent(),
            Value<int> intuition = const Value.absent(),
            Value<int> presence = const Value.absent(),
            Value<String> skillsJson = const Value.absent(),
            Value<String> languagesJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroFollowersCompanion.insert(
            id: id,
            heroId: heroId,
            name: name,
            followerType: followerType,
            might: might,
            agility: agility,
            reason: reason,
            intuition: intuition,
            presence: presence,
            skillsJson: skillsJson,
            languagesJson: languagesJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroFollowersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroFollowersTable> {
  $$HeroFollowersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get followerType => $state.composableBuilder(
      column: $state.table.followerType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get might => $state.composableBuilder(
      column: $state.table.might,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get agility => $state.composableBuilder(
      column: $state.table.agility,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get reason => $state.composableBuilder(
      column: $state.table.reason,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get intuition => $state.composableBuilder(
      column: $state.table.intuition,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get presence => $state.composableBuilder(
      column: $state.table.presence,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get skillsJson => $state.composableBuilder(
      column: $state.table.skillsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get languagesJson => $state.composableBuilder(
      column: $state.table.languagesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroFollowersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroFollowersTable> {
  $$HeroFollowersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get followerType => $state.composableBuilder(
      column: $state.table.followerType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get might => $state.composableBuilder(
      column: $state.table.might,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get agility => $state.composableBuilder(
      column: $state.table.agility,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get reason => $state.composableBuilder(
      column: $state.table.reason,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get intuition => $state.composableBuilder(
      column: $state.table.intuition,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get presence => $state.composableBuilder(
      column: $state.table.presence,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get skillsJson => $state.composableBuilder(
      column: $state.table.skillsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get languagesJson => $state.composableBuilder(
      column: $state.table.languagesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroProjectSourcesTableCreateCompanionBuilder
    = HeroProjectSourcesCompanion Function({
  required String id,
  required String heroId,
  required String name,
  required String type,
  Value<String?> language,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$HeroProjectSourcesTableUpdateCompanionBuilder
    = HeroProjectSourcesCompanion Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> name,
  Value<String> type,
  Value<String?> language,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$HeroProjectSourcesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroProjectSourcesTable,
    HeroProjectSource,
    $$HeroProjectSourcesTableFilterComposer,
    $$HeroProjectSourcesTableOrderingComposer,
    $$HeroProjectSourcesTableCreateCompanionBuilder,
    $$HeroProjectSourcesTableUpdateCompanionBuilder> {
  $$HeroProjectSourcesTableTableManager(
      _$AppDatabase db, $HeroProjectSourcesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroProjectSourcesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$HeroProjectSourcesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroProjectSourcesCompanion(
            id: id,
            heroId: heroId,
            name: name,
            type: type,
            language: language,
            description: description,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String name,
            required String type,
            Value<String?> language = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroProjectSourcesCompanion.insert(
            id: id,
            heroId: heroId,
            name: name,
            type: type,
            language: language,
            description: description,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroProjectSourcesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroProjectSourcesTable> {
  $$HeroProjectSourcesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroProjectSourcesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroProjectSourcesTable> {
  $$HeroProjectSourcesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroNotesTableCreateCompanionBuilder = HeroNotesCompanion Function({
  required String id,
  required String heroId,
  required String title,
  Value<String> content,
  Value<String?> folderId,
  Value<bool> isFolder,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroNotesTableUpdateCompanionBuilder = HeroNotesCompanion Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> title,
  Value<String> content,
  Value<String?> folderId,
  Value<bool> isFolder,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroNotesTable,
    HeroNote,
    $$HeroNotesTableFilterComposer,
    $$HeroNotesTableOrderingComposer,
    $$HeroNotesTableCreateCompanionBuilder,
    $$HeroNotesTableUpdateCompanionBuilder> {
  $$HeroNotesTableTableManager(_$AppDatabase db, $HeroNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroNotesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroNotesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<bool> isFolder = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroNotesCompanion(
            id: id,
            heroId: heroId,
            title: title,
            content: content,
            folderId: folderId,
            isFolder: isFolder,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String title,
            Value<String> content = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<bool> isFolder = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroNotesCompanion.insert(
            id: id,
            heroId: heroId,
            title: title,
            content: content,
            folderId: folderId,
            isFolder: isFolder,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroNotesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroNotesTable> {
  $$HeroNotesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get folderId => $state.composableBuilder(
      column: $state.table.folderId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFolder => $state.composableBuilder(
      column: $state.table.isFolder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroNotesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroNotesTable> {
  $$HeroNotesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get folderId => $state.composableBuilder(
      column: $state.table.folderId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFolder => $state.composableBuilder(
      column: $state.table.isFolder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroEntriesTableCreateCompanionBuilder = HeroEntriesCompanion
    Function({
  Value<int> id,
  required String heroId,
  required String entryType,
  required String entryId,
  Value<String> sourceType,
  Value<String> sourceId,
  Value<String> gainedBy,
  Value<String?> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$HeroEntriesTableUpdateCompanionBuilder = HeroEntriesCompanion
    Function({
  Value<int> id,
  Value<String> heroId,
  Value<String> entryType,
  Value<String> entryId,
  Value<String> sourceType,
  Value<String> sourceId,
  Value<String> gainedBy,
  Value<String?> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$HeroEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroEntriesTable,
    HeroEntry,
    $$HeroEntriesTableFilterComposer,
    $$HeroEntriesTableOrderingComposer,
    $$HeroEntriesTableCreateCompanionBuilder,
    $$HeroEntriesTableUpdateCompanionBuilder> {
  $$HeroEntriesTableTableManager(_$AppDatabase db, $HeroEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroEntriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroEntriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> entryType = const Value.absent(),
            Value<String> entryId = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> gainedBy = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroEntriesCompanion(
            id: id,
            heroId: heroId,
            entryType: entryType,
            entryId: entryId,
            sourceType: sourceType,
            sourceId: sourceId,
            gainedBy: gainedBy,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String heroId,
            required String entryType,
            required String entryId,
            Value<String> sourceType = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> gainedBy = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroEntriesCompanion.insert(
            id: id,
            heroId: heroId,
            entryType: entryType,
            entryId: entryId,
            sourceType: sourceType,
            sourceId: sourceId,
            gainedBy: gainedBy,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$HeroEntriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroEntriesTable> {
  $$HeroEntriesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryType => $state.composableBuilder(
      column: $state.table.entryType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryId => $state.composableBuilder(
      column: $state.table.entryId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceType => $state.composableBuilder(
      column: $state.table.sourceType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceId => $state.composableBuilder(
      column: $state.table.sourceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gainedBy => $state.composableBuilder(
      column: $state.table.gainedBy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroEntriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroEntriesTable> {
  $$HeroEntriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryType => $state.composableBuilder(
      column: $state.table.entryType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryId => $state.composableBuilder(
      column: $state.table.entryId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceType => $state.composableBuilder(
      column: $state.table.sourceType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceId => $state.composableBuilder(
      column: $state.table.sourceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gainedBy => $state.composableBuilder(
      column: $state.table.gainedBy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroConfigTableCreateCompanionBuilder = HeroConfigCompanion Function({
  Value<int> id,
  required String heroId,
  required String configKey,
  required String valueJson,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$HeroConfigTableUpdateCompanionBuilder = HeroConfigCompanion Function({
  Value<int> id,
  Value<String> heroId,
  Value<String> configKey,
  Value<String> valueJson,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$HeroConfigTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroConfigTable,
    HeroConfigData,
    $$HeroConfigTableFilterComposer,
    $$HeroConfigTableOrderingComposer,
    $$HeroConfigTableCreateCompanionBuilder,
    $$HeroConfigTableUpdateCompanionBuilder> {
  $$HeroConfigTableTableManager(_$AppDatabase db, $HeroConfigTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroConfigTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroConfigTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> configKey = const Value.absent(),
            Value<String> valueJson = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroConfigCompanion(
            id: id,
            heroId: heroId,
            configKey: configKey,
            valueJson: valueJson,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String heroId,
            required String configKey,
            required String valueJson,
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              HeroConfigCompanion.insert(
            id: id,
            heroId: heroId,
            configKey: configKey,
            valueJson: valueJson,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$HeroConfigTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroConfigTable> {
  $$HeroConfigTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get configKey => $state.composableBuilder(
      column: $state.table.configKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get valueJson => $state.composableBuilder(
      column: $state.table.valueJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get metadata => $state.composableBuilder(
      column: $state.table.metadata,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroConfigTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroConfigTable> {
  $$HeroConfigTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get configKey => $state.composableBuilder(
      column: $state.table.configKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get valueJson => $state.composableBuilder(
      column: $state.table.valueJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get metadata => $state.composableBuilder(
      column: $state.table.metadata,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroRetainersTableCreateCompanionBuilder = HeroRetainersCompanion
    Function({
  required String id,
  required String heroId,
  required String retainerComponentId,
  required String name,
  required String role,
  Value<bool> isCustom,
  Value<String?> customDataJson,
  Value<String> advancementChoicesJson,
  Value<String> characteristicChoicesJson,
  Value<int> level,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<int?> currentRecoveries,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroRetainersTableUpdateCompanionBuilder = HeroRetainersCompanion
    Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> retainerComponentId,
  Value<String> name,
  Value<String> role,
  Value<bool> isCustom,
  Value<String?> customDataJson,
  Value<String> advancementChoicesJson,
  Value<String> characteristicChoicesJson,
  Value<int> level,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<int?> currentRecoveries,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroRetainersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroRetainersTable,
    HeroRetainer,
    $$HeroRetainersTableFilterComposer,
    $$HeroRetainersTableOrderingComposer,
    $$HeroRetainersTableCreateCompanionBuilder,
    $$HeroRetainersTableUpdateCompanionBuilder> {
  $$HeroRetainersTableTableManager(_$AppDatabase db, $HeroRetainersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroRetainersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroRetainersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> retainerComponentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<String?> customDataJson = const Value.absent(),
            Value<String> advancementChoicesJson = const Value.absent(),
            Value<String> characteristicChoicesJson = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<int?> currentRecoveries = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroRetainersCompanion(
            id: id,
            heroId: heroId,
            retainerComponentId: retainerComponentId,
            name: name,
            role: role,
            isCustom: isCustom,
            customDataJson: customDataJson,
            advancementChoicesJson: advancementChoicesJson,
            characteristicChoicesJson: characteristicChoicesJson,
            level: level,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            currentRecoveries: currentRecoveries,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String retainerComponentId,
            required String name,
            required String role,
            Value<bool> isCustom = const Value.absent(),
            Value<String?> customDataJson = const Value.absent(),
            Value<String> advancementChoicesJson = const Value.absent(),
            Value<String> characteristicChoicesJson = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<int?> currentRecoveries = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroRetainersCompanion.insert(
            id: id,
            heroId: heroId,
            retainerComponentId: retainerComponentId,
            name: name,
            role: role,
            isCustom: isCustom,
            customDataJson: customDataJson,
            advancementChoicesJson: advancementChoicesJson,
            characteristicChoicesJson: characteristicChoicesJson,
            level: level,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            currentRecoveries: currentRecoveries,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroRetainersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroRetainersTable> {
  $$HeroRetainersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get retainerComponentId => $state.composableBuilder(
      column: $state.table.retainerComponentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCustom => $state.composableBuilder(
      column: $state.table.isCustom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customDataJson => $state.composableBuilder(
      column: $state.table.customDataJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get advancementChoicesJson => $state.composableBuilder(
      column: $state.table.advancementChoicesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get characteristicChoicesJson =>
      $state.composableBuilder(
          column: $state.table.characteristicChoicesJson,
          builder: (column, joinBuilders) =>
              ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentRecoveries => $state.composableBuilder(
      column: $state.table.currentRecoveries,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroRetainersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroRetainersTable> {
  $$HeroRetainersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get retainerComponentId => $state.composableBuilder(
      column: $state.table.retainerComponentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCustom => $state.composableBuilder(
      column: $state.table.isCustom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customDataJson => $state.composableBuilder(
      column: $state.table.customDataJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get advancementChoicesJson =>
      $state.composableBuilder(
          column: $state.table.advancementChoicesJson,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get characteristicChoicesJson => $state
      .composableBuilder(
          column: $state.table.characteristicChoicesJson,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentRecoveries => $state.composableBuilder(
      column: $state.table.currentRecoveries,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroCompanionsTableCreateCompanionBuilder = HeroCompanionsCompanion
    Function({
  required String id,
  required String heroId,
  required String companionComponentId,
  required String name,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<int> currentRampage,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroCompanionsTableUpdateCompanionBuilder = HeroCompanionsCompanion
    Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> companionComponentId,
  Value<String> name,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<int> currentRampage,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroCompanionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroCompanionsTable,
    HeroCompanion,
    $$HeroCompanionsTableFilterComposer,
    $$HeroCompanionsTableOrderingComposer,
    $$HeroCompanionsTableCreateCompanionBuilder,
    $$HeroCompanionsTableUpdateCompanionBuilder> {
  $$HeroCompanionsTableTableManager(
      _$AppDatabase db, $HeroCompanionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroCompanionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroCompanionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> companionComponentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<int> currentRampage = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroCompanionsCompanion(
            id: id,
            heroId: heroId,
            companionComponentId: companionComponentId,
            name: name,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            currentRampage: currentRampage,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String companionComponentId,
            required String name,
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<int> currentRampage = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroCompanionsCompanion.insert(
            id: id,
            heroId: heroId,
            companionComponentId: companionComponentId,
            name: name,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            currentRampage: currentRampage,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroCompanionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroCompanionsTable> {
  $$HeroCompanionsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get companionComponentId => $state.composableBuilder(
      column: $state.table.companionComponentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentRampage => $state.composableBuilder(
      column: $state.table.currentRampage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroCompanionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroCompanionsTable> {
  $$HeroCompanionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get companionComponentId => $state.composableBuilder(
      column: $state.table.companionComponentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentRampage => $state.composableBuilder(
      column: $state.table.currentRampage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$HeroMinionSquadsTableCreateCompanionBuilder
    = HeroMinionSquadsCompanion Function({
  required String id,
  required String heroId,
  required String minionComponentId,
  required String squadName,
  Value<int> memberCount,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HeroMinionSquadsTableUpdateCompanionBuilder
    = HeroMinionSquadsCompanion Function({
  Value<String> id,
  Value<String> heroId,
  Value<String> minionComponentId,
  Value<String> squadName,
  Value<int> memberCount,
  Value<int?> currentStamina,
  Value<int> tempStamina,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HeroMinionSquadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeroMinionSquadsTable,
    HeroMinionSquad,
    $$HeroMinionSquadsTableFilterComposer,
    $$HeroMinionSquadsTableOrderingComposer,
    $$HeroMinionSquadsTableCreateCompanionBuilder,
    $$HeroMinionSquadsTableUpdateCompanionBuilder> {
  $$HeroMinionSquadsTableTableManager(
      _$AppDatabase db, $HeroMinionSquadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HeroMinionSquadsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HeroMinionSquadsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> heroId = const Value.absent(),
            Value<String> minionComponentId = const Value.absent(),
            Value<String> squadName = const Value.absent(),
            Value<int> memberCount = const Value.absent(),
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroMinionSquadsCompanion(
            id: id,
            heroId: heroId,
            minionComponentId: minionComponentId,
            squadName: squadName,
            memberCount: memberCount,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String heroId,
            required String minionComponentId,
            required String squadName,
            Value<int> memberCount = const Value.absent(),
            Value<int?> currentStamina = const Value.absent(),
            Value<int> tempStamina = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeroMinionSquadsCompanion.insert(
            id: id,
            heroId: heroId,
            minionComponentId: minionComponentId,
            squadName: squadName,
            memberCount: memberCount,
            currentStamina: currentStamina,
            tempStamina: tempStamina,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$HeroMinionSquadsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HeroMinionSquadsTable> {
  $$HeroMinionSquadsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get minionComponentId => $state.composableBuilder(
      column: $state.table.minionComponentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get squadName => $state.composableBuilder(
      column: $state.table.squadName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get memberCount => $state.composableBuilder(
      column: $state.table.memberCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HeroesTableFilterComposer get heroId {
    final $$HeroesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HeroesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$HeroMinionSquadsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HeroMinionSquadsTable> {
  $$HeroMinionSquadsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get minionComponentId => $state.composableBuilder(
      column: $state.table.minionComponentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get squadName => $state.composableBuilder(
      column: $state.table.squadName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get memberCount => $state.composableBuilder(
      column: $state.table.memberCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentStamina => $state.composableBuilder(
      column: $state.table.currentStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tempStamina => $state.composableBuilder(
      column: $state.table.tempStamina,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HeroesTableOrderingComposer get heroId {
    final $$HeroesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.heroId,
        referencedTable: $state.db.heroes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HeroesTableOrderingComposer(ComposerState(
                $state.db, $state.db.heroes, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db, _db.components);
  $$HeroesTableTableManager get heroes =>
      $$HeroesTableTableManager(_db, _db.heroes);
  $$HeroValuesTableTableManager get heroValues =>
      $$HeroValuesTableTableManager(_db, _db.heroValues);
  $$MetaEntriesTableTableManager get metaEntries =>
      $$MetaEntriesTableTableManager(_db, _db.metaEntries);
  $$HeroDowntimeProjectsTableTableManager get heroDowntimeProjects =>
      $$HeroDowntimeProjectsTableTableManager(_db, _db.heroDowntimeProjects);
  $$HeroFollowersTableTableManager get heroFollowers =>
      $$HeroFollowersTableTableManager(_db, _db.heroFollowers);
  $$HeroProjectSourcesTableTableManager get heroProjectSources =>
      $$HeroProjectSourcesTableTableManager(_db, _db.heroProjectSources);
  $$HeroNotesTableTableManager get heroNotes =>
      $$HeroNotesTableTableManager(_db, _db.heroNotes);
  $$HeroEntriesTableTableManager get heroEntries =>
      $$HeroEntriesTableTableManager(_db, _db.heroEntries);
  $$HeroConfigTableTableManager get heroConfig =>
      $$HeroConfigTableTableManager(_db, _db.heroConfig);
  $$HeroRetainersTableTableManager get heroRetainers =>
      $$HeroRetainersTableTableManager(_db, _db.heroRetainers);
  $$HeroCompanionsTableTableManager get heroCompanions =>
      $$HeroCompanionsTableTableManager(_db, _db.heroCompanions);
  $$HeroMinionSquadsTableTableManager get heroMinionSquads =>
      $$HeroMinionSquadsTableTableManager(_db, _db.heroMinionSquads);
}
