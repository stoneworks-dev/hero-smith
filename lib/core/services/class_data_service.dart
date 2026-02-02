import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/class_data.dart';

/// Service for loading and managing class progression data from JSON files
class ClassDataService {
  static final ClassDataService _instance = ClassDataService._internal();
  factory ClassDataService() => _instance;
  ClassDataService._internal();

  final Map<String, ClassData> _classCache = {};
  bool _isInitialized = false;

  /// List of all available class file names (without .json extension)
  static const List<String> availableClasses = [
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

  /// Initialize and load all class data
  Future<void> initialize() async {
    if (_isInitialized) return;

    for (final className in availableClasses) {
      final classData = await _loadClassData(className);
      _classCache[classData.classId] = classData;
    }

    _isInitialized = true;
  }

  /// Load a specific class data from JSON file
  Future<ClassData> _loadClassData(String className) async {
    try {
      final jsonString = await rootBundle.loadString(
        'data/classes_levels_and_stats/$className.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return ClassData.fromJson(jsonData);
    } catch (e, stackTrace) {
      throw Exception('Failed to load class "$className": $e\n$stackTrace');
    }
  }

  /// Get all available classes
  List<ClassData> getAllClasses() {
    if (!_isInitialized) {
      throw StateError('ClassDataService not initialized. Call initialize() first.');
    }
    return _classCache.values.toList();
  }

  /// Get a specific class by ID
  ClassData? getClassById(String classId) {
    return _classCache[classId];
  }

  /// Get a specific class by name
  ClassData? getClassByName(String name) {
    return _classCache.values.firstWhere(
      (classData) => classData.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw StateError('Class not found: $name'),
    );
  }

  /// Get level progression for a specific class and level
  LevelProgression? getLevelProgression(String classId, int level) {
    final classData = getClassById(classId);
    if (classData == null) return null;

    try {
      return classData.levels.firstWhere((l) => l.level == level);
    } catch (e) {
      return null;
    }
  }

  /// Get all levels up to and including the specified level
  List<LevelProgression> getLevelsUpTo(String classId, int level) {
    final classData = getClassById(classId);
    if (classData == null) return [];

    return classData.levels.where((l) => l.level <= level).toList();
  }

  /// Clear the cache (useful for testing)
  void clearCache() {
    _classCache.clear();
    _isInitialized = false;
  }
}
