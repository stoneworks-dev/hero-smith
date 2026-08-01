import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/component.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/strife_theme.dart';
import '../../../core/text/main_pages/strife/abilities_page_text.dart';
import '../../../widgets/abilities/abilities_shared.dart';
import '../../../widgets/abilities/ability_expandable_item.dart';

class AbilitiesPage extends ConsumerWidget {
  const AbilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abilitiesAsync = ref.watch(componentsByTypeProvider('ability'));

    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        backgroundColor: NavigationTheme.navBarBackground,
        foregroundColor: FormTheme.textBright,
        elevation: 0,
        title: Text(AbilitiesPageText.appBarTitle),
      ),
      body: abilitiesAsync.when(
        data: (items) => SafeArea(
          top: false,
          child: _AbilitiesView(items: items),
        ),
        loading: () => const _AbilitiesLoadingState(),
        error: (err, _) => _AbilitiesErrorState(error: err),
      ),
    );
  }
}

class _AbilitiesView extends StatefulWidget {
  const _AbilitiesView({required this.items});

  final List<Component> items;

  @override
  State<_AbilitiesView> createState() => _AbilitiesViewState();
}

class _AbilitiesViewState extends State<_AbilitiesView> {
  String _searchQuery = '';
  String? _resourceFilter;
  String? _costFilter;
  String? _actionTypeFilter;
  String? _distanceFilter;
  String? _targetsFilter;
  String? _classFilter;

  // Cache filter options
  List<String>? _cachedResourceOptions;
  List<String>? _cachedCostOptions;
  List<String>? _cachedActionTypeOptions;
  List<String>? _cachedDistanceOptions;
  List<String>? _cachedTargetsOptions;
  List<String>? _cachedClassOptions;
  List<Component>? _cachedItems;

