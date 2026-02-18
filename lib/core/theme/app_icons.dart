import 'package:flutter/material.dart';

import 'app_icon_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppIcons – centralised icon constants & mapping helpers.
//
// Domain-specific inner classes keep things discoverable:
//   AppIcons.nav.*      – main / sheet navigation tabs
//   AppIcons.classes.*   – per-class identity icons
//   AppIcons.levels.*    – hero-level tier icons
//   AppIcons.chars.*     – characteristic icons (Might, Agility…)
//   AppIcons.kits.*      – kit-type icons
//   AppIcons.treasures.* – treasure-type icons
//   AppIcons.imbuements.*– imbuement-type icons
//   AppIcons.prereqs.*   – prerequisite-type icons
//   AppIcons.projects.*  – downtime category icons
//   AppIcons.story.*     – story / identity icons
//   AppIcons.combat.*    – stamina, speed, stability…
//   AppIcons.abilities.* – abilities & features
//   AppIcons.perks.*     – perks & titles
//   AppIcons.notes.*     – notes system
//   AppIcons.io.*        – import / export / share
//   AppIcons.ui.*        – generic UI chrome
//
// Icons use game-icons.net SVGs (CC BY 3.0) for domain-specific imagery and
// Material Design icons for generic UI chrome.
// ─────────────────────────────────────────────────────────────────────────────

class AppIcons {
  AppIcons._();

  // ── Convenience aliases (legacy) ──────────────────────────────────────────
  static const AppIconData projects =
      SvgAppIcon('assets/icons/lorc/scroll-unfurled.svg');
  static const AppIconData imbuements =
      SvgAppIcon('assets/icons/lorc/anvil-impact.svg');
  static const AppIconData event = MaterialIcon(Icons.event_note);
  static const AppIconData dice =
      SvgAppIcon('assets/icons/delapouite/dice-twenty-faces-twenty.svg');
  static const AppIconData treasures =
      SvgAppIcon('assets/icons/lorc/gem-pendant.svg');

