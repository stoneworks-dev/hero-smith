import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Represents a single generation option preset
class GenerationPreset {
  final String key;
  final String label;
  /// Fixed dice-to-value mapping for this preset (e.g., for pray_1d3).
  /// If provided, these values are used instead of standard 1d3.
  final List<int>? values;

  const GenerationPreset({required this.key, required this.label, this.values});

  factory GenerationPreset.fromJson(Map<String, dynamic> json) {
    final valuesJson = json['values'] as List<dynamic>?;
    return GenerationPreset(
      key: json['key'] as String,
      label: json['label'] as String,
      values: valuesJson?.map((e) => e as int).toList(),
    );
  }
}

/// Represents a level-based modification to generation options
class LevelModification {
  final int level;
  final String? increase;
  final String? remove;
  /// Updated dice values at this level for the 'increase' option (e.g., plus_1d3).
  /// Only applies when 'increase' is a dice-based option like 'plus_1d3'.
  final List<int>? values;

  const LevelModification({
    required this.level,
    this.increase,
    this.remove,
    this.values,
  });

  factory LevelModification.fromJson(Map<String, dynamic> json) {
    final valuesJson = json['values'] as List<dynamic>?;
    return LevelModification(
      level: json['level'] as int,
      increase: json['increase'] as String?,
      remove: json['remove'] as String?,
      values: valuesJson?.map((e) => e as int).toList(),
    );
  }
}

/// Represents a class's heroic resource generation options
class HeroicResourceGeneration {
  final String classKey;
  final String resourceKey;
  final List<String> generationOptions;
  final List<LevelModification> levelModifications;

  const HeroicResourceGeneration({
    required this.classKey,
    required this.resourceKey,
    required this.generationOptions,
    this.levelModifications = const [],
  });

