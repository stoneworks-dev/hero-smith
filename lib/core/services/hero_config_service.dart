import '../db/app_database.dart';

/// Service wrapper around hero_config for structured read/write.
class HeroConfigService {
  HeroConfigService(this._db);
  final AppDatabase _db;

  Future<void> setConfigValue({
    required String heroId,
    required String key,
    required Map<String, dynamic> value,
    String? metadata,
  }) {
    return _db.setHeroConfig(
      heroId: heroId,
      configKey: key,
      value: value,
      metadata: metadata,
    );
  }

  Future<Map<String, dynamic>?> getConfigValue(
      String heroId, String key) async {
    return _db.getHeroConfigValue(heroId, key);
  }

  /// Return all config keys for a hero as a map keyed by configKey.
  Future<Map<String, Map<String, dynamic>>> getConfigMap(String heroId) async {
    final rows = await (_db.select(_db.heroConfig)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      try {
        result[row.configKey] =
            (await getConfigValue(heroId, row.configKey)) ?? {};
      } catch (_) {
        // Ignore parse failures; keep entry absent.
      }
    }
    return result;
  }

  Future<void> removeConfigKey(String heroId, String key) {
    return _db.deleteHeroConfig(heroId, key);
  }

  Stream<List<HeroConfigData>> watchConfig(String heroId) {
    return (_db.select(_db.heroConfig)..where((t) => t.heroId.equals(heroId)))
        .watch();
  }
}
