/// The rule-level identity of one hero component.
///
/// Display names are deliberately excluded: conflict checks operate on stable
/// component IDs within an entry type.
class HeroEntryKey {
  const HeroEntryKey({
    required this.entryType,
    required this.canonicalEntryId,
  });

  final String entryType;
  final String canonicalEntryId;

  String get normalizedEntryType => entryType.trim();
  String get normalizedEntryId => canonicalEntryId.trim();

  @override
  bool operator ==(Object other) {
    return other is HeroEntryKey &&
        other.normalizedEntryType == normalizedEntryType &&
        other.normalizedEntryId == normalizedEntryId;
  }

  @override
  int get hashCode => Object.hash(normalizedEntryType, normalizedEntryId);

  @override
  String toString() => '$normalizedEntryType:$normalizedEntryId';
}

/// The persisted source tuple that owns a hero entry.
class HeroClaimSource {
  const HeroClaimSource({
    required this.sourceType,
    required this.sourceId,
  });

  final String sourceType;
  final String sourceId;

  String get normalizedSourceType => sourceType.trim();
  String get normalizedSourceId => sourceId.trim();

  @override
  bool operator ==(Object other) {
    return other is HeroClaimSource &&
        other.normalizedSourceType == normalizedSourceType &&
        other.normalizedSourceId == normalizedSourceId;
  }

  @override
  int get hashCode => Object.hash(normalizedSourceType, normalizedSourceId);

  @override
  String toString() => '$normalizedSourceType:$normalizedSourceId';
}

enum HeroClaimOrigin { persisted, draft }

/// One owner of a component claim.
///
/// Draft claims carry a stable [slotKey]. Persisted claims are replaced by
/// source tuple because the current storage schema does not persist slot keys.
class HeroClaimOwner {
  const HeroClaimOwner.persisted({
    required this.source,
    this.displayLabel,
  })  : origin = HeroClaimOrigin.persisted,
        slotKey = null;

  const HeroClaimOwner.draft({
    required this.source,
    required this.slotKey,
    this.displayLabel,
  }) : origin = HeroClaimOrigin.draft;

  final HeroClaimSource source;
  final HeroClaimOrigin origin;
  final String? slotKey;
  final String? displayLabel;

  String? get normalizedSlotKey {
    final normalized = slotKey?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  bool operator ==(Object other) {
    return other is HeroClaimOwner &&
        other.source == source &&
        other.origin == origin &&
        other.normalizedSlotKey == normalizedSlotKey;
  }

  @override
  int get hashCode => Object.hash(source, origin, normalizedSlotKey);

  @override
  String toString() {
    final slotSuffix = normalizedSlotKey == null ? '' : '#$normalizedSlotKey';
    return '${origin.name}:$source$slotSuffix';
  }
}

class HeroEntryClaim {
  const HeroEntryClaim({
    required this.key,
    required this.owner,
  });

  final HeroEntryKey key;
  final HeroClaimOwner owner;

  @override
  bool operator ==(Object other) {
    return other is HeroEntryClaim && other.key == key && other.owner == owner;
  }

  @override
  int get hashCode => Object.hash(key, owner);
}
