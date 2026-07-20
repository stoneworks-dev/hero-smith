import '../storage/hero_storage_contract.dart';
import 'stat_modification_model.dart';

class HeroSource {
  const HeroSource({
    required this.sourceType,
    required this.sourceId,
    this.gainedBy = HeroEntryGainedBy.grant,
  });

  const HeroSource.manualChoice({
    this.sourceId = '',
    this.gainedBy = HeroEntryGainedBy.choice,
  }) : sourceType = HeroEntrySourceTypes.manualChoice;

  final String sourceType;
  final String sourceId;
  final String gainedBy;

  HeroSource copyWith({
    String? sourceType,
    String? sourceId,
    String? gainedBy,
  }) {
    return HeroSource(
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      gainedBy: gainedBy ?? this.gainedBy,
    );
  }
}

class ResolvedGrant {
  const ResolvedGrant({
    required this.entryType,
    required this.entryId,
    this.payload,
    this.gainedBy,
  });

  factory ResolvedGrant.statMod({
    required String stat,
    required Iterable<StatModification> modifications,
    String? entryId,
    String? gainedBy,
  }) {
    final normalizedStat = stat.trim().toLowerCase();
    return ResolvedGrant(
      entryType: HeroEntryTypes.statMod,
      entryId: entryId ?? normalizedStat,
      payload: {
        'mods':
            modifications.map((modification) => modification.toJson()).toList(),
      },
      gainedBy: gainedBy,
    );
  }

  final String entryType;
  final String entryId;
  final Map<String, dynamic>? payload;
  final String? gainedBy;
}
