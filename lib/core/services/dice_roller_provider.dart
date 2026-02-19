import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final diceRollerPreferencesProvider =
    AsyncNotifierProvider<DiceRollerPreferences, bool>(
      DiceRollerPreferences.new,
    );

class DiceRollerPreferences extends AsyncNotifier<bool> {
  static const String _key = 'show_global_dice_roller';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, visible);
    state = AsyncData(visible);
  }
}
