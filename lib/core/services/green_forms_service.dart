import 'dart:convert';

import 'package:flutter/services.dart';

import '../../widgets/creature stat block/green_animal_form.dart';

/// Service for loading and managing Green Elementalist animal forms data.
class GreenFormsService {
  GreenFormsService._();
  static final instance = GreenFormsService._();

  List<GreenAnimalForm>? _cachedForms;
  bool _initialized = false;

  /// Load all green animal forms from the data file.
  Future<List<GreenAnimalForm>> loadAllForms() async {
    if (_cachedForms != null) return _cachedForms!;

    try {
      final jsonString = await rootBundle.loadString(
        'data/features/green_forms.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedForms = jsonList
          .map((item) => GreenAnimalForm.fromJson(item as Map<String, dynamic>))
          .toList();
      _cachedForms!.sort((a, b) => a.level.compareTo(b.level));
      _initialized = true;
      return _cachedForms!;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get forms available at a specific hero level.
  Future<List<GreenAnimalForm>> getFormsForLevel(int heroLevel) async {
    final allForms = await loadAllForms();
    return allForms.where((form) => form.level <= heroLevel).toList();
  }

  /// Get forms that are locked (above hero level).
  Future<List<GreenAnimalForm>> getLockedForms(int heroLevel) async {
    final allForms = await loadAllForms();
    return allForms.where((form) => form.level > heroLevel).toList();
  }

  /// Get a specific form by ID.
  Future<GreenAnimalForm?> getFormById(String formId) async {
    final allForms = await loadAllForms();
    try {
      return allForms.firstWhere((form) => form.id == formId);
    } catch (_) {
      return null;
    }
  }

  /// Check if service is initialized.
  bool get isInitialized => _initialized;

  /// Clear cached data (useful for testing or refreshing).
  void clearCache() {
    _cachedForms = null;
    _initialized = false;
  }

  /// Group forms by level for display.
  Future<Map<int, List<GreenAnimalForm>>> getFormsGroupedByLevel() async {
    final allForms = await loadAllForms();
    final grouped = <int, List<GreenAnimalForm>>{};
    
    for (final form in allForms) {
      grouped.putIfAbsent(form.level, () => []).add(form);
    }
    
    return grouped;
  }
}