  // ── Sub-groups ────────────────────────────────────────────────────────────
  static const nav = NavIcons._();
  static const classes = ClassIcons._();
  static const levels = LevelIcons._();
  static const chars = CharacteristicIcons._();
  static const kits = KitIcons._();
  static const treasureTypes = TreasureIcons._();
  static const imbuementTypes = ImbuementIcons._();
  static const prereqs = PrerequisiteIcons._();
  static const projectCategories = ProjectCategoryIcons._();
  static const story = StoryIcons._();
  static const combat = CombatIcons._();
  static const abilities = AbilityIcons._();
  static const perks = PerkIcons._();
  static const notes = NoteIcons._();
  static const gear = GearIcons._();
  static const io = IoIcons._();
  static const ui = UiIcons._();
  static const damageTypes = DamageTypeIcons._();
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG path constants (private)
// ─────────────────────────────────────────────────────────────────────────────

class _Svg {
  _Svg._();
  // lorc
  static const anvil = 'assets/icons/lorc/anvil.svg';
  static const anvilImpact = 'assets/icons/lorc/anvil-impact.svg';
  static const backup = 'assets/icons/lorc/backup.svg';
  static const backstab = 'assets/icons/lorc/backstab.svg';
  static const barbute = 'assets/icons/lorc/barbute.svg';
  static const battleGear = 'assets/icons/lorc/battle-gear.svg';
  static const beveledStar = 'assets/icons/lorc/beveled-star.svg';
  static const allForOne = 'assets/icons/lorc/all-for-one.svg';
  static const bookmark = 'assets/icons/lorc/bookmark.svg';
  static const bookmarklet = 'assets/icons/lorc/bookmarklet.svg';
  static const bookAura = 'assets/icons/lorc/book-aura.svg';
  static const bouncingSword = 'assets/icons/lorc/bouncing-sword.svg';
  static const brain = 'assets/icons/lorc/brain.svg';
  static const borderedShield = 'assets/icons/lorc/bordered-shield.svg';
  static const burningBook = 'assets/icons/lorc/burning-book.svg';
  static const burningPassion = 'assets/icons/lorc/burning-passion.svg';
  static const candleSkull = 'assets/icons/lorc/candle-skull.svg';
  static const cash = 'assets/icons/lorc/cash.svg';
  static const checkboxTree = 'assets/icons/lorc/checkbox-tree.svg';
  static const choppedSkull = 'assets/icons/lorc/chopped-skull.svg';
  static const cloakDagger = 'assets/icons/lorc/cloak-dagger.svg';
  static const crackedHelm = 'assets/icons/lorc/cracked-helm.svg';
  static const cog = 'assets/icons/lorc/cog.svg';
  static const crossedAxes = 'assets/icons/lorc/crossed-axes.svg';
  static const crossedSwords = 'assets/icons/lorc/crossed-swords.svg';
  static const crownCoin = 'assets/icons/lorc/crown-coin.svg';
  static const crown = 'assets/icons/lorc/crown.svg';
  static const crownedExplosion = 'assets/icons/lorc/crowned-explosion.svg';
  static const crownedSkull = 'assets/icons/lorc/crowned-skull.svg';
  static const crownedHeart = 'assets/icons/lorc/crowned-heart.svg';
  static const crystalShine = 'assets/icons/lorc/crystal-shine.svg';
  static const crystalWand = 'assets/icons/lorc/crystal-wand.svg';
  static const cursedStar = 'assets/icons/lorc/cursed-star.svg';
  static const deadlyStrike = 'assets/icons/lorc/deadly-strike.svg';
  static const deathNote = 'assets/icons/lorc/death-note.svg';
  static const disintegrate = 'assets/icons/lorc/disintegrate.svg';
  static const divergence = 'assets/icons/lorc/divergence.svg';
  static const eclipse = 'assets/icons/lorc/eclipse.svg';
  static const eclipseFlare = 'assets/icons/lorc/eclipse-flare.svg';
  static const fastArrow = 'assets/icons/lorc/fast-arrow.svg';
  static const fireRing = 'assets/icons/lorc/fire-ring.svg';
  static const fist = 'assets/icons/lorc/fist.svg';
  static const flatStar = 'assets/icons/lorc/flat-star.svg';
  static const foldedPaper = 'assets/icons/lorc/folded-paper.svg';
  static const gavel = 'assets/icons/lorc/gavel.svg';
  static const gemChain = 'assets/icons/lorc/gem-chain.svg';
  static const gearHammer = 'assets/icons/lorc/gear-hammer.svg';
  static const gemPendant = 'assets/icons/lorc/gem-pendant.svg';
  static const giftOfKnowledge = 'assets/icons/lorc/gift-of-knowledge.svg';
  static const glowingHands = 'assets/icons/lorc/glowing-hands.svg';
  static const helmetHeadShot = 'assets/icons/lorc/helmet-head-shot.svg';
  static const iceBolt = 'assets/icons/lorc/ice-bolt.svg';
  static const iciclesAura = 'assets/icons/lorc/icicles-aura.svg';
  static const knapsack = 'assets/icons/lorc/knapsack.svg';
  static const laurelCrown = 'assets/icons/lorc/laurel-crown.svg';
  static const layeredArmor = 'assets/icons/lorc/layered-armor.svg';
  static const lightningHelix = 'assets/icons/lorc/lightning-helix.svg';
  static const lightningBranches = 'assets/icons/lorc/lightning-branches.svg';
  static const lightningStorm = 'assets/icons/lorc/lightning-storm.svg';
  static const lockedChest = 'assets/icons/lorc/locked-chest.svg';
  static const powerLightning = 'assets/icons/lorc/power-lightning.svg';
  static const lyre = 'assets/icons/lorc/lyre.svg';
  static const quillInk = 'assets/icons/lorc/quill-ink.svg';
  static const magicPalm = 'assets/icons/lorc/magic-palm.svg';
  static const magicShield = 'assets/icons/lorc/magic-shield.svg';
  static const magicSwirl = 'assets/icons/lorc/magic-swirl.svg';
  static const medal = 'assets/icons/lorc/medal.svg';
  static const onTarget = 'assets/icons/lorc/on-target.svg';
  static const openBook = 'assets/icons/lorc/open-book.svg';
  static const oppression = 'assets/icons/lorc/oppression.svg';
  static const papers = 'assets/icons/lorc/papers.svg';
  static const poisonBottle = 'assets/icons/lorc/poison-bottle.svg';
  static const prayer = 'assets/icons/lorc/prayer.svg';
  static const psychicWaves = 'assets/icons/lorc/psychic-waves.svg';
  static const rallyTheTroops = 'assets/icons/lorc/rally-the-troops.svg';
  static const relicBlade = 'assets/icons/lorc/relic-blade.svg';
  static const runeSword = 'assets/icons/lorc/rune-sword.svg';
  static const sinusoidalBeam = 'assets/icons/lorc/sinusoidal-beam.svg';
  static const run = 'assets/icons/lorc/run.svg';
  static const scrollUnfurled = 'assets/icons/lorc/scroll-unfurled.svg';
  static const shieldReflect = 'assets/icons/lorc/shield-reflect.svg';
  static const skullCrack = 'assets/icons/lorc/skull-crack.svg';
  static const smallFire = 'assets/icons/lorc/small-fire.svg';
  static const firePunch = 'assets/icons/lorc/fire-punch.svg';
  static const sonicShout = 'assets/icons/lorc/sonic-shout.svg';
  static const sprint = 'assets/icons/lorc/sprint.svg';
  static const splitBody = 'assets/icons/lorc/split-body.svg';
  static const standingPotion = 'assets/icons/lorc/standing-potion.svg';
  static const swapBag = 'assets/icons/lorc/swap-bag.svg';
  static const starProminences = 'assets/icons/lorc/star-prominences.svg';
  static const starSwirl = 'assets/icons/lorc/star-swirl.svg';
  static const swordsEmblem = 'assets/icons/lorc/swords-emblem.svg';
  static const vibratingShield = 'assets/icons/delapouite/vibrating-shield.svg';
  static const wisdom = 'assets/icons/delapouite/wisdom.svg';
  static const wizardStaff = 'assets/icons/lorc/wizard-staff.svg';
  static const swordSmithing = 'assets/icons/lorc/sword-smithing.svg';
  static const thirdEye = 'assets/icons/lorc/third-eye.svg';
  static const thunderBlade = 'assets/icons/lorc/thunder-blade.svg';
  static const hammerDrop = 'assets/icons/lorc/hammer-drop.svg';
  static const stoneCrafting = 'assets/icons/lorc/stone-crafting.svg';
  static const swordSpade = 'assets/icons/lorc/sword-spade.svg';
  static const tiedScroll = 'assets/icons/lorc/tied-scroll.svg';
  static const wingfoot = 'assets/icons/lorc/wingfoot.svg';
  static const woodAxe = 'assets/icons/lorc/wood-axe.svg';
  static const campfire  = 'assets/icons/lorc/campfire.svg';
  // lorc – kit equipment
  static const arrowScope = 'assets/icons/lorc/arrow-scope.svg';
  static const batteredAxe = 'assets/icons/lorc/battered-axe.svg';
  static const breastplate = 'assets/icons/lorc/breastplate.svg';
  static const broadDagger = 'assets/icons/lorc/broad-dagger.svg';
  static const flatHammer = 'assets/icons/lorc/flat-hammer.svg';
  static const grab = 'assets/icons/lorc/grab.svg';
  static const muscleUp = 'assets/icons/lorc/muscle-up.svg';
  static const pocketBow = 'assets/icons/lorc/pocket-bow.svg';
  static const pointySword = 'assets/icons/lorc/pointy-sword.svg';
  static const robe = 'assets/icons/lorc/robe.svg';
  static const scaleMail = 'assets/icons/lorc/scale-mail.svg';
  static const stoneSpear = 'assets/icons/lorc/stone-spear.svg';
  static const whip = 'assets/icons/lorc/whip.svg';
  static const wingedArrow = 'assets/icons/lorc/winged-arrow.svg';
  // delapouite
  static const ancientColumns = 'assets/icons/delapouite/ancient-columns.svg';
  static const backpack = 'assets/icons/delapouite/backpack.svg';
  static const chestArmor = 'assets/icons/delapouite/chest-armor.svg';
  static const bangingGavel = 'assets/icons/delapouite/banging-gavel.svg';
  static const bodyBalance = 'assets/icons/delapouite/body-balance.svg';
  static const bookPile = 'assets/icons/delapouite/book-pile.svg';
  static const bodyHeight = 'assets/icons/delapouite/body-height.svg';
  static const brainTentacle = 'assets/icons/delapouite/brain-tentacle.svg';
  static const diamondHilt = 'assets/icons/delapouite/diamond-hilt.svg';
  static const diceTwenty =
      'assets/icons/delapouite/dice-twenty-faces-twenty.svg';
  static const familyTree = 'assets/icons/delapouite/family-tree.svg';
  static const heartBeats = 'assets/icons/delapouite/heart-beats.svg';
  static const lunarWand = 'assets/icons/delapouite/lunar-wand.svg';
  static const magicPotion = 'assets/icons/delapouite/magic-potion.svg';
  static const healing = 'assets/icons/delapouite/healing.svg';
  static const healingShield = 'assets/icons/delapouite/healing-shield.svg';
  static const mightyForce = 'assets/icons/delapouite/mighty-force.svg';
  static const person = 'assets/icons/delapouite/person.svg';
  static const pillow = 'assets/icons/delapouite/pillow.svg';
  static const positionMarker =
      'assets/icons/delapouite/position-marker.svg';
  static const progression = 'assets/icons/delapouite/progression.svg';
  static const ribbonShield = 'assets/icons/delapouite/ribbon-shield.svg';
  static const scrollQuill = 'assets/icons/delapouite/scroll-quill.svg';
  static const secretBook = 'assets/icons/delapouite/secret-book.svg';
  static const shieldBash = 'assets/icons/delapouite/shield-bash.svg';
  static const skills = 'assets/icons/delapouite/skills.svg';
  static const swordBrandish = 'assets/icons/delapouite/sword-brandish.svg';
  static const spellBook = 'assets/icons/delapouite/spell-book.svg';
  static const swordsPower = 'assets/icons/delapouite/swords-power.svg';
  static const token = 'assets/icons/delapouite/token.svg';
  // delapouite – story/features
  static const bookshelf = 'assets/icons/delapouite/bookshelf.svg';
  static const classicalKnowledge = 'assets/icons/delapouite/classical-knowledge.svg';
  static const conqueror = 'assets/icons/delapouite/conqueror.svg';
  static const emeraldNecklace = 'assets/icons/delapouite/emerald-necklace.svg';
  static const pearlNecklace = 'assets/icons/delapouite/pearl-necklace.svg';
  static const shakingHands = 'assets/icons/delapouite/shaking-hands.svg';
  static const waxTablet = 'assets/icons/delapouite/wax-tablet.svg';
  // delapouite – kit equipment
  static const sharpHalberd = 'assets/icons/delapouite/sharp-halberd.svg';
  static const vikingShield = 'assets/icons/delapouite/viking-shield.svg';
  // sbed
  static const acid = 'assets/icons/sbed/acid.svg';
  static const deathSkull = 'assets/icons/sbed/death-skull.svg';
  static const help = 'assets/icons/sbed/help.svg';
  static const shield = 'assets/icons/sbed/shield.svg';
  // zeromancer
  static const heartPlus = 'assets/icons/zeromancer/heart-plus.svg';
  // kier-heyl
  static const elfHelmet = 'assets/icons/kier-heyl/elf-helmet.svg';
  // willdabeast
  static const williamTellSkull = 'assets/icons/lorc/william-tell-skull.svg';
  static const whiteBook = 'assets/icons/willdabeast/white-book.svg';
  // seregacthtuf
  static const pouchWithBeads = 'assets/icons/seregacthtuf/pouch-with-beads.svg';
  // skoll
  static const openTreasureChest = 'assets/icons/skoll/open-treasure-chest.svg';
  // darkzaitzev
  static const hoodedFigure = 'assets/icons/darkzaitzev/hooded-figure.svg';
  // lorc – features/story
  static const crestedHelmet = 'assets/icons/lorc/crested-helmet.svg';
  static const holySymbol = 'assets/icons/lorc/holy-symbol.svg';
  static const skeletonKey = 'assets/icons/lorc/skeleton-key.svg';
  // lorc – green forms
  static const graspingClaws = 'assets/icons/lorc/grasping-claws.svg';
  static const wolfHead = 'assets/icons/lorc/wolf-head.svg';
  static const foodChain = 'assets/icons/lorc/food-chain.svg';
  static const frog = 'assets/icons/lorc/frog.svg';
  static const gecko = 'assets/icons/lorc/gecko.svg';
  static const hangingSpider = 'assets/icons/lorc/hanging-spider.svg';
  static const sharkJaws = 'assets/icons/lorc/shark-jaws.svg';
  static const crocJaws = 'assets/icons/lorc/croc-jaws.svg';
  // delapouite – green forms
  static const rat = 'assets/icons/delapouite/rat.svg';
  static const saberToothCatHead = 'assets/icons/delapouite/saber-toothed-cat-head.svg';
  static const horseHead = 'assets/icons/delapouite/horse-head.svg';
  static const bearHead = 'assets/icons/delapouite/bear-head.svg';
  static const eagleHead = 'assets/icons/delapouite/eagle-head.svg';
  static const snakeTongue = 'assets/icons/delapouite/snake-tongue.svg';
  static const kangaroo = 'assets/icons/delapouite/kangaroo.svg';
  static const armadillo = 'assets/icons/delapouite/armadillo.svg';
  static const ostrich = 'assets/icons/delapouite/ostrich.svg';
  static const krakenTentacle = 'assets/icons/delapouite/kraken-tentacle.svg';
  static const rhinocerosHorn = 'assets/icons/delapouite/rhinoceros-horn.svg';
  // caro-asercion – green forms
  static const barnOwl = 'assets/icons/caro-asercion/barn-owl.svg';
  static const boar = 'assets/icons/caro-asercion/boar.svg';
  // lorc – downtime
  static const hourglass = 'assets/icons/lorc/hourglass.svg';
  static const embrassedEnergy = 'assets/icons/lorc/embrassed-energy.svg';
  static const trade = 'assets/icons/lorc/trade.svg';
  static const minions = 'assets/icons/lorc/minions.svg';
  static const conversation = 'assets/icons/lorc/conversation.svg';
  static const treasureMap = 'assets/icons/lorc/treasure-map.svg';
  static const autoRepair = 'assets/icons/lorc/auto-repair.svg';
  static const potionBall = 'assets/icons/lorc/potion-ball.svg';
  static const emptyHourglass = 'assets/icons/lorc/empty-hourglass.svg';
  // delapouite – downtime
  static const perspectiveDice = 'assets/icons/delapouite/perspective-dice-six-faces-random.svg';
  static const sparkles = 'assets/icons/delapouite/sparkles.svg';
  static const roundStar = 'assets/icons/delapouite/round-star.svg';
  static const notebook = 'assets/icons/delapouite/notebook.svg';
  static const archiveResearch = 'assets/icons/delapouite/archive-research.svg';
  static const twoCoins = 'assets/icons/delapouite/two-coins.svg';
  static const chest = 'assets/icons/delapouite/chest.svg';
  static const discussion = 'assets/icons/delapouite/discussion.svg';
  // faithtoken – downtime
  static const minerals = 'assets/icons/faithtoken/minerals.svg';
  // darkzaitzev – downtime
  static const ninjaHeroicStance = 'assets/icons/darkzaitzev/ninja-heroic-stance.svg';
  // cathelineau – downtime
  static const swordman = 'assets/icons/cathelineau/swordman.svg';
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation
// ─────────────────────────────────────────────────────────────────────────────

class NavIcons {
  const NavIcons._();

