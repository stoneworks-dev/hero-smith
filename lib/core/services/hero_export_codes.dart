/// Hero Export Pick Codes
///
/// This file contains all the code mappings used in the picks-only export format.
/// Edit these to customize what gets exported and how.
///
/// FORMAT: P:NAME|pick1;pick2;pick3...
/// Each pick is: CODE:value or CODE.sub:value or CODE:val1,val2
library;

// =============================================================================
// PICK CODES - Used in the P: export format
// =============================================================================

/// Pick type codes for export
/// Format in export: CODE:value
const pickCodes = {
  // === STORY PICKS ===
  'ancestry': 'a', // a:dragon_knight
  'traits': 't', // t:trait1,trait2
  'trait_choice': 't.', // t.traitId:choice (prefix, traitId appended)
  'culture_environment': 'ce', // ce:secluded
  'culture_organisation': 'co', // co:bureaucratic
  'culture_upbringing': 'cu', // cu:creative
  'culture_skills': 'cs', // cs:skill1,skill2,skill3
  'career': 'r', // r:aristocrat
  'career_skills': 'rs', // rs:skill1,skill2
  'career_perk': 'rp', // rp:linguist
  'career_perk_choice': 'rp.', // rp.perkId.key:value (prefix)
  'inciting_incident': 'ri', // ri:Royal Pauper
  'complication': 'w', // w:animal_form
  'languages': 'l', // l:lang1,lang2
  'all_skills': 'sk', // sk:skill1,skill2

  // === STRIFE PICKS ===
  'class': 'c', // c:censor
  'subclass': 's', // s:Oracle
  'char_array': 'ca', // ca:balanced (array name)
  'char_map': 'cm', // cm:m>2,a>1,r>0,i>1,p>0
  'level_choices': 'lv', // lv:3>m,5>a (level>stat)
  'feature_selection': 'fs', // fs:featureId>choice1,choice2

  // === STRENGTH PICKS ===
  'kit': 'k', // k:panther
  'kit_skill': 'ks', // ks:stealth
  'kit_equipment': 'ke', // ke:slot>itemId
  'deity': 'd', // d:adun
  'domains': 'o', // o:Life,Death
  'domain_skill': 'os', // os:skillId
  'title': 'n', // n:dragonslayer

  // === MANUAL PICKS ===
  'abilities': 'ab', // ab:ability1,ability2
  'perks': 'pk', // pk:perk1,perk2
  'equipment': 'eq', // eq:item1,item2

  // === META ===
  'level': 'lv#', // lv#:5 (only if > 1)
};

/// Reverse lookup: code -> pick type
final codeToPickType = {
  for (final e in pickCodes.entries)
    if (!e.value.endsWith('.')) e.value: e.key
};

// =============================================================================
// CHARACTERISTIC CODES - Single char for stat names
// =============================================================================

const statCodes = {
  'might': 'm',
  'agility': 'a',
  'reason': 'r',
  'intuition': 'i',
  'presence': 'p',
};

final codeToStat = {for (final e in statCodes.entries) e.value: e.key};

// =============================================================================
// ID PREFIXES TO STRIP - Makes IDs shorter in export
// =============================================================================

/// Prefixes stripped from IDs during export, restored during import
const idPrefixes = [
  'ancestry_',
  'ancestry_trait_',
  'career_',
  'skill_',
  'language_',
  'ability_',
  'complication_',
  'culture_',
  'environment_',
  'organisation_',
  'upbringing_',
  'deity_',
  'perk_',
  'domain_',
  'kit_',
  'class_',
  'subclass_',
  'title_',
  'feature_',
  'censor_', // class-specific prefixes
  'conduit_',
  'elementalist_',
  'fury_',
  'null_',
  'shadow_',
  'tactician_',
  'talent_',
  'troubadour_',
];

// =============================================================================
// RUNTIME STATE CODES - For optional runtime export
// =============================================================================

const runtimeCodes = {
  'stamina.current': 'h', // h42
  'stamina.temp': 't', // t5
  'recoveries.current': 'c', // c8
  'heroic.current': 'e', // e3
  'surges.current': 'sg', // sg2
  'heroTokens.current': 'tk', // tk1
  'score.victories': 'v', // v3
  'score.exp': 'x', // x12
  'score.wealth': 'w', // w4
  'score.renown': 'rn', // rn2
  'conditions.list': 'cd', // cd:<base64 json>
  'resistances.immunities': 'im', // im:<base64 json>
  'mods.map': 'mm', // mm:<base64 json>
  'heroic.resource': 'er', // er:<base64 text>
};

final codeToRuntime = {for (final e in runtimeCodes.entries) e.value: e.key};

// =============================================================================
// CORE STATS CODES - For optional full export
// =============================================================================

const coreStatCodes = {
  'basics.level': 'L',
  'stats.might': 'M',
  'stats.agility': 'A',
  'stats.reason': 'R',
  'stats.intuition': 'I',
  'stats.presence': 'P',
  'stats.size': 'Z',
  'stats.speed': 'V',
  'stats.stability': 'Y',
  'stats.disengage': 'D',
  'stamina.max': 'H',
  'recoveries.max': 'C',
  'recoveries.value': 'RV',
  'heroic.resource': 'HR',
  'score.victories': 'V',
  'score.exp': 'X',
  'score.wealth': 'W',
  'score.renown': 'RN',
};

final codeToCoreStats = {for (final e in coreStatCodes.entries) e.value: e.key};

// =============================================================================
// USER DATA CODES - For optional user data export
// =============================================================================

const userDataCodes = {
  'projects': 'p',
  'followers': 'f',
  'sources': 's',
  'treasures': 't',
};

// =============================================================================
// NOTES/DATA CODES - For optional notes/data export (base64 JSON)
// =============================================================================

const notesDataCodes = {
  'notes': 'n',
  'coin_purse': 'cp',
  'inventory': 'i',
};

// =============================================================================
// CONFIG KEYS - Essential configs that store user choices
// =============================================================================

/// Config keys that contain user picks (read during export)
const essentialConfigKeys = [
  // Story
  'ancestry.trait_choices',
  'culture.environment.skill',
  'culture.organisation.skill',
  'culture.upbringing.skill',
  'career.chosen_skills',
  'career.chosen_perks',
  'career.inciting_incident',
  // Strife
  'strife.characteristic_array',
  'strife.characteristic_assignments',
  'strife.level_choice_selections',
  'class_feature.selections',
  'strife.class_feature_selections',
  // Strength
  'kit.selections',
  // Dynamic: perk.{id}.selections
];

// =============================================================================
// SHORTS - Short codes for various hero aspects
// =============================================================================

