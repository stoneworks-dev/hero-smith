import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A single psi boost option with its cost and effect.
class PsiBoost {
  final String id;
  final String name;
  final int cost;
  final String effect;

  const PsiBoost({
    required this.id,
    required this.name,
    required this.cost,
    required this.effect,
  });

  factory PsiBoost.fromJson(Map<String, dynamic> json) {
    return PsiBoost(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: json['cost'] as int,
      effect: json['effect'] as String,
    );
  }
}

/// Data for the Psi Boost feature, including all available boosts.
class PsiBoostData {
  final String id;
  final String name;
  final String description;
  final List<PsiBoost> boosts;

  const PsiBoostData({
    required this.id,
    required this.name,
    required this.description,
    required this.boosts,
  });

  factory PsiBoostData.fromJson(Map<String, dynamic> json) {
    final boostsList = (json['boosts'] as List<dynamic>)
        .map((b) => PsiBoost.fromJson(b as Map<String, dynamic>))
        .toList();

    return PsiBoostData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      boosts: boostsList,
    );
  }

  /// Get all boosts that are affordable with the given resource.
  List<PsiBoost> getAffordableBoosts(int currentResource) {
    return boosts.where((b) => b.cost <= currentResource).toList();
  }

  /// Get boosts grouped by cost tier (1, 3, 5).
  Map<int, List<PsiBoost>> getBoostsByCost() {
    final result = <int, List<PsiBoost>>{};
    for (final boost in boosts) {
      result.putIfAbsent(boost.cost, () => []).add(boost);
    }
    return result;
  }
}

/// Service for loading and caching Psi Boost data.
class PsiBoostService {
  static PsiBoostService? _instance;
  PsiBoostData? _cachedData;

  PsiBoostService._();

  factory PsiBoostService() => _instance ??= PsiBoostService._();

  /// Load the psi boost data from the asset.
  Future<PsiBoostData> loadPsiBoostData() async {
    if (_cachedData != null) return _cachedData!;

    final jsonString = await rootBundle.loadString('data/features/psi_boost.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    _cachedData = PsiBoostData.fromJson(json);
    return _cachedData!;
  }

  /// Clear the cache (useful for testing).
  void clearCache() {
    _cachedData = null;
  }
}
