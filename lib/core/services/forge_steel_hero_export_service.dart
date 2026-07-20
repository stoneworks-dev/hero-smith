import 'dart:convert';

import '../db/app_database.dart' as db;
import '../models/hero_assembled_model.dart';
import '../storage/hero_storage_contract.dart';
import 'forge_steel_hero_export.dart';
import 'forge_steel_export_validator.dart';
import 'hero_assembly_service.dart';
import 'hero_entry_normalizer.dart';
import 'hero_export_models.dart';
import 'hero_export_policy.dart';

class ForgeSteelHeroExportService {
  ForgeSteelHeroExportService(this._db)
      : _assemblyService = HeroAssemblyService(_db),
        _normalizer = HeroEntryNormalizer(_db);

  final db.AppDatabase _db;
  final HeroAssemblyService _assemblyService;
  final HeroEntryNormalizer _normalizer;

  Future<ForgeSteelHeroExport> buildExport(String heroId) async =>
      (await _buildExport(heroId)).export;

  /// Builds Codex JSON and a separate report. The report is not embedded in
  /// the JSON because Codex expects the hero object at the document root.
  Future<ExportArtifact> buildArtifact(String heroId) async {
    final build = await _buildExport(heroId);
    final content = build.export.toPrettyJson();
    final baseReport = _buildReport(build.assembly);
    return ExportArtifact(
      content: content,
      suggestedExtension: 'ds-hero',
      report: ExportReport(
        target: baseReport.target,
        heroId: baseReport.heroId,
        formatVersion: baseReport.formatVersion,
        importerRevision: baseReport.importerRevision,
        coverage: baseReport.coverage,
        issues: [
          ...baseReport.issues,
          ...ForgeSteelExportValidator.validate(build.export),
        ],
      ),
    );
  }

  Future<_ForgeExportBuild> _buildExport(String heroId) async {
    late _ForgeExportBuild build;
    try {
      await _db.transaction(() async {
        // See HeroExportService: the mapper may need normalized legacy rows,
        // but export itself must not write repairs to the hero.
        await _normalizer.normalize(heroId);

        final assembly = await _assemblyService.assemble(heroId);
        if (assembly == null) {
          throw ArgumentError('Hero not found: $heroId');
        }

        final components = await _db.getAllComponents();
        build = _ForgeExportBuild(
          export: _ForgeSteelHeroMapper(_ComponentResolver(components))
              .map(assembly),
          assembly: assembly,
        );
        throw const _ReadOnlyForgeExportComplete();
      });
    } on _ReadOnlyForgeExportComplete {
      return build;
    }
    throw StateError('Codex export completed without an artifact.');
  }

  ExportReport _buildReport(HeroAssembly assembly) {
    final coverage = <ExportSectionCoverage>[
      const ExportSectionCoverage(
        section: 'hero',
        inputCount: 1,
        emittedCount: 1,
      ),
    ];
    final issues = <ExportIssue>[];
    final entryTypes = assembly.entriesByType.keys.toList()..sort();

    for (final entryType in entryTypes) {
      final entries = assembly.entriesByType[entryType]!;
      final policy = HeroExportPolicyRegistry.forEntryType(entryType);
      if (policy == null) {
        coverage.add(ExportSectionCoverage(
          section: 'entries.$entryType',
          inputCount: entries.length,
          emittedCount: 0,
          unresolvedCount: entries.length,
        ));
        for (final entry in entries) {
          issues.add(_entryIssue(
            entry,
            code: 'component.unresolved',
            severity: ExportIssueSeverity.error,
            message: 'No Codex export policy exists for "$entryType".',
          ));
        }
        continue;
      }

      final support = policy.codex;
      coverage.add(ExportSectionCoverage(
        section: 'entries.$entryType',
        inputCount: entries.length,
        emittedCount: support == ExportTargetSupport.supported
            ? entries.length
            : 0,
        unsupportedCount: support == ExportTargetSupport.unsupported
            ? entries.length
            : 0,
        unresolvedCount:
            support == ExportTargetSupport.partial ? entries.length : 0,
      ));

      if (support == ExportTargetSupport.supported) continue;
      for (final entry in entries) {
        issues.add(_entryIssue(
          entry,
          code: support == ExportTargetSupport.unsupported
              ? 'codex.field_unsupported'
              : 'codex.mapping_partial',
          severity: ExportIssueSeverity.warning,
          message: support == ExportTargetSupport.unsupported
              ? '$entryType is preserved in native backup but is ignored by Codex.'
              : '$entryType needs provenance-aware Codex mapping before it can '
                  'be verified as exported.',
        ));
      }
    }

    return ExportReport(
      target: HeroExportTarget.codexForge,
      heroId: assembly.heroId,
      formatVersion: 1,
      coverage: coverage,
      issues: issues,
    );
  }

  ExportIssue _entryIssue(
    db.HeroEntry entry, {
    required String code,
    required ExportIssueSeverity severity,
    required String message,
  }) =>
      ExportIssue(
        code: code,
        severity: severity,
        origin: ExportIssueOrigin.heroSmith,
        fieldPath: 'entries.${entry.entryType}.${entry.entryId}',
        message: message,
        entryType: entry.entryType,
        entryId: entry.entryId,
        sourceType: entry.sourceType,
        sourceId: entry.sourceId,
      );

  Future<String> exportHeroToJson(String heroId) async {
    return (await buildArtifact(heroId)).content;
  }
}

class _ReadOnlyForgeExportComplete implements Exception {
  const _ReadOnlyForgeExportComplete();
}

class _ForgeExportBuild {
  const _ForgeExportBuild({required this.export, required this.assembly});

  final ForgeSteelHeroExport export;
  final HeroAssembly assembly;
}

