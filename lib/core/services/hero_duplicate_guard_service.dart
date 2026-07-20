import '../db/app_database.dart' as db;
import '../storage/hero_storage_contract.dart';

/// Centralizes duplicate-prevention rules for hero-owned entries that should
/// only appear once on a hero.
class HeroDuplicateGuardService {
  const HeroDuplicateGuardService();

  /// Every component-backed hero entry is non-repeating unless the game rule
  /// explicitly exempts it. Titles are intentionally deferred: a hero may
  /// currently hold multiple title rows and their progression semantics will
  /// be handled in the dedicated title slice.
  static final Set<String> nonRepeatingEntryTypes = Set<String>.unmodifiable(
    HeroEntryTypes.componentBackedTypes.difference(
      const {HeroEntryTypes.title},
    ),
  );

  bool guardsEntryType(String entryType) {
    return nonRepeatingEntryTypes.contains(entryType);
  }

  Set<String> reservedIds({
    required Iterable<db.HeroEntry> entries,
    required String entryType,
    Iterable<String?> localIds = const <String?>[],
    HeroEntrySourceRef? exceptSource,
    String? currentId,
  }) {
    if (!guardsEntryType(entryType)) return const <String>{};

    final reserved = <String>{};
    for (final entry in entries) {
      if (entry.entryType != entryType) continue;
      if (exceptSource != null && exceptSource.matches(entry)) continue;
      final normalized = normalizeId(entry.entryId);
      if (normalized != null) {
        reserved.add(normalized);
      }
    }

    for (final id in localIds) {
      final normalized = normalizeId(id);
      if (normalized != null) {
        reserved.add(normalized);
      }
    }

    final normalizedCurrent = normalizeId(currentId);
    if (normalizedCurrent != null) {
      reserved.remove(normalizedCurrent);
    }
    return reserved;
  }

  Set<String> conflictingIds({
    required Iterable<String?> candidateIds,
    required Iterable<db.HeroEntry> entries,
    required String entryType,
    Iterable<String?> localIds = const <String?>[],
    HeroEntrySourceRef? exceptSource,
  }) {
    if (!guardsEntryType(entryType)) return const <String>{};

    final reserved = reservedIds(
      entries: entries,
      entryType: entryType,
      localIds: localIds,
      exceptSource: exceptSource,
    );

    return candidateIds
        .map(normalizeId)
        .whereType<String>()
        .where(reserved.contains)
        .toSet();
  }

  bool isReserved({
    required String? candidateId,
    required Iterable<db.HeroEntry> entries,
    required String entryType,
    Iterable<String?> localIds = const <String?>[],
    HeroEntrySourceRef? exceptSource,
    String? currentId,
  }) {
    final normalized = normalizeId(candidateId);
    if (normalized == null) return false;
    return reservedIds(
      entries: entries,
      entryType: entryType,
      localIds: localIds,
      exceptSource: exceptSource,
      currentId: currentId,
    ).contains(normalized);
  }

  static String? normalizeId(String? id) {
    final trimmed = id?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class HeroEntrySourceRef {
  const HeroEntrySourceRef({
    required this.sourceType,
    required this.sourceId,
  });

  final String sourceType;
  final String sourceId;

  bool matches(db.HeroEntry entry) {
    return entry.sourceType == sourceType && entry.sourceId == sourceId;
  }
}
