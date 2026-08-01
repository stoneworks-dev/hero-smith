import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/complication_grant_models.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icon_data.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_complication_section_text.dart';
import '../../../../core/storage/hero_storage_contract.dart';
import '../../../hero_builder/domain/hero_claim.dart';
import '../../../hero_builder/domain/hero_conflict_index.dart';
import '../../../../widgets/abilities/ability_expandable_item.dart';
import '../../../../widgets/treasures/treasures.dart';

class _SearchOption<T> {
  const _SearchOption({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final T? value;
  final String? subtitle;
}

class _PickerSelection<T> {
  const _PickerSelection({required this.value});

  final T? value;
}

Future<_PickerSelection<T>?> _showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<_SearchOption<T>> options,
  T? selected,
  Color? accent,
  AppIconData? icon,
}) {
  final accentColor = accent ?? CreatorTheme.complicationAccent;
  final effectiveIcon = icon ?? const MaterialIcon(Icons.search);

  return showDialog<_PickerSelection<T>>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = query.trim().toLowerCase();
          final List<_SearchOption<T>> filtered = normalizedQuery.isEmpty
              ? options
              : options
                  .where(
                    (option) =>
                        option.label.toLowerCase().contains(normalizedQuery) ||
                        (option.subtitle?.toLowerCase().contains(
                                  normalizedQuery,
                                ) ??
                            false),
                  )
                  .toList();

          return Dialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: accentColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: AppIcon(effectiveIcon,
                              color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              Icon(Icons.close, color: FormTheme.textSecondary),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(color: FormTheme.textBright),
                      decoration: InputDecoration(
                        hintText: StoryComplicationSectionText.searchHint,
                        hintStyle: TextStyle(color: FormTheme.textMuted),
                        prefixIcon:
                            Icon(Icons.search, color: FormTheme.textMuted),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: FormTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: FormTheme.borderLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  StoryComplicationSectionText.noMatchesFound,
                                  style: TextStyle(
                                    color: FormTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final isNoneOption = option.value == null;
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isNoneOption
                                      ? FormTheme.surfaceMuted
                                      : isSelected
                                          ? accentColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accentColor.withValues(
                                              alpha: 0.4),
                                        )
                                      : isNoneOption
                                          ? Border.all(
                                              color: FormTheme.border,
                                            )
                                          : null,
                                ),
                                child: ListTile(
                                  leading: isNoneOption
                                      ? Icon(Icons.remove_circle_outline,
                                          size: 20, color: FormTheme.textMuted)
                                      : null,
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isNoneOption
                                          ? FormTheme.textSecondary
                                          : isSelected
                                              ? accentColor
                                              : Colors.grey.shade200,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontStyle: isNoneOption
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                  subtitle: option.subtitle != null
                                      ? Text(
                                          option.subtitle!,
                                          style: TextStyle(
                                            color: FormTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: accentColor, size: 22)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    _PickerSelection<T>(value: option.value),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Cancel button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: FormTheme.borderDim),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: FormTheme.textSecondary,
                      ),
                      child:
                          const Text(StoryComplicationSectionText.cancelLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class StoryComplicationSection extends ConsumerStatefulWidget {
  const StoryComplicationSection({
    super.key,
    required this.selectedComplicationId,
    required this.complicationChoices,
    this.conflictIndex = HeroConflictIndex.empty,
    required this.onComplicationChanged,
    required this.onChoicesChanged,
    required this.onDirty,
    this.heroAncestryTraitIds = const {},
  });

  final String? selectedComplicationId;
  final Map<String, String> complicationChoices;
  final HeroConflictIndex conflictIndex;
  final ValueChanged<String?> onComplicationChanged;
  final ValueChanged<Map<String, String>> onChoicesChanged;
  final VoidCallback onDirty;

  /// Ancestry trait IDs already selected by the hero (to exclude from complication trait picks)
  final Set<String> heroAncestryTraitIds;

  @override
  ConsumerState<StoryComplicationSection> createState() =>
      _StoryComplicationSectionState();
}

class _StoryComplicationSectionState
    extends ConsumerState<StoryComplicationSection> {
  @override
  Widget build(BuildContext context) {
    const accent = CreatorTheme.complicationAccent;
    final complicationsAsync =
        ref.watch(selectableComponentsByTypeProvider('complication'));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: CreatorTheme.sectionDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: StoryComplicationSectionText.sectionTitle,
            subtitle: StoryComplicationSectionText.sectionSubtitle,
            appIcon: StoryIcons.complication,
            accent: accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Builder(builder: (context) {
              final complications = complicationsAsync.valueOrNull;
              if (complications == null) {
                if (complicationsAsync.hasError) {
                  return CreatorTheme.errorMessage(
                    '${StoryComplicationSectionText.failedToLoadComplicationsPrefix}${complicationsAsync.error}',
                  );
                }
                return CreatorTheme.loadingIndicator(accent);
              }

              if (complications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    StoryComplicationSectionText.noComplicationsAvailable,
                    style: TextStyle(color: FormTheme.textMuted),
                  ),
                );
              }

              final sorted = [...complications];
              sorted.sort((a, b) => a.name.compareTo(b.name));
              final pickerComplications = sorted.where((comp) {
                final claimed = widget.conflictIndex.isClaimed(
                  HeroEntryKey(
                    entryType: HeroEntryTypes.complication,
                    canonicalEntryId: comp.id,
                  ),
                  ignoredDraftSlotKey: 'story.complication:selection#0',
                );
                return !claimed;
              }).toList();

              final selectedComp = widget.selectedComplicationId != null
                  ? sorted.firstWhere(
                      (c) => c.id == widget.selectedComplicationId,
                      orElse: () => sorted.first,
                    )
                  : null;

              Future<void> openSearch() async {
                final options = <_SearchOption<String?>>[
                  const _SearchOption<String?>(
                    label: StoryComplicationSectionText.noneOptionLabel,
                    value: null,
                  ),
                  ...pickerComplications.map(
                    (comp) => _SearchOption<String?>(
                      label: comp.name,
                      value: comp.id,
                    ),
                  ),
                ];

                final result = await _showSearchablePicker<String?>(
                  context: context,
                  title: StoryComplicationSectionText.selectComplicationTitle,
                  options: options,
                  selected: widget.selectedComplicationId,
                );

                if (result == null) return;
                widget.onComplicationChanged(result.value);
                widget.onDirty();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Complication dropdown
                  InkWell(
                    onTap: openSearch,
                    borderRadius:
                        BorderRadius.circular(CreatorTheme.inputBorderRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: FormTheme.surface,
                        borderRadius: BorderRadius.circular(
                            CreatorTheme.inputBorderRadius),
                        border: Border.all(
                          color: selectedComp != null
                              ? accent.withValues(alpha: 0.5)
                              : FormTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          AppIcon(
                            StoryIcons.complication,
                            color: selectedComp != null
                                ? accent
                                : FormTheme.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StoryComplicationSectionText
                                      .selectComplicationLabel,
                                  style: TextStyle(
                                    color: FormTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedComp != null
                                      ? selectedComp.name
                                      : StoryComplicationSectionText
                                          .nonePlaceholder,
                                  style: TextStyle(
                                    color: selectedComp != null
                                        ? FormTheme.textBright
                                        : FormTheme.borderLight,
                                    fontSize: 15,
                                    fontWeight: selectedComp != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.search,
                              color: FormTheme.textMuted, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (selectedComp != null) ...[
                    const SizedBox(height: 24),
                    StoryComplicationDetails(
                      complication: selectedComp,
                      choices: widget.complicationChoices,
                      conflictIndex: widget.conflictIndex,
                      onChoicesChanged: (choices) {
                        widget.onChoicesChanged(choices);
                        widget.onDirty();
                      },
                      heroAncestryTraitIds: widget.heroAncestryTraitIds,
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class StoryComplicationDetails extends ConsumerWidget {
  const StoryComplicationDetails({
    super.key,
    required this.complication,
    required this.choices,
    this.conflictIndex = HeroConflictIndex.empty,
    required this.onChoicesChanged,
    this.heroAncestryTraitIds = const {},
    this.trailing,
  });

  final model.Component complication;
  final Map<String, String> choices;
  final HeroConflictIndex conflictIndex;
  final ValueChanged<Map<String, String>> onChoicesChanged;
  final Widget? trailing;

  /// Ancestry trait IDs already selected by the hero (to exclude from complication trait picks)
  final Set<String> heroAncestryTraitIds;

  void _updateChoice(String key, String? value) {
    final newChoices = Map<String, String>.from(choices);
    if (value == null || value.isEmpty) {
      newChoices.remove(key);
    } else {
      newChoices[key] = value;
    }
    onChoicesChanged(newChoices);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = CreatorTheme.complicationAccent;
    final data = complication.data;
    final complicationId = complication.id;

    // Parse grants
    final grantsData = data['grants'];
    List<ComplicationGrant> grants = [];
    if (grantsData != null) {
      grants = ComplicationGrant.parseFromGrantsData(
        grantsData,
        complicationId,
        complication.name,
        choices,
      );
    }
    final allComponents = ref.watch(allComponentsProvider).valueOrNull ??
        const <model.Component>[];
    final effectiveConflictIndex = conflictIndex.withClaims(
      _grantDraftClaims(grants, complicationId, allComponents),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.withValues(alpha: 0.2),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: const AppIcon(StoryIcons.complication,
                    color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  complication.name,
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (data['description'] != null) ...[
            Text(
              data['description'].toString(),
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (data['effects'] != null) ...[
            _buildEffects(context, data['effects']),
            const SizedBox(height: 12),
          ],
          if (grants.isNotEmpty) ...[
            _buildGrantsSection(
              context,
              ref,
              grants,
              complicationId,
              effectiveConflictIndex,
            ),
          ],
        ],
      ),
    );
  }

  Iterable<HeroEntryClaim> _grantDraftClaims(
    List<ComplicationGrant> grants,
    String complicationId,
    List<model.Component> allComponents,
  ) sync* {
    final source = HeroClaimSource(
      sourceType: HeroEntrySourceTypes.complication,
      sourceId: complicationId,
    );
    String? idByName(String type, String name) => allComponents
        .firstWhereOrNull(
          (component) =>
              component.type == type &&
              component.name.trim().toLowerCase() == name.trim().toLowerCase(),
        )
        ?.id;
    HeroEntryClaim claim(String type, String id, String slot) => HeroEntryClaim(
          key: HeroEntryKey(entryType: type, canonicalEntryId: id),
          owner: HeroClaimOwner.draft(
            source: source,
            slotKey: slot,
            displayLabel: 'Complication grant',
          ),
        );

    var treasureIndex = 0;
    for (final grant in grants) {
      switch (grant) {
        case SkillGrant():
          final id = idByName(HeroEntryTypes.skill, grant.skillName);
          if (id != null) {
            yield claim(
              HeroEntryTypes.skill,
              id,
              _fixedGrantSlot(complicationId, 'skill', grant.skillName),
            );
          }
        case SkillFromGroupGrant():
          for (var i = 0; i < grant.selectedSkillIds.length; i++) {
            yield claim(
              HeroEntryTypes.skill,
              grant.selectedSkillIds[i],
              'story.complication:${complicationId}_skill_$i',
            );
          }
        case SkillFromOptionsGrant():
          final id = grant.selectedSkillId;
          if (id != null && id.isNotEmpty) {
            yield claim(
              HeroEntryTypes.skill,
              id,
              'story.complication:${complicationId}_skill_option',
            );
          }
        case AbilityGrant():
          final id = idByName(HeroEntryTypes.ability, grant.abilityName);
          if (id != null) {
            yield claim(
              HeroEntryTypes.ability,
              id,
              _fixedGrantSlot(complicationId, 'ability', grant.abilityName),
            );
          }
        case TreasureGrant():
          final id = grant.selectedTreasureId;
          if (id != null && id.isNotEmpty) {
            yield claim(
              HeroEntryTypes.treasure,
              id,
              'story.complication:${complicationId}_treasure_$treasureIndex',
            );
          }
          treasureIndex++;
        case LeveledTreasureGrant():
          final id = grant.selectedTreasureId;
          if (id != null && id.isNotEmpty) {
            yield claim(
              HeroEntryTypes.treasure,
              id,
              'story.complication:${complicationId}_treasure_$treasureIndex',
            );
          }
          treasureIndex++;
        case LanguageGrant():
          for (var i = 0; i < grant.selectedLanguageIds.length; i++) {
            yield claim(
              HeroEntryTypes.language,
              grant.selectedLanguageIds[i],
              'story.complication:${complicationId}_language_$i',
            );
          }
        case DeadLanguageGrant():
          for (var i = 0; i < grant.selectedLanguageIds.length; i++) {
            yield claim(
              HeroEntryTypes.language,
              grant.selectedLanguageIds[i],
              'story.complication:${complicationId}_dead_language_$i',
            );
          }
        case AncestryTraitsGrant():
          final selected =
              choices['${complicationId}_ancestry_traits']?.split(',') ??
                  const <String>[];
          for (final id in selected.where((id) => id.trim().isNotEmpty)) {
            yield claim(
              HeroEntryTypes.ancestryTrait,
              id,
              'story.complication:${complicationId}_ancestry_trait:$id',
            );
          }
        case FeatureGrant():
          final id = allComponents
              .firstWhereOrNull(
                (component) =>
                    component.name.trim().toLowerCase() ==
                    grant.featureName.trim().toLowerCase(),
              )
              ?.id;
          if (id != null) {
            yield claim(
              HeroEntryTypes.feature,
              id,
              _fixedGrantSlot(complicationId, 'feature', grant.featureName),
            );
          }
        default:
          break;
      }
    }
    for (final choice in choices.entries.where(
      (choice) => choice.key.startsWith('${complicationId}_trait_'),
    )) {
      final selectedAbility = allComponents.firstWhereOrNull(
        (component) =>
            component.type == HeroEntryTypes.ability &&
            (component.id == choice.value ||
                component.name.trim().toLowerCase() ==
                    choice.value.trim().toLowerCase()),
      );
      if (selectedAbility != null) {
        yield claim(
          HeroEntryTypes.ability,
          selectedAbility.id,
          'story.complication:${choice.key}',
        );
      }
    }
  }

  String _fixedGrantSlot(String complicationId, String type, String name) =>
      'story.complication:$complicationId:fixed-$type:${name.trim().toLowerCase()}';

  bool _isClaimedByAnotherOwner(
    HeroConflictIndex index,
    String entryType,
    String entryId,
    String slotKey,
  ) =>
      index.isClaimed(
        HeroEntryKey(entryType: entryType, canonicalEntryId: entryId),
        ignoredDraftSlotKey: slotKey,
      );

  Widget _buildEffects(BuildContext context, dynamic effects) {
    const accent = CreatorTheme.complicationAccent;
    final effectsData = effects as Map<String, dynamic>?;
    if (effectsData == null) return const SizedBox.shrink();

    final benefit = effectsData['benefit']?.toString();
    final drawback = effectsData['drawback']?.toString();
    final both = effectsData['both']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(CombatIcons.surges, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(
              StoryComplicationSectionText.effectsTitle,
              style: TextStyle(
                color: FormTheme.textBright,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (benefit != null && benefit.isNotEmpty) ...[
          _buildEffectItem(
            context,
            StoryComplicationSectionText.effectBenefitLabel,
            benefit,
            const Color(0xFF66BB6A), // Green for benefit
            Icons.add_circle_outline,
          ),
          const SizedBox(height: 8),
        ],
        if (drawback != null && drawback.isNotEmpty) ...[
          _buildEffectItem(
            context,
            StoryComplicationSectionText.effectDrawbackLabel,
            drawback,
            accent, // Red for drawback
            Icons.remove_circle_outline,
          ),
          const SizedBox(height: 8),
        ],
        if (both != null && both.isNotEmpty) ...[
          _buildEffectItem(
            context,
            StoryComplicationSectionText.effectMixedLabel,
            both,
            const Color(0xFFAB47BC), // Purple for mixed
            Icons.swap_horiz,
          ),
        ],
      ],
    );
  }

  Widget _buildEffectItem(
    BuildContext context,
    String label,
    String text,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: FormTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrantsSection(
    BuildContext context,
    WidgetRef ref,
    List<ComplicationGrant> grants,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    if (grants.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];

    // Track treasure index for both TreasureGrant and LeveledTreasureGrant
    // They share the same index since they're parsed from the same "treasures" array
    int treasureIndex = 0;

    for (final grant in grants) {
      Widget? widget;

      // Pass appropriate index for treasure grants
      if (grant is TreasureGrant) {
        if (grant.requiresChoice) {
          widget = _buildTreasureChoiceGrant(context, ref, grant,
              complicationId, treasureIndex, conflictIndex);
        } else {
          final echelonStr = grant.echelon != null
              ? '${StoryComplicationSectionText.echelonPrefix}${grant.echelon}${StoryComplicationSectionText.echelonSuffix}'
              : '';
          widget = _buildGrantItem(
            context,
            '${grant.treasureType.replaceAll('_', ' ')}$echelonStr',
            AppIcons.treasures,
          );
        }
        treasureIndex++;
      } else if (grant is LeveledTreasureGrant) {
        widget = _buildLeveledTreasureGrant(
            context, ref, grant, complicationId, treasureIndex, conflictIndex);
        treasureIndex++;
      } else {
        widget = _buildGrantWidget(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );
      }

      if (widget != null) {
        items.add(widget);
        items.add(const SizedBox(height: 8));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(PerkIcons.grant,
                color: CreatorTheme.complicationAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              StoryComplicationSectionText.grantsTitle,
              style: TextStyle(
                color: FormTheme.textBright,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget? _buildGrantWidget(
    BuildContext context,
    WidgetRef ref,
    ComplicationGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    switch (grant) {
      case SkillGrant():
        return _buildFixedSkillGrant(
          context,
          ref,
          grant.skillName,
          complicationId,
          conflictIndex,
        );

      case SkillFromGroupGrant():
        return _buildSkillFromGroupGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );

      case SkillFromOptionsGrant():
        return _buildSkillFromOptionsGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );

      case AbilityGrant():
        return _buildAbilityGrant(
          context,
          ref,
          grant.abilityName,
          complicationId,
          conflictIndex,
        );

      // TreasureGrant and LeveledTreasureGrant are handled in _buildGrantsSection with indices
      case TreasureGrant():
        return null;

      case LeveledTreasureGrant():
        return null;

      case TokenGrant():
        return _buildGrantItem(
          context,
          '${grant.count} ${grant.tokenType.replaceAll('_', ' ')}${StoryComplicationSectionText.tokenSuffixSingular}${grant.count == 1 ? '' : StoryComplicationSectionText.tokenSuffixPlural}',
          PerkIcons.token,
        );

      case LanguageGrant():
        return _buildLanguageGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );

      case DeadLanguageGrant():
        return _buildDeadLanguageGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );

      case IncreaseTotalGrant():
        final typeStr = grant.damageType != null
            ? '${StoryComplicationSectionText.damageTypePrefix}${grant.damageType}${StoryComplicationSectionText.damageTypeSuffix}'
            : '';
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.increasePrefix}${grant.value} ${grant.stat.replaceAll('_', ' ')}$typeStr',
          const MaterialIcon(Icons.trending_up_outlined),
        );

      case IncreaseTotalPerEchelonGrant():
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.increasePrefix}${grant.valuePerEchelon} ${grant.stat.replaceAll('_', ' ')}${StoryComplicationSectionText.perEchelonSuffix}',
          const MaterialIcon(Icons.trending_up_outlined),
        );

      case DecreaseTotalGrant():
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.decreasePrefix}${grant.value} ${grant.stat.replaceAll('_', ' ')}',
          const MaterialIcon(Icons.trending_down_outlined),
        );

      case SetBaseStatIfNotLowerGrant():
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.baseStatPrefix}${grant.stat.replaceAll('_', ' ')}${StoryComplicationSectionText.baseStatSeparator}${grant.value}',
          const MaterialIcon(Icons.adjust_outlined),
        );

      case AncestryTraitsGrant():
        return _buildAncestryTraitsGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );

      case PickOneGrant():
        return _buildPickOneGrant(context, ref, grant, complicationId);

      case IncreaseRecoveryGrant():
        final valueStr = grant.value == 'highest_characteristic'
            ? StoryComplicationSectionText.recoveryHighestCharacteristic
            : '${StoryComplicationSectionText.recoveryByPrefix}${grant.value}';
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.increaseRecoveryPrefix}$valueStr',
          CombatIcons.recovery,
        );

      case FeatureGrant():
        return _buildFixedFeatureGrant(
          context,
          ref,
          grant,
          complicationId,
          conflictIndex,
        );
    }
  }

  Widget _buildSkillFromGroupGrant(
    BuildContext context,
    WidgetRef ref,
    SkillFromGroupGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final groupsStr = grant.groups.join(', ');
    final skillsAsync = ref.watch(selectableComponentsByTypeProvider('skill'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(StoryIcons.skills, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseSkillFromGroupPrefix}${grant.count}'
                  '${grant.count > 1 ? StoryComplicationSectionText.skillPluralSuffix : StoryComplicationSectionText.skillSingularSuffix}'
                  '${StoryComplicationSectionText.chooseSkillFromGroupSuffix}$groupsStr',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final allSkills = skillsAsync.valueOrNull;
            if (allSkills == null) {
              if (skillsAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingSkillsPrefix}${skillsAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter skills by groups - 'any' means all groups
            final isAnyGroup = grant.groups.contains('any');
            final filteredSkills = allSkills.where((skill) {
              final skillGroup =
                  (skill.data['group'] as String?)?.toLowerCase() ?? '';
              if (isAnyGroup) return true;
              return grant.groups.any((g) => g.toLowerCase() == skillGroup);
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (filteredSkills.isEmpty) {
              return Text(
                '${StoryComplicationSectionText.noSkillsAvailablePrefix}$groupsStr',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Build picker slots for each skill choice
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(grant.count, (index) {
                final choiceKey = '${complicationId}_skill_$index';
                final selectedId = index < grant.selectedSkillIds.length
                    ? grant.selectedSkillIds[index]
                    : null;
                final selectedSkill = selectedId != null
                    ? filteredSkills.firstWhereOrNull((s) => s.id == selectedId)
                    : null;

                // Exclude already selected skills from options and guard
                // against skills the hero already owns from other sources.
                final slotKey = 'story.complication:$choiceKey';
                final availableSkills = filteredSkills
                    .where(
                      (skill) => !_isClaimedByAnotherOwner(
                        conflictIndex,
                        HeroEntryTypes.skill,
                        skill.id,
                        slotKey,
                      ),
                    )
                    .toList();
                final isDuplicate = selectedId != null &&
                    _isClaimedByAnotherOwner(
                      conflictIndex,
                      HeroEntryTypes.skill,
                      selectedId,
                      slotKey,
                    );

                return Padding(
                  padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final options = availableSkills.map((s) {
                        final group = s.data['group'] as String? ?? '';
                        final description =
                            s.data['description'] as String? ?? '';
                        return _SearchOption<String>(
                          label: s.name,
                          value: s.id,
                          subtitle:
                              '${StoryComplicationSectionText.groupSubtitlePrefix}$group${StoryComplicationSectionText.groupSubtitleSuffix}$description',
                        );
                      }).toList();

                      final result = await _showSearchablePicker<String>(
                        context: context,
                        title:
                            '${StoryComplicationSectionText.selectSkillTitlePrefix}${index + 1}',
                        options: options,
                        selected: selectedId,
                      );

                      if (result != null) {
                        _updateChoice(choiceKey, result.value);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FormTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDuplicate
                              ? Colors.orange.withValues(alpha: 0.7)
                              : selectedSkill != null
                                  ? accent.withValues(alpha: 0.6)
                                  : FormTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDuplicate
                                ? Icons.warning_amber_rounded
                                : selectedSkill != null
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                            size: 20,
                            color: isDuplicate
                                ? Colors.orange.shade600
                                : selectedSkill != null
                                    ? accent
                                    : FormTheme.borderLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedSkill == null
                                  ? '${StoryComplicationSectionText.tapToSelectSkillPrefix}${index + 1}${StoryComplicationSectionText.tapToSelectSkillSuffix}'
                                  : isDuplicate
                                      ? '${selectedSkill.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                      : selectedSkill.name,
                              style: TextStyle(
                                color: isDuplicate
                                    ? Colors.orange.shade200
                                    : selectedSkill != null
                                        ? FormTheme.textBright
                                        : FormTheme.textMuted,
                                fontStyle: selectedSkill != null
                                    ? null
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: FormTheme.borderLight),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillFromOptionsGrant(
    BuildContext context,
    WidgetRef ref,
    SkillFromOptionsGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final skillsAsync = ref.watch(selectableComponentsByTypeProvider('skill'));
    final choiceKey = '${complicationId}_skill_option';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(StoryIcons.skills, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseSkillFromOptionsPrefix}${grant.options.join(', ')}',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final allSkills = skillsAsync.valueOrNull;
            if (allSkills == null) {
              if (skillsAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingSkillsPrefix}${skillsAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter skills by options - match by name (case-insensitive)
            final optionNamesLower =
                grant.options.map((o) => o.toLowerCase()).toSet();
            final filteredSkills = allSkills.where((skill) {
              return optionNamesLower.contains(skill.name.toLowerCase());
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (filteredSkills.isEmpty) {
              return Text(
                '${StoryComplicationSectionText.noMatchingSkillsPrefix}${grant.options.join(', ')}',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            final selectedSkill = grant.selectedSkillId != null
                ? filteredSkills
                    .firstWhereOrNull((s) => s.id == grant.selectedSkillId)
                : null;
            final slotKey = 'story.complication:$choiceKey';
            final availableSkills = filteredSkills
                .where(
                  (skill) => !_isClaimedByAnotherOwner(
                    conflictIndex,
                    HeroEntryTypes.skill,
                    skill.id,
                    slotKey,
                  ),
                )
                .toList();
            final isDuplicate = grant.selectedSkillId != null &&
                _isClaimedByAnotherOwner(
                  conflictIndex,
                  HeroEntryTypes.skill,
                  grant.selectedSkillId!,
                  slotKey,
                );

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final options = availableSkills.map((s) {
                  final group = s.data['group'] as String? ?? '';
                  final description = s.data['description'] as String? ?? '';
                  return _SearchOption<String>(
                    label: s.name,
                    value: s.id,
                    subtitle:
                        '${StoryComplicationSectionText.groupSubtitlePrefix}$group${StoryComplicationSectionText.groupSubtitleSuffix}$description',
                  );
                }).toList();

                final result = await _showSearchablePicker<String>(
                  context: context,
                  title: StoryComplicationSectionText.selectSkillTitle,
                  options: options,
                  selected: grant.selectedSkillId,
                );

                if (result != null) {
                  _updateChoice(choiceKey, result.value);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FormTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDuplicate
                        ? Colors.orange.withValues(alpha: 0.7)
                        : selectedSkill != null
                            ? accent.withValues(alpha: 0.6)
                            : FormTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDuplicate
                          ? Icons.warning_amber_rounded
                          : selectedSkill != null
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                      size: 20,
                      color: isDuplicate
                          ? Colors.orange.shade600
                          : selectedSkill != null
                              ? accent
                              : FormTheme.borderLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedSkill == null
                            ? StoryComplicationSectionText.tapToSelectSkill
                            : isDuplicate
                                ? '${selectedSkill.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                : selectedSkill.name,
                        style: TextStyle(
                          color: isDuplicate
                              ? Colors.orange.shade200
                              : selectedSkill != null
                                  ? FormTheme.textBright
                                  : FormTheme.textMuted,
                          fontStyle:
                              selectedSkill != null ? null : FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: FormTheme.borderLight),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTreasureChoiceGrant(
    BuildContext context,
    WidgetRef ref,
    TreasureGrant grant,
    String complicationId,
    int treasureIndex,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final componentsAsync = ref.watch(selectableAllComponentsProvider);

    // Determine the treasure type to filter by
    final treasureType = grant.treasureType.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.treasures, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseTreasurePrefix}${treasureType.replaceAll('_', ' ')}${grant.echelon != null ? '${StoryComplicationSectionText.echelonPrefix}${grant.echelon}${StoryComplicationSectionText.echelonSuffix}' : ''}',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final components = componentsAsync.valueOrNull;
            if (components == null) {
              if (componentsAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingTreasuresPrefix}${componentsAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter by treasure type
            final treasures = components.where((c) {
              if (c.type != treasureType) return false;
              // Filter by echelon if specified
              if (grant.echelon != null) {
                final echelon = c.data['echelon'] as int?;
                return echelon == grant.echelon;
              }
              return true;
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (treasures.isEmpty) {
              return Text(
                '${StoryComplicationSectionText.noTreasureAvailablePrefix}${treasureType.replaceAll('_', ' ')}${StoryComplicationSectionText.treasurePluralSuffix}',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Use the proper index for the choice key
            final choiceKey = '${complicationId}_treasure_$treasureIndex';
            final slotKey = 'story.complication:$choiceKey';
            final selectedId = grant.selectedTreasureId;
            final selectedTreasure = selectedId != null
                ? treasures.firstWhereOrNull((t) => t.id == selectedId)
                : null;
            final availableTreasures = treasures
                .where(
                  (treasure) => !_isClaimedByAnotherOwner(
                    conflictIndex,
                    HeroEntryTypes.treasure,
                    treasure.id,
                    slotKey,
                  ),
                )
                .toList();
            final isDuplicate = selectedId != null &&
                _isClaimedByAnotherOwner(
                  conflictIndex,
                  HeroEntryTypes.treasure,
                  selectedId,
                  slotKey,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final options = availableTreasures.map((t) {
                      final subtitle = t.data['description'] as String?;
                      return _SearchOption<String>(
                        label: t.name,
                        value: t.id,
                        subtitle: subtitle,
                      );
                    }).toList();

                    final result = await _showSearchablePicker<String>(
                      context: context,
                      title:
                          '${StoryComplicationSectionText.selectTreasureTitlePrefix}${treasureType.replaceAll('_', ' ')}',
                      options: options,
                      selected: selectedId,
                    );

                    if (result != null) {
                      _updateChoice(choiceKey, result.value);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: FormTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDuplicate
                            ? Colors.orange.withValues(alpha: 0.7)
                            : selectedTreasure != null
                                ? accent.withValues(alpha: 0.6)
                                : FormTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedTreasure != null
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: selectedTreasure != null
                              ? accent
                              : FormTheme.borderLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedTreasure == null
                                ? StoryComplicationSectionText.tapToSelect
                                : isDuplicate
                                    ? '${selectedTreasure.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                    : selectedTreasure.name,
                            style: TextStyle(
                              color: selectedTreasure != null
                                  ? FormTheme.textBright
                                  : FormTheme.textMuted,
                              fontStyle: selectedTreasure != null
                                  ? null
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: FormTheme.borderLight,
                        ),
                      ],
                    ),
                  ),
                ),
                // Show treasure card preview when selected
                if (selectedTreasure != null) ...[
                  const SizedBox(height: 12),
                  _buildTreasurePreview(context, selectedTreasure),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeveledTreasureGrant(
    BuildContext context,
    WidgetRef ref,
    LeveledTreasureGrant grant,
    String complicationId,
    int leveledTreasureIndex,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final componentsAsync = ref.watch(selectableAllComponentsProvider);

    // The category to filter by (e.g., "weapon", "armor")
    final category = grant.category?.toLowerCase();
    final categoryLabel = category?.replaceAll('_', ' ') ??
        StoryComplicationSectionText.defaultTreasureCategory;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.treasures, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseLeveledTreasurePrefix}$categoryLabel',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final components = componentsAsync.valueOrNull;
            if (components == null) {
              if (componentsAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingTreasuresPrefix}${componentsAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter for leveled treasures matching the category
            final treasures = components.where((c) {
              if (c.type != 'leveled_treasure') return false;
              // Filter by leveled_type if category is specified
              if (category != null) {
                final leveledType = c.data['leveled_type'] as String?;
                return leveledType?.toLowerCase() == category;
              }
              return true;
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (treasures.isEmpty) {
              return Text(
                '${StoryComplicationSectionText.noLeveledTreasurePrefix}$categoryLabel${StoryComplicationSectionText.treasurePluralSuffix}',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Use the proper index for the choice key
            final choiceKey =
                '${complicationId}_treasure_$leveledTreasureIndex';
            final slotKey = 'story.complication:$choiceKey';
            final selectedId = grant.selectedTreasureId;
            final selectedTreasure = selectedId != null
                ? treasures.firstWhereOrNull((t) => t.id == selectedId)
                : null;
            final availableTreasures = treasures
                .where(
                  (treasure) => !_isClaimedByAnotherOwner(
                    conflictIndex,
                    HeroEntryTypes.treasure,
                    treasure.id,
                    slotKey,
                  ),
                )
                .toList();
            final isDuplicate = selectedId != null &&
                _isClaimedByAnotherOwner(
                  conflictIndex,
                  HeroEntryTypes.treasure,
                  selectedId,
                  slotKey,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final options = availableTreasures.map((t) {
                      final subtitle = t.data['description'] as String?;
                      return _SearchOption<String>(
                        label: t.name,
                        value: t.id,
                        subtitle: subtitle,
                      );
                    }).toList();

                    final result = await _showSearchablePicker<String>(
                      context: context,
                      title:
                          '${StoryComplicationSectionText.selectLeveledTreasureTitlePrefix}$categoryLabel',
                      options: options,
                      selected: selectedId,
                    );

                    if (result != null) {
                      _updateChoice(choiceKey, result.value);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: FormTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDuplicate
                            ? Colors.orange.withValues(alpha: 0.7)
                            : selectedTreasure != null
                                ? accent.withValues(alpha: 0.6)
                                : FormTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedTreasure != null
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: selectedTreasure != null
                              ? accent
                              : FormTheme.borderLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedTreasure == null
                                ? StoryComplicationSectionText.tapToSelect
                                : isDuplicate
                                    ? '${selectedTreasure.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                    : selectedTreasure.name,
                            style: TextStyle(
                              color: selectedTreasure != null
                                  ? FormTheme.textBright
                                  : FormTheme.textMuted,
                              fontStyle: selectedTreasure != null
                                  ? null
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: FormTheme.borderLight,
                        ),
                      ],
                    ),
                  ),
                ),
                // Show treasure card preview when selected
                if (selectedTreasure != null) ...[
                  const SizedBox(height: 12),
                  _buildTreasurePreview(context, selectedTreasure),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLanguageGrant(
    BuildContext context,
    WidgetRef ref,
    LanguageGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final languagesAsync =
        ref.watch(selectableComponentsByTypeProvider('language'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(StoryIcons.languages, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseLanguagePrefix}${grant.count}${grant.count > 1 ? StoryComplicationSectionText.languagePluralSuffix : StoryComplicationSectionText.languageSingularSuffix}',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final allLanguages = languagesAsync.valueOrNull;
            if (allLanguages == null) {
              if (languagesAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingLanguagesPrefix}${languagesAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter out dead languages - this is for living languages only
            final livingLanguages = allLanguages.where((lang) {
              final langType =
                  (lang.data['type'] as String?)?.toLowerCase() ?? '';
              return langType != 'dead';
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (livingLanguages.isEmpty) {
              return Text(
                StoryComplicationSectionText.noLanguagesAvailable,
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Build picker slots for each language choice
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(grant.count, (index) {
                final choiceKey = '${complicationId}_language_$index';
                final selectedId = index < grant.selectedLanguageIds.length
                    ? grant.selectedLanguageIds[index]
                    : null;
                final selectedLanguage = selectedId != null
                    ? livingLanguages
                        .firstWhereOrNull((l) => l.id == selectedId)
                    : null;

                // Exclude already selected languages from options and guard
                // against languages the hero already owns from other sources.
                final slotKey = 'story.complication:$choiceKey';
                final availableLanguages = livingLanguages
                    .where(
                      (language) => !_isClaimedByAnotherOwner(
                        conflictIndex,
                        HeroEntryTypes.language,
                        language.id,
                        slotKey,
                      ),
                    )
                    .toList();
                final isDuplicate = selectedId != null &&
                    _isClaimedByAnotherOwner(
                      conflictIndex,
                      HeroEntryTypes.language,
                      selectedId,
                      slotKey,
                    );

                return Padding(
                  padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final options = availableLanguages.map((l) {
                        final langType = l.data['type'] as String? ?? '';
                        final region = l.data['region'] as String?;
                        final ancestry = l.data['ancestry'] as String?;
                        final subtitle = region != null
                            ? '${StoryComplicationSectionText.languageGroupPrefix}$langType${StoryComplicationSectionText.languageGroupSuffix}${StoryComplicationSectionText.languageRegionPrefix}$region'
                            : ancestry != null
                                ? '${StoryComplicationSectionText.languageGroupPrefix}$langType${StoryComplicationSectionText.languageGroupSuffix}${StoryComplicationSectionText.languageAncestryPrefix}$ancestry'
                                : '${StoryComplicationSectionText.languageGroupPrefix}$langType${StoryComplicationSectionText.languageGroupSuffixOnly}';
                        return _SearchOption<String>(
                          label: l.name,
                          value: l.id,
                          subtitle: subtitle,
                        );
                      }).toList();

                      final result = await _showSearchablePicker<String>(
                        context: context,
                        title:
                            '${StoryComplicationSectionText.selectLanguageTitlePrefix}${index + 1}',
                        options: options,
                        selected: selectedId,
                      );

                      if (result != null) {
                        _updateChoice(choiceKey, result.value);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FormTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDuplicate
                              ? Colors.orange.withValues(alpha: 0.7)
                              : selectedLanguage != null
                                  ? accent.withValues(alpha: 0.6)
                                  : FormTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDuplicate
                                ? Icons.warning_amber_rounded
                                : selectedLanguage != null
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                            size: 20,
                            color: isDuplicate
                                ? Colors.orange.shade600
                                : selectedLanguage != null
                                    ? accent
                                    : FormTheme.borderLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedLanguage == null
                                  ? '${StoryComplicationSectionText.tapToSelectLanguagePrefix}${index + 1}${StoryComplicationSectionText.tapToSelectLanguageSuffix}'
                                  : isDuplicate
                                      ? '${selectedLanguage.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                      : selectedLanguage.name,
                              style: TextStyle(
                                color: isDuplicate
                                    ? Colors.orange.shade200
                                    : selectedLanguage != null
                                        ? FormTheme.textBright
                                        : FormTheme.textMuted,
                                fontStyle: selectedLanguage != null
                                    ? null
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: FormTheme.borderLight),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeadLanguageGrant(
    BuildContext context,
    WidgetRef ref,
    DeadLanguageGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final languagesAsync =
        ref.watch(selectableComponentsByTypeProvider('language'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(StoryIcons.languages, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${StoryComplicationSectionText.chooseDeadLanguagePrefix}${grant.count}${grant.count > 1 ? StoryComplicationSectionText.deadLanguagePluralSuffix : StoryComplicationSectionText.deadLanguageSingularSuffix}',
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final allLanguages = languagesAsync.valueOrNull;
            if (allLanguages == null) {
              if (languagesAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingLanguagesPrefix}${languagesAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Filter for dead languages only
            final deadLanguages = allLanguages.where((lang) {
              final langType =
                  (lang.data['language_type'] as String?)?.toLowerCase() ?? '';
              return langType == 'dead';
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (deadLanguages.isEmpty) {
              return Text(
                StoryComplicationSectionText.noDeadLanguagesAvailable,
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Build picker slots for each language choice
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(grant.count, (index) {
                final choiceKey = '${complicationId}_dead_language_$index';
                final selectedId = index < grant.selectedLanguageIds.length
                    ? grant.selectedLanguageIds[index]
                    : null;
                final selectedLanguage = selectedId != null
                    ? deadLanguages.firstWhereOrNull((l) => l.id == selectedId)
                    : null;

                // Exclude already selected languages from options and guard
                // against languages the hero already owns from other sources.
                final slotKey = 'story.complication:$choiceKey';
                final availableLanguages = deadLanguages
                    .where(
                      (language) => !_isClaimedByAnotherOwner(
                        conflictIndex,
                        HeroEntryTypes.language,
                        language.id,
                        slotKey,
                      ),
                    )
                    .toList();
                final isDuplicate = selectedId != null &&
                    _isClaimedByAnotherOwner(
                      conflictIndex,
                      HeroEntryTypes.language,
                      selectedId,
                      slotKey,
                    );

                return Padding(
                  padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final options = availableLanguages.map((l) {
                        final ancestry = l.data['ancestry'] as String? ?? '';
                        final commonTopics = l.data['common_topics'] as List?;
                        final topicsStr =
                            commonTopics != null ? commonTopics.join(', ') : '';
                        final subtitle = topicsStr.isNotEmpty
                            ? '${StoryComplicationSectionText.deadLanguageAncestryPrefix}$ancestry${StoryComplicationSectionText.deadLanguageTopicsSeparator}$topicsStr'
                            : '${StoryComplicationSectionText.deadLanguageAncestryPrefix}$ancestry';
                        return _SearchOption<String>(
                          label: l.name,
                          value: l.id,
                          subtitle: subtitle,
                        );
                      }).toList();

                      final result = await _showSearchablePicker<String>(
                        context: context,
                        title:
                            '${StoryComplicationSectionText.selectDeadLanguageTitlePrefix}${index + 1}',
                        options: options,
                        selected: selectedId,
                      );

                      if (result != null) {
                        _updateChoice(choiceKey, result.value);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FormTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDuplicate
                              ? Colors.orange.withValues(alpha: 0.7)
                              : selectedLanguage != null
                                  ? accent.withValues(alpha: 0.6)
                                  : FormTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDuplicate
                                ? Icons.warning_amber_rounded
                                : selectedLanguage != null
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                            size: 20,
                            color: isDuplicate
                                ? Colors.orange.shade600
                                : selectedLanguage != null
                                    ? accent
                                    : FormTheme.borderLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedLanguage == null
                                  ? '${StoryComplicationSectionText.tapToSelectDeadLanguagePrefix}${index + 1}${StoryComplicationSectionText.tapToSelectDeadLanguageSuffix}'
                                  : isDuplicate
                                      ? '${selectedLanguage.name} (${StoryComplicationSectionText.duplicateChoiceLabel})'
                                      : selectedLanguage.name,
                              style: TextStyle(
                                color: isDuplicate
                                    ? Colors.orange.shade200
                                    : selectedLanguage != null
                                        ? FormTheme.textBright
                                        : FormTheme.textMuted,
                                fontStyle: selectedLanguage != null
                                    ? null
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: FormTheme.borderLight),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPickOneGrant(
    BuildContext context,
    WidgetRef ref,
    PickOneGrant grant,
    String complicationId,
  ) {
    const accent = CreatorTheme.complicationAccent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AbilityIcons.featureChoice,
                  size: 18, color: accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  StoryComplicationSectionText.chooseOneLabel,
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(grant.options.length, (index) {
            final isSelected = grant.selectedIndex == index;
            final description = grant.getOptionDescription(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  _updateChoice('${complicationId}_pick_one', index.toString());
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.2)
                        : FormTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? accent : FormTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected ? accent : FormTheme.borderLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            color: isSelected
                                ? FormTheme.textBright
                                : FormTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds an ancestry traits picker for AncestryTraitsGrant (e.g., Dragon Dreams complication)
  Widget _buildAncestryTraitsGrant(
    BuildContext context,
    WidgetRef ref,
    AncestryTraitsGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final ancestryTraitsAsync =
        ref.watch(selectableComponentsByTypeProvider('ancestry_trait'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(StoryIcons.heroName, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${grant.ancestryPoints} ${_formatAncestryName(grant.ancestry)}${grant.ancestryPoints == 1 ? StoryComplicationSectionText.ancestryTraitPointSingularSuffix : StoryComplicationSectionText.ancestryTraitPointPluralSuffix}',
                  style: const TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final allAncestryTraits = ancestryTraitsAsync.valueOrNull;
            if (allAncestryTraits == null) {
              if (ancestryTraitsAsync.hasError) {
                return Text(
                    '${StoryComplicationSectionText.errorLoadingAncestryTraitsPrefix}${ancestryTraitsAsync.error}',
                    style: TextStyle(color: Colors.red.shade300));
              }
              return const SizedBox(
                height: 48,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent)),
              );
            }
            // Find the ancestry traits component that matches the grant's ancestry
            // e.g., "dragon_knight" matches "ancestry_dragon_knight" in ancestry_id
            final targetAncestryId = 'ancestry_${grant.ancestry}';
            final traitsComp = allAncestryTraits.firstWhereOrNull(
              (t) => t.data['ancestry_id'] == targetAncestryId,
            );

            if (traitsComp == null) {
              return Text(
                '${StoryComplicationSectionText.noTraitsFoundPrefix}${grant.ancestry}',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            final traitsList =
                (traitsComp.data['traits'] as List?)?.cast<Map>() ??
                    const <Map>[];

            if (traitsList.isEmpty) {
              return Text(
                '${StoryComplicationSectionText.noTraitsAvailablePrefix}${grant.ancestry}',
                style: TextStyle(
                    color: FormTheme.textMuted, fontStyle: FontStyle.italic),
              );
            }

            // Get selected traits from complication choices
            // Stored as comma-separated list: "complicationId_ancestry_traits" -> "dk_draconian_guard,dk_wings"
            final choiceKey = '${complicationId}_ancestry_traits';
            final selectedIdsStr = choices[choiceKey] ?? '';
            final selectedIds = selectedIdsStr.isNotEmpty
                ? selectedIdsStr.split(',').toSet()
                : <String>{};

            // Calculate spent points from selected traits
            final spent = selectedIds.fold<int>(0, (sum, id) {
              final match = traitsList.firstWhere(
                (t) => (t['id'] ?? t['name']).toString() == id,
                orElse: () => const {},
              );
              return sum + (match.cast<String, dynamic>()['cost'] as int? ?? 0);
            });
            final remaining = grant.ancestryPoints - spent;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${StoryComplicationSectionText.pointsLabelPrefix}${grant.ancestryPoints}',
                        style: TextStyle(
                            color: FormTheme.textBright, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: remaining < 0
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: remaining < 0
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${StoryComplicationSectionText.remainingLabelPrefix}$remaining',
                        style: TextStyle(
                          color: remaining < 0
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...traitsList.map((t) {
                  final traitData = t.cast<String, dynamic>();
                  final id = (traitData['id'] ?? traitData['name']).toString();
                  final name = (traitData['name'] ?? id).toString();
                  final desc = (traitData['description'] ?? '').toString();
                  final cost = (traitData['cost'] as int?) ?? 0;
                  final selected = selectedIds.contains(id);
                  final canSelect = selected || remaining - cost >= 0;

                  // Check for trait choices (immunity picks, ability picks)
                  final hasImmunityChoice = _traitHasImmunityChoice(traitData);
                  final abilityOptions = _getAbilityOptions(traitData);

                  // Exclude traits already selected by hero in ancestry section
                  final alreadyPickedByHero =
                      heroAncestryTraitIds.contains(id) ||
                          _isClaimedByAnotherOwner(
                            conflictIndex,
                            HeroEntryTypes.ancestryTrait,
                            id,
                            'story.complication:${complicationId}_ancestry_trait:$id',
                          );
                  if (alreadyPickedByHero) {
                    // Show as disabled/already picked
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        enabled: false,
                        leading: Icon(Icons.check_circle,
                            color: FormTheme.borderLight),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: FormTheme.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          StoryComplicationSectionText.alreadySelectedAncestry,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: FormTheme.borderLight,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FormTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$cost',
                            style: TextStyle(color: FormTheme.textMuted),
                          ),
                        ),
                      ),
                    );
                  }

                  // Get trait-specific choice value
                  final traitChoiceKey = '${complicationId}_trait_$id';
                  final currentTraitChoice = choices[traitChoiceKey];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            fillColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return accent;
                              }
                              return FormTheme.border;
                            }),
                            checkColor:
                                WidgetStateProperty.all(FormTheme.textBright),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: canSelect
                              ? (value) {
                                  if (value == null) return;
                                  final newSelected =
                                      Set<String>.from(selectedIds);
                                  if (value) {
                                    newSelected.add(id);
                                  } else {
                                    newSelected.remove(id);
                                    // Clear trait-specific choice when deselected
                                    final newChoices =
                                        Map<String, String>.from(choices);
                                    newChoices.remove(traitChoiceKey);
                                    onChoicesChanged(newChoices);
                                  }
                                  _updateChoice(
                                      choiceKey, newSelected.join(','));
                                }
                              : null,
                          title: Text(
                            name,
                            style: TextStyle(
                              color: canSelect
                                  ? FormTheme.textBright
                                  : FormTheme.textMuted,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                softWrap: true,
                                style: TextStyle(
                                    color: FormTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cost',
                              style: TextStyle(
                                  color: accent.withValues(alpha: 0.9)),
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      // Show immunity dropdown for selected traits with immunity choice
                      if (selected && hasImmunityChoice) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 40, right: 16, bottom: 8),
                          child: _buildImmunityDropdown(
                            traitId: id,
                            complicationId: complicationId,
                            currentValue: currentTraitChoice,
                            availableTypes: _immunityChoiceOptions(traitData),
                            excludedValues: _getExcludedImmunities(
                                id, complicationId, choices),
                          ),
                        ),
                      ],
                      // Show ability dropdown for selected traits with ability choice
                      if (selected && abilityOptions.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 40, right: 16, bottom: 8),
                          child: _buildAbilityDropdown(
                            ref: ref,
                            traitId: id,
                            complicationId: complicationId,
                            options: abilityOptions,
                            currentValue: currentTraitChoice,
                            conflictIndex: conflictIndex,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatAncestryName(String ancestry) {
    // Convert "dragon_knight" to "Dragon Knight"
    return ancestry.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildFixedSkillGrant(
    BuildContext context,
    WidgetRef ref,
    String skillName,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    final skillsAsync = ref.watch(selectableComponentsByTypeProvider('skill'));
    final skills = skillsAsync.valueOrNull;
    final normalizedName = skillName.trim().toLowerCase();
    final skillId = skills
        ?.firstWhereOrNull(
          (skill) => skill.name.trim().toLowerCase() == normalizedName,
        )
        ?.id;

    return _buildGrantItem(
      context,
      '${StoryComplicationSectionText.skillGrantPrefix}$skillName',
      StoryIcons.skills,
      isConflict: skillId != null &&
          _isClaimedByAnotherOwner(
            conflictIndex,
            HeroEntryTypes.skill,
            skillId,
            _fixedGrantSlot(complicationId, 'skill', skillName),
          ),
    );
  }

  Widget _buildFixedFeatureGrant(
    BuildContext context,
    WidgetRef ref,
    FeatureGrant grant,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    final components = ref.watch(allComponentsProvider).valueOrNull;
    final normalizedName = grant.featureName.trim().toLowerCase();
    final featureId = components
        ?.firstWhereOrNull(
          (component) => component.name.trim().toLowerCase() == normalizedName,
        )
        ?.id;
    final featureTypeDisplay = grant.featureType == 'mount'
        ? 'Mount'
        : grant.featureType == 'follower'
            ? 'Follower'
            : 'Feature';

    return _buildGrantItem(
      context,
      '${StoryComplicationSectionText.featureTypeDisplayPrefix}$featureTypeDisplay ${grant.featureName}${StoryComplicationSectionText.featureTypeTypePrefix}${grant.featureType}${StoryComplicationSectionText.featureTypeTypeSuffix}',
      AbilityIcons.abilityGrant,
      isConflict: featureId != null &&
          _isClaimedByAnotherOwner(
            conflictIndex,
            HeroEntryTypes.feature,
            featureId,
            _fixedGrantSlot(complicationId, 'feature', grant.featureName),
          ),
    );
  }

  Widget _buildGrantItem(
    BuildContext context,
    String text,
    AppIconData icon, {
    bool isConflict = false,
  }) {
    const accent = CreatorTheme.complicationAccent;
    final color = isConflict ? Colors.orange : accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isConflict ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: color.withValues(alpha: isConflict ? 0.5 : 0.2)),
      ),
      child: Row(
        children: [
          AppIcon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isConflict
                        ? Colors.orange.shade200
                        : FormTheme.textBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isConflict) ...[
                  const SizedBox(height: 2),
                  Text(
                    StoryComplicationSectionText.duplicateGrantLabel,
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isConflict) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConflictWrapper({
    required Widget child,
    required bool isConflict,
  }) {
    if (!isConflict) return child;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Text(
                StoryComplicationSectionText.duplicateGrantLabel,
                style: TextStyle(
                  color: Colors.orange.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Builds an ability grant widget that looks up and displays the full ability details.
  Widget _buildAbilityGrant(
    BuildContext context,
    WidgetRef ref,
    String abilityName,
    String complicationId,
    HeroConflictIndex conflictIndex,
  ) {
    const accent = CreatorTheme.complicationAccent;
    final abilityAsync = ref.watch(abilityByNameProvider(abilityName));

    final ability = abilityAsync.valueOrNull;
    if (ability == null) {
      if (abilityAsync.hasError) {
        return _buildGrantItem(
          context,
          '${StoryComplicationSectionText.abilityGrantPrefix}$abilityName',
          AbilityIcons.abilityGrant,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: accent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${StoryComplicationSectionText.loadingAbilityPrefix}$abilityName${StoryComplicationSectionText.loadingAbilitySuffix}',
              style: TextStyle(
                color: FormTheme.textBright,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return _buildConflictWrapper(
      isConflict: _isClaimedByAnotherOwner(
        conflictIndex,
        HeroEntryTypes.ability,
        ability.id,
        _fixedGrantSlot(complicationId, 'ability', abilityName),
      ),
      child: AbilityExpandableItem(component: ability),
    );
  }

  Widget _buildTreasurePreview(BuildContext context, model.Component treasure) {
    // Use the unified TreasureCard for all treasure types
    return TreasureCard(component: treasure);
  }

  /// Check if trait has immunity choice (type: "pick_one")
  bool _traitHasImmunityChoice(Map<String, dynamic> trait) {
    final increaseTotal = trait['increase_total'] as Map?;
    if (increaseTotal != null) {
      return increaseTotal['type'] == 'pick_one' &&
          increaseTotal['stat'] == 'immunity';
    }
    return _hasCanonicalImmunityChoice(trait['grants']);
  }

  bool _hasCanonicalImmunityChoice(Object? grants) {
    if (grants is List) {
      return grants.any(_isCanonicalImmunityChoiceGrant);
    }
    if (grants is Map) {
      if (grants['grants'] is List) {
        return _hasCanonicalImmunityChoice(grants['grants']);
      }
      return _isCanonicalImmunityChoiceGrant(grants);
    }
    return false;
  }

  bool _isCanonicalImmunityChoiceGrant(Object? grant) {
    if (grant is! Map) return false;
    final payload = grant['payload'];
    final stat = payload is Map ? payload['stat']?.toString() : null;
    return grant['kind'] == 'choice' &&
        grant['choice_type'] == 'damage_type' &&
        (stat == null || stat == 'immunity');
  }

  List<String> _immunityChoiceOptions(Map<String, dynamic> node) {
    final canonicalOptions = _canonicalImmunityChoiceOptions(node['grants']);
    return canonicalOptions.isEmpty ? _immunityTypes : canonicalOptions;
  }

  List<String> _canonicalImmunityChoiceOptions(Object? grants) {
    if (grants is List) {
      for (final grant in grants) {
        final options = _canonicalImmunityChoiceOptions(grant);
        if (options.isNotEmpty) return options;
      }
      return const [];
    }
    if (grants is Map) {
      if (grants['grants'] is List) {
        return _canonicalImmunityChoiceOptions(grants['grants']);
      }
      if (!_isCanonicalImmunityChoiceGrant(grants)) return const [];
      return _stringList(grants['options']);
    }
    return const [];
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// Get ability options for pick_ability_name traits
  List<String> _getAbilityOptions(Map<String, dynamic> trait) {
    final options = trait['pick_ability_name'] as List?;
    if (options == null) return [];
    return options.cast<String>();
  }

  static const List<String> _immunityTypes =
      StoryComplicationSectionText.immunityTypes;

  /// Get immunity types that should be excluded from a trait's dropdown.
  Set<String> _getExcludedImmunities(String currentTraitId,
      String complicationId, Map<String, String> choices) {
    final excluded = <String>{};

    // Exclude other traits' immunity choices (but not the current trait's choice)
    for (final entry in choices.entries) {
      if (entry.key == '${complicationId}_trait_$currentTraitId') continue;
      if (!entry.key.startsWith('${complicationId}_trait_')) continue;
      // Only add if it's likely an immunity type
      if (_immunityTypes.contains(entry.value.toLowerCase())) {
        excluded.add(entry.value.toLowerCase());
      }
    }

    return excluded;
  }

  Widget _buildImmunityDropdown({
    required String traitId,
    required String complicationId,
    required String? currentValue,
    List<String>? availableTypes,
    required Set<String> excludedValues,
  }) {
    const accent = Color(0xFFAB47BC); // Purple for immunity
    final choiceTypes = availableTypes == null || availableTypes.isEmpty
        ? _immunityTypes
        : availableTypes;
    // Filter out excluded immunity types (but keep current value if it was previously selected)
    final visibleTypes = choiceTypes.where((type) {
      if (type == currentValue) return true; // Always show current selection
      return !excludedValues.contains(type);
    }).toList();

    final choiceKey = '${complicationId}_trait_$traitId';

    return DropdownButtonFormField<String>(
      value: currentValue,
      dropdownColor: FormTheme.surface,
      decoration: CreatorTheme.dropdownDecoration(
        label: StoryComplicationSectionText.immunityDropdownLabel,
        accent: accent,
      ),
      style: TextStyle(color: FormTheme.textBright),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            StoryComplicationSectionText.immunityDropdownHint,
            style: TextStyle(color: FormTheme.textSecondary),
          ),
        ),
        ...visibleTypes.map(
          (type) => DropdownMenuItem<String>(
            value: type,
            child: Text(type[0].toUpperCase() + type.substring(1)),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          _updateChoice(choiceKey, value);
        }
      },
    );
  }

  Widget _buildAbilityDropdown({
    required WidgetRef ref,
    required String traitId,
    required String complicationId,
    required List<String> options,
    required String? currentValue,
    required HeroConflictIndex conflictIndex,
  }) {
    const accent = Color(0xFF26C6DA); // Cyan for abilities
    final choiceKey = '${complicationId}_trait_$traitId';
    final slotKey = 'story.complication:$choiceKey';
    final abilities =
        ref.watch(selectableComponentsByTypeProvider('ability')).valueOrNull ??
            const <model.Component>[];
    String? abilityId(String value) => abilities
        .firstWhereOrNull(
          (ability) =>
              ability.id == value ||
              ability.name.trim().toLowerCase() == value.trim().toLowerCase(),
        )
        ?.id;
    final visibleOptions = options.where((ability) {
      if (ability == currentValue) return true;
      final id = abilityId(ability);
      return id == null ||
          !_isClaimedByAnotherOwner(
            conflictIndex,
            HeroEntryTypes.ability,
            id,
            slotKey,
          );
    }).toList();
    final selectedId = currentValue == null ? null : abilityId(currentValue);
    final isConflict = selectedId != null &&
        _isClaimedByAnotherOwner(
          conflictIndex,
          HeroEntryTypes.ability,
          selectedId,
          slotKey,
        );

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      dropdownColor: FormTheme.surface,
      decoration: CreatorTheme.dropdownDecoration(
        label: StoryComplicationSectionText.abilityDropdownLabel,
        accent: accent,
      ).copyWith(
        errorText: isConflict
            ? StoryComplicationSectionText.duplicateChoiceLabel
            : null,
      ),
      style: TextStyle(color: FormTheme.textBright),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            StoryComplicationSectionText.abilityDropdownHint,
            style: TextStyle(color: FormTheme.textSecondary),
          ),
        ),
        ...visibleOptions.map(
          (ability) => DropdownMenuItem<String>(
            value: ability,
            child: Text(ability),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          _updateChoice(choiceKey, value);
        }
      },
    );
  }
}
