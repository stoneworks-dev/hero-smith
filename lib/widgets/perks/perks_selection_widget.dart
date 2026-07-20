import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/models/component.dart' as model;
import '../../core/services/perk_grants_service.dart';
import '../../core/storage/hero_storage_contract.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/form_theme.dart';
import '../../core/text/widgets/perks_widget_text.dart';
import '../../features/hero_builder/domain/hero_claim.dart';
import '../../features/hero_builder/domain/hero_conflict_index.dart';
import '../../features/hero_builder/domain/hero_mutation_scope.dart';
import '../abilities/ability_expandable_item.dart';

// Perks accent color for default styling
const _perksColor = Color(0xFFFF7043);

/// Provider for loading perk grant choices for a specific hero and perk
final perkGrantChoicesProvider = FutureProvider.family<
    Map<String, List<String>>,
    ({String heroId, String perkId})>((ref, args) async {
  final service = ref.read(perkGrantsServiceProvider);
  return service.getAllGrantChoicesForPerk(
    heroId: args.heroId,
    perkId: args.perkId,
  );
});

/// Callback for perk selection changes
typedef PerksSelectionChanged = void Function(Set<String> selectedPerkIds);

/// A reusable widget for selecting perks.
///
/// This widget can be used:
/// 1. In the story creator's career section (with perkType filter and pickCount)
/// 2. In the hero sheet's perks tab (showing all hero perks and allowing additions)
/// 3. In the strife creator (with class-specific perk allowances)
class PerksSelectionWidget extends ConsumerStatefulWidget {
  const PerksSelectionWidget({
    super.key,
    required this.heroId,
    this.selectedPerkIds = const {},
    this.reservedPerkIds = const {},
    this.perkConflictIndex,
    this.languageConflictIndex,
    this.skillConflictIndex,
    this.perkSlotKeyPrefix,
    this.perkType,
    this.allowedGroups,
    this.pickCount,
    this.onSelectionChanged,
    this.onDirty,
    this.languages = const [],
    this.skills = const [],
    this.reservedLanguageIds = const {},
    this.reservedSkillIds = const {},
    this.ownedSkillIds,
    this.showHeader = true,
    this.headerTitle = 'Perks',
    this.headerSubtitle,
    this.allowAddingNew = false,
    this.emptyStateMessage = 'No perks selected.',
    this.persistToDatabase = false,
  });

  /// The hero ID for grant choice persistence
  final String heroId;

  /// Currently selected perk IDs
  final Set<String> selectedPerkIds;

  /// Perk IDs that are reserved (e.g., from other sources) and should be excluded
  final Set<String> reservedPerkIds;

  /// Source-aware conflicts for selection slots. When supplied, this replaces
  /// flat [reservedPerkIds] filtering for the indexed perk picker.
  final HeroConflictIndex? perkConflictIndex;

  /// Parent-draft projections used by language/skill choices nested inside a
  /// selected perk. The nested editor removes only that perk's exact source.
  final HeroConflictIndex? languageConflictIndex;
  final HeroConflictIndex? skillConflictIndex;

  /// Stable prefix used to identify each indexed perk slot.
  final String? perkSlotKeyPrefix;

  /// Optional perk type filter (e.g., "crafting", "exploration")
  final String? perkType;

  /// Optional allowed perk groups; takes priority over [perkType] when provided.
  final Set<String>? allowedGroups;

  /// Number of perks to pick. If null, shows all selected perks (view mode)
  final int? pickCount;

  /// Callback when selection changes
  final PerksSelectionChanged? onSelectionChanged;

  /// Callback when data is modified (for dirty tracking)
  final VoidCallback? onDirty;

  /// Available languages for grant selection
  final List<model.Component> languages;

  /// Available skills for grant selection
  final List<model.Component> skills;

  /// Language IDs reserved by other sources
  final Set<String> reservedLanguageIds;

  /// Skill IDs reserved by other sources
  final Set<String> reservedSkillIds;

  /// Effective skills for `one_owned` grants. Null keeps the compatibility
  /// behavior where [reservedSkillIds] doubles as the owned-skill set.
  final Set<String>? ownedSkillIds;

  /// Whether to show the header
  final bool showHeader;

  /// Title for the header
  final String headerTitle;

  /// Subtitle for the header
  final String? headerSubtitle;

  /// Whether to allow adding new perks (shows an "Add Perk" button)
  final bool allowAddingNew;

  /// Message shown when no perks are selected
  final String emptyStateMessage;

  /// Whether to persist selection changes directly to the database.
  /// Set to true when this widget manages ALL of a hero's perks (e.g., in hero sheet).
  /// Set to false when this widget manages only a subset (e.g., career perks in story creator).
  final bool persistToDatabase;

  @override
  ConsumerState<PerksSelectionWidget> createState() =>
      _PerksSelectionWidgetState();
}

