import 'dart:convert';

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/component.dart' as model;
import '../repositories/component_drift_repository.dart';

/// Service for managing the global items catalog.
///
/// Items come from two sources:
/// 1. **Seeded items** – loaded from `data/items/items.json` at startup (source='seed').
/// 2. **User-created items** – added via the Items page or inventory (source='user').
///
/// All items are stored in the `Components` table with `type = 'item'`.
class ItemsCatalogService {
  ItemsCatalogService(this._db, this._repo);

  final AppDatabase _db;
  final ComponentDriftRepository _repo;

  static const String itemType = 'item';

  /// Watch all items (seeded + user-created), sorted alphabetically.
  Stream<List<model.Component>> watchAllItems() {
    return _repo.watchByType(itemType);
  }

  /// Get all items once.
  Future<List<model.Component>> getAllItems() async {
    final rows = await _db.getComponentsByType(itemType);
    return rows
        .map(_mapRow)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Search items by name.
  Future<List<model.Component>> searchItems(String query) async {
    return _repo.search(query, type: itemType);
  }

  /// Create a new user item and add it to the catalog.
  /// Returns the created component.
  Future<model.Component> createItem({
    required String name,
    String description = '',
    String category = 'custom',
  }) async {
    final id = 'item_${_slugify(name)}';

    // Check if item with this ID already exists
    final existing = await _db.getComponentById(id);
    if (existing != null) {
      // Return existing item rather than duplicating
      return _mapRow(existing);
    }

    final data = {
      'description': description,
      'category': category,
    };

    await _db.upsertComponentModel(
      id: id,
      type: itemType,
      name: name,
      dataMap: data,
      source: 'user',
    );

    return model.Component(
      id: id,
      type: itemType,
      name: name,
      data: data,
      source: 'user',
    );
  }

  /// Ensure an item exists in the catalog. If it already exists, returns it.
  /// Used when adding items from hero inventory to ensure catalog has a copy.
  Future<model.Component> ensureItemInCatalog({
    required String name,
    String description = '',
  }) async {
    // Try to find by slug ID first
    final id = 'item_${_slugify(name)}';
    final existing = await _db.getComponentById(id);
    if (existing != null) return _mapRow(existing);

    // Try case-insensitive name match
    final all = await getAllItems();
    final match = all
        .where((c) => c.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (match != null) return match;

    // Create new user item
    return createItem(name: name, description: description);
  }

  /// Delete a user-created item. Seeded items cannot be deleted.
  Future<bool> deleteItem(String id) async {
    final component = await _db.getComponentById(id);
    if (component == null) return false;
    if (component.source != 'user') return false;
    return _repo.delete(id);
  }

  /// Update a user-created item.
  Future<void> updateItem({
    required String id,
    required String name,
    String description = '',
    String category = 'custom',
  }) async {
    await _db.upsertComponentModel(
      id: id,
      type: itemType,
      name: name,
      dataMap: {
        'description': description,
        'category': category,
      },
      source: 'user',
    );
  }

  /// Get item category label for display.
  static String categoryLabel(String? category) {
    switch (category) {
      case 'project_material':
        return 'Project Material';
      case 'treasure_component':
        return 'Treasure Component';
      case 'equipment':
        return 'Equipment';
      case 'consumable':
        return 'Consumable';
      case 'custom':
        return 'Custom';
      default:
        return 'Item';
    }
  }

  /// Get category color for display. Shared across items page & inventory.
  static Color categoryColor(String? category) {
    switch (category) {
      case 'project_material':
        return const Color(0xFF7B1FA2); // Purple
      case 'treasure_component':
        return const Color(0xFFFF8F00); // Amber
      case 'equipment':
        return const Color(0xFF546E7A); // Blue Grey
      case 'consumable':
        return const Color(0xFF2E7D32); // Green
      case 'custom':
        return const Color(0xFF5D4037); // Brown (same as items theme)
      default:
        return const Color(0xFF5D4037); // Brown
    }
  }

  /// Get category icon for display. Shared across items page & inventory.
  static IconData categoryIcon(String? category) {
    switch (category) {
      case 'project_material':
        return Icons.construction;
      case 'treasure_component':
        return Icons.diamond_outlined;
      case 'equipment':
        return Icons.handyman;
      case 'consumable':
        return Icons.local_dining;
      case 'custom':
        return Icons.inventory_2_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String _slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static model.Component _mapRow(Component row) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(row.dataJson) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    return model.Component(
      id: row.id,
      type: row.type,
      name: row.name,
      data: data,
      source: row.source,
      parentId: row.parentId,
    );
  }
}
