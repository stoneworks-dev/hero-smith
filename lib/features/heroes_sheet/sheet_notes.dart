import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/app_database.dart';
import '../../core/repositories/hero_notes_repository.dart' as notes_repo;
import '../../core/text/heroes_sheet/sheet_notes_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icon_data.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/hero_sheet_theme.dart';

// Provider for the notes repository
final heroNotesRepositoryProvider =
    Provider<notes_repo.HeroNotesRepository>((ref) {
  return notes_repo.HeroNotesRepository(AppDatabase.instance);
});

/// Notes page for hero sheet - mobile-friendly list view with page navigation
class SheetNotes extends ConsumerStatefulWidget {
  const SheetNotes({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<SheetNotes> createState() => _SheetNotesState();
}

class _SheetNotesState extends ConsumerState<SheetNotes> {
  String? _currentFolderId; // null = root level
  notes_repo.NoteSortOrder _sortOrder = notes_repo.NoteSortOrder.newestFirst;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createNewNote() async {
    final noteId = await ref.read(heroNotesRepositoryProvider).createNote(
          heroId: widget.heroId,
          title: SheetNotesText.untitledNote,
          content: '',
          folderId: _currentFolderId,
        );

    if (!mounted) return;

    // Navigate to note editor
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteEditorPage(
          heroId: widget.heroId,
          noteId: noteId,
          isNewNote: true,
        ),
      ),
    );

    setState(() {}); // Refresh list
  }

  Future<void> _createNewFolder() async {
    final name = await _showTextInputDialog(
      context: context,
      title: SheetNotesText.createFolderDialogTitle,
      hint: SheetNotesText.createFolderDialogHint,
      initialValue: SheetNotesText.createFolderInitialValue,
    );

    if (name == null || name.trim().isEmpty) return;

    await ref.read(heroNotesRepositoryProvider).createFolder(
          heroId: widget.heroId,
          title: name.trim(),
          parentFolderId: null, // Flat structure - folders only at root
        );

    setState(() {});
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: SheetNotesText.deleteNoteDialogTitle,
      message: SheetNotesText.deleteNoteDialogMessage,
    );

    if (!confirmed) return;

