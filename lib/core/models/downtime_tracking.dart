/// Models for tracking hero downtime projects and related data

/// Represents a follower that can help with downtime projects
class Follower {
  final String id;
  final String heroId;
  final String name;
  final String followerType;
  final int might;
  final int agility;
  final int reason;
  final int intuition;
  final int presence;
  final List<String> skills;
  final List<String> languages;

  const Follower({
    required this.id,
    required this.heroId,
    required this.name,
    required this.followerType,
    required this.might,
    required this.agility,
    required this.reason,
    required this.intuition,
    required this.presence,
    required this.skills,
    required this.languages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heroId': heroId,
      'name': name,
      'followerType': followerType,
      'might': might,
      'agility': agility,
      'reason': reason,
      'intuition': intuition,
      'presence': presence,
      'skills': skills,
      'languages': languages,
    };
  }

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'] as String,
      heroId: json['heroId'] as String,
      name: json['name'] as String,
      followerType: json['followerType'] as String,
      might: json['might'] as int,
      agility: json['agility'] as int,
      reason: json['reason'] as int,
      intuition: json['intuition'] as int,
      presence: json['presence'] as int,
      skills: List<String>.from(json['skills'] as List),
      languages: List<String>.from(json['languages'] as List),
    );
  }

  Follower copyWith({
    String? id,
    String? heroId,
    String? name,
    String? followerType,
    int? might,
    int? agility,
    int? reason,
    int? intuition,
    int? presence,
    List<String>? skills,
    List<String>? languages,
  }) {
    return Follower(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      name: name ?? this.name,
      followerType: followerType ?? this.followerType,
      might: might ?? this.might,
      agility: agility ?? this.agility,
      reason: reason ?? this.reason,
      intuition: intuition ?? this.intuition,
      presence: presence ?? this.presence,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
    );
  }
}

/// Represents a project source, item, or guide that aids in downtime projects
class ProjectSource {
  final String id;
  final String heroId;
  final String name;
  final String type; // 'source', 'item', 'guide'
  final String? language;
  final String? description;

  const ProjectSource({
    required this.id,
    required this.heroId,
    required this.name,
    required this.type,
    this.language,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heroId': heroId,
      'name': name,
      'type': type,
      'language': language,
      'description': description,
    };
  }

  factory ProjectSource.fromJson(Map<String, dynamic> json) {
    return ProjectSource(
      id: json['id'] as String,
      heroId: json['heroId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      language: json['language'] as String?,
      description: json['description'] as String?,
    );
  }

  ProjectSource copyWith({
    String? id,
    String? heroId,
    String? name,
    String? type,
    String? language,
    String? description,
  }) {
    return ProjectSource(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      name: name ?? this.name,
      type: type ?? this.type,
      language: language ?? this.language,
      description: description ?? this.description,
    );
  }
}

/// Event tracking for a downtime project
class ProjectEvent {
  final int pointThreshold;
  final bool triggered;
  final String? eventDescription;
  final DateTime? triggeredAt;

  const ProjectEvent({
    required this.pointThreshold,
    required this.triggered,
    this.eventDescription,
    this.triggeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'pointThreshold': pointThreshold,
      'triggered': triggered,
      'eventDescription': eventDescription,
      'triggeredAt': triggeredAt?.toIso8601String(),
    };
  }

  factory ProjectEvent.fromJson(Map<String, dynamic> json) {
    return ProjectEvent(
      pointThreshold: json['pointThreshold'] as int,
      triggered: json['triggered'] as bool,
      eventDescription: json['eventDescription'] as String?,
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.parse(json['triggeredAt'] as String)
          : null,
    );
  }

