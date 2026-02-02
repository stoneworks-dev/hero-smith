import 'package:flutter/foundation.dart';

import '../db/app_database.dart';

/// Validation result containing issues found during hero data validation.
class HeroValidationResult {
  final String heroId;
  final List<String> bannedValueKeys;
  final List<String> duplicateEntries;
  final List<String> orphanConfigKeys;
  final List<String> unresolvedComponentIds;
  final List<String> aggregationMismatches;
  final List<String> metadataMismatches;

  const HeroValidationResult({
    required this.heroId,
    this.bannedValueKeys = const [],
    this.duplicateEntries = const [],
    this.orphanConfigKeys = const [],
    this.unresolvedComponentIds = const [],
    this.aggregationMismatches = const [],
    this.metadataMismatches = const [],
  });

  bool get isValid =>
      bannedValueKeys.isEmpty &&
      duplicateEntries.isEmpty &&
      orphanConfigKeys.isEmpty &&
      unresolvedComponentIds.isEmpty &&
      aggregationMismatches.isEmpty &&
      metadataMismatches.isEmpty;

  int get totalIssues =>
      bannedValueKeys.length +
      duplicateEntries.length +
      orphanConfigKeys.length +
      unresolvedComponentIds.length +
      aggregationMismatches.length +
      metadataMismatches.length;

  @override
  String toString() {
    if (isValid) return 'Hero $heroId: VALID';
    
    final buffer = StringBuffer('Hero $heroId: $totalIssues issues found\n');
    
    if (bannedValueKeys.isNotEmpty) {
      buffer.writeln('  Banned hero_values keys:');
      for (final key in bannedValueKeys) {
        buffer.writeln('    - $key');
      }
    }
    
    if (duplicateEntries.isNotEmpty) {
      buffer.writeln('  Duplicate hero_entries:');
      for (final entry in duplicateEntries) {
        buffer.writeln('    - $entry');
      }
    }
    
    if (orphanConfigKeys.isNotEmpty) {
      buffer.writeln('  Orphan hero_config keys:');
      for (final key in orphanConfigKeys) {
        buffer.writeln('    - $key');
      }
    }
    
    if (unresolvedComponentIds.isNotEmpty) {
      buffer.writeln('  Unresolved component IDs:');
      for (final id in unresolvedComponentIds) {
        buffer.writeln('    - $id');
      }
    }
    
    if (aggregationMismatches.isNotEmpty) {
      buffer.writeln('  Aggregation mismatches:');
      for (final mismatch in aggregationMismatches) {
        buffer.writeln('    - $mismatch');
      }
    }
    
    if (metadataMismatches.isNotEmpty) {
      buffer.writeln('  Metadata mismatches:');
      for (final mismatch in metadataMismatches) {
        buffer.writeln('    - $mismatch');
      }
    }
    
    return buffer.toString();
  }
}

/// Debug utility for validating hero data integrity across all three storage layers.
/// 
/// This validator checks:
/// - No banned hero_values keys exist
/// - No duplicate hero_entries
/// - No orphan config rows
/// - All component IDs resolve to known components
/// - Aggregation values match entries
/// - No mismatched metadata
class HeroDataValidator {
  final AppDatabase _db;

  /// Banned prefixes that should NOT appear in hero_values.
  /// Content should be in hero_entries, selections in hero_config.
  static const List<String> _bannedValuePrefixes = [
    // Identity content → hero_entries
    'basics.className',
    'basics.subclass',
    'basics.ancestry',
    'basics.career',
    'basics.kit',
    
    // Ancestry grants → hero_entries
    'ancestry.granted_abilities',
    'ancestry.applied_bonuses',
    'ancestry.condition_immunities',
    'ancestry.stat_mods',
    'ancestry.selected_traits',
    
    // Perk grants → hero_entries / hero_config
    'perk_abilities.',
    'perk_grant.',
    
    // Complication grants → hero_entries
    'complication.applied_grants',
    'complication.abilities',
    'complication.skills',
    'complication.features',
    'complication.treasures',
    'complication.languages',
    'complication.damage_resistances',
    'complication.stat_mods',
    
    // Class feature grants → hero_entries
    'class_feature.',
    'class_feature_abilities',
    'class_feature_skills',
    'class_feature_stat_mods',
    'class_feature_resistances',
    
    // Kit grants → hero_entries
    'kit_grants.',
    'kit.abilities',
    'kit.equipment',
    'kit.stat_bonuses',
    'kit.signature_ability',
    
    // Career grants → hero_entries
    'career.abilities',
    'career.skills_granted',
    'career.perks_granted',
    
    // Culture grants → hero_entries
    'culture.skills_granted',
    'culture.languages_granted',
    
    // Faith → hero_entries
    'faith.deity',
    'faith.domain',
    
    // Legacy strife content
    'strife.equipment_bonuses',
  ];

  /// Valid entry types for hero_entries table.
  static const Set<String> _validEntryTypes = {
    'class',
    'subclass',
    'ancestry',
    'ancestry_trait',
    'career',
    'kit',
    'deity',
    'domain',
    'ability',
    'skill',
    'perk',
    'language',
    'title',
    'equipment',
    'stat_mod',
    'resistance',
    'immunity',
    'weakness',
    'feature',
    'complication',
    'culture',
  };

  HeroDataValidator(this._db);

