import '../db/app_database.dart' as db;
import 'damage_resistance_model.dart';
import 'stat_modification_model.dart';

/// A unified in-memory view of a hero combining numeric/state values,
/// content entries, and configuration.
/// 
/// This is the AUTHORITATIVE model for hero data, built from three storage layers:
/// - hero_values → numeric state (stats, stamina, recoveries, conditions, etc.)
/// - hero_entries → all content (abilities, skills, perks, equipment, etc.)
/// - hero_config → selections/choices metadata
class HeroAssembly {
  final String heroId;
  final String name;

  // ===========================================================================
  // IDENTITY (from hero_entries with entry_type = class/subclass/ancestry/etc.)
  // ===========================================================================
  final String? classId;
  final String? subclassId;
  final String? ancestryId;
  final String? careerId;
  final String? kitId;
  final String? deityId;
  final List<String> domainIds;

  // ===========================================================================
  // NUMERIC/STATE (from hero_values)
  // ===========================================================================
  final Map<String, int> stats; // might/agility/reason/intuition/presence/size/speed/disengage/stability
  final Map<String, int> stamina; // current/max/temp/winded/dying
  final Map<String, int> recoveries; // current/max/value
  final List<String> conditions;
  final Map<String, int> potency; // strong/average/weak
  final Map<String, int> counters; // wealth/renown/victories/exp/surges/project_points/heroic_current
  final Map<String, int> userMods; // from mods.map - user-managed temporary modifiers
  final int level;

  // ===========================================================================
  // RESISTANCES (aggregate from hero_values, individual entries from hero_entries)
  // ===========================================================================
  final HeroDamageResistances resistances;
  final List<db.HeroEntry> resistanceEntries; // raw resistance grants from hero_entries

  // ===========================================================================
  // STAT MODIFICATIONS (merged from all sources in hero_entries)
  // ===========================================================================
  final HeroStatModifications statMods; // merged from ancestry/perks/complications/class_features/kits
  final Map<String, List<db.HeroEntry>> statModsBySource; // grouped by source

  // ===========================================================================
  // CONTENT ENTRIES (from hero_entries)
  // ===========================================================================
  final List<db.HeroEntry> skills;
  final List<db.HeroEntry> perks;
  final List<db.HeroEntry> languages;
  final List<db.HeroEntry> abilities;
  final List<db.HeroEntry> titles;
  final List<db.HeroEntry> equipment;
  final List<db.HeroEntry> traits; // ancestry traits
  final List<db.HeroEntry> classFeatures;
  final List<db.HeroEntry> conditionImmunities;
  final List<db.HeroEntry> featureStatBonuses; // feature-granted stat bonuses

  // ===========================================================================
  // CONTENT GROUPED BY SOURCE (sourceType:sourceId)
  // ===========================================================================
  final Map<String, List<db.HeroEntry>> abilitiesBySource;
  final Map<String, List<db.HeroEntry>> skillsBySource;
  final Map<String, List<db.HeroEntry>> perksBySource;
  final Map<String, List<db.HeroEntry>> featuresBySource;
  final Map<String, List<db.HeroEntry>> languagesBySource;
  final Map<String, List<db.HeroEntry>> equipmentBySource;
  final Map<String, List<db.HeroEntry>> resistancesBySource;

  // ===========================================================================
  // RAW DATA (for advanced use cases)
  // ===========================================================================
  final Map<String, Map<String, dynamic>> config; // raw hero_config
  final Map<String, List<db.HeroEntry>> entriesBySource; // all entries grouped
  final Map<String, List<db.HeroEntry>> entriesByType; // all entries by type

  const HeroAssembly({
    required this.heroId,
    required this.name,
    // Identity
    this.classId,
    this.subclassId,
    this.ancestryId,
    this.careerId,
    this.kitId,
    this.deityId,
    this.domainIds = const [],
    // Numeric/state
    required this.stats,
    required this.stamina,
    required this.recoveries,
    required this.conditions,
    required this.potency,
    required this.counters,
    required this.userMods,
    required this.level,
    // Resistances
    required this.resistances,
    this.resistanceEntries = const [],
    // Stat mods
    required this.statMods,
    this.statModsBySource = const {},
    // Content entries
    this.skills = const [],
    this.perks = const [],
    this.languages = const [],
    this.abilities = const [],
    this.titles = const [],
    this.equipment = const [],
    this.traits = const [],
    this.classFeatures = const [],
    this.conditionImmunities = const [],
    this.featureStatBonuses = const [],
    // Grouped by source
    this.abilitiesBySource = const {},
    this.skillsBySource = const {},
    this.perksBySource = const {},
    this.featuresBySource = const {},
    this.languagesBySource = const {},
    this.equipmentBySource = const {},
    this.resistancesBySource = const {},
    // Raw data
    required this.config,
    this.entriesBySource = const {},
    this.entriesByType = const {},
  });

