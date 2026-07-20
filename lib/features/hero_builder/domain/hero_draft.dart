import 'package:collection/collection.dart';

import 'hero_claim.dart';

/// Sentinel so `copyWith` can distinguish "not passed" from "set to null".
const Object _unset = Object();

const _setEq = SetEquality<String>();
const _listEq = ListEquality<String?>();
const _intListEq = ListEquality<int>();
const _mapEq = MapEquality<String, String>();
const _nullableMapEq = MapEquality<String, String?>();
const _intMapEq = MapEquality<String, int>();
const _deepEq = DeepCollectionEquality();

enum HeroBuilderSection { story, strife, strength }

/// The Story tab's complete choice state. Mirrors [StoryCreatorSavePayload]
/// so a commit can be built without re-deriving anything from widgets.
class StoryDraft {
  StoryDraft({
    this.name = '',
    this.ancestryId,
    Set<String> ancestryTraitIds = const <String>{},
    Map<String, String> ancestryTraitChoices = const <String, String>{},
    this.environmentId,
    this.organisationId,
    this.upbringingId,
    this.environmentSkillId,
    this.organisationSkillId,
    this.upbringingSkillId,
    this.cultureLanguageId,
    this.careerId,
    List<String?> careerLanguageIds = const <String?>[],
    Set<String> careerSkillIds = const <String>{},
    Set<String> careerPerkIds = const <String>{},
    this.careerIncidentName,
    this.complicationId,
    Map<String, String> complicationChoices = const <String, String>{},
  })  : ancestryTraitIds = Set<String>.unmodifiable(ancestryTraitIds),
        ancestryTraitChoices =
            Map<String, String>.unmodifiable(ancestryTraitChoices),
        careerLanguageIds = List<String?>.unmodifiable(careerLanguageIds),
        careerSkillIds = Set<String>.unmodifiable(careerSkillIds),
        careerPerkIds = Set<String>.unmodifiable(careerPerkIds),
        complicationChoices =
            Map<String, String>.unmodifiable(complicationChoices);

  final String name;
  final String? ancestryId;
  final Set<String> ancestryTraitIds;
  final Map<String, String> ancestryTraitChoices;
  final String? environmentId;
  final String? organisationId;
  final String? upbringingId;
  final String? environmentSkillId;
  final String? organisationSkillId;
  final String? upbringingSkillId;
  final String? cultureLanguageId;
  final String? careerId;
  final List<String?> careerLanguageIds;
  final Set<String> careerSkillIds;
  final Set<String> careerPerkIds;
  final String? careerIncidentName;
  final String? complicationId;
  final Map<String, String> complicationChoices;

