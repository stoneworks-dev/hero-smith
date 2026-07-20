import 'hero_claim.dart';
import 'hero_mutation_scope.dart';

enum HeroConflictKind { crossSource, withinDraft }

class HeroConflict {
  const HeroConflict({
    required this.key,
    required this.owners,
    required this.kind,
  });

  final HeroEntryKey key;
  final List<HeroClaimOwner> owners;
  final HeroConflictKind kind;
}

/// An immutable, source-preserving index of effective hero claims.
class HeroConflictIndex {
  const HeroConflictIndex._(this._ownersByKey);

  static const HeroConflictIndex empty = HeroConflictIndex._({});

  final Map<HeroEntryKey, Set<HeroClaimOwner>> _ownersByKey;

  factory HeroConflictIndex.projected({
    required Iterable<HeroEntryClaim> persistedClaims,
    Iterable<HeroEntryClaim> draftClaims = const [],
    Iterable<HeroMutationScope> mutationScopes = const [],
  }) {
    final scopes = mutationScopes.toList(growable: false);
    final ownersByKey = <HeroEntryKey, Set<HeroClaimOwner>>{};

    for (final claim in persistedClaims) {
      final isReplaced = scopes.any(
        (scope) => scope.replaces(claim),
      );
      if (!isReplaced) {
        _addClaim(ownersByKey, claim);
      }
    }
    for (final claim in draftClaims) {
      _addClaim(ownersByKey, claim);
    }

    return HeroConflictIndex._(_freeze(ownersByKey));
  }

  HeroConflictIndex withClaims(Iterable<HeroEntryClaim> claims) {
    final ownersByKey = <HeroEntryKey, Set<HeroClaimOwner>>{
      for (final entry in _ownersByKey.entries)
        entry.key: Set<HeroClaimOwner>.from(entry.value),
    };
    for (final claim in claims) {
      _addClaim(ownersByKey, claim);
    }
    return HeroConflictIndex._(_freeze(ownersByKey));
  }

  /// Projects a mutation on top of an already-projected index. This is used by
  /// nested editors (for example a perk grant picker) that must preserve the
  /// parent draft's effective claims while replacing only their own source.
  HeroConflictIndex replacing({
    Iterable<HeroMutationScope> mutationScopes = const [],
    Iterable<HeroEntryClaim> draftClaims = const [],
  }) {
    final scopes = mutationScopes.toList(growable: false);
    final ownersByKey = <HeroEntryKey, Set<HeroClaimOwner>>{};
    for (final entry in _ownersByKey.entries) {
      for (final owner in entry.value) {
        final claim = HeroEntryClaim(key: entry.key, owner: owner);
        if (!scopes.any((scope) => scope.replaces(claim))) {
          _addClaim(ownersByKey, claim);
        }
      }
    }
    for (final claim in draftClaims) {
      _addClaim(ownersByKey, claim);
    }
    return HeroConflictIndex._(_freeze(ownersByKey));
  }

  bool isClaimed(
    HeroEntryKey key, {
    String? ignoredDraftSlotKey,
  }) {
    return ownersFor(
      key,
      ignoredDraftSlotKey: ignoredDraftSlotKey,
    ).isNotEmpty;
  }

  HeroConflict? conflictFor(
    HeroEntryKey key, {
    String? ignoredDraftSlotKey,
  }) {
    final owners = ownersFor(
      key,
      ignoredDraftSlotKey: ignoredDraftSlotKey,
    );
    if (owners.isEmpty) return null;

    final isWithinDraft = owners.every(
      (owner) => owner.origin == HeroClaimOrigin.draft,
    );
    return HeroConflict(
      key: key,
      owners: owners,
      kind: isWithinDraft
          ? HeroConflictKind.withinDraft
          : HeroConflictKind.crossSource,
    );
  }

  List<HeroClaimOwner> ownersFor(
    HeroEntryKey key, {
    String? ignoredDraftSlotKey,
  }) {
    final normalizedIgnoredSlot = ignoredDraftSlotKey?.trim();
    final owners = _ownersByKey[key]
            ?.where(
              (owner) => !(owner.origin == HeroClaimOrigin.draft &&
                  normalizedIgnoredSlot != null &&
                  normalizedIgnoredSlot.isNotEmpty &&
                  owner.normalizedSlotKey == normalizedIgnoredSlot),
            )
            .toList() ??
        <HeroClaimOwner>[];
    owners.sort(_compareOwners);
    return List<HeroClaimOwner>.unmodifiable(owners);
  }

  Set<String> claimedEntryIds(String entryType) {
    final normalizedEntryType = entryType.trim();
    return Set<String>.unmodifiable(
      _ownersByKey.entries
          .where(
            (entry) =>
                entry.key.normalizedEntryType == normalizedEntryType &&
                entry.value.isNotEmpty,
          )
          .map((entry) => entry.key.normalizedEntryId),
    );
  }

  static void _addClaim(
    Map<HeroEntryKey, Set<HeroClaimOwner>> ownersByKey,
    HeroEntryClaim claim,
  ) {
    if (claim.key.normalizedEntryType.isEmpty ||
        claim.key.normalizedEntryId.isEmpty ||
        claim.owner.source.normalizedSourceType.isEmpty) {
      return;
    }
    ownersByKey.putIfAbsent(claim.key, () => <HeroClaimOwner>{}).add(
          claim.owner,
        );
  }

  static Map<HeroEntryKey, Set<HeroClaimOwner>> _freeze(
    Map<HeroEntryKey, Set<HeroClaimOwner>> ownersByKey,
  ) {
    return Map<HeroEntryKey, Set<HeroClaimOwner>>.unmodifiable({
      for (final entry in ownersByKey.entries)
        entry.key: Set<HeroClaimOwner>.unmodifiable(entry.value),
    });
  }

  static int _compareOwners(HeroClaimOwner a, HeroClaimOwner b) {
    var result = a.origin.index.compareTo(b.origin.index);
    if (result != 0) return result;
    result =
        a.source.normalizedSourceType.compareTo(b.source.normalizedSourceType);
    if (result != 0) return result;
    result = a.source.normalizedSourceId.compareTo(b.source.normalizedSourceId);
    if (result != 0) return result;
    return (a.normalizedSlotKey ?? '').compareTo(b.normalizedSlotKey ?? '');
  }
}