//Classes
const classShorts = {
  // Full IDs
  'class_censor': 'CE',
  'class_conduit': 'CO',
  'class_elementalist': 'EL',
  'class_fury': 'FU',
  'class_null': 'NU',
  'class_shadow': 'SH',
  'class_tactician': 'TA',
  'class_talent': 'TL',
  'class_troubadour': 'TR',
  // Stripped versions
  'censor': 'CE',
  'conduit': 'CO',
  'elementalist': 'EL',
  'fury': 'FU',
  'null': 'NU',
  'shadow': 'SH',
  'tactician': 'TA',
  'talent': 'TL',
  'troubadour': 'TR',
};

//Subclasses
const subclassShorts = {
  // Full IDs
  'subclass_exorcist': 'EX',
  'subclass_oracle': 'OR',
  'subclass_paragon': 'PA',
  'subclass_earth': 'EA',
  'subclass_fire': 'FI',
  'subclass_green': 'GR',
  'subclass_void': 'VO',
  'subclass_berserker': 'BE',
  'subclass_reaver': 'RE',
  'subclass_stormwight': 'ST',
  'subclass_chronokinetic': 'CK',
  'subclass_cryokinetic': 'CR',
  'subclass_metakinetic': 'MK',
  'subclass_black_ash': 'BA',
  'subclass_caustic_alchemy': 'CA',
  'subclass_harlequin_mask': 'HM',
  'subclass_insurgent': 'IN',
  'subclass_mastermind': 'MM',
  'subclass_vanguard': 'VA',
  'subclass_chronopathy': 'CH',
  'subclass_telekinesis': 'TE',
  'subclass_telepathy': 'TP',
  'subclass_auteur': 'AU',
  'subclass_duelist': 'DU',
  'subclass_virtuoso': 'VI',
  // Stripped versions
  'exorcist': 'EX',
  'oracle': 'OR',
  'paragon': 'PA',
  'earth': 'EA',
  'fire': 'FI',
  'green': 'GR',
  'void': 'VO',
  'berserker': 'BE',
  'reaver': 'RE',
  'stormwight': 'ST',
  'chronokinetic': 'CK',
  'cryokinetic': 'CR',
  'metakinetic': 'MK',
  'black_ash': 'BA',
  'caustic_alchemy': 'CA',
  'harlequin_mask': 'HM',
  'insurgent': 'IN',
  'mastermind': 'MM',
  'vanguard': 'VA',
  'chronopathy': 'CH',
  'telekinesis': 'TE',
  'telepathy': 'TP',
  'auteur': 'AU',
  'duelist': 'DU',
  'virtuoso': 'VI',
};

//Domains
const domainsShorts = {
  'creation': 'CR',
  'death': 'DE',
  'fate': 'FA',
  'knowledge': 'KN',
  'life': 'LI',
  'love': 'LO',
  'nature': 'NA',
  'protection': 'PR',
  'storm': 'ST',
  'sun': 'SU',
  'trickery': 'TR',
  'war': 'WA',
};

// Ancestries
const ancestryShorts = {
  'devil': 'DV',
  'dragon_knight': 'DK',
  'dwarf': 'DW',
  'wode_elf': 'WE',
  'high_elf': 'HE',
  'hakaan': 'HA',
  'human': 'HU',
  'memonek': 'ME',
  'orc': 'OR',
  'polder': 'PO',
  'revenant': 'RV',
  'time_raider': 'TR',
};

// Ancestry Traits - Format: ANCESTRY_PREFIX.TRAIT_SHORT
const ancestryTraitsShorts = {
  // Devil traits
  'devil_barbed_tail': 'DV.BT',
  'devil_beast_legs': 'DV.BL',
  'devil_glowing_eyes': 'DV.GE',
  'devil_hellsight': 'DV.HS',
  'devil_impressive_horns': 'DV.IH',
  'devil_prehensile_tail': 'DV.PT',
  'devil_wings': 'DV.WI',
  // Dragon Knight traits
  'dk_draconian_guard': 'DK.DG',
  'dk_draconian_pride': 'DK.DP',
  'dk_dragon_breath': 'DK.DB',
  'dk_prismatic_scales': 'DK.PS',
  'dk_remember_your_oath': 'DK.RO',
  'dk_wings': 'DK.WI',
  // Dwarf traits
  'dwarf_great_fortitude': 'DW.GF',
  'dwarf_grounded': 'DW.GR',
  'dwarf_spark_off_your_skin': 'DW.SS',
  'dwarf_stand_tough': 'DW.ST',
  'dwarf_stone_singer': 'DW.SG',
  // Wode Elf traits
  'wode_forest_walk': 'WE.FW',
  'wode_quick_and_brutal': 'WE.QB',
  'wode_otherworldly_grace': 'WE.OG',
  'wode_revisit_memory': 'WE.RM',
  'wode_swift': 'WE.SW',
  'wode_the_wode_defends': 'WE.WD',
  // High Elf traits
  'high_elf_glamor_of_terror': 'HE.GT',
  'high_elf_graceful_retreat': 'HE.GR',
  'high_elf_high_senses': 'HE.HS',
  'high_elf_otherworldly_grace': 'HE.OG',
  'high_elf_revisit_memory': 'HE.RM',
  'high_elf_unstoppable_mind': 'HE.UM',
  // Hakaan traits
  'hakaan_all_is_a_feather': 'HA.AF',
  'hakaan_doomsight': 'HA.DS',
  'hakaan_forceful': 'HA.FO',
  'hakaan_great_fortitude': 'HA.GF',
  'hakaan_stand_tough': 'HA.ST',
  // Human traits
  'human_cant_take_hold': 'HU.CH',
  'human_determination': 'HU.DE',
  'human_perseverance': 'HU.PE',
  'human_resist_the_unnatural': 'HU.RU',
  'human_staying_power': 'HU.SP',
  // Memonek traits
  'memonek_i_am_law': 'ME.IL',
  'memonek_keeper_of_order': 'ME.KO',
  'memonek_lightning_nimbleness': 'ME.LN',
  'memonek_nonstop': 'ME.NS',
  'memonek_systematic_mind': 'ME.SM',
  'memonek_unphased': 'ME.UP',
  'memonek_useful_emotion': 'ME.UE',
  // Orc traits
  'orc_bloodfire_rush': 'OR.BR',
  'orc_glowing_recovery': 'OR.GR',
  'orc_grounded': 'OR.GD',
  'orc_nonstop': 'OR.NS',
  'orc_passionate_artisan': 'OR.PA',
  // Polder traits
  'polder_corruption_immunity': 'PO.CI',
  'polder_fearless': 'PO.FE',
  'polder_graceful_retreat': 'PO.GR',
  'polder_nimblestep': 'PO.NM',
  'polder_polder_geist': 'PO.PG',
  'polder_reactive_tumble': 'PO.RT',
  // Revenant traits
  'revenant_bloodless': 'RV.BL',
  'revenant_undead_influence': 'RV.UI',
  'revenant_vengeance_mark': 'RV.VM',
  // Time Raider traits
  'tr_beyondsight': 'TR.BS',
  'tr_foresight': 'TR.FO',
  'tr_four_armed_athletics': 'TR.FA',
  'tr_four_armed_martial_arts': 'TR.FM',
  'tr_psionic_gift': 'TR.PG',
  'tr_unstoppable_mind': 'TR.UM',
};