  StoryDraft copyWith({
    String? name,
    Object? ancestryId = _unset,
    Set<String>? ancestryTraitIds,
    Map<String, String>? ancestryTraitChoices,
    Object? environmentId = _unset,
    Object? organisationId = _unset,
    Object? upbringingId = _unset,
    Object? environmentSkillId = _unset,
    Object? organisationSkillId = _unset,
    Object? upbringingSkillId = _unset,
    Object? cultureLanguageId = _unset,
    Object? careerId = _unset,
    List<String?>? careerLanguageIds,
    Set<String>? careerSkillIds,
    Set<String>? careerPerkIds,
    Object? careerIncidentName = _unset,
    Object? complicationId = _unset,
    Map<String, String>? complicationChoices,
  }) {
    return StoryDraft(
      name: name ?? this.name,
      ancestryId:
          identical(ancestryId, _unset) ? this.ancestryId : ancestryId as String?,
      ancestryTraitIds: ancestryTraitIds ?? this.ancestryTraitIds,
      ancestryTraitChoices: ancestryTraitChoices ?? this.ancestryTraitChoices,
      environmentId: identical(environmentId, _unset)
          ? this.environmentId
          : environmentId as String?,
      organisationId: identical(organisationId, _unset)
          ? this.organisationId
          : organisationId as String?,
      upbringingId: identical(upbringingId, _unset)
          ? this.upbringingId
          : upbringingId as String?,
      environmentSkillId: identical(environmentSkillId, _unset)
          ? this.environmentSkillId
          : environmentSkillId as String?,
      organisationSkillId: identical(organisationSkillId, _unset)
          ? this.organisationSkillId
          : organisationSkillId as String?,
      upbringingSkillId: identical(upbringingSkillId, _unset)
          ? this.upbringingSkillId
          : upbringingSkillId as String?,
      cultureLanguageId: identical(cultureLanguageId, _unset)
          ? this.cultureLanguageId
          : cultureLanguageId as String?,
      careerId:
          identical(careerId, _unset) ? this.careerId : careerId as String?,
      careerLanguageIds: careerLanguageIds ?? this.careerLanguageIds,
      careerSkillIds: careerSkillIds ?? this.careerSkillIds,
      careerPerkIds: careerPerkIds ?? this.careerPerkIds,
      careerIncidentName: identical(careerIncidentName, _unset)
          ? this.careerIncidentName
          : careerIncidentName as String?,
      complicationId: identical(complicationId, _unset)
          ? this.complicationId
          : complicationId as String?,
      complicationChoices: complicationChoices ?? this.complicationChoices,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoryDraft &&
        other.name == name &&
        other.ancestryId == ancestryId &&
        _setEq.equals(other.ancestryTraitIds, ancestryTraitIds) &&
        _mapEq.equals(other.ancestryTraitChoices, ancestryTraitChoices) &&
        other.environmentId == environmentId &&
        other.organisationId == organisationId &&
        other.upbringingId == upbringingId &&
        other.environmentSkillId == environmentSkillId &&
        other.organisationSkillId == organisationSkillId &&
        other.upbringingSkillId == upbringingSkillId &&
        other.cultureLanguageId == cultureLanguageId &&
        other.careerId == careerId &&
        _listEq.equals(other.careerLanguageIds, careerLanguageIds) &&
        _setEq.equals(other.careerSkillIds, careerSkillIds) &&
        _setEq.equals(other.careerPerkIds, careerPerkIds) &&
        other.careerIncidentName == careerIncidentName &&
        other.complicationId == complicationId &&
        _mapEq.equals(other.complicationChoices, complicationChoices);
  }

  @override
  int get hashCode => Object.hash(
        name,
        ancestryId,
        _setEq.hash(ancestryTraitIds),
        _mapEq.hash(ancestryTraitChoices),
        environmentId,
        organisationId,
        upbringingId,
        environmentSkillId,
        organisationSkillId,
        upbringingSkillId,
        cultureLanguageId,
        careerId,
        _listEq.hash(careerLanguageIds),
        _setEq.hash(careerSkillIds),
        _setEq.hash(careerPerkIds),
        careerIncidentName,
        complicationId,
        _mapEq.hash(complicationChoices),
      );
}

/// Subclass choice as the Strife draft owns it.
///
/// Deliberately a domain value rather than a reuse of
/// `SubclassSelectionResult`, which lives in a Flutter-importing model file;
/// the application layer converts between the two.
class StrifeSubclassDraft {
  StrifeSubclassDraft({
    this.subclassKey,
    this.subclassName,
    this.skillId,
    this.deityId,
    List<String> domainNames = const <String>[],
  }) : domainNames = List<String>.unmodifiable(domainNames);

  final String? subclassKey;
  final String? subclassName;

  /// The fixed subclass skill grant, owned by `subclass:subclass_skill`.
  final String? skillId;
  final String? deityId;
  final List<String> domainNames;

  @override
  bool operator ==(Object other) {
    return other is StrifeSubclassDraft &&
        other.subclassKey == subclassKey &&
        other.subclassName == subclassName &&
        other.skillId == skillId &&
        other.deityId == deityId &&
        const ListEquality<String>().equals(other.domainNames, domainNames);
  }

