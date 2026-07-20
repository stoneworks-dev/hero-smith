import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final diceRollerPreferencesProvider =
    AsyncNotifierProvider<DiceRollerPreferences, bool>(
      DiceRollerPreferences.new,
    );

class DiceRollerPreferences extends AsyncNotifier<bool> {
  static const String _key = 'show_global_dice_roller';
  static const String _posXKey = 'global_dice_roller_pos_x';
  static const String _posYKey = 'global_dice_roller_pos_y';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  /// Toggling visibility also forgets the saved FAB position, so a roller
  /// stuck somewhere awkward can be rescued by switching it off and on.
  Future<void> setVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, visible);
    await prefs.remove(_posXKey);
    await prefs.remove(_posYKey);
    state = AsyncData(visible);
  }

  Future<Offset?> loadFabPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_posXKey);
    final y = prefs.getDouble(_posYKey);
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  Future<void> saveFabPosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_posXKey, position.dx);
    await prefs.setDouble(_posYKey, position.dy);
  }
}
