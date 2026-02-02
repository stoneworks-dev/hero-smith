import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/downtime_data_source.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/models/downtime.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/gear/treasures_tab_text.dart';
import '../../../widgets/treasures/treasures.dart';
import 'gear_dialogs.dart';
import 'gear_utils.dart';
import 'gear_widgets.dart';

/// Treasures tab for the gear sheet.
class TreasuresTab extends ConsumerStatefulWidget {
  const TreasuresTab({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<TreasuresTab> createState() => _TreasuresTabState();
}

class _TreasuresTabState extends ConsumerState<TreasuresTab> {
  List<model.Component> _allTreasures = [];
  List<DowntimeEntry> _allImbuements = [];
  bool _isLoadingTreasures = true;
  String? _error;
  StreamSubscription<Map<String, Map<String, dynamic>>>?
      _treasureEntriesSubscription;
  StreamSubscription<List<String>>? _imbuementIdsSubscription;

  /// Map of treasureId -> {quantity: int, ...other payload data}
  Map<String, Map<String, dynamic>> _heroTreasureEntries = {};
  List<String> _heroImbuementIds = [];

  @override
  void initState() {
    super.initState();
    _loadAllTreasures();
    _loadAllImbuements();
    _watchHeroTreasureEntries();
    _watchHeroImbuementIds();
  }

  @override
  void dispose() {
    _treasureEntriesSubscription?.cancel();
    _imbuementIdsSubscription?.cancel();
    super.dispose();
  }

  void _watchHeroTreasureEntries() {
    final db = ref.read(appDatabaseProvider);
    _treasureEntriesSubscription =
        db.watchHeroEntriesWithPayload(widget.heroId, 'treasure').listen(
      (entries) {
        if (mounted) {
          setState(() {
            _heroTreasureEntries = entries;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = '${TreasuresTabText.watchTreasuresFailedPrefix}$e';
          });
        }
      },
    );
  }

  void _watchHeroImbuementIds() {
    final db = ref.read(appDatabaseProvider);
    _imbuementIdsSubscription =
        db.watchHeroComponentIds(widget.heroId, 'imbuement').listen(
      (ids) {
        if (mounted) {
          setState(() {
            _heroImbuementIds = ids;
          });
        }
      },
      onError: (e) {
        // Ignore imbuement errors - they're optional
      },
    );
  }

  Future<void> _loadAllImbuements() async {
    try {
      final dataSource = DowntimeDataSource();
      final imbuements = await dataSource.loadImbuements();
      if (mounted) {
        setState(() {
          _allImbuements = imbuements;
        });
      }
    } catch (e) {
      // Ignore imbuement loading errors - they're optional
    }
  }

  Future<void> _loadAllTreasures() async {
    try {
      // Load all treasures from all types
      final allComponents = await ref.read(allComponentsProvider.future);
      final treasures = allComponents
          .where((c) =>
              c.type == 'consumable' ||
              c.type == 'trinket' ||
              c.type == 'artifact' ||
              c.type == 'leveled_treasure')
          .toList();

      if (mounted) {
        setState(() {
          _allTreasures = treasures..sort((a, b) => a.name.compareTo(b.name));
          _isLoadingTreasures = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTreasures = false;
          _error = '${TreasuresTabText.loadTreasuresFailedPrefix}$e';
        });
      }
    }
  }

  /// Get the quantity of a treasure from entries.
  int _getTreasureQuantity(String treasureId) {
    final entry = _heroTreasureEntries[treasureId];
    return entry?['quantity'] as int? ?? 1;
  }

  /// Check if a treasure is equipped.
  bool _isTreasureEquipped(String treasureId) {
    final entry = _heroTreasureEntries[treasureId];
    return entry?['equipped'] as bool? ?? false;
  }

  /// Toggle equip state for a treasure.
  Future<void> _toggleEquip(String treasureId, String treasureType) async {
    final db = ref.read(appDatabaseProvider);
    final isCurrentlyEquipped = _isTreasureEquipped(treasureId);
    final willBeEquipped = !isCurrentlyEquipped;

    // Check for leveled treasure jealousy warning
    if (willBeEquipped && treasureType.toLowerCase() == 'leveled_treasure') {
      final equippedLeveledCount = _countEquippedLeveledTreasures();
      // Show warning if equipping a 4th leveled treasure (already have 3)
      if (equippedLeveledCount >= 3) {
        _showJealousyWarning();
      }
    }

    try {
      final existingPayload = Map<String, dynamic>.from(
        _heroTreasureEntries[treasureId] ?? {},
      );
      existingPayload['equipped'] = willBeEquipped;

      await db.updateHeroEntryPayload(
        heroId: widget.heroId,
        entryType: 'treasure',
        entryId: treasureId,
        payload: existingPayload,
      );
      
      // Recalculate and save equipped treasure bonuses
      await _recalculateEquippedBonuses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.toggleEquipFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Recalculate equipped treasure bonuses and save to hero values.
  Future<void> _recalculateEquippedBonuses() async {
    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final treasureBonusService = ref.read(treasureBonusServiceProvider);
      final heroLevel = await heroRepo.getHeroLevel(widget.heroId);
      
      await treasureBonusService.recalculateAndSaveEquippedBonuses(
        widget.heroId,
        heroLevel,
      );
    } catch (e) {
      // Silently ignore bonus calculation errors
    }
  }

  /// Count how many leveled treasures are currently equipped.
  int _countEquippedLeveledTreasures() {
    int count = 0;
    for (final entry in _heroTreasureEntries.entries) {
      final treasureId = entry.key;
      final payload = entry.value;
      final isEquipped = payload['equipped'] as bool? ?? false;
      if (isEquipped) {
        // Find the treasure to check its type
        final treasure = _allTreasures.firstWhere(
          (t) => t.id == treasureId,
          orElse: () => _allTreasures.first,
        );
        if (treasure.type.toLowerCase() == 'leveled_treasure') {
          count++;
        }
      }
    }
    return count;
  }

  /// Show warning about leveled treasure jealousy.
  void _showJealousyWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400),
            const SizedBox(width: 8),
            const Text(TreasuresTabText.jealousyWarningTitle),
          ],
        ),
        content: const Text(TreasuresTabText.jealousyWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(TreasuresTabText.jealousyWarningDismiss),
          ),
        ],
      ),
    );
  }

  Future<void> _addTreasure(String treasureId) async {
    final db = ref.read(appDatabaseProvider);

    // Check if treasure already exists - if so, increment quantity
    if (_heroTreasureEntries.containsKey(treasureId)) {
      final currentQty = _getTreasureQuantity(treasureId);
      await _updateTreasureQuantity(treasureId, currentQty + 1);
      return;
    }

    try {
      // Add new treasure with quantity 1
      await db.addHeroEntryWithPayload(
        heroId: widget.heroId,
        entryType: 'treasure',
        entryId: treasureId,
        payload: {'quantity': 1},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.addTreasureFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTreasureQuantity(
      String treasureId, int newQuantity) async {
    final db = ref.read(appDatabaseProvider);

    try {
      if (newQuantity <= 0) {
        // Remove the treasure entirely
        await _removeTreasure(treasureId);
        return;
      }

      // Update the payload with new quantity
      final existingPayload = Map<String, dynamic>.from(
        _heroTreasureEntries[treasureId] ?? {},
      );
      existingPayload['quantity'] = newQuantity;

      await db.updateHeroEntryPayload(
        heroId: widget.heroId,
        entryType: 'treasure',
        entryId: treasureId,
        payload: existingPayload,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.updateQuantityFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _incrementTreasure(String treasureId) async {
    final currentQty = _getTreasureQuantity(treasureId);
    await _updateTreasureQuantity(treasureId, currentQty + 1);
  }

  Future<void> _decrementTreasure(String treasureId) async {
    final currentQty = _getTreasureQuantity(treasureId);
    if (currentQty <= 1) {
      await _removeTreasure(treasureId);
    } else {
      await _updateTreasureQuantity(treasureId, currentQty - 1);
    }
  }

  Future<void> _removeTreasure(String treasureId) async {
    final db = ref.read(appDatabaseProvider);

    try {
      // Delete the entry entirely
      await db.clearHeroEntryType(widget.heroId, 'treasure');
      // Re-add remaining treasures
      final remaining =
          Map<String, Map<String, dynamic>>.from(_heroTreasureEntries);
      remaining.remove(treasureId);
      for (final entry in remaining.entries) {
        await db.addHeroEntryWithPayload(
          heroId: widget.heroId,
          entryType: 'treasure',
          entryId: entry.key,
          payload: entry.value,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.removeTreasureFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddTreasureDialog() {
    // Show all treasures - user can add more of the same (increases quantity)
    final availableTreasures = _allTreasures;
    final availableImbuements =
        _allImbuements.where((i) => !_heroImbuementIds.contains(i.id)).toList();

    showDialog(
      context: context,
      builder: (context) => AddTreasureDialog(
        availableTreasures: availableTreasures,
        availableImbuements: availableImbuements,
        onTreasureSelected: (treasureId) {
          _addTreasure(treasureId);
          Navigator.of(context).pop();
        },
        onImbuementSelected: (imbuementId) {
          _addImbuement(imbuementId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _addImbuement(String imbuementId) async {
    if (_heroImbuementIds.contains(imbuementId)) return;

    final db = ref.read(appDatabaseProvider);
    final updated = [..._heroImbuementIds, imbuementId];

    try {
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'imbuement',
        componentIds: updated,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.addImbuementFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImbuementsInfoDialog() async {
    final treasureBonusService = ref.read(treasureBonusServiceProvider);
    final description = await treasureBonusService.loadImbuementsDescription();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TreasuresTabText.imbuementsInfoDialogTitle,
          style: TextStyle(color: NavigationTheme.imbuementsTabColor),
        ),
        content: SingleChildScrollView(
          child: Text(
            description.isNotEmpty
                ? description
                : 'No description available.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(TreasuresTabText.closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTreasures) {
      return Center(
          child:
              CircularProgressIndicator(color: NavigationTheme.treasureColor));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get treasures that the hero has (using entries map)
    final heroTreasureIds = _heroTreasureEntries.keys.toSet();
    final heroTreasures =
        _allTreasures.where((t) => heroTreasureIds.contains(t.id)).toList();

    // Get hero's imbuements
    final heroImbuements =
        _allImbuements.where((e) => _heroImbuementIds.contains(e.id)).toList();

    // Group treasures by type
    final groupedTreasures = <String, List<model.Component>>{};
    for (final treasure in heroTreasures) {
      final groupKey = getTreasureGroupName(treasure.type);
      groupedTreasures.putIfAbsent(groupKey, () => []).add(treasure);
    }

    // Total count includes sum of all quantities plus imbuements
    final totalTreasureCount = _heroTreasureEntries.values.fold<int>(
      0,
      (sum, entry) => sum + (entry['quantity'] as int? ?? 1),
    );
    final totalCount = totalTreasureCount + heroImbuements.length;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Text(
                    '${TreasuresTabText.treasuresAndImbuementsHeaderPrefix}$totalCount${TreasuresTabText.treasuresAndImbuementsHeaderSuffix}',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: (heroTreasures.isEmpty && heroImbuements.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            TreasuresTabText.emptyStateMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Imbuements section (if any)
                        if (heroImbuements.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  TreasuresTabText.itemImbuementsHeader,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: NavigationTheme.imbuementsTabColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: NavigationTheme.imbuementsTabColor,
                                  ),
                                  tooltip: TreasuresTabText.imbuementsInfoTooltip,
                                  onPressed: _showImbuementsInfoDialog,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          ...heroImbuements.map((imbuement) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Stack(
                                children: [
                                  ImbuementCard(imbuement: imbuement),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.white70, size: 20),
                                      onPressed: () =>
                                          _removeImbuement(imbuement.id),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.black.withValues(alpha: 0.6),
                                        padding: const EdgeInsets.all(6),
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Treasures sections
                        ...groupedTreasures.entries.map((entry) {
                          final groupName = entry.key;
                          final treasures = entry.value;
                          // Get color from first treasure in group (all same type)
                          final sectionColor = _getTreasureGroupColor(
                              treasures.isNotEmpty ? treasures.first.type : '');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: sectionColor,
                                  ),
                                ),
                              ),
                              ...treasures.map((treasure) {
                                final quantity =
                                    _getTreasureQuantity(treasure.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildTreasureCard(treasure, quantity),
                                );
                              }),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
        // Floating Action Button for adding treasures
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'treasures_tab_fab',
            onPressed: _showAddTreasureDialog,
            tooltip: TreasuresTabText.addButtonLabel,
            backgroundColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  BorderSide(color: NavigationTheme.treasureColor, width: 1.5),
            ),
            child:
                Icon(Icons.add, color: NavigationTheme.treasureColor, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _removeImbuement(String imbuementId) async {
    final db = ref.read(appDatabaseProvider);
    final updated = _heroImbuementIds.where((id) => id != imbuementId).toList();

    try {
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'imbuement',
        componentIds: updated,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TreasuresTabText.removeImbuementFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTreasureCard(model.Component treasure, int quantity) {
    final isEquipped = _isTreasureEquipped(treasure.id);
    final isEquipable = treasure.type.toLowerCase() != 'consumable';
    
    // Use the unified TreasureCard with quantity controls
    return TreasureCard(
      component: treasure,
      quantity: quantity,
      showQuantityControls: true,
      showEquipToggle: isEquipable,
      isEquipped: isEquipped,
      onToggleEquip: () => _toggleEquip(treasure.id, treasure.type),
      onIncrement: () => _incrementTreasure(treasure.id),
      onDecrement: () => _decrementTreasure(treasure.id),
      onRemove: () => _removeTreasure(treasure.id),
    );
  }

  /// Get the color for a treasure type group header.
  Color _getTreasureGroupColor(String type) {
    switch (type.toLowerCase()) {
      case 'consumable':
        return NavigationTheme.consumablesColor;
      case 'trinket':
        return NavigationTheme.trinketsColor;
      case 'leveled_treasure':
        return NavigationTheme.leveledColor;
      case 'artifact':
        return NavigationTheme.artifactsColor;
      default:
        return NavigationTheme.treasureColor;
    }
  }
}
