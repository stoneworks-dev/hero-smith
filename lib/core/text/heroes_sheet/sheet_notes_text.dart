class SheetNotesText {
  static const String untitledNote = 'Untitled Note';

  static const String searchHint = 'Search notes...';

  static const String sortByLabel = 'Sort by';
  static const String sortNewestFirst = 'Newest First';
  static const String sortOldestFirst = 'Oldest First';
  static const String sortAlphabetical = 'Alphabetical';

  static const String createFolderDialogTitle = 'Create Folder';
  static const String createFolderDialogHint = 'Folder name';
  static const String createFolderInitialValue = 'New Folder';

  static const String deleteNoteDialogTitle = 'Delete Note';
  static const String deleteNoteDialogMessage =
      'Are you sure you want to delete this note?';

  static const String deleteFolderDialogTitle = 'Delete Folder';
  static const String deleteFolderDialogMessage =
      'Are you sure? This will delete all notes inside this folder.';

  static const String fabCreateFolderTooltip = 'Create Folder';
  static const String fabCreateNoteTooltip = 'Create Note';

  static const String searchNoMatches = 'No matching notes found';

  static const String backToNotes = 'Back to Notes';

  static const String folderEmpty = 'No notes in this folder.\nTap + to create one!';

  static const String rootEmpty =
      'No notes or folders yet.\nTap + to create a note\nor the folder icon to create a folder!';

  static const String sectionFolders = 'FOLDERS';
  static const String sectionNotes = 'NOTES';

  static String created(String formattedDate) => 'Created $formattedDate';
  static String updated(String formattedDate) => 'Updated $formattedDate';

  static const String tooltipDeleteFolder = 'Delete folder';
  static const String tooltipDeleteNote = 'Delete note';

  static const String noteSavedSnack = 'Note saved';

  static const String editNoteTitle = 'Edit Note';
  static const String saveTooltip = 'Save';

  static const String fieldTitleLabel = 'Title';
  static const String fieldContentLabel = 'Content';

  static const String actionCancel = 'Cancel';
  static const String actionCreate = 'Create';
  static const String actionDelete = 'Delete';

  static const String dateJustNow = 'just now';
  static const String dateYesterday = 'yesterday';

  static String dateMinutesAgo(int minutes) => '${minutes}m ago';
  static String dateHoursAgo(int hours) => '${hours}h ago';
  static String dateDaysAgo(int days) => '${days}d ago';
}
