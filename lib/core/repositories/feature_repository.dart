import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/feature.dart';

class FeatureRepository {
  static const List<String> _classNames = [
    'censor',
    'conduit',
    'elementalist',
    'fury',
    'null',
    'shadow',
    'tactician',
    'talent',
    'troubadour',
  ];

  static Future<Map<String, List<Feature>>> loadAllClassFeatures() async {
    final Map<String, List<Feature>> classFeatures = {};

    for (final className in _classNames) {
      try {
        final features = await loadClassFeatures(className);
        // Include the class even if it has zero valid features parsed,
        // so navigation cards still render and issues are visible.
        classFeatures[className] = features;
      } catch (e) {
        // Skip classes that don't have feature files
        continue;
      }
    }

    return classFeatures;
  }

  static Future<List<Feature>> loadClassFeatures(String className) async {
    try {
      final jsonString = await rootBundle.loadString(
          'data/features/class_features/${className}_features.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      // Parse features defensively: skip invalid entries instead of failing the whole class
      final List<Feature> features = [];
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          try {
            final normalized = Map<String, dynamic>.from(item);
            final currentClass = normalized['class']?.toString().trim();
            if (currentClass == null || currentClass.isEmpty) {
              normalized['class'] = className;
            }
            final currentType = normalized['type']?.toString().trim();
            if (currentType == null || currentType.isEmpty) {
              normalized['type'] = 'feature';
            }
            features.add(Feature.fromJson(normalized));
          } catch (_) {
            // Skip invalid feature entries silently
          }
        }
      }

      return features;
    } catch (e) {
      throw Exception('Failed to load features for class $className: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadClassFeatureMaps(
    String className,
  ) async {
    try {
      final jsonString = await rootBundle.loadString(
        'data/features/class_features/${className}_features.json',
      );
      final decoded = json.decode(jsonString);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw Exception('Failed to load feature maps for class $className: $e');
    }
  }

  static Map<int, List<Feature>> groupFeaturesByLevel(List<Feature> features) {
    final Map<int, List<Feature>> grouped = {};

    for (final feature in features) {
      grouped.putIfAbsent(feature.level, () => []).add(feature);
    }

    // Sort features within each level by name
    for (final levelFeatures in grouped.values) {
      levelFeatures.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  static String formatClassName(String className) {
    if (className.isEmpty) return className;
    return className[0].toUpperCase() + className.substring(1);
  }

  static List<int> getSortedLevels(Map<int, List<Feature>> featuresByLevel) {
    final levels = featuresByLevel.keys.toList();
    levels.sort();
    return levels;
  }
}
