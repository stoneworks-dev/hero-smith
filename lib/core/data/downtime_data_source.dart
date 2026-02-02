import 'package:flutter/services.dart' show rootBundle;
import '../models/downtime.dart';

/// Model for craftable treasure items
class CraftableTreasure {
  final String id;
  final String name;
  final String type; // consumable, trinket, leveled_treasure
  final int? echelon;
  final String description;
  final List<String> keywords;
  final String? itemPrerequisite;
  final String? projectSource;
  final List<String> projectRollCharacteristics;
  final int? projectGoal;
  final String? projectGoalDescription;
  final bool isLeveled;
  final String? leveledType; // armor, weapon, implement, shield
  final Map<String, dynamic> raw;

  CraftableTreasure({
    required this.id,
    required this.name,
    required this.type,
    this.echelon,
    required this.description,
    required this.keywords,
    this.itemPrerequisite,
    this.projectSource,
    required this.projectRollCharacteristics,
    this.projectGoal,
    this.projectGoalDescription,
    required this.isLeveled,
    this.leveledType,
    required this.raw,
  });

  factory CraftableTreasure.fromJson(Map<String, dynamic> j, String type) {
    return CraftableTreasure(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      type: type,
      echelon: j['echelon'] as int?,
      description: j['description']?.toString() ?? '',
      keywords: List<String>.from(j['keywords'] ?? []),
      itemPrerequisite: j['item_prerequisite']?.toString(),
      projectSource: j['project_source']?.toString(),
      projectRollCharacteristics: List<String>.from(j['project_roll_characteristics'] ?? []),
      projectGoal: j['project_goal'] as int?,
      projectGoalDescription: j['project_goal_description']?.toString(),
      isLeveled: j['leveled'] == true,
      leveledType: j['leveled_type']?.toString(),
      raw: j,
    );
  }

  /// Get display name for the treasure type
  String get typeDisplayName {
    switch (type) {
      case 'consumable':
        return 'Consumable';
      case 'trinket':
        return 'Trinket';
      case 'leveled_treasure':
        return 'Leveled Treasure';
      default:
        return type;
    }
  }
}

class DowntimeDataSource {
  static const _projectsPath = 'data/downtime/downtime_projects.json';
  static const _imbuementsPath = 'data/downtime/item_imbuements.json';
  static const _eventsPath = 'data/downtime/downtime_events.json';
  static const _consumablesPath = 'data/treasures/consumables.json';
  static const _trinketsPath = 'data/treasures/trinkets.json';
  static const _leveledTreasuresPath = 'data/treasures/leveled_treasures.json';
  static const _fallbackEventsName = 'Crafting and Research Events';

  /// Public getter to expose the default/fallback events table name
  String get fallbackEventsName => _fallbackEventsName;

  /// Returns the expected events table name for a given entry, without loading tables
  String expectedEventsTableNameFor(DowntimeEntry entry) =>
      '${entry.name.trim()} Events';

  Future<List<DowntimeEntry>> loadProjects() async {
    final txt = await rootBundle.loadString(_projectsPath);
    final list = decodeJsonList(txt);
    return list
        .whereType<Map<String, dynamic>>()
        .map(DowntimeEntry.fromJson)
        .toList();
  }

  Future<List<DowntimeEntry>> loadImbuements() async {
    final txt = await rootBundle.loadString(_imbuementsPath);
    final list = decodeJsonList(txt);
    return list
        .whereType<Map<String, dynamic>>()
        .map(DowntimeEntry.fromJson)
        .toList();
  }

  Future<List<EventTable>> loadEventTables() async {
    final txt = await rootBundle.loadString(_eventsPath);
    final list = decodeJsonList(txt);
    return list
        .whereType<Map<String, dynamic>>()
        .map(EventTable.fromJson)
        .toList();
  }

  Future<EventTable?> resolveEventsForEntry(DowntimeEntry entry) async {
    final tables = await loadEventTables();
    final wanted = '${entry.name.trim()} Events'.toLowerCase();
    final exact = tables.firstWhere(
      (t) => t.name.toLowerCase() == wanted,
      orElse: () => EventTable(id: '', name: '', events: const []),
    );
    if (exact.name.isNotEmpty) return exact;

    return tables.firstWhere(
      (t) => t.name == _fallbackEventsName,
      orElse: () => EventTable(
          id: _fallbackEventsName, name: _fallbackEventsName, events: const []),
    );
  }

