import 'dart:convert';

import 'package:collection/collection.dart';

import '../db/app_database.dart';

/// Centralized service for resolving ability names to component IDs.
///
/// This service consolidates the ability resolution logic that was previously
/// duplicated across PerkGrantsService, KitGrantsService, TitleGrantsService,
/// ClassFeatureGrantsService, and ComplicationGrantsService.
///
/// All data is loaded from the Components table (seeded from JSON at startup).
/// Resolution strategies:
/// 1. Database lookup by exact name (case-insensitive)
/// 2. Database lookup by normalized slug
/// 3. Fallback to slugified name
class AbilityResolverService {
  AbilityResolverService(this._db);

  final AppDatabase _db;

  /// Resolves a single ability name to its component ID.
  ///
  /// [abilityName] - The display name or reference of the ability
  /// [sourceType] - The type of source requesting resolution (perk, title, kit, etc.)
  ///                Used to check source-specific ability JSON files as fallback.
  /// [ensureInDb] - If true and the ability is found in a JSON file but not in DB,
  ///                it will be inserted into the Components table.
  ///
  /// Returns the component ID, or a slugified fallback if not found.
  Future<String> resolveAbilityId(
    String abilityName, {
    String? sourceType,
    bool ensureInDb = false,
  }) async {
    // Note: sourceType and ensureInDb are kept for API compatibility
    // but are no longer needed since all data is now in the Components table.
    if (abilityName.isEmpty) return '';

    // 1. Try database lookup by name (using only abilities for efficiency)
    final abilities = await _db.getComponentsByType('ability');
    final normalizedName = _normalizeForComparison(abilityName);

    final dbMatch = abilities.firstWhereOrNull((c) {
      return _normalizeForComparison(c.name) == normalizedName;
    });

    if (dbMatch != null) {
      return dbMatch.id;
    }

    // 2. Try database lookup by slug match on ID
    final slugMatch = abilities.firstWhereOrNull((c) {
      return _normalizeSlug(c.id) == _normalizeSlug(abilityName);
    });

    if (slugMatch != null) {
      return slugMatch.id;
    }

    // 3. Fallback to slugified name
    return slugify(abilityName);
  }

  /// Resolves multiple ability names to their component IDs.
  ///
  /// See [resolveAbilityId] for parameter details.
  /// Returns a list of component IDs in the same order as input names.
  /// Empty names are skipped (not included in output).
  Future<List<String>> resolveAbilityIds(
    List<String> abilityNames, {
    String? sourceType,
    bool ensureInDb = false,
  }) async {
    final ids = <String>[];
    for (final name in abilityNames) {
      if (name.isEmpty) continue;
      final id = await resolveAbilityId(
        name,
        sourceType: sourceType,
        ensureInDb: ensureInDb,
      );
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }

  /// Builds a lookup map from ability names to IDs for efficient batch resolution.
  ///
  /// Useful when you need to resolve many abilities and want to avoid
  /// repeated database queries.
  Future<Map<String, String>> buildAbilityNameToIdMap() async {
    final abilities = await _db.getComponentsByType('ability');
    return {
      for (final c in abilities) c.name.toLowerCase(): c.id,
    };
  }

  /// Checks if an ability exists in the database by ID.
  Future<bool> abilityExistsInDb(String abilityId) async {
    final component = await _db.getComponentById(abilityId);
    return component != null && component.type == 'ability';
  }

  /// Gets an ability component by ID from the database.
  Future<Component?> getAbilityById(String abilityId) async {
    final component = await _db.getComponentById(abilityId);
    if (component?.type == 'ability') {
      return component;
    }
    return null;
  }

  // --- DB-based Data Loading ---

  /// Gets all skills from the Components table.
  Future<List<Component>> getAllSkills() async {
    return _db.getComponentsByType('skill');
  }

  /// Gets skills filtered by group (e.g., 'crafting', 'exploration', 'interpersonal').
  Future<List<Component>> getSkillsByGroup(String group) async {
    final skills = await _db.getComponentsByType('skill');
    return skills.where((s) {
      final data = s.dataJson.isNotEmpty ? jsonDecode(s.dataJson) : {};
      return (data['group'] as String?)?.toLowerCase() == group.toLowerCase();
    }).toList();
  }

  /// Gets all languages from the Components table.
  Future<List<Component>> getAllLanguages() async {
    return _db.getComponentsByType('language');
  }

  /// Gets all titles from the Components table.
  Future<List<Component>> getAllTitles() async {
    return _db.getComponentsByType('title');
  }

  /// Gets a title by ID from the Components table.
  Future<Component?> getTitleById(String titleId) async {
    final component = await _db.getComponentById(titleId);
    if (component?.type == 'title') {
      return component;
    }
    return null;
  }

  // --- Private Helpers ---

  String _normalizeForComparison(String value) {
    return value.toLowerCase().trim();
  }

  String _normalizeSlug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Converts a name to a URL/ID-friendly slug.
  static String slugify(String value) {
    final normalized =
        value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collapsed = normalized.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }
}