// Culture
const cultureEnvironmentShorts = {
  // Full IDs
  'environment_wilderness': 'WL',
  'environment_urban': 'UR',
  'environment_secluded': 'SE',
  'environment_rural': 'RU',
  'environment_nomadic': 'NO',
  // Stripped versions (for fallback)
  'wilderness': 'WL',
  'urban': 'UR',
  'secluded': 'SE',
  'rural': 'RU',
  'nomadic': 'NO',
};

const cultureOrganisationShorts = {
  // Full IDs
  'organisation_communal': 'CO',
  'organisation_bureaucratic': 'BU',
  // Stripped versions
  'communal': 'CO',
  'bureaucratic': 'BU',
};

const cultureUpbringingShorts = {
  // Full IDs
  'upbringing_noble': 'NO',
  'upbringing_martial': 'MA',
  'upbringing_lawless': 'LA',
  'upbringing_labor': 'LB',
  'upbringing_creative': 'CR',
  'upbringing_academic': 'AC',
  // Stripped versions
  'noble': 'NO',
  'martial': 'MA',
  'lawless': 'LA',
  'labor': 'LB',
  'creative': 'CR',
  'academic': 'AC',
};

// Careers
const careerShorts = {
  'career_agent': 'AG',
  'career_aristocrat': 'AR',
  'career_artisan': 'AT',
  'career_beggar': 'BE',
  'career_criminal': 'CR',
  'career_disciple': 'DI',
  'career_explorer': 'EX',
  'career_farmer': 'FA',
  'career_gladiator': 'GL',
  'career_laborer': 'LA',
  'career_mages_apprentice': 'MA',
  'career_performer': 'PE',
  'career_politician': 'PO',
  'career_sage': 'SA',
  'career_sailor': 'SL',
  'career_soldier': 'SO',
  'career_warden': 'WA',
  'career_watch_officer': 'WO',
};

// Inciting Incidents - grouped by career
const incitingIncidentShorts = {
  // Agent
  'Disavowed': 'AG.DI',
  'Faceless': 'AG.FA',
  'Free Agent': 'AG.FR',
  'Informed': 'AG.IN',
  'Spies and Lovers': 'AG.SL',
  'Turncoat': 'AG.TU',
  // Aristocrat
  'Blood Money': 'AR.BM',
  'Charmed Life': 'AR.CL',
  'Inheritance': 'AR.IN',
  'Privileged Position': 'AR.PP',
  'Royal Pauper': 'AR.RP',
  'Wicked Secret': 'AR.WS',
  // Artisan
  'Continue the Work': 'AT.CW',
  'Inspired': 'AT.IN',
  'Robbery': 'AT.RO',
  'Stolen Passions': 'AT.SP',
  'Tarnished Honor': 'AT.TH',
  'Twisted Skill': 'AT.TS',
  // Beggar
  'Champion': 'BE.CH',
  'Night Terrors': 'BE.NT',
  'One Good Deed': 'BE.OG',
  'Precious': 'BE.PR',
  'Strange Charity': 'BE.SC',
  'Witness': 'BE.WI',
  // Criminal
  'Antiquity Procurement': 'CR.AP',
  'Atonement': 'CR.AT',
  'Friendly Priest': 'CR.FP',
  'Shadowed Influence': 'CR.SI',
  'Simply Survival': 'CR.SS',
  'Stand Against Tyranny': 'CR.ST',
  // Disciple
  "Angel's Advocate": 'DI.AA',
  'Dogma': 'DI.DO',
  'Freedom to Worship': 'DI.FW',
  'Lost Faith': 'DI.LF',
  'Near-Death Experience': 'DI.ND',
  'Taxing Times': 'DI.TT',
  // Explorer
  'Awakening': 'EX.AW',
  'Missing Piece': 'EX.MP',
  'Nothing Belongs in a Museum': 'EX.NB',
  'Unschooled': 'EX.UN',
  'Wanderlust': 'EX.WA',
  'Wind in Your Sails': 'EX.WS',
  // Farmer
  'Blight': 'FA.BL',
  'Bored': 'FA.BO',
  'Cursed': 'FA.CU',
  'Hard Times': 'FA.HT',
  'Razed': 'FA.RA',
  'Stolen': 'FA.ST',
  // Gladiator
  'Betrayed': 'GL.BE',
  'Heckler': 'GL.HE',
  'Joined the Arena': 'GL.JA',
  'New Challenges': 'GL.NC',
  "Scion's Compassion": 'GL.SC',
  "Warriors' Home": 'GL.WH',
  // Laborer
  'Deep Sentinel': 'LA.DS',
  'Disaster': 'LA.DI',
  'Embarrassment': 'LA.EM',
  'Live the Dream': 'LA.LD',
  'Shining Light': 'LA.SL',
  'Slow and Steady': 'LA.SS',
  // Mage's Apprentice
  'Forgotten Memories': 'MA.FM',
  'Magic of Friendship': 'MA.MF',
  'Missing Mage': 'MA.MM',
  'Nightmares Made Flesh': 'MA.NM',
  'Otherworldly': 'MA.OW',
  'Ultimate Power': 'MA.UP',
  // Performer
  'Cursed Audience': 'PE.CA',
  'False Accolades': 'PE.FA',
  'Fame and Fortune': 'PE.FF',
  'Songs to the Dead': 'PE.SD',
  'Speechless': 'PE.SP',
  'Tragic Lesson': 'PE.TL',
  // Politician
  'Diplomatic Immunity': 'PO.DI',
  'Insurrectionist': 'PO.IN',
  'Respected Consul': 'PO.RC',
  'Right Side of History': 'PO.RS',
  'Self-Serving': 'PO.SS',
  'Unbound': 'PO.UB',
  // Sage
  'Bookish Ideas': 'SA.BI',
  'Cure the Curse': 'SA.CC',
  'Lost Library': 'SA.LL',
  'Paper Guilt': 'SA.PG',
  'Unforeseen Futures': 'SA.UF',
  'Vanishing': 'SA.VA',
  // Sailor
  'Alone': 'SL.AL',
  'Deserter': 'SL.DE',
  'Forgotten': 'SL.FO',
  'Jealousy': 'SL.JE',
  'Marooned': 'SL.MA',
  'Water Fear': 'SL.WF',
  // Soldier
  'Dishonorable Discharge': 'SO.DD',
  'Out of Retirement': 'SO.OR',
  'Peace Through Healing': 'SO.PH',
  'Sole Survivor': 'SO.SS',
  'Stolen Valor': 'SO.SV',
  'Vow of Sacrifice': 'SO.VS',
  // Warden
  // 'Betrayed': 'WA.BE', // duplicate with Gladiator
  'Corruption': 'WA.CO',
  'Exiled': 'WA.EX',
  'Honor the Fallen': 'WA.HF',
  'Portents': 'WA.PO',
  'Theft': 'WA.TH',
  // Watch Officer
  'Bigger Fish': 'WO.BF',
  'Corruption Within': 'WO.CW',
  'Frame Job': 'WO.FJ',
  'Missing Mentor': 'WO.MM',
  'One That Got Away': 'WO.OG',
  'Powerful Enemies': 'WO.PE',
};