  // Main bottom-nav tabs (inactive / active pairs)
  static const AppIconData heroes = SvgAppIcon(_Svg.crackedHelm);
  static const AppIconData heroesActive = SvgAppIcon(_Svg.barbute);
  static const AppIconData strife = SvgAppIcon(_Svg.woodAxe);
  static const AppIconData strifeActive = SvgAppIcon(_Svg.choppedSkull);
  static const AppIconData story = SvgAppIcon(_Svg.secretBook);
  static const AppIconData storyActive = SvgAppIcon(_Svg.spellBook);
  static const AppIconData gear = SvgAppIcon(_Svg.backpack);
  static const AppIconData gearActive = SvgAppIcon(_Svg.battleGear);
  static const AppIconData downtime = SvgAppIcon(_Svg.anvilImpact);
  static const AppIconData downtimeActive = SvgAppIcon(_Svg.swordSmithing);

  // Hero-sheet tabs (inactive / active pairs)
  static const AppIconData sheetMain = SvgAppIcon(_Svg.tiedScroll);
  static const AppIconData sheetMainActive = SvgAppIcon(_Svg.scrollQuill);
  static const AppIconData sheetAbilities = SvgAppIcon(_Svg.hammerDrop);
  static const AppIconData sheetAbilitiesActive = SvgAppIcon(_Svg.bangingGavel);
  static const AppIconData sheetGear = SvgAppIcon(_Svg.backpack);
  static const AppIconData sheetGearActive = SvgAppIcon(_Svg.battleGear);
  static const AppIconData sheetFeatures = SvgAppIcon(_Svg.swordSpade);
  static const AppIconData sheetFeaturesActive = SvgAppIcon(_Svg.stoneCrafting);
  static const AppIconData sheetNotes = SvgAppIcon(_Svg.whiteBook);
  static const AppIconData sheetNotesActive = SvgAppIcon(_Svg.openBook);

