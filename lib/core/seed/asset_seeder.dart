import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../db/app_database.dart';

typedef SeedAssetLoader = Future<String> Function(String path);

/// Handles versioned, non-destructive synchronization of bundled JSON content.
///
/// Content versions are deliberately independent from Drift's schema version:
/// a release can update game content without changing the database structure.
class AssetSeeder {
  static const int _chunkSize = 500;
  static const String contentManifestPath = 'data/content_manifest.json';
  static const String contentVersionMetaKey = 'seed.content_version';

  /// Discover all JSON assets under data/ via AssetManifest.
  static Future<List<String>> discoverDataJsonAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> assets = jsonDecode(manifest);
    return assets.keys
        .where(
          (path) =>
              path.startsWith('data/') &&
              path.endsWith('.json') &&
              path != contentManifestPath,
        )
        .toList()
      ..sort();
  }

  /// Synchronizes bundled content when its version is newer than the version
  /// recorded in this database.
  ///
  /// Existing heroes are preserved because rows are updated in place by their
  /// stable component ID. Seed rows absent from a newer bundle are retained;
  /// content authors should mark removed choices with `isRetired: true`.
  static Future<bool> seedBundledContentIfNeeded(AppDatabase db) async {
    final rawManifest = await rootBundle.loadString(contentManifestPath);
    final decoded = jsonDecode(rawManifest);
    if (decoded is! Map) {
      throw const FormatException('Content manifest must be a JSON object.');
    }
    final rawVersion = decoded['version'];
    final contentVersion = rawVersion is int
        ? rawVersion
        : int.tryParse(rawVersion?.toString() ?? '');
    if (contentVersion == null || contentVersion < 1) {
      throw const FormatException(
        'Content manifest "version" must be a positive integer.',
      );
    }

    return seedIfNewer(
      db: db,
      contentVersion: contentVersion,
      assetPaths: await discoverDataJsonAssets(),
      loadAsset: rootBundle.loadString,
    );
  }

  /// Backwards-compatible entry point retained for existing callers.
  static Future<void> seedFromManifestIfEmpty(AppDatabase db) async {
    await seedBundledContentIfNeeded(db);
  }

  /// Testable implementation of the versioned seed synchronization.
  ///
  /// Returns true when a synchronization was applied.
  static Future<bool> seedIfNewer({
    required AppDatabase db,
    required int contentVersion,
    required Iterable<String> assetPaths,
    required SeedAssetLoader loadAsset,
  }) async {
    if (contentVersion < 1) {
      throw ArgumentError.value(
        contentVersion,
        'contentVersion',
        'Must be a positive integer.',
      );
    }

    final storedVersion =
        int.tryParse(await db.getMeta(contentVersionMetaKey) ?? '') ?? 0;
    if (storedVersion >= contentVersion) return false;

    // Parse the complete bundle before opening the transaction. A malformed
    // asset therefore cannot leave the database half-updated.
    final records = await _readSeedRecords(
      assetPaths: assetPaths,
      loadAsset: loadAsset,
    );

    await db.transaction(() async {
      final existing = await db.select(db.components).get();
      final protectedIds = existing
          .where((row) => row.source != 'seed')
          .map((row) => row.id)
          .toSet();

      for (var offset = 0; offset < records.length; offset += _chunkSize) {
        final end = (offset + _chunkSize).clamp(0, records.length);
        final chunk = records.sublist(offset, end);
        await db.batch((batch) {
          for (final record in chunk) {
            // Never let bundled data replace a user-created or imported row
            // that happens to use the same ID.
            if (protectedIds.contains(record.id)) continue;

            final insert = record.toInsertCompanion();
            batch.insert(
              db.components,
              insert,
              onConflict: DoUpdate(
                (_) => record.toUpdateCompanion(),
                target: [db.components.id],
              ),
            );
          }
        });
      }

      // Advancing the version is part of the same transaction as all upserts.
      await db.setMeta(contentVersionMetaKey, contentVersion.toString());
    });

    return true;
  }

  static Future<List<_SeedRecord>> _readSeedRecords({
    required Iterable<String> assetPaths,
    required SeedAssetLoader loadAsset,
  }) async {
    final records = <_SeedRecord>[];
    final seenIds = <String>{};
    final sortedPaths = assetPaths.toList()..sort();

    for (final path in sortedPaths) {
      // Skip the legacy class-ability shape. The simplified/dynamic formats
      // are the canonical sources used by the app.
      if (path.contains('data/abilities/class_abilities/') &&
          !path.contains('class_abilities_simplified') &&
          !path.contains('class_abilities_dynamic')) {
        continue;
      }

      final decoded = jsonDecode(await loadAsset(path));
      final Iterable<Map<String, dynamic>> items;
      if (decoded is List) {
        items = decoded
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry));
      } else if (decoded is Map) {
        items = [Map<String, dynamic>.from(decoded)];
      } else {
        continue;
      }

      for (final source in items) {
        final work = Map<String, dynamic>.from(source);
        final originalId = _popComponentId(work);
        if (originalId == null || originalId.isEmpty) continue;

        late final String type;
        var resolvedId = originalId;
        if (path.contains('/abilities/') ||
            path.startsWith('data/abilities/')) {
          final maybeAction = work.remove('type');
          if (maybeAction != null && work['action_type'] == null) {
            work['action_type'] = maybeAction;
          }
          type = 'ability';
          work['original_id'] ??= originalId;
          work['ability_source_path'] ??= path;
          final classSlug = _classSlugFromAbilityPath(path);
          if (classSlug != null) {
            work['class_slug'] ??= classSlug;
            resolvedId = _resolvedClassAbilityId(
              path: path,
              originalId: originalId,
              classSlug: classSlug,
              data: work,
            );
            work['resolved_id'] ??= resolvedId;
          }
        } else {
          type = work.remove('type')?.toString() ?? 'unknown';
        }
        if (!seenIds.add(resolvedId)) continue;

        records.add(
          _SeedRecord(
            id: resolvedId,
            type: type,
            name: work.remove('name')?.toString() ?? '',
            dataJson: jsonEncode(work),
          ),
        );
      }
    }

    return records;
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
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _classSlugFromAbilityPath(String path) {
    const prefixes = [
      'data/abilities/class_abilities_new/',
      'data/abilities/class_abilities_simplified/',
      'data/abilities/class_abilities_dynamic/',
    ];
    final normalized = path.replaceAll('\\', '/');
    String? relative;
    for (final prefix in prefixes) {
      if (normalized.startsWith(prefix)) {
        relative = normalized.substring(prefix.length);
        break;
      }
    }
    if (relative == null || relative.isEmpty) return null;

    final firstSegment = relative.split('/').first.trim();
    if (firstSegment.isEmpty) return null;
    final filename = firstSegment.endsWith('.json')
        ? firstSegment.substring(0, firstSegment.length - 5)
        : firstSegment;
    final className = filename.endsWith('_abilities')
        ? filename.substring(0, filename.length - '_abilities'.length)
        : filename;
    final slug = className
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? null : slug;
  }

  static String _resolvedClassAbilityId({
    required String path,
    required String originalId,
    required String classSlug,
    required Map<String, dynamic> data,
  }) {
    final normalizedPath = path.replaceAll('\\', '/');
    final marker = normalizedPath.indexOf('class_abilities_');
    String? levelSegment;
    if (marker >= 0) {
      final afterFamily = normalizedPath.substring(marker).split('/');
      if (afterFamily.length >= 3) {
        levelSegment = _slugify(afterFamily[2].replaceAll('.json', ''));
      }
    }

    final resource = data['resource']?.toString().trim() ?? '';
    final resourceValue = _toInt(data['resource_value']);
    final costs = data['costs'];
    String? costResource;
    int? costAmount;
    if (costs is Map) {
      costResource = costs['resource']?.toString().trim();
      costAmount = _toInt(costs['amount']);
    } else {
      costResource = resource;
      costAmount =
          resourceValue != null && resourceValue > 0 ? resourceValue : null;
      if (!data.containsKey('costs') && resource.isNotEmpty) {
        data['costs'] = resource.toLowerCase() == 'signature'
            ? <String, dynamic>{'resource': resource, 'signature': true}
            : <String, dynamic>{
                'resource': resource,
                if (costAmount != null) 'amount': costAmount,
              };
      }
    }

    return <String>[
      'ability',
      classSlug,
      if (levelSegment != null && levelSegment.isNotEmpty) levelSegment,
      if (costResource != null && costResource.isNotEmpty)
        _slugify(costResource),
      if (costAmount != null) 'cost$costAmount',
      originalId,
    ].join('_');
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static String _slugify(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class _SeedRecord {
  const _SeedRecord({
    required this.id,
    required this.type,
    required this.name,
    required this.dataJson,
  });

  final String id;
  final String type;
  final String name;
  final String dataJson;

  ComponentsCompanion toInsertCompanion() {
    final now = DateTime.now();
    return ComponentsCompanion.insert(
      id: id,
      type: type,
      name: name,
      dataJson: Value(dataJson),
      source: const Value('seed'),
      parentId: const Value(null),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  ComponentsCompanion toUpdateCompanion() {
    return ComponentsCompanion(
      type: Value(type),
      name: Value(name),
      dataJson: Value(dataJson),
      source: const Value('seed'),
      parentId: const Value(null),
      updatedAt: Value(DateTime.now()),
    );
  }
}
