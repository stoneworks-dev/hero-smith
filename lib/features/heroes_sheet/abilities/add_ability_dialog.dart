import 'package:flutter/material.dart';

import '../../../core/models/component.dart';
import '../../../core/services/ability_data_service.dart';
import '../../../core/text/heroes_sheet/abilities/add_ability_dialog_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';
import '../../../widgets/abilities/abilities_shared.dart';
import '../../../widgets/abilities/ability_filter_dropdown.dart';
import '../../../widgets/abilities/ability_summary.dart';

/// Dialog for adding abilities to a hero with search and filters.
/// 
/// Provides ability search by name and filtering by:
/// - Resource type
/// - Cost amount
/// - Action type
/// - Distance
/// - Targets
class AddAbilityDialog extends StatefulWidget {
  const AddAbilityDialog({
    super.key,
    required this.heroId,
    this.loadLibraryOverride,
  });

  final String heroId;
  final Future<AbilityLibrary> Function()? loadLibraryOverride;

  @override
  State<AddAbilityDialog> createState() => _AddAbilityDialogState();
}

class _AddAbilityDialogState extends State<AddAbilityDialog> {
  String _searchQuery = '';
  String? _resourceFilter;
  String? _costFilter;
  String? _actionTypeFilter;
  String? _distanceFilter;
  String? _targetsFilter;
  List<Component>? _allAbilities;
  bool _isLoading = false;