  List<Component> get _filteredItems {
    var filtered = widget.items;

    // Search by name
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    // Filter by resource type
    if (_resourceFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final resourceLabel = abilityData.resourceLabel?.toLowerCase();
        return resourceLabel == _resourceFilter!.toLowerCase();
      }).toList();
    }

    // Filter by cost
    if (_costFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        if (_costFilter == 'signature') {
          return abilityData.isSignature;
        }
        final cost = abilityData.costAmount;
        if (cost == null) return false;
        return cost.toString() == _costFilter;
      }).toList();
    }

    // Filter by action type
    if (_actionTypeFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final actionType = abilityData.actionType?.toLowerCase();
        return actionType == _actionTypeFilter!.toLowerCase();
      }).toList();
    }

    // Filter by distance
    if (_distanceFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final distance = abilityData.rangeSummary?.toLowerCase();
        return distance?.contains(_distanceFilter!.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by targets
    if (_targetsFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final targets = abilityData.targets?.toLowerCase();
        return targets?.contains(_targetsFilter!.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by class
    if (_classFilter != null) {
      filtered = filtered.where((item) {
        final className = item.data['class_name'] as String?;
        return className?.toLowerCase() == _classFilter!.toLowerCase();
      }).toList();
    }

    return filtered..sort((a, b) => a.name.compareTo(b.name));
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _resourceFilter = null;
      _costFilter = null;
      _actionTypeFilter = null;
      _distanceFilter = null;
      _targetsFilter = null;
      _classFilter = null;
    });
  }

  void _computeFilterOptions() {
    if (_cachedItems == widget.items) return;
    
    _cachedItems = widget.items;
    
    final resourceSet = <String>{};
    final costSet = <String>{};
    final actionTypeSet = <String>{};
    final distanceSet = <String>{};
    final targetsSet = <String>{};
    final classSet = <String>{};

    for (final item in widget.items) {
      final ability = AbilityData.fromComponent(item);
      
      if (ability.resourceLabel?.isNotEmpty ?? false) {
        resourceSet.add(ability.resourceLabel!);
      }
      
      if (ability.isSignature) {
        costSet.add('signature');
      }
      final amount = ability.costAmount;
      if (amount != null && amount > 0) {
        costSet.add(amount.toString());
      }
      
      if (ability.actionType?.isNotEmpty ?? false) {
        actionTypeSet.add(ability.actionType!);
      }
      
      if (ability.rangeSummary?.isNotEmpty ?? false) {
        distanceSet.add(ability.rangeSummary!);
      }
      
      if (ability.targets?.isNotEmpty ?? false) {
        targetsSet.add(ability.targets!);
      }

      final className = item.data['class_name'] as String?;
      if (className != null && className.isNotEmpty) {
        classSet.add(className);
      }
    }

    _cachedResourceOptions = resourceSet.toList()..sort();
    _cachedCostOptions = costSet.toList()..sort((a, b) {
      if (a == 'signature' && b == 'signature') return 0;
      if (a == 'signature') return -1;
      if (b == 'signature') return 1;
      final aInt = int.tryParse(a);
      final bInt = int.tryParse(b);
      if (aInt != null && bInt != null) return aInt.compareTo(bInt);
      return a.compareTo(b);
    });
    _cachedActionTypeOptions = actionTypeSet.toList()..sort();
    _cachedDistanceOptions = distanceSet.toList()..sort();
    _cachedTargetsOptions = targetsSet.toList()..sort();
    _cachedClassOptions = classSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    _computeFilterOptions();
    
    final decoration = _abilitiesBackground(context);
    final filtered = _filteredItems;
    final stats = _AbilitySummaryStats.fromComponents(widget.items);

    if (widget.items.isEmpty) {
      return DecoratedBox(
        decoration: decoration,
        child: const _AbilitiesEmptyState(),
      );
    }

    final hasActiveFilters = _searchQuery.isNotEmpty ||
        _resourceFilter != null ||
        _costFilter != null ||
        _actionTypeFilter != null ||
        _distanceFilter != null ||
        _targetsFilter != null ||
        _classFilter != null;

    return DecoratedBox(
      decoration: decoration,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _AbilitiesSummaryCard(stats: stats),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildSearchAndFilters(
                context,
                resourceOptions: _cachedResourceOptions ?? [],
                costOptions: _cachedCostOptions ?? [],
                actionTypeOptions: _cachedActionTypeOptions ?? [],
                distanceOptions: _cachedDistanceOptions ?? [],
                targetsOptions: _cachedTargetsOptions ?? [],
                classOptions: _cachedClassOptions ?? [],
              ),
            ),
          ),
          if (hasActiveFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildActiveFiltersChips(context),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: FormTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AbilitiesPageText.noAbilitiesMatchFilters,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FormTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: Icon(Icons.clear, color: StrifeTheme.abilitiesAccent),
                        label: Text(AbilitiesPageText.clearFilters, style: TextStyle(color: StrifeTheme.abilitiesAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AbilityExpandableItem(component: filtered[index]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context, {
    required List<String> resourceOptions,
    required List<String> costOptions,
    required List<String> actionTypeOptions,
    required List<String> distanceOptions,
    required List<String> targetsOptions,
    required List<String> classOptions,
  }) {
    final accent = StrifeTheme.abilitiesAccent;

    return Card(
      elevation: 4,
      color: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            TextField(
              style: TextStyle(color: Colors.grey.shade200),
              decoration: InputDecoration(
                hintText: AbilitiesPageText.searchHint,
                hintStyle: TextStyle(color: FormTheme.textMuted),
                prefixIcon: Icon(Icons.search, color: FormTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: FormTheme.textSecondary),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: FormTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FormTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            // Filters
            Text(
              AbilitiesPageText.filtersLabel,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.resourceFilter,
                  value: _resourceFilter,
                  options: resourceOptions,
                  onChanged: (value) => setState(() => _resourceFilter = value),
                ),
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.costFilter,
          value: _costFilter == null
            ? null
            : (_costFilter == 'signature'
              ? 'Signature'
              : _costFilter),
                  options: costOptions
                      .map((c) => c == 'signature' ? 'Signature' : c)
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (value == null) {
                      _costFilter = null;
                    } else if (value.toLowerCase() == 'signature') {
                      _costFilter = 'signature';
                    } else {
                      _costFilter = value;
                    }
                  }),
                ),
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.actionFilter,
                  value: _actionTypeFilter,
                  options: actionTypeOptions,
                  onChanged: (value) => setState(() => _actionTypeFilter = value),
                ),
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.distanceFilter,
                  value: _distanceFilter,
                  options: distanceOptions,
                  onChanged: (value) => setState(() => _distanceFilter = value),
                ),
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.targetsFilter,
                  value: _targetsFilter,
                  options: targetsOptions,
                  onChanged: (value) => setState(() => _targetsFilter = value),
                ),
                _buildFilterDropdown(
                  context,
                  label: AbilitiesPageText.classFilter,
                  value: _classFilter,
                  options: classOptions,
                  onChanged: (value) => setState(() => _classFilter = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    final accent = StrifeTheme.abilitiesAccent;

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: NavigationTheme.cardBackgroundDark,
        border: Border.all(
          color: value != null ? accent : FormTheme.border,
          width: value != null ? 2 : 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          label,
          style: TextStyle(color: FormTheme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        underline: const SizedBox.shrink(),
        isDense: true,
        isExpanded: true,
        dropdownColor: NavigationTheme.cardBackgroundDark,
        style: TextStyle(
          color: FormTheme.textSecondary,
          fontSize: 14,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: value != null ? accent : FormTheme.textMuted,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(AbilitiesPageText.allFilterLabel(label), overflow: TextOverflow.ellipsis),
          ),
          ...options.map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context) {
    final chips = <Widget>[];

    if (_searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.nameFilter(_searchQuery),
        onRemove: () => setState(() => _searchQuery = ''),
      ));
    }

    if (_resourceFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.resourceFilterChip(_resourceFilter!),
        onRemove: () => setState(() => _resourceFilter = null),
      ));
    }

    if (_costFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: _costFilter == 'signature'
            ? AbilitiesPageText.costSignature
            : AbilitiesPageText.costFilterChip(_costFilter!),
        onRemove: () => setState(() => _costFilter = null),
      ));
    }

    if (_actionTypeFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.actionFilterChip(_actionTypeFilter!),
        onRemove: () => setState(() => _actionTypeFilter = null),
      ));
    }

    if (_distanceFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.distanceFilterChip(_distanceFilter!),
        onRemove: () => setState(() => _distanceFilter = null),
      ));
    }

    if (_targetsFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.targetsFilterChip(_targetsFilter!),
        onRemove: () => setState(() => _targetsFilter = null),
      ));
    }

    if (_classFilter != null) {
      chips.add(_buildFilterChip(
        context,
        label: AbilitiesPageText.classFilterChip(_classFilter!),
        onRemove: () => setState(() => _classFilter = null),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    final accent = StrifeTheme.abilitiesAccent;

    return Card(
      elevation: StrifeTheme.cardElevation,
      color: NavigationTheme.cardBackgroundDark,
      shape: const RoundedRectangleBorder(borderRadius: StrifeTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AbilitiesPageText.activeFiltersLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade200,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear_all, size: 16, color: accent),
                  label: Text(AbilitiesPageText.clearAll, style: TextStyle(color: accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    final accent = StrifeTheme.abilitiesAccent;

    return Chip(
      label: Text(label, style: TextStyle(color: Colors.grey.shade200)),
      deleteIcon: Icon(Icons.close, size: 18, color: FormTheme.textSecondary),
      onDeleted: onRemove,
      backgroundColor: accent.withValues(alpha: 0.15),
      side: BorderSide(color: accent.withValues(alpha: 0.4)),
    );
  }
}

class _AbilitiesSummaryCard extends StatelessWidget {
  const _AbilitiesSummaryCard({required this.stats});

  final _AbilitySummaryStats stats;

  @override
  Widget build(BuildContext context) {
    final accent = StrifeTheme.abilitiesAccent;
    
    return Card(
      elevation: 4,
      color: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with accent stripe style
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.2),
                  accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.3), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: NavigationTheme.cardIconDecoration(accent),
                  child: Icon(Icons.bolt, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AbilitiesPageText.abilityLibraryTitle,
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AbilitiesPageText.browseAbilities(stats.total),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatChip(
                  context,
                  icon: Icons.auto_awesome,
                  label: AbilitiesPageText.totalAbilities,
                  value: stats.total.toString(),
                ),
                _buildStatChip(
                  context,
                  icon: Icons.star_border,
                  label: AbilitiesPageText.signatureNoCost,
                  value: stats.signatureCount.toString(),
                ),
                _buildStatChip(
                  context,
                  icon: Icons.flash_on,
                  label: AbilitiesPageText.costedAbilities,
                  value: stats.costedCount.toString(),
                ),
                _buildStatChip(
                  context,
                  icon: Icons.science_outlined,
                  label: AbilitiesPageText.resourceTypes,
                  value: stats.resourceTypeCount.toString(),
                ),
                _buildStatChip(
                  context,
                  icon: Icons.trending_up,
                  label: AbilitiesPageText.highestCost,
                  value: stats.highestCost?.toString() ?? '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final accent = StrifeTheme.abilitiesAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: FormTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilitiesEmptyState extends StatelessWidget {
  const _AbilitiesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: StrifeTheme.cardElevation,
          color: NavigationTheme.cardBackgroundDark,
          shape: const RoundedRectangleBorder(borderRadius: StrifeTheme.cardRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StrifeTheme.sectionHeader(
                context,
                title: AbilitiesPageText.noAbilitiesFound,
                subtitle: AbilitiesPageText.checkDataSeed,
                icon: Icons.info_outline,
                accent: StrifeTheme.abilitiesAccent,
              ),
              Padding(
                padding: StrifeTheme.cardPadding,
                child: Text(
                  AbilitiesPageText.noAbilitiesBody,
                  style: TextStyle(color: FormTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbilitiesLoadingState extends StatelessWidget {
  const _AbilitiesLoadingState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _abilitiesBackground(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: StrifeTheme.abilitiesAccent),
            const SizedBox(height: 16),
            Text(
              AbilitiesPageText.loadingAbilities,
              style: TextStyle(color: FormTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilitiesErrorState extends StatelessWidget {
  const _AbilitiesErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error.toString();

    return DecoratedBox(
      decoration: _abilitiesBackground(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: StrifeTheme.cardElevation,
            color: NavigationTheme.cardBackgroundDark,
            shape: const RoundedRectangleBorder(borderRadius: StrifeTheme.cardRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StrifeTheme.sectionHeader(
                  context,
                  title: AbilitiesPageText.unableToLoad,
                  subtitle: AbilitiesPageText.tryAgain,
                  icon: Icons.error_outline,
                  accent: StrifeTheme.abilitiesAccent,
                ),
                Padding(
                  padding: StrifeTheme.cardPadding,
                  child: Text(
                    message,
                    style: TextStyle(color: FormTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AbilitySummaryStats {
  const _AbilitySummaryStats({
    required this.total,
    required this.signatureCount,
    required this.costedCount,
    required this.highestCost,
    required this.resourceTypeCount,
  });

  factory _AbilitySummaryStats.fromComponents(List<Component> components) {
    var signature = 0;
    var costed = 0;
    int? highestCost;
    final resourceTypes = <String>{};

    for (final component in components) {
      final abilityData = AbilityData.fromComponent(component);
      final cost = abilityData.costAmount;

      if (abilityData.isSignature || cost == null || cost <= 0) {
        signature += 1;
      } else {
        costed += 1;
        if (highestCost == null || cost > highestCost) {
          highestCost = cost;
        }
      }

      final resourceLabel = abilityData.resourceLabel;
      if (resourceLabel != null && resourceLabel.isNotEmpty) {
        resourceTypes.add(resourceLabel);
      }
    }

    return _AbilitySummaryStats(
      total: components.length,
      signatureCount: signature,
      costedCount: costed,
      highestCost: highestCost,
      resourceTypeCount: resourceTypes.length,
    );
  }

  final int total;
  final int signatureCount;
  final int costedCount;
  final int? highestCost;
  final int resourceTypeCount;
}

BoxDecoration _abilitiesBackground(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        StrifeTheme.abilitiesAccent.withValues(alpha: 0.08),
        theme.colorScheme.surface,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}