/// Maps this app's display names to the names Forge Steel/Codex expects, so the
/// name-driven importer can resolve them. Only same-element corrections live
/// here (punctuation, spacing, British spelling, the canonical Forge Steel
/// spelling) — never a mapping to a semantically different element.
///
/// Generated from an audit of the app's components against Forge Steel's data;
/// extend it when the audit surfaces new divergences. Keys are matched on the
/// exact (trimmed) name.
const Map<String, String> forgeNameAliases = {
  // Ancestries (Forge Steel spelling; the importer translates to Codex)
  'High Elf': 'Elf (high)',
  'Wode Elf': 'Elf (wode)',
  // Complications
  'Self-Taught': 'Self Taught',
  // Titles
  'Dwarven Legionnaire': 'Dwarf Legionnaire',
  // Languages (spelling)
  'Filiaric': 'Filliaric',
  'Illyric': 'Illyvric',
  'Phaedric': 'Phaedran',
  'Urollaic': 'Urollialic',
  // Perks (British spelling)
  'Traveling Artisan': 'Travelling Artisan',
  'Traveling Sage': 'Travelling Sage',
  // Abilities (punctuation / spacing / canonical Forge Steel spelling)
  'Behold a Shield of Faith!': 'Behold, a Shield of Faith!',
  'Back Blasphemer!': 'Back, Blasphemer!',
  'Begone!': 'Begone',
  'The Gods Command You Obey': 'The Gods Command, You Obey',
  'Ray of Agonizing Self-Reflection': 'Ray of Agonizing Self Reflection',
  'Earth Accepts Me': 'The Earth Accepts Me',
  'Meteoric Introduction': 'A Meteoric Introduction',
  'Corrupt Spirit': 'Corrupted Spirit',
  'Stasis Field': 'Statis Field',
  'Every Step... Death!': 'Every Step ... Death!',
};

/// Applies [forgeNameAliases] to a resolved display name.
String aliasForgeName(String name) => forgeNameAliases[name.trim()] ?? name;

class _ForgeSteelHeroMapper {
  const _ForgeSteelHeroMapper(this._resolver);

  final _ComponentResolver _resolver;

  ForgeSteelHeroExport map(HeroAssembly assembly) {
    final className = _resolver.nameForId(assembly.classId);
    if (className == null) {
      throw StateError('Codex export requires a selected class.');
    }

    final ancestryName = _resolver.nameForId(assembly.ancestryId);
    final careerName = _resolver.nameForId(assembly.careerId);
    final complicationEntry = _firstEntry(
      assembly.getEntriesByType(HeroEntryTypes.complication),
    );
    final languageNames = _storyLanguageNames(assembly);

    final ancestryFeatures = _ancestryFeatures(assembly);

    final abilityExports = _abilityExports(assembly);
    final levelOneFeatures = _levelOneFeatures(
      assembly: assembly,
      selectedAbilityEntries: _classAbilityEntries(assembly),
    );
    final primaryCharacteristics = _primaryCharacteristicNames(assembly);

    return ForgeSteelHeroExport(
      name: assembly.name,
      ancestry: ancestryName == null
          ? null
          : ForgeAncestryExport(
              id: _codexId(assembly.ancestryId),
              name: ancestryName,
              description: _resolver.descriptionForId(assembly.ancestryId),
              features: ancestryFeatures,
            ),
      culture: _cultureExport(assembly, languageNames.culture),
      career: careerName == null
          ? null
          : ForgeCareerExport(
              id: _codexId(assembly.careerId),
              name: careerName,
              description: _resolver.descriptionForId(assembly.careerId),
              features: _careerFeatures(assembly, languageNames.career),
              incitingIncident: _incitingIncident(assembly),
            ),
      heroClass: ForgeClassExport(
        id: _codexId(assembly.classId),
        name: className,
        description: _resolver.descriptionForId(assembly.classId),
        type: 'standard',
        primaryCharacteristicsOptions: primaryCharacteristics.isEmpty
            ? const []
            : [primaryCharacteristics],
        primaryCharacteristics: primaryCharacteristics,
        level: assembly.level <= 0 ? 1 : assembly.level,
        characteristics: _characteristics(assembly),
        characteristicArray: _characteristicArray(assembly),
        abilities: abilityExports,
        featuresByLevel: [
          ForgeLevelFeaturesExport(level: 1, features: levelOneFeatures),
        ],
        subclasses: _subclasses(assembly),
      ),
      complication: complicationEntry == null
          ? null
          : ForgeNamedRef(
              id: _codexId(complicationEntry.entryId),
              name: _resolver.nameForEntry(complicationEntry)!,
              description: _resolver.descriptionForEntry(complicationEntry),
            ),
    );
  }

  List<ForgeFeatureExport> _ancestryFeatures(HeroAssembly assembly) {
    final features = <ForgeFeatureExport>[];
    final signature = _ancestrySignatureSelection(assembly);
    final ancestryTraits = _namedSelectionsForEntries(
      _ancestryTraitEntries(assembly),
    );
    final ancestrySelections = <ForgeNamedSelection>[
      if (signature != null) signature,
      ...ancestryTraits,
    ];
    if (ancestrySelections.isNotEmpty) {
      features.add(
        ForgeFeatureExport.choice(
          ancestrySelections,
          id: _featureId('ancestry-traits'),
          name: 'Ancestry Traits',
        ),
      );
    }

    // Skills granted by an ancestry trait (e.g. Devil's Silver Tongue) are
    // recorded in config under `ancestry.trait_choices`, not as ancestry-sourced
    // skill entries. Merge both so the importer's race-fill skill choice can
    // resolve them; otherwise the skill is silently dropped on import.
    final ancestrySkills = _dedupNames([
      ..._ancestryTraitChoiceSkillNames(assembly),
      ..._namesForEntries(_ancestrySkillEntries(assembly)),
    ]);
    if (ancestrySkills.isNotEmpty) {
      features.add(
        ForgeFeatureExport.skillChoice(
          ancestrySkills,
          id: _featureId('ancestry-skill-choice'),
          name:
              signature == null ? 'Ancestry Skill' : '${signature.name} Skill',
        ),
      );
    }

    return features;
  }

  /// Resolves skill names chosen for ancestry traits from
  /// `ancestry.trait_choices` config (keys containing "skill"), e.g.
  /// `{"signature_skill": "skill_brag"}` -> `["Brag"]`.
  List<String> _ancestryTraitChoiceSkillNames(HeroAssembly assembly) {
    final dynamic raw = assembly.config[HeroConfigKeys.ancestryTraitChoices];
    if (raw is! Map) return const [];
    final Map choices = raw;
    final names = <String>[];
    for (final entry in choices.entries) {
      if (!entry.key.toString().toLowerCase().contains('skill')) continue;
      final id = entry.value?.toString().trim();
      if (id == null || id.isEmpty) continue;
      final name = _resolver.nameForId(id);
      if (name != null && name.isNotEmpty) names.add(name);
    }
    return names;
  }

