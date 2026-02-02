import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/repositories/hero_entry_repository.dart';

import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/semantic/hero_entry_tokens.dart';
import '../../../core/text/heroes_sheet/abilities/sheet_abilities_text.dart';
import 'ability_list_view.dart';
import 'add_ability_dialog.dart';
import 'common_abilities_view.dart';
import 'sheet_abilities_providers.dart';

// Re-export providers for backwards compatibility
export 'sheet_abilities_providers.dart';

/// Shows active, passive, and situational abilities available to the hero.
class SheetAbilities extends ConsumerStatefulWidget {
  const SheetAbilities({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<SheetAbilities> createState() => _SheetAbilitiesState();
}

class _SheetAbilitiesState extends ConsumerState<SheetAbilities> {
  bool _perkGrantsEnsured = false;

  @override
  void initState() {
    super.initState();
    _ensurePerkGrants();
  }

  /// Ensure all perk grants are applied when the abilities sheet loads.
  /// This handles cases where perks were added outside the PerksSelectionWidget.
  Future<void> _ensurePerkGrants() async {
    if (_perkGrantsEnsured) return;
    _perkGrantsEnsured = true;

    try {
      final service = ref.read(perkGrantsServiceProvider);
      await service.ensureAllPerkGrantsApplied(
        heroId: widget.heroId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to ensure perk grants: $e');
      }
    }
  }

  Future<void> _showAddAbilityDialog(BuildContext context) async {
    final selectedAbilityId = await showDialog<String?>(
      context: context,
      builder: (context) => AddAbilityDialog(heroId: widget.heroId),
    );

    if (selectedAbilityId != null && mounted) {
      await _addAbilityToHero(selectedAbilityId);
    }
  }

  Future<void> _addAbilityToHero(String abilityId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final entries = HeroEntryRepository(db);

      // Check if ability is already added with manual_choice source
      final existingEntries = await entries.listEntriesByType(
          widget.heroId, HeroEntryTypes.ability);
      final alreadyAdded = existingEntries.any(
        (e) =>
            e.entryId == abilityId &&
            e.sourceType == HeroEntrySourceTypes.manualChoice,
      );

      if (alreadyAdded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(SheetAbilitiesText.snackAbilityAlreadyAdded)),
          );
        }
        return;
      }

      // Add ability to hero_entries with sourceType='manual_choice'
      await entries.addEntry(
        heroId: widget.heroId,
        entryType: HeroEntryTypes.ability,
        entryId: abilityId,
        sourceType: HeroEntrySourceTypes.manualChoice,
        sourceId: HeroEntrySourceIds.sheetAdd,
        gainedBy: HeroEntryGainedBy.choice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SheetAbilitiesText.snackAbilityAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${SheetAbilitiesText.snackAbilityAddFailedPrefix}$e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ability IDs stream
    final abilityIdsAsync = ref.watch(heroAbilityIdsProvider(widget.heroId));
    final theme = Theme.of(context);

    // Tab data with icons and colors
    const tabData = [
      (
        icon: Icons.bolt,
        label: SheetAbilitiesText.tabHeroAbilities,
        color: NavigationTheme.abilitiesColor
      ),
      (
        icon: Icons.public,
        label: SheetAbilitiesText.tabCommonAbilities,
        color: NavigationTheme.featuresColor
      ),
    ];

    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              return Column(
                children: [
                  // Custom styled tab bar - only this rebuilds on tab change
                  AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      return Container(
                        color: NavigationTheme.navBarBackground,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(
                          children: List.generate(tabData.length, (index) {
                            final tab = tabData[index];
                            final isSelected = tabController.index == index;
                            final color = isSelected
                                ? tab.color
                                : NavigationTheme.inactiveColor;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => tabController.animateTo(index),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: isSelected
                                      ? NavigationTheme
                                          .selectedNavItemDecoration(tab.color)
                                      : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tab.icon,
                                        color: color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          tab.label,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                  // TabBarView - outside AnimatedBuilder to avoid rebuild
                  Expanded(
                    child: Container(
                      color: NavigationTheme.cardBackgroundDark,
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          // Hero-specific abilities tab
                          abilityIdsAsync.when(
                            data: (abilityIds) {
                              if (abilityIds.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bolt_outlined,
                                            size: 48,
                                            color: Colors.grey.shade600),
                                        const SizedBox(height: 12),
                                        Text(
                                          SheetAbilitiesText.emptyHeroTitle,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          SheetAbilitiesText.emptyHeroSubtitle,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return AbilityListView(
                                abilityIds: abilityIds,
                                heroId: widget.heroId,
                              );
                            },
                            loading: () => Center(
                                child: CircularProgressIndicator(
                                    color: NavigationTheme.abilitiesColor)),
                            error: (error, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Colors.red),
                                    const SizedBox(height: 12),
                                    Text(
                                      SheetAbilitiesText.errorTitle,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      error.toString(),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Common abilities tab
                          const CommonAbilitiesView(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // Floating Action Button for adding abilities
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'sheet_abilities_fab',
            onPressed: () => _showAddAbilityDialog(context),
            tooltip: SheetAbilitiesText.addAbilityTooltip,
            backgroundColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  BorderSide(color: NavigationTheme.abilitiesColor, width: 1.5),
            ),
            child: Icon(Icons.add,
                color: NavigationTheme.abilitiesColor, size: 20),
          ),
        ),
      ],
    );
  }
}