  // Generic nav actions (keep Material)
  static const AppIconData forward = MaterialIcon(Icons.chevron_right_rounded);
  static const AppIconData forwardSlim = MaterialIcon(Icons.chevron_right);
  static const AppIconData back = MaterialIcon(Icons.arrow_back);
  static const AppIconData drillIn = MaterialIcon(Icons.arrow_forward_ios);
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Classes
// ─────────────────────────────────────────────────────────────────────────────

class ClassIcons {
  const ClassIcons._();

  static const AppIconData censor = SvgAppIcon(_Svg.gavel);
  static const AppIconData conduit = SvgAppIcon(_Svg.lightningHelix);
  static const AppIconData elementalist = SvgAppIcon(_Svg.fireRing);
  static const AppIconData fury = SvgAppIcon(_Svg.burningPassion);
  static const AppIconData nullClass = SvgAppIcon(_Svg.eclipse);
  static const AppIconData shadow = SvgAppIcon(_Svg.cloakDagger);
  static const AppIconData tactician = SvgAppIcon(_Svg.rallyTheTroops);
  static const AppIconData talent = SvgAppIcon(_Svg.crystalShine);
  static const AppIconData troubadour = SvgAppIcon(_Svg.lyre);
  static const AppIconData fallback = SvgAppIcon(_Svg.helmetHeadShot);

