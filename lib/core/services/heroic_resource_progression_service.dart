import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/heroic_resource_progression.dart';

/// Service for loading and managing heroic resource progression data.
/// 
/// This service handles:
/// - Growing Ferocity tables for Fury class (Berserker, Reaver, Stormwight kits)
/// - Discipline Mastery tables for Null class
class HeroicResourceProgressionService {
  HeroicResourceProgressionService._();

  static final HeroicResourceProgressionService _instance =
      HeroicResourceProgressionService._();

  factory HeroicResourceProgressionService() => _instance;

  // Cache for loaded progressions
  Map<String, HeroicResourceProgression>? _ferocityProgressions;
  Map<String, HeroicResourceProgression>? _disciplineProgressions;

  static const String _ferocityAssetPath = 'data/features/growing_ferocity.json';
  static const String _disciplineAssetPath = 'data/features/discipline_mastery.json';

  /// Mapping of stormwight kit IDs/names to their growing ferocity feature IDs
  static const Map<String, String> _stormwightKitToFeatureId = {
    'kit_boren': 'boren_growing_ferocity',
    'boren': 'boren_growing_ferocity',
    'kit_corven': 'corven_growing_ferocity',
    'corven': 'corven_growing_ferocity',
    'kit_raden': 'raden_growing_ferocity',
    'raden': 'raden_growing_ferocity',
    'kit_vulken': 'vuken_growing_ferocity',
    'vulken': 'vuken_growing_ferocity',
    // Note: vuken in data, but kit might be vulken
    'kit_vuken': 'vuken_growing_ferocity',
    'vuken': 'vuken_growing_ferocity',
  };

  /// Mapping of fury subclass names to their growing ferocity feature IDs
  static const Map<String, String> _furySubclassToFeatureId = {
    'berserker': 'berserker_growing_ferocity',
    'reaver': 'reaver_growing_ferocity',
  };

  /// Mapping of null subclass names to their discipline mastery feature IDs
  static const Map<String, String> _nullSubclassToFeatureId = {
    'chronokinetic': 'chronokinetic_mastery',
    'cryokinetic': 'cryokinetic_mastery',
    'metakinetic': 'metakinetic_mastery',
  };

  /// Load all Growing Ferocity progressions
  Future<Map<String, HeroicResourceProgression>> loadFerocityProgressions() async {
    if (_ferocityProgressions != null) {
      return _ferocityProgressions!;
    }

    final result = await _loadProgressions(
      assetPath: _ferocityAssetPath,
      resourceName: 'Ferocity',
      resourceKey: 'ferocity',
    );

    _ferocityProgressions = result;
    return result;
  }

  /// Load all Discipline Mastery progressions
  Future<Map<String, HeroicResourceProgression>> loadDisciplineProgressions() async {
    if (_disciplineProgressions != null) {
      return _disciplineProgressions!;
    }

    final result = await _loadProgressions(
      assetPath: _disciplineAssetPath,
      resourceName: 'Discipline',
      resourceKey: 'discipline',
    );

    _disciplineProgressions = result;
    return result;
  }

  Future<Map<String, HeroicResourceProgression>> _loadProgressions({
    required String assetPath,
    required String resourceName,
    required String resourceKey,
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      final result = <String, HeroicResourceProgression>{};
      for (final item in jsonList) {
        if (item is! Map<String, dynamic>) continue;
        final progression = HeroicResourceProgression.fromJson(
          item,
          resourceName: resourceName,
          resourceKey: resourceKey,
        );
        if (progression.id.isNotEmpty) {
          result[progression.id] = progression;
        }
      }
      return result;
    } catch (e) {
      // Return empty map on error
      return const {};
    }
  }

  /// Determine if a class uses heroic resource progression tables.
  /// Returns true for Fury and Null classes only.
  bool classUsesProgressionTable(String? className) {
    if (className == null) return false;
    final normalized = className.trim().toLowerCase();
    return normalized == 'fury' || normalized == 'null';
  }

  /// Get the heroic resource type for a class.
  /// Returns null if the class doesn't use progression tables.
  HeroicResourceType? getResourceType(String? className) {
    if (className == null) return null;
    final normalized = className.trim().toLowerCase();
    switch (normalized) {
      case 'fury':
        return HeroicResourceType.ferocity;
      case 'null':
        return HeroicResourceType.discipline;
      default:
        return null;
    }
  }

  /// Check if a Fury subclass is Stormwight (requires kit selection for progression)
  bool isStormwightSubclass(String? subclassName) {
    if (subclassName == null) return false;
    final normalized = subclassName.trim().toLowerCase();
    return normalized == 'stormwight';
  }

  /// Get the progression for a Fury hero based on their subclass and kit.
  /// 
  /// For Berserker/Reaver subclasses: uses the subclass progression directly.
  /// For Stormwight subclass: uses the kit-based progression (requires kitId).
  Future<HeroicResourceProgression?> getFerocityProgression({
    required String? subclassName,
    String? kitId,
  }) async {
    if (subclassName == null) return null;

    final progressions = await loadFerocityProgressions();
    final normalizedSubclass = subclassName.trim().toLowerCase();

    // Check if it's a standard subclass (Berserker, Reaver)
    if (_furySubclassToFeatureId.containsKey(normalizedSubclass)) {
      final featureId = _furySubclassToFeatureId[normalizedSubclass];
      return featureId != null ? progressions[featureId] : null;
    }

    // If Stormwight, need to look up by kit
    if (isStormwightSubclass(subclassName) && kitId != null) {
      final normalizedKit = kitId.trim().toLowerCase();
      final featureId = _stormwightKitToFeatureId[normalizedKit];
      return featureId != null ? progressions[featureId] : null;
    }

    return null;
  }

  /// Get the progression for a Null hero based on their subclass.
  Future<HeroicResourceProgression?> getDisciplineProgression({
    required String? subclassName,
  }) async {
    if (subclassName == null) return null;

    final progressions = await loadDisciplineProgressions();
    final normalizedSubclass = subclassName.trim().toLowerCase();

    final featureId = _nullSubclassToFeatureId[normalizedSubclass];
    return featureId != null ? progressions[featureId] : null;
  }

  /// Get the appropriate progression based on class, subclass, and kit.
  /// This is the main entry point for getting a hero's progression table.
  Future<HeroicResourceProgression?> getProgression({
    required String? className,
    required String? subclassName,
    String? kitId,
  }) async {
    final resourceType = getResourceType(className);
    if (resourceType == null) return null;

    switch (resourceType) {
      case HeroicResourceType.ferocity:
        return getFerocityProgression(
          subclassName: subclassName,
          kitId: kitId,
        );
      case HeroicResourceType.discipline:
        return getDisciplineProgression(subclassName: subclassName);
    }
  }

  /// Clear cached data (useful for testing or hot reload)
  void clearCache() {
    _ferocityProgressions = null;
    _disciplineProgressions = null;
  }
}