  factory HeroicResourceGeneration.fromJson(Map<String, dynamic> json) {
    final levelMods = json['generation_increase_at_levels'] as List<dynamic>?;
    return HeroicResourceGeneration(
      classKey: json['class_key'] as String,
      resourceKey: json['resource_key'] as String,
      generationOptions: (json['generation_options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      levelModifications: levelMods
          ?.map((e) => LevelModification.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Result of a resource generation action
class GenerationResult {
  final int value;
  final String description;
  final bool requiresConfirmation;
  final List<int>? alternativeValues; // For dice rolls where user can pick
  /// Maps dice roll (1, 2, 3) to actual resource value gained.
  /// Used to display the mapping in the dice roll dialog.
  final Map<int, int>? diceToValueMapping;

  const GenerationResult({
    required this.value,
    required this.description,
    this.requiresConfirmation = false,
    this.alternativeValues,
    this.diceToValueMapping,
  });
}

/// Service for managing heroic resource generation
class ResourceGenerationService {
  static ResourceGenerationService? _instance;
  static ResourceGenerationService get instance {
    _instance ??= ResourceGenerationService._();
    return _instance!;
  }

  ResourceGenerationService._();

  Map<String, GenerationPreset> _presets = {};
  Map<String, HeroicResourceGeneration> _classResources = {};
  bool _initialized = false;

  final Random _random = Random();

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'data/features/class_features/resource_generation.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load presets
      final presetsList = data['amount_presets'] as List<dynamic>;
      for (final presetJson in presetsList) {
        final preset = GenerationPreset.fromJson(presetJson as Map<String, dynamic>);
        _presets[preset.key] = preset;
      }

      // Load class resources
      final resourcesList = data['heroic_resources'] as List<dynamic>;
      for (final resourceJson in resourcesList) {
        final resource = HeroicResourceGeneration.fromJson(resourceJson as Map<String, dynamic>);
        _classResources[resource.classKey] = resource;
      }

      _initialized = true;
    } catch (e) {
      // If loading fails, use empty defaults
      _presets = {};
      _classResources = {};
      _initialized = true;
    }
  }

  /// Get the generation options for a class, adjusted for hero level
  List<GenerationPreset> getGenerationOptionsForClass(String? classId, {int heroLevel = 1}) {
    if (classId == null || classId.isEmpty) return [];

    // Extract class key from classId (e.g., "class_fury" -> "fury")
    final classKey = classId.startsWith('class_')
        ? classId.substring('class_'.length)
        : classId;

    final resourceGen = _classResources[classKey.toLowerCase()];
    if (resourceGen == null) return [];

    // Start with base options
    final optionKeys = List<String>.from(resourceGen.generationOptions);

    // Apply level-based modifications
    for (final mod in resourceGen.levelModifications) {
      if (heroLevel >= mod.level) {
        // Remove the old option if specified
        if (mod.remove != null) {
          optionKeys.remove(mod.remove);
        }
        // Add the new option if not already present (only if increase is specified)
        if (mod.increase != null && !optionKeys.contains(mod.increase)) {
          optionKeys.add(mod.increase!);
        }
      }
    }

    return optionKeys
        .map((key) => _presets[key])
        .whereType<GenerationPreset>()
        .toList();
  }

  /// Get the preset by key
  GenerationPreset? getPreset(String key) => _presets[key];

  /// Calculate the result for a generation option
  GenerationResult calculateGeneration({
    required String optionKey,
    required int victories,
    String? classId,
    int heroLevel = 1,
  }) {
    switch (optionKey) {
      case 'victories':
        return GenerationResult(
          value: victories,
          description: '+$victories (Victories)',
        );

      case 'plus_1':
        return const GenerationResult(
          value: 1,
          description: '+1',
        );

      case 'plus_2':
        return const GenerationResult(
          value: 2,
          description: '+2',
        );

      case 'plus_3':
        return const GenerationResult(
          value: 3,
          description: '+3',
        );

      case 'plus_4':
        return const GenerationResult(
          value: 4,
          description: '+4',
        );

      case 'plus_5':
        return const GenerationResult(
          value: 5,
          description: '+5',
        );

      case 'plus_1d3':
        return _roll1d3WithBonus(0);

      case 'plus_1d3+1':
        return _roll1d3WithBonus(1);

      case 'plus_1d3+2':
        return _roll1d3WithBonus(2);

      default:
        // Check if this matches plus_1d3+N pattern for any other bonus
        if (optionKey.startsWith('plus_1d3+')) {
          final bonusStr = optionKey.substring('plus_1d3+'.length);
          final bonus = int.tryParse(bonusStr);
          if (bonus != null) {
            return _roll1d3WithBonus(bonus);
          }
        }
        
        // Check if this is a preset with fixed dice values (like pray_1d3)
        final preset = _presets[optionKey];
        if (preset != null && preset.values != null && preset.values!.length >= 3) {
          final roll = _random.nextInt(3) + 1;
          final values = preset.values!;
          final diceToValueMapping = {
            1: values[0],
            2: values[1],
            3: values[2],
          };
          final alternativeValues = values.toSet().toList()..sort();
          final actualValue = values[roll - 1];
          
          return GenerationResult(
            value: actualValue,
            description: '+$actualValue (${preset.label} → $roll)',
            requiresConfirmation: true,
            alternativeValues: alternativeValues,
            diceToValueMapping: diceToValueMapping,
          );
        }
        
        return const GenerationResult(
          value: 0,
          description: '+0',
        );
    }
  }

  /// Helper method to roll 1d3 with a bonus added to each result
  GenerationResult _roll1d3WithBonus(int bonus) {
    final roll = _random.nextInt(3) + 1;
    final diceToValueMapping = {
      1: 1 + bonus,
      2: 2 + bonus,
      3: 3 + bonus,
    };
    final alternativeValues = [1 + bonus, 2 + bonus, 3 + bonus];
    final actualValue = roll + bonus;
    
    final bonusLabel = bonus > 0 ? '+$bonus' : '';
    return GenerationResult(
      value: actualValue,
      description: '+$actualValue (1d3$bonusLabel → $roll)',
      requiresConfirmation: true,
      alternativeValues: alternativeValues,
      diceToValueMapping: diceToValueMapping,
    );
  }

  /// Get the display label for an option, replacing X with victories count
  String getDisplayLabel(String optionKey, int victories) {
    final preset = _presets[optionKey];
    if (preset == null) return '+?';

    if (optionKey == 'victories') {
      return '+$victories';
    }

    return preset.label;
  }
}
