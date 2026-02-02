import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../db/app_database.dart';

/// Handles discovering JSON assets under data/ and seeding the database.
class AssetSeeder {
  static const int _chunkSize = 500;

  /// Discover all JSON assets under data/ via AssetManifest
  static Future<List<String>> discoverDataJsonAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> assets = jsonDecode(manifest);
    return assets.keys
        .where((k) => k.startsWith('data/') && k.endsWith('.json'))
        .toList();
  }

  /// Seed once from assets if the database is empty. No incremental seeding.
  static Future<void> seedFromManifestIfEmpty(AppDatabase db) async {
    try {
      final assets = await discoverDataJsonAssets();
      if (AppDatabase.databasePreexisted) {
        // Seed classes if missing
        await _seedTypeIfMissing(
          db: db,
          assets: assets,
          type: 'class',
          pathPredicate: (path) =>
              path.startsWith('data/classes_levels_and_stats/'),
        );
        // Seed perk/title/complication abilities if missing (by specific IDs)
        await _seedSupplementalAbilitiesIfMissing(db, assets);
        return;
      }

      await _seedAssetsInChunks(db: db, assetPaths: assets);
      // print('DEBUG: Seeding completed');
    } catch (e) {
      // print('DEBUG: Error in seedFromManifestIfEmpty: $e');
      rethrow;
    }
  }
  
  /// Supplemental ability files that may be missing in pre-existing databases
  static const _supplementalAbilityFiles = [
    'data/abilities/perk_abilities.json',
    'data/abilities/titles_abilities.json',
    'data/abilities/complication_abilities.json',
    'data/abilities/ancestry_abilities.json',
    'data/abilities/kit_abilities.json',
  ];
  
  /// Seed supplemental abilities (perk/title/etc) if not already present
  static Future<void> _seedSupplementalAbilitiesIfMissing(
    AppDatabase db, 
    List<String> assets,
  ) async {
    for (final filePath in _supplementalAbilityFiles) {
      if (!assets.contains(filePath)) continue;
      
      try {
        final raw = await rootBundle.loadString(filePath);
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        
        final items = decoded.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        if (items.isEmpty) continue;
        
        // Check if any of these abilities are missing
        final idsToCheck = items
            .map((m) => _peekComponentId(m))
            .whereType<String>()
            .toList();
        
        if (idsToCheck.isEmpty) continue;
        
        final existing = await (db.select(db.components)
              ..where((c) => c.id.isIn(idsToCheck)))
            .get();
        
        final existingIds = existing.map((c) => c.id).toSet();
        final missingIds = idsToCheck.where((id) => !existingIds.contains(id)).toSet();
        
        if (missingIds.isEmpty) continue;
        
        // Seed only missing abilities from this file
        await _seedAssetsInChunks(db: db, assetPaths: [filePath]);
      } catch (_) {
        // Ignore errors for individual files
      }
    }
  }
  
  /// Peek at component ID without removing it from the map
  static String? _peekComponentId(Map<String, dynamic> source) {
    const candidateKeys = ['id', 'componentId', 'classId', 'abilityId', 'featureId'];
    for (final key in candidateKeys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static Future<void> _seedAssetsInChunks({
    required AppDatabase db,
    required Iterable<String> assetPaths,
  }) async {
    final buffer = <ComponentsCompanion>[];
    final seenIds = <String>{};

    Future<void> flush() async {
      if (buffer.isEmpty) return;
      final ops = List<ComponentsCompanion>.from(buffer);
      buffer.clear();
      await db.batch((b) {
        for (final op in ops) {
          b.insert(db.components, op, mode: InsertMode.insertOrReplace);
        }
      });
      // Yield to the UI/event loop so first-run seeding doesn't freeze the app.
      await Future<void>.delayed(Duration.zero);
    }

    for (final path in assetPaths) {
      // Skip legacy class_abilities folder - only load simplified format
      if (path.contains('data/abilities/class_abilities/') &&
          !path.contains('class_abilities_simplified') &&
          !path.contains('class_abilities_dynamic')) {
        continue;
      }

      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      Iterable<Map<String, dynamic>> items;
      if (decoded is List) {
        items = decoded.cast<Map>().map((e) => Map<String, dynamic>.from(e));
      } else if (decoded is Map<String, dynamic>) {
        items = [Map<String, dynamic>.from(decoded)];
      } else {
        continue;
      }

      final now = DateTime.now();
      for (final map in items) {
        final work = Map<String, dynamic>.from(map);
        final id = _popComponentId(work);
        if (id == null || id.isEmpty) continue;
        if (!seenIds.add(id)) continue;

        String type;
        if (path.contains('/abilities/') || path.startsWith('data/abilities/')) {
          // Preserve action label if the source used a generic 'type' field
          final maybeAction = work.remove('type');
          if (maybeAction != null && work['action_type'] == null) {
            work['action_type'] = maybeAction;
          }
          type = 'ability';
        } else {
          type = work.remove('type') as String? ?? 'unknown';
        }

        final name = work.remove('name') as String? ?? '';
        final dataJson = jsonEncode(work);
        buffer.add(
          ComponentsCompanion.insert(
            id: id,
            type: type,
            name: name,
            dataJson: Value(dataJson),
            source: const Value('seed'),
            parentId: const Value(null),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        if (buffer.length >= _chunkSize) {
          await flush();
        }
      }
    }

    await flush();
  }

  static String? _popComponentId(Map<String, dynamic> source) {
    const candidateKeys = [
      'id',
      'componentId',
      'classId',
      'abilityId',
      'featureId',
    ];
    for (final key in candidateKeys) {
      final value = source.remove(key);
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static Future<void> _seedTypeIfMissing({
    required AppDatabase db,
    required List<String> assets,
    required String type,
    required bool Function(String path) pathPredicate,
  }) async {
    final existing = await (db.select(db.components)
          ..where((c) => c.type.equals(type)))
        .get();
    if (existing.isNotEmpty) return;
    final filtered = assets.where(pathPredicate).toList();
    if (filtered.isEmpty) return;
    await _seedAssetsInChunks(db: db, assetPaths: filtered);
  }
}