  List<String> _dedupNames(Iterable<String> names) {
    final seen = <String>{};
    final result = <String>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
    }
    return result;
  }

  ForgeNamedSelection? _ancestrySignatureSelection(HeroAssembly assembly) {
    final rawName =
        assembly.config[HeroConfigKeys.ancestrySignatureName]?['name'];
    final name = rawName?.toString().trim() ??
        _resolver.signatureNameForAncestry(assembly.ancestryId);
    if (name == null || name.isEmpty) return null;

    final data = _resolver.signatureDataForAncestry(assembly.ancestryId, name);
    final description = data['description']?.toString().trim() ?? '';
    return ForgeNamedSelection(
      id: _featureId('ancestry-${name.toLowerCase()}'),
      name: name,
      description: description,
    );
  }

  ForgeCultureExport? _cultureExport(
    HeroAssembly assembly,
    List<String> languageNames,
  ) {
    final environmentEntry = _firstEntry(
      assembly.getEntriesByType(HeroEntryTypes.cultureEnvironment),
    );
    final organizationEntry = _firstEntry(
      assembly.getEntriesByType(HeroEntryTypes.cultureOrganisation),
    );
    final upbringingEntry = _firstEntry(
      assembly.getEntriesByType(HeroEntryTypes.cultureUpbringing),
    );

    if (languageNames.isEmpty &&
        environmentEntry == null &&
        organizationEntry == null &&
        upbringingEntry == null) {
      return null;
    }

    return ForgeCultureExport(
      id: _featureId('culture-bespoke-culture'),
      name: 'Bespoke Culture',
      type: 'Bespoke',
      languages: languageNames,
      language: languageNames.isEmpty
          ? null
          : ForgeFeatureExport.languageChoice(
              languageNames,
              id: _featureId('culture-language'),
              name: 'Language',
              count: languageNames.length,
            ),
      environment: environmentEntry == null
          ? null
          : ForgeCultureAspectExport(
              id: _codexId(environmentEntry.entryId),
              name: _resolver.nameForEntry(environmentEntry)!,
              description: _resolver.descriptionForEntry(environmentEntry),
              listOptions: _skillGroupOptions(environmentEntry.entryId),
              selected: _cultureAspectSkillNames(
                assembly,
                HeroEntryTypes.cultureEnvironment,
              ),
            ),
      organization: organizationEntry == null
          ? null
          : ForgeCultureAspectExport(
              id: _codexId(organizationEntry.entryId),
              name: _resolver.nameForEntry(organizationEntry)!,
              description: _resolver.descriptionForEntry(organizationEntry),
              listOptions: _skillGroupOptions(organizationEntry.entryId),
              selected: _cultureAspectSkillNames(
                assembly,
                HeroEntryTypes.cultureOrganisation,
              ),
            ),
      upbringing: upbringingEntry == null
          ? null
          : ForgeCultureAspectExport(
              id: _codexId(upbringingEntry.entryId),
              name: _resolver.nameForEntry(upbringingEntry)!,
              description: _resolver.descriptionForEntry(upbringingEntry),
              listOptions: _skillGroupOptions(upbringingEntry.entryId),
              selected: _cultureAspectSkillNames(
                assembly,
                HeroEntryTypes.cultureUpbringing,
              ),
            ),
    );
  }

  _StoryLanguageNames _storyLanguageNames(HeroAssembly assembly) {
    final explicitCultureLanguages = _namesForEntries(
      _cultureLanguageEntries(assembly).where((entry) {
        return entry.sourceId != 'culture_languages';
      }).toList(growable: false),
    );
    final cultureLanguages =
        _namesForEntries(_cultureLanguageEntries(assembly));
    final explicitCareerLanguages =
        _namesForEntries(_careerLanguageEntries(assembly));

    if (explicitCultureLanguages.isNotEmpty) {
      return _StoryLanguageNames(
        culture: explicitCultureLanguages,
        career: explicitCareerLanguages,
      );
    }

    final combinedLanguages = cultureLanguages.isNotEmpty
        ? cultureLanguages
        : _namesForEntries(_choiceEntries(assembly.languages));

    if (combinedLanguages.isEmpty) {
      return _StoryLanguageNames(
        culture: const [],
        career: explicitCareerLanguages,
      );
    }

    if (explicitCareerLanguages.isNotEmpty) {
      final careerLookup =
          explicitCareerLanguages.map((name) => name.toLowerCase()).toSet();
      return _StoryLanguageNames(
        culture: combinedLanguages
            .where((name) => !careerLookup.contains(name.toLowerCase()))
            .toList(growable: false),
        career: explicitCareerLanguages,
      );
    }

    final careerLanguageCount = _careerLanguageCount(assembly);
    if (careerLanguageCount <= 0) {
      return _StoryLanguageNames(culture: combinedLanguages, career: const []);
    }

    final splitIndex = combinedLanguages.length - careerLanguageCount;
    if (splitIndex <= 0) {
      return _StoryLanguageNames(culture: const [], career: combinedLanguages);
    }

    return _StoryLanguageNames(
      culture: combinedLanguages.take(splitIndex).toList(growable: false),
      career: combinedLanguages.skip(splitIndex).toList(growable: false),
    );
  }

  List<db.HeroEntry> _cultureLanguageEntries(HeroAssembly assembly) {
    return assembly.languages.where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.culture;
    }).toList(growable: false);
  }

  List<db.HeroEntry> _careerLanguageEntries(HeroAssembly assembly) {
    final careerId = assembly.careerId;
    return _careerEntries(
      assembly,
      entryType: HeroEntryTypes.language,
      careerId: careerId,
    );
  }

  int _careerLanguageCount(HeroAssembly assembly) {
    final rawValue = _resolver.dataForId(assembly.careerId)['languages'];
    if (rawValue is num) return rawValue.toInt();
    return int.tryParse(rawValue?.toString() ?? '') ?? 0;
  }

  List<String> _cultureAspectSkillNames(
    HeroAssembly assembly,
    String sourceId,
  ) {
    return _namesForEntries(
      _entriesFromSource(
        assembly,
        HeroEntrySourceTypes.culture,
        sourceId,
        entryType: HeroEntryTypes.skill,
      ),
    );
  }

  List<ForgeFeatureExport> _careerFeatures(
    HeroAssembly assembly,
    List<String> careerLanguageNames,
  ) {
    final features = <ForgeFeatureExport>[];
    final careerId = assembly.careerId;
    final careerData = _resolver.dataForId(careerId);
    final careerIdForFeature = _codexId(careerId) ?? 'career';

    final careerSkills = _careerEntries(
      assembly,
      entryType: HeroEntryTypes.skill,
      careerId: careerId,
    );
    final skillNames = _namesForEntries(careerSkills);
    if (skillNames.isNotEmpty) {
      features.add(
        ForgeFeatureExport.skillChoice(
          skillNames,
          id: '$careerIdForFeature-skill-choice',
          name: 'Skills',
          listOptions: _stringList(careerData['skill_groups'])
              .map(_titleCaseWords)
              .toList(growable: false),
          count: skillNames.length,
        ),
      );
    }

    final careerPerks = _careerEntries(
      assembly,
      entryType: HeroEntryTypes.perk,
      careerId: careerId,
    );
    final perkSelections = _namedSelectionsForEntries(careerPerks);
    if (perkSelections.isNotEmpty) {
      features.add(
        ForgeFeatureExport.perk(
          perkSelections,
          id: '$careerIdForFeature-perk-choice',
          name: 'Perk',
          lists: _careerPerkLists(careerData),
          count: perkSelections.length,
        ),
      );
    }

    if (careerLanguageNames.isNotEmpty) {
      features.add(
        ForgeFeatureExport.languageChoice(
          careerLanguageNames,
          id: '$careerIdForFeature-language-choice',
          name: 'Languages',
          count: _careerLanguageCount(assembly) == 0
              ? careerLanguageNames.length
              : _careerLanguageCount(assembly),
        ),
      );
    }

    void addBonus(String dataKey, String field) {
      final rawValue = careerData[dataKey];
      final value = rawValue is num
          ? rawValue.toInt()
          : int.tryParse(rawValue?.toString() ?? '') ?? 0;
      if (value != 0) {
        features.add(
          ForgeFeatureExport.bonus(
            field: field,
            value: value,
            id: '$careerIdForFeature-${dataKey.replaceAll('_', '-')}',
          ),
        );
      }
    }

    addBonus('renown', 'Renown');
    addBonus('wealth', 'Wealth');
    addBonus('project_points', 'Project Points');

    return features;
  }

  List<ForgeFeatureExport> _levelOneFeatures({
    required HeroAssembly assembly,
    required List<db.HeroEntry> selectedAbilityEntries,
  }) {
    final features = <ForgeFeatureExport>[];

    final kits = _namedSelectionsForEntries(
      _choiceEntries(assembly.getEntriesByType(HeroEntryTypes.kit)),
    );
    if (kits.isNotEmpty) {
      features.add(
        ForgeFeatureExport.kit(
          kits,
          id: _featureId('class-kit-choice'),
          name: 'Kit',
        ),
      );
    }

    features.addAll(_classAbilityFeatures(selectedAbilityEntries));

    // Skills granted by a domain feature are recorded as class_feature entries
    // but must be exported under a "Domain Feature", not the flat class Skill
    // Choice (Codex rejects domain skills not in the class's allowed groups).
    final domainSkillIds = <String>{
      for (final ids in _domainSkillSelections(assembly).values) ...ids,
    };
    final classSkills = _namesForEntries(
      _classChoiceEntries(assembly.skills)
          .where((entry) => !domainSkillIds.contains(entry.entryId))
          .toList(growable: false),
    );
    if (classSkills.isNotEmpty) {
      features.add(
        ForgeFeatureExport.skillChoice(
          classSkills,
          id: _featureId('class-skill-choice'),
          name: 'Skills',
          count: classSkills.length,
        ),
      );
    }

    final perks =
        _namedSelectionsForEntries(_classChoiceEntries(assembly.perks));
    if (perks.isNotEmpty) {
      features.add(
        ForgeFeatureExport.perk(
          perks,
          id: _featureId('class-perk-choice'),
          name: 'Perk',
          count: perks.length,
        ),
      );
    }

    final domains = _namedSelectionsForEntries(
      assembly.getEntriesByType(HeroEntryTypes.domain),
      includeEmptyFeaturesByLevel: true,
    );
    if (domains.isNotEmpty) {
      features.add(
        ForgeFeatureExport.domain(
          domains,
          id: _featureId('class-domain-choice'),
          name: 'Domain',
          count: domains.length,
        ),
      );
      // The importer only registers a domain if it also finds a matching
      // "Domain Feature" entry, so emit one per selected domain.
      features.addAll(_domainFeatures(assembly));
    }

    return features;
  }

  /// Maps domain name -> chosen skill ids from
  /// `class_feature.skill_group_selections`, keyed by the domain-feature key,
  /// e.g. `{"censor_1_level_domain_feature": {"Creation": "skill_alchemy"}}`.
  Map<String, List<String>> _domainSkillSelections(HeroAssembly assembly) {
    final dynamic raw =
        assembly.config[HeroConfigKeys.classFeatureSkillGroupSelections];
    final result = <String, List<String>>{};
    if (raw is! Map) return result;
    for (final feature in raw.entries) {
      if (!feature.key.toString().toLowerCase().contains('domain')) continue;
      final dynamic byDomain = feature.value;
      if (byDomain is! Map) continue;
      for (final selection in byDomain.entries) {
        final id = selection.value?.toString().trim();
        if (id == null || id.isEmpty) continue;
        result
            .putIfAbsent(selection.key.toString(), () => <String>[])
            .add(id);
      }
    }
    return result;
  }

  /// Builds one "Domain Feature" per selected domain. The nested selection id
  /// must start with `domain-<slug>` for the importer to attribute it, and the
  /// feature carries the domain's chosen skills (if any).
  List<ForgeFeatureExport> _domainFeatures(HeroAssembly assembly) {
    final domainEntries = assembly.getEntriesByType(HeroEntryTypes.domain);
    if (domainEntries.isEmpty) return const [];
    final skillsByDomain = _domainSkillSelections(assembly);
    final features = <ForgeFeatureExport>[];
    for (final entry in domainEntries) {
      final domainName = _resolver.nameForEntry(entry);
      if (domainName == null) continue;
      final slug = domainName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final skillNames = _dedupNames(
        (skillsByDomain[domainName] ?? const [])
            .map((id) => _resolver.nameForId(id))
            .whereType<String>(),
      );
      features.add(
        ForgeFeatureExport(
          'Domain Feature',
          {
            'selected': [
              {
                'id': 'domain-$slug-skill',
                'type': 'Skill Choice',
                'name': '$domainName Domain',
                'data': {
                  'options': const <String>[],
                  'listOptions': const <String>[],
                  'count': skillNames.isEmpty ? 1 : skillNames.length,
                  'selected': skillNames,
                },
              },
            ],
          },
          id: _featureId('class-domain-feature-$slug'),
          name: '$domainName Domain',
        ),
      );
    }
    return features;
  }

  List<ForgeFeatureExport> _classAbilityFeatures(
    List<db.HeroEntry> selectedAbilityEntries,
  ) {
    final idsByCost = <int, List<String>>{};
    for (final entry in selectedAbilityEntries) {
      // Only player-chosen abilities belong in a Class Ability choice slot.
      // Granted class abilities (Judgment, My Life for Yours) and domain-granted
      // abilities (Hands of the Maker) are auto-added by the importer; placing
      // them in a choice pollutes the slot and blocks the real selection.
      if (!_isChosenEntry(entry)) continue;
      final name = _resolver.nameForEntry(entry);
      if (name == null) continue;
      final cost = _abilityCost(entry);
      idsByCost.putIfAbsent(cost, () => <String>[]).add(
            _localAbilityId(entry.entryId),
          );
    }

    final sortedCosts = idsByCost.keys.toList()..sort();
    return [
      for (final cost in sortedCosts)
        ForgeFeatureExport.classAbility(
          idsByCost[cost]!,
          id: _featureId('class-ability-$cost'),
          name: cost == 0 ? 'Signature Ability' : '$cost Cost Ability',
          cost: cost,
          minLevel: 1,
        ),
    ];
  }

  int _abilityCost(db.HeroEntry entry) {
    final data = _resolver.dataForEntry(entry);
    final rawCost = data['resource_value'] ?? data['cost'];
    if (rawCost is num) return rawCost.toInt();
    final costs = data['costs'];
    if (costs is Map) {
      if (costs['signature'] == true) return 0;
      final amount = costs['amount'];
      if (amount is num) return amount.toInt();
      final parsedAmount = int.tryParse(amount?.toString() ?? '');
      if (parsedAmount != null) return parsedAmount;
    }
    return int.tryParse(rawCost?.toString() ?? '') ?? 0;
  }

  List<ForgeAbilityRefExport> _abilityExports(HeroAssembly assembly) {
    final abilitiesByExportId = <String, ForgeAbilityRefExport>{};
    for (final entry in _classAbilityEntries(assembly)) {
      final name = _resolver.nameForEntry(entry);
      if (name == null) continue;

      final exportId = _localAbilityId(entry.entryId);
      abilitiesByExportId.putIfAbsent(
        exportId,
        () => ForgeAbilityRefExport(
          id: exportId,
          name: name,
          description: _resolver.descriptionForEntry(entry),
        ),
      );
    }
    return abilitiesByExportId.values.toList(growable: false);
  }

  List<db.HeroEntry> _ancestryTraitEntries(HeroAssembly assembly) {
    final entries = assembly.traits.where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.ancestry ||
          entry.sourceType == HeroEntrySourceTypes.manualChoice ||
          entry.gainedBy == HeroEntryGainedBy.choice;
    }).toList(growable: false);

    if (entries.isNotEmpty) return entries;
    return assembly.traits;
  }

  List<db.HeroEntry> _careerEntries(
    HeroAssembly assembly, {
    required String entryType,
    String? careerId,
  }) {
    final entries = assembly.getEntriesByType(entryType).where((entry) {
      if (entry.sourceType != HeroEntrySourceTypes.career) return false;
      if (careerId == null || careerId.isEmpty) return true;
      return entry.sourceId == careerId ||
          entry.sourceId == 'career_choice' ||
          entry.sourceId == entryType;
    }).toList(growable: false);
    if (entries.isNotEmpty) return entries;

    return assembly.getEntriesByType(entryType).where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.manualChoice &&
          entry.gainedBy == HeroEntryGainedBy.choice &&
          entry.sourceId == 'career_choice';
    }).toList(growable: false);
  }

  List<db.HeroEntry> _ancestrySkillEntries(HeroAssembly assembly) {
    final entries = assembly.skills.where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.ancestry;
    }).toList(growable: false);
    if (entries.isNotEmpty) return entries;

    return assembly.skills.where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.manualChoice &&
          entry.sourceId == HeroEntrySourceTypes.ancestry;
    }).toList(growable: false);
  }

  List<db.HeroEntry> _classAbilityEntries(HeroAssembly assembly) {
    final entries = assembly.abilities.where((entry) {
      return entry.sourceType == HeroEntrySourceTypes.manualChoice ||
          entry.sourceType == HeroEntrySourceTypes.classEntry ||
          entry.sourceType == HeroEntrySourceTypes.classFeature ||
          entry.sourceType == HeroEntrySourceTypes.subclass;
    }).toList(growable: false);

    if (entries.isNotEmpty) return entries;
    return _choiceEntries(assembly.abilities);
  }

  List<ForgeCharacteristicExport> _characteristics(HeroAssembly assembly) => [
        ForgeCharacteristicExport(
          characteristic: 'Might',
          value: assembly.stats['might'] ?? 0,
        ),
        ForgeCharacteristicExport(
          characteristic: 'Agility',
          value: assembly.stats['agility'] ?? 0,
        ),
        ForgeCharacteristicExport(
          characteristic: 'Reason',
          value: assembly.stats['reason'] ?? 0,
        ),
        ForgeCharacteristicExport(
          characteristic: 'Intuition',
          value: assembly.stats['intuition'] ?? 0,
        ),
        ForgeCharacteristicExport(
          characteristic: 'Presence',
          value: assembly.stats['presence'] ?? 0,
        ),
      ];

  List<ForgeSubclassExport> _subclasses(HeroAssembly assembly) {
    final subclassId = assembly.subclassId;
    final subclassName = _resolver.nameForId(subclassId);
    if (subclassName == null) return const [];
    return [
      ForgeSubclassExport(
        id: _codexId(subclassId),
        name: subclassName,
        description: _resolver.descriptionForId(subclassId),
      ),
    ];
  }

  ForgeNamedRef? _incitingIncident(HeroAssembly assembly) {
    final value =
        assembly.config[HeroConfigKeys.careerIncitingIncident]?['name'];
    final name = value?.toString().trim();
    if (name == null || name.isEmpty) return null;

    final incidents =
        _resolver.dataForId(assembly.careerId)['inciting_incidents'];
    if (incidents is List) {
      for (var i = 0; i < incidents.length; i++) {
        final incident = incidents[i];
        if (incident is! Map) continue;
        final incidentName = incident['name']?.toString().trim();
        if (incidentName == null ||
            incidentName.toLowerCase() != name.toLowerCase()) {
          continue;
        }
        final careerId = _codexId(assembly.careerId) ?? 'career';
        return ForgeNamedRef(
          id: incident['id']?.toString().trim().isNotEmpty == true
              ? _codexId(incident['id']?.toString())
              : '$careerId-ii-${i + 1}',
          name: incidentName,
          description: incident['description']?.toString().trim(),
        );
      }
    }

    return ForgeNamedRef(name: name);
  }

  List<String> _primaryCharacteristicNames(HeroAssembly assembly) {
    final classData = _resolver.dataForId(assembly.classId);
    final starting = classData['starting_characteristics'];
    if (starting is! Map) return const [];
    final fixed = starting['fixed_starting_characteristics'];
    if (fixed is! Map) return const [];

    final names = <String>[];
    for (final entry in fixed.entries) {
      final value = entry.value;
      final numericValue = value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
      if (numericValue == 0) continue;
      names.add(_titleCaseWords(entry.key.toString()));
    }
    return names;
  }

  Map<String, dynamic>? _characteristicArray(HeroAssembly assembly) {
    final array = assembly.config[HeroConfigKeys.strifeCharacteristicArray];
    final assignments =
        assembly.config[HeroConfigKeys.strifeCharacteristicAssignments];
    final payload = <String, dynamic>{};

    if (array != null) {
      payload.addAll(array);
    }

    final assignmentMap = assignments?['assignments'];
    if (assignmentMap is Map && assignmentMap.isNotEmpty) {
      payload['assignments'] = Map<String, dynamic>.from(assignmentMap);
    }

    return payload.isEmpty ? null : payload;
  }

  List<String> _skillGroupOptions(String componentId) {
    final data = _resolver.dataForId(componentId);
    final rawGroups = data['skillGroups'] ?? data['skill_groups'];
    return _stringList(rawGroups).map(_titleCaseWords).toList(growable: false);
  }

  List<String> _careerPerkLists(Map<String, dynamic> careerData) {
    final rawPerkType = careerData['perk_type']?.toString().trim();
    if (rawPerkType == null || rawPerkType.isEmpty) return const [];
    final normalized = rawPerkType
        .replaceAll(RegExp(r'\bperk\b', caseSensitive: false), '')
        .trim();
    if (normalized.isEmpty) return const [];
    return [_titleCaseWords(normalized)];
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _lookupIdForEntry(db.HeroEntry entry) {
    return HeroEntryTypes.componentLookupId(entry.entryType, entry.entryId) ??
        entry.entryId;
  }

  String? _codexId(String? id) {
    final value = id?.trim();
    if (value == null || value.isEmpty || value.startsWith('user_')) {
      return null;
    }
    final sanitized = value
        .replaceAll('_', '-')
        .replaceAll(RegExp(r'[^A-Za-z0-9.-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return sanitized.isEmpty ? null : sanitized;
  }

  String _featureId(String value) {
    return _codexId(value) ?? 'feature';
  }

  String _titleCaseWords(String value) {
    final words = value
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words.map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  List<db.HeroEntry> _choiceEntries(List<db.HeroEntry> entries) {
    return entries.where(_isChosenEntry).toList(growable: false);
  }

  List<db.HeroEntry> _classChoiceEntries(List<db.HeroEntry> entries) {
    return entries.where((entry) {
      if (!_isChosenEntry(entry)) return false;
      return entry.sourceType == HeroEntrySourceTypes.manualChoice ||
          entry.sourceType == HeroEntrySourceTypes.classEntry ||
          entry.sourceType == HeroEntrySourceTypes.classFeature ||
          entry.sourceType == HeroEntrySourceTypes.subclass;
    }).toList(growable: false);
  }

  List<db.HeroEntry> _entriesFromSource(
    HeroAssembly assembly,
    String sourceType,
    String sourceId, {
    String? entryType,
  }) {
    final entries = assembly.getEntriesFromSource(sourceType, sourceId);
    if (entryType == null) return entries;
    return entries
        .where((entry) => entry.entryType == entryType)
        .toList(growable: false);
  }

  bool _isChosenEntry(db.HeroEntry entry) {
    return entry.gainedBy == HeroEntryGainedBy.choice ||
        entry.sourceType == HeroEntrySourceTypes.manualChoice;
  }

  List<String> _namesForEntries(List<db.HeroEntry> entries) {
    final names = <String>[];
    final seen = <String>{};
    for (final entry in entries) {
      final name = _resolver.nameForEntry(entry);
      if (name == null) continue;
      final normalized = name.toLowerCase();
      if (seen.add(normalized)) names.add(name);
    }
    return names;
  }

  List<ForgeNamedSelection> _namedSelectionsForEntries(
    List<db.HeroEntry> entries, {
    bool includeEmptyFeaturesByLevel = false,
  }) {
    final selections = <ForgeNamedSelection>[];
    final seen = <String>{};
    for (final entry in entries) {
      final name = _resolver.nameForEntry(entry);
      if (name == null) continue;
      final normalized = name.toLowerCase();
      if (!seen.add(normalized)) continue;
      selections.add(
        ForgeNamedSelection(
          id: _codexId(_lookupIdForEntry(entry)),
          name: name,
          description: _resolver.descriptionForEntry(entry),
          featuresByLevel:
              includeEmptyFeaturesByLevel ? const <ForgeLevelFeaturesExport>[] : null,
        ),
      );
    }
    return selections;
  }

  db.HeroEntry? _firstEntry(List<db.HeroEntry> entries) {
    for (final entry in entries) {
      if (_resolver.nameForEntry(entry) != null) return entry;
    }
    return null;
  }
}

class _StoryLanguageNames {
  const _StoryLanguageNames({required this.culture, required this.career});

  final List<String> culture;
  final List<String> career;
}

class _ComponentResolver {
  _ComponentResolver(List<db.Component> components)
      : _componentsById = {
          for (final component in components) component.id: component,
        },
        _abilityAliasIds = _buildAbilityAliasIndex(components),
        _nestedComponentsById = _buildNestedComponentIndex(components);

  final Map<String, db.Component> _componentsById;
  final Map<String, String> _abilityAliasIds;
  final Map<String, _NestedComponent> _nestedComponentsById;

  String? nameForId(String? id) {
    final raw = _rawNameForId(id);
    return raw == null ? null : aliasForgeName(raw);
  }

  String? _rawNameForId(String? id) {
    final lookupId = id?.trim();
    if (lookupId == null || lookupId.isEmpty || lookupId.startsWith('user_')) {
      return null;
    }

    final component = _componentForLookupId(lookupId);
    if (component != null) {
      if (component.source == 'user') return null;
      final name = component.name.trim();
      if (name.isNotEmpty) return name;
    }

    final nested = _nestedComponentsById[lookupId];
    if (nested != null && nested.name.isNotEmpty) {
      return nested.name;
    }

    return _fallbackDisplayName(lookupId);
  }

  String? nameForEntry(db.HeroEntry entry) {
    final lookupId = HeroEntryTypes.componentLookupId(
          entry.entryType,
          entry.entryId,
        ) ??
        entry.entryId;
    return nameForId(lookupId);
  }

  String descriptionForEntry(db.HeroEntry entry) {
    final lookupId = HeroEntryTypes.componentLookupId(
          entry.entryType,
          entry.entryId,
        ) ??
        entry.entryId;
    return _descriptionForId(lookupId);
  }

  String descriptionForId(String? id) {
    final lookupId = id?.trim();
    if (lookupId == null || lookupId.isEmpty || lookupId.startsWith('user_')) {
      return '';
    }
    return _descriptionForId(lookupId);
  }

  Map<String, dynamic> dataForEntry(db.HeroEntry entry) {
    final lookupId = HeroEntryTypes.componentLookupId(
          entry.entryType,
          entry.entryId,
        ) ??
        entry.entryId;
    return _dataForId(lookupId);
  }

  String? signatureNameForAncestry(String? ancestryId) {
    final lookupAncestryId = ancestryId?.trim();
    if (lookupAncestryId == null || lookupAncestryId.isEmpty) return null;

    for (final component in _componentsById.values) {
      if (component.type != 'ancestry_trait' || component.dataJson.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(component.dataJson);
        if (decoded is! Map) continue;
        final data = Map<String, dynamic>.from(decoded);
        if (data['ancestry_id']?.toString().trim() != lookupAncestryId) {
          continue;
        }
        for (final item in _signatureItems(data['signature'])) {
          final name = item['name']?.toString().trim();
          if (name != null && name.isNotEmpty) return name;
        }
      } catch (_) {}
    }

    return null;
  }

  Map<String, dynamic> signatureDataForAncestry(
    String? ancestryId,
    String signatureName,
  ) {
    final lookupAncestryId = ancestryId?.trim();
    if (lookupAncestryId == null || lookupAncestryId.isEmpty) {
      return const {};
    }

    for (final component in _componentsById.values) {
      if (component.type != 'ancestry_trait' || component.dataJson.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(component.dataJson);
        if (decoded is! Map) continue;
        final data = Map<String, dynamic>.from(decoded);
        if (data['ancestry_id']?.toString().trim() != lookupAncestryId) {
          continue;
        }

        final signature = data['signature'];
        for (final item in _signatureItems(signature)) {
          final name = item['name']?.toString().trim();
          if (name != null &&
              name.toLowerCase() == signatureName.trim().toLowerCase()) {
            return item;
          }
        }
      } catch (_) {}
    }

    return const {};
  }

  String _descriptionForId(String id) {
    final data = _dataForId(id);
    final parts = <String>[];

    void addString(String key) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) parts.add(value);
    }

    addString('description');
    addString('story_text');
    addString('power_roll');
    _addTierEffects(parts, data['tier_effects']);
    addString('effect');
    addString('special_effect');

    final seen = <String>{};
    final uniqueParts = <String>[];
    for (final part in parts) {
      if (seen.add(part)) uniqueParts.add(part);
    }
    return uniqueParts.join('\n\n');
  }

  Map<String, dynamic> dataForId(String? id) {
    if (id == null || id.isEmpty) return const {};
    return _dataForId(id);
  }

  Map<String, dynamic> _dataForId(String id) {
    final component = _componentForLookupId(id);
    if (component != null && component.dataJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(component.dataJson);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    final nested = _nestedComponentsById[id];
    if (nested != null) return nested.data;
    return const {};
  }

  db.Component? _componentForLookupId(String id) {
    final component = _componentsById[id];
    if (component != null) return component;

    for (final candidate in [id, ..._candidateAbilityLookupIds(id)]) {
      final directComponent = _componentsById[candidate];
      if (directComponent != null) return directComponent;

      final abilityId = _abilityAliasIds[candidate] ??
          _abilityAliasIds[_abilityAliasSlug(candidate)];
      if (abilityId != null) return _componentsById[abilityId];
    }
    return null;
  }

  void _addTierEffects(List<String> parts, dynamic tierEffects) {
    if (tierEffects is! List) return;
    for (final tierEffect in tierEffects) {
      if (tierEffect is! Map) continue;
      final lines = <String>[];
      for (final key in ['tier1', 'tier2', 'tier3']) {
        final value = tierEffect[key]?.toString().trim();
        if (value != null && value.isNotEmpty) lines.add(value);
      }
      if (lines.isNotEmpty) parts.add(lines.join('\n'));
    }
  }

  String _fallbackDisplayName(String id) {
    var value = id;
    for (final prefix in _fallbackPrefixes) {
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length);
        break;
      }
    }
    value = value.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    if (value.isEmpty) return id;
    return value.split(RegExp(r'\s+')).map(_titleCaseWord).join(' ');
  }

  String _titleCaseWord(String word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}

class _NestedComponent {
  const _NestedComponent({
    required this.name,
    required this.data,
  });

  final String name;
  final Map<String, dynamic> data;
}

Iterable<Map<String, dynamic>> _signatureItems(dynamic signature) sync* {
  if (signature is Map) {
    yield Map<String, dynamic>.from(signature);
    return;
  }
  if (signature is List) {
    for (final item in signature) {
      if (item is Map) yield Map<String, dynamic>.from(item);
    }
  }
}

Map<String, _NestedComponent> _buildNestedComponentIndex(
  List<db.Component> components,
) {
  final index = <String, _NestedComponent>{};

  void addNode(Object? node) {
    if (node is! Map) return;
    final data = Map<String, dynamic>.from(node);
    final id = data['id']?.toString().trim();
    final name = data['name']?.toString().trim();
    if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
      index[id] = _NestedComponent(name: name, data: data);
    }
  }

  for (final component in components.where((c) => c.type == 'ancestry_trait')) {
    if (component.dataJson.isEmpty) continue;
    try {
      final decoded = jsonDecode(component.dataJson);
      if (decoded is! Map) continue;
      final data = Map<String, dynamic>.from(decoded);
      for (final item in _signatureItems(data['signature'])) {
        addNode(item);
      }
      final traits = data['traits'];
      if (traits is List) {
        for (final trait in traits) {
          addNode(trait);
        }
      }
    } catch (_) {}
  }

  return index;
}

