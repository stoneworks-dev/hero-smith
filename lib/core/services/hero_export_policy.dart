import '../storage/hero_storage_contract.dart';

/// Whether a canonical storage family can be represented by an export target.
enum ExportTargetSupport { supported, partial, unsupported }

/// High-level hero-owned storage families. New tables must be added here before
/// they can be considered covered by export work.
enum HeroExportStorageFamily {
  hero,
  entries,
  config,
  heroValues,
  downtimeProjects,
  followers,
  projectSources,
  notes,
  retainers,
}

/// Declares the current contract for one canonical family or entry type.
class ExportPolicy {
  const ExportPolicy({
    required this.native,
    required this.codex,
    required this.reason,
  });

  final ExportTargetSupport native;
  final ExportTargetSupport codex;
  final String reason;
}

/// Maps a hero-owned Drift table to the section used by the native backup.
///
/// Update this registry with the schema whenever a new hero-owned table is
/// added. The accompanying test deliberately rejects both missing and stale
/// entries, so a table cannot silently fall outside the backup contract.
class NativeHeroTablePolicy {
  const NativeHeroTablePolicy({
    required this.tableName,
    required this.storageFamily,
    required this.snapshotSection,
    required this.isOptional,
  });

  final String tableName;
  final HeroExportStorageFamily storageFamily;
  final String snapshotSection;
  final bool isOptional;
}

/// Central policy registry for export coverage.
///
/// `partial` is intentional: the data is canonical and retained by native
/// backups, while the current Codex mapper only has a verified representation
/// for some owner/slot variants. Those variants must report their final
/// emitted/unsupported/unresolved outcome during later mapper work.
class HeroExportPolicyRegistry {
  HeroExportPolicyRegistry._();

  static const ExportPolicy _nativeOnly = ExportPolicy(
    native: ExportTargetSupport.supported,
    codex: ExportTargetSupport.unsupported,
    reason: 'Preserved by Hero Smith backups but ignored by the Codex importer.',
  );