// Complications
const complicationShorts = {
  'complication_advanced_studies': 'AS',
  'complication_amnesia': 'AM',
  'complication_animal_form': 'AF',
  'complication_antihero': 'AH',
  'complication_artifact_bonded': 'AB',
  'complication_bereaved': 'BR',
  'complication_betrothed': 'BT',
  'complication_chaos_touched': 'CT',
  'complication_chosen_one': 'CO',
  'complication_consuming_interest': 'CI',
  'complication_corrupted_mentor': 'CM',
  'complication_coward': 'CW',
  'complication_crash_landed': 'CL',
  'complication_cult_victim': 'CV',
  'complication_curse_of_caution': 'CC',
  'complication_curse_of_immortality': 'IM',
  'complication_curse_of_misfortune': 'MF',
  'complication_curse_of_poverty': 'CP',
  'complication_curse_of_punishment': 'PU',
  'complication_curse_of_stone': 'CS',
  'complication_cursed_weapon': 'CX',
  'complication_disgraced': 'DG',
  'complication_dragon_dreams': 'DD',
  'complication_elemental_inside': 'EI',
  'complication_evanesceria': 'EV',
  'complication_exile': 'EX',
  'complication_fallen_immortal': 'FI',
  'complication_famous_relative': 'FR',
  'complication_feytouched': 'FT',
  'complication_fiery_ideal': 'FD',
  'complication_fire_and_chaos': 'FC',
  'complication_following_in_the_footsteps': 'FF',
  'complication_forbidden_romance': 'FB',
  'complication_frostheart': 'FH',
  'complication_getting_too_old_for_this': 'GO',
  'complication_gnoll_mauled': 'GM',
  'complication_greening': 'GR',
  'complication_grifter': 'GT',
  'complication_grounded': 'GD',
  'complication_guilty_conscience': 'GC',
  'complication_hawk_rider': 'HR',
  'complication_host_body': 'HB',
  'complication_hunted': 'HU',
  'complication_hunter': 'HN',
  'complication_indebted': 'IN',
  'complication_infernal_contract': 'IC',
  'complication_infernal_contract_but_like_bad': 'IB',
  'complication_ivory_tower': 'IT',
  'complication_lifebonded': 'LB',
  'complication_lightning_soul': 'LS',
  'complication_loner': 'LO',
  'complication_lost_in_time': 'LT',
  'complication_lost_your_head': 'LH',
  'complication_lucky': 'LU',
  'complication_master_chef': 'MC',
  'complication_meddling_butler': 'MB',
  'complication_medium': 'MD',
  'complication_medusa_blood': 'MU',
  'complication_misunderstood': 'MI',
  'complication_mundane': 'MN',
  'complication_outlaw': 'OL',
  'complication_pirate': 'PI',
  'complication_preacher': 'PR',
  'complication_primordial_sickness': 'PS',
  'complication_prisoner_of_the_synlirii': 'SY',
  'complication_promising_apprentice': 'PA',
  'complication_psychic_eruption': 'PE',
  'complication_raised_by_beasts': 'RB',
  'complication_refugee': 'RF',
  'complication_rival': 'RI',
  'complication_rogue_talent': 'RT',
  'complication_runaway': 'RU',
  'complication_searching_for_a_cure': 'SC',
  'complication_secret_identity': 'SI',
  'complication_secret_twin': 'SW',
  'complication_self_taught': 'ST',
  'complication_sewer_folk': 'SF',
  'complication_shadow_born': 'SB',
  'complication_shared_spirit': 'SS',
  'complication_shattered_legacy': 'SL',
  'complication_shipwrecked': 'SH',
  'complication_siblings_shield': 'SD',
  'complication_silent_sentinel': 'SN',
  'complication_slight_case_of_lycanthropy': 'LY',
  'complication_stolen_face': 'TF',
  'complication_strange_inheritance': 'TI',
  'complication_stripped_of_rank': 'SR',
  'complication_thrill_seeker': 'TS',
  'complication_vampire_scion': 'VS',
  'complication_voice_in_your_head': 'VH',
  'complication_vow_of_duty': 'VD',
  'complication_vow_of_honesty': 'VO',
  'complication_waking_dreams': 'WD',
  'complication_war_dog_collar': 'WC',
  'complication_war_of_assassins': 'WA',
  'complication_ward': 'WR',
  'complication_waterborn': 'WB',
  'complication_wodewalker': 'WW',
  'complication_wrathful_spirit': 'WS',
  'complication_wrongly_imprisoned': 'WI',
};

// Deities (gods and saints)
const deityShorts = {
  // Gods
  'deity_adun': 'AD',
  'deity_cavall': 'CA',
  'deity_cyrvis': 'CY',
  'deity_kul': 'KU',
  'deity_nebular': 'NE',
  'deity_nikros': 'NI',
  'deity_ord': 'OR',
  'deity_ov': 'OV',
  'deity_salorna': 'SA',
  'deity_val': 'VA',
  // Saints
  'saint_atossa': 'S.AT',
  'saint_chokassa': 'S.CH',
  'saint_draighen': 'S.DR',
  'saint_eriarwen': 'S.ER',
  'saint_eseld': 'S.ES',
  'saint_gaed': 'S.GA',
  'saint_grole': 'S.GR',
  'saint_gryffyn': 'S.GY',
  'saint_gwenllian': 'S.GW',
  'saint_illwyv': 'S.IL',
  'saint_khorvath': 'S.KH',
  'saint_khravila': 'S.KR',
  'saint_kyruyalka': 'S.KY',
  'saint_magnetar': 'S.MA',
  'saint_llewellyn': 'S.LL',
  'saint_mahsiti': 'S.MH',
  'saint_pentalion': 'S.PE',
  'saint_prexaspes': 'S.PR',
  'saint_ripples': 'S.RI',
  'saint_sea_of_suns': 'S.SS',
  'saint_stakros': 'S.ST',
  'saint_taste_morning': 'S.TM',
  'saint_thellasko': 'S.TH',
  'saint_thyll': 'S.TY',
  'saint_uryal': 'S.UR',
  'saint_valak': 'S.VA',
  'saint_yllin': 'S.YL',
  'saint_zarok': 'S.ZA',
};

