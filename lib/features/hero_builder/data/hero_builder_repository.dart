import '../../../core/db/app_database.dart' as db;
import '../../../core/repositories/hero_entry_repository.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/class_feature_data_service.dart';
import '../../../core/services/class_feature_grants_service.dart';
import '../../../core/services/complication_grants_service.dart';
import '../../../core/services/hero_duplicate_guard_service.dart';
import '../../../core/storage/hero_storage_contract.dart';
import '../domain/hero_claim.dart';
import '../domain/hero_draft.dart';

/// Loads one immutable baseline for a hero-builder session.
///
/// The abstraction exists so the controller can be tested without a database.
abstract class HeroBuilderRepository {
  Future<HeroBuilderBaseline> loadBaseline(String heroId);

  /// Digest of the hero's current persisted entries. A commit compares this
  /// with the baseline's digest to detect edits made outside the builder.
  Future<String> entriesFingerprint(String heroId);
}

class DriftHeroBuilderRepository implements HeroBuilderRepository {
  DriftHeroBuilderRepository(this._db)
      : _heroes = HeroRepository(_db),
        _entries = HeroEntryRepository(_db),
        _classFeatureGrants = ClassFeatureGrantsService(_db),
        _complicationGrants = ComplicationGrantsService(_db);

  final db.AppDatabase _db;
  final HeroRepository _heroes;
  final HeroEntryRepository _entries;
  final ClassFeatureGrantsService _classFeatureGrants;
  final ComplicationGrantsService _complicationGrants;

  int _revisionCounter = 0;

  @override
  Future<HeroBuilderBaseline> loadBaseline(String heroId) async {
    final hero = await _heroes.load(heroId);
    if (hero == null) {
      throw StateError('Hero $heroId not found');
    }

    final entryRows = await _entries.listAllEntriesForHero(heroId);

    final story = await _loadStoryDraft(
      heroId,
      name: hero.name,
      ancestryId: hero.ancestry,
    );
    final strife = await _loadStrifeDraft(
      heroId: heroId,
      level: hero.level,
      classId: hero.className?.trim(),
      subclassName: hero.subclass?.trim(),
      deityId: hero.deityId?.trim(),
      domainField: hero.domain,
      entryRows: entryRows,
    );
    final strength = await _loadStrengthDraft(heroId);

    return HeroBuilderBaseline(
      revision: ++_revisionCounter,
      story: story,
      strife: strife,
      strength: strength,
      persistedClaims: _toPersistedClaims(entryRows),
      entriesFingerprint: _fingerprint(entryRows),
    );
  }

  @override
  Future<String> entriesFingerprint(String heroId) async {
    return _fingerprint(await _entries.listAllEntriesForHero(heroId));
  }

  Future<StoryDraft> _loadStoryDraft(
    String heroId, {
    required String name,
    required String? ancestryId,
  }) async {
    final culture = await _heroes.loadCultureSelection(heroId);
    final career = await _heroes.loadCareerSelection(heroId);
    final traitIds = await _heroes.getSelectedAncestryTraits(heroId);
    final traitChoices = await _heroes.getAncestryTraitChoices(heroId);
    final complicationId = await _heroes.loadComplication(heroId);
    final complicationChoices =
        await _complicationGrants.loadComplicationChoices(heroId);

    return StoryDraft(
      name: name,
      ancestryId: ancestryId,
      ancestryTraitIds: traitIds.toSet(),
      ancestryTraitChoices: traitChoices,
      environmentId: culture.environmentId,
      organisationId: culture.organisationId,
      upbringingId: culture.upbringingId,
      environmentSkillId: culture.environmentSkillId,
      organisationSkillId: culture.organisationSkillId,
      upbringingSkillId: culture.upbringingSkillId,
      cultureLanguageId: culture.languageId,
      careerId: career.careerId,
      careerLanguageIds: career.chosenLanguageIds,
      careerSkillIds: career.chosenSkillIds.toSet(),
      careerPerkIds: career.chosenPerkIds.toSet(),
      careerIncidentName: career.incitingIncidentName,
      complicationId: complicationId,
      complicationChoices: complicationChoices,
    );
  }

