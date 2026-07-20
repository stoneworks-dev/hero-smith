import '../db/app_database.dart';
import '../models/hero_mutation_model.dart';
import '../models/stat_modification_model.dart';
import '../repositories/hero_entry_repository.dart';
import '../storage/hero_storage_contract.dart';
import 'damage_resistance_service.dart';
import 'hero_config_service.dart';

class HeroMutationService {
  HeroMutationService(AppDatabase db)
      : _db = db,
        _entries = HeroEntryRepository(db),
        _config = HeroConfigService(db),
        _resistances = DamageResistanceService(db);

  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final HeroConfigService _config;
  final DamageResistanceService _resistances;

  Future<void> addContentEntry({
    required String heroId,
    required HeroSource source,
    required ResolvedGrant grant,
  }) async {
    _validateSource(source);
    _validateGrant(grant);

    final gainedBy = grant.gainedBy ?? source.gainedBy;
    _validateGainedBy(gainedBy);

    await _entries.addEntry(
      heroId: heroId,
      entryType: grant.entryType,
      entryId: grant.entryId,
      sourceType: source.sourceType,
      sourceId: source.sourceId,
      gainedBy: gainedBy,
      payload: grant.payload,
    );
  }

  Future<void> addContentEntries({
    required String heroId,
    required HeroSource source,
    required Iterable<ResolvedGrant> grants,
  }) async {
    await _db.transaction(() async {
      for (final grant in grants) {
        await addContentEntry(
          heroId: heroId,
          source: source,
          grant: grant,
        );
      }
    });
  }

  Future<void> replaceContentEntries({
    required String heroId,
    required HeroSource source,
    required String entryType,
    required Iterable<String> entryIds,
    String? gainedBy,
  }) async {
    _validateSource(source);
    _validateEntryType(entryType);

    final resolvedGainedBy = gainedBy ?? source.gainedBy;
    _validateGainedBy(resolvedGainedBy);

    final normalizedIds = entryIds
        .map((entryId) => entryId.trim())
        .where((entryId) => entryId.isNotEmpty)
        .toList();

    await _db.transaction(() async {
      await _entries.removeEntriesFromSource(
        heroId: heroId,
        sourceType: source.sourceType,
        sourceId: source.sourceId,
        entryType: entryType,
      );

      for (final entryId in normalizedIds) {
        await addContentEntry(
          heroId: heroId,
          source: source,
          grant: ResolvedGrant(
            entryType: entryType,
            entryId: entryId,
            gainedBy: resolvedGainedBy,
          ),
        );
      }
    });
  }

  Future<void> addStatMod({
    required String heroId,
    required HeroSource source,
    required String stat,
    required Iterable<StatModification> modifications,
    String? entryId,
  }) async {
    final normalizedStat = stat.trim().toLowerCase();
    final modList = modifications.toList();
    if (normalizedStat.isEmpty || modList.isEmpty) return;

    await addContentEntry(
      heroId: heroId,
      source: source,
      grant: ResolvedGrant.statMod(
        stat: normalizedStat,
        entryId: entryId,
        modifications: modList,
      ),
    );
  }

  Future<void> addStatMods({
    required String heroId,
    required HeroSource source,
    required Map<String, List<StatModification>> modificationsByStat,
  }) async {
    for (final entry in modificationsByStat.entries) {
      await addStatMod(
        heroId: heroId,
        source: source,
        stat: entry.key,
        modifications: entry.value,
      );
    }
  }

  Future<void> addResistance({
    required String heroId,
    required HeroSource source,
    required String damageType,
    int immunity = 0,
    int weakness = 0,
    String? dynamicImmunity,
    String? dynamicWeakness,
    int immunityPerEchelon = 0,
    int weaknessPerEchelon = 0,
    bool recompute = true,
  }) async {
    _validateSource(source);

    final normalizedDamageType = damageType.trim().toLowerCase();
    if (normalizedDamageType.isEmpty ||
        !_hasResistanceGrant(
          immunity: immunity,
          weakness: weakness,
          dynamicImmunity: dynamicImmunity,
          dynamicWeakness: dynamicWeakness,
          immunityPerEchelon: immunityPerEchelon,
          weaknessPerEchelon: weaknessPerEchelon,
        )) {
      return;
    }

    await _resistances.addResistanceEntry(
      heroId: heroId,
      damageType: normalizedDamageType,
      sourceType: source.sourceType,
      sourceId: source.sourceId,
      immunity: immunity,
      weakness: weakness,
      dynamicImmunity: dynamicImmunity,
      dynamicWeakness: dynamicWeakness,
      immunityPerEchelon: immunityPerEchelon,
      weaknessPerEchelon: weaknessPerEchelon,
    );

    if (recompute) {
      await recomputeAggregates(heroId);
    }
  }