// Languages
const languageShorts = {
  // Human languages
  'language_uvalic': 'UV',
  'language_higaran': 'HG',
  'language_oaxuatl': 'OX',
  'language_khemharic': 'KH',
  'language_khoursirian': 'KS',
  'language_phaedric': 'PH',
  'language_riojan': 'RJ',
  'language_variac': 'VR',
  'language_vaniric': 'VN',
  'language_vaslorian': 'VL',
  'language_korthite': 'KT',
  'language_court_speech': 'CS',
  // Ancestral languages
  'language_anjali': 'AJ',
  'language_axiomatic': 'AX',
  'language_caelian': 'CL',
  'language_filiaric': 'FL',
  'language_the_first_language': 'TF',
  'language_hyrallic': 'HY',
  'language_illyric': 'IL',
  'language_kalliak': 'KL',
  'language_kethaic': 'KE',
  'language_khelt': 'KE2',
  'language_low_kuric': 'LK',
  'language_mindspeech': 'MS',
  'language_proto_ctholl': 'PC',
  'language_szetch': 'SZ',
  'language_tholl': 'TH',
  'language_urollaic': 'UR',
  'language_vastariax': 'VX',
  'language_vhoric': 'VH',
  'language_voll': 'VO',
  'language_yllyric': 'YL',
  'language_zahariax': 'ZH',
  'language_zaliac': 'ZL',
  'language_zodiakol': 'ZK',
  'language_hakaan': 'HA',
  'language_kalliak_human_dialect': 'KD',
  'language_kheltish': 'KI',
  'language_minaran': 'MN',
  'language_zantarim': 'ZT',
  'language_faelish': 'FA',
  'language_galethic': 'GA',
  'language_kelonic': 'KO',
  'language_oaxic': 'OA',
  'language_wodic': 'WD',
  'language_kollaric': 'KR',
  'language_high_kuric': 'HK',
  'language_valianic': 'VL2',
  // Dead languages
  'language_ananjali': 'AN',
  'language_high_rhyvian': 'HR',
  'language_khamish': 'KM',
  'language_kheltivari': 'KV',
  'language_low_rhyvian': 'LR',
  'language_old_variac': 'OV',
  'language_phorialtic': 'PL',
  'language_rallarian': 'RL',
  'language_ullorvic': 'UL',
};

// Skills
const skillShorts = {
  // Crafting
  'skill_alchemy': 'AL',
  'skill_architecture': 'AR',
  'skill_blacksmithing': 'BL',
  'skill_carpentry': 'CA',
  'skill_cooking': 'CK',
  'skill_fletching': 'FL',
  'skill_forgery': 'FG',
  'skill_jewelry': 'JW',
  'skill_mechanics': 'MC',
  'skill_tailoring': 'TL',
  // Exploration
  'skill_climb': 'CL',
  'skill_drive': 'DR',
  'skill_endurance': 'EN',
  'skill_gymnastics': 'GY',
  'skill_heal': 'HE',
  'skill_jump': 'JU',
  'skill_lift': 'LI',
  'skill_navigate': 'NV',
  'skill_ride': 'RI',
  'skill_swim': 'SW',
  // Interpersonal
  'skill_brag': 'BR',
  'skill_empathize': 'EM',
  'skill_flirt': 'FT',
  'skill_gamble': 'GM',
  'skill_handle_animals': 'HA',
  'skill_interrogate': 'IN',
  'skill_intimidate': 'IT',
  'skill_lead': 'LD',
  'skill_lie': 'LY',
  'skill_music': 'MU',
  'skill_perform': 'PF',
  'skill_persuade': 'PS',
  'skill_read_person': 'RP',
  // Intrigue
  'skill_alertness': 'AT',
  'skill_conceal_object': 'CO',
  'skill_disguise': 'DI',
  'skill_eavesdrop': 'EV',
  'skill_escape_artist': 'EA',
  'skill_hide': 'HI',
  'skill_pick_lock': 'PL',
  'skill_pick_pocket': 'PP',
  'skill_sabotage': 'SB',
  'skill_search': 'SE',
  'skill_sneak': 'SN',
  'skill_track': 'TR',
  // Lore
  'skill_criminal_underworld': 'CU',
  'skill_culture': 'CT',
  'skill_history': 'HY',
  'skill_magic': 'MG',
  'skill_monsters': 'MO',
  'skill_nature': 'NA',
  'skill_psionics': 'PN',
  'skill_religion': 'RE',
  'skill_rumors': 'RU',
  'skill_society': 'SO',
  'skill_strategy': 'ST',
  'skill_timescape': 'TS',
};

// Perks
const perkShorts = {
  // Crafting perks
  'area_of_expertise': 'AE',
  'expert_artisan': 'EA',
  'handy': 'HN',
  'improvisation_creation': 'IC',
  'inspired_artisan': 'IA',
  'traveling_artisan': 'TA',
  // Exploration perks
  'brawny': 'BW',
  'camouflage_hunter': 'CH',
  'danger_sense': 'DS',
  'friend_catapult': 'FC',
  'ive_got_you': 'IG',
  'monster_whisperer': 'MW',
  'put_your_back_into_it': 'PB',
  'team_leader': 'TL',
  'teamwork': 'TW',
  'wood_wise': 'WW',
  // Interpersonal perks
  'charming_liar': 'CL',
  'dazzler': 'DZ',
  'engrossing_monologue': 'EM',
  'harmonizer': 'HZ',
  'lie_detector': 'LD',
  'open_book': 'OB',
  'pardon_my_friend': 'PM',
  'power_player': 'PP',
  'so_tell_me': 'ST',
  'spot_the_tell': 'TT',
  // Intrigue perks
  'criminal_contacts': 'CC',
  'forgettable_face': 'FF',
  'gum_up_the_works': 'GW',
  'lucky_dog': 'LK',
  'master_of_disguise': 'MD',
  'slipped_lead': 'SL',
  // Lore perks
  'but_i_know_who_does': 'BK',
  'eidetic_memory': 'ED',
  'expert_sage': 'ES',
  'ive_read_about_this_place': 'IR',
  'linguist': 'LG',
  'polymath': 'PY',
  'specialist': 'SP',
  'traveling_sage': 'TS',
  // Supernatural perks
  'arcane_trick': 'AT',
  'creature_sense': 'CS',
  'familiar': 'FM',
  'invisible_force': 'IF',
  'psychic_whisper': 'PW',
  'ritualist': 'RT',
  'thingspeaker': 'TK',
};