class _PerksSelectionWidgetState extends ConsumerState<PerksSelectionWidget> {
  bool _appliedInitialGrants = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ensureExistingPerkGrants());
  }

  @override
  void didUpdateWidget(covariant PerksSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroId != widget.heroId ||
        !setEquals(oldWidget.selectedPerkIds, widget.selectedPerkIds)) {
      _appliedInitialGrants = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ensureExistingPerkGrants());
    }
  }

  @override
  Widget build(BuildContext context) {
    final perksAsync = ref.watch(componentsByTypeProvider('perk'));

    return perksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(PerksWidgetText.failedToLoadPerks(e))),
      data: (perks) => _buildContent(context, perks),
    );
  }

  Widget _buildContent(BuildContext context, List<model.Component> allPerks) {
    // Use the perks accent color for consistency
    const borderColor = _perksColor;
    final normalizedAllowedGroups =
        _normalizeAllowedGroups(widget.allowedGroups);

    // Filter perks by type if specified
    final filteredPerks = _filterPerksByType(
      allPerks,
      widget.perkType,
      allowedGroups: normalizedAllowedGroups,
    );

    final hasFilters = normalizedAllowedGroups.isNotEmpty ||
        (widget.perkType?.isNotEmpty ?? false);
    if (filteredPerks.isEmpty && hasFilters) {
      // Fallback to all perks if no perks match the type
      return _buildPerkSelector(context, allPerks, borderColor);
    }

    return _buildPerkSelector(context, filteredPerks, borderColor);
  }

  Set<String> _normalizeAllowedGroups(Set<String>? groups) {
    if (groups == null) return const {};
    return groups
        .map(_normalizePerkType)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  List<model.Component> _filterPerksByType(
    List<model.Component> perks,
    String? perkType, {
    Set<String> allowedGroups = const {},
  }) {
    if ((perkType == null || perkType.isEmpty) && allowedGroups.isEmpty) {
      return perks..sort((a, b) => a.name.compareTo(b.name));
    }

    final normalizedType = _normalizePerkType(perkType);
    final normalizedAllowed = allowedGroups
        .map(_normalizePerkType)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalizedType == null && normalizedAllowed.isEmpty) {
      return perks..sort((a, b) => a.name.compareTo(b.name));
    }

    final filtered = perks.where((perk) {
      final rawType = (perk.data['perk_type'] ??
              perk.data['perkType'] ??
              perk.data['group'])
          ?.toString();
      final normalizedPerkType = _normalizePerkType(rawType);
      if (normalizedPerkType == null || normalizedPerkType.isEmpty) {
        return false;
      }
      if (normalizedAllowed.isNotEmpty) {
        return normalizedAllowed.any(
          (group) =>
              normalizedPerkType == group ||
              normalizedPerkType.contains(group) ||
              group.contains(normalizedPerkType),
        );
      }
      if (normalizedType == null || normalizedType.isEmpty) {
        return true;
      }
      return normalizedPerkType == normalizedType ||
          normalizedPerkType.contains(normalizedType) ||
          normalizedType.contains(normalizedPerkType);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return filtered;
  }

  String? _normalizePerkType(String? value) {
    if (value == null) return null;
    final cleaned = value
        .toLowerCase()
        .replaceAll('perk', '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String _formatGroupLabel(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return 'General';
    }
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _buildPerkSelector(
    BuildContext context,
    List<model.Component> perks,
    Color borderColor,
  ) {
    final pickCount = widget.pickCount;

    // Group perks by type
    final grouped = <String, List<model.Component>>{};
    for (final perk in perks) {
      final rawType = (perk.data['group'] ??
              perk.data['perk_type'] ??
              perk.data['perkType'])
          ?.toString();
      final key = _formatGroupLabel(rawType);
      grouped.putIfAbsent(key, () => []).add(perk);
    }
    final sortedGroupKeys = grouped.keys.toList()..sort();
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    // Create perk map for lookup
    final perkMap = {for (final perk in perks) perk.id: perk};

    // Get current selections
    final currentSelections =
        widget.selectedPerkIds.where(perkMap.containsKey).toList();

    // If pickCount is null, show all selected perks (view mode)
    if (pickCount == null) {
      return _buildViewMode(context, currentSelections, perkMap, borderColor,
          grouped, sortedGroupKeys);
    }

    // Build selection mode
    return _buildSelectionMode(
      context,
      pickCount,
      currentSelections,
      perkMap,
      borderColor,
      grouped,
      sortedGroupKeys,
    );
  }

  Widget _buildViewMode(
    BuildContext context,
    List<String> currentSelections,
    Map<String, model.Component> perkMap,
    Color borderColor,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            children: [
              Icon(Icons.stars, color: borderColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.headerTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (widget.allowAddingNew)
                TextButton.icon(
                  onPressed: () => _openAddPerkPicker(
                    context,
                    currentSelections,
                    perkMap,
                    grouped,
                    sortedGroupKeys,
                    borderColor,
                  ),
                  icon: Icon(Icons.add, color: borderColor),
                  label: Text(PerksWidgetText.addPerk,
                      style: TextStyle(color: borderColor)),
                ),
            ],
          ),
          if (widget.headerSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.headerSubtitle!,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
        if (currentSelections.isEmpty)
          _buildEmptyState(
              borderColor, currentSelections, perkMap, grouped, sortedGroupKeys)
        else
          ...currentSelections.asMap().entries.map((entry) {
            final index = entry.key;
            final perkId = entry.value;
            final perk = perkMap[perkId]!;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < currentSelections.length - 1 ? 12 : 0,
              ),
              child: _buildPerkDisplay(context, perk, borderColor,
                  showRemove: widget.allowAddingNew),
            );
          }),
        // Add Perk button at the bottom when not empty and header is hidden
        // Space for FAB when perks exist
        if (currentSelections.isNotEmpty && widget.allowAddingNew)
          const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyState(
    Color borderColor,
    List<String> currentSelections,
    Map<String, model.Component> perkMap,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Column(
        children: [
          Icon(Icons.star_border, size: 48, color: FormTheme.borderLight),
          const SizedBox(height: 12),
          Text(
            widget.emptyStateMessage,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: FormTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionMode(
    BuildContext context,
    int pickCount,
    List<String> currentSelections,
    Map<String, model.Component> perkMap,
    Color borderColor,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
  ) {
    List<String?> currentSlots() {
      final slots = List<String?>.filled(pickCount, null);
      for (var i = 0; i < pickCount && i < currentSelections.length; i++) {
        slots[i] = currentSelections[i];
      }
      return slots;
    }

    final slots = currentSlots();
    final remaining = slots.where((value) => value == null).length;
    final perkTypeLabel = widget.perkType?.isNotEmpty == true
        ? ' of type ${widget.perkType}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          const SizedBox(height: 8),
          Text(
            'Choose $pickCount perk${pickCount == 1 ? '' : 's'}$perkTypeLabel.',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: FormTheme.textBright),
          ),
          const SizedBox(height: 8),
        ],
        for (var index = 0; index < pickCount; index++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openSearchForPerkIndex(
              context,
              index,
              slots,
              perkMap,
              grouped,
              sortedGroupKeys,
              borderColor,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: NavigationTheme.cardBackgroundDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withAlpha(102)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: borderColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.star, size: 16, color: borderColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perk pick ${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: borderColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slots[index] != null
                              ? perkMap[slots[index]]!.name
                              : 'Choose perk',
                          style: TextStyle(
                            fontSize: 15,
                            color: slots[index] != null
                                ? FormTheme.textBright
                                : FormTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.search, color: FormTheme.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_perkConflictForSlot(index, slots[index]) case final conflict?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Already owned by: ${_ownerLabels(conflict)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (slots[index] != null) ...[
            const SizedBox(height: 6),
            _buildPerkDisplay(context, perkMap[slots[index]]!, borderColor),
          ],
          const SizedBox(height: 12),
        ],
        if (remaining > 0)
          Text(
            '$remaining pick${remaining == 1 ? '' : 's'} remaining.',
            style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPerkDisplay(
    BuildContext context,
    model.Component perk,
    Color borderColor, {
    bool showRemove = false,
  }) {
    final grantsRaw = perk.data['grants'];
    final grants =
        grantsRaw is List ? grantsRaw : (grantsRaw is Map ? [grantsRaw] : null);
    final group = (perk.data['group'] as String?) ?? 'exploration';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppIcon(PerkGroupIcons.fromGroup(group),
                    size: 16, color: borderColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  perk.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: FormTheme.textBright,
                    fontSize: 15,
                  ),
                ),
              ),
              if (showRemove)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: FormTheme.textMuted),
                  onPressed: () => _removePerk(perk.id, perk.name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            perk.data['description']?.toString() ??
                PerksWidgetText.noDescriptionAvailable,
            style: TextStyle(
              fontSize: 13,
              color: FormTheme.textSecondary,
            ),
          ),
          if (grants != null && grants.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: borderColor.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Grants:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: borderColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _PerkGrantsDisplay(
              heroId: widget.heroId,
              perkId: perk.id,
              grants: grants,
              accentColor: borderColor,
              languages: widget.languages,
              skills: widget.skills,
              reservedLanguageIds: widget.reservedLanguageIds,
              reservedSkillIds: widget.reservedSkillIds,
              ownedSkillIds: widget.ownedSkillIds ?? widget.reservedSkillIds,
              languageConflictIndex: widget.languageConflictIndex,
              skillConflictIndex: widget.skillConflictIndex,
              onDirty: widget.onDirty ?? () {},
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _removePerk(String perkId, String perkName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FormTheme.borderDim),
        ),
        title: Text(PerksWidgetText.removePerk,
            style: TextStyle(color: FormTheme.textBright)),
        content: Text(
          'Are you sure you want to remove "$perkName"?',
          style: TextStyle(color: FormTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(PerksWidgetText.cancel,
                style: TextStyle(color: FormTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
            child: Text(PerksWidgetText.remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newSelection = Set<String>.from(widget.selectedPerkIds)
      ..remove(perkId);
    await _applySelectionChange(newSelection, {perkId}, perkMap: null);
  }

  Future<void> _openSearchForPerkIndex(
    BuildContext context,
    int index,
    List<String?> currentSlots,
    Map<String, model.Component> perkMap,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
    Color borderColor,
  ) async {
    final options = _buildSearchOptionsForPerkIndex(
      index,
      currentSlots,
      perkMap,
      grouped,
      sortedGroupKeys,
    );

    final result = await showSearchablePicker<String?>(
      context: context,
      title: PerksWidgetText.selectPerk,
      options: options,
      selected: currentSlots[index],
    );

    if (result == null) return;

    final updated = List<String?>.from(currentSlots);
    updated[index] = result.value;

    // Remove duplicates
    if (result.value != null) {
      for (var i = 0; i < updated.length; i++) {
        if (i != index && updated[i] == result.value) {
          updated[i] = null;
        }
      }
    }

    final next = LinkedHashSet<String>();
    for (final pick in updated) {
      if (pick != null) {
        next.add(pick);
      }
    }
    final removed = Set<String>.from(widget.selectedPerkIds)..removeAll(next);
    await _applySelectionChange(next, removed, perkMap: perkMap);
  }

  Future<void> _openAddPerkPicker(
    BuildContext context,
    List<String> currentSelections,
    Map<String, model.Component> perkMap,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
    Color borderColor,
  ) async {
    final excludedIds = <String>{
      ...widget.reservedPerkIds,
      ...currentSelections,
    };

    final options = <SearchOption<String?>>[
      SearchOption<String?>(
        label: PerksWidgetText.choosePerk,
        value: null,
      ),
    ];

    for (final key in sortedGroupKeys) {
      for (final perk in grouped[key]!) {
        if (excludedIds.contains(perk.id)) {
          continue;
        }
        options.add(
          SearchOption<String?>(
            label: perk.name,
            value: perk.id,
            subtitle: key,
          ),
        );
      }
    }

    final result = await showSearchablePicker<String?>(
      context: context,
      title: PerksWidgetText.addPerk,
      options: options,
      selected: null,
    );

    if (result == null || result.value == null) return;

    final newSelection = Set<String>.from(widget.selectedPerkIds)
      ..add(result.value!);
    await _applySelectionChange(newSelection, const {}, perkMap: perkMap);
  }

  List<SearchOption<String?>> _buildSearchOptionsForPerkIndex(
    int currentIndex,
    List<String?> slots,
    Map<String, model.Component> perkMap,
    Map<String, List<model.Component>> grouped,
    List<String> sortedGroupKeys,
  ) {
    final options = <SearchOption<String?>>[
      SearchOption<String?>(
        label: PerksWidgetText.choosePerk,
        value: null,
      ),
    ];

    final conflictIndex = widget.perkConflictIndex;
    final slotKey = _perkSlotKey(currentIndex);
    final excludedIds = <String>{...widget.reservedPerkIds};
    if (conflictIndex == null || slotKey == null) {
      for (var i = 0; i < slots.length; i++) {
        if (i == currentIndex) continue;
        final pick = slots[i];
        if (pick != null) {
          excludedIds.add(pick);
        }
      }
    }
    final currentValue = slots[currentIndex];

    for (final key in sortedGroupKeys) {
      for (final perk in grouped[key]!) {
        final blocked = conflictIndex != null && slotKey != null
            ? perk.id != currentValue &&
                conflictIndex.isClaimed(
                  HeroEntryKey(
                    entryType: 'perk',
                    canonicalEntryId: perk.id,
                  ),
                  ignoredDraftSlotKey: slotKey,
                )
            : _isBlocked(perk.id, excludedIds, currentId: currentValue);
        if (blocked) {
          continue;
        }
        final conflict = perk.id == currentValue
            ? _perkConflictForSlot(currentIndex, perk.id)
            : null;
        options.add(
          SearchOption<String?>(
            label: perk.name,
            value: perk.id,
            subtitle: conflict == null
                ? key
                : 'Already owned by: ${_ownerLabels(conflict)}',
          ),
        );
      }
    }

    return options;
  }

  bool _isBlocked(String id, Set<String> blocked, {String? currentId}) {
    if (id == currentId) return false;
    return blocked.contains(id);
  }

  String? _perkSlotKey(int index) {
    final prefix = widget.perkSlotKeyPrefix?.trim();
    if (prefix == null || prefix.isEmpty) return null;
    return '$prefix#$index';
  }

  HeroConflict? _perkConflictForSlot(int index, String? perkId) {
    final conflictIndex = widget.perkConflictIndex;
    final slotKey = _perkSlotKey(index);
    if (conflictIndex == null ||
        slotKey == null ||
        perkId == null ||
        perkId.trim().isEmpty) {
      return null;
    }
    return conflictIndex.conflictFor(
      HeroEntryKey(
        entryType: 'perk',
        canonicalEntryId: perkId,
      ),
      ignoredDraftSlotKey: slotKey,
    );
  }

  String _ownerLabels(HeroConflict conflict) {
    return conflict.owners
        .map((owner) => owner.displayLabel ?? owner.source.toString())
        .join(', ');
  }

  Future<void> _ensureExistingPerkGrants() async {
    if (_appliedInitialGrants) return;
    // Only apply grants if persistToDatabase is enabled
    if (!widget.persistToDatabase) {
      _appliedInitialGrants = true;
      return;
    }
    if (widget.heroId.isEmpty) return;
    if (widget.selectedPerkIds.isEmpty) {
      _appliedInitialGrants = true;
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final service = ref.read(perkGrantsServiceProvider);
    for (final perkId in widget.selectedPerkIds) {
      final component = await _loadPerkComponent(perkId, null, db);
      if (component == null) continue;
      await service.applyPerkGrants(
        heroId: widget.heroId,
        perkId: perkId,
        grantsJson: component.data['grants'],
      );
    }
    _appliedInitialGrants = true;
  }

  Future<void> _applySelectionChange(
    Set<String> next,
    Set<String> removed, {
    Map<String, model.Component>? perkMap,
  }) async {
    final added = next.difference(widget.selectedPerkIds);
    final effectiveNext = Set<String>.from(next);

    // Only persist to database and apply grants if persistToDatabase is enabled
    if (widget.persistToDatabase && widget.heroId.isNotEmpty) {
      final db = ref.read(appDatabaseProvider);
      final entries = ref.read(heroEntryRepositoryProvider);
      final guard = ref.read(heroDuplicateGuardServiceProvider);
      final service = ref.read(perkGrantsServiceProvider);

      // Apply grants for newly added perks (abilities)
      for (final perkId in added) {
        final existingPerks = await entries.listEntriesByType(
          widget.heroId,
          HeroEntryTypes.perk,
        );
        if (guard.isReserved(
          candidateId: perkId,
          entries: existingPerks,
          entryType: HeroEntryTypes.perk,
        )) {
          effectiveNext.remove(perkId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(PerksWidgetText.perkAlreadyAdded)),
            );
          }
          continue;
        }
        await entries.addEntry(
          heroId: widget.heroId,
          entryType: HeroEntryTypes.perk,
          entryId: perkId,
          sourceType: HeroEntrySourceTypes.heroSheet,
          sourceId: HeroEntryTypes.perk,
          gainedBy: HeroEntryGainedBy.choice,
        );
        final component = await _loadPerkComponent(perkId, perkMap, db);
        if (component == null) continue;
        await service.applyPerkGrants(
          heroId: widget.heroId,
          perkId: perkId,
          grantsJson: component.data['grants'],
        );
      }

      // Remove grants from removed perks
      for (final perkId in removed) {
        final removedCount = await entries.removeEntryFromSource(
          heroId: widget.heroId,
          entryType: HeroEntryTypes.perk,
          entryId: perkId,
          sourceType: HeroEntrySourceTypes.heroSheet,
          sourceId: HeroEntryTypes.perk,
        );
        if (removedCount == 0) {
          effectiveNext.add(perkId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  PerksWidgetText.perkOwnedElsewhere,
                ),
              ),
            );
          }
          continue;
        }
        await service.removePerkGrants(heroId: widget.heroId, perkId: perkId);
      }
    }

    widget.onSelectionChanged?.call(effectiveNext);
    widget.onDirty?.call();
  }

  Future<model.Component?> _loadPerkComponent(
    String perkId,
    Map<String, model.Component>? perkMap,
    dynamic db,
  ) async {
    if (perkMap != null && perkMap.containsKey(perkId)) {
      return perkMap[perkId];
    }
    final row = await db.getComponentById(perkId);
    if (row == null) return null;
    Map<String, dynamic> data = {};
    if (row.dataJson != null && row.dataJson.isNotEmpty) {
      data = jsonDecode(row.dataJson) as Map<String, dynamic>;
    } else if (row.data != null) {
      data = Map<String, dynamic>.from(row.data as Map);
    }
    return model.Component(
      id: row.id,
      type: row.type,
      name: row.name,
      data: data,
    );
  }
}

/// A widget that displays the granted abilities/skills/languages for a perk.
class _PerkGrantsDisplay extends ConsumerWidget {
  const _PerkGrantsDisplay({
    required this.heroId,
    required this.perkId,
    required this.grants,
    required this.accentColor,
    required this.languages,
    required this.skills,
    required this.reservedLanguageIds,
    required this.reservedSkillIds,
    required this.ownedSkillIds,
    required this.languageConflictIndex,
    required this.skillConflictIndex,
    required this.onDirty,
  });

  final String heroId;
  final String perkId;
  final List<dynamic> grants;
  final Color accentColor;
  final List<model.Component> languages;
  final List<model.Component> skills;
  final Set<String> reservedLanguageIds;
  final Set<String> reservedSkillIds;
  final Set<String> ownedSkillIds;
  final HeroConflictIndex? languageConflictIndex;
  final HeroConflictIndex? skillConflictIndex;
  final VoidCallback onDirty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = FormTheme.textSecondary;
    final languageMap = {for (final lang in languages) lang.id: lang};
    final skillMap = {for (final skill in skills) skill.id: skill};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grant in grants)
          _buildGrantItem(
              context, ref, grant, textColor, languageMap, skillMap),
      ],
    );
  }

  Widget _buildGrantItem(
    BuildContext context,
    WidgetRef ref,
    dynamic grant,
    Color textColor,
    Map<String, model.Component> languageMap,
    Map<String, model.Component> skillMap,
  ) {
    if (grant is! Map) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('• ${grant.toString()}',
            style: TextStyle(fontSize: 12, color: textColor)),
      );
    }

    final parsedGrant = PerkGrant.fromJson(grant);
    if (parsedGrant != null) {
      return _buildParsedGrantItem(
        context,
        ref,
        parsedGrant,
        textColor,
        languageMap,
        skillMap,
      );
    }

    if (grant.containsKey('ability')) {
      return _buildAbilityGrant(
          context, ref, grant['ability'] as String?, textColor);
    }

    if (grant.containsKey('languages')) {
      final count = _parseCount(grant['languages']);
      return _buildLanguageGrant(context, ref, count, textColor, languageMap);
    }

    if (grant.containsKey('skill')) {
      final skillData = grant['skill'];
      if (skillData is Map) {
        return _buildSkillGrant(context, ref,
            Map<String, dynamic>.from(skillData), textColor, skillMap);
      }
    }

    final formatted =
        grant.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return _buildGrantRow('• $formatted', textColor);
  }

  Widget _buildParsedGrantItem(
    BuildContext context,
    WidgetRef ref,
    PerkGrant grant,
    Color textColor,
    Map<String, model.Component> languageMap,
    Map<String, model.Component> skillMap,
  ) {
    return switch (grant) {
      AbilityGrant(:final abilityName) =>
        _buildAbilityGrant(context, ref, abilityName, textColor),
      CreatureGrant(:final creatureName) =>
        _buildGrantRow('• Creature: $creatureName', textColor),
      SkillFromOwnedGrant(:final group) =>
        _buildSkillOwnedGrant(context, ref, group, textColor, skillMap),
      SkillPickGrant(:final group, :final count) =>
        _buildSkillPickGrant(context, ref, group, count, textColor, skillMap),
      LanguageGrant(:final count) =>
        _buildLanguageGrant(context, ref, count, textColor, languageMap),
      MultiGrant(:final grants) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final nestedGrant in grants)
              _buildParsedGrantItem(
                context,
                ref,
                nestedGrant,
                textColor,
                languageMap,
                skillMap,
              ),
          ],
        ),
    };
  }

  Widget _buildAbilityGrant(
    BuildContext context,
    WidgetRef ref,
    String? abilityName,
    Color textColor,
  ) {
    if (abilityName == null || abilityName.isEmpty) {
      return _buildGrantRow('• Ability grant', textColor);
    }

    final abilityAsync = ref.watch(abilityByNameProvider(abilityName));
    return abilityAsync.when(
      data: (ability) {
        if (ability == null) {
          return _buildGrantRow('• Ability: $abilityName', textColor);
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: AbilityExpandableItem(component: ability),
        );
      },
      loading: () => _buildLoadingRow(textColor, 'Loading $abilityName...'),
      error: (e, _) => _buildGrantRow('• Ability: $abilityName', textColor),
    );
  }

  Widget _buildLanguageGrant(
    BuildContext context,
    WidgetRef ref,
    int count,
    Color textColor,
    Map<String, model.Component> languageMap,
  ) {
    if (heroId.isEmpty) {
      return _buildGrantRow(
          'Choose ${count == 1 ? 'a' : count} new language${count == 1 ? '' : 's'}.',
          textColor);
    }

    // Calculate reserved languages for warning
    final reservedLangs = languages
        .where((lang) => reservedLanguageIds.contains(lang.id))
        .toList();
    final reservedCount = reservedLangs.length;

    final choicesAsync =
        ref.watch(perkGrantChoicesProvider((heroId: heroId, perkId: perkId)));
    return choicesAsync.when(
      data: (choices) {
        final selected = List<String>.from(choices['language'] ?? const []);
        final conflictIndex = _grantConflictIndex(
          ref,
          entryType: HeroEntryTypes.language,
          grantType: 'language',
          chosenIds: selected,
        );
        final widgets = <Widget>[];

        // Add warning if some languages are reserved
        if (conflictIndex == null && reservedCount > 0) {
          final reservedNames = reservedLangs.map((l) => l.name).toList()
            ..sort();
          final langsText = reservedCount == 1
              ? '${reservedNames.first} is'
              : '${reservedNames.join(", ")} are';
          widgets.add(_buildReservationWarning(
            '$langsText already selected elsewhere',
          ));
        }

        for (var index = 0; index < count; index++) {
          final selectedId = index < selected.length ? selected[index] : null;
          final label =
              count == 1 ? 'Language Choice' : 'Language Choice ${index + 1}';
          widgets.add(
            _buildPickerField(
              context: context,
              label: label,
              placeholder: 'Choose language',
              selectedName:
                  selectedId != null ? languageMap[selectedId]?.name : null,
              onTap: () => _openLanguagePicker(
                context: context,
                ref: ref,
                slotIndex: index,
                currentChoices: selected,
                currentSelectedId: selectedId,
                conflictIndex: conflictIndex,
                slotKey: _grantSlotKey('language', index),
              ),
            ),
          );
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
      },
      loading: () => _buildLoadingRow(textColor, 'Loading languages...'),
      error: (e, _) =>
          _buildGrantRow('Failed to load languages: $e', textColor),
    );
  }

  Widget _buildSkillGrant(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> skillData,
    Color textColor,
    Map<String, model.Component> skillMap,
  ) {
    final group = (skillData['group'] as String?)?.trim();
    if (group == null || group.isEmpty) {
      return _buildGrantRow('Skill grant available', textColor);
    }

    final countData = skillData['count'];
    if (countData == 'one_owned') {
      return _buildSkillOwnedGrant(context, ref, group, textColor, skillMap);
    }

    final count = _parseCount(countData);
    if (count <= 0) {
      return _buildGrantRow('Choose a ${_capitalize(group)} skill.', textColor);
    }

    return _buildSkillPickGrant(
        context, ref, group, count, textColor, skillMap);
  }

  Widget _buildSkillOwnedGrant(
    BuildContext context,
    WidgetRef ref,
    String group,
    Color textColor,
    Map<String, model.Component> skillMap,
  ) {
    final normalizedGroup = group.toLowerCase();
    final owned = skills.where((skill) {
      final skillGroup = (skill.data['group'] as String?)?.toLowerCase();
      return skillGroup == normalizedGroup && ownedSkillIds.contains(skill.id);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (owned.isEmpty) {
      return _buildGrantRow(
          'No ${_capitalize(group)} skills known yet.', textColor);
    }

    final choicesAsync =
        ref.watch(perkGrantChoicesProvider((heroId: heroId, perkId: perkId)));
    return choicesAsync.when(
      data: (choices) {
        final selected = List<String>.from(choices['skill_owned'] ?? const []);
        final selectedId = selected.isNotEmpty ? selected.first : null;
        final label = '${_capitalize(group)} Skill';
        return _buildPickerField(
          context: context,
          label: label,
          placeholder: 'Choose skill',
          selectedName: selectedId != null ? skillMap[selectedId]?.name : null,
          onTap: () => _openSkillPicker(
            context: context,
            ref: ref,
            grantType: 'skill_owned',
            slotIndex: 0,
            currentChoices: selected,
            currentSelectedId: selectedId,
            group: group,
            allowOwnedOnly: true,
          ),
        );
      },
      loading: () => _buildLoadingRow(textColor, 'Loading skills...'),
      error: (e, _) => _buildGrantRow('Failed to load skills: $e', textColor),
    );
  }

  Widget _buildSkillPickGrant(
    BuildContext context,
    WidgetRef ref,
    String group,
    int count,
    Color textColor,
    Map<String, model.Component> skillMap,
  ) {
    final normalizedGroup = group.toLowerCase();

    // Get all skills in the group
    final allInGroup = skills.where((skill) {
      final skillGroup = (skill.data['group'] as String?)?.toLowerCase();
      return skillGroup == normalizedGroup;
    }).toList();

    // Calculate how many are reserved
    final reservedInGroup = allInGroup
        .where((skill) => reservedSkillIds.contains(skill.id))
        .toList();
    final reservedCount = reservedInGroup.length;

    final choicesAsync =
        ref.watch(perkGrantChoicesProvider((heroId: heroId, perkId: perkId)));
    return choicesAsync.when(
      data: (choices) {
        final selected = List<String>.from(choices['skill_pick'] ?? const []);
        final conflictIndex = _grantConflictIndex(
          ref,
          entryType: HeroEntryTypes.skill,
          grantType: 'skill_pick',
          chosenIds: selected,
        );
        final widgets = <Widget>[];

        // Add warning if some skills are reserved
        if (conflictIndex == null && reservedCount > 0) {
          final reservedNames = reservedInGroup.map((s) => s.name).toList()
            ..sort();
          final skillsText = reservedCount == 1
              ? '${reservedNames.first} is'
              : '${reservedNames.join(", ")} are';
          widgets.add(_buildReservationWarning(
            '$skillsText already selected elsewhere',
          ));
        }

        for (var index = 0; index < count; index++) {
          final selectedId = index < selected.length ? selected[index] : null;
          final label = count == 1
              ? 'New ${_capitalize(group)} Skill'
              : 'New ${_capitalize(group)} Skill ${index + 1}';
          widgets.add(
            _buildPickerField(
              context: context,
              label: label,
              placeholder: 'Choose skill',
              selectedName:
                  selectedId != null ? skillMap[selectedId]?.name : null,
              onTap: () => _openSkillPicker(
                context: context,
                ref: ref,
                grantType: 'skill_pick',
                slotIndex: index,
                currentChoices: selected,
                currentSelectedId: selectedId,
                group: group,
                allowOwnedOnly: false,
                conflictIndex: conflictIndex,
                slotKey: _grantSlotKey('skill_pick', index),
              ),
            ),
          );
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
      },
      loading: () => _buildLoadingRow(textColor, 'Loading skills...'),
      error: (e, _) => _buildGrantRow('Failed to load skills: $e', textColor),
    );
  }

  Widget _buildReservationWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(38),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.withAlpha(102)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.orange.shade400),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required BuildContext context,
    required String label,
    required String placeholder,
    required String? selectedName,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: FormTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withAlpha(77)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.edit, size: 14, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedName ?? placeholder,
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedName != null
                            ? FormTheme.textBright
                            : FormTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.search, size: 18, color: FormTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguagePicker({
    required BuildContext context,
    required WidgetRef ref,
    required int slotIndex,
    required List<String> currentChoices,
    required String? currentSelectedId,
    required HeroConflictIndex? conflictIndex,
    required String slotKey,
  }) async {
    final exclude = conflictIndex == null
        ? <String>{
            ...reservedLanguageIds.where((id) => id.isNotEmpty),
            ...currentChoices
                .where((id) => id.isNotEmpty && id != currentSelectedId),
          }
        : const <String>{};
    final options = _buildLanguageOptions(
      exclude,
      currentSelectedId,
      conflictIndex: conflictIndex,
      slotKey: slotKey,
    );
    final result = await showSearchablePicker<String?>(
      context: context,
      title: PerksWidgetText.selectLanguage,
      options: options,
      selected: currentSelectedId,
    );
    if (result == null) return;
    final updated = _updatedChoiceList(currentChoices, slotIndex, result.value);
    await _saveGrantChoice(ref, 'language', updated);
  }

  Future<void> _openSkillPicker({
    required BuildContext context,
    required WidgetRef ref,
    required String grantType,
    required int slotIndex,
    required List<String> currentChoices,
    required String? currentSelectedId,
    required String group,
    required bool allowOwnedOnly,
    HeroConflictIndex? conflictIndex,
    String? slotKey,
  }) async {
    final exclude = currentChoices
        .where((id) => id.isNotEmpty && id != currentSelectedId)
        .toSet();
    if (!allowOwnedOnly && conflictIndex == null) {
      exclude.addAll(reservedSkillIds);
    }
    final options = _buildSkillOptions(
      group: group,
      allowOwnedOnly: allowOwnedOnly,
      exclude: exclude,
      currentSelectedId: currentSelectedId,
      conflictIndex: allowOwnedOnly ? null : conflictIndex,
      slotKey: slotKey,
    );
    final result = await showSearchablePicker<String?>(
      context: context,
      title: PerksWidgetText.selectSkill(_capitalize(group)),
      options: options,
      selected: currentSelectedId,
    );
    if (result == null) return;
    final updated = _updatedChoiceList(currentChoices, slotIndex, result.value);
    await _saveGrantChoice(ref, grantType, updated);
  }

  List<SearchOption<String?>> _buildLanguageOptions(
    Set<String> exclude,
    String? currentSelectedId, {
    HeroConflictIndex? conflictIndex,
    String? slotKey,
  }) {
    final grouped = <String, List<model.Component>>{};
    for (final lang in languages) {
      final type =
          (lang.data['language_type'] as String?)?.toLowerCase() ?? 'human';
      grouped.putIfAbsent(type, () => []).add(lang);
    }
    for (final group in grouped.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    final options = <SearchOption<String?>>[
      SearchOption<String?>(label: PerksWidgetText.chooseLanguage, value: null),
    ];

    for (final entry in grouped.entries) {
      for (final lang in entry.value) {
        final blocked = conflictIndex != null && slotKey != null
            ? conflictIndex.isClaimed(
                HeroEntryKey(
                  entryType: HeroEntryTypes.language,
                  canonicalEntryId: lang.id,
                ),
                ignoredDraftSlotKey: slotKey,
              )
            : exclude.contains(lang.id);
        if (lang.id != currentSelectedId && blocked) {
          continue;
        }
        options.add(
          SearchOption<String?>(
            label: lang.name,
            value: lang.id,
            subtitle: _languageGroupTitle(entry.key),
          ),
        );
      }
    }
    return options;
  }

  List<SearchOption<String?>> _buildSkillOptions({
    required String group,
    required bool allowOwnedOnly,
    required Set<String> exclude,
    required String? currentSelectedId,
    HeroConflictIndex? conflictIndex,
    String? slotKey,
  }) {
    final normalizedGroup = group.toLowerCase();
    final source = skills.where((skill) {
      final skillGroup = (skill.data['group'] as String?)?.toLowerCase();
      if (skillGroup != normalizedGroup) return false;
      if (allowOwnedOnly) {
        return reservedSkillIds.contains(skill.id);
      }
      return conflictIndex != null ||
          !reservedSkillIds.contains(skill.id) ||
          skill.id == currentSelectedId;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final options = <SearchOption<String?>>[
      SearchOption<String?>(label: PerksWidgetText.chooseSkill, value: null),
    ];

    for (final skill in source) {
      final blocked = conflictIndex != null && slotKey != null
          ? conflictIndex.isClaimed(
              HeroEntryKey(
                entryType: HeroEntryTypes.skill,
                canonicalEntryId: skill.id,
              ),
              ignoredDraftSlotKey: slotKey,
            )
          : exclude.contains(skill.id);
      if (skill.id != currentSelectedId && blocked) continue;
      options.add(SearchOption<String?>(label: skill.name, value: skill.id));
    }
    return options;
  }

  List<String> _updatedChoiceList(
      List<String> currentChoices, int slotIndex, String? newValue) {
    final updated = List<String>.from(currentChoices);
    while (updated.length <= slotIndex) {
      updated.add('');
    }
    updated[slotIndex] = newValue?.trim() ?? '';
    return updated.where((value) => value.isNotEmpty).toList();
  }

  Future<void> _saveGrantChoice(
    WidgetRef ref,
    String grantType,
    List<String> chosenIds,
  ) async {
    final service = ref.read(perkGrantsServiceProvider);
    await service.saveGrantChoiceAndApply(
      heroId: heroId,
      perkId: perkId,
      grantType: grantType,
      chosenIds: chosenIds,
    );
    onDirty();
    ref.invalidate(perkGrantChoicesProvider((heroId: heroId, perkId: perkId)));
  }

  HeroConflictIndex? _grantConflictIndex(
    WidgetRef ref, {
    required String entryType,
    required String grantType,
    required List<String> chosenIds,
  }) {
    final entries = ref.watch(heroEntriesProvider(heroId)).valueOrNull;
    if (entries == null) return null;
    final perkSource = HeroClaimSource(
      sourceType: HeroEntrySourceTypes.perk,
      sourceId: perkId,
    );

    final draftClaims = chosenIds
        .asMap()
        .entries
        .where((choice) => choice.value.trim().isNotEmpty)
        .map(
          (choice) => HeroEntryClaim(
            key: HeroEntryKey(
              entryType: entryType,
              canonicalEntryId: choice.value,
            ),
            owner: HeroClaimOwner.draft(
              source: perkSource,
              slotKey: _grantSlotKey(grantType, choice.key),
              displayLabel: 'Perk grant',
            ),
          ),
        );
    final parentIndex = entryType == HeroEntryTypes.language
        ? languageConflictIndex
        : entryType == HeroEntryTypes.skill
            ? skillConflictIndex
            : null;
    if (parentIndex != null) {
      return parentIndex.replacing(
        mutationScopes: [
          HeroMutationScope.single(perkSource, entryType: entryType),
        ],
        draftClaims: draftClaims,
      );
    }

    return HeroConflictIndex.projected(
      persistedClaims:
          entries.where((entry) => entry.entryType == entryType).map(
                (entry) => HeroEntryClaim(
                  key: HeroEntryKey(
                    entryType: entry.entryType,
                    canonicalEntryId: entry.entryId,
                  ),
                  owner: HeroClaimOwner.persisted(
                    source: HeroClaimSource(
                      sourceType: entry.sourceType,
                      sourceId: entry.sourceId,
                    ),
                    displayLabel: entry.sourceId.trim().isEmpty
                        ? entry.sourceType
                        : '${entry.sourceType}:${entry.sourceId}',
                  ),
                ),
              ),
      mutationScopes: [
        HeroMutationScope.single(perkSource, entryType: entryType),
      ],
      draftClaims: draftClaims,
    );
  }

  String _grantSlotKey(String grantType, int index) =>
      'perk:$perkId:$grantType#$index';

  Widget _buildGrantRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _buildLoadingRow(Color color, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child:
                CircularProgressIndicator(strokeWidth: 1.5, color: accentColor),
          ),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  int _parseCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _languageGroupTitle(String key) {
    switch (key) {
      case 'ancestral':
        return 'Ancestral Languages';
      case 'dead':
        return 'Dead Languages';
      default:
        return 'Human Languages';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

// ============================================================================
// Searchable Picker - Reusable component
// ============================================================================

/// Represents an option in the searchable picker
class SearchOption<T> {
  const SearchOption({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final T? value;
  final String? subtitle;
}

/// Result of a picker selection
class PickerSelection<T> {
  const PickerSelection({required this.value});

  final T? value;
}

/// Shows a searchable picker dialog
Future<PickerSelection<T>?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<SearchOption<T>> options,
  T? selected,
}) {
  return showDialog<PickerSelection<T>>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = query.trim().toLowerCase();
          final List<SearchOption<T>> filtered = normalizedQuery.isEmpty
              ? options
              : options
                  .where(
                    (option) =>
                        option.label.toLowerCase().contains(normalizedQuery) ||
                        (option.subtitle
                                ?.toLowerCase()
                                .contains(normalizedQuery) ??
                            false),
                  )
                  .toList();

          return Dialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: FormTheme.borderDim),
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
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _perksColor.withValues(alpha: 0.2),
                          _perksColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: _perksColor.withValues(alpha: 0.3),
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
                            color: _perksColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: _perksColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(Icons.auto_awesome,
                              color: _perksColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: _perksColor,
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
                        hintText: PerksWidgetText.searchHint,
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
                          borderSide: BorderSide(color: _perksColor, width: 2),
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
                            padding: const EdgeInsets.all(24),
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
                                  'No matches found',
                                  style: TextStyle(color: FormTheme.textMuted),
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
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _perksColor.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: _perksColor.withValues(
                                              alpha: 0.4))
                                      : null,
                                ),
                                child: ListTile(
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? _perksColor
                                          : FormTheme.textBright,
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : null,
                                    ),
                                  ),
                                  subtitle: option.subtitle != null
                                      ? Text(
                                          option.subtitle!,
                                          style: TextStyle(
                                              color: FormTheme.textMuted),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: _perksColor, size: 22)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    PickerSelection<T>(value: option.value),
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
                      child: Text(PerksWidgetText.cancel),
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