  @override
  int get hashCode => Object.hash(
        subclassKey,
        subclassName,
        skillId,
        deityId,
        const ListEquality<String>().hash(domainNames),
      );
}

/// The Strife tab's complete choice state, mirroring the fields the page's
/// dirty snapshot tracks today. Slot maps are keyed by the same allowance keys
/// the persisted `strife.*_selections` configs use.
class StrifeDraft {
  StrifeDraft({
    this.level = 1,
    this.classId,
    this.arrayDescription,
    List<int> arrayValues = const <int>[],
    Map<String, int> assignedCharacteristics = const <String, int>{},
    Map<String, String?> levelChoiceSelections = const <String, String?>{},
    Map<String, String?> skillSelections = const <String, String?>{},
    Map<String, String?> abilitySelections = const <String, String?>{},
    Map<String, String?> perkSelections = const <String, String?>{},
    this.subclass,
    List<String?> equipmentIds = const <String?>[],
  })  : arrayValues = List<int>.unmodifiable(arrayValues),
        assignedCharacteristics =
            Map<String, int>.unmodifiable(assignedCharacteristics),
        levelChoiceSelections =
            Map<String, String?>.unmodifiable(levelChoiceSelections),
        skillSelections = Map<String, String?>.unmodifiable(skillSelections),
        abilitySelections =
            Map<String, String?>.unmodifiable(abilitySelections),
        perkSelections = Map<String, String?>.unmodifiable(perkSelections),
        equipmentIds = List<String?>.unmodifiable(equipmentIds);

  final int level;
  final String? classId;
  final String? arrayDescription;
  final List<int> arrayValues;
  final Map<String, int> assignedCharacteristics;
  final Map<String, String?> levelChoiceSelections;
  final Map<String, String?> skillSelections;
  final Map<String, String?> abilitySelections;
  final Map<String, String?> perkSelections;
  final StrifeSubclassDraft? subclass;
  final List<String?> equipmentIds;

  StrifeDraft copyWith({
    int? level,
    Object? classId = _unset,
    Object? arrayDescription = _unset,
    List<int>? arrayValues,
    Map<String, int>? assignedCharacteristics,
    Map<String, String?>? levelChoiceSelections,
    Map<String, String?>? skillSelections,
    Map<String, String?>? abilitySelections,
    Map<String, String?>? perkSelections,
    Object? subclass = _unset,
    List<String?>? equipmentIds,
  }) {
    return StrifeDraft(
      level: level ?? this.level,
      classId: identical(classId, _unset) ? this.classId : classId as String?,
      arrayDescription: identical(arrayDescription, _unset)
          ? this.arrayDescription
          : arrayDescription as String?,
      arrayValues: arrayValues ?? this.arrayValues,
      assignedCharacteristics:
          assignedCharacteristics ?? this.assignedCharacteristics,
      levelChoiceSelections:
          levelChoiceSelections ?? this.levelChoiceSelections,
      skillSelections: skillSelections ?? this.skillSelections,
      abilitySelections: abilitySelections ?? this.abilitySelections,
      perkSelections: perkSelections ?? this.perkSelections,
      subclass: identical(subclass, _unset)
          ? this.subclass
          : subclass as StrifeSubclassDraft?,
      equipmentIds: equipmentIds ?? this.equipmentIds,
    );
  }

