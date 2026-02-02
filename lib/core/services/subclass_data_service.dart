import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subclass_models.dart';

class SubclassDataService {
  static final SubclassDataService _instance = SubclassDataService._internal();
  factory SubclassDataService() => _instance;
  SubclassDataService._internal();

  final Map<String, List<Map<String, dynamic>>> _classFeaturesCache = {};
  List<DeityOption>? _deityCache;
  Set<String>? _allDomainsCache;

  Future<SubclassFeatureData?> loadSubclassFeatureData({
    required String classSlug,
    required String featureName,
  }) async {
    final features = await _loadClassFeatures(classSlug);
    final normalizedTarget = featureName.trim().toLowerCase();

    for (final feature in features) {
      final name = feature['name']?.toString() ?? '';
      if (name.trim().toLowerCase() != normalizedTarget) continue;

      final description = feature['description']?.toString();
      final rawOptions = feature['options'];
      if (rawOptions is! List) {
        return SubclassFeatureData(
          featureName: name,
          featureDescription: description,
          options: const <SubclassOption>[],
        );
      }

      final options = rawOptions
          .whereType<Map>()
          .map((option) => Map<String, dynamic>.from(option))
          .map(_mapToSubclassOption)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return SubclassFeatureData(
        featureName: name,
        featureDescription: description,
        options: options,
      );
    }

    return null;
  }

  Future<List<DeityOption>> loadDeities() async {
    if (_deityCache != null) {
      return _deityCache!;
    }

    final jsonString = await rootBundle.loadString('data/story/deities.json');
    final decoded = json.decode(jsonString) as List<dynamic>;
    final deities = decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(_mapToDeityOption)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _deityCache = deities;
    return deities;
  }

  Future<Set<String>> loadAllDomains() async {
    if (_allDomainsCache != null) {
      return _allDomainsCache!;
    }

    final deities = await loadDeities();
    final domains = <String>{};
    for (final deity in deities) {
      domains.addAll(deity.domains);
    }
    _allDomainsCache = domains;
    return domains;
  }

  Future<List<Map<String, dynamic>>> _loadClassFeatures(String classSlug) async {
    if (_classFeaturesCache.containsKey(classSlug)) {
      return _classFeaturesCache[classSlug]!;
    }

    final path = 'data/features/class_features/${classSlug}_features.json';
    final jsonString = await rootBundle.loadString(path);
    final decoded = json.decode(jsonString) as List<dynamic>;
    final features = decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    _classFeaturesCache[classSlug] = features;
    return features;
  }

  SubclassOption _mapToSubclassOption(Map<String, dynamic> option) {
    String? _string(dynamic value) => value?.toString();

    final rawName = _string(option['name'] ?? option['subclass_name']) ?? 'Subclass Option';
    final key = _buildOptionKey(option, rawName);

    return SubclassOption(
      key: key,
      name: rawName,
      description: _string(option['description']),
      skill: _string(option['skill'] ?? option['skill_name']),
      skillGroup: _string(option['skill_group'] ?? option['skillGroup']),
      domain: _string(option['domain']),
      abilityName: _string(option['ability'] ?? option['ability_name']),
      raw: option,
    );
  }

  DeityOption _mapToDeityOption(Map<String, dynamic> map) {
    String? _string(dynamic value) => value?.toString();

    final domainsRaw = map['domains'];
    final domains = <String>[];
    if (domainsRaw is List) {
      for (final entry in domainsRaw) {
        final value = entry?.toString();
        if (value == null || value.isEmpty) continue;
        domains.add(value);
      }
    } else if (domainsRaw is String && domainsRaw.isNotEmpty) {
      domains.add(domainsRaw);
    }

    return DeityOption(
      id: _string(map['id']) ?? _buildOptionKey(map, _string(map['name']) ?? 'deity'),
      name: _string(map['name']) ?? 'Unknown Deity',
      category: _string(map['category']) ?? 'god',
      domains: domains,
    );
  }

  String _buildOptionKey(Map<String, dynamic> option, String fallBackName) {
    final explicitId = option['id']?.toString();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }
    final name = option['name']?.toString() ?? fallBackName;
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collapsed = normalized.replaceAll(RegExp(r'_+'), '_');
    final stripped = collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
    if (stripped.isEmpty) {
      return fallBackName.toLowerCase();
    }
    return stripped;
  }
}
