/// Central vocabulary for the hero storage split.
///
/// Keep storage keys and entry/source tokens here before using them in
/// validators, normalizers, repositories, services, or UI write paths.
class HeroValueKeys {
  HeroValueKeys._();

  static const String legacyPerkAbilitiesPrefix = 'perk_abilities.';
  static const String legacyPerkGrantPrefix = 'perk_grant.';
  static const String legacyStrifeEquipmentIds = 'strife.equipment_ids';
  static const String legacyEquipmentBonuses = 'strife.equipment_bonuses';
  static const String legacyFeatureStatBonuses = 'strife.feature_stat_bonuses';

  static const String basicsEquipment = 'basics.equipment';
  static const String level = 'basics.level';
  static const String dynamicModifiers = 'dynamic_modifiers';
  static const String heroTokensCurrent = 'heroTokens.current';
  static const String careerProjectPointsUsed = 'career.project_points_used';
  static const String complicationTokens = 'complication.tokens';
  static const String complicationTokensCurrent = 'complication.tokens_current';
  static const String complicationRecoveryBonus = 'complication.recovery_bonus';
  static const String complicationOriginalBaseStats =
      'complication.original_base_stats';
  static const String downtimeStoryProjectPoints =
      'downtime.story_project_points';
  static const String treasureHighestBonusStamina =
      'treasure.highest_bonus_stamina';
  static const String treasureEquippedStaminaBonus =
      'treasure.equipped_stamina_bonus';
  static const String treasureEquippedStabilityBonus =
      'treasure.equipped_stability_bonus';
  static const String treasureEquippedSpeedBonus =
      'treasure.equipped_speed_bonus';

  static const Set<String> allowedPrefixes = {
    'stats.',
    'stamina.',
    'recoveries.',
    'resistances.',
    'conditions.',
    'potency.',
    'score.',
    'projects.',
    'heroic.',
    'surges.',
    'mods.',
  };

  static const Set<String> coreAllowedExactKeys = {
    level,
    dynamicModifiers,
    heroTokensCurrent,
    careerProjectPointsUsed,
    complicationTokensCurrent,
    complicationRecoveryBonus,
    downtimeStoryProjectPoints,
  };

  /// Transitional keys still written by current services/UI.
  /// Each one should be removed or reclassified in a later checked step.
  static const Set<String> temporaryAllowedExactKeys = {
    treasureHighestBonusStamina,
    treasureEquippedStaminaBonus,
    treasureEquippedStabilityBonus,
    treasureEquippedSpeedBonus,
  };

  static const Set<String> bannedExactKeys = {
    basicsEquipment,
    legacyStrifeEquipmentIds,
    complicationTokens,
    complicationOriginalBaseStats,
  };

  static const Set<String> allowedExactKeys = {
    ...coreAllowedExactKeys,
    ...temporaryAllowedExactKeys,
  };

  static const List<String> bannedPrefixes = [
    'basics.className',
    'basics.subclass',
    'basics.ancestry',
    'basics.career',
    'basics.kit',
    'ancestry.granted_abilities',
    'ancestry.applied_bonuses',
    'ancestry.condition_immunities',
    'ancestry.stat_mods',
    'ancestry.selected_traits',
    legacyPerkAbilitiesPrefix,
    legacyPerkGrantPrefix,
    'complication.applied_grants',
    'complication.abilities',
    'complication.skills',
    'complication.features',
    'complication.treasures',
    'complication.languages',
    'complication.damage_resistances',
    'complication.stat_mods',
    'class_feature.',
    'class_feature_abilities',
    'class_feature_skills',
    'class_feature_stat_mods',
    'class_feature_resistances',
    'kit_grants.',
    'kit.abilities',
    'kit.equipment',
    'kit.stat_bonuses',
    'kit.signature_ability',
    legacyEquipmentBonuses,
    legacyFeatureStatBonuses,
    'career.abilities',
    'career.skills_granted',
    'career.perks_granted',
    'culture.skills_granted',
    'culture.languages_granted',
    'faith.deity',
    'faith.domain',
  ];

  static bool isAllowed(String key) {
    return allowedExactKeys.contains(key) ||
        allowedPrefixes.any((prefix) => key.startsWith(prefix));
  }

  static bool isBanned(String key) {
    return bannedExactKeys.contains(key) ||
        bannedPrefixes.any((prefix) => key.startsWith(prefix));
  }
}

class HeroEntryTypes {
  HeroEntryTypes._();

