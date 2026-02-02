import 'package:drift/drift.dart';
import '../db/app_database.dart' as db;

String _generateId() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      '_' +
      (DateTime.now().microsecond % 1000).toString();
}

enum NoteSortOrder {
  newestFirst,
  oldestFirst,
  alphabetical,
}

/// Repository for managing hero notes and folders
class HeroNotesRepository {
  final db.AppDatabase _db;

  HeroNotesRepository(this._db);

  // ========== Fetch Operations ==========

  /// Get all notes and folders for a hero at root level (folderId == null)
  Future<List<HeroNote>> getRootItems(String heroId, {NoteSortOrder sortOrder = NoteSortOrder.newestFirst}) async {
    final query = _db.select(_db.heroNotes)
      ..where((t) => t.heroId.equals(heroId) & t.folderId.isNull());

    final rows = await query.get();
    return _sortNotes(rows.map(_noteFromRow).toList(), sortOrder);
  }

  /// Get all notes within a specific folder
  Future<List<HeroNote>> getNotesInFolder(String folderId, {NoteSortOrder sortOrder = NoteSortOrder.newestFirst}) async {
    final query = _db.select(_db.heroNotes)
      ..where((t) => t.folderId.equals(folderId) & t.isFolder.equals(false));

    final rows = await query.get();
    return _sortNotes(rows.map(_noteFromRow).toList(), sortOrder);
  }

  /// Get a specific note or folder by ID
  Future<HeroNote?> getNote(String noteId) async {
    final row = await (_db.select(_db.heroNotes)
          ..where((t) => t.id.equals(noteId)))
        .getSingleOrNull();

    return row != null ? _noteFromRow(row) : null;
  }

  /// Search notes by text (case-insensitive, searches title and content)
  Future<List<HeroNote>> searchNotes(String heroId, String searchText) async {
    if (searchText.trim().isEmpty) {
      return [];
    }

    final searchPattern = '%${searchText.toLowerCase()}%';
    
    // Custom query using LOWER() for case-insensitive search
    final rows = await _db.customSelect(
      '''
      SELECT * FROM hero_notes 
      WHERE hero_id = ? 
        AND is_folder = 0
        AND (LOWER(title) LIKE ? OR LOWER(content) LIKE ?)
      ORDER BY updated_at DESC
      ''',
      variables: [
        Variable<String>(heroId),
        Variable<String>(searchPattern),
        Variable<String>(searchPattern),
      ],
      readsFrom: {_db.heroNotes},
    ).get();

    return rows.map((row) {
      return HeroNote(
        id: row.read<String>('id'),
        heroId: row.read<String>('hero_id'),
        title: row.read<String>('title'),
        content: row.read<String>('content'),
        folderId: row.read<String?>('folder_id'),
        isFolder: row.read<bool>('is_folder'),
        sortOrder: row.read<int>('sort_order'),
        createdAt: row.read<DateTime>('created_at'),
        updatedAt: row.read<DateTime>('updated_at'),
      );
    }).toList();
  }

  // ========== Create Operations ==========

