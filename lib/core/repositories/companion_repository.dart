import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/companion_instance.dart';

/// Repository for CRUD operations on hero companion instances.
class CompanionRepository {
  CompanionRepository(this._db);
  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Watch the active companion for a hero (at most one).
  Stream<CompanionInstance?> watchCompanionForHero(String heroId) {
    return (_db.select(_db.heroCompanions)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row));
  }

  /// Get the active companion for a hero (one-shot).
  Future<CompanionInstance?> getCompanionForHero(String heroId) async {
    final row = await (_db.select(_db.heroCompanions)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Get a companion by its instance ID.
  Future<CompanionInstance?> getById(String id) async {
    final row = await (_db.select(_db.heroCompanions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Add a companion to a hero. Returns the new instance ID.
  ///
  /// Deactivates any existing active companion for this hero first, so a
  /// hero never ends up with more than one active row — [watchCompanionForHero]
  /// assumes at most one and throws otherwise. This guards the invariant
  /// directly instead of relying on every caller to pass the right
  /// `replaceId`/remove the old one first.
  Future<String> addCompanion({
    required String heroId,
    required String companionComponentId,
    required String name,
  }) async {
    await (_db.update(_db.heroCompanions)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .write(const HeroCompanionsCompanion(isActive: Value(false)));

    final id = _generateId();
    final now = DateTime.now();
    await _db.into(_db.heroCompanions).insert(
          HeroCompanionsCompanion.insert(
            id: id,
            heroId: heroId,
            companionComponentId: companionComponentId,
            name: name,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  /// Remove a companion instance by ID.
  Future<int> removeCompanion(String id) {
    return (_db.delete(_db.heroCompanions)..where((t) => t.id.equals(id)))
        .go();
  }

  /// Update a companion's name.
  Future<void> updateName(String id, String name) async {
    await (_db.update(_db.heroCompanions)..where((t) => t.id.equals(id)))
        .write(HeroCompanionsCompanion(
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update combat state (current stamina, temp stamina). There is no
  /// companion-specific recovery count to update — recoveries are spent from
  /// the hero's own pool (see [CompanionInstance] doc comment).
  Future<void> updateCombatState(
    String id, {
    int? currentStamina,
    int? tempStamina,
  }) async {
    await (_db.update(_db.heroCompanions)..where((t) => t.id.equals(id)))
        .write(HeroCompanionsCompanion(
      currentStamina: currentStamina != null
          ? Value(currentStamina)
          : const Value.absent(),
      tempStamina:
          tempStamina != null ? Value(tempStamina) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Set the companion's current rampage stacks (clamped to 0..24). Adjusted
  /// manually; rampage is a companion resource decoupled from the hero's
  /// heroic-resource generation.
  Future<void> updateRampage(String id, int rampage) async {
    await (_db.update(_db.heroCompanions)..where((t) => t.id.equals(id)))
        .write(HeroCompanionsCompanion(
      currentRampage: Value(rampage.clamp(0, 24)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CompanionInstance _fromRow(HeroCompanion row) {
    return CompanionInstance(
      id: row.id,
      heroId: row.heroId,
      companionComponentId: row.companionComponentId,
      name: row.name,
      currentStamina: row.currentStamina,
      tempStamina: row.tempStamina,
      currentRampage: row.currentRampage,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'comp_${ts}_$_idCounter';
  }
}
