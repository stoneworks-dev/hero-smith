import 'dart:convert';

import '../db/app_database.dart';
import '../repositories/hero_entry_repository.dart';
import 'ability_resolver_service.dart';

/// Service to handle title grant processing.
/// 
/// Titles can grant abilities through their selected benefit.
/// This service writes ability entries to hero_entries with sourceType='title'.
class TitleGrantsService {
  TitleGrantsService(this._db)
      : _entries = HeroEntryRepository(_db),
        _abilityResolver = AbilityResolverService(_db);
  
  final AppDatabase _db;
  final HeroEntryRepository _entries;
  final AbilityResolverService _abilityResolver;
  
  /// Get all titles from the database.
  Future<List<Component>> loadTitles() async {
    return _abilityResolver.getAllTitles();
  }
  
  /// Get a title by ID from the database.
  /// Returns the title data as a Map for compatibility with existing code.
  Future<Map<String, dynamic>?> getTitleById(String titleId) async {
    final component = await _abilityResolver.getTitleById(titleId);
    if (component == null) return null;
    
    // Reconstruct the title data from Component
    final data = component.dataJson.isNotEmpty 
        ? jsonDecode(component.dataJson) as Map<String, dynamic>
        : <String, dynamic>{};
    return {
      'id': component.id,
      'name': component.name,
      ...data,
    };
  }
  
  /// Get the ability ID for a title benefit, if it grants one
  Future<String?> getAbilityIdForBenefit(
    Map<String, dynamic> title, 
    int benefitIndex,
  ) async {
    final benefits = title['benefits'] as List?;
    if (benefits == null || benefitIndex >= benefits.length) return null;
    
    final benefit = benefits[benefitIndex] as Map<String, dynamic>?;
    if (benefit == null) return null;
    
    final abilityRef = benefit['ability'];
    if (abilityRef == null || abilityRef.toString().isEmpty) return null;
    
    final abilitySlug = abilityRef.toString();
    return await _abilityResolver.resolveAbilityId(
      abilitySlug,
      sourceType: 'title',
      ensureInDb: true,
    );
  }
  
  /// Apply title grants for a hero.
  /// 
  /// Takes a list of selected titles in format "titleId:benefitIndex"
  /// and writes any granted abilities to hero_entries.
  Future<void> applyTitleGrants({
    required String heroId,
    required List<String> selectedTitleIds,
  }) async {
    // First clear all existing title-granted abilities
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
    );
    
    // Process each selected title
    for (final selection in selectedTitleIds) {
      final parts = selection.split(':');
      if (parts.length != 2) continue;
      
      final titleId = parts[0];
      final benefitIndex = int.tryParse(parts[1]) ?? 0;
      
      final title = await getTitleById(titleId);
      if (title == null) continue;
      
      final abilityId = await getAbilityIdForBenefit(title, benefitIndex);
      if (abilityId == null || abilityId.isEmpty) continue;
      
      // Note: getAbilityIdForBenefit already calls _abilityResolver with ensureInDb: true
      
      // Write ability entry with title as source
      await _entries.addEntry(
        heroId: heroId,
        entryType: 'ability',
        entryId: abilityId,
        sourceType: 'title',
        sourceId: titleId,
        gainedBy: 'grant',
        payload: {
          'benefitIndex': benefitIndex,
          'titleName': title['name'],
        },
      );
    }
  }
  
  /// Remove all title grants for a hero.
  Future<void> removeTitleGrants({
    required String heroId,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
    );
  }
  
  /// Remove grants for a specific title.
  Future<void> removeTitleGrantsForTitle({
    required String heroId,
    required String titleId,
  }) async {
    await _entries.removeEntriesFromSource(
      heroId: heroId,
      sourceType: 'title',
      sourceId: titleId,
    );
  }
  
  /// Get all abilities granted by titles for a hero.
  Future<List<String>> getGrantedAbilities({
    required String heroId,
  }) async {
    final all = await _entries.listEntriesByType(heroId, 'ability');
    return all
        .where((e) => e.sourceType == 'title')
        .map((e) => e.entryId)
        .toList();
  }
}