  List<Component> get _filteredItems {
    if (_allAbilities == null) return [];
    
    var filtered = _allAbilities!;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) => item.name.toLowerCase().contains(query)).toList();
    }

    if (_resourceFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final resourceLabel = abilityData.resourceLabel?.toLowerCase();
        return resourceLabel == _resourceFilter!.toLowerCase();
      }).toList();
    }

    if (_costFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        if (_costFilter == 'signature') return abilityData.isSignature;
        final cost = abilityData.costAmount;
        if (cost == null) return false;
        return cost.toString() == _costFilter;
      }).toList();
    }

    if (_actionTypeFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final actionType = abilityData.actionType?.toLowerCase();
        return actionType == _actionTypeFilter!.toLowerCase();
      }).toList();
    }

    if (_distanceFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final distance = abilityData.rangeSummary?.toLowerCase();
        return distance?.contains(_distanceFilter!.toLowerCase()) ?? false;
      }).toList();
    }

    if (_targetsFilter != null) {
      filtered = filtered.where((item) {
        final abilityData = AbilityData.fromComponent(item);
        final targets = abilityData.targets?.toLowerCase();
        return targets?.contains(_targetsFilter!.toLowerCase()) ?? false;
      }).toList();
    }

    return filtered..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _loadAbilities() async {
    if (_isLoading || _allAbilities != null) return;
    setState(() => _isLoading = true);
    try {
      final loader = widget.loadLibraryOverride ?? AbilityDataService().loadLibrary;
      final library = await loader();
      setState(() {
        _allAbilities = library.components.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _triggerSearch() {
    // Load abilities if they haven't been loaded yet and user has interacted with search/filters
    if (_allAbilities == null) {
      _loadAbilities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    
    // Extract unique filter options (only if abilities are loaded)
    final resourceOptions = _allAbilities
            ?.map((item) => AbilityData.fromComponent(item).resourceLabel)
            .where((type) => type != null && type.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList() ??
        [];
    if (resourceOptions.isNotEmpty) resourceOptions.sort();
    
    final costSet = <String>{};
    if (_allAbilities != null) {
      for (final item in _allAbilities!) {
        final ability = AbilityData.fromComponent(item);
        if (ability.isSignature) costSet.add('signature');
        final amount = ability.costAmount;
        if (amount != null && amount > 0) costSet.add(amount.toString());
      }
    }
    final costOptions = costSet.toList()..sort((a, b) {
      if (a == 'signature' && b == 'signature') return 0;
      if (a == 'signature') return -1;
      if (b == 'signature') return 1;
      final aInt = int.tryParse(a);
      final bInt = int.tryParse(b);
      if (aInt != null && bInt != null) return aInt.compareTo(bInt);
      return a.compareTo(b);
    });
    
    final actionTypeOptions = _allAbilities
            ?.map((item) => AbilityData.fromComponent(item).actionType)
            .where((type) => type != null && type.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList() ??
        [];
    if (actionTypeOptions.isNotEmpty) actionTypeOptions.sort();
    
    final distanceOptions = _allAbilities
            ?.map((item) => AbilityData.fromComponent(item).rangeSummary)
            .where((dist) => dist != null && dist.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList() ??
        [];
    if (distanceOptions.isNotEmpty) distanceOptions.sort();
    
    final targetsOptions = _allAbilities
            ?.map((item) => AbilityData.fromComponent(item).targets)
            .where((targets) => targets != null && targets.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList() ??
        [];
    if (targetsOptions.isNotEmpty) targetsOptions.sort();

    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      child: Container(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            AppBar(
              title: const Text(AddAbilityDialogText.dialogTitle, style: TextStyle(color: Colors.white)),
              backgroundColor: NavigationTheme.navBarBackground,
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop())],
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchAndFilters(
                        context, 
                        resourceOptions: resourceOptions, 
                        costOptions: costOptions, 
                        actionTypeOptions: actionTypeOptions, 
                        distanceOptions: distanceOptions, 
                        targetsOptions: targetsOptions,
                      ),
                    ),
                  ),
                  if (_isLoading) 
                    SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: NavigationTheme.abilitiesColor)))
                  else if (_allAbilities == null) 
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24), 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey.shade600), 
                              const SizedBox(height: 16), 
                              Text(
                                AddAbilityDialogText.searchPrompt, 
                                style: TextStyle(color: Colors.grey.shade400), 
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (filtered.isEmpty) 
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24), 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade600), 
                              const SizedBox(height: 16), 
                              Text(
                                AddAbilityDialogText.noAbilitiesFound,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else 
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAbilitySummaryCard(filtered[index]), 
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbilitySummaryCard(Component ability) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: FormTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(ability.id), 
        borderRadius: BorderRadius.circular(12), 
        child: Padding(
          padding: const EdgeInsets.all(16), 
          child: AbilitySummary(component: ability),
        ),
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
  }) {
    final isEnabled = _allAbilities != null;
    return Card(
      color: FormTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: NavigationTheme.abilitiesColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AddAbilityDialogText.searchHint,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: NavigationTheme.abilitiesColor),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400), 
                        onPressed: () { setState(() => _searchQuery = ''); },
                      ) 
                    : null, 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NavigationTheme.abilitiesColor, width: 2),
                ),
              ), 
              onChanged: (value) { 
                setState(() => _searchQuery = value); 
                if (!isEnabled) _triggerSearch();
              },
            ), 
            const SizedBox(height: 16), 
            Text(
              AddAbilityDialogText.filtersTitle,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade300),
            ), 
            const SizedBox(height: 12), 
            Wrap(
              spacing: 8, 
              runSpacing: 8, 
              children: [
                GestureDetector(
                  onTap: !isEnabled ? _triggerSearch : null,
                  child: AbilityFilterDropdown(
                    label: AddAbilityDialogText.filterResourceLabel, 
                    value: _resourceFilter, 
                    options: resourceOptions, 
                    enabled: isEnabled,
                    allLabelPrefix: AddAbilityDialogText.allFilterPrefix,
                    onChanged: (value) { 
                      setState(() => _resourceFilter = value); 
                      _triggerSearch(); 
                    },
                  ),
                ), 
                GestureDetector(
                  onTap: !isEnabled ? _triggerSearch : null,
                  child: AbilityFilterDropdown(
                    label: AddAbilityDialogText.filterCostLabel, 
                    value: _costFilter == null
                        ? null
                        : (_costFilter == 'signature'
                            ? AddAbilityDialogText.signatureLabel
                            : _costFilter), 
                    options: costOptions
                        .map((c) => c == 'signature'
                            ? AddAbilityDialogText.signatureLabel
                            : c)
                        .toList(), 
                    enabled: isEnabled,
                    allLabelPrefix: AddAbilityDialogText.allFilterPrefix,
                    onChanged: (value) { 
                      setState(
                        () => _costFilter =
                            value == AddAbilityDialogText.signatureLabel
                                ? 'signature'
                                : value,
                      ); 
                      _triggerSearch(); 
                    },
                  ),
                ), 
                GestureDetector(
                  onTap: !isEnabled ? _triggerSearch : null,
                  child: AbilityFilterDropdown(
                    label: AddAbilityDialogText.filterActionTypeLabel, 
                    value: _actionTypeFilter, 
                    options: actionTypeOptions, 
                    enabled: isEnabled,
                    allLabelPrefix: AddAbilityDialogText.allFilterPrefix,
                    onChanged: (value) { 
                      setState(() => _actionTypeFilter = value); 
                      _triggerSearch(); 
                    },
                  ),
                ), 
                GestureDetector(
                  onTap: !isEnabled ? _triggerSearch : null,
                  child: AbilityFilterDropdown(
                    label: AddAbilityDialogText.filterDistanceLabel, 
                    value: _distanceFilter, 
                    options: distanceOptions, 
                    enabled: isEnabled,
                    allLabelPrefix: AddAbilityDialogText.allFilterPrefix,
                    onChanged: (value) { 
                      setState(() => _distanceFilter = value); 
                      _triggerSearch(); 
                    },
                  ),
                ), 
                GestureDetector(
                  onTap: !isEnabled ? _triggerSearch : null,
                  child: AbilityFilterDropdown(
                    label: AddAbilityDialogText.filterTargetsLabel, 
                    value: _targetsFilter, 
                    options: targetsOptions, 
                    enabled: isEnabled,
                    allLabelPrefix: AddAbilityDialogText.allFilterPrefix,
                    onChanged: (value) { 
                      setState(() => _targetsFilter = value); 
                      _triggerSearch(); 
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