  static const Map<HeroExportStorageFamily, ExportPolicy> storageFamilies = {
    HeroExportStorageFamily.hero: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Identity is represented by the native hero row and Codex root.',
    ),
    HeroExportStorageFamily.entries: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Codex support depends on entry type and provenance.',
    ),
    HeroExportStorageFamily.config: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Some selections are mapped; config is otherwise app-local.',
    ),
    HeroExportStorageFamily.heroValues: _nativeOnly,
    HeroExportStorageFamily.downtimeProjects: _nativeOnly,
    HeroExportStorageFamily.followers: _nativeOnly,
    HeroExportStorageFamily.projectSources: _nativeOnly,
    HeroExportStorageFamily.notes: _nativeOnly,
    HeroExportStorageFamily.retainers: _nativeOnly,
  };

  /// Every table in `AppDatabase` that is owned by a single hero.
  static const Map<String, NativeHeroTablePolicy> nativeTables = {
    'heroes': NativeHeroTablePolicy(
      tableName: 'heroes',
      storageFamily: HeroExportStorageFamily.hero,
      snapshotSection: 'hero',
      isOptional: false,
    ),
    'hero_entries': NativeHeroTablePolicy(
      tableName: 'hero_entries',
      storageFamily: HeroExportStorageFamily.entries,
      snapshotSection: 'entries',
      isOptional: false,
    ),
    'hero_config': NativeHeroTablePolicy(
      tableName: 'hero_config',
      storageFamily: HeroExportStorageFamily.config,
      snapshotSection: 'config',
      isOptional: false,
    ),
    'hero_values': NativeHeroTablePolicy(
      tableName: 'hero_values',
      storageFamily: HeroExportStorageFamily.heroValues,
      snapshotSection: 'values',
      isOptional: false,
    ),
    'hero_downtime_projects': NativeHeroTablePolicy(
      tableName: 'hero_downtime_projects',
      storageFamily: HeroExportStorageFamily.downtimeProjects,
      snapshotSection: 'projects',
      isOptional: true,
    ),
    'hero_followers': NativeHeroTablePolicy(
      tableName: 'hero_followers',
      storageFamily: HeroExportStorageFamily.followers,
      snapshotSection: 'followers',
      isOptional: true,
    ),
    'hero_project_sources': NativeHeroTablePolicy(
      tableName: 'hero_project_sources',
      storageFamily: HeroExportStorageFamily.projectSources,
      snapshotSection: 'sources',
      isOptional: true,
    ),
    'hero_notes': NativeHeroTablePolicy(
      tableName: 'hero_notes',
      storageFamily: HeroExportStorageFamily.notes,
      snapshotSection: 'notes',
      isOptional: true,
    ),
    'hero_retainers': NativeHeroTablePolicy(
      tableName: 'hero_retainers',
      storageFamily: HeroExportStorageFamily.retainers,
      snapshotSection: 'retainers',
      isOptional: true,
    ),
  };

  static const Map<String, ExportPolicy> entryTypes = {
    HeroEntryTypes.ability: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Chosen class abilities are mapped; grants need explicit handling.',
    ),
    HeroEntryTypes.ancestry: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Mapped as the Codex ancestry.',
    ),
    HeroEntryTypes.ancestryTrait: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Trait choices require verified ancestry-slot provenance.',
    ),
    HeroEntryTypes.career: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Mapped as the Codex career.',
    ),
    HeroEntryTypes.classEntry: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Required Codex class identity.',
    ),
    HeroEntryTypes.classFeature: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Leveled generic and subclass feature mapping is incomplete.',
    ),
    HeroEntryTypes.complication: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Identity is mapped; complication choices and grants are not.',
    ),
    HeroEntryTypes.conditionImmunity: _nativeOnly,
    HeroEntryTypes.culture: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Culture is assembled from its owned aspects and choices.',
    ),
    HeroEntryTypes.cultureEnvironment: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Mapped as a Codex culture aspect.',
    ),
    HeroEntryTypes.cultureOrganisation: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Mapped as a Codex culture aspect.',
    ),
    HeroEntryTypes.cultureUpbringing: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.supported,
      reason: 'Mapped as a Codex culture aspect.',
    ),
    HeroEntryTypes.damageResistance: _nativeOnly,
    HeroEntryTypes.deity: _nativeOnly,
    HeroEntryTypes.domain: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Current support is limited to existing domain feature shapes.',
    ),
    HeroEntryTypes.equipment: _nativeOnly,
    HeroEntryTypes.equipmentBonuses: _nativeOnly,
    HeroEntryTypes.feature: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Only verified generic choice shapes can be exported.',
    ),
    HeroEntryTypes.featureStatBonus: _nativeOnly,
    HeroEntryTypes.imbuement: _nativeOnly,
    HeroEntryTypes.immunity: _nativeOnly,
    HeroEntryTypes.itemPrerequisite: _nativeOnly,
    HeroEntryTypes.kit: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Selected kits are mapped; owner level must be preserved.',
    ),
    HeroEntryTypes.kitFeature: _nativeOnly,
    HeroEntryTypes.kitStatBonus: _nativeOnly,
    HeroEntryTypes.language: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Culture and career ownership is not fully provenance-correct.',
    ),
    HeroEntryTypes.perk: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Career and class choice ownership must be resolved.',
    ),
    HeroEntryTypes.resistance: _nativeOnly,
    HeroEntryTypes.skill: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Only verified owner slots are safely representable.',
    ),
    HeroEntryTypes.statMod: _nativeOnly,
    HeroEntryTypes.subclass: ExportPolicy(
      native: ExportTargetSupport.supported,
      codex: ExportTargetSupport.partial,
      reason: 'Identity is mapped; subclass features are not yet complete.',
    ),
    HeroEntryTypes.title: _nativeOnly,
    HeroEntryTypes.treasure: _nativeOnly,
    HeroEntryTypes.weakness: _nativeOnly,
  };

  static ExportPolicy? forEntryType(String entryType) => entryTypes[entryType];
}