  /// Validate a single hero's data integrity.
  Future<HeroValidationResult> validate(String heroId) async {
    final bannedKeys = <String>[];
    final duplicateEntries = <String>[];
    final orphanConfigs = <String>[];
    final unresolvedIds = <String>[];
    final aggregationMismatches = <String>[];
    final metadataMismatches = <String>[];

    // 1. Check for banned hero_values keys
    final values = await _db.getHeroValues(heroId);
    for (final value in values) {
      if (_isBannedKey(value.key)) {
        bannedKeys.add(value.key);
      }
    }

    // 2. Check for duplicate hero_entries
    final entries = await (_db.select(_db.heroEntries)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    final entrySignatures = <String>{};
    for (final entry in entries) {
      final signature = '${entry.entryType}:${entry.entryId}:${entry.sourceType}:${entry.sourceId}';
      if (entrySignatures.contains(signature)) {
        duplicateEntries.add(signature);
      } else {
        entrySignatures.add(signature);
      }
    }

    // 3. Check for invalid entry types
    for (final entry in entries) {
      if (!_validEntryTypes.contains(entry.entryType)) {
        metadataMismatches.add('Invalid entry_type: ${entry.entryType} for ${entry.entryId}');
      }
    }

    // 4. Check that component IDs resolve (for resolvable types)
    final resolvableTypes = {'ability', 'skill', 'perk', 'equipment', 'class', 'subclass', 'ancestry', 'career', 'kit'};
    for (final entry in entries) {
      if (resolvableTypes.contains(entry.entryType)) {
        final component = await _db.getComponentById(entry.entryId);
        if (component == null) {
          // Try by type lookup (some components may be stored differently)
          final byType = await (_db.select(_db.components)
                ..where((c) => c.type.equals(entry.entryType)))
              .get();
          final exists = byType.any((c) => c.id == entry.entryId);
          if (!exists) {
            unresolvedIds.add('${entry.entryType}:${entry.entryId}');
          }
        }
      }
    }

    // 5. Check aggregation consistency (resistances)
    final resistanceEntries = entries.where((e) => e.entryType == 'resistance').toList();
    
    // Verify resistances.damage aggregate matches sum of resistance entries
    final resistanceDamageValue = values.where((v) => v.key == 'resistances.damage').firstOrNull;
    
    if (resistanceEntries.isEmpty && resistanceDamageValue?.textValue != null) {
      aggregationMismatches.add(
        'resistances.damage has value but no resistance entries exist',
      );
    }

    // 6. Check for orphan config keys (config referencing non-existent entries)
    final configs = await (_db.select(_db.heroConfig)
          ..where((t) => t.heroId.equals(heroId)))
        .get();
    
    for (final config in configs) {
      // Check if config references a selection that should have corresponding entries
      if (config.configKey.contains('.selected_') || config.configKey.endsWith('_selection')) {
        // These are selection configs - they're valid
        continue;
      }
      
      // Check for strife.* configs that should reference valid data
      if (config.configKey.startsWith('strife.') && 
          config.configKey != 'strife.subclass_key' &&
          config.configKey != 'strife.characteristic_array' &&
          config.configKey != 'strife.characteristic_assignments' &&
          config.configKey != 'strife.level_choice_selections' &&
          config.configKey != 'strife.class_feature_selections') {
        // Unknown strife config key - might be orphaned
        orphanConfigs.add('Unknown strife config: ${config.configKey}');
      }
    }

    // 7. Verify identity entries consistency
    final classEntry = entries.where((e) => e.entryType == 'class').firstOrNull;
    
    // Check hero row matches entries (heroes table has classComponentId, not className)
    final heroRow = await (_db.select(_db.heroes)
          ..where((t) => t.id.equals(heroId)))
        .getSingleOrNull();
    if (heroRow != null) {
      if (classEntry != null && 
          heroRow.classComponentId != null && 
          heroRow.classComponentId != classEntry.entryId) {
        metadataMismatches.add(
          'heroes.classComponentId (${heroRow.classComponentId}) != class entry (${classEntry.entryId})',
        );
      }
    }

    return HeroValidationResult(
      heroId: heroId,
      bannedValueKeys: bannedKeys,
      duplicateEntries: duplicateEntries,
      orphanConfigKeys: orphanConfigs,
      unresolvedComponentIds: unresolvedIds,
      aggregationMismatches: aggregationMismatches,
      metadataMismatches: metadataMismatches,
    );
  }

  /// Validate all heroes in the database.
  Future<List<HeroValidationResult>> validateAll() async {
    final heroes = await _db.select(_db.heroes).get();
    final results = <HeroValidationResult>[];
    
    for (final hero in heroes) {
      results.add(await validate(hero.id));
    }
    
    return results;
  }

  /// Print a summary of validation results.
  static void printSummary(List<HeroValidationResult> results) {
    if (!kDebugMode) return;
    
    final validCount = results.where((r) => r.isValid).length;
    final invalidCount = results.length - validCount;
    
    debugPrint('=== Hero Data Validation Summary ===');
    debugPrint('Total heroes: ${results.length}');
    debugPrint('Valid: $validCount');
    debugPrint('Invalid: $invalidCount');
    
    if (invalidCount > 0) {
      debugPrint('\n=== Invalid Heroes ===');
      for (final result in results.where((r) => !r.isValid)) {
        debugPrint(result.toString());
      }
    }
  }

  bool _isBannedKey(String key) {
    for (final prefix in _bannedValuePrefixes) {
      if (key.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