Map<String, String> _buildAbilityAliasIndex(List<db.Component> components) {
  final index = <String, String>{};

  for (final component in components.where((c) => c.type == 'ability')) {
    final id = component.id.trim();
    if (id.isEmpty) continue;

    final data = _decodeComponentData(component);
    final cost = _abilityCostFromData(data);
    final resource = _abilityResourceFromData(data);
    final originalId = data['original_id']?.toString().trim();

    void addAlias(String value) {
      final alias = value.trim();
      if (alias.isEmpty) return;
      index.putIfAbsent(alias, () => id);
      index.putIfAbsent(_abilityAliasSlug(alias), () => id);
    }

    addAlias(id);
    addAlias(component.name);
    if (id.startsWith('ability-')) {
      addAlias(id.substring('ability-'.length));
    }
    if (id.startsWith('ability_')) {
      addAlias(id.substring('ability_'.length));
    }
    if (originalId != null && originalId.isNotEmpty) {
      addAlias(originalId);
    }

    final classSlug = _abilityClassSlug(component, data);
    if (classSlug == null || classSlug.isEmpty) continue;

    final baseIds = <String>{id};
    if (originalId != null && originalId.isNotEmpty) baseIds.add(originalId);
    if (id.startsWith('ability_${classSlug}_')) {
      baseIds.add(id.substring('ability_${classSlug}_'.length));
    }

    for (final baseId in baseIds) {
      addAlias('ability_${classSlug}_$baseId');
      if (resource != null && resource.toLowerCase() == 'signature') {
        addAlias('ability_${classSlug}_signature_$baseId');
      }
      if (cost != null && cost > 0) {
        addAlias('ability_${classSlug}_cost${cost}_$baseId');
        if (resource != null && resource.isNotEmpty) {
          addAlias('ability_${classSlug}_${resource}_cost${cost}_$baseId');
        }
      }
    }
  }

  return index;
}

