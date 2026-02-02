import 'dart:convert';
import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/downtime_tracking.dart';

String _generateId() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      '_' +
      (DateTime.now().microsecond % 1000).toString();
}

/// Repository for managing hero downtime projects, followers, and sources
class DowntimeRepository {
  final db.AppDatabase _db;

  DowntimeRepository(this._db);

  // ========== Hero Downtime Projects ==========

  /// Get all downtime projects for a hero
  Future<List<HeroDowntimeProject>> getHeroProjects(String heroId) async {
    final rows = await (_db.select(_db.heroDowntimeProjects)
          ..where((t) => t.heroId.equals(heroId)))
        .get();

    return rows.map(_projectFromRow).toList();
  }

  /// Get a specific project by ID
  Future<HeroDowntimeProject?> getProject(String projectId) async {
    final row = await (_db.select(_db.heroDowntimeProjects)
          ..where((t) => t.id.equals(projectId)))
        .getSingleOrNull();

    return row != null ? _projectFromRow(row) : null;
  }

  /// Create a new downtime project for a hero
  Future<String> createProject({
    required String heroId,
    String? templateProjectId,
    required String name,
    required String description,
    required int projectGoal,
    List<String>? prerequisites,
    String? projectSource,
    String? sourceLanguage,
    List<String>? guides,
    List<String>? rollCharacteristics,
    String notes = '',
    bool isCustom = true,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    final events = HeroDowntimeProject.calculateEventThresholds(projectGoal);

    await _db.into(_db.heroDowntimeProjects).insert(
          db.HeroDowntimeProjectsCompanion.insert(
            id: id,
            heroId: heroId,
            templateProjectId: Value(templateProjectId),
            name: name,
            description: Value(description),
            projectGoal: projectGoal,
            currentPoints: const Value(0),
            prerequisitesJson: Value(jsonEncode(prerequisites ?? [])),
            projectSource: Value(projectSource),
            sourceLanguage: Value(sourceLanguage),
            guidesJson: Value(jsonEncode(guides ?? [])),
            rollCharacteristicsJson:
                Value(jsonEncode(rollCharacteristics ?? [])),
            eventsJson: Value(jsonEncode(events.map((e) => e.toJson()).toList())),
            notes: Value(notes),
            isCustom: Value(isCustom),
            isCompleted: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  /// Update project points and check for event triggers
  Future<void> updateProjectPoints(String projectId, int newPoints) async {
    final project = await getProject(projectId);
    if (project == null) return;

    final updatedProject = project.copyWith(
      currentPoints: newPoints,
      updatedAt: DateTime.now(),
    );

    // Check if any events should be triggered
    final withEvents = updatedProject.updateEventTriggers();

    await (_db.update(_db.heroDowntimeProjects)
          ..where((t) => t.id.equals(projectId)))
        .write(
      db.HeroDowntimeProjectsCompanion(
        currentPoints: Value(withEvents.currentPoints),
        eventsJson: Value(jsonEncode(withEvents.events.map((e) => e.toJson()).toList())),
        updatedAt: Value(withEvents.updatedAt),
      ),
    );
  }

  /// Mark project as completed
  Future<void> completeProject(String projectId) async {
    await (_db.update(_db.heroDowntimeProjects)
          ..where((t) => t.id.equals(projectId)))
        .write(
      db.HeroDowntimeProjectsCompanion(
        isCompleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update project details
  Future<void> updateProject(HeroDowntimeProject project) async {
    await (_db.update(_db.heroDowntimeProjects)
          ..where((t) => t.id.equals(project.id)))
        .write(
      db.HeroDowntimeProjectsCompanion(
        name: Value(project.name),
        description: Value(project.description),
        projectGoal: Value(project.projectGoal),
        currentPoints: Value(project.currentPoints),
        prerequisitesJson: Value(jsonEncode(project.prerequisites)),
        projectSource: Value(project.projectSource),
        sourceLanguage: Value(project.sourceLanguage),
        guidesJson: Value(jsonEncode(project.guides)),
        rollCharacteristicsJson: Value(jsonEncode(project.rollCharacteristics)),
        eventsJson: Value(jsonEncode(project.events.map((e) => e.toJson()).toList())),
        notes: Value(project.notes),
        isCompleted: Value(project.isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    await (_db.delete(_db.heroDowntimeProjects)
          ..where((t) => t.id.equals(projectId)))
        .go();
  }

  HeroDowntimeProject _projectFromRow(db.HeroDowntimeProject row) {
    return HeroDowntimeProject(
      id: row.id,
      heroId: row.heroId,
      templateProjectId: row.templateProjectId,
      name: row.name,
      description: row.description,
      projectGoal: row.projectGoal,
      currentPoints: row.currentPoints,
      prerequisites: List<String>.from(jsonDecode(row.prerequisitesJson)),
      projectSource: row.projectSource,
      sourceLanguage: row.sourceLanguage,
      guides: List<String>.from(jsonDecode(row.guidesJson)),
      rollCharacteristics: List<String>.from(jsonDecode(row.rollCharacteristicsJson)),
      events: (jsonDecode(row.eventsJson) as List)
          .map((e) => ProjectEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: row.notes,
      isCustom: row.isCustom,
      isCompleted: row.isCompleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ========== Followers ==========

  /// Get all followers for a hero
  Future<List<Follower>> getHeroFollowers(String heroId) async {
    final rows = await (_db.select(_db.heroFollowers)
          ..where((t) => t.heroId.equals(heroId)))
        .get();

    return rows.map(_followerFromRow).toList();
  }

  /// Create a new follower
  Future<String> createFollower({
    required String heroId,
    required String name,
    required String followerType,
    int might = 0,
    int agility = 0,
    int reason = 0,
    int intuition = 0,
    int presence = 0,
    List<String>? skills,
    List<String>? languages,
  }) async {
    final id = _generateId();

    await _db.into(_db.heroFollowers).insert(
          db.HeroFollowersCompanion.insert(
            id: id,
            heroId: heroId,
            name: name,
            followerType: followerType,
            might: Value(might),
            agility: Value(agility),
            reason: Value(reason),
            intuition: Value(intuition),
            presence: Value(presence),
            skillsJson: Value(jsonEncode(skills ?? [])),
            languagesJson: Value(jsonEncode(languages ?? [])),
          ),
        );

    return id;
  }

  /// Update a follower
  Future<void> updateFollower(Follower follower) async {
    await (_db.update(_db.heroFollowers)
          ..where((t) => t.id.equals(follower.id)))
        .write(
      db.HeroFollowersCompanion(
        name: Value(follower.name),
        followerType: Value(follower.followerType),
        might: Value(follower.might),
        agility: Value(follower.agility),
        reason: Value(follower.reason),
        intuition: Value(follower.intuition),
        presence: Value(follower.presence),
        skillsJson: Value(jsonEncode(follower.skills)),
        languagesJson: Value(jsonEncode(follower.languages)),
      ),
    );
  }

  /// Delete a follower
  Future<void> deleteFollower(String followerId) async {
    await (_db.delete(_db.heroFollowers)
          ..where((t) => t.id.equals(followerId)))
        .go();
  }

  Follower _followerFromRow(db.HeroFollower row) {
    return Follower(
      id: row.id,
      heroId: row.heroId,
      name: row.name,
      followerType: row.followerType,
      might: row.might,
      agility: row.agility,
      reason: row.reason,
      intuition: row.intuition,
      presence: row.presence,
      skills: List<String>.from(jsonDecode(row.skillsJson)),
      languages: List<String>.from(jsonDecode(row.languagesJson)),
    );
  }

  // ========== Project Sources ==========

  /// Get all project sources for a hero
  Future<List<ProjectSource>> getHeroSources(String heroId) async {
    final rows = await (_db.select(_db.heroProjectSources)
          ..where((t) => t.heroId.equals(heroId)))
        .get();

    return rows.map(_sourceFromRow).toList();
  }

  /// Create a new project source
  Future<String> createSource({
    required String heroId,
    required String name,
    required String type,
    String? language,
    String? description,
  }) async {
    final id = _generateId();

    await _db.into(_db.heroProjectSources).insert(
          db.HeroProjectSourcesCompanion.insert(
            id: id,
            heroId: heroId,
            name: name,
            type: type,
            language: Value(language),
            description: Value(description),
          ),
        );

    return id;
  }

  /// Update a project source
  Future<void> updateSource(ProjectSource source) async {
    await (_db.update(_db.heroProjectSources)
          ..where((t) => t.id.equals(source.id)))
        .write(
      db.HeroProjectSourcesCompanion(
        name: Value(source.name),
        type: Value(source.type),
        language: Value(source.language),
        description: Value(source.description),
      ),
    );
  }

  /// Delete a project source
  Future<void> deleteSource(String sourceId) async {
    await (_db.delete(_db.heroProjectSources)
          ..where((t) => t.id.equals(sourceId)))
        .go();
  }

  ProjectSource _sourceFromRow(db.HeroProjectSource row) {
    return ProjectSource(
      id: row.id,
      heroId: row.heroId,
      name: row.name,
      type: row.type,
      language: row.language,
      description: row.description,
    );
  }

  // ========== Story-Granted Project Points ==========

  /// Get story-granted project points for a hero
  Future<int> getStoryProjectPoints(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final value = values.firstWhere(
      (v) => v.key == 'downtime.story_project_points',
      orElse: () => db.HeroValue(
        id: 0,
        heroId: heroId,
        key: 'downtime.story_project_points',
        value: 0,
        updatedAt: DateTime.now(),
      ),
    );
    return value.value ?? 0;
  }

  /// Set story-granted project points
  Future<void> setStoryProjectPoints(String heroId, int points) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'downtime.story_project_points',
      value: points,
    );
  }
}