  Future<StrifeDraft> _loadStrifeDraft({
    required String heroId,
    required int level,
    required String? classId,
    required String? subclassName,
    required String? deityId,
    required String? domainField,
    required List<db.HeroEntry> entryRows,
  }) async {
    final arrayConfig = await _db.getHeroConfigValue(
      heroId,
      HeroConfigKeys.strifeCharacteristicArray,
    );
    final arrayValues = await _heroes.getCharacteristicArrayValues(heroId);
    final assignments = await _heroes.getCharacteristicAssignments(heroId);
    final levelChoices = await _heroes.getLevelChoiceSelections(heroId);
    final equipmentIds = await _heroes.getEquipmentIds(heroId);

    final domainNames = (domainField ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    StrifeSubclassDraft? subclass;
    final hasSubclassData = (subclassName?.isNotEmpty ?? false) ||
        (deityId?.isNotEmpty ?? false) ||
        domainNames.isNotEmpty;
    if (hasSubclassData) {
      final savedKey = await _heroes.getSubclassKey(heroId);
      final subclassSkillRow = entryRows
          .where(
            (row) =>
                row.entryType == HeroEntryTypes.skill &&
                row.sourceType == HeroEntrySourceTypes.subclass &&
                row.sourceId == HeroEntrySourceIds.subclassSkill,
          )
          .toList();
      subclass = StrifeSubclassDraft(
        subclassKey: savedKey ??
            (subclassName == null || subclassName.isEmpty
                ? null
                : ClassFeatureDataService.slugify(subclassName)),
        subclassName: subclassName,
        skillId:
            subclassSkillRow.isEmpty ? null : subclassSkillRow.first.entryId,
        deityId: deityId == null || deityId.isEmpty ? null : deityId,
        domainNames: domainNames,
      );
    }

    return StrifeDraft(
      level: level,
      classId: classId == null || classId.isEmpty ? null : classId,
      arrayDescription: arrayConfig?['name']?.toString(),
      arrayValues: arrayValues,
      assignedCharacteristics: assignments,
      levelChoiceSelections: levelChoices,
      skillSelections: await _loadSelectionMap(
        heroId,
        HeroConfigKeys.strifeSkillSelections,
      ),
      abilitySelections: await _loadSelectionMap(
        heroId,
        HeroConfigKeys.strifeAbilitySelections,
      ),
      perkSelections: await _loadSelectionMap(
        heroId,
        HeroConfigKeys.strifePerkSelections,
      ),
      subclass: subclass,
      equipmentIds: equipmentIds,
    );
  }

  Future<StrengthDraft> _loadStrengthDraft(String heroId) async {
    return StrengthDraft(
      featureSelections: await _heroes.getFeatureSelections(heroId),
      skillGroupSelections:
          await _classFeatureGrants.loadSkillGroupSelections(heroId),
    );
  }

  Future<Map<String, String?>> _loadSelectionMap(
    String heroId,
    String configKey,
  ) async {
    final config = await _db.getHeroConfigValue(heroId, configKey);
    if (config == null) return const <String, String?>{};
    return config.map(
      (key, value) => MapEntry(key.toString(), value?.toString()),
    );
  }

  static List<HeroEntryClaim> _toPersistedClaims(
    Iterable<db.HeroEntry> entryRows,
  ) {
    const guard = HeroDuplicateGuardService();
    return [
      for (final row in entryRows)
        if (guard.guardsEntryType(row.entryType))
          HeroEntryClaim(
            key: HeroEntryKey(
              entryType: row.entryType,
              canonicalEntryId: row.entryId,
            ),
            owner: HeroClaimOwner.persisted(
              source: HeroClaimSource(
                sourceType: row.sourceType,
                sourceId: row.sourceId,
              ),
              // Matches the label the creator pages built by hand, so conflict
              // messages read the same after they migrate.
              displayLabel: row.sourceId.trim().isEmpty
                  ? row.sourceType
                  : '${row.sourceType}:${row.sourceId}',
            ),
          ),
    ];
  }

  /// FNV-1a over the sorted row tuples; stable across processes so it can be
  /// persisted later if a durable revision becomes necessary.
  static String _fingerprint(Iterable<db.HeroEntry> entryRows) {
    final lines = entryRows
        .map(
          (row) =>
              '${row.entryType}|${row.entryId}|${row.sourceType}|${row.sourceId}|${row.gainedBy}',
        )
        .toList()
      ..sort();

    var hash = 0xcbf29ce484222325;
    for (final line in lines) {
      for (final unit in line.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
      }
      hash ^= 0x0a;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return '${lines.length}:${hash.toRadixString(16)}';
  }
}