// Titles (main titles only, not sub-abilities)
const titleShorts = {
  // Echelon 1
  'ancient_loremaster': 'AL',
  'battleaxe_diplomat': 'BD',
  'brawler': 'BR',
  'city_rat': 'CR',
  'doomed': 'DM',
  'dwarven_legionnaire': 'DL',
  'elemental_dabbler': 'ED',
  'faction_member': 'FM',
  'local_hero': 'LH',
  'mage_hunter': 'MH',
  'marshal': 'MS',
  'monster_bane': 'MB',
  'owed_a_favor': 'OF',
  'presumed_dead': 'PD',
  'ratcatcher': 'RC',
  'saved_for_a_worse_fate': 'SF',
  'ship_captain': 'SC',
  'troupe_leading_player': 'TP',
  'wanted_dead_or_alive': 'WD',
  'zombie_slayer': 'ZS',
  // Echelon 2
  'arena_fighter': 'AF',
  'awakened': 'AW',
  'battlefield_commander': 'BC',
  'blood_magic': 'BM',
  'corsair': 'CO',
  'faction_officer': 'FO',
  'fey_friend': 'FF',
  'giant_slayer': 'GS',
  'godsworn': 'GW',
  'heist_hero': 'HH',
  'knight': 'KN',
  'master_librarian': 'ML',
  'special_agent': 'SA',
  'sworn_hunter': 'SH',
  'undead_slain': 'US',
  'unstoppable': 'UN',
  // Echelon 3
  'armed_and_dangerous': 'AD',
  'back_from_the_grave': 'BG',
  'demon_slayer': 'DS',
  'diabolist': 'DB',
  'dragon_blooded': 'DR',
  'fleet_admiral': 'FA',
  'maestro': 'MA',
  'master_crafter': 'MC',
  'noble': 'NO',
  'planar_voyager': 'PV',
  'scarred': 'SR',
  'siege_breaker': 'SB',
  'teacher': 'TC',
  // Echelon 4
  'champion_competitor': 'CC',
  'demigod': 'DG',
};

// Conditions
const conditionShorts = {
  'condition_bleeding': 'BL',
  'condition_dazed': 'DZ',
  'condition_frightened': 'FR',
  'condition_grabbed': 'GR',
  'condition_prone': 'PR',
  'condition_restrained': 'RS',
  'condition_slowed': 'SL',
  'condition_taunted': 'TA',
  'condition_weakened': 'WK',
  'condition_strained': 'ST',
};

// =============================================================================
// TREASURES - Artifacts, Consumables, Leveled Treasures, Trinkets
// =============================================================================

// Artifacts (legendary items)
const artefactShorts = {
  'blade_of_a_thousand_years': 'BT',
  'encepter': 'EN',
  'mortal_coil': 'MC',
};

// Consumables
const consumableShorts = {
  // Echelon 1
  'black_ash_dart': 'BD',
  'blood_essence_vial': 'BV',
  'buzz_balm': 'BB',
  'catapult_dust': 'CD',
  'giants_blood_flame': 'GF',
  'growth_potion': 'GP',
  'healing_potion': 'HP',
  'imps_tongue': 'IT',
  'lachomp_tooth': 'LT',
  'mirror_token': 'MT',
  'pocket_homunculus': 'PH',
  'portable_cloud': 'PC',
  'professor_veratismos_quaff_n_huf_snuff': 'QS',
  'snapdragon': 'SD',
  // Echelon 2
  'breath_of_dawn': 'BO',
  'bull_shot': 'BS',
  'chocolate_of_immovability': 'CI',
  'concealment_potion': 'CP',
  'float_powder': 'FP',
  'purified_jelly': 'PJ',
  'scroll_of_resurrection': 'SR',
  'telemagnet': 'TM',
  'vial_of_ethereal_attack': 'VA',
  // Echelon 3
  'anamorphic_larva': 'AL',
  'bottled_paradox': 'BP',
  'gallios_visiting_card': 'GV',
  'personal_effigy': 'PE',
  'stygian_liquor': 'SL',
  'timesplitter': 'TS',
  'ward_token': 'WT',
  'wellness_tonic': 'WN',
  // Echelon 4
  'breath_of_creation': 'BC',
  'elixir_of_saint_elspeth': 'ES',
  'page_from_the_infinite_library_solaris': 'PL',
  'restorative_of_the_bright_court': 'RB',
};

// Leveled Treasures (armor, shields, weapons, implements)
const leveledTreasureShorts = {
  // Armor
  'adaptive_second_skin_of_toxins': 'AS',
  'chain_of_the_sea_and_sky': 'CS',
  'grand_scarab': 'GS',
  'kuranzoi_prismscale': 'KP',
  'paper_trappings': 'PT',
  'shrouded_memory': 'SM',
  'spiny_turtle': 'SP',
  'star_hunter': 'SH',
  // Shields
  'kings_roar': 'KR',
  'telekinetic_bulwark': 'TB',
  // Implements
  'abjurers_bastion': 'AB',
  'brittlebreaker': 'BB',
  'ether_fueled_vessel': 'EV',
  'chaldorb': 'CH',
  'foesense_lenses': 'FL',
  'words_become_wonders_at_next_breath': 'WW',
  // Weapons
  'authoritys_end': 'AE',
  'blade_of_quintessence': 'BQ',
  'blade_of_the_luxurious_fop': 'BL',
  'displacer': 'DP',
  'executioners_blade': 'EB',
  'icemaker_maul': 'IM',
  'knife_of_nine': 'KN',
  'lance_of_the_sundered_star': 'LS',
  'molten_constrictor': 'MC',
  'onerous_bow': 'OB',
  'steeltongue': 'ST',
  'third_eye_seeker': 'TE',
  'thunderhead_bident': 'TH',
  'wetwork': 'WK',
  // Other
  'thief_of_joy': 'TJ',
  'bloodbound_band': 'BD',
  'bloody_hand_wraps': 'BH',
  'lightning_treads': 'LT',
  'revengers_wrap': 'RW',
};

// Trinkets
const trinketShorts = {
  // Echelon 1
  'color_cloak_blue': 'CB',
  'color_cloak_red': 'CR',
  'color_cloak_yellow': 'CY',
  'deadweight': 'DW',
  'displacing_replacement_bracer': 'DR',
  'divine_vine': 'DV',
  'flameshade_gloves': 'FG',
  'gecko_gloves': 'GG',
  'hellcharger_helm': 'HH',
  'mask_of_the_many': 'MM',
  'quantum_satchel': 'QS',
  'unbinder_boots': 'UB',
  // Echelon 2
  'bastion_belt': 'BAB',
  'evilest_eye': 'EE',
  'insightful_crown': 'IC',
  'key_of_inquiry': 'KI',
  'mediators_charm': 'MC',
  'necklace_of_the_bayou': 'NB',
  'scannerstone': 'SS',
  'stop_n_go_coin': 'SG',
  // Echelon 3
  'bracers_of_strife': 'BS',
  'mask_of_oversight': 'MO',
  'mirage_band': 'MB',
  'nullfield_resonator_ring': 'NR',
  'shifting_ring': 'SR',
  // Echelon 4
  'gravekeepers_lantern': 'GL',
  'psi_blade': 'PB',
};

// =============================================================================
// KITS & KIT-LIKE OPTIONS
// =============================================================================

