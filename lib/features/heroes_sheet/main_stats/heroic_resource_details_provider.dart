/// Provider for fetching heroic resource details from class feature data.
/// 
/// This provider handles loading and caching heroic resource information
/// for display in the hero stats view.
library;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/feature_repository.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_models_text.dart';
import 'hero_main_stats_models.dart';

/// Cache for heroic resource details by class slug.
final heroicResourceCache = <String, HeroicResourceDetails>{};

/// Provider that fetches heroic resource details for a given class.
final heroicResourceDetailsProvider =
    FutureProvider.family<HeroicResourceDetails?, HeroicResourceRequest>(
  (ref, request) async {
    final slug = slugFromClassId(request.classId);
    if (slug == null) {
      final fallback = request.fallbackName;
      return fallback == null ? null : HeroicResourceDetails(name: fallback);
    }

    final cached = heroicResourceCache[slug];
    if (cached != null) return cached;

    try {
      final maps = await FeatureRepository.loadClassFeatureMaps(slug);
      final entry = maps.firstWhereOrNull(
        (map) =>
            (map['type']?.toString().toLowerCase() ?? '') == 'heroic resource',
      );
      if (entry == null) {
        final fallback = request.fallbackName;
        if (fallback == null) return null;
        final details = HeroicResourceDetails(name: fallback);
        heroicResourceCache[slug] = details;
        return details;
      }

      final name = entry['name']?.toString() ??
          request.fallbackName ??
          HeroMainStatsModelsText.heroicResourceFallbackName;
      final description = entry['description']?.toString();

      String? inCombatName;
      String? inCombatDescription;
      final inCombat = entry['in_combat'];
      if (inCombat is Map) {
        inCombatName = inCombat['name']?.toString();
        inCombatDescription = inCombat['description']?.toString();
      }

      String? outCombatName;
      String? outCombatDescription;
      final outCombat = entry['out_of_combat'];
      if (outCombat is Map) {
        outCombatName = outCombat['name']?.toString();
        outCombatDescription = outCombat['description']?.toString();
      }

      String? strainName;
      String? strainDescription;
      final strain = entry['strain'];
      if (strain is Map) {
        strainName = strain['name']?.toString();
        strainDescription = strain['description']?.toString();
      }

      final canBeNegative = entry['can_be_negative'] == true;
      final negativeFormula = entry['negative_formula']?.toString();

      final details = HeroicResourceDetails(
        name: name,
        description: description,
        inCombatName: inCombatName,
        inCombatDescription: inCombatDescription,
        outCombatName: outCombatName,
        outCombatDescription: outCombatDescription,
        strainName: strainName,
        strainDescription: strainDescription,
        canBeNegative: canBeNegative,
        negativeFormula: negativeFormula,
      );
      heroicResourceCache[slug] = details;
      return details;
    } catch (_) {
      final fallback = request.fallbackName;
      return fallback == null ? null : HeroicResourceDetails(name: fallback);
    }
  },
);

/// Extracts the class slug from a class ID string.
/// 
/// Removes the 'class_' prefix if present.
String? slugFromClassId(String? classId) {
  if (classId == null || classId.isEmpty) return null;
  if (classId.startsWith('class_')) {
    return classId.substring('class_'.length);
  }
  return classId;
}