  /// Resolve a class name to its icon.
  static AppIconData fromName(String className) {
    switch (className.toLowerCase()) {
      case 'censor':
        return censor;
      case 'conduit':
        return conduit;
      case 'elementalist':
        return elementalist;
      case 'fury':
        return fury;
      case 'null':
        return nullClass;
      case 'shadow':
        return shadow;
      case 'tactician':
        return tactician;
      case 'talent':
        return talent;
      case 'troubadour':
        return troubadour;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Levels (echelon tiers)
// ─────────────────────────────────────────────────────────────────────────────

class LevelIcons {
  const LevelIcons._();

  static const AppIconData tier1 = SvgAppIcon(_Svg.flatStar);
  static const AppIconData tier2 = SvgAppIcon(_Svg.beveledStar);
  static const AppIconData tier3 = SvgAppIcon(_Svg.starProminences);
  static const AppIconData tier4 = SvgAppIcon(_Svg.starSwirl);

  /// Resolve a hero level (1-10) to its tier icon.
  static AppIconData fromLevel(int level) {
    if (level <= 3) return tier1;
    if (level <= 6) return tier2;
    if (level <= 9) return tier3;
    return tier4;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Characteristics (Might, Agility, Reason, Intuition, Presence)
// ─────────────────────────────────────────────────────────────────────────────

class CharacteristicIcons {
  const CharacteristicIcons._();

  static const AppIconData might = SvgAppIcon(_Svg.fist);
  static const AppIconData agility = SvgAppIcon(_Svg.wingfoot);
  static const AppIconData reason = SvgAppIcon(_Svg.brain);
  static const AppIconData intuition = SvgAppIcon(_Svg.thirdEye);
  static const AppIconData presence = SvgAppIcon(_Svg.crownedHeart);
  static const AppIconData fallback = SvgAppIcon(_Svg.help);

  /// Resolve a characteristic name to its icon.
  static AppIconData fromName(String characteristic) {
    switch (characteristic.toLowerCase()) {
      case 'might':
        return might;
      case 'agility':
        return agility;
      case 'reason':
        return reason;
      case 'intuition':
        return intuition;
      case 'presence':
        return presence;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kit Types
// ─────────────────────────────────────────────────────────────────────────────

class KitIcons {
  const KitIcons._();

  static const AppIconData kit = SvgAppIcon(_Svg.swordsEmblem);
  static const AppIconData stormwightKit = SvgAppIcon(_Svg.powerLightning);
  static const AppIconData psionicAugmentation =
      SvgAppIcon(_Svg.psychicWaves);
  static const AppIconData ward = SvgAppIcon(_Svg.magicShield);
  static const AppIconData prayer = SvgAppIcon(_Svg.prayer);
  static const AppIconData enchantment = SvgAppIcon(_Svg.magicSwirl);
  static const AppIconData fallback = SvgAppIcon(_Svg.cog);

  /// Resolve a kit type identifier to its icon.
  static AppIconData fromType(String type) {
    switch (type) {
      case 'kit':
        return kit;
      case 'stormwight_kit':
        return stormwightKit;
      case 'psionic_augmentation':
        return psionicAugmentation;
      case 'ward':
        return ward;
      case 'prayer':
        return prayer;
      case 'enchantment':
        return enchantment;
      default:
        return fallback;
    }
  }

  /// Map for dropdown / list builders.
  static const Map<String, AppIconData> byType = {
    'kit': kit,
    'stormwight_kit': stormwightKit,
    'psionic_augmentation': psionicAugmentation,
    'ward': ward,
    'prayer': prayer,
    'enchantment': enchantment,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Kit Equipment
// ─────────────────────────────────────────────────────────────────────────────

class KitEquipmentIcons {
  const KitEquipmentIcons._();

  // Armor types
  static const AppIconData armorShield = SvgAppIcon(_Svg.vikingShield);
  static const AppIconData armorNone = SvgAppIcon(_Svg.muscleUp);
  static const AppIconData armorLight = SvgAppIcon(_Svg.robe);
  static const AppIconData armorMedium = SvgAppIcon(_Svg.scaleMail);
  static const AppIconData armorHeavy = SvgAppIcon(_Svg.breastplate);

  // Weapon types
  static const AppIconData weaponBow = SvgAppIcon(_Svg.pocketBow);
  static const AppIconData weaponPolearm = SvgAppIcon(_Svg.sharpHalberd);
  static const AppIconData weaponWhip = SvgAppIcon(_Svg.whip);
  static const AppIconData weaponNone = SvgAppIcon(_Svg.grab);
  static const AppIconData weaponLight = SvgAppIcon(_Svg.broadDagger);
  static const AppIconData weaponMedium = SvgAppIcon(_Svg.batteredAxe);
  static const AppIconData weaponHeavy = SvgAppIcon(_Svg.flatHammer);

  // Melee bonuses
  static const AppIconData meleeDamage = SvgAppIcon(_Svg.pointySword);
  static const AppIconData meleeRange = SvgAppIcon(_Svg.stoneSpear);

  // Ranged bonuses
  static const AppIconData rangedDamage = SvgAppIcon(_Svg.wingedArrow);
  static const AppIconData rangedRange = SvgAppIcon(_Svg.arrowScope);

  /// Resolve an armor type to its icon.
  static AppIconData fromArmorType(String type) {
    switch (type) {
      case 'shield':
        return armorShield;
      case 'none':
        return armorNone;
      case 'light':
        return armorLight;
      case 'medium':
        return armorMedium;
      case 'heavy':
        return armorHeavy;
      default:
        return armorNone;
    }
  }

  /// Resolve a weapon type to its icon.
  static AppIconData fromWeaponType(String type) {
    switch (type) {
      case 'bow':
        return weaponBow;
      case 'polearm':
        return weaponPolearm;
      case 'whip':
      case 'ensnaring_weapon':
        return weaponWhip;
      case 'none':
      case 'unarmed_strikes':
        return weaponNone;
      case 'light':
        return weaponLight;
      case 'medium':
        return weaponMedium;
      case 'heavy':
        return weaponHeavy;
      default:
        return weaponNone;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill Groups
// ─────────────────────────────────────────────────────────────────────────────

class SkillGroupIcons {
  const SkillGroupIcons._();

  static const AppIconData crafting = SvgAppIcon(_Svg.gearHammer);
  static const AppIconData exploration = SvgAppIcon(_Svg.conqueror);
  static const AppIconData interpersonal = SvgAppIcon(_Svg.shakingHands);
  static const AppIconData intrigue = SvgAppIcon(_Svg.hoodedFigure);
  static const AppIconData lore = SvgAppIcon(_Svg.classicalKnowledge);
  static const AppIconData fallback = SvgAppIcon(_Svg.gearHammer);

  /// Resolve a skill group name to its icon.
  static AppIconData fromGroup(String group) {
    switch (group.toLowerCase()) {
      case 'crafting':
        return crafting;
      case 'exploration':
        return exploration;
      case 'interpersonal':
        return interpersonal;
      case 'intrigue':
        return intrigue;
      case 'lore':
        return lore;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Types
// ─────────────────────────────────────────────────────────────────────────────

class LanguageTypeIcons {
  const LanguageTypeIcons._();

  static const AppIconData tab = SvgAppIcon(_Svg.bookshelf);
  static const AppIconData ancestral = SvgAppIcon(_Svg.waxTablet);
  static const AppIconData human = SvgAppIcon(_Svg.bookmarklet);
  static const AppIconData dead = SvgAppIcon(_Svg.deathNote);
  static const AppIconData fallback = SvgAppIcon(_Svg.bookshelf);

  /// Resolve a language type to its icon.
  static AppIconData fromType(String type) {
    switch (type.toLowerCase()) {
      case 'ancestral':
        return ancestral;
      case 'human':
        return human;
      case 'dead':
        return dead;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Perk Groups
// ─────────────────────────────────────────────────────────────────────────────

class PerkGroupIcons {
  const PerkGroupIcons._();

  static const AppIconData tab = SvgAppIcon(_Svg.giftOfKnowledge);
  static const AppIconData supernatural = SvgAppIcon(_Svg.eclipseFlare);
  static const AppIconData exploration = SvgAppIcon(_Svg.eclipseFlare);
  static const AppIconData crafting = SvgAppIcon(_Svg.anvil);
  static const AppIconData intrigue = SvgAppIcon(_Svg.backstab);
  static const AppIconData interpersonal = SvgAppIcon(_Svg.backup);
  static const AppIconData lore = SvgAppIcon(_Svg.wisdom);
  static const AppIconData fallback = SvgAppIcon(_Svg.giftOfKnowledge);

  /// Resolve a perk group name to its icon.
  static AppIconData fromGroup(String group) {
    switch (group.toLowerCase()) {
      case 'supernatural':
        return supernatural;
      case 'exploration':
        return exploration;
      case 'crafting':
        return crafting;
      case 'intrigue':
        return intrigue;
      case 'interpersonal':
        return interpersonal;
      case 'lore':
        return lore;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title Echelons
// ─────────────────────────────────────────────────────────────────────────────

class TitleIcons {
  const TitleIcons._();

  static const AppIconData tab = SvgAppIcon(_Svg.crownedSkull);
  static const AppIconData echelon1 = SvgAppIcon(_Svg.emeraldNecklace);
  static const AppIconData echelon2 = SvgAppIcon(_Svg.pearlNecklace);
  static const AppIconData echelon3 = SvgAppIcon(_Svg.gemPendant);
  static const AppIconData echelon4 = SvgAppIcon(_Svg.crown);
  static const AppIconData fallback = SvgAppIcon(_Svg.crownedSkull);

  // Section icons
  static const AppIconData prerequisite = SvgAppIcon(_Svg.skeletonKey);
  static const AppIconData description = SvgAppIcon(_Svg.scrollUnfurled);
  static const AppIconData benefits = SvgAppIcon(_Svg.giftOfKnowledge);
  static const AppIconData special = SvgAppIcon(_Svg.starSwirl);

  /// Resolve an echelon number to its icon.
  static AppIconData fromEchelon(int echelon) {
    switch (echelon) {
      case 1:
        return echelon1;
      case 2:
        return echelon2;
      case 3:
        return echelon3;
      case 4:
        return echelon4;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features Tab
// ─────────────────────────────────────────────────────────────────────────────

class FeatureIcons {
  const FeatureIcons._();

  static const AppIconData subclass = SvgAppIcon(_Svg.divergence);
  static const AppIconData domain = SvgAppIcon(_Svg.holySymbol);
  static const AppIconData deity = SvgAppIcon(_Svg.prayer);
  static const AppIconData characteristics = SvgAppIcon(_Svg.bodyBalance);
}

// ─────────────────────────────────────────────────────────────────────────────
// Treasure Types
// ─────────────────────────────────────────────────────────────────────────────

class TreasureIcons {
  const TreasureIcons._();

  static const AppIconData consumable = SvgAppIcon(_Svg.magicPotion);
  static const AppIconData trinket = SvgAppIcon(_Svg.gemChain);
  static const AppIconData artifact = SvgAppIcon(_Svg.relicBlade);
  static const AppIconData leveledTreasure = SvgAppIcon(_Svg.lockedChest);
  static const AppIconData fallback = SvgAppIcon(_Svg.cog);
  static const AppIconData treasuresTab = SvgAppIcon(_Svg.openTreasureChest);

  // Leveled sub-types
  static const AppIconData shield = SvgAppIcon(_Svg.borderedShield);
  static const AppIconData armor = SvgAppIcon(_Svg.chestArmor);
  static const AppIconData implement = SvgAppIcon(_Svg.lunarWand);
  static const AppIconData weapon = SvgAppIcon(_Svg.relicBlade);
  static const AppIconData otherLeveled = SvgAppIcon(_Svg.gemPendant);

  // Per-artifact icons
  static const AppIconData bladeOfAThousandYears = SvgAppIcon(_Svg.diamondHilt);
  static const AppIconData encepter = SvgAppIcon(_Svg.wizardStaff);
  static const AppIconData mortalCoil = SvgAppIcon(_Svg.sinusoidalBeam);

  /// Resolve a treasure type to its icon.
  static AppIconData fromType(String type) {
    switch (type) {
      case 'consumable':
        return consumable;
      case 'trinket':
        return trinket;
      case 'artifact':
        return artifact;
      case 'leveled_treasure':
        return leveledTreasure;
      default:
        return fallback;
    }
  }

  /// Resolve a leveled treasure sub-type to its icon.
  static AppIconData fromLeveledType(String? leveledType) {
    switch (leveledType) {
      case 'shield':
        return shield;
      case 'armor':
        return armor;
      case 'implement':
        return implement;
      case 'weapon':
        return weapon;
      case 'other':
        return otherLeveled;
      default:
        return leveledTreasure;
    }
  }

  /// Resolve an artifact by its component ID to a unique icon.
  static AppIconData fromArtifactId(String? id) {
    switch (id) {
      case 'blade_of_a_thousand_years':
        return bladeOfAThousandYears;
      case 'encepter':
        return encepter;
      case 'mortal_coil':
        return mortalCoil;
      default:
        return artifact;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Imbuement Types
// ─────────────────────────────────────────────────────────────────────────────

class ImbuementIcons {
  const ImbuementIcons._();

  static const AppIconData armor = SvgAppIcon(_Svg.vibratingShield);
  static const AppIconData weapon = SvgAppIcon(_Svg.runeSword);
  static const AppIconData implement = SvgAppIcon(_Svg.burningBook);
  static const AppIconData fallback = SvgAppIcon(_Svg.magicSwirl);

  /// Resolve an imbuement type to its icon.
  static AppIconData fromType(String type) {
    switch (type) {
      case 'armor_imbuement':
        return armor;
      case 'weapon_imbuement':
        return weapon;
      case 'implement_imbuement':
        return implement;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prerequisite Types (downtime projects)
// ─────────────────────────────────────────────────────────────────────────────

class PrerequisiteIcons {
  const PrerequisiteIcons._();

  static const AppIconData itemPrerequisite = SvgAppIcon(_Svg.lockedChest);
  static const AppIconData projectSource = SvgAppIcon(_Svg.openBook);
  static const AppIconData location =
      SvgAppIcon(_Svg.positionMarker);
  static const AppIconData skill = SvgAppIcon(_Svg.gearHammer);
  static const AppIconData level = SvgAppIcon(_Svg.progression);
  static const AppIconData heroClass = SvgAppIcon(_Svg.helmetHeadShot);
  static const AppIconData feature = SvgAppIcon(_Svg.beveledStar);
  static const AppIconData fallback = SvgAppIcon(_Svg.help);

  /// Resolve a prerequisite key to its icon.
  static AppIconData fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'item_prerequisite':
        return itemPrerequisite;
      case 'project_source':
        return projectSource;
      case 'location':
        return location;
      case 'skill':
        return skill;
      case 'level':
        return level;
      case 'class':
        return heroClass;
      case 'feature':
        return feature;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Downtime Project Categories
// ─────────────────────────────────────────────────────────────────────────────

class ProjectCategoryIcons {
  const ProjectCategoryIcons._();

  // Numeric categories (by tier)
  static const AppIconData epic = SvgAppIcon(_Svg.crownedExplosion);
  static const AppIconData major = SvgAppIcon(_Svg.medal);
  static const AppIconData medium = SvgAppIcon(_Svg.scrollUnfurled);
  static const AppIconData small = SvgAppIcon(_Svg.tiedScroll);

  // Named categories (project template browser)
  static const AppIconData project = SvgAppIcon(_Svg.scrollUnfurled);
  static const AppIconData imbuement = SvgAppIcon(_Svg.anvilImpact);
  static const AppIconData treasure = SvgAppIcon(_Svg.gemPendant);
  static const AppIconData fallback = SvgAppIcon(_Svg.help);

  /// Resolve a numeric project category (1-4) to its icon.
  static AppIconData fromTier(int category) {
    switch (category) {
      case 4:
        return epic;
      case 3:
        return major;
      case 2:
        return medium;
      case 1:
        return small;
      default:
        return fallback;
    }
  }

  /// Resolve a named category to its icon.
  static AppIconData fromName(String category) {
    switch (category) {
      case 'project':
        return project;
      case 'imbuement':
        return imbuement;
      case 'treasure':
        return treasure;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Story / Hero Identity
// ─────────────────────────────────────────────────────────────────────────────

class StoryIcons {
  const StoryIcons._();

  static const AppIconData heroName = SvgAppIcon(_Svg.crestedHelmet);
  static const AppIconData heroAvatar = SvgAppIcon(_Svg.barbute);
  static const AppIconData yourHeroes = SvgAppIcon(_Svg.scrollQuill);
  static const AppIconData addHero = MaterialIcon(Icons.person_add);
  static const AppIconData ancestry = SvgAppIcon(_Svg.familyTree);
  static const AppIconData culture = SvgAppIcon(_Svg.ancientColumns);
  static const AppIconData career = SvgAppIcon(_Svg.anvil);
  static const AppIconData complication = SvgAppIcon(_Svg.cursedStar);
  static const AppIconData languages = SvgAppIcon(_Svg.scrollUnfurled);
  static const AppIconData classSelector = SvgAppIcon(_Svg.battleGear);
  static const AppIconData heroClass = SvgAppIcon(_Svg.borderedShield);
  static const AppIconData subclass = SvgAppIcon(_Svg.divergence);
  static const AppIconData skills = SvgAppIcon(_Svg.skills);
  static const AppIconData editHero = SvgAppIcon(_Svg.quillInk);
}

// ─────────────────────────────────────────────────────────────────────────────
// Combat / Stats
// ─────────────────────────────────────────────────────────────────────────────

class CombatIcons {
  const CombatIcons._();

  // Stamina
  static const AppIconData stamina = SvgAppIcon(_Svg.heartBeats);
  static const AppIconData staminaHealthy = SvgAppIcon(_Svg.barbute);
  static const AppIconData staminaWinded = SvgAppIcon(_Svg.crackedHelm);
  static const AppIconData staminaDying = SvgAppIcon(_Svg.skullCrack);

  /// Resolve a stamina-state icon based on the hero's health.
  static AppIconData staminaState(int current, int max) {
    if (max <= 0) return staminaDying;
    final ratio = current / max;
    if (ratio <= 0) return staminaDying;
    if (ratio <= 0.5) return staminaWinded;
    return staminaHealthy;
  }

  // Core stats
  static const AppIconData wealth = SvgAppIcon(_Svg.cash);
  static const AppIconData renown = SvgAppIcon(_Svg.elfHelmet);
  static const AppIconData victories = SvgAppIcon(_Svg.swordsPower);
  static const AppIconData experience = SvgAppIcon(_Svg.laurelCrown);
  static const AppIconData characteristics = SvgAppIcon(_Svg.deadlyStrike);
  static const AppIconData attributes = SvgAppIcon(_Svg.iciclesAura);
  static const AppIconData damage = SvgAppIcon(_Svg.splitBody);
  static const AppIconData heal = SvgAppIcon(_Svg.healing);
  static const AppIconData recovery = SvgAppIcon(_Svg.healingShield);
  static const AppIconData useRecovery = SvgAppIcon(_Svg.heartPlus);
  static const AppIconData heroTokens = SvgAppIcon(_Svg.ribbonShield);
  static const AppIconData heroicResource = SvgAppIcon(_Svg.mightyForce);
  static const AppIconData surges = SvgAppIcon(_Svg.thunderBlade);
  static const AppIconData conditions = SvgAppIcon(_Svg.oppression);
  static const AppIconData damageResistances = SvgAppIcon(_Svg.shieldReflect);
  static const AppIconData coinPurse = SvgAppIcon(_Svg.swapBag);
  static const AppIconData respite = SvgAppIcon(_Svg.campfire);
  static const AppIconData downtime = SvgAppIcon(_Svg.anvilImpact);

  // Movement
  static const AppIconData size = SvgAppIcon(_Svg.bodyHeight);
  static const AppIconData speed = SvgAppIcon(_Svg.wingfoot);
  static const AppIconData stability = SvgAppIcon(_Svg.bodyBalance);
  static const AppIconData freeStrike = SvgAppIcon(_Svg.onTarget);
  final AppIconData movement = const SvgAppIcon(_Svg.sprint);
}

// ─────────────────────────────────────────────────────────────────────────────
// Abilities & Features
// ─────────────────────────────────────────────────────────────────────────────

class AbilityIcons {
  const AbilityIcons._();

  static const AppIconData ability = SvgAppIcon(_Svg.magicPalm);
  static const AppIconData abilityGrant = SvgAppIcon(_Svg.glowingHands);
  static const AppIconData feature = SvgAppIcon(_Svg.beveledStar);
  static const AppIconData featureOverview = SvgAppIcon(_Svg.bookAura);
  static const AppIconData subclass = SvgAppIcon(_Svg.divergence);
  static const AppIconData featureChoice = SvgAppIcon(_Svg.checkboxTree);
  static const AppIconData progression = SvgAppIcon(_Svg.progression);
  static const AppIconData heroToken = SvgAppIcon(_Svg.crownCoin);
  // Action type icons
  final AppIconData actions = const SvgAppIcon(_Svg.swordBrandish);
  final AppIconData maneuvers = const SvgAppIcon(_Svg.shieldBash);
  final AppIconData triggered = const SvgAppIcon(_Svg.bouncingSword);
  // Ability info icons
  final AppIconData target = const SvgAppIcon(_Svg.williamTellSkull);
  final AppIconData range = const SvgAppIcon(_Svg.fastArrow);
  // Tab icons
  final AppIconData heroAbilities = const SvgAppIcon(_Svg.allForOne);
  final AppIconData commonAbilities = const SvgAppIcon(_Svg.crossedAxes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Perks & Titles
// ─────────────────────────────────────────────────────────────────────────────

class PerkIcons {
  const PerkIcons._();

  static const AppIconData grant = SvgAppIcon(_Svg.giftOfKnowledge);
  static const AppIconData grantOutlined = SvgAppIcon(_Svg.giftOfKnowledge);
  static const AppIconData description = SvgAppIcon(_Svg.openBook);
  static const AppIconData token = SvgAppIcon(_Svg.token);
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes System
// ─────────────────────────────────────────────────────────────────────────────

class NoteIcons {
  const NoteIcons._();

  final AppIconData topHeader = const SvgAppIcon(_Svg.candleSkull);
  final AppIconData folderHeader = const SvgAppIcon(_Svg.bookPile);
  final AppIconData folder = const SvgAppIcon(_Svg.bookmark);
  final AppIconData noteHeader = const SvgAppIcon(_Svg.papers);
  final AppIconData note = const SvgAppIcon(_Svg.foldedPaper);
  static const AppIconData timestamp = MaterialIcon(Icons.access_time);
  static const AppIconData save = MaterialIcon(Icons.save);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gear / Inventory
// ─────────────────────────────────────────────────────────────────────────────

class GearIcons {
  const GearIcons._();

  final AppIconData inventoryTab = const SvgAppIcon(_Svg.backpack);
  final AppIconData container = const SvgAppIcon(_Svg.knapsack);
  final AppIconData item = const SvgAppIcon(_Svg.pouchWithBeads);
  final AppIconData kitsTab = const SvgAppIcon(_Svg.swordsEmblem);
  final AppIconData treasuresTab = const SvgAppIcon(_Svg.openTreasureChest);
}

// ─────────────────────────────────────────────────────────────────────────────
// Import / Export / Share
// ─────────────────────────────────────────────────────────────────────────────

class IoIcons {
  const IoIcons._();

  static const AppIconData importClipboard = MaterialIcon(Icons.content_paste);
  static const AppIconData copy = MaterialIcon(Icons.copy);
  static const AppIconData paste = MaterialIcon(Icons.paste);
  static const AppIconData openFile = MaterialIcon(Icons.file_open);
  static const AppIconData export_ = MaterialIcon(Icons.save_alt);
  static const AppIconData share = MaterialIcon(Icons.share);
  static const AppIconData upload = MaterialIcon(Icons.upload_rounded);
  static const AppIconData download = MaterialIcon(Icons.download);
}

// ─────────────────────────────────────────────────────────────────────────────
// General UI Chrome
// ─────────────────────────────────────────────────────────────────────────────

class UiIcons {
  const UiIcons._();

  static const AppIconData search = MaterialIcon(Icons.search);
  static const AppIconData searchOff = MaterialIcon(Icons.search_off);
  static const AppIconData close = MaterialIcon(Icons.close);
  static const AppIconData clear = MaterialIcon(Icons.clear);
  static const AppIconData check = MaterialIcon(Icons.check);
  static const AppIconData checkCircle = MaterialIcon(Icons.check_circle);
  static const AppIconData circleOutlined = MaterialIcon(Icons.circle_outlined);
  static const AppIconData add = MaterialIcon(Icons.add);
  static const AppIconData addCircle = MaterialIcon(Icons.add_circle_outline);
  static const AppIconData remove = MaterialIcon(Icons.remove);
  static const AppIconData removeCircle =
      MaterialIcon(Icons.remove_circle_outline);
  static const AppIconData delete = MaterialIcon(Icons.delete);
  static const AppIconData deleteOutline = MaterialIcon(Icons.delete_outline);
  static const AppIconData edit = MaterialIcon(Icons.edit);
  static const AppIconData editNote = MaterialIcon(Icons.edit_note);
  static const AppIconData info = MaterialIcon(Icons.info_outline);
  static const AppIconData error = MaterialIcon(Icons.error_outline);
  static const AppIconData refresh = MaterialIcon(Icons.refresh);
  static const AppIconData lock = MaterialIcon(Icons.lock);
  static const AppIconData swap = MaterialIcon(Icons.swap_horiz);
  static const AppIconData tune = MaterialIcon(Icons.tune);
  static const AppIconData expandMore = MaterialIcon(Icons.expand_more);
  static const AppIconData expandLess = MaterialIcon(Icons.expand_less);
  static const AppIconData dropDown = MaterialIcon(Icons.arrow_drop_down);
  static const AppIconData emptyState = MaterialIcon(Icons.inbox_outlined);
  static const AppIconData moreVert = MaterialIcon(Icons.more_vert);
  static const AppIconData moreHoriz = MaterialIcon(Icons.more_horiz);
}

// ─────────────────────────────────────────────────────────────────────────────
// Downtime
// ─────────────────────────────────────────────────────────────────────────────

class DowntimeIcons {
  const DowntimeIcons._();

  // -- Page & Tab icons --
  /// Main downtime header icon (hourglass)
  static const AppIconData downtimeHeader = SvgAppIcon(_Svg.hourglass);
  /// Events / event tables
  static const AppIconData events = SvgAppIcon(_Svg.scrollQuill);
  /// Projects tab
  static const AppIconData projects = SvgAppIcon(_Svg.anvil);
  /// Followers tab
  static const AppIconData followers = SvgAppIcon(_Svg.backup);
  /// Sources tab
  static const AppIconData sources = SvgAppIcon(_Svg.bookmarklet);

  // -- Project detail icons --
  /// Active projects section header
  static const AppIconData activeProjects = SvgAppIcon(_Svg.cog);
  /// Browse templates
  static const AppIconData browseTemplates = SvgAppIcon(_Svg.archiveResearch);
  /// Empty state (no projects / no items)
  static const AppIconData emptyState = SvgAppIcon(_Svg.emptyHourglass);
  /// Notes section
  static const AppIconData notes = SvgAppIcon(_Svg.notebook);
  /// Roll for progress (dice)
  static const AppIconData diceRoll = SvgAppIcon(_Svg.perspectiveDice);
  /// Surge / power roll surge
  static const AppIconData surge = SvgAppIcon(_Svg.embrassedEnergy);
  /// Collect crafted treasure
  static const AppIconData collectTreasure = SvgAppIcon(_Svg.treasureMap);
  /// Collect imbuement
  static const AppIconData collectImbuement = SvgAppIcon(_Svg.autoRepair);
  /// Treasure effect label
  static const AppIconData treasureEffect = SvgAppIcon(_Svg.sparkles);
  /// Imbuement effect label
  static const AppIconData imbuementEffect = SvgAppIcon(_Svg.autoRepair);
  /// Rewards / inventory section
  static const AppIconData rewards = SvgAppIcon(_Svg.chest);

  // -- Follower icons --
  /// Single follower avatar
  static const AppIconData follower = SvgAppIcon(_Svg.swordman);
  /// Add follower
  static const AppIconData addFollower = SvgAppIcon(_Svg.swordman);
  /// Follower skills
  static const AppIconData followerSkills = SvgAppIcon(_Svg.gearHammer);
  /// Follower languages
  static const AppIconData followerLanguages = SvgAppIcon(_Svg.conversation);
  /// Follower group / team roll
  static const AppIconData followerGroup = SvgAppIcon(_Svg.minions);

  // -- Source type icons --
  /// Source type: research book
  static const AppIconData sourceBook = SvgAppIcon(_Svg.openBook);
  /// Source type: item
  static const AppIconData sourceItem = SvgAppIcon(_Svg.swapBag);
  /// Source type: guide (person)
  static const AppIconData sourceGuide = SvgAppIcon(_Svg.discussion);
  /// Source type: fallback
  static const AppIconData sourceFallback = SvgAppIcon(_Svg.bookmarklet);

  // -- Treasure type icons --
  /// Consumable treasure
  static const AppIconData consumable = SvgAppIcon(_Svg.potionBall);
  /// Trinket / generic magic
  static const AppIconData trinket = SvgAppIcon(_Svg.sparkles);
  /// Leveled treasure
  static const AppIconData leveledTreasure = SvgAppIcon(_Svg.openTreasureChest);
  /// Generic treasure
  static const AppIconData genericTreasure = SvgAppIcon(_Svg.minerals);
  /// Enchantment / imbuement star
  static const AppIconData enchantment = SvgAppIcon(_Svg.roundStar);
  /// Template browser header
  static const AppIconData templateBrowser = SvgAppIcon(_Svg.archiveResearch);
  /// Lore / book category
  static const AppIconData lore = SvgAppIcon(_Svg.secretBook);

  /// Resolve a source type to its icon.
  static AppIconData fromSourceType(String type) {
    switch (type) {
      case 'source': return sourceBook;
      case 'item': return sourceItem;
      case 'guide': return sourceGuide;
      default: return sourceFallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heroic Resources
// ─────────────────────────────────────────────────────────────────────────────

class HeroicResourceIcons {
  const HeroicResourceIcons._();

  static const AppIconData ferocity = SvgAppIcon(_Svg.firePunch);
  static const AppIconData discipline = MaterialIcon(Icons.psychology_rounded);
  static const AppIconData fallback = MaterialIcon(Icons.auto_awesome);

  /// Resolve a resource name to its icon.
  static AppIconData fromName(String resourceName) {
    switch (resourceName.toLowerCase()) {
      case 'ferocity': return ferocity;
      case 'discipline': return discipline;
      default: return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Damage Types
// ─────────────────────────────────────────────────────────────────────────────

class DamageTypeIcons {
  const DamageTypeIcons._();

  static const AppIconData acid = SvgAppIcon(_Svg.acid);
  static const AppIconData cold = SvgAppIcon(_Svg.iceBolt);
  static const AppIconData corruption = SvgAppIcon(_Svg.disintegrate);
  static const AppIconData fire = SvgAppIcon(_Svg.smallFire);
  static const AppIconData holy = SvgAppIcon(_Svg.lightningStorm);
  static const AppIconData lightning = SvgAppIcon(_Svg.lightningBranches);
  static const AppIconData poison = SvgAppIcon(_Svg.poisonBottle);
  static const AppIconData psychic = SvgAppIcon(_Svg.brainTentacle);
  static const AppIconData sonic = SvgAppIcon(_Svg.sonicShout);
  static const AppIconData fallback = SvgAppIcon(_Svg.splitBody);

  /// Resolve a damage type name to its icon.
  static AppIconData fromName(String damageType) {
    switch (damageType.toLowerCase()) {
      case 'acid':
        return acid;
      case 'cold':
        return cold;
      case 'corruption':
        return corruption;
      case 'fire':
        return fire;
      case 'holy':
        return holy;
      case 'lightning':
        return lightning;
      case 'poison':
        return poison;
      case 'psychic':
        return psychic;
      case 'sonic':
        return sonic;
      default:
        return fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Green Elementalist Forms
// ─────────────────────────────────────────────────────────────────────────────

class GreenFormIcons {
  const GreenFormIcons._();

  /// Widget icon for the green forms selector
  static const AppIconData widget = SvgAppIcon(_Svg.graspingClaws);

  static const AppIconData canine = SvgAppIcon(_Svg.wolfHead);
  static const AppIconData fish = SvgAppIcon(_Svg.foodChain);
  static const AppIconData rodent = SvgAppIcon(_Svg.rat);
  static const AppIconData bird = SvgAppIcon(_Svg.barnOwl);
  static const AppIconData greatCat = SvgAppIcon(_Svg.saberToothCatHead);
  static const AppIconData giantFrog = SvgAppIcon(_Svg.frog);
  static const AppIconData horse = SvgAppIcon(_Svg.horseHead);
  static const AppIconData mohler = SvgAppIcon(_Svg.boar);
  static const AppIconData bear = SvgAppIcon(_Svg.bearHead);
  static const AppIconData giantBird = SvgAppIcon(_Svg.eagleHead);
  static const AppIconData giantSalamander = SvgAppIcon(_Svg.gecko);
  static const AppIconData giantSpider = SvgAppIcon(_Svg.hangingSpider);
  static const AppIconData giantSnake = SvgAppIcon(_Svg.snakeTongue);
  static const AppIconData kangaroo = SvgAppIcon(_Svg.kangaroo);
  static const AppIconData spinyArmadillo = SvgAppIcon(_Svg.armadillo);
  static const AppIconData ostrich = SvgAppIcon(_Svg.ostrich);
  static const AppIconData shark = SvgAppIcon(_Svg.sharkJaws);
  static const AppIconData giantOctopus = SvgAppIcon(_Svg.krakenTentacle);
  static const AppIconData rhinoceros = SvgAppIcon(_Svg.rhinocerosHorn);
  static const AppIconData kingTerrorLizard = SvgAppIcon(_Svg.crocJaws);
  static const AppIconData fallback = SvgAppIcon(_Svg.graspingClaws);

  /// Resolve a form ID to its icon.
  static AppIconData fromId(String formId) {
    switch (formId) {
      case 'canine': return canine;
      case 'fish': return fish;
      case 'rodent': return rodent;
      case 'bird': return bird;
      case 'great_cat': return greatCat;
      case 'giant_frog': return giantFrog;
      case 'horse': return horse;
      case 'mohler': return mohler;
      case 'bear': return bear;
      case 'giant_bird': return giantBird;
      case 'giant_salamander': return giantSalamander;
      case 'giant_spider': return giantSpider;
      case 'giant_snake': return giantSnake;
      case 'kangaroo': return kangaroo;
      case 'spiny_armadillo': return spinyArmadillo;
      case 'ostrich': return ostrich;
      case 'shark': return shark;
      case 'giant_octopus': return giantOctopus;
      case 'rhinoceros': return rhinoceros;
      case 'king_terror_lizard': return kingTerrorLizard;
      default: return fallback;
    }
  }
}
