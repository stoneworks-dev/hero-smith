/// Data models for the coin purse system.
library;

import '../../../core/theme/main_stats_theme.dart';

/// Represents a single coin type with its name, quantity, and multiplier (value per coin).
class Coin {
  final String id;
  final String name;
  final int quantity; // Number of coins
  final double multiplier; // Value per coin
  final int colorValue; // Color for the card (stored as int)

  Coin({
    String? id,
    required this.name,
    required this.quantity,
    this.multiplier = 1.0,
    this.colorValue = 0xFFFFD54F, // Default amber (MainStatsTheme.coinColors[0])
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Calculate the total value of this coin (quantity * multiplier)
  double get totalValue => quantity * multiplier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'multiplier': multiplier,
        'colorValue': colorValue,
      };

  factory Coin.fromJson(Map<String, dynamic> json) {
    final mult = json['multiplier'];
    return Coin(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      multiplier: mult is num ? mult.toDouble() : 1.0,
      colorValue: json['colorValue'] as int? ?? 0xFFFFD54F, // Default amber (MainStatsTheme.coinColors[0])
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coin &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          multiplier == other.multiplier &&
          colorValue == other.colorValue;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ quantity.hashCode ^ multiplier.hashCode ^ colorValue.hashCode;
}

/// Represents a collection of coins in the purse.
class CoinPurse {
  final List<Coin> coins;

  const CoinPurse({this.coins = const []});

  /// Calculate the total value of all coins in the purse (quantity * multiplier for each)
  double get totalValue => coins.fold(0.0, (sum, coin) => sum + coin.totalValue);

  /// Add a new coin to the purse
  CoinPurse addCoin(Coin coin) {
    return CoinPurse(coins: [...coins, coin]);
  }

  /// Remove a coin at a specific index
  CoinPurse removeCoin(int index) {
    if (index < 0 || index >= coins.length) return this;
    final newCoins = List<Coin>.from(coins);
    newCoins.removeAt(index);
    return CoinPurse(coins: newCoins);
  }

  /// Update a coin at a specific index
  CoinPurse updateCoin(int index, Coin coin) {
    if (index < 0 || index >= coins.length) return this;
    final newCoins = List<Coin>.from(coins);
    newCoins[index] = coin;
    return CoinPurse(coins: newCoins);
  }

  /// Reorder coins within the purse.
  CoinPurse reorderCoins(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= coins.length) return this;
    if (newIndex < 0 || newIndex > coins.length) return this;

    final newCoins = List<Coin>.from(coins);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = newCoins.removeAt(oldIndex);
    newCoins.insert(newIndex, moved);
    return CoinPurse(coins: newCoins);
  }

  Map<String, dynamic> toJson() => {
        'coins': coins.map((c) => c.toJson()).toList(),
      };

  factory CoinPurse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CoinPurse();
    final coinList = json['coins'] as List<dynamic>? ?? [];
    return CoinPurse(
      coins: coinList
          .map((c) => Coin.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoinPurse &&
          runtimeType == other.runtimeType &&
          _listEquals(coins, other.coins);

  @override
  int get hashCode => coins.fold(0, (hash, coin) => hash ^ coin.hashCode);

  static bool _listEquals(List<Coin> a, List<Coin> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
