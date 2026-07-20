import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../db/app_database.dart';
import '../models/canonical_grant_model.dart';

/// Service for calculating treasure-related bonuses (armor imbuements, etc.)
///
/// Armor imbuements grant stamina bonuses based on their level:
/// - Level 1: +6 stamina
/// - Level 5: +12 stamina
/// - Level 9: +21 stamina
///
/// These bonuses use "take highest" logic - only the highest bonus applies.
///
/// Equipped treasures can also grant stat bonuses:
/// - Leveled treasures: stamina based on level (1/5/9), immunities
/// - Trinkets: grants array with increase_total (stamina, stability, immunities)
/// - Artifacts: stat_bonuses similar to leveled treasures
///
/// Stacking rules:
/// - stacks_with_other_treasures: true = additive (e.g., Bastion Belt stamina)
/// - stacks_with_other_treasures: false = take highest only (e.g., armor bonuses)
class TreasureBonusService {
  TreasureBonusService(this._db);

  final AppDatabase _db;

  /// Path to imbuements descriptions JSON
  static const _imbuementsDescriptionsPath =
      'data/downtime/imbuements_descriptions.json';

  /// Path to item imbuements JSON (for type/level lookup)
  static const _itemImbuementsPath = 'data/downtime/item_imbuements.json';

  /// Paths to treasure JSON files
  static const _leveledTreasuresPath = 'data/treasures/leveled_treasures.json';
  static const _trinketsPath = 'data/treasures/trinkets.json';
  static const _artefactsPath = 'data/treasures/artefacts.json';

  /// Cached imbuements data
  static List<Map<String, dynamic>>? _cachedImbuements;
  static String? _cachedDescription;

  /// Cached treasure data
  static List<Map<String, dynamic>>? _cachedLeveledTreasures;
  static List<Map<String, dynamic>>? _cachedTrinkets;
  static List<Map<String, dynamic>>? _cachedArtefacts;

  /// Get the stamina bonus for an armor imbuement based on its level.
  /// Returns 0 if not an armor imbuement.
  static int getArmorImbuementStaminaBonus(int level) {
    if (level >= 9) return 21;
    if (level >= 5) return 12;
    if (level >= 1) return 6;
    return 0;
  }

  /// Load imbuements data (cached).
  Future<List<Map<String, dynamic>>> _loadImbuementsData() async {
    if (_cachedImbuements != null) return _cachedImbuements!;

    try {
      final txt = await rootBundle.loadString(_itemImbuementsPath);
      final list = jsonDecode(txt) as List<dynamic>;
      _cachedImbuements = list.cast<Map<String, dynamic>>();
      return _cachedImbuements!;
    } catch (e) {
      return [];
    }
  }

  /// Get imbuement data by ID.
  Future<Map<String, dynamic>?> getImbuementById(String id) async {
    final imbuements = await _loadImbuementsData();
    for (final imbuement in imbuements) {
      if (imbuement['id'] == id) return imbuement;
    }
    return null;
  }

  /// Load the imbued items description from JSON.
  Future<String> loadImbuementsDescription() async {
    if (_cachedDescription != null) return _cachedDescription!;

    try {
      final txt = await rootBundle.loadString(_imbuementsDescriptionsPath);
      final list = jsonDecode(txt) as List<dynamic>;
      if (list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>;
        _cachedDescription = first['description'] as String? ?? '';
        return _cachedDescription!;
      }
    } catch (e) {
      // Ignore errors
    }
    return '';
  }