  ProjectEvent copyWith({
    int? pointThreshold,
    bool? triggered,
    String? eventDescription,
    DateTime? triggeredAt,
  }) {
    return ProjectEvent(
      pointThreshold: pointThreshold ?? this.pointThreshold,
      triggered: triggered ?? this.triggered,
      eventDescription: eventDescription ?? this.eventDescription,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }
}

/// Represents a hero's downtime project tracking
class HeroDowntimeProject {
  final String id;
  final String heroId;
  final String? templateProjectId; // Reference to template from JSON
  final String name;
  final String description;
  final int projectGoal;
  final int currentPoints;
  final List<String> prerequisites;
  final String? projectSource;
  final String? sourceLanguage;
  final List<String> guides;
  final List<String> rollCharacteristics; // 'might', 'agility', etc.
  final List<ProjectEvent> events;
  final String notes; // User notes for tracking progress, ideas, etc.
  final bool isCustom; // User-created vs template-based
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HeroDowntimeProject({
    required this.id,
    required this.heroId,
    this.templateProjectId,
    required this.name,
    required this.description,
    required this.projectGoal,
    required this.currentPoints,
    required this.prerequisites,
    this.projectSource,
    this.sourceLanguage,
    required this.guides,
    required this.rollCharacteristics,
    required this.events,
    this.notes = '',
    required this.isCustom,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate which events should exist based on project goal
  static List<ProjectEvent> calculateEventThresholds(int projectGoal) {
    if (projectGoal <= 30) {
      return []; // No events
    } else if (projectGoal <= 200) {
      return [
        ProjectEvent(
          pointThreshold: projectGoal ~/ 2,
          triggered: false,
        ),
      ];
    } else if (projectGoal <= 999) {
      return [
        ProjectEvent(
          pointThreshold: projectGoal ~/ 3,
          triggered: false,
        ),
        ProjectEvent(
          pointThreshold: (projectGoal * 2) ~/ 3,
          triggered: false,
        ),
      ];
    } else {
      // 1000+
      return [
        ProjectEvent(
          pointThreshold: projectGoal ~/ 4,
          triggered: false,
        ),
        ProjectEvent(
          pointThreshold: projectGoal ~/ 2,
          triggered: false,
        ),
        ProjectEvent(
          pointThreshold: (projectGoal * 3) ~/ 4,
          triggered: false,
        ),
      ];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heroId': heroId,
      'templateProjectId': templateProjectId,
      'name': name,
      'description': description,
      'projectGoal': projectGoal,
      'currentPoints': currentPoints,
      'prerequisites': prerequisites,
      'projectSource': projectSource,
      'sourceLanguage': sourceLanguage,
      'guides': guides,
      'rollCharacteristics': rollCharacteristics,
      'events': events.map((e) => e.toJson()).toList(),
      'notes': notes,
      'isCustom': isCustom,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HeroDowntimeProject.fromJson(Map<String, dynamic> json) {
    return HeroDowntimeProject(
      id: json['id'] as String,
      heroId: json['heroId'] as String,
      templateProjectId: json['templateProjectId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      projectGoal: json['projectGoal'] as int,
      currentPoints: json['currentPoints'] as int,
      prerequisites: List<String>.from(json['prerequisites'] as List),
      projectSource: json['projectSource'] as String?,
      sourceLanguage: json['sourceLanguage'] as String?,
      guides: List<String>.from(json['guides'] as List),
      rollCharacteristics: List<String>.from(json['rollCharacteristics'] as List),
      events: (json['events'] as List)
          .map((e) => ProjectEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
      isCustom: json['isCustom'] as bool,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  HeroDowntimeProject copyWith({
    String? id,
    String? heroId,
    String? templateProjectId,
    String? name,
    String? description,
    int? projectGoal,
    int? currentPoints,
    List<String>? prerequisites,
    String? projectSource,
    String? sourceLanguage,
    List<String>? guides,
    List<String>? rollCharacteristics,
    List<ProjectEvent>? events,
    String? notes,
    bool? isCustom,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HeroDowntimeProject(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      templateProjectId: templateProjectId ?? this.templateProjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      projectGoal: projectGoal ?? this.projectGoal,
      currentPoints: currentPoints ?? this.currentPoints,
      prerequisites: prerequisites ?? this.prerequisites,
      projectSource: projectSource ?? this.projectSource,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      guides: guides ?? this.guides,
      rollCharacteristics: rollCharacteristics ?? this.rollCharacteristics,
      events: events ?? this.events,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get progress percentage
  double get progress => projectGoal > 0 ? (currentPoints / projectGoal).clamp(0.0, 1.0) : 0.0;

  /// Check which events should be triggered based on current points
  HeroDowntimeProject updateEventTriggers() {
    final updatedEvents = events.map((event) {
      if (!event.triggered && currentPoints >= event.pointThreshold) {
        return event.copyWith(
          triggered: true,
          triggeredAt: DateTime.now(),
        );
      }
      return event;
    }).toList();

    return copyWith(events: updatedEvents, updatedAt: DateTime.now());
  }
}