  static const String ability = 'ability';
  static const String ancestry = 'ancestry';
  static const String ancestryTrait = 'ancestry_trait';
  static const String career = 'career';
  static const String classEntry = 'class';
  static const String classFeature = 'class_feature';
  static const String complication = 'complication';
  static const String conditionImmunity = 'condition_immunity';
  static const String culture = 'culture';
  static const String cultureEnvironment = 'culture_environment';
  static const String cultureOrganisation = 'culture_organisation';
  static const String cultureUpbringing = 'culture_upbringing';
  static const String damageResistance = 'damage_resistance';
  static const String deity = 'deity';
  static const String domain = 'domain';
  static const String equipment = 'equipment';
  static const String equipmentBonuses = 'equipment_bonuses';
  static const String feature = 'feature';
  static const String featureStatBonus = 'feature_stat_bonus';
  static const String imbuement = 'imbuement';
  static const String immunity = 'immunity';
  static const String itemPrerequisite = 'item_prerequisite';
  static const String kit = 'kit';
  static const String kitFeature = 'kit_feature';
  static const String kitStatBonus = 'kit_stat_bonus';
  static const String language = 'language';
  static const String perk = 'perk';
  static const String resistance = 'resistance';
  static const String skill = 'skill';
  static const String statMod = 'stat_mod';
  static const String subclass = 'subclass';
  static const String title = 'title';
  static const String treasure = 'treasure';
  static const String weakness = 'weakness';

  static const Set<String> validTypes = {
    ability,
    ancestry,
    ancestryTrait,
    career,
    classEntry,
    classFeature,
    complication,
    conditionImmunity,
    culture,
    cultureEnvironment,
    cultureOrganisation,
    cultureUpbringing,
    damageResistance,
    deity,
    domain,
    equipment,
    equipmentBonuses,
    feature,
    featureStatBonus,
    imbuement,
    immunity,
    itemPrerequisite,
    kit,
    kitFeature,
    kitStatBonus,
    language,
    perk,
    resistance,
    skill,
    statMod,
    subclass,
    title,
    treasure,
    weakness,
  };

  static const Set<String> componentBackedTypes = {
    ability,
    ancestry,
    ancestryTrait,
    career,
    classEntry,
    classFeature,
    complication,
    culture,
    cultureEnvironment,
    cultureOrganisation,
    cultureUpbringing,
    deity,
    domain,
    equipment,
    feature,
    imbuement,
    kit,
    language,
    perk,
    skill,
    subclass,
    title,
    treasure,
  };

  static const Set<String> resistanceTypes = {
    resistance,
    damageResistance,
    immunity,
    weakness,
  };

  static const Set<String> bannedTypes = {};

  static bool isValid(String entryType) => validTypes.contains(entryType);

  static String? componentLookupId(String entryType, String entryId) {
    if (!componentBackedTypes.contains(entryType)) return null;
    if (entryType == title && entryId.contains(':')) {
      return entryId.split(':').first;
    }
    return entryId;
  }
}

class HeroEntrySourceTypes {
  HeroEntrySourceTypes._();

  static const String ancestry = 'ancestry';
  static const String career = 'career';
  static const String classEntry = 'class';
  static const String classFeature = 'class_feature';
  static const String complication = 'complication';
  static const String complicationAncestryTrait = 'complication_ancestry_trait';
  static const String culture = 'culture';
  static const String deity = 'deity';
  static const String domain = 'domain';
  static const String equipment = 'equipment';
  static const String heroSheet = 'hero_sheet';
  static const String import = 'import';
  static const String kit = 'kit';
  static const String legacy = 'legacy';
  static const String legacyComponent = 'legacy_component';
  static const String manualChoice = 'manual_choice';
  static const String perk = 'perk';
  static const String subclass = 'subclass';
  static const String title = 'title';

  static const Set<String> validTypes = {
    ancestry,
    career,
    classEntry,
    classFeature,
    complication,
    complicationAncestryTrait,
    culture,
    deity,
    domain,
    equipment,
    heroSheet,
    import,
    kit,
    legacy,
    legacyComponent,
    manualChoice,
    perk,
    subclass,
    title,
  };

  static bool isValid(String sourceType) => validTypes.contains(sourceType);
}

class HeroEntrySourceIds {
  HeroEntrySourceIds._();

  static const String careerChoice = 'career_choice';
  static const String cultureEnvironment = 'culture_environment';
  static const String cultureLanguages = 'culture_languages';
  static const String cultureOrganisation = 'culture_organisation';
  static const String cultureUpbringing = 'culture_upbringing';
  static const String domainChoice = 'domain_choice';
  static const String equipmentSlots = 'equipment_slots';
  static const String kitCombined = 'combined';
  static const String sheetAdd = 'sheet_add';
  static const String strifeAbilityChoice = HeroEntryTypes.ability;
  static const String strifePerkChoice = HeroEntryTypes.perk;
  static const String strifeSkillChoice = HeroEntryTypes.skill;
  static const String subclassSkill = 'subclass_skill';
}

class HeroEntryGainedBy {
  HeroEntryGainedBy._();

  static const String calculated = 'calculated';
  static const String choice = 'choice';
  static const String grant = 'grant';

  static const Set<String> validValues = {
    calculated,
    choice,
    grant,
  };

  static bool isValid(String gainedBy) => validValues.contains(gainedBy);
}

class HeroConfigKeys {
  HeroConfigKeys._();

