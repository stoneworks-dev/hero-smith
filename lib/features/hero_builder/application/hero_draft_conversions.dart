import '../../../core/models/class_data.dart';
import '../../../core/models/story_creator_models.dart';
import '../../../core/models/subclass_models.dart';
import '../../../core/services/strife_creator_service.dart';
import '../domain/hero_draft.dart';

/// Converts builder drafts into the core models existing services and widgets
/// expect.
///
/// The domain layer cannot depend on these models (they import Flutter), so the
/// bridge lives in the application layer and is shared by the commit service
/// and the creator pages to keep one definition.
SubclassSelectionResult? subclassSelectionFromDraft(StrifeSubclassDraft? draft) {
  if (draft == null) return null;
  return SubclassSelectionResult(
    subclassKey: draft.subclassKey,
    subclassName: draft.subclassName,
    // Already the resolved skill id: the repository loads it straight from
    // the persisted `subclass:subclass_skill` entry row, and the picker
    // resolves names to ids before writing the draft slot.
    skill: draft.skillId,
    deityId: draft.deityId,
    // The Strength tab has only ever had the deity id available; it displays
    // the same value for both fields.
    deityName: draft.deityId,
    domainNames: draft.domainNames,
  );
}

/// Builds the Strife save payload from a draft.
///
/// [StrifeDraft] mirrors the payload's selection fields field-for-field; the
/// caller supplies what the draft doesn't carry: the resolved [ClassData],
/// the previously-persisted class id (for class-change detection), and the
/// previously-persisted perk ids (for grant-removal diffing).
StrifeCreatorSavePayload strifePayloadFromDraft({
  required String heroId,
  required StrifeDraft draft,
  required ClassData classData,
  required String? previousClassId,
  required Set<String> previousPerkIds,
}) {
  return StrifeCreatorSavePayload(
    heroId: heroId,
    classData: classData,
    previousClassId: previousClassId,
    level: draft.level,
    selectedArray: draft.arrayDescription == null
        ? null
        : CharacteristicArray(
            values: draft.arrayValues,
            description: draft.arrayDescription!,
          ),
    assignedCharacteristics: draft.assignedCharacteristics,
    levelChoiceSelections: draft.levelChoiceSelections,
    selectedAbilities: draft.abilitySelections,
    selectedSkills: draft.skillSelections,
    selectedPerks: draft.perkSelections,
    selectedSubclass: subclassSelectionFromDraft(draft.subclass),
    selectedKitIds: draft.equipmentIds,
    previousPerkIds: previousPerkIds,
  );
}

/// Builds the Story save payload from a draft.
///
/// [StoryDraft] mirrors the payload field-for-field, so this is a faithful
/// projection rather than a transformation.
StoryCreatorSavePayload storyPayloadFromDraft({
  required String heroId,
  required StoryDraft draft,
}) {
  return StoryCreatorSavePayload(
    heroId: heroId,
    name: draft.name,
    ancestryId: draft.ancestryId,
    ancestryTraitIds: draft.ancestryTraitIds,
    ancestryTraitChoices: draft.ancestryTraitChoices,
    environmentId: draft.environmentId,
    organisationId: draft.organisationId,
    upbringingId: draft.upbringingId,
    environmentSkillId: draft.environmentSkillId,
    organisationSkillId: draft.organisationSkillId,
    upbringingSkillId: draft.upbringingSkillId,
    cultureLanguageId: draft.cultureLanguageId,
    careerLanguageIds: draft.careerLanguageIds,
    careerId: draft.careerId,
    careerSkillIds: draft.careerSkillIds,
    careerPerkIds: draft.careerPerkIds,
    careerIncidentName: draft.careerIncidentName,
    complicationId: draft.complicationId,
    complicationChoices: draft.complicationChoices,
  );
}
