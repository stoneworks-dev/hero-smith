import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Repository dedicated to hero_entries (content ownership).
class HeroEntryRepository {
  HeroEntryRepository(this._db);
  final AppDatabase _db;

  Future<void> addEntry({
    required String heroId,
    required String entryType,
    required String entryId,
    String sourceType = 'manual_choice',
    String sourceId = '',
    String gainedBy = 'grant',
    Map<String, dynamic>? payload,
  }) {
    return _db.upsertHeroEntry(
      heroId: heroId,
      entryType: entryType,
      entryId: entryId,
      sourceType: sourceType,
      sourceId: sourceId,
      gainedBy: gainedBy,
      payload: payload,
    );
  }

  /// Replace all entries from a given source.
  Future<void> addEntriesFromSource({
    required String heroId,
    required String sourceType,
    required String sourceId,
    required String entryType,
    required Iterable<String> entryIds,
    String gainedBy = 'grant',
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.heroEntries)
            ..where((t) =>
                t.heroId.equals(heroId) &
                t.sourceType.equals(sourceType) &
                t.sourceId.equals(sourceId) &
                t.entryType.equals(entryType)))
          .go();
      for (final id in entryIds.where((e) => e.isNotEmpty)) {
        await addEntry(
          heroId: heroId,
          entryType: entryType,
          entryId: id,
          sourceType: sourceType,
          sourceId: sourceId,
          gainedBy: gainedBy,
        );
      }
    });
  }

  Future<int> removeEntriesFromSource({
    required String heroId,
    required String sourceType,
    String? sourceId,
    String? entryType,
  }) {
    final query = _db.delete(_db.heroEntries)
      ..where((t) => t.heroId.equals(heroId) & t.sourceType.equals(sourceType));
    if (sourceId != null) {
      query.where((t) => t.sourceId.equals(sourceId));
    }
    if (entryType != null) {
      query.where((t) => t.entryType.equals(entryType));
    }
    return query.go();
  }

  /// Remove a specific entry by heroId, entryType, and entryId.
  /// This removes the entry regardless of source type (useful for career-granted perks, etc.)
  Future<int> removeEntryById(String heroId, String entryType, String entryId) {
    return (_db.delete(_db.heroEntries)
          ..where((t) =>
              t.heroId.equals(heroId) &
              t.entryType.equals(entryType) &
              t.entryId.equals(entryId)))
        .go();
  }

  Future<List<HeroEntry>> listEntriesByType(
      String heroId, String entryType) async {
    return (_db.select(_db.heroEntries)
          ..where((t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .get();
  }

  Future<List<HeroEntry>> listAllEntriesForHero(String heroId) async {
    return (_db.select(_db.heroEntries)..where((t) => t.heroId.equals(heroId)))
        .get();
  }

  Future<Set<String>> getEntryTypesForHero(String heroId) async {
    final rows = await (_db.customSelect(
      'SELECT DISTINCT entry_type as et FROM hero_entries WHERE hero_id = ?',
      variables: [Variable.withString(heroId)],
    )).get();
    return rows
        .map((r) => r.data['et']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Future<List<HeroEntry>> getEntriesWithSourceInformation(
      String heroId, String entryType) async {
    return listEntriesByType(heroId, entryType);
  }

  Stream<List<HeroEntry>> watchEntries(String heroId) {
    return (_db.select(_db.heroEntries)..where((t) => t.heroId.equals(heroId)))
        .watch();
  }

  Stream<List<HeroEntry>> watchEntriesByType(
      String heroId, String entryType) {
    return (_db.select(_db.heroEntries)
          ..where((t) => t.heroId.equals(heroId) & t.entryType.equals(entryType)))
        .watch();
  }

  /// Convenience: entries grouped by source key "sourceType:sourceId".
  Future<Map<String, List<HeroEntry>>> entriesGroupedBySource(
      String heroId) async {
    final entries = await listAllEntriesForHero(heroId);
    return groupBy(
        entries, (HeroEntry e) => '${e.sourceType}:${e.sourceId}'.trim());
  }
}