  static const String ancestrySignatureName = 'ancestry.signature_name';
  static const String ancestryAppliedBonuses = 'ancestry.applied_bonuses';
  static const String ancestryTraitChoices = 'ancestry.trait_choices';
  static const String basicsEquipment = HeroValueKeys.basicsEquipment;
  static const String basicsKit = 'basics.kit';
  static const String careerChosenPerks = 'career.chosen_perks';
  static const String careerChosenSkills = 'career.chosen_skills';
  static const String careerChosenLanguages = 'career.chosen_languages';
  static const String careerIncitingIncident = 'career.inciting_incident';
  static const String classFeatureSelections = 'class_feature.selections';
  static const String classFeatureSkillGroupSelections =
      'class_feature.skill_group_selections';
  static const String classFeatureSubclassKey = 'class_feature.subclass_key';
  static const String complicationAppliedGrants = 'complication.applied_grants';
  static const String complicationChoices = 'complication.choices';
  static const String complicationOriginalBaseStats =
      HeroValueKeys.complicationOriginalBaseStats;
  static const String complicationTokens = HeroValueKeys.complicationTokens;
  static const String cultureEnvironmentSkill = 'culture.environment.skill';
  static const String cultureLanguageSelection = 'culture.language_selection';
  static const String cultureOrganisationSkill = 'culture.organisation.skill';
  static const String cultureUpbringingSkill = 'culture.upbringing.skill';
  static const String equipmentSlots = 'equipment.slots';
  static const String gearFavoriteKits = 'gear.favorite_kits';
  static const String gearInventoryContainers = 'gear.inventory_containers';
  static const String gearInventoryLooseItems = 'gear.inventory_loose_items';
  static const String importNeedsSaveStory = 'import.needs_save_story';
  static const String importNeedsSaveStrife = 'import.needs_save_strife';
  static const String kitSelections = 'kit.selections';
  static const String strifeAbilitySelections = 'strife.ability_selections';
  static const String strifeCharacteristicArray = 'strife.characteristic_array';
  static const String strifeCharacteristicAssignments =
      'strife.characteristic_assignments';
  static const String strifeClassFeatureSelections =
      'strife.class_feature_selections';
  static const String strifeImportAbilityIds = 'strife.import_ability_ids';
  static const String strifeLevelChoiceSelections =
      'strife.level_choice_selections';
  static const String strifePerkSelections = 'strife.perk_selections';
  static const String strifeSkillSelections = 'strife.skill_selections';
  static const String strifeSubclassKey = 'strife.subclass_key';
  static const String strifeSubclassSkillId = 'strife.subclass_skill_id';
  static const String titleAncestryTraitChoices =
      'title.ancestry_trait_choices';
  static const String titleAncestryTraits = 'title.ancestry_traits';
  static const String titleCharacteristicChoices =
      'title.characteristic_choices';
  static const String titleDamageTypeChoices = 'title.damage_type_choices';
  static const String titleHeroicAbilityChoices =
      'title.heroic_ability_choices';
  static const String titleLanguageChoices = 'title.language_choices';
  static const String titleProgress = 'title_progress';
  static const String titleSkillChoices = 'title.skill_choices';
  static const String xpSpeed = 'progression.xp_speed';

  static String perkSelections(String perkId) => 'perk.$perkId.selections';

  static const Set<String> knownExactKeys = {
    ancestrySignatureName,
    ancestryAppliedBonuses,
    ancestryTraitChoices,
    careerChosenPerks,
    careerChosenSkills,
    careerChosenLanguages,
    careerIncitingIncident,
    classFeatureSelections,
    classFeatureSkillGroupSelections,
    classFeatureSubclassKey,
    complicationAppliedGrants,
    complicationChoices,
    complicationOriginalBaseStats,
    complicationTokens,
    cultureEnvironmentSkill,
    cultureLanguageSelection,
    cultureOrganisationSkill,
    cultureUpbringingSkill,
    equipmentSlots,
    gearFavoriteKits,
    gearInventoryContainers,
    gearInventoryLooseItems,
    importNeedsSaveStory,
    importNeedsSaveStrife,
    kitSelections,
    strifeAbilitySelections,
    strifeCharacteristicArray,
    strifeCharacteristicAssignments,
    strifeClassFeatureSelections,
    strifeImportAbilityIds,
    strifeLevelChoiceSelections,
    strifePerkSelections,
    strifeSkillSelections,
    strifeSubclassKey,
    strifeSubclassSkillId,
    titleAncestryTraitChoices,
    titleAncestryTraits,
    titleCharacteristicChoices,
    titleDamageTypeChoices,
    titleHeroicAbilityChoices,
    titleLanguageChoices,
    titleProgress,
    titleSkillChoices,
    xpSpeed,
  };

  static const Set<String> knownPrefixes = {
    'perk.',
  };

  static const Set<String> bannedKeys = {
    'ancestry.stat_mods',
    'complication.stat_mods',
    'strife.class_feature.subclass_key',
  };

  static bool isKnown(String key) {
    return knownExactKeys.contains(key) ||
        knownPrefixes.any((prefix) => key.startsWith(prefix));
  }

  static bool isBanned(String key) => bannedKeys.contains(key);
}