  /// Calculate the highest stamina bonus from armor imbuements.
  /// Uses "take highest" logic - only the highest bonus applies.
  Future<int> calculateHighestArmorImbuementStamina(String heroId) async {
    // Get hero's imbuement IDs
    final imbuementIds = await _db.getHeroComponentIds(heroId, 'imbuement');
    if (imbuementIds.isEmpty) return 0;

    final imbuementsData = await _loadImbuementsData();

    int highestBonus = 0;

    for (final id in imbuementIds) {
      // Find the imbuement data
      final imbuementData = imbuementsData.firstWhere(
        (i) => i['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      final type = imbuementData['type'] as String? ?? '';
      final level = imbuementData['level'] as int? ?? 0;

      // Only armor imbuements grant stamina
      if (type == 'armor_imbuement') {
        final bonus = getArmorImbuementStaminaBonus(level);
        if (bonus > highestBonus) {
          highestBonus = bonus;
        }
      }
    }

    return highestBonus;
  }

  /// Watch the highest stamina bonus from armor imbuements.
  Stream<int> watchHighestArmorImbuementStamina(String heroId) {
    return _db.watchHeroComponentIds(heroId, 'imbuement').asyncMap(
      (imbuementIds) async {
        if (imbuementIds.isEmpty) return 0;
        return calculateHighestArmorImbuementStamina(heroId);
      },
    );
  }

  /// Calculate combined treasure stamina from both imbuements and equipped treasures.
  ///
  /// Stacking rules:
  /// - Armor imbuements: non-stacking (take highest)
  /// - Equipped treasures with stacks_with_other_treasures: false -> non-stacking (take highest)
  /// - Equipped treasures with stacks_with_other_treasures: true -> stacking (additive)
  ///
  /// Final formula: max(armor_imbuement, highest_non_stacking_treasure) + stacking_treasures
  Future<int> calculateCombinedTreasureStamina(
      String heroId, int heroLevel) async {
    // Get armor imbuement stamina (non-stacking)
    final imbuementStamina =
        await calculateHighestArmorImbuementStamina(heroId);

    // Get hero's highest characteristic (for multiplier-based bonuses)
    final highestChar = await _getHeroHighestCharacteristic(heroId);

    // Get equipped treasure bonuses
    final equippedBonuses = await calculateEquippedTreasureBonuses(
      heroId,
      heroLevel,
      highestCharacteristic: highestChar,
    );

    // Combine: take highest of (imbuement, non-stacking treasures), then add stacking
    final highestNonStacking =
        imbuementStamina > equippedBonuses.highestNonStackingStamina
            ? imbuementStamina
            : equippedBonuses.highestNonStackingStamina;

    return highestNonStacking + equippedBonuses.stackingStamina;
  }

  /// Watch combined treasure stamina from both imbuements and equipped treasures.
  /// Reacts to changes in imbuements, treasure entries, or hero level.
  Stream<int> watchCombinedTreasureStamina(String heroId) async* {
    // Emit initial value immediately
    final initialLevel = await _getHeroLevel(heroId);
    yield await calculateCombinedTreasureStamina(heroId, initialLevel);

    // Watch imbuements, treasure entries, AND hero values (for level/characteristic changes)
    final imbuementStream = _db.watchHeroComponentIds(heroId, 'imbuement');
    final treasureStream = _db.watchHeroEntriesWithPayload(heroId, 'treasure');
    final valuesStream = _db.watchHeroValues(heroId);

    // Combine all three streams - recalculate when any changes
    yield* _combineThreeStreams(imbuementStream, treasureStream, valuesStream)
        .asyncMap((_) async {
      // Get hero level from values
      final heroLevel = await _getHeroLevel(heroId);
      return calculateCombinedTreasureStamina(heroId, heroLevel);
    });
  }

  /// Watch all equipped treasure bonuses (stamina, stability, speed, immunities).
  /// Reacts to changes in treasure entries or hero level/characteristics.
  Stream<EquippedTreasureBonuses> watchEquippedTreasureBonuses(
      String heroId) async* {
    // Emit initial value immediately
    final initialLevel = await _getHeroLevel(heroId);
    final initialHighestChar = await _getHeroHighestCharacteristic(heroId);
    final imbuementStamina =
        await calculateHighestArmorImbuementStamina(heroId);
    var bonuses = await calculateEquippedTreasureBonuses(
      heroId,
      initialLevel,
      highestCharacteristic: initialHighestChar,
    );

    // Combine imbuement stamina with treasure stamina for total
    final combinedStamina = _combineTreasureStamina(imbuementStamina, bonuses);
    yield bonuses.copyWith(stamina: combinedStamina);

    // Watch treasure entries, imbuements, AND hero values (for level/characteristic changes)
    final treasureStream = _db.watchHeroEntriesWithPayload(heroId, 'treasure');
    final imbuementStream = _db.watchHeroComponentIds(heroId, 'imbuement');
    final valuesStream = _db.watchHeroValues(heroId);

    // Combine streams - recalculate when any changes
    yield* _combineThreeStreams(treasureStream, imbuementStream, valuesStream)
        .asyncMap((_) async {
      final heroLevel = await _getHeroLevel(heroId);
      final highestChar = await _getHeroHighestCharacteristic(heroId);
      final imbStamina = await calculateHighestArmorImbuementStamina(heroId);
      final bonuses = await calculateEquippedTreasureBonuses(
        heroId,
        heroLevel,
        highestCharacteristic: highestChar,
      );

      // Combine imbuement stamina with treasure stamina for total
      final combinedStamina = _combineTreasureStamina(imbStamina, bonuses);
      return bonuses.copyWith(stamina: combinedStamina);
    });
  }

  /// Combine imbuement stamina with treasure stamina using stacking rules.
  int _combineTreasureStamina(
      int imbuementStamina, EquippedTreasureBonuses treasureBonuses) {
    final highestNonStacking =
        imbuementStamina > treasureBonuses.highestNonStackingStamina
            ? imbuementStamina
            : treasureBonuses.highestNonStackingStamina;
    return highestNonStacking + treasureBonuses.stackingStamina;
  }

  /// Get the current level of a hero from hero values.
  Future<int> _getHeroLevel(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    final levelValue = values.where((v) => v.key == 'basics.level').firstOrNull;
    return levelValue?.value ?? 1;
  }

  /// Get the hero's highest characteristic value.
  /// Checks might, agility, reason, intuition, and presence to find the max.
  Future<int> _getHeroHighestCharacteristic(String heroId) async {
    final values = await _db.getHeroValues(heroId);

    int getValue(String key) {
      final v = values.where((v) => v.key == key).firstOrNull;
      return v?.value ?? 0;
    }

    final characteristics = [
      getValue('stats.might'),
      getValue('stats.agility'),
      getValue('stats.reason'),
      getValue('stats.intuition'),
      getValue('stats.presence'),
    ];

    return characteristics.reduce((a, b) => a > b ? a : b);
  }

  /// Helper to combine three streams into one that emits whenever any emits.
  Stream<void> _combineThreeStreams<A, B, C>(
      Stream<A> a, Stream<B> b, Stream<C> c) {
    final controller = StreamController<void>.broadcast();

    final subA = a.listen((_) => controller.add(null));
    final subB = b.listen((_) => controller.add(null));
    final subC = c.listen((_) => controller.add(null));

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
      subC.cancel();
    };

    return controller.stream;
  }

  /// Save the treasure highest bonus stamina to hero values.
  Future<void> saveTreasureHighestBonusStamina(
    String heroId,
    int staminaBonus,
  ) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'treasure.highest_bonus_stamina',
      value: staminaBonus,
    );
  }

  /// Load the treasure highest bonus stamina from hero values.
  Future<int> loadTreasureHighestBonusStamina(String heroId) async {
    final values = await _db.getHeroValues(heroId);
    for (final v in values) {
      if (v.key == 'treasure.highest_bonus_stamina') {
        return v.value ?? 0;
      }
    }
    return 0;
  }

  /// Recalculate and save the treasure highest bonus stamina.
  /// Call this when imbuements change.
  Future<int> recalculateAndSaveTreasureStamina(String heroId) async {
    final bonus = await calculateHighestArmorImbuementStamina(heroId);
    await saveTreasureHighestBonusStamina(heroId, bonus);
    return bonus;
  }

  // ========== Equipped Treasure Bonus Calculation ==========

  /// Load leveled treasures data (cached).
  Future<List<Map<String, dynamic>>> _loadLeveledTreasures() async {
    if (_cachedLeveledTreasures != null) return _cachedLeveledTreasures!;

    try {
      final txt = await rootBundle.loadString(_leveledTreasuresPath);
      final list = jsonDecode(txt) as List<dynamic>;
      _cachedLeveledTreasures = list.cast<Map<String, dynamic>>();
      return _cachedLeveledTreasures!;
    } catch (e) {
      return [];
    }
  }

  /// Load trinkets data (cached).
  Future<List<Map<String, dynamic>>> _loadTrinkets() async {
    if (_cachedTrinkets != null) return _cachedTrinkets!;

    try {
      final txt = await rootBundle.loadString(_trinketsPath);
      final list = jsonDecode(txt) as List<dynamic>;
      _cachedTrinkets = list.cast<Map<String, dynamic>>();
      return _cachedTrinkets!;
    } catch (e) {
      return [];
    }
  }

  /// Load artefacts data (cached).
  Future<List<Map<String, dynamic>>> _loadArtefacts() async {
    if (_cachedArtefacts != null) return _cachedArtefacts!;

    try {
      final txt = await rootBundle.loadString(_artefactsPath);
      final list = jsonDecode(txt) as List<dynamic>;
      _cachedArtefacts = list.cast<Map<String, dynamic>>();
      return _cachedArtefacts!;
    } catch (e) {
      return [];
    }
  }

  /// Find treasure data by ID across all treasure types.
  Future<Map<String, dynamic>?> getTreasureById(String id) async {
    // Check leveled treasures
    final leveled = await _loadLeveledTreasures();
    for (final t in leveled) {
      if (t['id'] == id) return t;
    }

    // Check trinkets
    final trinkets = await _loadTrinkets();
    for (final t in trinkets) {
      if (t['id'] == id) return t;
    }

    // Check artefacts
    final artefacts = await _loadArtefacts();
    for (final t in artefacts) {
      if (t['id'] == id) return t;
    }

    return null;
  }

  /// Calculate all stat bonuses from equipped treasures.
  /// Returns a map of stat types to their bonus values.
  ///
  /// Hero level is used to determine leveled treasure bonuses.
  /// [highestCharacteristic] is used for multiplier-based bonuses (e.g., Thief of Joy).
  Future<EquippedTreasureBonuses> calculateEquippedTreasureBonuses(
    String heroId,
    int heroLevel, {
    int highestCharacteristic = 0,
  }) async {
    // Get hero's treasure entries with payload
    final treasureEntries = await _db.getHeroEntriesWithPayload(
      heroId,
      'treasure',
    );

    // Filter to only equipped treasures
    final equippedIds = <String>[];
    for (final entry in treasureEntries.entries) {
      final payload = entry.value;
      if (payload['equipped'] == true) {
        equippedIds.add(entry.key);
      }
    }

    if (equippedIds.isEmpty) {
      return EquippedTreasureBonuses.empty();
    }

    // Collect all bonuses
    int highestNonStackingStamina = 0;
    int stackingStamina = 0;
    int stability = 0;
    int speed = 0;
    Map<String, int> immunities = {}; // damage type -> immunity value

    for (final treasureId in equippedIds) {
      final treasureData = await getTreasureById(treasureId);
      if (treasureData == null) continue;

      final type = treasureData['type'] as String? ?? '';

      if (type == 'leveled_treasure') {
        final treasureBonuses = calculateLeveledTreasureBonusesFromData(
          treasureData,
          heroLevel,
          highestCharacteristic: highestCharacteristic,
        );
        stackingStamina += treasureBonuses.stackingStamina;
        if (treasureBonuses.highestNonStackingStamina >
            highestNonStackingStamina) {
          highestNonStackingStamina = treasureBonuses.highestNonStackingStamina;
        }
        stability += treasureBonuses.stability;
        speed += treasureBonuses.speed;
        for (final entry in treasureBonuses.immunities.entries) {
          immunities[entry.key] = (immunities[entry.key] ?? 0) > entry.value
              ? immunities[entry.key]!
              : entry.value;
        }
      } else if (type == 'trinket') {
        final trinketBonuses = calculateTrinketBonusesFromData(
          treasureData,
          heroLevel,
        );
        stackingStamina += trinketBonuses.stackingStamina;
        if (trinketBonuses.highestNonStackingStamina >
            highestNonStackingStamina) {
          highestNonStackingStamina = trinketBonuses.highestNonStackingStamina;
        }
        stability += trinketBonuses.stability;
        speed += trinketBonuses.speed;
        for (final entry in trinketBonuses.immunities.entries) {
          immunities[entry.key] = (immunities[entry.key] ?? 0) > entry.value
              ? immunities[entry.key]!
              : entry.value;
        }
      } else if (type == 'artifact') {
        // Parse stat_bonuses for artifacts
        final statBonuses =
            treasureData['stat_bonuses'] as Map<String, dynamic>?;
        if (statBonuses != null) {
          // Stamina bonus
          final staminaBonus = statBonuses['stamina'] as Map<String, dynamic>?;
          if (staminaBonus != null) {
            final stacks =
                staminaBonus['stacks_with_other_treasures'] as bool? ?? false;
            final value = staminaBonus['value'] as int? ?? 0;

            if (stacks) {
              stackingStamina += value;
            } else {
              if (value > highestNonStackingStamina) {
                highestNonStackingStamina = value;
              }
            }
          }

          // Immunities
          final immunitiesData =
              statBonuses['immunities'] as Map<String, dynamic>?;
          if (immunitiesData != null) {
            for (final damageType in immunitiesData.keys) {
              final immunityData =
                  immunitiesData[damageType] as Map<String, dynamic>?;
              if (immunityData != null) {
                final value = immunityData['value'] as int? ?? 0;
                immunities[damageType] = (immunities[damageType] ?? 0) > value
                    ? immunities[damageType]!
                    : value;
              }
            }
          }
        }
      }
    }

    return EquippedTreasureBonuses(
      stamina: highestNonStackingStamina + stackingStamina,
      highestNonStackingStamina: highestNonStackingStamina,
      stackingStamina: stackingStamina,
      stability: stability,
      speed: speed,
      immunities: immunities,
    );
  }

  @visibleForTesting
  static EquippedTreasureBonuses calculateLeveledTreasureBonusesFromData(
    Map<String, dynamic> treasureData,
    int heroLevel, {
    int highestCharacteristic = 0,
  }) {
    final statBonuses = extractLeveledTreasureStatBonusesFromData(treasureData);
    if (statBonuses.isEmpty) return EquippedTreasureBonuses.empty();

    var highestNonStackingStamina = 0;
    var stackingStamina = 0;
    var stability = 0;
    var speed = 0;
    final immunities = <String, int>{};

    final staminaBonus = _optionalStringMap(statBonuses['stamina']);
    if (staminaBonus != null) {
      final stacks =
          staminaBonus['stacks_with_other_treasures'] as bool? ?? false;
      final staminaType = staminaBonus['type'] as String? ?? 'flat';

      final value = staminaType == 'highest_characteristic_multiplier'
          ? _getLeveledValue(staminaBonus, heroLevel) * highestCharacteristic
          : _getLeveledValue(staminaBonus, heroLevel);

      if (stacks) {
        stackingStamina += value;
      } else if (value > highestNonStackingStamina) {
        highestNonStackingStamina = value;
      }
    }

    final immunitiesData = _optionalStringMap(statBonuses['immunities']);
    if (immunitiesData != null) {
      for (final damageType in immunitiesData.keys) {
        final immunityData = _optionalStringMap(immunitiesData[damageType]);
        if (immunityData == null) continue;

        final immunityType = immunityData['type'] as String? ?? 'flat';
        final value = switch (immunityType) {
          'flat' => _getLeveledValue(immunityData, heroLevel),
          'highest_characteristic' =>
            _hasImmunityAtLevel(immunityData, heroLevel)
                ? highestCharacteristic
                : 0,
          _ => 0,
        };

        immunities[damageType] = (immunities[damageType] ?? 0) > value
            ? immunities[damageType]!
            : value;
      }
    }

    final speedBonus = _optionalStringMap(statBonuses['speed']);
    if (speedBonus != null) {
      speed += _getLeveledValue(speedBonus, heroLevel);
    }

    final stabilityBonus = _optionalStringMap(statBonuses['stability']);
    if (stabilityBonus != null) {
      stability += _getLeveledValue(stabilityBonus, heroLevel);
    }

    return EquippedTreasureBonuses(
      stamina: highestNonStackingStamina + stackingStamina,
      highestNonStackingStamina: highestNonStackingStamina,
      stackingStamina: stackingStamina,
      stability: stability,
      speed: speed,
      immunities: immunities,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> extractLeveledTreasureStatBonusesFromData(
    Map<String, dynamic> treasureData,
  ) {
    final legacyStatBonuses = _optionalStringMap(treasureData['stat_bonuses']);
    if (legacyStatBonuses != null) return legacyStatBonuses;

    final grants = treasureData['grants'];
    if (grants == null || !_looksLikeCanonicalGrants(grants)) return const {};

    final result = <String, dynamic>{};
    final immunities = <String, dynamic>{};
    final parsedGrants = CanonicalGrant.parseList(
      grants,
      defaultSource:
          'treasures/leveled_treasures.json:${treasureData['id'] ?? 'treasure'}',
    );

    for (final grant
        in parsedGrants.whereType<CanonicalEquipmentBonusesGrant>()) {
      for (final entry in grant.leveledBonuses.entries) {
        result[entry.key] = Map<String, dynamic>.from(entry.value);
      }
      for (final entry in grant.leveledImmunities.entries) {
        immunities[entry.key] = Map<String, dynamic>.from(entry.value);
      }
    }

    if (immunities.isNotEmpty) {
      result['immunities'] = immunities;
    }
    return result;
  }

  @visibleForTesting
  static EquippedTreasureBonuses calculateTrinketBonusesFromData(
    Map<String, dynamic> treasureData,
    int heroLevel,
  ) {
    final grants = treasureData['grants'];
    if (grants == null) return EquippedTreasureBonuses.empty();

    if (_looksLikeCanonicalGrants(grants)) {
      return _calculateCanonicalTrinketBonuses(
        grants,
        heroLevel,
        defaultSource:
            'treasures/trinkets.json:${treasureData['id'] ?? 'trinket'}',
      );
    }

    return _calculateLegacyTrinketBonuses(grants, heroLevel);
  }

  static EquippedTreasureBonuses _calculateCanonicalTrinketBonuses(
    Object grants,
    int heroLevel, {
    required String defaultSource,
  }) {
    var highestNonStackingStamina = 0;
    var stackingStamina = 0;
    var stability = 0;
    var speed = 0;
    final immunities = <String, int>{};

    final parsedGrants = CanonicalGrant.parseList(
      grants,
      defaultSource: defaultSource,
    );
    for (final grant in parsedGrants) {
      switch (grant) {
        case CanonicalStatModGrant():
          final value = grant.modifications.fold<int>(
            0,
            (sum, modification) => sum + modification.getActualValue(heroLevel),
          );
          final stat = _normalizeStatName(grant.stat);
          switch (stat) {
            case 'stamina':
              final stacks =
                  grant.payload?['stacks_with_other_treasures'] == true;
              if (stacks) {
                stackingStamina += value;
              } else if (value > highestNonStackingStamina) {
                highestNonStackingStamina = value;
              }
              break;
            case 'stability':
              stability += value;
              break;
            case 'speed':
              speed += value;
              break;
          }
        case CanonicalResistanceGrant():
          final value = _resolveResistanceValue(
            staticValue: grant.immunity,
            dynamicValue: grant.dynamicImmunity,
            perEchelonValue: grant.immunityPerEchelon,
            heroLevel: heroLevel,
          );
          if (value > 0) {
            final damageType = grant.damageType.toLowerCase();
            immunities[damageType] = (immunities[damageType] ?? 0) > value
                ? immunities[damageType]!
                : value;
          }
        default:
          break;
      }
    }

    return EquippedTreasureBonuses(
      stamina: highestNonStackingStamina + stackingStamina,
      highestNonStackingStamina: highestNonStackingStamina,
      stackingStamina: stackingStamina,
      stability: stability,
      speed: speed,
      immunities: immunities,
    );
  }

  static EquippedTreasureBonuses _calculateLegacyTrinketBonuses(
    Object grants,
    int heroLevel,
  ) {
    if (grants is! List) return EquippedTreasureBonuses.empty();

    var stackingStamina = 0;
    var stability = 0;
    var speed = 0;
    final immunities = <String, int>{};

    for (final grant in grants) {
      if (grant is! Map<String, dynamic>) continue;

      final increaseTotal = grant['increase_total'] as Map<String, dynamic>?;
      if (increaseTotal == null) continue;

      final stat = increaseTotal['stat'] as String? ?? '';
      final valueRaw = increaseTotal['value'];
      var value = 0;

      if (valueRaw is int) {
        value = valueRaw;
      } else if (valueRaw == 'level') {
        value = heroLevel;
      }

      switch (stat) {
        case 'stamina':
          // Bastion Belt explicitly stacks.
          stackingStamina += value;
          break;
        case 'stability':
          stability += value;
          break;
        case 'speed':
          speed += value;
          break;
        case 'immunity':
          final immunityType = increaseTotal['type'] as String? ?? 'damage';
          immunities[immunityType] = (immunities[immunityType] ?? 0) > value
              ? immunities[immunityType]!
              : value;
          break;
      }
    }

    return EquippedTreasureBonuses(
      stamina: stackingStamina,
      highestNonStackingStamina: 0,
      stackingStamina: stackingStamina,
      stability: stability,
      speed: speed,
      immunities: immunities,
    );
  }

  static bool _looksLikeCanonicalGrants(Object grants) {
    if (grants is Map) {
      if (grants['schema'] == canonicalGrantSchemaId) return true;
      if (grants.containsKey('kind')) return true;
      final nested = grants['grants'];
      return nested != null && _looksLikeCanonicalGrants(nested);
    }
    if (grants is List) {
      return grants.any(
        (grant) => grant is Map && grant.containsKey('kind'),
      );
    }
    return false;
  }

  static String _normalizeStatName(String stat) =>
      stat.trim().toLowerCase().replaceAll(' ', '_');

  static int _resolveResistanceValue({
    required int staticValue,
    required String? dynamicValue,
    required int perEchelonValue,
    required int heroLevel,
  }) {
    var value = staticValue;
    if (dynamicValue != null) {
      final normalized = dynamicValue.trim().toLowerCase();
      if (normalized == 'level') {
        value += heroLevel;
      } else {
        value += int.tryParse(normalized) ?? 0;
      }
    }
    if (perEchelonValue != 0) {
      value += perEchelonValue * (((heroLevel - 1) ~/ 3) + 1);
    }
    return value;
  }

  /// Get the appropriate value for a leveled treasure based on hero level.
  static int _getLeveledValue(Map<String, dynamic> bonus, int heroLevel) {
    if (heroLevel >= 9 && bonus['level_9'] != null) {
      return bonus['level_9'] as int? ?? 0;
    } else if (heroLevel >= 5 && bonus['level_5'] != null) {
      return bonus['level_5'] as int? ?? 0;
    } else if (bonus['level_1'] != null) {
      return bonus['level_1'] as int? ?? 0;
    }
    // Fallback for flat values
    return bonus['value'] as int? ?? 0;
  }

  /// Check if an immunity with highest_characteristic type is active at the hero's level.
  /// These immunities use boolean values (true/false) per level to indicate availability.
  static bool _hasImmunityAtLevel(
      Map<String, dynamic> immunityData, int heroLevel) {
    if (heroLevel >= 9 && immunityData['level_9'] != null) {
      return immunityData['level_9'] == true;
    } else if (heroLevel >= 5 && immunityData['level_5'] != null) {
      return immunityData['level_5'] == true;
    } else if (immunityData['level_1'] != null) {
      return immunityData['level_1'] == true;
    }
    return false;
  }

  static Map<String, dynamic>? _optionalStringMap(Object? value) {
    if (value is! Map) return null;
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value
    };
  }

  /// Save all equipped treasure bonuses to hero values.
  Future<void> saveEquippedTreasureBonuses(
    String heroId,
    EquippedTreasureBonuses bonuses,
  ) async {
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'treasure.equipped_stamina_bonus',
      value: bonuses.stamina,
    );
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'treasure.equipped_stability_bonus',
      value: bonuses.stability,
    );
    await _db.upsertHeroValue(
      heroId: heroId,
      key: 'treasure.equipped_speed_bonus',
      value: bonuses.speed,
    );
  }

  /// Recalculate and save all equipped treasure bonuses.
  /// Call this when treasures are equipped/unequipped.
  Future<EquippedTreasureBonuses> recalculateAndSaveEquippedBonuses(
    String heroId,
    int heroLevel,
  ) async {
    final bonuses = await calculateEquippedTreasureBonuses(heroId, heroLevel);
    await saveEquippedTreasureBonuses(heroId, bonuses);
    return bonuses;
  }
}

