/// Utility helpers for keeping component selections unique across widgets.
class ComponentSelectionGuard {
  /// Returns true when [candidateId] is blocked by [reservedIds], unless it
  /// matches the [currentId] being edited (current selections stay visible).
  static bool isBlocked(
    String? candidateId,
    Set<String> reservedIds, {
    String? currentId,
  }) {
    if (candidateId == null || candidateId.isEmpty) return false;
    if (currentId != null && candidateId == currentId) return false;
    return reservedIds.contains(candidateId);
  }

  /// Filters [options] by removing any whose id (via [idSelector]) is blocked.
  static List<T> filterAllowed<T>({
    required Iterable<T> options,
    required Set<String> reservedIds,
    required String Function(T option) idSelector,
    String? currentId,
  }) {
    if (reservedIds.isEmpty) return List<T>.from(options);
    return options
        .where(
          (option) =>
              !isBlocked(idSelector(option), reservedIds, currentId: currentId),
        )
        .toList();
  }

  /// Clears any selected values that are now blocked. Returns true when a
  /// change was made so callers can emit callbacks conditionally.
  static bool pruneBlockedSelections(
    Map<String, List<String?>> selections,
    Set<String> reservedIds, {
    Set<String> allowIds = const <String>{},
  }) {
    var changed = false;
    if (reservedIds.isEmpty) return false;
    for (final slots in selections.values) {
      for (var i = 0; i < slots.length; i++) {
        final value = slots[i];
        if (value != null &&
            !allowIds.contains(value) &&
            isBlocked(value, reservedIds)) {
          slots[i] = null;
          changed = true;
        }
      }
    }
    return changed;
  }
}
