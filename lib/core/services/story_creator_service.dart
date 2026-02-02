import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart' as db;
import '../db/providers.dart';
import '../models/story_creator_models.dart';
import '../repositories/hero_repository.dart';
import 'ancestry_bonus_service.dart';
import 'complication_grants_service.dart';
import 'perk_grants_service.dart';

class StoryCreatorService {
  StoryCreatorService(
    this._heroRepository,
    this._ancestryBonusService,
    this._complicationGrantsService,
    this._db,
  );

  final HeroRepository _heroRepository;
  final AncestryBonusService _ancestryBonusService;
  final ComplicationGrantsService _complicationGrantsService;
  final db.AppDatabase _db;
  Map<String, StoryCultureSuggestion>? _suggestionsCache;

  Future<StoryCreatorLoadResult> loadInitialData(String heroId) async {
    final hero = await _heroRepository.load(heroId);
    final culture = await _heroRepository.loadCultureSelection(heroId);
    final career = await _heroRepository.loadCareerSelection(heroId);
    final traits = await _heroRepository.getSelectedAncestryTraits(heroId);
    final traitChoices = await _heroRepository.getAncestryTraitChoices(heroId);
    final complicationId = await _heroRepository.loadComplication(heroId);
    final complicationChoices = await _complicationGrantsService.loadComplicationChoices(heroId);

    await _complicationGrantsService.syncSkillGrants(heroId);

    return StoryCreatorLoadResult(
      hero: hero,
      cultureSelection: culture,
      careerSelection: career,
      ancestryTraitIds: traits,
      ancestryTraitChoices: traitChoices,
      complicationId: complicationId,
      complicationChoices: complicationChoices,
    );
  }

  Future<void> saveStory(StoryCreatorSavePayload payload) async {
    final hero = await _heroRepository.load(payload.heroId);
    if (hero == null) {
      throw Exception('Hero with id ${payload.heroId} not found.');
    }

    // Check if ancestry or traits have changed
    final oldAncestryId = hero.ancestry;
    final oldTraitIds = await _heroRepository.getSelectedAncestryTraits(payload.heroId);
    final oldTraitChoices = await _heroRepository.getAncestryTraitChoices(payload.heroId);
    final ancestryChanged = oldAncestryId != payload.ancestryId;
    final traitsChanged = !_listEquals(oldTraitIds, payload.ancestryTraitIds.toList());
    final choicesChanged = !_mapEquals(oldTraitChoices, payload.ancestryTraitChoices);

    // Remove old bonuses if ancestry, traits, or choices changed
    if (ancestryChanged || traitsChanged || choicesChanged) {
      await _ancestryBonusService.removeBonuses(payload.heroId);
    }

    // Check if complication or its choices have changed
    final oldComplicationId = await _heroRepository.loadComplication(payload.heroId);
    final oldComplicationChoices = await _complicationGrantsService.loadComplicationChoices(payload.heroId);
    final complicationChanged = oldComplicationId != payload.complicationId;
    final complicationChoicesChanged = !_mapEquals(oldComplicationChoices, payload.complicationChoices);

    // Remove old complication grants if complication or choices changed
    if (complicationChanged || complicationChoicesChanged) {
      await _complicationGrantsService.removeGrants(payload.heroId);
    }

    hero.name = payload.name;
    hero.ancestry = payload.ancestryId;
    hero.career = payload.careerId;

    await _heroRepository.save(hero);

    await _heroRepository.saveAncestryTraits(
      heroId: payload.heroId,
      ancestryId: payload.ancestryId,
      selectedTraitIds: payload.ancestryTraitIds.toList(),
    );

    // Save trait choices (immunity type, ability selection, etc.)
    await _heroRepository.saveAncestryTraitChoices(
      payload.heroId,
      payload.ancestryTraitChoices,
    );

    // Apply new ancestry bonuses if ancestry, traits, or choices changed
    if (ancestryChanged || traitsChanged || choicesChanged) {
      final bonuses = await _ancestryBonusService.parseAncestryBonuses(
        ancestryId: payload.ancestryId,
        selectedTraitIds: payload.ancestryTraitIds.toList(),
        traitChoices: payload.ancestryTraitChoices,
      );
      final heroLevel = await _heroRepository.getHeroLevel(payload.heroId);
      await _ancestryBonusService.applyBonuses(
        heroId: payload.heroId,
        bonuses: bonuses,
        heroLevel: heroLevel,
      );
    }

    final languageIds = payload.languageIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    await _heroRepository.saveCultureSelection(
      heroId: payload.heroId,
      environmentId: payload.environmentId,
      organisationId: payload.organisationId,
      upbringingId: payload.upbringingId,
      languageIds: languageIds,
      environmentSkillId: payload.environmentSkillId,
      organisationSkillId: payload.organisationSkillId,
      upbringingSkillId: payload.upbringingSkillId,
    );

    // Get previously selected perks before saving career selection
    final oldCareerSelection = await _heroRepository.loadCareerSelection(payload.heroId);
    final oldPerkIds = oldCareerSelection.chosenPerkIds.toSet();
    final newPerkIds = payload.careerPerkIds.toSet();
    
    // Determine which perks were removed and which were added
    final removedPerkIds = oldPerkIds.difference(newPerkIds);
    final addedPerkIds = newPerkIds.difference(oldPerkIds);

    await _heroRepository.saveCareerSelection(
      heroId: payload.heroId,
      careerId: payload.careerId,
      chosenSkillIds: payload.careerSkillIds.toList(),
      chosenPerkIds: payload.careerPerkIds.toList(),
      incitingIncidentName: payload.careerIncidentName,
    );

    // Remove grants from perks that were deselected
    await _removePerkGrants(
      heroId: payload.heroId,
      perkIds: removedPerkIds.toList(),
    );

    // Apply perk grants (abilities) for newly selected perks
    await _applyPerkGrants(
      heroId: payload.heroId,
      perkIds: addedPerkIds.toList(),
    );

    await _heroRepository.saveComplication(
      heroId: payload.heroId,
      complicationId: payload.complicationId,
    );

    // Save complication choices
    await _complicationGrantsService.saveComplicationChoices(
      heroId: payload.heroId,
      choices: payload.complicationChoices,
    );

    // Apply new complication grants if complication or choices changed
    if (complicationChanged || complicationChoicesChanged) {
      final grants = await _complicationGrantsService.parseComplicationGrants(
        complicationId: payload.complicationId,
        choices: payload.complicationChoices,
      );
      final heroLevel = await _heroRepository.getHeroLevel(payload.heroId);
      await _complicationGrantsService.applyGrants(
        heroId: payload.heroId,
        grants: grants,
        heroLevel: heroLevel,
      );
    }
  }

