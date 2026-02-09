import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_service.dart';

/// Singleton [UpdateService] instance.
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Manages the user's preference for suppressing update prompts.
final updatePreferencesProvider =
    AsyncNotifierProvider<UpdatePreferences, bool>(UpdatePreferences.new);

/// Whether to show the update dialog on startup.
///
/// Combines the user preference with whether an update is actually available.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  final showPrompts = await ref.watch(updatePreferencesProvider.future);
  if (!showPrompts) return null;

  final service = ref.read(updateServiceProvider);
  return service.checkForUpdate();
});

/// Force-check for updates regardless of preference (used from About page).
final forceUpdateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  final service = ref.read(updateServiceProvider);
  return service.checkForUpdate();
});

/// Manages the "don't show update prompts" preference via SharedPreferences.
class UpdatePreferences extends AsyncNotifier<bool> {
  static const String _key = 'show_update_prompts';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    // Default: show prompts (true).
    return prefs.getBool(_key) ?? true;
  }

  /// Sets whether update prompts should be shown on startup.
  Future<void> setShowPrompts(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, show);
    state = AsyncData(show);
  }

  /// Toggle the current preference.
  Future<void> toggle() async {
    final current = state.valueOrNull ?? true;
    await setShowPrompts(!current);
  }
}