  /// Create a new folder at root level or inside another folder
  Future<String> createFolder({
    required String heroId,
    required String title,
    String? parentFolderId,
  }) async {
    final id = _generateId();
    final now = DateTime.now();

    // Get the max sort order for the target location
    final maxSortOrder = await _getMaxSortOrder(heroId, parentFolderId);

    await _db.into(_db.heroNotes).insert(
      db.HeroNotesCompanion.insert(
        id: id,
        heroId: heroId,
        title: title,
        content: const Value(''),
        folderId: Value(parentFolderId),
        isFolder: const Value(true),
        sortOrder: Value(maxSortOrder + 1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return id;
  }

  /// Create a new note at root level or inside a folder
  Future<String> createNote({
    required String heroId,
    required String title,
    String content = '',
    String? folderId,
  }) async {
    final id = _generateId();
    final now = DateTime.now();

    // Get the max sort order for the target location
    final maxSortOrder = await _getMaxSortOrder(heroId, folderId);

    await _db.into(_db.heroNotes).insert(
      db.HeroNotesCompanion.insert(
        id: id,
        heroId: heroId,
        title: title,
        content: Value(content),
        folderId: Value(folderId),
        isFolder: const Value(false),
        sortOrder: Value(maxSortOrder + 1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return id;
  }

  // ========== Update Operations ==========

  /// Update note title and/or content
  Future<void> updateNote({
    required String noteId,
    String? title,
    String? content,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;

    if (updates.isEmpty) return;

    await (_db.update(_db.heroNotes)
          ..where((t) => t.id.equals(noteId)))
        .write(
      db.HeroNotesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        content: content != null ? Value(content) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update folder title
  Future<void> updateFolderTitle(String folderId, String newTitle) async {
    await (_db.update(_db.heroNotes)
          ..where((t) => t.id.equals(folderId)))
        .write(
      db.HeroNotesCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Move a note to a different folder (or to root level if folderId is null)
  Future<void> moveNote(String noteId, String? newFolderId) async {
    final note = await getNote(noteId);
    if (note == null || note.isFolder) return; // Can't move folders

    // Get max sort order in destination
    final maxSortOrder = await _getMaxSortOrder(note.heroId, newFolderId);

    await (_db.update(_db.heroNotes)
          ..where((t) => t.id.equals(noteId)))
        .write(
      db.HeroNotesCompanion(
        folderId: Value(newFolderId),
        sortOrder: Value(maxSortOrder + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update sort order for a note/folder
  Future<void> updateSortOrder(String noteId, int newSortOrder) async {
    await (_db.update(_db.heroNotes)
          ..where((t) => t.id.equals(noteId)))
        .write(
      db.HeroNotesCompanion(
        sortOrder: Value(newSortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ========== Delete Operations ==========

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    await (_db.delete(_db.heroNotes)
          ..where((t) => t.id.equals(noteId)))
        .go();
  }

  /// Delete a folder and all notes inside it
  Future<void> deleteFolder(String folderId) async {
    await _db.transaction(() async {
      // Delete all notes in the folder
      await (_db.delete(_db.heroNotes)
            ..where((t) => t.folderId.equals(folderId)))
          .go();

      // Delete the folder itself
      await (_db.delete(_db.heroNotes)
            ..where((t) => t.id.equals(folderId)))
          .go();
    });
  }

  // ========== Helper Methods ==========

  /// Get the maximum sort order for a given location (heroId + folderId)
  Future<int> _getMaxSortOrder(String heroId, String? folderId) async {
    final query = folderId == null
        ? (_db.selectOnly(_db.heroNotes)
          ..addColumns([_db.heroNotes.sortOrder.max()])
          ..where(_db.heroNotes.heroId.equals(heroId) & _db.heroNotes.folderId.isNull()))
        : (_db.selectOnly(_db.heroNotes)
          ..addColumns([_db.heroNotes.sortOrder.max()])
          ..where(_db.heroNotes.folderId.equals(folderId)));

    final result = await query.getSingleOrNull();
    return result?.read(_db.heroNotes.sortOrder.max()) ?? 0;
  }

  /// Convert database row to HeroNote model
  HeroNote _noteFromRow(db.HeroNote row) {
    return HeroNote(
      id: row.id,
      heroId: row.heroId,
      title: row.title,
      content: row.content,
      folderId: row.folderId,
      isFolder: row.isFolder,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Sort notes based on sort order preference
  List<HeroNote> _sortNotes(List<HeroNote> notes, NoteSortOrder sortOrder) {
    switch (sortOrder) {
      case NoteSortOrder.newestFirst:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOrder.oldestFirst:
        notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSortOrder.alphabetical:
        notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return notes;
  }
}

/// Simple model class for hero notes
class HeroNote {
  final String id;
  final String heroId;
  final String title;
  final String content;
  final String? folderId;
  final bool isFolder;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  HeroNote({
    required this.id,
    required this.heroId,
    required this.title,
    required this.content,
    this.folderId,
    required this.isFolder,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  HeroNote copyWith({
    String? title,
    String? content,
    String? folderId,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return HeroNote(
      id: id,
      heroId: heroId,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      isFolder: isFolder,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