  Future<StoryCultureSuggestion?> suggestionForAncestry(String? ancestryName) async {
    if (ancestryName == null || ancestryName.trim().isEmpty) return null;
    final map = await _loadSuggestions();
    return map[ancestryName.trim().toLowerCase()];
  }

  Future<Map<String, StoryCultureSuggestion>> _loadSuggestions() async {
    if (_suggestionsCache != null) return _suggestionsCache!;
    try {
      final raw = await rootBundle
          .loadString('data/story/culture/culture_suggestions.json');
      final decoded = jsonDecode(raw);
      final result = <String, StoryCultureSuggestion>{};
      if (decoded is Map && decoded['typical_ancestry_cultures'] is List) {
        for (final entry in decoded['typical_ancestry_cultures']) {
          if (entry is! Map) continue;
          final map = entry.cast<String, dynamic>();
          final key = (map['ancestry']?.toString() ?? '').toLowerCase();
          if (key.isEmpty) continue;
          result[key] = StoryCultureSuggestion(
            language: _clean(map['language']),
            environment: _clean(map['environment']),
            organization: _clean(map['organization']),
            upbringing: _clean(map['upbringing']),
          );
        }
      }
      _suggestionsCache = result;
      return result;
    } catch (_) {
      _suggestionsCache = const <String, StoryCultureSuggestion>{};
      return _suggestionsCache!;
    }
  }

  String? _clean(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Apply perk grants for selected perks.
  /// This adds ability grants from perks to the hero's abilities.
  Future<void> _applyPerkGrants({
    required String heroId,
    required List<String> perkIds,
  }) async {
    // Get all perks from database
    final allComponents = await _db.getAllComponents();
    final perkGrantsService = PerkGrantsService(_db);
    
    for (final perkId in perkIds) {
      final perkComp = allComponents.where(
        (c) => c.id == perkId && c.type == 'perk',
      ).firstOrNull;
      
      if (perkComp == null) continue;
      
      try {
        final data = jsonDecode(perkComp.dataJson) as Map<String, dynamic>;
        final grantsRaw = data['grants'];
        if (grantsRaw != null) {
          await perkGrantsService.applyPerkGrants(
            heroId: heroId,
            perkId: perkId,
            grantsJson: grantsRaw,
          );
        }
      } catch (_) {
        // Skip if perk data is invalid
      }
    }
  }

  /// Remove perk grants for deselected perks.
  /// This removes ability grants from perks that are no longer selected.
  Future<void> _removePerkGrants({
    required String heroId,
    required List<String> perkIds,
  }) async {
    final perkGrantsService = PerkGrantsService(_db);
    
    for (final perkId in perkIds) {
      await perkGrantsService.removePerkGrants(
        heroId: heroId,
        perkId: perkId,
      );
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

final storyCreatorServiceProvider = Provider<StoryCreatorService>((ref) {
  final repo = ref.read(heroRepositoryProvider);
  final ancestryBonusService = ref.read(ancestryBonusServiceProvider);
  final complicationGrantsService = ref.read(complicationGrantsServiceProvider);
  final database = ref.read(appDatabaseProvider);
  return StoryCreatorService(repo, ancestryBonusService, complicationGrantsService, database);
});