  // ===========================================================================
  // COMPUTED STATS (applying all modifiers)
  // ===========================================================================

  /// Get the final computed value for a stat, applying all modifiers.
  int getComputedStat(String stat) {
    final base = stats[stat] ?? 0;
    final modTotal = statMods.getTotalForStatAtLevel(stat, level);
    final userMod = userMods[stat] ?? 0;
    return base + modTotal + userMod;
  }

  /// Get breakdown of stat value sources.
  Map<String, int> getStatBreakdown(String stat) {
    return {
      'base': stats[stat] ?? 0,
      'mods': statMods.getTotalForStatAtLevel(stat, level),
      'user': userMods[stat] ?? 0,
      'total': getComputedStat(stat),
    };
  }

  // ===========================================================================
  // CONTENT ACCESSORS
  // ===========================================================================

  /// Get all ability IDs (entry_id values).
  List<String> get abilityIds => abilities.map((e) => e.entryId).toList();

  /// Get all skill IDs.
  List<String> get skillIds => skills.map((e) => e.entryId).toList();

  /// Get all perk IDs.
  List<String> get perkIds => perks.map((e) => e.entryId).toList();

  /// Get all language IDs.
  List<String> get languageIds => languages.map((e) => e.entryId).toList();

  /// Get all title IDs.
  List<String> get titleIds => titles.map((e) => e.entryId).toList();

  /// Get all equipment IDs.
  List<String> get equipmentIds => equipment.map((e) => e.entryId).toList();

  /// Get all trait IDs.
  List<String> get traitIds => traits.map((e) => e.entryId).toList();

  /// Get all class feature IDs.
  List<String> get classFeatureIds => classFeatures.map((e) => e.entryId).toList();

  // ===========================================================================
  // SOURCE FILTERING HELPERS
  // ===========================================================================

  /// Get abilities from a specific source type.
  List<db.HeroEntry> getAbilitiesFromSource(String sourceType, [String? sourceId]) {
    return abilities.where((e) {
      if (e.sourceType != sourceType) return false;
      if (sourceId != null && e.sourceId != sourceId) return false;
      return true;
    }).toList();
  }

  /// Get skills from a specific source type.
  List<db.HeroEntry> getSkillsFromSource(String sourceType, [String? sourceId]) {
    return skills.where((e) {
      if (e.sourceType != sourceType) return false;
      if (sourceId != null && e.sourceId != sourceId) return false;
      return true;
    }).toList();
  }

  /// Get all entries from a specific source.
  List<db.HeroEntry> getEntriesFromSource(String sourceType, String sourceId) {
    final key = '$sourceType:$sourceId';
    return entriesBySource[key] ?? [];
  }

  /// Get all entries of a specific type.
  List<db.HeroEntry> getEntriesByType(String entryType) {
    return entriesByType[entryType] ?? [];
  }

  // ===========================================================================
  // RESISTANCE HELPERS
  // ===========================================================================

  /// Get net resistance value for a damage type (uses hero level for dynamic resistances).
  int getResistanceFor(String damageType) {
    final resistance = resistances.forType(damageType);
    return resistance?.netValueAtLevel(level) ?? 0;
  }

  /// Check if hero has immunity to a damage type.
  bool hasImmunityTo(String damageType) {
    return getResistanceFor(damageType) > 0;
  }

  /// Check if hero has weakness to a damage type.
  bool hasWeaknessTo(String damageType) {
    return getResistanceFor(damageType) < 0;
  }

  /// Get all condition immunities.
  List<String> get conditionImmunityIds => 
      conditionImmunities.map((e) => e.entryId).toList();

  // ===========================================================================
  // CONFIG ACCESSORS
  // ===========================================================================

  /// Get a config value by key.
  Map<String, dynamic>? getConfig(String key) => config[key];

  /// Get class feature selections.
  Map<String, dynamic>? get classFeatureSelections => 
      config['class_feature.selections'];

  /// Get kit selections.
  Map<String, dynamic>? get kitSelections => config['kit.selections'];

  /// Get ancestry trait choices.
  Map<String, dynamic>? get ancestryTraitChoices => 
      config['ancestry.trait_choices'];
}
