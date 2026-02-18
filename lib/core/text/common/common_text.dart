/// Shared UI strings used across multiple features.
///
/// Reference these instead of duplicating common action words
/// in individual text classes.
class CommonText {
  CommonText._();

  // ── Actions ──────────────────────────────────────────────
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String delete = 'Delete';
  static const String remove = 'Remove';
  static const String save = 'Save';
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String create = 'Create';
  static const String search = 'Search';
  static const String done = 'Done';
  static const String confirm = 'Confirm';
  static const String apply = 'Apply';
  static const String ok = 'OK';

  // ── States ───────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String none = 'None';
  static const String error = 'Error';
  static const String noResults = 'No results found';

  // ── Prompts ──────────────────────────────────────────────
  static const String areYouSure = 'Are you sure?';
  static const String unsavedChanges = 'You have unsaved changes.';
}
