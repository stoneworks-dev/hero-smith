import 'native_snapshot_exceptions.dart';

/// A pure migration from one native snapshot schema version to the next.
typedef NativeSnapshotMigration = Map<String, dynamic> Function(
  Map<String, dynamic> snapshot,
);

/// Ordered native snapshot migrations.
///
/// There is no pre-v2 HS2 schema in repository history: the predecessor was
/// the retired `P:` picks-only format. Therefore the registry starts empty and
/// deliberately refuses a hypothetical older HS2 version until its exact
/// migration has been implemented and tested.
class NativeSnapshotMigrator {
  NativeSnapshotMigrator._();

  static final Map<int, NativeSnapshotMigration> _migrations = {};

  static Map<String, dynamic> migrateToCurrent(
    Map<String, dynamic> decoded, {
    required int currentVersion,
  }) {
    final rawVersion = decoded['v'];
    if (rawVersion is! int || rawVersion <= 0) {
      throw const NativeSnapshotException(
        code: 'native.snapshot_invalid',
        fieldPath: 'v',
        message: 'Invalid native snapshot: version is required',
      );
    }
    if (rawVersion > currentVersion) {
      throw NativeSnapshotException(
        code: 'native.version_too_new',
        fieldPath: 'v',
        message: 'Native snapshot version $rawVersion is newer than '
            'the supported version $currentVersion.',
      );
    }

    var version = rawVersion;
    var snapshot = _copyMap(decoded);
    while (version < currentVersion) {
      final migration = _migrations[version];
      if (migration == null) {
        throw NativeSnapshotException(
          code: 'native.version_unsupported',
          fieldPath: 'v',
          message: 'No native snapshot migration exists from v$version to '
              'v${version + 1}.',
        );
      }
      snapshot = migration(_copyMap(snapshot));
      final migratedVersion = snapshot['v'];
      if (migratedVersion != version + 1) {
        throw StateError(
          'Native migration v$version did not produce v${version + 1}.',
        );
      }
      version = migratedVersion;
    }
    return snapshot;
  }

  static Map<String, dynamic> _copyMap(Map<dynamic, dynamic> source) => {
        for (final entry in source.entries)
          entry.key.toString(): _copyValue(entry.value),
      };

  static dynamic _copyValue(dynamic value) {
    if (value is Map) return _copyMap(value);
    if (value is List) return value.map(_copyValue).toList(growable: false);
    return value;
  }
}