  /// Replaces one slot in a slot map without mutating the original.
  StrifeDraft withSlot({
    required String family,
    required String slotKey,
    required String? entryId,
  }) {
    Map<String, String?> updated(Map<String, String?> current) {
      final next = Map<String, String?>.from(current);
      next[slotKey] = entryId;
      return next;
    }

    switch (family) {
      case 'ability':
        return copyWith(abilitySelections: updated(abilitySelections));
      case 'skill':
        return copyWith(skillSelections: updated(skillSelections));
      case 'perk':
        return copyWith(perkSelections: updated(perkSelections));
      default:
        throw ArgumentError.value(family, 'family', 'Unknown strife slot map');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is StrifeDraft &&
        other.level == level &&
        other.classId == classId &&
        other.arrayDescription == arrayDescription &&
        _intListEq.equals(other.arrayValues, arrayValues) &&
        _intMapEq.equals(
            other.assignedCharacteristics, assignedCharacteristics) &&
        _nullableMapEq.equals(
            other.levelChoiceSelections, levelChoiceSelections) &&
        _nullableMapEq.equals(other.skillSelections, skillSelections) &&
        _nullableMapEq.equals(other.abilitySelections, abilitySelections) &&
        _nullableMapEq.equals(other.perkSelections, perkSelections) &&
        other.subclass == subclass &&
        _listEq.equals(other.equipmentIds, equipmentIds);
  }

  @override
  int get hashCode => Object.hash(
        level,
        classId,
        arrayDescription,
        _intListEq.hash(arrayValues),
        _intMapEq.hash(assignedCharacteristics),
        _nullableMapEq.hash(levelChoiceSelections),
        _nullableMapEq.hash(skillSelections),
        _nullableMapEq.hash(abilitySelections),
        _nullableMapEq.hash(perkSelections),
        subclass,
        _listEq.hash(equipmentIds),
      );
}

/// The Strength tab's complete choice state: which options each class feature
/// selected and which skill each skill-group choice picked.
class StrengthDraft {
  StrengthDraft({
    Map<String, Set<String>> featureSelections =
        const <String, Set<String>>{},
    Map<String, Map<String, String>> skillGroupSelections =
        const <String, Map<String, String>>{},
  })  : featureSelections = Map<String, Set<String>>.unmodifiable({
          for (final entry in featureSelections.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        }),
        skillGroupSelections =
            Map<String, Map<String, String>>.unmodifiable({
          for (final entry in skillGroupSelections.entries)
            entry.key: Map<String, String>.unmodifiable(entry.value),
        });

  final Map<String, Set<String>> featureSelections;
  final Map<String, Map<String, String>> skillGroupSelections;

  StrengthDraft copyWith({
    Map<String, Set<String>>? featureSelections,
    Map<String, Map<String, String>>? skillGroupSelections,
  }) {
    return StrengthDraft(
      featureSelections: featureSelections ?? this.featureSelections,
      skillGroupSelections: skillGroupSelections ?? this.skillGroupSelections,
    );
  }

  StrengthDraft withFeatureSelection(String featureId, Set<String> options) {
    final next = {
      for (final entry in featureSelections.entries)
        entry.key: Set<String>.from(entry.value),
    };
    if (options.isEmpty) {
      next.remove(featureId);
    } else {
      next[featureId] = Set<String>.from(options);
    }
    return copyWith(featureSelections: next);
  }

  StrengthDraft withSkillGroupSelection({
    required String featureId,
    required String grantKey,
    required String? skillId,
  }) {
    final next = {
      for (final entry in skillGroupSelections.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    if (skillId == null || skillId.trim().isEmpty) {
      next[featureId]?.remove(grantKey);
      if (next[featureId]?.isEmpty ?? false) next.remove(featureId);
    } else {
      next.putIfAbsent(featureId, () => <String, String>{});
      next[featureId]![grantKey] = skillId.trim();
    }
    return copyWith(skillGroupSelections: next);
  }

  @override
  bool operator ==(Object other) {
    return other is StrengthDraft &&
        _deepEq.equals(other.featureSelections, featureSelections) &&
        _deepEq.equals(other.skillGroupSelections, skillGroupSelections);
  }

  @override
  int get hashCode => Object.hash(
        _deepEq.hash(featureSelections),
        _deepEq.hash(skillGroupSelections),
      );
}

/// The persisted state the builder session was loaded from.
class HeroBuilderBaseline {
  HeroBuilderBaseline({
    required this.revision,
    required this.story,
    required this.strife,
    required this.strength,
    required List<HeroEntryClaim> persistedClaims,
    required this.entriesFingerprint,
    List<String> compatibilityWarnings = const <String>[],
  })  : persistedClaims = List<HeroEntryClaim>.unmodifiable(persistedClaims),
        compatibilityWarnings =
            List<String>.unmodifiable(compatibilityWarnings);

  /// Placeholder used before the first load completes. Revision 0 is reserved
  /// for it, so a real baseline always compares as newer.
  factory HeroBuilderBaseline.empty() => HeroBuilderBaseline(
        revision: 0,
        story: StoryDraft(),
        strife: StrifeDraft(),
        strength: StrengthDraft(),
        persistedClaims: const [],
        entriesFingerprint: '',
      );

  /// Returns a copy with the given fields replaced. The revision is preserved,
  /// so this is not a fresh load — it is used to fold deterministic, load-time
  /// derivations (which the UI recomputes identically every load) into the
  /// baseline so they do not read as unsaved edits.
  HeroBuilderBaseline copyWith({
    StoryDraft? story,
    StrifeDraft? strife,
    StrengthDraft? strength,
  }) {
    return HeroBuilderBaseline(
      revision: revision,
      story: story ?? this.story,
      strife: strife ?? this.strife,
      strength: strength ?? this.strength,
      persistedClaims: persistedClaims,
      entriesFingerprint: entriesFingerprint,
      compatibilityWarnings: compatibilityWarnings,
    );
  }

  /// Monotonic counter bumped every time a fresh baseline is loaded.
  final int revision;
  final StoryDraft story;
  final StrifeDraft strife;
  final StrengthDraft strength;

  /// Every guarded persisted claim, with sources preserved.
  final List<HeroEntryClaim> persistedClaims;

  /// Deterministic digest of the persisted rows the drafts depend on. A
  /// commit compares this against the database to detect external edits.
  final String entriesFingerprint;

  final List<String> compatibilityWarnings;
}

/// Immutable state for one hero-builder session.
class HeroBuilderState {
  HeroBuilderState({
    required this.baseline,
    required this.story,
    required this.strife,
    required this.strength,
    this.draftRevision = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.lastError,
  });

  factory HeroBuilderState.fromBaseline(HeroBuilderBaseline baseline) {
    return HeroBuilderState(
      baseline: baseline,
      story: baseline.story,
      strife: baseline.strife,
      strength: baseline.strength,
    );
  }

  final HeroBuilderBaseline baseline;
  final StoryDraft story;
  final StrifeDraft strife;
  final StrengthDraft strength;

  /// Bumped on every draft command; memoization keys off
  /// `(baseline.revision, draftRevision)`.
  final int draftRevision;
  final bool isLoading;
  final bool isSaving;
  final String? lastError;

  bool get storyDirty => story != baseline.story;
  bool get strifeDirty => strife != baseline.strife;
  bool get strengthDirty => strength != baseline.strength;
  bool get isDirty => storyDirty || strifeDirty || strengthDirty;

  bool sectionDirty(HeroBuilderSection section) {
    switch (section) {
      case HeroBuilderSection.story:
        return storyDirty;
      case HeroBuilderSection.strife:
        return strifeDirty;
      case HeroBuilderSection.strength:
        return strengthDirty;
    }
  }

  HeroBuilderState copyWith({
    HeroBuilderBaseline? baseline,
    StoryDraft? story,
    StrifeDraft? strife,
    StrengthDraft? strength,
    int? draftRevision,
    bool? isLoading,
    bool? isSaving,
    Object? lastError = _unset,
  }) {
    return HeroBuilderState(
      baseline: baseline ?? this.baseline,
      story: story ?? this.story,
      strife: strife ?? this.strife,
      strength: strength ?? this.strength,
      draftRevision: draftRevision ?? this.draftRevision,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      lastError:
          identical(lastError, _unset) ? this.lastError : lastError as String?,
    );
  }
}