    await ref.read(heroNotesRepositoryProvider).deleteNote(noteId);
    setState(() {});
  }

  Future<void> _renameFolder(String folderId, String currentName) async {
    final newName = await _showTextInputDialog(
      context: context,
      title: SheetNotesText.renameFolderDialogTitle,
      hint: SheetNotesText.createFolderDialogHint,
      initialValue: currentName,
    );

    if (newName == null || newName.trim().isEmpty || newName.trim() == currentName) return;

    await ref.read(heroNotesRepositoryProvider).updateFolderTitle(
          folderId,
          newName.trim(),
        );

    setState(() {});
  }

  Future<void> _deleteFolder(String folderId) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: SheetNotesText.deleteFolderDialogTitle,
      message: SheetNotesText.deleteFolderDialogMessage,
    );

    if (!confirmed) return;

    await ref.read(heroNotesRepositoryProvider).deleteFolder(folderId);

    if (_currentFolderId == folderId) {
      setState(() {
        _currentFolderId = null;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _openNote(notes_repo.HeroNote note) async {
    if (note.isFolder) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteEditorPage(
          heroId: widget.heroId,
          noteId: note.id,
          isNewNote: false,
        ),
      ),
    );

    setState(() {}); // Refresh list in case note was modified
  }

  void _openFolder(String folderId) {
    setState(() {
      _currentFolderId = folderId;
    });
  }

  void _navigateBack() {
    setState(() {
      _currentFolderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FormTheme.borderDim),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HeroSheetTheme.notesAccent.withAlpha(38),
                  HeroSheetTheme.notesAccent.withAlpha(10),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeroSheetTheme.notesAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      AppIcon(AppIcons.notes.topHeader, color: HeroSheetTheme.notesAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentFolderId != null
                            ? 'In folder'
                            : 'Your adventure journal',
                        style: TextStyle(
                            color: FormTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: FormTheme.textBright),
              decoration: InputDecoration(
                hintText: SheetNotesText.searchHint,
                hintStyle: TextStyle(color: FormTheme.textMuted),
                prefixIcon: Icon(Icons.search, color: FormTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: FormTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: NavigationTheme.cardBackgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: FormTheme.borderDim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: FormTheme.borderDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.trim().isNotEmpty;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Sort options (hide when searching)
          if (!_isSearching && _currentFolderId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSortChip(SheetNotesText.sortNewestFirst,
                      notes_repo.NoteSortOrder.newestFirst),
                  const SizedBox(width: 8),
                  _buildSortChip(SheetNotesText.sortOldestFirst,
                      notes_repo.NoteSortOrder.oldestFirst),
                  const SizedBox(width: 8),
                  _buildSortChip(SheetNotesText.sortAlphabetical,
                      notes_repo.NoteSortOrder.alphabetical),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Notes and folders list
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildNotesList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentFolderId == null) // Only show folder button at root
            FloatingActionButton.small(
              heroTag: 'createFolder',
              onPressed: _createNewFolder,
              tooltip: SheetNotesText.fabCreateFolderTooltip,
              backgroundColor: NavigationTheme.cardBackgroundDark,
              foregroundColor: HeroSheetTheme.notesAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
              ),
              child: AppIcon(AppIcons.notes.folderHeader, color: HeroSheetTheme.notesAccent, size: 24),
            ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'createNote',
            onPressed: _createNewNote,
            tooltip: SheetNotesText.fabCreateNoteTooltip,
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: HeroSheetTheme.notesAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
            ),
            child: AppIcon(AppIcons.notes.noteHeader, color: HeroSheetTheme.notesAccent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, notes_repo.NoteSortOrder order) {
    final isSelected = _sortOrder == order;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOrder = order;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? HeroSheetTheme.notesAccent.withAlpha(51)
              : NavigationTheme.cardBackgroundDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? HeroSheetTheme.notesAccent : FormTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? HeroSheetTheme.notesAccent : FormTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final repo = ref.read(heroNotesRepositoryProvider);
    return FutureBuilder<List<notes_repo.HeroNote>>(
      future: repo.searchNotes(widget.heroId, _searchController.text),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: HeroSheetTheme.notesAccent));
        }

        final notes = snapshot.data!;
        if (notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: FormTheme.borderLight),
                  const SizedBox(height: 16),
                  Text(
                    SheetNotesText.searchNoMatches,
                    style: TextStyle(color: FormTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildNoteCard(note);
          },
        );
      },
    );
  }

  Widget _buildNotesList() {
    final repo = ref.read(heroNotesRepositoryProvider);

    if (_currentFolderId != null) {
      // Show notes in folder with back button
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FormTheme.borderDim),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: HeroSheetTheme.notesAccent.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    const Icon(Icons.arrow_back, color: HeroSheetTheme.notesAccent, size: 20),
              ),
              title: const Text(
                SheetNotesText.backToNotes,
                style:
                    TextStyle(color: FormTheme.textBright, fontWeight: FontWeight.w500),
              ),
              onTap: _navigateBack,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<notes_repo.HeroNote>>(
              future: repo.getNotesInFolder(_currentFolderId!,
                  sortOrder: _sortOrder),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: HeroSheetTheme.notesAccent));
                }

                final notes = snapshot.data!;
                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open,
                              size: 48, color: FormTheme.borderLight),
                          const SizedBox(height: 16),
                          Text(
                            SheetNotesText.folderEmpty,
                            style: TextStyle(color: FormTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(note);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // Show root level items (folders and notes without folder)
    return FutureBuilder<List<notes_repo.HeroNote>>(
      future: repo.getRootItems(widget.heroId, sortOrder: _sortOrder),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: HeroSheetTheme.notesAccent));
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add, size: 64, color: FormTheme.borderLight),
                  const SizedBox(height: 16),
                  Text(
                    SheetNotesText.rootEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: FormTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewNote,
                    icon: const Icon(Icons.add),
                    label: const Text(SheetNotesText.fabCreateNoteTooltip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HeroSheetTheme.notesAccent,
                      foregroundColor: FormTheme.textBright,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Separate folders and notes
        final folders = items.where((item) => item.isFolder).toList();
        final notes = items.where((item) => !item.isFolder).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (folders.isNotEmpty) ...[
              _buildSectionHeader(SheetNotesText.sectionFolders, AppIcons.notes.folderHeader),
              ...folders.map((folder) => _buildFolderCard(folder)),
              if (notes.isNotEmpty) const SizedBox(height: 16),
            ],
            if (notes.isNotEmpty) ...[
              _buildSectionHeader(SheetNotesText.sectionNotes, AppIcons.notes.noteHeader),
              ...notes.map((note) => _buildNoteCard(note)),
            ],
            const SizedBox(height: 80), // Space for FAB
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, AppIconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: HeroSheetTheme.notesAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          AppIcon(icon, size: 16, color: HeroSheetTheme.notesAccent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: HeroSheetTheme.notesAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCard(notes_repo.HeroNote folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openFolder(folder.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HeroSheetTheme.notesAccent.withAlpha(38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(AppIcons.notes.folder, size: 28, color: HeroSheetTheme.notesAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: FormTheme.textBright,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: FormTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            SheetNotesText.created(
                                _formatDate(folder.createdAt)),
                            style: TextStyle(
                                fontSize: 12, color: FormTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: HeroSheetTheme.notesAccent),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: FormTheme.textMuted),
                  onPressed: () => _renameFolder(folder.id, folder.title),
                  tooltip: SheetNotesText.tooltipRenameFolder,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: FormTheme.textMuted),
                  onPressed: () => _deleteFolder(folder.id),
                  tooltip: SheetNotesText.tooltipDeleteFolder,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(notes_repo.HeroNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openNote(note),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeroSheetTheme.notesAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIcon(AppIcons.notes.note,
                      size: 24, color: HeroSheetTheme.notesAccent.withAlpha(179)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: FormTheme.textBright,
                        ),
                      ),
                      if (note.content.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: FormTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.update,
                              size: 12, color: FormTheme.borderLight),
                          const SizedBox(width: 4),
                          Text(
                            SheetNotesText.updated(_formatDate(note.updatedAt)),
                            style: TextStyle(
                                fontSize: 11, color: FormTheme.borderLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: FormTheme.textMuted),
                  onPressed: () => _deleteNote(note.id),
                  tooltip: SheetNotesText.tooltipDeleteNote,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return SheetNotesText.dateJustNow;
        return SheetNotesText.dateMinutesAgo(diff.inMinutes);
      }
      return SheetNotesText.dateHoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return SheetNotesText.dateYesterday;
    } else if (diff.inDays < 7) {
      return SheetNotesText.dateDaysAgo(diff.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Separate page for editing a note
class _NoteEditorPage extends ConsumerStatefulWidget {
  const _NoteEditorPage({
    required this.heroId,
    required this.noteId,
    required this.isNewNote,
  });

  final String heroId;
  final String noteId;
  final bool isNewNote;

  @override
  ConsumerState<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<_NoteEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  Future<void> _loadNote() async {
    final repo = ref.read(heroNotesRepositoryProvider);
    final note = await repo.getNote(widget.noteId);

    if (note == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _isLoading = false;
      _isDirty = false;
    });
  }

  Future<void> _saveNote() async {
    final repo = ref.read(heroNotesRepositoryProvider);
    await repo.updateNote(
      noteId: widget.noteId,
      title: _titleController.text.trim().isEmpty
          ? SheetNotesText.untitledNote
          : _titleController.text.trim(),
      content: _contentController.text,
    );

    setState(() {
      _isDirty = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SheetNotesText.noteSavedSnack),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_isDirty) {
      await _saveNote();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NavigationTheme.navBarBackground,
        body:
            const Center(child: CircularProgressIndicator(color: HeroSheetTheme.notesAccent)),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: NavigationTheme.navBarBackground,
        appBar: AppBar(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          foregroundColor: FormTheme.textBright,
          title: const Text(SheetNotesText.editNoteTitle),
          actions: [
            if (_isDirty)
              IconButton(
                icon: const Icon(Icons.save, color: HeroSheetTheme.notesAccent),
                tooltip: SheetNotesText.saveTooltip,
                onPressed: _saveNote,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: SheetNotesText.fieldTitleLabel,
                  labelStyle: TextStyle(color: FormTheme.textSecondary),
                  filled: true,
                  fillColor: NavigationTheme.cardBackgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: FormTheme.borderDim),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: FormTheme.borderDim),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FormTheme.textBright,
                ),
                cursorColor: HeroSheetTheme.notesAccent,
              ),
              const SizedBox(height: 16),
              // Content field
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: SheetNotesText.fieldContentLabel,
                    labelStyle: TextStyle(color: FormTheme.textSecondary),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: NavigationTheme.cardBackgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: FormTheme.borderDim),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: FormTheme.borderDim),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: FormTheme.textBright,
                    height: 1.5,
                  ),
                  cursorColor: HeroSheetTheme.notesAccent,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper dialog functions
Future<String?> _showTextInputDialog({
  required BuildContext context,
  required String title,
  required String hint,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Text(title, style: const TextStyle(color: FormTheme.textBright)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: FormTheme.textMuted),
            filled: true,
            fillColor: NavigationTheme.navBarBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: FormTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: FormTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: HeroSheetTheme.notesAccent, width: 2),
            ),
          ),
          style: const TextStyle(color: FormTheme.textBright),
          cursorColor: HeroSheetTheme.notesAccent,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              SheetNotesText.actionCancel,
              style: TextStyle(color: FormTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              SheetNotesText.actionCreate,
              style: TextStyle(color: HeroSheetTheme.notesAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool> _showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Text(title, style: const TextStyle(color: FormTheme.textBright)),
        content: Text(message, style: TextStyle(color: FormTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              SheetNotesText.actionCancel,
              style: TextStyle(color: FormTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              SheetNotesText.actionDelete,
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

