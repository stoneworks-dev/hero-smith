import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/minion_squad_instance.dart';

/// Thrown when a hero already has the maximum number of active minion
/// squads (2, per the Summoner rules) and another is requested.
class SquadLimitExceededError extends StateError {
  SquadLimitExceededError() : super('A hero can have at most 2 active minion squads');
}

/// Repository for CRUD operations on hero minion squad instances.
///
/// Unlike [CompanionRepository]/[RetainerRepository] (each hero has at most
/// one active row, enforced by deactivating any prior row on add), a hero
/// can have **up to 2** concurrent active squads — enforced here in
/// [addSquad] by counting existing active rows rather than replacing them.
class MinionRepository {
  MinionRepository(this._db);
  final AppDatabase _db;

  static const maxActiveSquads = 2;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Watch all active minion squads for a hero (0-2).
  Stream<List<MinionSquadInstance>> watchSquadsForHero(String heroId) {
    return (_db.select(_db.heroMinionSquads)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  /// Get a squad by its instance ID.
  Future<MinionSquadInstance?> getById(String id) async {
    final row = await (_db.select(_db.heroMinionSquads)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Add a minion squad to a hero. Returns the new instance ID.
  ///
  /// Throws [SquadLimitExceededError] if the hero already has
  /// [maxActiveSquads] active squads — callers should check
  /// [watchSquadsForHero]'s current length before offering the "Add Squad"
  /// action, but this guards the invariant directly regardless.
  Future<String> addSquad({
    required String heroId,
    required String minionComponentId,
    required String squadName,
    int memberCount = 1,
  }) async {
    final activeCount = await (_db.select(_db.heroMinionSquads)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .get()
        .then((rows) => rows.length);
    if (activeCount >= maxActiveSquads) {
      throw SquadLimitExceededError();
    }

    final id = _generateId();
    final now = DateTime.now();
    await _db.into(_db.heroMinionSquads).insert(
          HeroMinionSquadsCompanion.insert(
            id: id,
            heroId: heroId,
            minionComponentId: minionComponentId,
            squadName: squadName,
            memberCount: Value(memberCount),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  /// Remove a squad instance by ID.
  Future<int> removeSquad(String id) {
    return (_db.delete(_db.heroMinionSquads)..where((t) => t.id.equals(id)))
        .go();
  }

  /// Update a squad's name.
  Future<void> updateName(String id, String squadName) async {
    await (_db.update(_db.heroMinionSquads)..where((t) => t.id.equals(id)))
        .write(HeroMinionSquadsCompanion(
      squadName: Value(squadName),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update combat state (member count, current stamina, temp stamina).
  Future<void> updateCombatState(
    String id, {
    int? memberCount,
    int? currentStamina,
    int? tempStamina,
  }) async {
    await (_db.update(_db.heroMinionSquads)..where((t) => t.id.equals(id)))
        .write(HeroMinionSquadsCompanion(
      memberCount:
          memberCount != null ? Value(memberCount) : const Value.absent(),
      currentStamina: currentStamina != null
          ? Value(currentStamina)
          : const Value.absent(),
      tempStamina:
          tempStamina != null ? Value(tempStamina) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  MinionSquadInstance _fromRow(HeroMinionSquad row) {
    return MinionSquadInstance(
      id: row.id,
      heroId: row.heroId,
      minionComponentId: row.minionComponentId,
      squadName: row.squadName,
      memberCount: row.memberCount,
      currentStamina: row.currentStamina,
      tempStamina: row.tempStamina,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'minionsquad_${ts}_$_idCounter';
  }
}
