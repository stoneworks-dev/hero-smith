import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/retainer_instance.dart';

/// Repository for CRUD operations on hero retainer instances.
class RetainerRepository {
  RetainerRepository(this._db);
  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Watch the active retainer for a hero (at most one).
  Stream<RetainerInstance?> watchRetainerForHero(String heroId) {
    return (_db.select(_db.heroRetainers)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row));
  }

  /// Get the active retainer for a hero (one-shot).
  Future<RetainerInstance?> getRetainerForHero(String heroId) async {
    final row = await (_db.select(_db.heroRetainers)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Get a retainer by its instance ID.
  Future<RetainerInstance?> getById(String id) async {
    final row = await (_db.select(_db.heroRetainers)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Watch all retainers for a hero (active and inactive).
  Stream<List<RetainerInstance>> watchAllForHero(String heroId) {
    return (_db.select(_db.heroRetainers)
          ..where((t) => t.heroId.equals(heroId)))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Add a retainer to a hero. Returns the new instance ID.
  ///
  /// Deactivates any existing active retainer for this hero first, so a hero
  /// never ends up with more than one active row — [watchRetainerForHero]
  /// assumes at most one and throws otherwise. This guards the invariant
  /// directly instead of relying on every caller to pass the right
  /// `replaceId`/remove the old one first (e.g. a double-tapped "Add"
  /// button from the empty state, which has no replaceId to pass).
  Future<String> addRetainer({
    required String heroId,
    required String retainerComponentId,
    required String name,
    required String role,
    bool isCustom = false,
    Map<String, dynamic>? customData,
    int startingLevel = 1,
  }) async {
    await (_db.update(_db.heroRetainers)
          ..where((t) => t.heroId.equals(heroId) & t.isActive.equals(true)))
        .write(const HeroRetainersCompanion(isActive: Value(false)));

    final id = _generateId();
    final now = DateTime.now();
    await _db.into(_db.heroRetainers).insert(
          HeroRetainersCompanion.insert(
            id: id,
            heroId: heroId,
            retainerComponentId: retainerComponentId,
            name: name,
            role: role,
            isCustom: Value(isCustom),
            customDataJson: Value(
              customData != null ? jsonEncode(customData) : null,
            ),
            level: Value(startingLevel),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  /// Set the retainer's own tracked level directly (clamped to 1-10).
  /// Retainers level independently of their hero.
  Future<void> setLevel(String id, int level) async {
    await (_db.update(_db.heroRetainers)..where((t) => t.id.equals(id)))
        .write(HeroRetainersCompanion(
      level: Value(level.clamp(1, 10)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Remove a retainer instance by ID.
  Future<int> removeRetainer(String id) {
    return (_db.delete(_db.heroRetainers)..where((t) => t.id.equals(id))).go();
  }

  /// Remove all retainers for a hero.
  Future<int> removeAllForHero(String heroId) {
    return (_db.delete(_db.heroRetainers)
          ..where((t) => t.heroId.equals(heroId)))
        .go();
  }

  /// Update a retainer's name.
  Future<void> updateName(String id, String name) async {
    await (_db.update(_db.heroRetainers)..where((t) => t.id.equals(id)))
        .write(HeroRetainersCompanion(
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Store a chosen advancement ability at a given level (4, 7, or 10).
  Future<void> setAdvancementChoice(
    String id, {
    required int level,
    required String abilityId,
  }) async {
    final instance = await getById(id);
    if (instance == null) return;
    final updated = Map<int, String>.from(instance.advancementChoices)
      ..[level] = abilityId;
    await (_db.update(_db.heroRetainers)..where((t) => t.id.equals(id)))
        .write(HeroRetainersCompanion(
      advancementChoicesJson:
          Value(RetainerInstance.encodeIntStringMap(updated)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Store a chosen characteristic bump at a given level (2 or 8).
  Future<void> setCharacteristicChoice(
    String id, {
    required int level,
    required String characteristic,
  }) async {
    final instance = await getById(id);
    if (instance == null) return;
    final updated = Map<int, String>.from(instance.characteristicChoices)
      ..[level] = characteristic;
    await (_db.update(_db.heroRetainers)..where((t) => t.id.equals(id)))
        .write(HeroRetainersCompanion(
      characteristicChoicesJson:
          Value(RetainerInstance.encodeIntStringMap(updated)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update combat state (current stamina, temp stamina, recoveries).
  Future<void> updateCombatState(
    String id, {
    int? currentStamina,
    int? tempStamina,
    int? currentRecoveries,
  }) async {
    await (_db.update(_db.heroRetainers)..where((t) => t.id.equals(id)))
        .write(HeroRetainersCompanion(
      currentStamina: currentStamina != null
          ? Value(currentStamina)
          : const Value.absent(),
      tempStamina:
          tempStamina != null ? Value(tempStamina) : const Value.absent(),
      currentRecoveries: currentRecoveries != null
          ? Value(currentRecoveries)
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  RetainerInstance _fromRow(HeroRetainer row) {
    return RetainerInstance(
      id: row.id,
      heroId: row.heroId,
      retainerComponentId: row.retainerComponentId,
      name: row.name,
      role: row.role,
      isCustom: row.isCustom,
      customData: row.customDataJson != null
          ? jsonDecode(row.customDataJson!) as Map<String, dynamic>
          : null,
      advancementChoices:
          RetainerInstance.decodeIntStringMap(row.advancementChoicesJson),
      characteristicChoices:
          RetainerInstance.decodeIntStringMap(row.characteristicChoicesJson),
      level: row.level,
      currentStamina: row.currentStamina,
      tempStamina: row.tempStamina,
      currentRecoveries: row.currentRecoveries ?? RetainerInstance.maxRecoveries,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'ret_${ts}_$_idCounter';
  }
}
