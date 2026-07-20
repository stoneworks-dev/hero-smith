import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/story_theme.dart';
import '../../core/text/heroes_sheet/story/sheet_story_titles_tab_text.dart';

const _accent = StoryTheme.titlesAccent;

/// Dialog for selecting ancestry traits granted by a title's ancestry_points benefit.
///
/// Shows traits from the specified ancestry with a points budget, allowing
/// the user to select traits up to the budget. Sub-choices (immunity type,
/// ability pick) are handled inline.
class TitleAncestryTraitsDialog extends ConsumerStatefulWidget {
  const TitleAncestryTraitsDialog({
    super.key,
    required this.heroId,
    required this.titleId,
    required this.ancestryId,
    required this.pointsBudget,
    required this.initialSelectedTraitIds,
    required this.initialSubChoices,
  });

  final String heroId;
  final String titleId;
  final String ancestryId;
  final int pointsBudget;
  final List<String> initialSelectedTraitIds;
  final Map<String, String> initialSubChoices;

  @override
  ConsumerState<TitleAncestryTraitsDialog> createState() =>
      _TitleAncestryTraitsDialogState();
}

class _TitleAncestryTraitsDialogState
    extends ConsumerState<TitleAncestryTraitsDialog> {
  late Set<String> _selectedTraitIds;
  late Map<String, String> _subChoices; // traitId -> chosen value
  List<Map<String, dynamic>> _traits = [];
  String _ancestryName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTraitIds = Set.from(widget.initialSelectedTraitIds);
    _subChoices = Map.from(widget.initialSubChoices);
    _loadTraits();
  }

  Future<void> _loadTraits() async {
    try {
      // Load ancestry_traits.json
      final raw = await rootBundle
          .loadString('data/story/ancestries/ancestry_traits.json');
      final decoded = json.decode(raw);
      final allTraitSets = decoded is List ? decoded : [decoded];

      for (final traitSet in allTraitSets) {
        if (traitSet is! Map) continue;
        final data = traitSet.cast<String, dynamic>();
        final aid = data['ancestry_id'] as String?;
        // Match by exact ID or with "ancestry_" prefix
        if (aid == widget.ancestryId ||
            aid == 'ancestry_${widget.ancestryId}' ||
            aid?.replaceFirst('ancestry_', '') == widget.ancestryId) {
          _ancestryName = (data['name'] as String?)
                  ?.replaceAll(' Traits', '')
                  .replaceAll('_', ' ') ??
              widget.ancestryId;
          _traits = ((data['traits'] as List?) ?? [])
              .whereType<Map>()
              .map((t) => t.cast<String, dynamic>())
              .toList();
          break;
        }
      }
    } catch (_) {
      // Fall back to empty
    }
    if (mounted) setState(() => _isLoading = false);
  }

  int get _spent => _selectedTraitIds.fold(0, (sum, id) {
        final trait = _traits.firstWhere(
          (t) => (t['id'] ?? t['name']).toString() == id,
          orElse: () => <String, dynamic>{},
        );
        return sum + ((trait['cost'] as int?) ?? 0);
      });

  int get _remaining => widget.pointsBudget - _spent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _accent),
              )
            else ...[
              _buildPointsBar(),
              Flexible(child: _buildTraitsList()),
            ],
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withAlpha(51),
            _accent.withAlpha(13),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: _accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SheetStoryTitlesTabText.ancestryTraitsTitle(_ancestryName),
                  style: const TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  SheetStoryTitlesTabText.pointsBudget(widget.pointsBudget),
                  style:
                      TextStyle(color: FormTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBar() {
    final remaining = _remaining;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: FormTheme.surface,
        ),
        child: Row(
          children: [
            _pointsBadge(
              'Budget: ${widget.pointsBudget}',
              const Color(0xFF5C6BC0),
            ),
            const SizedBox(width: 12),
            _pointsBadge(
              'Remaining: $remaining',
              remaining >= 0
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointsBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withAlpha(51),
          border: Border.all(color: color.withAlpha(102)),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );

  Widget _buildTraitsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _traits.length,
      itemBuilder: (context, index) => _buildTraitTile(_traits[index]),
    );
  }

  Widget _buildTraitTile(Map<String, dynamic> trait) {
    final id = (trait['id'] ?? trait['name']).toString();
    final name = (trait['name'] ?? id).toString();
    final desc = (trait['description'] ?? '').toString();
    final cost = (trait['cost'] as int?) ?? 0;
    final selected = _selectedTraitIds.contains(id);
    final canSelect = selected || _remaining - cost >= 0;
    final isUnavailable = !selected && !canSelect;

    final hasImmunityChoice = _traitHasImmunityChoice(trait);
    final abilityOptions = _getAbilityOptions(trait);

    return Opacity(
      opacity: isUnavailable ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? _accent.withAlpha(26)
              : isUnavailable
                  ? const Color(0xFF1A1A1A)
                  : FormTheme.surface,
          border: Border.all(
            color: selected
                ? _accent.withAlpha(102)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FormTheme.surfaceMuted,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, size: 14, color: FormTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      SheetStoryTitlesTabText.notEnoughPoints,
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
                      setState(() {
                        if (value == true) {
                          _selectedTraitIds.add(id);
                        } else {
                          _selectedTraitIds.remove(id);
                          // Clear sub-choices for deselected trait
                          _subChoices.remove(id);
                        }
                      });
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
                    fontSize: 12,
                  ),
                ),
              ),
              isThreeLine: true,
              secondary: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? Colors.red.withAlpha(38)
                      : const Color(0xFF5C6BC0).withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUnavailable
                        ? Colors.red.withAlpha(77)
                        : const Color(0xFF5C6BC0).withAlpha(102),
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
            // Immunity choice dropdown
            if (selected && hasImmunityChoice)
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                child: _buildImmunityDropdown(
                  id,
                  availableTypes: _immunityChoiceOptions(trait),
                ),
              ),
            // Ability pick dropdown
            if (selected && abilityOptions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
                child: _buildAbilityDropdown(id, abilityOptions),
              ),
          ],
        ),
      ),
    );
  }

  bool _traitHasImmunityChoice(Map<String, dynamic> trait) {
    final increase = trait['increase_total'];
    if (increase is Map) {
      return increase['type'] == 'pick_one';
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
    return canonicalOptions.isEmpty ? _defaultImmunityTypes : canonicalOptions;
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

  List<String> _getAbilityOptions(Map<String, dynamic> trait) {
    final pick = trait['pick_ability_name'];
    if (pick is List) return pick.whereType<String>().toList();
    return [];
  }

  static const List<String> _defaultImmunityTypes = [
    'acid',
    'cold',
    'corruption',
    'fire',
    'holy',
    'lightning',
    'poison',
    'psychic',
  ];

  Widget _buildImmunityDropdown(
    String traitId, {
    List<String>? availableTypes,
  }) {
    final choiceTypes = availableTypes == null || availableTypes.isEmpty
        ? _defaultImmunityTypes
        : availableTypes;
    final current = _subChoices[traitId];
    final visibleTypes = [
      ...choiceTypes,
      if (current != null &&
          current.isNotEmpty &&
          !choiceTypes.contains(current))
        current,
    ];

    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(
        labelText: 'Choose immunity type',
        labelStyle: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: StoryTheme.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accent.withAlpha(102)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dropdownColor: NavigationTheme.cardBackgroundDark,
      style: TextStyle(color: FormTheme.textBright, fontSize: 13),
      items: visibleTypes
          .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t[0].toUpperCase() + t.substring(1)),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _subChoices[traitId] = value);
      },
    );
  }

  Widget _buildAbilityDropdown(String traitId, List<String> options) {
    final current = _subChoices[traitId];

    return DropdownButtonFormField<String>(
      value: options.contains(current) ? current : null,
      decoration: InputDecoration(
        labelText: 'Choose ability',
        labelStyle: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: StoryTheme.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accent.withAlpha(102)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dropdownColor: NavigationTheme.cardBackgroundDark,
      style: TextStyle(color: FormTheme.textBright, fontSize: 13),
      items: options
          .map((name) => DropdownMenuItem(
                value: name,
                child: Text(name),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _subChoices[traitId] = value);
      },
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(color: FormTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(
                TitleAncestryTraitsResult(
                  selectedTraitIds: _selectedTraitIds.toList(),
                  subChoices: Map.from(_subChoices),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Result from the ancestry traits dialog.
class TitleAncestryTraitsResult {
  const TitleAncestryTraitsResult({
    required this.selectedTraitIds,
    required this.subChoices,
  });

  final List<String> selectedTraitIds;
  final Map<String, String> subChoices;
}