  /// Groups imbuements by echelon (level) and then by type
  Future<Map<int, Map<String, List<DowntimeEntry>>>>
      loadImbuementsByLevelAndType() async {
    final imbuements = await loadImbuements();
    final grouped = <int, Map<String, List<DowntimeEntry>>>{};

    for (final imbuement in imbuements) {
      final level = imbuement.raw['level'] as int? ?? 1;
      final type = imbuement.raw['type'] as String? ?? 'unknown';

      grouped.putIfAbsent(level, () => <String, List<DowntimeEntry>>{});
      grouped[level]!.putIfAbsent(type, () => <DowntimeEntry>[]);
      grouped[level]![type]!.add(imbuement);
    }

    // Sort by level
    final sortedGrouped = <int, Map<String, List<DowntimeEntry>>>{};
    final sortedKeys = grouped.keys.toList()..sort();
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  /// Get a human-readable name for imbuement types
  String getImbuementTypeName(String type) {
    switch (type) {
      case 'armor_imbuement':
        return 'Armor Imbuements';
      case 'weapon_imbuement':
        return 'Weapon Imbuements';
      case 'implement_imbuement':
        return 'Implement Imbuements';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  /// Get level display name
  String getLevelName(int level) {
    switch (level) {
      case 1:
        return '1st Level';
      case 5:
        return '5th Level';
      case 9:
        return '9th Level';
      default:
        return '${level}th Level';
    }
  }

  // ========== Craftable Treasures ==========

  /// Load all craftable treasures (consumables, trinkets, leveled treasures)
  Future<List<CraftableTreasure>> loadAllCraftableTreasures() async {
    final results = <CraftableTreasure>[];

    // Load consumables
    try {
      final consumablesTxt = await rootBundle.loadString(_consumablesPath);
      final consumablesList = decodeJsonList(consumablesTxt);
      results.addAll(
        consumablesList
            .whereType<Map<String, dynamic>>()
            .where((j) => j['id'] != 'test_treasure') // Skip test entry
            .map((j) => CraftableTreasure.fromJson(j, 'consumable')),
      );
    } catch (e) {
      // Consumables file may not exist
    }

    // Load trinkets
    try {
      final trinketsTxt = await rootBundle.loadString(_trinketsPath);
      final trinketsList = decodeJsonList(trinketsTxt);
      results.addAll(
        trinketsList
            .whereType<Map<String, dynamic>>()
            .map((j) => CraftableTreasure.fromJson(j, 'trinket')),
      );
    } catch (e) {
      // Trinkets file may not exist
    }

    // Load leveled treasures
    try {
      final leveledTxt = await rootBundle.loadString(_leveledTreasuresPath);
      final leveledList = decodeJsonList(leveledTxt);
      results.addAll(
        leveledList
            .whereType<Map<String, dynamic>>()
            .map((j) => CraftableTreasure.fromJson(j, 'leveled_treasure')),
      );
    } catch (e) {
      // Leveled treasures file may not exist
    }

    return results;
  }

  /// Load craftable treasures grouped by type
  Future<Map<String, List<CraftableTreasure>>> loadCraftableTreasuresByType() async {
    final all = await loadAllCraftableTreasures();
    final grouped = <String, List<CraftableTreasure>>{};

    for (final treasure in all) {
      grouped.putIfAbsent(treasure.type, () => <CraftableTreasure>[]);
      grouped[treasure.type]!.add(treasure);
    }

    return grouped;
  }

  /// Load craftable treasures of a specific type, grouped by echelon
  Future<Map<int, List<CraftableTreasure>>> loadCraftableTreasuresByEchelon(String type) async {
    final all = await loadAllCraftableTreasures();
    final filtered = all.where((t) => t.type == type);
    final grouped = <int, List<CraftableTreasure>>{};

    for (final treasure in filtered) {
      final echelon = treasure.echelon ?? 0;
      grouped.putIfAbsent(echelon, () => <CraftableTreasure>[]);
      grouped[echelon]!.add(treasure);
    }

    // Sort by echelon
    final sortedGrouped = <int, List<CraftableTreasure>>{};
    final sortedKeys = grouped.keys.toList()..sort();
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  /// Load leveled treasures grouped by equipment type
  Future<Map<String, List<CraftableTreasure>>> loadLeveledTreasuresByEquipmentType() async {
    final all = await loadAllCraftableTreasures();
    final leveled = all.where((t) => t.type == 'leveled_treasure');
    final grouped = <String, List<CraftableTreasure>>{};

    for (final treasure in leveled) {
      final equipType = treasure.leveledType ?? 'other';
      grouped.putIfAbsent(equipType, () => <CraftableTreasure>[]);
      grouped[equipType]!.add(treasure);
    }

    return grouped;
  }

  /// Load a single craftable treasure by ID, or null if not found
  Future<CraftableTreasure?> getCraftableTreasureById(String id) async {
    final all = await loadAllCraftableTreasures();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if an ID corresponds to a craftable treasure
  Future<bool> isTreasureId(String id) async {
    return await getCraftableTreasureById(id) != null;
  }

  /// Get display name for treasure type
  String getTreasureTypeName(String type) {
    switch (type) {
      case 'consumable':
        return 'Consumables';
      case 'trinket':
        return 'Trinkets';
      case 'leveled_treasure':
        return 'Leveled Treasures';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  /// Get echelon display name
  String getEchelonName(int echelon) {
    switch (echelon) {
      case 0:
        return 'No Echelon';
      case 1:
        return '1st Echelon';
      case 2:
        return '2nd Echelon';
      case 3:
        return '3rd Echelon';
      case 4:
        return '4th Echelon';
      default:
        return '${echelon}th Echelon';
    }
  }
}
