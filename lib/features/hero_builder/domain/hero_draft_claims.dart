import '../../../core/storage/hero_storage_contract.dart';
import 'hero_claim.dart';
import 'hero_draft.dart';
import 'hero_mutation_scope.dart';

/// Maps builder drafts onto conflict-index inputs.
///
/// Sources and entry types follow the canonical owner matrix in
/// `hero_builder_provenance_plan.md`. Families whose claims require async
/// grant expansion — ancestry traits, complication nested grants, perk-nested
/// picks, and the Strength feature option batch — are deliberately absent
/// here; their editors keep their own projections until each one migrates
/// into the controller.
class HeroDraftClaims {
  HeroDraftClaims._();

  static const cultureLanguageSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.culture,
    sourceId: HeroEntrySourceIds.cultureLanguages,
  );
  static const cultureEnvironmentSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.culture,
    sourceId: HeroEntrySourceIds.cultureEnvironment,
  );
  static const cultureOrganisationSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.culture,
    sourceId: HeroEntrySourceIds.cultureOrganisation,
  );
  static const cultureUpbringingSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.culture,
    sourceId: HeroEntrySourceIds.cultureUpbringing,
  );
  static const careerChoiceSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.career,
    sourceId: HeroEntrySourceIds.careerChoice,
  );
  static const strifeAbilitySource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.manualChoice,
    sourceId: HeroEntrySourceIds.strifeAbilityChoice,
  );
  static const strifeSkillSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.manualChoice,
    sourceId: HeroEntrySourceIds.strifeSkillChoice,
  );
  static const strifePerkSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.manualChoice,
    sourceId: HeroEntrySourceIds.strifePerkChoice,
  );
  static const subclassSkillSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.subclass,
    sourceId: HeroEntrySourceIds.subclassSkill,
  );
  static const equipmentSlotsSource = HeroClaimSource(
    sourceType: HeroEntrySourceTypes.equipment,
    sourceId: HeroEntrySourceIds.equipmentSlots,
  );

  static HeroClaimSource skillGroupSource(String featureId, String grantKey) {
    return HeroClaimSource(
      sourceType: HeroEntrySourceTypes.classFeature,
      sourceId: '${featureId}_skill_group_$grantKey',
    );
  }

  // Slot keys identify a draft claim's owning editor slot. They are in-memory
  // identity only — never persisted — but editors and this mapping must agree
  // on them, so they live here rather than as literals in a page.

  static const String cultureLanguageSlot = 'story.culture:language#0';
  static const String cultureEnvironmentSkillSlot =
      'story.culture:environment-skill#0';
  static const String cultureOrganisationSkillSlot =
      'story.culture:organisation-skill#0';
  static const String cultureUpbringingSkillSlot =
      'story.culture:upbringing-skill#0';
  static const String subclassSkillSlot = 'strife.subclass:skill#0';

  /// Perk pickers build their own `<prefix>#<index>` keys, so they consume the
  /// prefix rather than the full slot key.
  static const String careerPerkSlotPrefix = 'story.career:perk';

  static String careerLanguageSlot(int index) => 'story.career:language#$index';
  static String careerSkillSlot(int index) => 'story.career:skill#$index';
  static String careerPerkSlot(int index) => '$careerPerkSlotPrefix#$index';
  /// Strife slot keys are built from the same `<allowanceId>#<index>` key the
  /// `strife.*_selections` configs use, so a config key maps straight to a slot.
  static String strifeAbilitySlot(String slotKey) => 'strife.ability:$slotKey';
  static String strifeSkillSlot(String slotKey) => 'strife.skills:$slotKey';
  static String strifePerkSlot(String slotKey) => 'strife.perks:$slotKey';

  /// The `<allowanceId>#<index>` key shared by the selection configs and slots.
  static String strifeSelectionKey(String allowanceId, int index) =>
      '$allowanceId#$index';

  /// Perk pickers append `#<index>` themselves.
  static String strifePerkSlotPrefix(String allowanceId) =>
      'strife.perks:$allowanceId';
  static String equipmentSlot(int index) => 'strife.equipment:slot#$index';
  static String skillGroupSlot(String featureId, String grantKey) =>
      'class_feature:$featureId:$grantKey';

  /// The persisted sources the current drafts replace, scoped by entry type
  /// exactly as the owner matrix declares.
  static List<HeroMutationScope> mutationScopes({
    required StrengthDraft baselineStrength,
    required StrengthDraft strength,
  }) {
    final scopes = <HeroMutationScope>[
      HeroMutationScope.single(
        cultureLanguageSource,
        entryType: HeroEntryTypes.language,
      ),
      HeroMutationScope.single(
        cultureEnvironmentSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        cultureOrganisationSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        cultureUpbringingSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        careerChoiceSource,
        entryType: HeroEntryTypes.language,
      ),
      HeroMutationScope.single(
        careerChoiceSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        careerChoiceSource,
        entryType: HeroEntryTypes.perk,
      ),
      HeroMutationScope.single(
        strifeAbilitySource,
        entryType: HeroEntryTypes.ability,
      ),
      HeroMutationScope.single(
        strifeSkillSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        strifePerkSource,
        entryType: HeroEntryTypes.perk,
      ),
      HeroMutationScope.single(
        subclassSkillSource,
        entryType: HeroEntryTypes.skill,
      ),
      HeroMutationScope.single(
        equipmentSlotsSource,
        entryType: HeroEntryTypes.equipment,
      ),
    ];

    // Skill-group scopes must cover the union of old and new nested choices so
    // a cleared or re-keyed choice's persisted row is also projected away.
    final skillGroupSources = <HeroClaimSource>{};
    void collect(StrengthDraft draft) {
      for (final feature in draft.skillGroupSelections.entries) {
        for (final grantKey in feature.value.keys) {
          skillGroupSources.add(skillGroupSource(feature.key, grantKey));
        }
      }
    }

    collect(baselineStrength);
    collect(strength);
    for (final source in skillGroupSources) {
      scopes.add(
        HeroMutationScope.single(source, entryType: HeroEntryTypes.skill),
      );
    }

    return scopes;
  }

  /// Every non-empty draft slot as a claim with a stable slot key.
  static List<HeroEntryClaim> draftClaims({
    required StoryDraft story,
    required StrifeDraft strife,
    required StrengthDraft strength,
  }) {
    final claims = <HeroEntryClaim>[];

    void add({
      required String entryType,
      required String? entryId,
      required HeroClaimSource source,
      required String slotKey,
      required String label,
    }) {
      final normalized = entryId?.trim();
      if (normalized == null || normalized.isEmpty) return;
      claims.add(
        HeroEntryClaim(
          key: HeroEntryKey(entryType: entryType, canonicalEntryId: normalized),
          owner: HeroClaimOwner.draft(
            source: source,
            slotKey: slotKey,
            displayLabel: label,
          ),
        ),
      );
    }

    // Story: culture language and skills.
    add(
      entryType: HeroEntryTypes.language,
      entryId: story.cultureLanguageId,
      source: cultureLanguageSource,
      slotKey: cultureLanguageSlot,
      label: 'Culture language',
    );
    add(
      entryType: HeroEntryTypes.skill,
      entryId: story.environmentSkillId,
      source: cultureEnvironmentSource,
      slotKey: cultureEnvironmentSkillSlot,
      label: 'Culture environment skill',
    );
    add(
      entryType: HeroEntryTypes.skill,
      entryId: story.organisationSkillId,
      source: cultureOrganisationSource,
      slotKey: cultureOrganisationSkillSlot,
      label: 'Culture organisation skill',
    );
    add(
      entryType: HeroEntryTypes.skill,
      entryId: story.upbringingSkillId,
      source: cultureUpbringingSource,
      slotKey: cultureUpbringingSkillSlot,
      label: 'Culture upbringing skill',
    );

    // Story: ordered career language slots plus career skills/perks.
    for (var i = 0; i < story.careerLanguageIds.length; i++) {
      add(
        entryType: HeroEntryTypes.language,
        entryId: story.careerLanguageIds[i],
        source: careerChoiceSource,
        slotKey: careerLanguageSlot(i),
        label: 'Career language ${i + 1}',
      );
    }
    var slot = 0;
    for (final skillId in story.careerSkillIds) {
      add(
        entryType: HeroEntryTypes.skill,
        entryId: skillId,
        source: careerChoiceSource,
        slotKey: careerSkillSlot(slot),
        label: 'Career skill ${slot + 1}',
      );
      slot++;
    }
    slot = 0;
    for (final perkId in story.careerPerkIds) {
      add(
        entryType: HeroEntryTypes.perk,
        entryId: perkId,
        source: careerChoiceSource,
        slotKey: careerPerkSlot(slot),
        label: 'Career perk ${slot + 1}',
      );
      slot++;
    }

    // Strife: ability/skill/perk slot maps keyed like their persisted configs.
    strife.abilitySelections.forEach((key, value) {
      add(
        entryType: HeroEntryTypes.ability,
        entryId: value,
        source: strifeAbilitySource,
        slotKey: strifeAbilitySlot(key),
        label: 'Strife ability slot',
      );
    });
    strife.skillSelections.forEach((key, value) {
      add(
        entryType: HeroEntryTypes.skill,
        entryId: value,
        source: strifeSkillSource,
        slotKey: strifeSkillSlot(key),
        label: 'Strife skill slot',
      );
    });
    strife.perkSelections.forEach((key, value) {
      add(
        entryType: HeroEntryTypes.perk,
        entryId: value,
        source: strifePerkSource,
        slotKey: strifePerkSlot(key),
        label: 'Strife perk slot',
      );
    });
    add(
      entryType: HeroEntryTypes.skill,
      entryId: strife.subclass?.skillId,
      source: subclassSkillSource,
      slotKey: subclassSkillSlot,
      label: 'Subclass skill',
    );
    for (var i = 0; i < strife.equipmentIds.length; i++) {
      add(
        entryType: HeroEntryTypes.equipment,
        entryId: strife.equipmentIds[i],
        source: equipmentSlotsSource,
        slotKey: equipmentSlot(i),
        label: 'Equipment slot ${i + 1}',
      );
    }

    // Strength: nested skill-group choices.
    strength.skillGroupSelections.forEach((featureId, grants) {
      grants.forEach((grantKey, skillId) {
        add(
          entryType: HeroEntryTypes.skill,
          entryId: skillId,
          source: skillGroupSource(featureId, grantKey),
          slotKey: skillGroupSlot(featureId, grantKey),
          label: 'Class feature skill choice',
        );
      });
    });

    return claims;
  }
}
