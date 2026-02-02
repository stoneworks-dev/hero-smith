import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_ancestry_section_text.dart';

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
  IconData? icon,
}) {
  final accentColor = accent ?? CreatorTheme.ancestryAccent;
  final effectiveIcon = icon ?? Icons.search;
  
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
                          child: Icon(effectiveIcon, color: accentColor, size: 20),
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
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: StoryAncestrySectionText.searchHint,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade700),
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
                                  color: Colors.grey.shade600,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  StoryAncestrySectionText.noMatchesFound,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
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
                                      ? Colors.grey.shade800.withValues(alpha: 0.4)
                                      : isSelected
                                          ? accentColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accentColor.withValues(alpha: 0.4),
                                        )
                                      : isNoneOption
                                          ? Border.all(
                                              color: Colors.grey.shade700,
                                            )
                                          : null,
                                ),
                                child: ListTile(
                                  leading: isNoneOption
                                      ? Icon(Icons.remove_circle_outline,
                                          size: 20, color: Colors.grey.shade500)
                                      : null,
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isNoneOption
                                          ? Colors.grey.shade400
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
                                            color: Colors.grey.shade500,
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
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                      ),
                      child: const Text('Cancel'),
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
    required this.onAncestryChanged,
    required this.onTraitSelectionChanged,
    required this.onTraitChoiceChanged,
    required this.onDirty,
  });

  final String? selectedAncestryId;
  final Set<String> selectedTraitIds;
  final Map<String, String> traitChoices;
  final ValueChanged<String?> onAncestryChanged;
  final void Function(String traitId, bool isSelected) onTraitSelectionChanged;
  final void Function(String traitOrSignatureId, String choiceValue) onTraitChoiceChanged;
  final VoidCallback onDirty;

  static const _accent = CreatorTheme.ancestryAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestriesAsync = ref.watch(componentsByTypeProvider('ancestry'));
    final ancestryTraitsAsync = ref.watch(componentsByTypeProvider('ancestry_trait'));

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        children: [
          CreatorTheme.sectionHeader(
            title: StoryAncestrySectionText.sectionTitle,
            subtitle: StoryAncestrySectionText.sectionSubtitle,
            icon: Icons.family_restroom,
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
              ...ancestries.map(
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
              icon: Icons.family_restroom,
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
                    ? Colors.white
                    : Colors.grey.shade500,
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
    required this.selectedTraitIds,
    required this.traitChoices,
    required this.onTraitSelectionChanged,
    required this.onTraitChoiceChanged,
    required this.onDirty,
  });

  final model.Component ancestry;
  final model.Component traitsComp;
  final Set<String> selectedTraitIds;
  final Map<String, String> traitChoices;
  final void Function(String traitId, bool isSelected) onTraitSelectionChanged;
  final void Function(String traitOrSignatureId, String choiceValue) onTraitChoiceChanged;
  final VoidCallback onDirty;

  static const _accent = CreatorTheme.ancestryAccent;

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

    final signature = (traitsComp.data['signature'] as Map?)?.cast<String, dynamic>();

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
                style: TextStyle(color: Colors.grey.shade300, height: 1.4)),
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
          if (signature != null) ...[
            Container(
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
                      Icon(Icons.star, color: _accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${StoryAncestrySectionText.signatureLabelPrefix}${signature['name'] ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((signature['description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      signature['description'] as String,
                      style: TextStyle(
                        height: 1.4,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                  // Show dropdown for signature immunity choice (e.g., Wyrmplate)
                  if (_signatureHasImmunityChoice(signature)) ...[
                    const SizedBox(height: 12),
                    _buildImmunityDropdown(
                      context: context,
                      signatureId: 'signature_immunity',
                      currentValue: traitChoices['signature_immunity'],
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
            const SizedBox(height: 16),
          ],
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
                  remaining >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
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
            final canSelect = selected || remaining - cost >= 0;
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
                            ? Colors.grey.shade800
                            : Colors.grey.shade700,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUnavailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Not enough points',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
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
                                  ? Colors.grey.shade600 
                                  : Colors.grey.shade300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          desc,
                          style: TextStyle(
                            color: isUnavailable 
                                ? Colors.grey.shade600 
                                : Colors.grey.shade400,
                            height: 1.4,
                          ),
                        ),
                      ),
                      isThreeLine: true,
                      secondary: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.red.withValues(alpha: 0.15)
                              : const Color(0xFF5C6BC0).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnavailable
                                ? Colors.red.withValues(alpha: 0.3)
                                : const Color(0xFF5C6BC0).withValues(alpha: 0.4),
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
                      checkColor: Colors.white,
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
                        // Exclude signature immunity and other trait immunity choices
                        excludedValues: _getExcludedImmunities(id, traitChoices),
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

  /// Check if signature has immunity choice (type: "pick_one")
  bool _signatureHasImmunityChoice(Map<String, dynamic> signature) {
    final increaseTotal = signature['increase_total'] as Map?;
    if (increaseTotal == null) return false;
    return increaseTotal['type'] == 'pick_one' && increaseTotal['stat'] == 'immunity';
  }

  /// Check if trait has immunity choice
  bool _traitHasImmunityChoice(Map<String, dynamic> trait) {
    final increaseTotal = trait['increase_total'] as Map?;
    if (increaseTotal == null) return false;
    return increaseTotal['type'] == 'pick_one' && increaseTotal['stat'] == 'immunity';
  }

  /// Get ability options for pick_ability_name traits
  List<String> _getAbilityOptions(Map<String, dynamic> trait) {
    final options = trait['pick_ability_name'] as List?;
    if (options == null) return [];
    return options.cast<String>();
  }

  /// Get immunity types that should be excluded from a trait's dropdown.
  /// Excludes signature immunity and other traits' immunity choices.
  Set<String> _getExcludedImmunities(String currentTraitId, Map<String, String> choices) {
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
    required Set<String> excludedValues,
    required ValueChanged<String?> onChanged,
  }) {
    // Filter out excluded immunity types (but keep current value if it was previously selected)
    final availableTypes = _immunityTypes.where((type) {
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
          ...availableTypes.map(
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
          icon: Icons.shield,
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
                    ? Colors.white
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade400,
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

    return InkWell(
      onTap: () async {
        final pickerOptions = [
          _SearchOption<String?>(
            label: StoryAncestrySectionText.abilityDropdownHint,
            value: null,
          ),
          ...options.map(
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
          icon: Icons.auto_awesome,
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
                    ? Colors.white
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