// Standard Kits
const kitShorts = {
  'kit_arcane_archer': 'AA',
  'kit_battlemind': 'BM',
  'kit_cloak_and_dagger': 'CD',
  'kit_dual_wielder': 'DW',
  'kit_guisarmier': 'GU',
  'kit_martial_artist': 'MA',
  'kit_mountain': 'MT',
  'kit_panther': 'PA',
  'kit_pugilist': 'PU',
  'kit_raider': 'RA',
  'kit_ranger': 'RG',
  'kit_rapid_fire': 'RF',
  'kit_retiarius': 'RE',
  'kit_shining_armor': 'SA',
  'kit_sniper': 'SN',
  'kit_spellsword': 'SS',
  'kit_stick_and_robe': 'SR',
  'kit_swashbuckler': 'SW',
  'kit_sword_and_board': 'SB',
  'kit_warrior_priest': 'WP',
  'kit_whirlwind': 'WW',
};

// Stormwight Kits (Fury)
const stormwightKitShorts = {
  'kit_boren': 'BO',
  'kit_corven': 'CO',
  'kit_raden': 'RD',
  'kit_vulken': 'VU',
};

// Psionic Augmentations (Talent/Null)
const augmentationShorts = {
  'battle_augmentation': 'BA',
  'distance_augmentation': 'DI',
  'density_augmentation': 'DE',
  'force_augmentation': 'FO',
  'speed_augmentation': 'SP',
};

// Enchantments (Troubadour/Elementalist)
const enchantmentShorts = {
  'enchantment_of_battle': 'BA',
  'enchantment_of_celerity': 'CE',
  'enchantment_of_destruction': 'DE',
  'enchantment_of_distance': 'DI',
  'enchantment_of_permanence': 'PE',
};

// Prayers (Conduit)
const prayerShorts = {
  'prayer_of_destruction': 'DE',
  'prayer_of_distance': 'DI',
  'prayer_OF_soldier_skill': 'SS',
  'prayer_of_speed': 'SP',
  'prayer_of_steel': 'ST',
};

// Wards
const wardShorts = {
  // Talent wards
  'entropy_ward': 'EN',
  'repulsive_ward': 'RP',
  'steel_ward': 'ST',
  'vanishing_ward': 'VA',
  // Conduit wards
  'bastion_ward': 'BA',
  'quickness_ward': 'QU',
  'sanctuary_ward': 'SA',
  'spirit_ward': 'SP',
  // Elementalist wards
  'ward_delightful_consequences': 'DC',
  'ward_excellent_protection': 'EP',
  'ward_nature_affection': 'NA',
  'ward_surprising_reactivity': 'SR',
};

// =============================================================================
// ITEM IMBUEMENTS
// =============================================================================

// Armor Imbuements - 1st Level
const armorImbuement1stShorts = {
  'awe_armor_imbuement_1st': 'AW',
  'damage_immunity_armor_imbuement_1st': 'DI',
  'disguise_armor_imbuement_1st': 'DS',
  'iridescent_armor_imbuement_1st': 'IR',
  'magic_resistance_armor_imbuement_1st': 'MR',
  'nettlebloom_armor_imbuement_1st': 'NB',
  'phasing_armor_imbuement_1st': 'PH',
  'psionic_resistance_armor_imbuement_1st': 'PR',
  'swift_armor_imbuement_1st': 'SW',
  'tempest_armor_imbuement_1st': 'TE',
};

// Armor Imbuements - 5th Level
const armorImbuement5thShorts = {
  'absorption_armor_imbuement_5th': 'AB',
  'damage_immunity_ii_armor_imbuement_5th': 'D2',
  'dragon_soul_armor_imbuement_5th': 'DS',
  'levitating_armor_imbuement_5th': 'LV',
  'magic_resistance_ii_armor_imbuement_5th': 'M2',
  'phasing_ii_armor_imbuement_5th': 'P2',
  'psionic_resistance_ii_armor_imbuement_5th': 'R2',
  'reactive_armor_imbuement_5th': 'RE',
  'second_wind_armor_imbuement_5th': 'SW',
  'shattering_armor_imbuement_5th': 'SH',
  'tempest_ii_armor_imbuement_5th': 'T2',
};

// Armor Imbuements - 9th Level
const armorImbuement9thShorts = {
  'devils_bargain_armor_imbuement_9th': 'DB',
  'dragon_soul_ii_armor_imbuement_9th': 'D2',
  'invulnerable_armor_imbuement_9th': 'IN',
  'leyline_walker_armor_imbuement_9th': 'LW',
  'life_armor_imbuement_9th': 'LF',
  'magic_resistance_iii_armor_imbuement_9th': 'M3',
  'phasing_iii_armor_imbuement_9th': 'P3',
  'psionic_resistance_iii_armor_imbuement_9th': 'R3',
  'temporal_flux_armor_imbuement_9th': 'TF',
  'unbending_armor_imbuement_9th': 'UB',
};

// Implement Imbuements - 1st Level
const implementImbuement1stShorts = {
  'berserking_implement_imbuement_1st': 'BE',
  'displacing_i_implement_imbuement_1st': 'D1',
  'elemental_implement_imbuement_1st': 'EL',
  'forceful_i_implement_imbuement_1st': 'F1',
  'rat_form_implement_imbuement_1st': 'RF',
  'rejuvenating_i_implement_imbuement_1st': 'R1',
  'seeking_implement_imbuement_1st': 'SE',
  'thought_sending_implement_imbuement_1st': 'TS',
  'warding_i_implement_imbuement_1st': 'W1',
};

// Implement Imbuements - 5th Level
const implementImbuement5thShorts = {
  'celerity_implement_imbuement_5th': 'CE',
  'celestine_implement_imbuement_5th': 'CL',
  'displacing_ii_implement_imbuement_5th': 'D2',
  'erupting_i_implement_imbuement_5th': 'E1',
  'forceful_ii_implement_imbuement_5th': 'F2',
  'hallucinatory_implement_imbuement_5th': 'HA',
  'lingering_i_implement_imbuement_5th': 'L1',
  'rejuvenating_ii_implement_imbuement_5th': 'R2',
  'warding_ii_implement_imbuement_5th': 'W2',
};

// Implement Imbuements - 9th Level
const implementImbuement9thShorts = {
  'anathema_implement_imbuement_9th': 'AN',
  'displacing_iii_implement_imbuement_9th': 'D3',
  'erupting_ii_implement_imbuement_9th': 'E2',
  'forceful_iii_implement_imbuement_9th': 'F3',
  'lingering_ii_implement_imbuement_9th': 'L2',
  'piercing_implement_imbuement_9th': 'PI',
  'psionic_siphon_implement_imbuement_9th': 'PS',
  'rejuvenating_iii_implement_imbuement_9th': 'R3',
  'warding_iii_implement_imbuement_9th': 'W3',
};

