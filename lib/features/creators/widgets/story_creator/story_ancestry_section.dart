import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icon_data.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_ancestry_section_text.dart';
import '../../../../core/storage/hero_storage_contract.dart';
import '../../../hero_builder/domain/hero_claim.dart';
import '../../../hero_builder/domain/hero_conflict_index.dart';

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
  final accentColor = accent ?? CreatorTheme.ancestryAccent;
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
                      autofocus: false,
                      style: TextStyle(color: FormTheme.textBright),
                      decoration: InputDecoration(
                        hintText: StoryAncestrySectionText.searchHint,
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
                                  StoryAncestrySectionText.noMatchesFound,
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
                      child: Text(StoryAncestrySectionText.cancel),
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

class StoryAncestrySection extends ConsumerWidget {
  const StoryAncestrySection({
    super.key,
    required this.selectedAncestryId,
    required this.selectedTraitIds,
    required this.traitChoices,
    this.skillConflictIndex = HeroConflictIndex.empty,
    this.abilityConflictIndex = HeroConflictIndex.empty,
    this.traitConflictIndex = HeroConflictIndex.empty,
    this.ancestryConflictIndex = HeroConflictIndex.empty,
    required this.onAncestryChanged,
    required this.onTraitSelectionChanged,
    required this.onTraitChoiceChanged,
    required this.onDirty,
  });

  final String? selectedAncestryId;
  final Set<String> selectedTraitIds;
  final Map<String, String> traitChoices;
  final HeroConflictIndex skillConflictIndex;
  final HeroConflictIndex abilityConflictIndex;
  final HeroConflictIndex traitConflictIndex;
  final HeroConflictIndex ancestryConflictIndex;
  final ValueChanged<String?> onAncestryChanged;
  final void Function(String traitId, bool isSelected) onTraitSelectionChanged;
  final void Function(String traitOrSignatureId, String choiceValue)
      onTraitChoiceChanged;
  final VoidCallback onDirty;

  static const _accent = CreatorTheme.ancestryAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestriesAsync = ref.watch(componentsByTypeProvider('ancestry'));
    final ancestryTraitsAsync =
        ref.watch(componentsByTypeProvider('ancestry_trait'));
    final skillsAsync = ref.watch(componentsByTypeProvider('skill'));
    final abilitiesAsync = ref.watch(componentsByTypeProvider('ability'));

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        children: [
          CreatorTheme.sectionHeader(
            title: StoryAncestrySectionText.sectionTitle,
            subtitle: StoryAncestrySectionText.sectionSubtitle,
            appIcon: StoryIcons.ancestry,
            accent: _accent,
          ),
          Padding(
            padding: CreatorTheme.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ancestriesAsync.when(
                  loading: () => CreatorTheme.loadingIndicator(_accent),
                  error: (e, _) => CreatorTheme.errorMessage(
                    '${StoryAncestrySectionText.errorPrefix}$e',
                    accent: _accent,
                  ),
                  data: (ancestries) => _buildAncestryDropdown(
                    context,
                    ancestries,
                    ancestryTraitsAsync,
                    skillsAsync,
                    abilitiesAsync,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAncestryDropdown(
    BuildContext context,
    List<model.Component> ancestries,
    AsyncValue<List<model.Component>> traitsAsync,
    AsyncValue<List<model.Component>> skillsAsync,
    AsyncValue<List<model.Component>> abilitiesAsync,
  ) {
    ancestries = List.of(ancestries)..sort((a, b) => a.name.compareTo(b.name));
    final selectedAncestry = ancestries.firstWhere(
      (a) => a.id == selectedAncestryId,
      orElse: () => ancestries.isNotEmpty
          ? ancestries.first
          : const model.Component(
              id: '',
              type: 'ancestry',
              name: StoryAncestrySectionText.unknownAncestryName,
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () async {
            final options = [
              _SearchOption<String?>(
                label: StoryAncestrySectionText.chooseAncestryOption,
                value: null,
              ),
              ...ancestries
                  .where(
                    (ancestry) => !ancestryConflictIndex.isClaimed(
                      HeroEntryKey(
                        entryType: HeroEntryTypes.ancestry,
                        canonicalEntryId: ancestry.id,
                      ),
                      ignoredDraftSlotKey: 'story.ancestry:selection#0',
                    ),
                  )
                  .map(
                    (a) => _SearchOption<String?>(
                      label: a.name,
                      value: a.id,
                    ),
                  ),
            ];
            final result = await _showSearchablePicker<String?>(
              context: context,
              title: StoryAncestrySectionText.selectAncestryTitle,
              options: options,
              selected: selectedAncestryId,
              accent: _accent,
              icon: StoryIcons.ancestry,
            );
            if (result == null) return;
            onAncestryChanged(result.value);
            onDirty();
          },
          borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
          child: InputDecorator(
            decoration: CreatorTheme.dropdownDecoration(
              label: StoryAncestrySectionText.chooseAncestryLabel,
              accent: _accent,
            ).copyWith(
              suffixIcon: const Icon(Icons.search, color: Colors.white70),
            ),
            child: Text(
              selectedAncestryId != null
                  ? selectedAncestry.name
                  : StoryAncestrySectionText.chooseAncestryOption,
              style: TextStyle(
                fontSize: 16,
                color: selectedAncestryId != null
                    ? FormTheme.textBright
                    : FormTheme.textMuted,
              ),
            ),
          ),
        ),
        if (selectedAncestryId != null) ...[
          const SizedBox(height: 16),
          traitsAsync.when(
            loading: () => CreatorTheme.loadingIndicator(_accent),
            error: (e, _) => CreatorTheme.errorMessage(
              '${StoryAncestrySectionText.errorLoadingTraitsPrefix}$e',
              accent: _accent,
            ),
            data: (traitsComps) {
              final traitsForSelected = traitsComps.firstWhere(
                (t) => t.data['ancestry_id'] == selectedAncestryId,
                orElse: () => traitsComps.firstWhere(
                  (t) => t.data['ancestry_id'] == selectedAncestry.id,
                  orElse: () => traitsComps.isNotEmpty
                      ? traitsComps.first
                      : const model.Component(
                          id: '', type: 'ancestry_trait', name: ''),
                ),
              );
              return _AncestryDetails(
                ancestry: selectedAncestry,
                traitsComp: traitsForSelected,
                allAncestries: ancestries,
                allAncestryTraits: traitsComps,
                allSkills: skillsAsync.valueOrNull ?? const <model.Component>[],
                allAbilities:
                    abilitiesAsync.valueOrNull ?? const <model.Component>[],
                skillConflictIndex: skillConflictIndex,
                abilityConflictIndex: abilityConflictIndex,
                traitConflictIndex: traitConflictIndex,
                selectedTraitIds: selectedTraitIds,
                traitChoices: traitChoices,
                onTraitSelectionChanged: onTraitSelectionChanged,
                onTraitChoiceChanged: onTraitChoiceChanged,
                onDirty: onDirty,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _AncestryDetails extends StatelessWidget {
  const _AncestryDetails({
    required this.ancestry,
    required this.traitsComp,
    required this.allAncestries,
    required this.allAncestryTraits,
    required this.allSkills,
    required this.allAbilities,
    required this.skillConflictIndex,
    required this.abilityConflictIndex,
    required this.traitConflictIndex,
    required this.selectedTraitIds,
    required this.traitChoices,
    required this.onTraitSelectionChanged,
    required this.onTraitChoiceChanged,
    required this.onDirty,
  });

  final model.Component ancestry;
  final model.Component traitsComp;
  final List<model.Component> allAncestries;
  final List<model.Component> allAncestryTraits;
  final List<model.Component> allSkills;
  final List<model.Component> allAbilities;
  final HeroConflictIndex skillConflictIndex;
  final HeroConflictIndex abilityConflictIndex;
  final HeroConflictIndex traitConflictIndex;
  final Set<String> selectedTraitIds;
  final Map<String, String> traitChoices;
  final void Function(String traitId, bool isSelected) onTraitSelectionChanged;
  final void Function(String traitOrSignatureId, String choiceValue)
      onTraitChoiceChanged;
  final VoidCallback onDirty;

  static const _accent = CreatorTheme.ancestryAccent;

  /// Get the chosen former ancestry ID for Revenant
  String? get _formerAncestryId => traitChoices['former_life_ancestry'];

  @override
  Widget build(BuildContext context) {
    final data = ancestry.data;
    final shortDesc = (data['short_description'] as String?) ?? '';
    final height = (data['height'] as Map?)?.cast<String, dynamic>();
    final weight = (data['weight'] as Map?)?.cast<String, dynamic>();
    final life = (data['life_expectancy'] as Map?)?.cast<String, dynamic>();
    final size = data['size'];
    final speed = data['speed'];
    final stability = data['stability'];

    // Handle signature as either a Map (single) or List (multiple, e.g., Revenant)
    final signatureRaw = traitsComp.data['signature'];
    final List<Map<String, dynamic>> signatures;
    if (signatureRaw is List) {
      signatures = signatureRaw
          .cast<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    } else if (signatureRaw is Map) {
      signatures = [signatureRaw.cast<String, dynamic>()];
    } else {
      signatures = [];
    }

    final points = (traitsComp.data['points'] as int?) ?? 0;
    final traitsList =
        (traitsComp.data['traits'] as List?)?.cast<Map>() ?? const <Map>[];

    final spent = selectedTraitIds.fold<int>(0, (sum, id) {
      final match = traitsList.firstWhere(
        (t) => (t['id'] ?? t['name']).toString() == id,
        orElse: () => const {},
      );
      return sum + (match.cast<String, dynamic>()['cost'] as int? ?? 0);
    });
    final remaining = points - spent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: CreatorTheme.subSectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shortDesc.isNotEmpty) ...[
            Text(shortDesc,
                style: TextStyle(color: FormTheme.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (height != null)
                _statChip(
                  '${StoryAncestrySectionText.heightChipPrefix}${height['min']}–${height['max']}',
                  const Color(0xFF42A5F5),
                ),
              if (weight != null)
                _statChip(
                  '${StoryAncestrySectionText.weightChipPrefix}${weight['min']}–${weight['max']}',
                  const Color(0xFF66BB6A),
                ),
              if (life != null)
                _statChip(
                  '${StoryAncestrySectionText.lifespanChipPrefix}${life['min']}–${life['max']}',
                  const Color(0xFFAB47BC),
                ),
              if (size != null)
                _statChip(
                  '${StoryAncestrySectionText.sizeChipPrefix}$size',
                  const Color(0xFFFFB74D),
                ),
              if (speed != null)
                _statChip(
                  '${StoryAncestrySectionText.speedChipPrefix}$speed',
                  const Color(0xFF26C6DA),
                ),
              if (stability != null)
                _statChip(
                  '${StoryAncestrySectionText.stabilityChipPrefix}$stability',
                  const Color(0xFFEF5350),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Render all signatures (supports both single and multiple like Revenant)
          ...signatures
              .map((signature) => _buildSignatureCard(context, signature)),
          // Points display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: FormTheme.surface,
            ),
            child: Row(
              children: [
                _pointsBadge(
                  '${StoryAncestrySectionText.pointsLabelPrefix}$points',
                  const Color(0xFF5C6BC0),
                ),
                const SizedBox(width: 12),
                _pointsBadge(
                  '${StoryAncestrySectionText.remainingLabelPrefix}$remaining',
                  remaining >= 0
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...traitsList.map((t) {
            final traitData = t.cast<String, dynamic>();
            final id = (traitData['id'] ?? traitData['name']).toString();
            final name = (traitData['name'] ?? id).toString();
            final desc = (traitData['description'] ?? '').toString();
            final cost = (traitData['cost'] as int?) ?? 0;
            final selected = selectedTraitIds.contains(id);
            final isDuplicate = traitConflictIndex.isClaimed(
              HeroEntryKey(
                entryType: HeroEntryTypes.ancestryTrait,
                canonicalEntryId: id,
              ),
              ignoredDraftSlotKey: 'story.ancestry:trait:$id',
            );
            final canSelect =
                selected || (!isDuplicate && remaining - cost >= 0);
            final isUnavailable = !selected && !canSelect;

            // Check if this trait has choices
            final hasImmunityChoice = _traitHasImmunityChoice(traitData);
            final abilityOptions = _getAbilityOptions(traitData);

            return Opacity(
              opacity: isUnavailable ? 0.45 : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? _accent.withValues(alpha: 0.1)
                      : isUnavailable
                          ? const Color(0xFF1A1A1A)
                          : FormTheme.surface,
                  border: Border.all(
                    color: selected
                        ? _accent.withValues(alpha: 0.4)
                        : isUnavailable
                            ? FormTheme.borderDim
                            : FormTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUnavailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FormTheme.surfaceMuted,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(9)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.block,
                                size: 14, color: FormTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              isDuplicate
                                  ? StoryAncestrySectionText.duplicateTrait
                                  : StoryAncestrySectionText.notEnoughPoints,
                              style: TextStyle(
                                fontSize: 11,
                                color: FormTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    CheckboxListTile(
                      value: selected,
                      onChanged: canSelect
                          ? (value) {
                              if (value == null) return;
                              onTraitSelectionChanged(id, value);
                              onDirty();
                            }
                          : null,
                      title: Text(
                        name,
                        style: TextStyle(
                          color: selected
                              ? _accent
                              : isUnavailable
                                  ? FormTheme.borderLight
                                  : FormTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          desc,
                          style: TextStyle(
                            color: isUnavailable
                                ? FormTheme.borderLight
                                : FormTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      isThreeLine: true,
                      secondary: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.red.withValues(alpha: 0.15)
                              : const Color(0xFF5C6BC0).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnavailable
                                ? Colors.red.withValues(alpha: 0.3)
                                : const Color(0xFF5C6BC0)
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$cost',
                          style: TextStyle(
                            color: isUnavailable
                                ? Colors.red.shade300
                                : const Color(0xFF7986CB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      checkColor: FormTheme.textBright,
                      activeColor: _accent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    // Show immunity dropdown for traits like Prismatic Scales
                    if (selected && hasImmunityChoice) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                        child: _buildImmunityDropdown(
                          context: context,
                          signatureId: id,
                          currentValue: traitChoices[id],
                          availableTypes: _immunityChoiceOptions(traitData),
                          // Exclude signature immunity and other trait immunity choices
                          excludedValues:
                              _getExcludedImmunities(id, traitChoices),
                          onChanged: (value) {
                            if (value != null) {
                              onTraitChoiceChanged(id, value);
                              onDirty();
                            }
                          },
                        ),
                      ),
                    ],
                    // Show ability dropdown for traits like Psionic Gift
                    if (selected && abilityOptions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                        child: _buildAbilityDropdown(
                          context: context,
                          traitId: id,
                          options: abilityOptions,
                          currentValue: traitChoices[id],
                          onChanged: (value) {
                            if (value != null) {
                              onTraitChoiceChanged(id, value);
                              onDirty();
                            }
                          },
                        ),
                      ),
                    ],
                    // Show Previous Life trait picker for Revenant
                    if (selected && _isPreviousLifeTrait(traitData)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                        child: _buildPreviousLifeTraitPicker(
                          context: context,
                          traitId: id,
                          cost: _getPreviousLifePointCost(traitData),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _pointsBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  /// Build a signature card widget for a single signature trait
  Widget _buildSignatureCard(
      BuildContext context, Map<String, dynamic> signature) {
    final name = (signature['name'] as String?) ?? '';
    final description = (signature['description'] as String?) ?? '';
    final isFormerLife = name == 'Former Life';
    final signatureSkillKey = _signatureSkillChoiceKey(signature);
    final currentSignatureSkillId =
        traitChoices[signatureSkillKey] ?? traitChoices['signature_skill'];
    final signatureSkillOptions = _skillChoiceOptions(signature['grants'],
        choiceId: signatureSkillKey, currentValue: currentSignatureSkillId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _accent.withValues(alpha: 0.1),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(AbilityIcons.feature, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${StoryAncestrySectionText.signatureLabelPrefix}$name',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  height: 1.4,
                  color: FormTheme.textSecondary,
                ),
              ),
            ],
            // Show ancestry picker for "Former Life" (Revenant)
            if (isFormerLife) ...[
              const SizedBox(height: 12),
              _buildFormerAncestryPicker(context),
            ],
            if (signatureSkillOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSkillDropdown(
                context: context,
                choiceId: signatureSkillKey,
                options: signatureSkillOptions,
                currentValue: currentSignatureSkillId,
                onChanged: (value) {
                  if (value != null) {
                    onTraitChoiceChanged(signatureSkillKey, value);
                    onDirty();
                  }
                },
              ),
            ],
            // Show dropdown for signature immunity choice (e.g., Wyrmplate)
            if (_signatureHasImmunityChoice(signature)) ...[
              const SizedBox(height: 12),
              _buildImmunityDropdown(
                context: context,
                signatureId: 'signature_immunity',
                currentValue: traitChoices['signature_immunity'],
                availableTypes: _immunityChoiceOptions(signature),
                excludedValues: const {}, // Signature has no exclusions
                onChanged: (value) {
                  if (value != null) {
                    onTraitChoiceChanged('signature_immunity', value);
                    onDirty();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the former ancestry picker for Revenant's "Former Life" signature
  Widget _buildFormerAncestryPicker(BuildContext context) {
    // Filter out Revenant from the list of choosable ancestries
    final eligibleAncestries = allAncestries
        .where((a) => a.id != 'ancestry_revenant')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selectedAncestry = eligibleAncestries.firstWhere(
      (a) => a.id == _formerAncestryId,
      orElse: () => const model.Component(id: '', type: 'ancestry', name: ''),
    );

    const formerLifeAccent = Color(0xFF7E57C2);

    return InkWell(
      onTap: () async {
        final options = [
          _SearchOption<String?>(
            label: StoryAncestrySectionText.formerLifeHint,
            value: null,
          ),
          ...eligibleAncestries.map(
            (a) => _SearchOption<String?>(
              label: a.name,
              value: a.id,
              subtitle: (a.data['short_description'] as String?)?.substring(
                0,
                ((a.data['short_description'] as String?)?.length ?? 0)
                    .clamp(0, 80),
              ),
            ),
          ),
        ];

        final result = await _showSearchablePicker<String?>(
          context: context,
          title: StoryAncestrySectionText.selectFormerAncestryTitle,
          options: options,
          selected: _formerAncestryId,
          accent: formerLifeAccent,
          icon: StoryIcons.ancestry,
        );

        if (result != null) {
          onTraitChoiceChanged('former_life_ancestry', result.value ?? '');
          onDirty();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: CreatorTheme.dropdownDecoration(
          label: StoryAncestrySectionText.formerLifeLabel,
          accent: formerLifeAccent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formerAncestryId != null && selectedAncestry.id.isNotEmpty
                  ? selectedAncestry.name
                  : StoryAncestrySectionText.formerLifeHint,
              style: TextStyle(
                color:
                    _formerAncestryId != null && selectedAncestry.id.isNotEmpty
                        ? FormTheme.textBright
                        : FormTheme.textMuted,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: FormTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Check if a trait is a "Previous Life" trait (Revenant-specific)
  bool _isPreviousLifeTrait(Map<String, dynamic> trait) {
    final name = (trait['name'] as String?) ?? '';
    return name.startsWith('Previous Life:');
  }

  /// Get the point cost that a "Previous Life" trait allows the user to pick
  int _getPreviousLifePointCost(Map<String, dynamic> trait) {
    final name = (trait['name'] as String?) ?? '';
    if (name.contains('1 Point')) return 1;
    if (name.contains('2 Point')) return 2;
    return 0;
  }

  /// Get traits from the former ancestry that match the given cost
  List<Map<String, dynamic>> _getFormerAncestryTraits(int cost) {
    if (_formerAncestryId == null) return [];

    // Find the traits component for the former ancestry
    final formerTraitsComp = allAncestryTraits.firstWhere(
      (t) => t.data['ancestry_id'] == _formerAncestryId,
      orElse: () =>
          const model.Component(id: '', type: 'ancestry_trait', name: ''),
    );

    if (formerTraitsComp.id.isEmpty) return [];

    final traitsList =
        (formerTraitsComp.data['traits'] as List?)?.cast<Map>() ?? [];
    return traitsList
        .map((t) => t.cast<String, dynamic>())
        .where((t) => (t['cost'] as int?) == cost)
        .toList();
  }

  /// Get the currently selected trait IDs for all "Previous Life" traits to exclude
  /// from other "Previous Life" trait pickers (to prevent duplicate selection)
  Set<String> _getAlreadyChosenPreviousLifeTraitIds(String excludeTraitId) {
    final chosen = <String>{};
    for (final entry in traitChoices.entries) {
      if (entry.key.startsWith('revenant_previous_life') &&
          entry.key != excludeTraitId) {
        if (entry.value.isNotEmpty) {
          chosen.add(entry.value);
        }
      }
    }
    return chosen;
  }

  /// Build a picker for selecting a trait from the former ancestry
  Widget _buildPreviousLifeTraitPicker({
    required BuildContext context,
    required String traitId,
    required int cost,
  }) {
    final currentChoiceId = traitChoices[traitId];
    final availableTraits = _getFormerAncestryTraits(cost);
    final alreadyChosen = _getAlreadyChosenPreviousLifeTraitIds(traitId);

    // Filter out already chosen traits
    final filteredTraits = availableTraits.where((t) {
      final id = (t['id'] ?? t['name']).toString();
      // Keep the current selection visible, filter out other already-chosen ones
      return id == currentChoiceId || !alreadyChosen.contains(id);
    }).toList();

    // Find the current selected trait
    final selectedTrait = filteredTraits.firstWhere(
      (t) => (t['id'] ?? t['name']).toString() == currentChoiceId,
      orElse: () => <String, dynamic>{},
    );
    final selectedTraitName = selectedTrait.isNotEmpty
        ? (selectedTrait['name'] as String?) ?? ''
        : '';

    const previousLifeAccent = Color(0xFF9575CD);

    if (_formerAncestryId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: FormTheme.surfaceMuted,
          border: Border.all(color: FormTheme.border),
        ),
        child: Text(
          StoryAncestrySectionText.chooseFormerAncestryFirst,
          style: TextStyle(
            color: FormTheme.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () async {
            if (filteredTraits.isEmpty) return;

            final options = [
              _SearchOption<String?>(
                label: StoryAncestrySectionText.previousLifeTraitHint,
                value: null,
              ),
              ...filteredTraits.map(
                (t) {
                  final id = (t['id'] ?? t['name']).toString();
                  final name = (t['name'] as String?) ?? id;
                  final desc = (t['description'] as String?) ?? '';
                  return _SearchOption<String?>(
                    label: name,
                    value: id,
                    subtitle: desc.length > 100
                        ? '${desc.substring(0, 100)}...'
                        : desc,
                  );
                },
              ),
            ];

            final result = await _showSearchablePicker<String?>(
              context: context,
              title: StoryAncestrySectionText.selectPreviousLifeTraitTitle,
              options: options,
              selected: currentChoiceId,
              accent: previousLifeAccent,
              icon: AbilityIcons.ability,
            );

            if (result != null) {
              onTraitChoiceChanged(traitId, result.value ?? '');
              onDirty();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: CreatorTheme.dropdownDecoration(
              label: StoryAncestrySectionText.previousLifeTraitLabel,
              accent: previousLifeAccent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedTraitName.isNotEmpty
                        ? selectedTraitName
                        : filteredTraits.isEmpty
                            ? StoryAncestrySectionText.noTraitsAvailable
                            : StoryAncestrySectionText.previousLifeTraitHint,
                    style: TextStyle(
                      color: selectedTraitName.isNotEmpty
                          ? FormTheme.textBright
                          : FormTheme.textMuted,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: FormTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Show the selected trait's description
        if (selectedTrait.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: previousLifeAccent.withValues(alpha: 0.08),
              border:
                  Border.all(color: previousLifeAccent.withValues(alpha: 0.2)),
            ),
            child: Text(
              (selectedTrait['description'] as String?) ?? '',
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          // Show immunity choice for the selected Previous Life trait (e.g., Prismatic Scales)
          if (_traitHasImmunityChoice(selectedTrait)) ...[
            const SizedBox(height: 8),
            _buildImmunityDropdown(
              context: context,
              signatureId: '${traitId}_immunity',
              currentValue: traitChoices['${traitId}_immunity'],
              availableTypes: _immunityChoiceOptions(selectedTrait),
              // Exclude signature immunity and other trait immunity choices
              excludedValues:
                  _getExcludedImmunities('${traitId}_immunity', traitChoices),
              onChanged: (value) {
                if (value != null) {
                  onTraitChoiceChanged('${traitId}_immunity', value);
                  onDirty();
                }
              },
            ),
          ],
          // Show ability choice for the selected Previous Life trait
          if (_getAbilityOptions(selectedTrait).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildAbilityDropdown(
              context: context,
              traitId: '${traitId}_ability',
              options: _getAbilityOptions(selectedTrait),
              currentValue: traitChoices['${traitId}_ability'],
              onChanged: (value) {
                if (value != null) {
                  onTraitChoiceChanged('${traitId}_ability', value);
                  onDirty();
                }
              },
            ),
          ],
        ],
      ],
    );
  }

  /// Check if signature has immunity choice (type: "pick_one")
  bool _signatureHasImmunityChoice(Map<String, dynamic> signature) {
    final increaseTotal = signature['increase_total'];
    if (increaseTotal is Map) {
      return increaseTotal['type'] == 'pick_one' &&
          increaseTotal['stat'] == 'immunity';
    } else if (increaseTotal is List) {
      return increaseTotal.any((entry) =>
          entry is Map &&
          entry['type'] == 'pick_one' &&
          entry['stat'] == 'immunity');
    }
    return _hasCanonicalImmunityChoice(signature['grants']);
  }

  /// Check if trait has immunity choice
  bool _traitHasImmunityChoice(Map<String, dynamic> trait) {
    final increaseTotal = trait['increase_total'];
    if (increaseTotal is Map) {
      return increaseTotal['type'] == 'pick_one' &&
          increaseTotal['stat'] == 'immunity';
    } else if (increaseTotal is List) {
      return increaseTotal.any((entry) =>
          entry is Map &&
          entry['type'] == 'pick_one' &&
          entry['stat'] == 'immunity');
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

  String _signatureSkillChoiceKey(Map<String, dynamic> signature) {
    final grant = _canonicalSkillChoiceGrant(signature['grants']);
    final choiceKey = grant?['choice_key']?.toString().trim();
    if (choiceKey != null && choiceKey.isNotEmpty) return choiceKey;
    return 'signature_skill';
  }

  Map<String, dynamic>? _canonicalSkillChoiceGrant(Object? grants) {
    if (grants is List) {
      for (final grant in grants) {
        final match = _canonicalSkillChoiceGrant(grant);
        if (match != null) return match;
      }
      return null;
    }
    if (grants is Map) {
      if (grants['grants'] is List) {
        return _canonicalSkillChoiceGrant(grants['grants']);
      }
      if (_isCanonicalSkillChoiceGrant(grants)) {
        return Map<String, dynamic>.from(grants);
      }
    }
    return null;
  }

  bool _isCanonicalSkillChoiceGrant(Object? grant) {
    if (grant is! Map) return false;
    final entryType = grant['entry_type']?.toString();
    return grant['kind'] == 'choice' &&
        grant['choice_type'] == 'skill' &&
        (entryType == null || entryType == 'skill');
  }

  List<model.Component> _skillChoiceOptions(
    Object? grants, {
    required String choiceId,
    String? currentValue,
  }) {
    final grant = _canonicalSkillChoiceGrant(grants);
    if (grant == null || allSkills.isEmpty) return const <model.Component>[];

    final groups = _stringList(grant['groups'])
        .map((group) => group.toLowerCase())
        .toSet();
    final explicitOptions = _stringList(grant['options'])
        .map((option) => option.toLowerCase())
        .toSet();

    final matches = <model.Component>[];
    for (final skill in allSkills) {
      final group = skill.data['group']?.toString().toLowerCase();
      final skillId = skill.id.toLowerCase();
      final skillName = skill.name.toLowerCase();
      final matchesGroup = group != null && groups.contains(group);
      final matchesExplicit = explicitOptions.contains(skillId) ||
          explicitOptions.contains(skillName);
      final includeAll = groups.isEmpty && explicitOptions.isEmpty;
      if (matchesGroup || matchesExplicit || includeAll) {
        matches.add(skill);
      }
    }

    if (currentValue != null && currentValue.isNotEmpty) {
      final currentSkill = allSkills.cast<model.Component?>().firstWhere(
            (skill) => skill?.id == currentValue,
            orElse: () => null,
          );
      if (currentSkill != null &&
          !matches.any((skill) => skill.id == currentSkill.id)) {
        matches.add(currentSkill);
      }
    }

    final slotKey = 'story.ancestry:$choiceId';
    final allowedMatches = matches.where((skill) {
      final claimedByAnotherSlot = skillConflictIndex.isClaimed(
        HeroEntryKey(
          entryType: HeroEntryTypes.skill,
          canonicalEntryId: skill.id,
        ),
        ignoredDraftSlotKey: slotKey,
      );
      return !claimedByAnotherSlot;
    }).toList();
    allowedMatches.sort((a, b) => a.name.compareTo(b.name));
    return allowedMatches;
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

  /// Get immunity types that should be excluded from a trait's dropdown.
  /// Excludes signature immunity and other traits' immunity choices.
  Set<String> _getExcludedImmunities(
      String currentTraitId, Map<String, String> choices) {
    final excluded = <String>{};

    // Exclude signature immunity choice
    final signatureImmunity = choices['signature_immunity'];
    if (signatureImmunity != null && signatureImmunity.isNotEmpty) {
      excluded.add(signatureImmunity);
    }

    // Exclude other traits' immunity choices (but not the current trait's choice)
    for (final entry in choices.entries) {
      if (entry.key == currentTraitId) continue;
      if (entry.key == 'signature_immunity') continue; // Already handled
      // Only add if it's likely an immunity type
      if (_immunityTypes.contains(entry.value.toLowerCase())) {
        excluded.add(entry.value.toLowerCase());
      }
    }

    return excluded;
  }

  static const List<String> _immunityTypes =
      StoryAncestrySectionText.immunityTypes;

  Widget _buildImmunityDropdown({
    required BuildContext context,
    required String signatureId,
    required String? currentValue,
    List<String>? availableTypes,
    required Set<String> excludedValues,
    required ValueChanged<String?> onChanged,
  }) {
    final choiceTypes = availableTypes == null || availableTypes.isEmpty
        ? _immunityTypes
        : availableTypes;
    // Filter out excluded immunity types (but keep current value if it was previously selected)
    final visibleTypes = choiceTypes.where((type) {
      if (type == currentValue) return true; // Always show current selection
      return !excludedValues.contains(type);
    }).toList();

    const immunityAccent = Color(0xFFAB47BC);

    return InkWell(
      onTap: () async {
        final options = [
          _SearchOption<String?>(
            label: StoryAncestrySectionText.immunityDropdownHint,
            value: null,
          ),
          ...visibleTypes.map(
            (type) => _SearchOption<String?>(
              label: type[0].toUpperCase() + type.substring(1),
              value: type,
            ),
          ),
        ];

        final result = await _showSearchablePicker<String?>(
          context: context,
          title: StoryAncestrySectionText.selectImmunityTitle,
          options: options,
          selected: currentValue,
          accent: immunityAccent,
          icon: CombatIcons.damageResistances,
        );

        if (result != null) {
          onChanged(result.value);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: CreatorTheme.dropdownDecoration(
          label: StoryAncestrySectionText.immunityDropdownLabel,
          accent: immunityAccent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentValue != null
                  ? currentValue[0].toUpperCase() + currentValue.substring(1)
                  : StoryAncestrySectionText.immunityDropdownHint,
              style: TextStyle(
                color: currentValue != null
                    ? FormTheme.textBright
                    : FormTheme.textMuted,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: FormTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbilityDropdown({
    required BuildContext context,
    required String traitId,
    required List<String> options,
    required String? currentValue,
    required ValueChanged<String?> onChanged,
  }) {
    const abilityAccent = Color(0xFF26C6DA);
    final slotKey = 'story.ancestry:$traitId';
    String? abilityId(String value) {
      for (final ability in allAbilities) {
        if (ability.id == value ||
            ability.name.trim().toLowerCase() == value.trim().toLowerCase()) {
          return ability.id;
        }
      }
      return null;
    }

    final visibleOptions = options.where((ability) {
      if (ability == currentValue) return true;
      final id = abilityId(ability);
      return id == null ||
          !abilityConflictIndex.isClaimed(
            HeroEntryKey(
              entryType: HeroEntryTypes.ability,
              canonicalEntryId: id,
            ),
            ignoredDraftSlotKey: slotKey,
          );
    }).toList();

    return InkWell(
      onTap: () async {
        final pickerOptions = [
          _SearchOption<String?>(
            label: StoryAncestrySectionText.abilityDropdownHint,
            value: null,
          ),
          ...visibleOptions.map(
            (ability) => _SearchOption<String?>(
              label: ability,
              value: ability,
            ),
          ),
        ];

        final result = await _showSearchablePicker<String?>(
          context: context,
          title: StoryAncestrySectionText.selectAbilityTitle,
          options: pickerOptions,
          selected: currentValue,
          accent: abilityAccent,
          icon: AbilityIcons.ability,
        );

        if (result != null) {
          onChanged(result.value);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: CreatorTheme.dropdownDecoration(
          label: StoryAncestrySectionText.abilityDropdownLabel,
          accent: abilityAccent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentValue ?? StoryAncestrySectionText.abilityDropdownHint,
              style: TextStyle(
                color: currentValue != null
                    ? FormTheme.textBright
                    : FormTheme.textMuted,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: FormTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillDropdown({
    required BuildContext context,
    required String choiceId,
    required List<model.Component> options,
    required String? currentValue,
    required ValueChanged<String?> onChanged,
  }) {
    const skillAccent = Color(0xFF5C6BC0);
    final skillIcon = SkillGroupIcons.fromGroup(
      options.first.data['group']?.toString() ?? '',
    );

    return InkWell(
      onTap: () async {
        final pickerOptions = [
          _SearchOption<String?>(
            label: StoryAncestrySectionText.skillDropdownHint,
            value: null,
          ),
          ...options.map(
            (skill) => _SearchOption<String?>(
              label: skill.name,
              value: skill.id,
              subtitle: skill.data['group']?.toString(),
            ),
          ),
        ];

        final result = await _showSearchablePicker<String?>(
          context: context,
          title: StoryAncestrySectionText.selectSkillTitle,
          options: pickerOptions,
          selected: currentValue,
          accent: skillAccent,
          icon: skillIcon,
        );

        if (result != null) {
          onChanged(result.value);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: CreatorTheme.dropdownDecoration(
          label: StoryAncestrySectionText.skillDropdownLabel,
          accent: skillAccent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                options
                        .cast<model.Component?>()
                        .firstWhere(
                          (skill) => skill?.id == currentValue,
                          orElse: () => null,
                        )
                        ?.name ??
                    StoryAncestrySectionText.skillDropdownHint,
                style: TextStyle(
                  color: currentValue != null
                      ? FormTheme.textBright
                      : FormTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: FormTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
