import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'app_database.dart' as db;
import '../seed/asset_seeder.dart';

/// Utility methods for database maintenance
class DatabaseMaintenance {
  /// Clear all ability components from the database
  /// Useful when switching between data formats to avoid duplicates
  static Future<void> clearAbilities(db.AppDatabase database) async {
    await (database.delete(database.components)
          ..where((c) => c.type.equals('ability')))
        .go();
  }

  /// Clear all components and reseed from assets
  /// WARNING: This will delete all seed data
  static Future<void> clearAndReseed(db.AppDatabase database) async {
    await (database.delete(database.components)
          ..where((c) => c.source.equals('seed')))
        .go();
    await AssetSeeder.seedFromManifestIfEmpty(database);
  }

  /// Reseed a specific component type from a JSON file
  /// This will clear existing components of that type and reload from the asset
  static Future<void> reseedComponentType(
    db.AppDatabase database, {
    required String type,
    required String assetPath,
  }) async {
    // Clear existing components of this type that were seeded
    await (database.delete(database.components)
          ..where((c) => c.type.equals(type) & c.source.equals('seed')))
        .go();

    // Load and parse the asset
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final batchOps = <db.ComponentsCompanion>[];
    final now = DateTime.now();

    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = map.remove('id')?.toString() ?? '';
      final itemType = map.remove('type')?.toString() ?? type;
      final name = map.remove('name')?.toString() ?? '';
      if (id.isEmpty || name.isEmpty) continue;

      batchOps.add(db.ComponentsCompanion.insert(
        id: id,
        type: itemType,
        name: name,
        dataJson: Value(jsonEncode(map)),
        source: const Value('seed'),
        parentId: const Value(null),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    }

    if (batchOps.isEmpty) return;
    await database.batch((b) {
      for (final op in batchOps) {
        b.insert(database.components, op, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Reseed perks from the perks.json asset
  static Future<void> reseedPerks(db.AppDatabase database) async {
    await reseedComponentType(
      database,
      type: 'perk',
      assetPath: 'data/story/perks.json',
    );
  }

  /// Clear only duplicate abilities (keeps one copy of each name)
  static Future<void> removeDuplicateAbilities(db.AppDatabase database) async {
    // Get all abilities
    final allAbilities = await (database.select(database.components)
          ..where((c) => c.type.equals('ability')))
        .get();

    // Group by name
    final byName = <String, List<db.Component>>{};
    for (final ability in allAbilities) {
      byName.putIfAbsent(ability.name, () => []).add(ability);
    }

    // For each name with duplicates, keep the simplified version
    for (final entry in byName.entries) {
      if (entry.value.length <= 1) continue;

      // Find simplified version (has 'resource' field as string in dataJson)
      db.Component? simplified;
      final toDelete = <db.Component>[];

      for (final ability in entry.value) {
        final dataJson = ability.dataJson;
        final data = jsonDecode(dataJson);
        final hasSimplifiedResource = data['resource'] is String;
        
        if (hasSimplifiedResource && simplified == null) {
          simplified = ability; // Keep this one
        } else {
          toDelete.add(ability); // Mark for deletion
        }
      }

      // If no simplified version found, keep the first one
      if (simplified == null && toDelete.isNotEmpty) {
        simplified = toDelete.removeAt(0);
      }

      // Delete duplicates
      for (final ability in toDelete) {
        await (database.delete(database.components)
              ..where((c) => c.id.equals(ability.id)))
            .go();
      }
    }
  }
}