// Weapon Imbuements - 1st Level
const weaponImbuement1stShorts = {
  'blood_bargain_weapon_imbuement_1st': 'BB',
  'chilling_i_weapon_imbuement_1st': 'C1',
  'disrupting_i_weapon_imbuement_1st': 'D1',
  'hurling_weapon_imbuement_1st': 'HU',
  'merciful_weapon_imbuement_1st': 'ME',
  'terrifying_i_weapon_imbuement_1st': 'T1',
  'thundering_i_weapon_imbuement_1st': 'H1',
  'vengeance_i_weapon_imbuement_1st': 'V1',
  'wingbane_weapon_imbuement_1st': 'WB',
};

// Weapon Imbuements - 5th Level
const weaponImbuement5thShorts = {
  'chargebreaker_weapon_imbuement_5th': 'CB',
  'chilling_ii_weapon_imbuement_5th': 'C2',
  'devastating_weapon_imbuement_5th': 'DV',
  'disrupting_ii_weapon_imbuement_5th': 'D2',
  'metamorphic_weapon_imbuement_5th': 'MM',
  'silencing_weapon_imbuement_5th': 'SI',
  'terrifying_ii_weapon_imbuement_5th': 'T2',
  'thundering_ii_weapon_imbuement_5th': 'H2',
  'vengeance_ii_weapon_imbuement_5th': 'V2',
};

// Weapon Imbuements - 9th Level
const weaponImbuement9thShorts = {
  'chilling_iii_weapon_imbuement_9th': 'C3',
  'disrupting_iii_weapon_imbuement_9th': 'D3',
  'draining_weapon_imbuement_9th': 'DR',
  'imprisoning_weapon_imbuement_9th': 'IM',
  'nova_weapon_imbuement_9th': 'NO',
  'terrifying_iii_weapon_imbuement_9th': 'T3',
  'thundering_iii_weapon_imbuement_9th': 'H3',
  'vengeance_iii_weapon_imbuement_9th': 'V3',
  'windcutting_weapon_imbuement_9th': 'WC',
};

// =============================================================================
// DOWNTIME PROJECTS
// =============================================================================

const downtimeProjectShorts = {
  // Crafting projects
  'build_airship': 'BA',
  'build_or_repair_road': 'BR',
  'craft_teleportation_platform': 'CT',
  'craft_treasure': 'CR',
  // Research projects
  'find_a_cure': 'FC',
  'discover_lore_common': 'DC',
  'discover_lore_obscure': 'DO',
  'discover_lore_lost': 'DL',
  'discover_lore_forbidden': 'DF',
  'study_lore': 'SL',
  // Training projects
  'hone_career_skills': 'HC',
  'learn_from_master_hone_ability': 'LH',
  'learn_from_master_improve_control': 'LI',
  'learn_from_master_acquire_ability': 'LA',
  'learn_new_language': 'LL',
  'learn_new_skill': 'LS',
  // Lifestyle projects
  'perfect_new_recipe_modern': 'RM',
  'perfect_new_recipe_vintage_or_home': 'RV',
  'perfect_new_recipe_ancient_or_lost': 'RA',
  'community_service': 'CS',
  'spend_time_with_loved_ones': 'ST',
  'fishing': 'FI',
};

// Reverse lookup maps for import
final shortsToClass = {for (final e in classShorts.entries) e.value: e.key};
final shortsToSubclass = {
  for (final e in subclassShorts.entries) e.value: e.key
};
final shortsToDomain = {for (final e in domainsShorts.entries) e.value: e.key};
final shortsToAncestry = {
  for (final e in ancestryShorts.entries) e.value: e.key
};
final shortsToAncestryTrait = {
  for (final e in ancestryTraitsShorts.entries) e.value: e.key
};
final shortsToCultureEnvironment = {
  for (final e in cultureEnvironmentShorts.entries) e.value: e.key
};
final shortsToCultureOrganisation = {
  for (final e in cultureOrganisationShorts.entries) e.value: e.key
};
final shortsToCultureUpbringing = {
  for (final e in cultureUpbringingShorts.entries) e.value: e.key
};
final shortsToCareer = {for (final e in careerShorts.entries) e.value: e.key};
final shortsToIncitingIncident = {
  for (final e in incitingIncidentShorts.entries) e.value: e.key
};
final shortsToComplication = {
  for (final e in complicationShorts.entries) e.value: e.key
};
final shortsToDeity = {for (final e in deityShorts.entries) e.value: e.key};
final shortsToLanguage = {
  for (final e in languageShorts.entries) e.value: e.key
};
final shortsToSkill = {for (final e in skillShorts.entries) e.value: e.key};
final shortsToPerk = {for (final e in perkShorts.entries) e.value: e.key};
final shortsToTitle = {for (final e in titleShorts.entries) e.value: e.key};
final shortsToCondition = {
  for (final e in conditionShorts.entries) e.value: e.key
};
final shortsToArtefact = {
  for (final e in artefactShorts.entries) e.value: e.key
};
final shortsToConsumable = {
  for (final e in consumableShorts.entries) e.value: e.key
};
final shortsToLeveledTreasure = {
  for (final e in leveledTreasureShorts.entries) e.value: e.key
};
final shortsToTrinket = {for (final e in trinketShorts.entries) e.value: e.key};
final shortsToKit = {for (final e in kitShorts.entries) e.value: e.key};
final shortsToStormwightKit = {
  for (final e in stormwightKitShorts.entries) e.value: e.key
};
final shortsToAugmentation = {
  for (final e in augmentationShorts.entries) e.value: e.key
};
final shortsToEnchantment = {
  for (final e in enchantmentShorts.entries) e.value: e.key
};
final shortsToPrayer = {for (final e in prayerShorts.entries) e.value: e.key};
final shortsToWard = {for (final e in wardShorts.entries) e.value: e.key};
final shortsToArmorImbuement1st = {
  for (final e in armorImbuement1stShorts.entries) e.value: e.key
};
final shortsToArmorImbuement5th = {
  for (final e in armorImbuement5thShorts.entries) e.value: e.key
};
final shortsToArmorImbuement9th = {
  for (final e in armorImbuement9thShorts.entries) e.value: e.key
};
final shortsToImplementImbuement1st = {
  for (final e in implementImbuement1stShorts.entries) e.value: e.key
};
final shortsToImplementImbuement5th = {
  for (final e in implementImbuement5thShorts.entries) e.value: e.key
};
final shortsToImplementImbuement9th = {
  for (final e in implementImbuement9thShorts.entries) e.value: e.key
};
final shortsToWeaponImbuement1st = {
  for (final e in weaponImbuement1stShorts.entries) e.value: e.key
};
final shortsToWeaponImbuement5th = {
  for (final e in weaponImbuement5thShorts.entries) e.value: e.key
};
final shortsToWeaponImbuement9th = {
  for (final e in weaponImbuement9thShorts.entries) e.value: e.key
};
final shortsToDowntimeProject = {
  for (final e in downtimeProjectShorts.entries) e.value: e.key
};