List<String> _candidateAbilityLookupIds(String id) {
  if (!id.startsWith('ability_')) return const [];

  final segments = id.substring('ability_'.length).split('_');
  if (segments.length < 2) return const [];

  final abilitySegments = segments.skip(1).toList(growable: false);
  if (abilitySegments.isEmpty) return const [];

  var startIndex = 0;
  int? cost;
  String? resource;

  if (abilitySegments.first == 'signature') {
    startIndex = 1;
  } else if (abilitySegments.length >= 2 &&
      abilitySegments[1].startsWith('cost')) {
    resource = abilitySegments.first;
    cost = int.tryParse(abilitySegments[1].substring('cost'.length));
    startIndex = 2;
  } else if (abilitySegments.first.startsWith('cost')) {
    cost = int.tryParse(abilitySegments.first.substring('cost'.length));
    startIndex = 1;
  }

  final base = abilitySegments.skip(startIndex).join('_').trim();
  if (base.isEmpty) return const [];

  final candidates = <String>[];
  void add(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || candidates.contains(trimmed)) return;
    candidates.add(trimmed);
  }

  final baseHyphen = base.replaceAll('_', '-');
  add(base);
  add(baseHyphen);
  add('ability-$baseHyphen');

  if (cost != null && resource != null && resource.isNotEmpty) {
    final resourceHyphen = resource.replaceAll('_', '-');
    final suffix = '-$cost-$resourceHyphen';
    if (baseHyphen.endsWith(suffix)) {
      final stripped =
          baseHyphen.substring(0, baseHyphen.length - suffix.length);
      add(stripped);
      add('ability-$stripped');
    }
  }

  return candidates;
}