  Future<void> saveConfigChoice({
    required String heroId,
    required String key,
    required Map<String, dynamic> value,
    String? metadata,
  }) async {
    _validateConfigKey(key);
    await _config.setConfigValue(
      heroId: heroId,
      key: key,
      value: value,
      metadata: metadata,
    );
  }

  Future<void> removeConfigChoice({
    required String heroId,
    required String key,
  }) async {
    _validateConfigKey(key);
    await _config.removeConfigKey(heroId, key);
  }

  Future<int> removeSource({
    required String heroId,
    required HeroSource source,
    String? entryType,
    bool recomputeAggregates = true,
  }) async {
    _validateSource(source);
    if (entryType != null) {
      _validateEntryType(entryType);
    }

    final removed = await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: source.sourceType,
      sourceId: source.sourceId,
      entryType: entryType,
    );

    if (recomputeAggregates) {
      await this.recomputeAggregates(heroId);
    }

    return removed;
  }

  Future<int> removeSourceType({
    required String heroId,
    required String sourceType,
    String? entryType,
    bool recomputeAggregates = true,
  }) async {
    _validateSourceType(sourceType);
    if (entryType != null) {
      _validateEntryType(entryType);
    }

    final removed = await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: sourceType,
      entryType: entryType,
    );

    if (recomputeAggregates) {
      await this.recomputeAggregates(heroId);
    }

    return removed;
  }

  Future<int> removeEntryById({
    required String heroId,
    required String entryType,
    required String entryId,
    bool recomputeAggregates = true,
  }) async {
    _validateEntryType(entryType);
    if (entryId.trim().isEmpty) {
      throw ArgumentError.value(entryId, 'entryId', 'Entry ID is empty');
    }

    final removed = await _entries.removeEntryById(
      heroId,
      entryType,
      entryId,
    );

    if (recomputeAggregates) {
      await this.recomputeAggregates(heroId);
    }

    return removed;
  }

  Future<void> recomputeAggregates(String heroId) {
    return _resistances.recomputeAggregateResistances(heroId);
  }

  bool _hasResistanceGrant({
    required int immunity,
    required int weakness,
    required String? dynamicImmunity,
    required String? dynamicWeakness,
    required int immunityPerEchelon,
    required int weaknessPerEchelon,
  }) {
    return immunity != 0 ||
        weakness != 0 ||
        dynamicImmunity != null ||
        dynamicWeakness != null ||
        immunityPerEchelon != 0 ||
        weaknessPerEchelon != 0;
  }

  void _validateGrant(ResolvedGrant grant) {
    _validateEntryType(grant.entryType);
    if (grant.entryId.trim().isEmpty) {
      throw ArgumentError.value(grant.entryId, 'entryId', 'Entry ID is empty');
    }
    if (grant.gainedBy != null) {
      _validateGainedBy(grant.gainedBy!);
    }
  }

  void _validateSource(HeroSource source) {
    _validateSourceType(source.sourceType);
    _validateGainedBy(source.gainedBy);
  }

  void _validateEntryType(String entryType) {
    if (!HeroEntryTypes.isValid(entryType)) {
      throw ArgumentError.value(
        entryType,
        'entryType',
        'Unknown hero entry type',
      );
    }
  }

  void _validateSourceType(String sourceType) {
    if (!HeroEntrySourceTypes.isValid(sourceType)) {
      throw ArgumentError.value(
        sourceType,
        'sourceType',
        'Unknown hero entry source type',
      );
    }
  }

  void _validateGainedBy(String gainedBy) {
    if (!HeroEntryGainedBy.isValid(gainedBy)) {
      throw ArgumentError.value(
        gainedBy,
        'gainedBy',
        'Unknown hero entry gainedBy value',
      );
    }
  }

  void _validateConfigKey(String key) {
    if (HeroConfigKeys.isBanned(key) || !HeroConfigKeys.isKnown(key)) {
      throw ArgumentError.value(
        key,
        'key',
        'Unknown or banned hero config key',
      );
    }
  }
}
