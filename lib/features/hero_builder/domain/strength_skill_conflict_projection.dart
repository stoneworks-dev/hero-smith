import '../../../core/storage/hero_storage_contract.dart';
import 'hero_claim.dart';
import 'hero_conflict_index.dart';
import 'hero_draft_claims.dart';
import 'hero_mutation_scope.dart';

// Ownership vocabulary is defined once in HeroDraftClaims; these aliases keep
// the Strength call sites readable.

HeroClaimSource strengthSkillGroupClaimSource(
  String featureId,
  String grantKey,
) =>
    HeroDraftClaims.skillGroupSource(featureId, grantKey);

String strengthSkillGroupSlotKey(String featureId, String grantKey) =>
    HeroDraftClaims.skillGroupSlot(featureId, grantKey);

HeroConflictIndex buildStrengthSkillConflictIndex({
  required Iterable<HeroEntryClaim> persistedClaims,
  required Map<String, Map<String, String>> selections,
}) {
  final activeSelections =
      <({String featureId, String grantKey, String skillId})>[
    for (final feature in selections.entries)
      for (final grant in feature.value.entries)
        if (grant.value.trim().isNotEmpty)
          (
            featureId: feature.key,
            grantKey: grant.key,
            skillId: grant.value,
          ),
  ];

  return HeroConflictIndex.projected(
    persistedClaims: persistedClaims,
    mutationScopes: activeSelections.map(
      (selection) => HeroMutationScope.single(
        strengthSkillGroupClaimSource(
          selection.featureId,
          selection.grantKey,
        ),
        entryType: HeroEntryTypes.skill,
      ),
    ),
    draftClaims: activeSelections.map(
      (selection) => HeroEntryClaim(
        key: HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: selection.skillId,
        ),
        owner: HeroClaimOwner.draft(
          source: strengthSkillGroupClaimSource(
            selection.featureId,
            selection.grantKey,
          ),
          slotKey: strengthSkillGroupSlotKey(
            selection.featureId,
            selection.grantKey,
          ),
          displayLabel: 'Class feature skill choice',
        ),
      ),
    ),
  );
}
