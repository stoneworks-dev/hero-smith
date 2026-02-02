import 'dart:convert';

// No direct Value usage here; keep imports minimal.

import '../db/app_database.dart' as db;
import '../models/component.dart' as model;

class ComponentDriftRepository {
  ComponentDriftRepository(this._db);

  final db.AppDatabase _db;

  // Seeding is handled by AssetSeeder at app startup.
  Future<void> seedIfNeeded(List<String> assetPaths) async {}

  Stream<List<model.Component>> watchAll() => _db
    .watchAllComponents()
    .map((rows) => rows.map(_mapRow).toList());

  Stream<List<model.Component>> watchByType(String type) => _db
    .watchComponentsByType(type)
    .map((rows) => rows.map(_mapRow).toList());

  Future<List<model.Component>> search(String query, {String? type}) async {
    final q = query.trim().toLowerCase();
    final List<db.Component> rows = await _db.getAllComponents();
    final filtered = rows.where((r) {
      final id = r.id.toLowerCase();
      final name = r.name.toLowerCase();
      final typeOk = type == null || r.type == type;
      return typeOk && (id.contains(q) || name.contains(q));
    }).toList();
    return filtered.map(_mapRow).toList();
  }

  Future<void> upsert(model.Component c) => _db.upsertComponentModel(
        id: c.id,
        type: c.type,
        name: c.name,
        dataMap: c.data,
    source: c.source,
    parentId: c.parentId,
      );

  Future<bool> delete(String id) => _db.deleteComponent(id);

  Future<model.Component> createCustom({
    required String type,
    required String name,
    Map<String, dynamic> data = const {},
    String? parentId,
  }) async {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await _db.upsertComponentModel(
      id: id,
      type: type,
      name: name,
      dataMap: data,
      source: 'user',
      parentId: parentId,
    );
    return model.Component(
      id: id,
      type: type,
      name: name,
      data: data,
      source: 'user',
      parentId: parentId,
    );
  }

  model.Component _mapRow(db.Component d) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(d.dataJson) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    return model.Component(
      id: d.id,
      type: d.type,
      name: d.name,
      data: data,
      source: d.source,
      parentId: d.parentId,
    );
  }
}
