import 'hero_claim.dart';

/// Declares the exact persisted source tuples replaced by one editor draft.
class HeroMutationScope {
  HeroMutationScope({
    required Iterable<HeroClaimSource> replacedSources,
    this.entryType,
    Iterable<String>? entryIds,
  })  : replacedSources = Set<HeroClaimSource>.unmodifiable(replacedSources),
        entryIds = entryIds == null
            ? null
            : Set<String>.unmodifiable(
                entryIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
              );

  HeroMutationScope.single(
    HeroClaimSource source, {
    this.entryType,
    Iterable<String>? entryIds,
  })  : replacedSources = Set<HeroClaimSource>.unmodifiable({source}),
        entryIds = entryIds == null
            ? null
            : Set<String>.unmodifiable(
                entryIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
              );

  final Set<HeroClaimSource> replacedSources;
  final String? entryType;
  final Set<String>? entryIds;

  bool replaces(HeroEntryClaim claim) {
    if (!replacedSources.contains(claim.owner.source)) return false;
    final scopedEntryIds = entryIds;
    if (scopedEntryIds != null &&
        !scopedEntryIds.contains(claim.key.normalizedEntryId)) {
      return false;
    }
    final normalizedEntryType = entryType?.trim();
    return normalizedEntryType == null ||
        normalizedEntryType.isEmpty ||
        claim.key.normalizedEntryType == normalizedEntryType;
  }
}