Map<String, dynamic> _decodeComponentData(db.Component component) {
  if (component.dataJson.isEmpty) return const {};
  try {
    final decoded = jsonDecode(component.dataJson);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return const {};
}

String? _abilityClassSlug(db.Component component, Map<String, dynamic> data) {
  final rawSlug = data['class_slug']?.toString().trim();
  if (rawSlug != null && rawSlug.isNotEmpty) return _abilityAliasSlug(rawSlug);

  final path = data['ability_source_path']?.toString().replaceAll('\\', '/');
  if (path != null && path.isNotEmpty) {
    final match = RegExp(r'class_abilities_simplified/([^/]+)_abilities\.json')
        .firstMatch(path);
    if (match != null) return _abilityAliasSlug(match.group(1)!);
  }

  final parts = component.id.split('_');
  if (parts.length > 2 && parts.first == 'ability') return parts[1];
  return null;
}

String? _abilityResourceFromData(Map<String, dynamic> data) {
  final raw = data['resource'] ?? data['costs']?['resource'];
  final resource = raw?.toString().trim();
  if (resource == null || resource.isEmpty) return null;
  return _abilityAliasSlug(resource);
}

int? _abilityCostFromData(Map<String, dynamic> data) {
  final rawCost = data['resource_value'] ?? data['cost'];
  if (rawCost is num) return rawCost.toInt();
  final parsedCost = int.tryParse(rawCost?.toString() ?? '');
  if (parsedCost != null) return parsedCost;

  final costs = data['costs'];
  if (costs is Map) {
    if (costs['signature'] == true) return 0;
    final amount = costs['amount'];
    if (amount is num) return amount.toInt();
    return int.tryParse(amount?.toString() ?? '');
  }
  return null;
}

String _abilityAliasSlug(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return '';
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _localAbilityId(String entryId) {
  final sanitized = entryId
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return sanitized.isEmpty ? 'ability' : sanitized;
}

const _fallbackPrefixes = [
  'ancestry_',
  'ancestry-',
  'career_',
  'career-',
  'class_',
  'class-',
  'complication_',
  'complication-',
  'culture_environment_',
  'culture-environment-',
  'culture_organisation_',
  'culture-organisation-',
  'culture_organization_',
  'culture-organization-',
  'culture_upbringing_',
  'culture-upbringing-',
  'deity_',
  'deity-',
  'domain_',
  'domain-',
  'kit_',
  'kit-',
  'language_',
  'language-',
  'perk_',
  'perk-',
  'skill_',
  'skill-',
  'subclass_',
  'subclass-',
  'title_',
  'title-',
  'ability_',
  'ability-',
];
