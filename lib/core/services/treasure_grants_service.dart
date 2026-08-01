import '../db/app_database.dart';
import '../models/canonical_grant_model.dart';
import '../models/hero_mutation_model.dart';
import '../storage/hero_storage_contract.dart';
import 'hero_mutation_service.dart';

/// Applies and removes abilities granted by an equipped treasure.
///
/// Treasures (trinkets, leveled treasures, artifacts) may grant an ability
/// via a canonical `{"kind": "entry", "entry_type": "ability", "entry_id": ...}`
/// grant, exactly like perks/kits/titles. Unlike those sources, a treasure's
/// grant is only live while the treasure is equipped, so callers apply it on
/// equip and remove it on unequip (or on removal of the treasure itself).
/// All entries are written to hero_entries with source_type='treasure' and
/// source_id=<treasureId>, so the granted ability shows up automatically
/// through the same hero_entries-driven ability list the rest of the app uses.
class TreasureGrantsService {
  TreasureGrantsService(AppDatabase db, {HeroMutationService? mutations})
      : _mutations = mutations ?? HeroMutationService(db);

  final HeroMutationService _mutations;

  /// Apply (or replace) the ability grants declared by a treasure's `grants`
  /// field. Safe to call with any JSON shape; non-ability and non-canonical
  /// grants are ignored. Calling with no ability grants clears any
  /// previously-applied ones for this treasure.
  Future<void> applyTreasureAbilityGrants({
    required String heroId,
    required String treasureId,
    required dynamic grantsJson,
  }) async {
    final abilityIds = _extractAbilityEntryIds(grantsJson);
    await _mutations.replaceContentEntries(
      heroId: heroId,
      source: _treasureSource(treasureId),
      entryType: HeroEntryTypes.ability,
      entryIds: abilityIds,
    );
  }

  /// Remove all abilities previously granted by this treasure.
  Future<void> removeTreasureAbilityGrants({
    required String heroId,
    required String treasureId,
  }) async {
    await _mutations.removeSource(
      heroId: heroId,
      source: _treasureSource(treasureId),
      entryType: HeroEntryTypes.ability,
      recomputeAggregates: false,
    );
  }

  HeroSource _treasureSource(String treasureId) => HeroSource(
        sourceType: HeroEntrySourceTypes.treasure,
        sourceId: treasureId,
      );

  List<String> _extractAbilityEntryIds(dynamic grantsJson) {
    if (!_looksLikeCanonicalGrants(grantsJson)) return const [];

    List<CanonicalGrant> parsed;
    try {
      parsed = CanonicalGrant.parseList(grantsJson, defaultSource: 'treasure');
    } catch (_) {
      return const [];
    }

    final seen = <String>{};
    final abilityIds = <String>[];
    for (final grant in parsed) {
      if (grant is! CanonicalEntryGrant) continue;
      if (grant.entryType != HeroEntryTypes.ability) continue;
      final entryId = grant.entryId.trim();
      if (entryId.isEmpty || !seen.add(entryId)) continue;
      abilityIds.add(entryId);
    }
    return abilityIds;
  }

  bool _looksLikeCanonicalGrants(dynamic grants) {
    if (grants is Map) {
      if (grants['schema'] == canonicalGrantSchemaId) return true;
      if (grants.containsKey('kind')) return true;
      final nested = grants['grants'];
      return nested != null && _looksLikeCanonicalGrants(nested);
    }
    if (grants is List) {
      return grants.any((grant) => grant is Map && grant.containsKey('kind'));
    }
    return false;
  }
}