/// Model for equipped treasure bonuses.
class EquippedTreasureBonuses {
  const EquippedTreasureBonuses({
    required this.stamina,
    required this.highestNonStackingStamina,
    required this.stackingStamina,
    required this.stability,
    required this.speed,
    required this.immunities,
  });

  static const EquippedTreasureBonuses _empty = EquippedTreasureBonuses(
    stamina: 0,
    highestNonStackingStamina: 0,
    stackingStamina: 0,
    stability: 0,
    speed: 0,
    immunities: {},
  );

  static EquippedTreasureBonuses empty() => _empty;

  final int stamina;
  final int highestNonStackingStamina;
  final int stackingStamina;
  final int stability;
  final int speed;
  final Map<String, int> immunities;

  EquippedTreasureBonuses copyWith({
    int? stamina,
    int? highestNonStackingStamina,
    int? stackingStamina,
    int? stability,
    int? speed,
    Map<String, int>? immunities,
  }) {
    return EquippedTreasureBonuses(
      stamina: stamina ?? this.stamina,
      highestNonStackingStamina:
          highestNonStackingStamina ?? this.highestNonStackingStamina,
      stackingStamina: stackingStamina ?? this.stackingStamina,
      stability: stability ?? this.stability,
      speed: speed ?? this.speed,
      immunities: immunities ?? this.immunities,
    );
  }

  @override
  String toString() {
    return 'EquippedTreasureBonuses(stamina: $stamina, stability: $stability, speed: $speed, immunities: $immunities)';
  }
}
