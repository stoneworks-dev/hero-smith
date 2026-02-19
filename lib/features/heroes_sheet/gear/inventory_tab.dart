import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/services/items_catalog_service.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/gear/inventory_tab_text.dart';
import '../../../core/text/heroes_sheet/gear/inventory_widgets_text.dart';
import 'gear_dialogs.dart';
import 'inventory_widgets.dart';

/// Inventory tab for the gear sheet.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  List<Map<String, dynamic>> _containers = [];
  List<Map<String, dynamic>> _looseItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containers = await heroRepo.getInventoryContainers(widget.heroId);
      final looseItems = await heroRepo.getLooseItems(widget.heroId);
      if (mounted) {
        setState(() {
          _containers = containers;
          _looseItems = looseItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${InventoryTabText.loadInventoryFailedPrefix}$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createContainer() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const CreateContainerDialog(),
    );

    if (name == null || name.isEmpty) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final newContainer = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'items': <Map<String, dynamic>>[],
      };
      final updated = [..._containers, newContainer];
      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.createContainerFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteContainer(String containerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(InventoryTabText.deleteContainerDialogTitle),
        content: const Text(InventoryTabText.deleteContainerDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(InventoryTabText.deleteContainerCancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(InventoryTabText.deleteContainerConfirmAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final updated = _containers.where((c) => c['id'] != containerId).toList();
      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.deleteContainerFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addItemToContainer(String containerId) async {
    final itemData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateItemDialog(),
    );

    if (itemData == null) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containerIndex =
          _containers.indexWhere((c) => c['id'] == containerId);
      if (containerIndex == -1) return;

      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      final items =
          List<Map<String, dynamic>>.from(container['items'] as List? ?? []);

      final itemName = itemData['name'] as String;
      final itemDesc = itemData['description'] as String? ?? '';
      final itemCategory = itemData['category'] as String? ?? 'custom';

      items.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': itemName,
        'description': itemDesc,
        'category': itemCategory,
        'quantity': int.tryParse(itemData['quantity']?.toString() ?? '1') ?? 1,
      });

      container['items'] = items;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);

      // Also ensure the item exists in the global items catalog
      final catalogService = ref.read(itemsCatalogServiceProvider);
      await catalogService.ensureItemInCatalog(
        name: itemName,
        description: itemDesc,
      );

      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.addItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(String containerId, String itemId) async {
    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containerIndex =
          _containers.indexWhere((c) => c['id'] == containerId);
      if (containerIndex == -1) return;

      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      final items =
          List<Map<String, dynamic>>.from(container['items'] as List? ?? []);

      items.removeWhere((item) => item['id'] == itemId);
      container['items'] = items;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.deleteItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editContainer(String containerId) async {
    final containerIndex =
        _containers.indexWhere((c) => c['id'] == containerId);
    if (containerIndex == -1) return;

    final currentName = _containers[containerIndex]['name'] as String? ??
        InventoryTabText.defaultContainerName;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditContainerDialog(currentName: currentName),
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      container['name'] = newName;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateContainerFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editItem(String containerId, String itemId,
      Map<String, dynamic> currentItem) async {
    final updatedItem = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditItemDialog(item: currentItem),
    );

    if (updatedItem == null) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containerIndex =
          _containers.indexWhere((c) => c['id'] == containerId);
      if (containerIndex == -1) return;

      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      final items =
          List<Map<String, dynamic>>.from(container['items'] as List? ?? []);

      final itemIndex = items.indexWhere((item) => item['id'] == itemId);
      if (itemIndex == -1) return;

      items[itemIndex] = {
        'id': itemId,
        'name': updatedItem['name'],
        'description': updatedItem['description'],
        'quantity': updatedItem['quantity'],
      };
      container['items'] = items;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateItemQuantity(
      String containerId, String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containerIndex =
          _containers.indexWhere((c) => c['id'] == containerId);
      if (containerIndex == -1) return;

      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      final items =
          List<Map<String, dynamic>>.from(container['items'] as List? ?? []);

      final itemIndex = items.indexWhere((item) => item['id'] == itemId);
      if (itemIndex == -1) return;

      final item = Map<String, dynamic>.from(items[itemIndex]);
      item['quantity'] = newQuantity;
      items[itemIndex] = item;
      container['items'] = items;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateQuantityFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show a dialog to search and add an item from the global catalog.
  Future<void> _addItemFromCatalog(String containerId) async {
    final selected = await showDialog<model.Component>(
      context: context,
      builder: (context) => _CatalogSearchDialog(ref: ref),
    );

    if (selected == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final containerIndex =
          _containers.indexWhere((c) => c['id'] == containerId);
      if (containerIndex == -1) return;

      final container = Map<String, dynamic>.from(_containers[containerIndex]);
      final items =
          List<Map<String, dynamic>>.from(container['items'] as List? ?? []);

      items.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': selected.name,
        'description': selected.data['description']?.toString() ?? '',
        'category': selected.data['category']?.toString() ?? 'custom',
        'quantity': 1,
      });

      container['items'] = items;

      final updated = List<Map<String, dynamic>>.from(_containers);
      updated[containerIndex] = container;

      await heroRepo.saveInventoryContainers(widget.heroId, updated);
      setState(() {
        _containers = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.addItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // LOOSE ITEMS
  // ===========================================================================

  Future<void> _addLooseItem() async {
    final itemData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateItemDialog(),
    );

    if (itemData == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final itemName = itemData['name'] as String;
      final itemDesc = itemData['description'] as String? ?? '';
      final itemCategory = itemData['category'] as String? ?? 'custom';

      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': itemName,
        'description': itemDesc,
        'category': itemCategory,
        'quantity': int.tryParse(itemData['quantity']?.toString() ?? '1') ?? 1,
      };

      final updated = [..._looseItems, newItem];
      await heroRepo.saveLooseItems(widget.heroId, updated);

      // Sync to catalog
      final catalogService = ref.read(itemsCatalogServiceProvider);
      await catalogService.ensureItemInCatalog(
        name: itemName,
        description: itemDesc,
      );

      setState(() {
        _looseItems = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.addItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addLooseItemFromCatalog() async {
    final selected = await showDialog<model.Component>(
      context: context,
      builder: (context) => _CatalogSearchDialog(ref: ref),
    );

    if (selected == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': selected.name,
        'description': selected.data['description']?.toString() ?? '',
        'category': selected.data['category']?.toString() ?? 'custom',
        'quantity': 1,
      };

      final updated = [..._looseItems, newItem];
      await heroRepo.saveLooseItems(widget.heroId, updated);
      setState(() {
        _looseItems = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.addItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLooseItem(String itemId) async {
    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final updated = _looseItems.where((i) => i['id'] != itemId).toList();
      await heroRepo.saveLooseItems(widget.heroId, updated);
      setState(() {
        _looseItems = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.deleteItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editLooseItem(
      String itemId, Map<String, dynamic> currentItem) async {
    final updatedItem = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditItemDialog(item: currentItem),
    );

    if (updatedItem == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final updated = List<Map<String, dynamic>>.from(_looseItems);
      final idx = updated.indexWhere((i) => i['id'] == itemId);
      if (idx == -1) return;

      updated[idx] = {
        'id': itemId,
        'name': updatedItem['name'],
        'description': updatedItem['description'],
        'category': _looseItems[idx]['category'] ?? 'custom',
        'quantity': updatedItem['quantity'],
      };

      await heroRepo.saveLooseItems(widget.heroId, updated);
      setState(() {
        _looseItems = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLooseItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final updated = List<Map<String, dynamic>>.from(_looseItems);
      final idx = updated.indexWhere((i) => i['id'] == itemId);
      if (idx == -1) return;

      final item = Map<String, dynamic>.from(updated[idx]);
      item['quantity'] = newQuantity;
      updated[idx] = item;

      await heroRepo.saveLooseItems(widget.heroId, updated);
      setState(() {
        _looseItems = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateQuantityFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // MOVE ITEMS BETWEEN LOCATIONS
  // ===========================================================================

  /// Move an item from a container to another container or loose items.
  Future<void> _moveItemFromContainer(
      String fromContainerId, Map<String, dynamic> item) async {
    final destination = await _showMoveDialog(
      excludeContainerId: fromContainerId,
      showLooseOption: true,
    );
    if (destination == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);

      // Remove from source container
      final containers = List<Map<String, dynamic>>.from(_containers);
      final srcIdx = containers.indexWhere((c) => c['id'] == fromContainerId);
      if (srcIdx == -1) return;

      final srcContainer = Map<String, dynamic>.from(containers[srcIdx]);
      final srcItems =
          List<Map<String, dynamic>>.from(srcContainer['items'] as List? ?? []);
      srcItems.removeWhere((i) => i['id'] == item['id']);
      srcContainer['items'] = srcItems;
      containers[srcIdx] = srcContainer;

      final movedItem = Map<String, dynamic>.from(item);
      // Give it a new ID in the destination
      movedItem['id'] = DateTime.now().millisecondsSinceEpoch.toString();

      if (destination == '__loose__') {
        // Move to loose items
        final looseItems = [..._looseItems, movedItem];
        await heroRepo.saveInventoryContainers(widget.heroId, containers);
        await heroRepo.saveLooseItems(widget.heroId, looseItems);
        setState(() {
          _containers = containers;
          _looseItems = looseItems;
        });
      } else {
        // Move to another container
        final destIdx = containers.indexWhere((c) => c['id'] == destination);
        if (destIdx == -1) return;

        final destContainer = Map<String, dynamic>.from(containers[destIdx]);
        final destItems = List<Map<String, dynamic>>.from(
            destContainer['items'] as List? ?? []);
        destItems.add(movedItem);
        destContainer['items'] = destItems;
        containers[destIdx] = destContainer;

        await heroRepo.saveInventoryContainers(widget.heroId, containers);
        setState(() {
          _containers = containers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.moveItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Move an item from loose items to a container.
  Future<void> _moveItemFromLoose(Map<String, dynamic> item) async {
    final destination = await _showMoveDialog(
      showLooseOption: false,
    );
    if (destination == null || !mounted) return;

    try {
      final heroRepo = ref.read(heroRepositoryProvider);

      // Remove from loose items
      final looseItems =
          _looseItems.where((i) => i['id'] != item['id']).toList();

      // Add to destination container
      final containers = List<Map<String, dynamic>>.from(_containers);
      final destIdx = containers.indexWhere((c) => c['id'] == destination);
      if (destIdx == -1) return;

      final destContainer = Map<String, dynamic>.from(containers[destIdx]);
      final destItems = List<Map<String, dynamic>>.from(
          destContainer['items'] as List? ?? []);

      final movedItem = Map<String, dynamic>.from(item);
      movedItem['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      destItems.add(movedItem);
      destContainer['items'] = destItems;
      containers[destIdx] = destContainer;

      await heroRepo.saveLooseItems(widget.heroId, looseItems);
      await heroRepo.saveInventoryContainers(widget.heroId, containers);
      setState(() {
        _looseItems = looseItems;
        _containers = containers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.moveItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show a dialog to pick the destination for a move.
  Future<String?> _showMoveDialog({
    String? excludeContainerId,
    required bool showLooseOption,
  }) async {
    final destinations = <Map<String, String>>[];

    if (showLooseOption) {
      destinations.add({
        'id': '__loose__',
        'name': InventoryTabText.looseItemsDestination,
      });
    }

    for (final container in _containers) {
      final cId = container['id']?.toString() ?? '';
      if (cId == excludeContainerId) continue;
      destinations.add({
        'id': cId,
        'name': container['name']?.toString() ??
            InventoryTabText.defaultContainerName,
      });
    }

    if (destinations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(InventoryTabText.noDestinations),
          ),
        );
      }
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  InventoryTabText.moveItemTitle,
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  InventoryTabText.moveItemSubtitle,
                  style: TextStyle(
                    color: FormTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...destinations.map((dest) => ListTile(
                    leading: Icon(
                      dest['id'] == '__loose__'
                          ? Icons.inventory_2_outlined
                          : Icons.cases_outlined,
                      color: NavigationTheme.itemsColor,
                      size: 22,
                    ),
                    title: Text(
                      dest['name'] ?? '',
                      style: const TextStyle(color: FormTheme.textBright),
                    ),
                    onTap: () => Navigator.pop(ctx, dest['id']),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: NavigationTheme.itemsColor));
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
                    InventoryTabText.inventoryTitle,
                    style: TextStyle(
                      color: FormTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: (_containers.isEmpty && _looseItems.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            AppIcons.gear.inventoryTab,
                            size: 64,
                            color: FormTheme.borderLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            InventoryTabText.emptyContainersMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: FormTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // ── Loose Items Section ──
                        _buildLooseItemsDragTarget(),
                        // ── Containers ──
                        ..._buildContainersReorderList(),
                        const SizedBox(height: 72), // FAB clearance
                      ],
                    ),
            ),
          ],
        ),
        // Floating Action Button for adding containers
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'inventory_tab_fab',
            onPressed: _createContainer,
            tooltip: InventoryTabText.newContainerButtonLabel,
            backgroundColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: NavigationTheme.itemsColor, width: 1.5),
            ),
            child: AppIcon(AppIcons.gear.container,
                color: NavigationTheme.itemsColor, size: 22),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContainersReorderList() {
    final widgets = <Widget>[];

    for (var index = 0; index < _containers.length; index++) {
      final container = _containers[index];
      final containerId = container['id'] as String;

      widgets.add(_buildContainerDropZone(index));
      widgets.add(
        LongPressDraggable<Map<String, dynamic>>(
          delay: const Duration(milliseconds: 150),
          data: {
            'source': 'container_card',
            'containerId': containerId,
            'containerIndex': index,
          },
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Opacity(
                opacity: 0.88,
                child: _buildContainerDragTarget(
                  containerId,
                  ContainerCard(
                    container: container,
                    onAddItem: () => _addItemToContainer(containerId),
                    onAddFromCatalog: () => _addItemFromCatalog(containerId),
                    onDeleteContainer: () => _deleteContainer(containerId),
                    onDeleteItem: (itemId) => _deleteItem(containerId, itemId),
                    onEditItem: (itemId, itemMap) =>
                        _editItem(containerId, itemId, itemMap),
                    onEditContainer: () => _editContainer(containerId),
                    onUpdateItemQuantity: (itemId, newQty) =>
                        _updateItemQuantity(containerId, itemId, newQty),
                    onMoveItem: (item) =>
                        _moveItemFromContainer(containerId, item),
                    onItemDropAt: (dragData, targetIndex) =>
                        _handleItemDropAt(
                      dragData: dragData,
                      toTarget: containerId,
                      targetIndex: targetIndex,
                    ),
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _buildContainerDragTarget(
              containerId,
              ContainerCard(
                container: container,
                onAddItem: () => _addItemToContainer(containerId),
                onAddFromCatalog: () => _addItemFromCatalog(containerId),
                onDeleteContainer: () => _deleteContainer(containerId),
                onDeleteItem: (itemId) => _deleteItem(containerId, itemId),
                onEditItem: (itemId, itemMap) =>
                    _editItem(containerId, itemId, itemMap),
                onEditContainer: () => _editContainer(containerId),
                onUpdateItemQuantity: (itemId, newQty) =>
                    _updateItemQuantity(containerId, itemId, newQty),
                onMoveItem: (item) => _moveItemFromContainer(containerId, item),
                onItemDropAt: (dragData, targetIndex) => _handleItemDropAt(
                  dragData: dragData,
                  toTarget: containerId,
                  targetIndex: targetIndex,
                ),
              ),
            ),
          ),
          child: _buildContainerDragTarget(
            containerId,
            ContainerCard(
              container: container,
              onAddItem: () => _addItemToContainer(containerId),
              onAddFromCatalog: () => _addItemFromCatalog(containerId),
              onDeleteContainer: () => _deleteContainer(containerId),
              onDeleteItem: (itemId) => _deleteItem(containerId, itemId),
              onEditItem: (itemId, itemMap) =>
                  _editItem(containerId, itemId, itemMap),
              onEditContainer: () => _editContainer(containerId),
              onUpdateItemQuantity: (itemId, newQty) =>
                  _updateItemQuantity(containerId, itemId, newQty),
              onMoveItem: (item) => _moveItemFromContainer(containerId, item),
              onItemDropAt: (dragData, targetIndex) => _handleItemDropAt(
                dragData: dragData,
                toTarget: containerId,
                targetIndex: targetIndex,
              ),
            ),
          ),
        ),
      );
    }

    widgets.add(_buildContainerDropZone(_containers.length));
    return widgets;
  }

  Widget _buildContainerDropZone(int targetIndex) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final source = details.data['source']?.toString();
        return source == 'container_card';
      },
      onAcceptWithDetails: (details) {
        _handleContainerDropAt(details.data, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovering ? 18 : 8,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHovering
                ? NavigationTheme.itemsColor.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHovering
                ? Border.all(
                    color: NavigationTheme.itemsColor.withValues(alpha: 0.8),
                    width: 1.5,
                  )
                : null,
          ),
        );
      },
    );
  }
  // ===========================================================================
  // DRAG & DROP
  // ===========================================================================

  /// Wraps a ContainerCard in a DragTarget that accepts items from elsewhere.
  Widget _buildContainerDragTarget(String containerId, Widget child) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        final source = data['source']?.toString();
        return source == 'loose' || source == 'container';
      },
      onAcceptWithDetails: (details) {
        _handleItemDropAt(
          dragData: details.data,
          toTarget: containerId,
          targetIndex: -1,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: NavigationTheme.itemsColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                )
              : const BoxDecoration(),
          child: child,
        );
      },
    );
  }

  /// Wraps the loose items section in a DragTarget.
  Widget _buildLooseItemsDragTarget() {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        final source = data['source']?.toString();
        return source == 'loose' || source == 'container';
      },
      onAcceptWithDetails: (details) {
        _handleItemDropAt(
          dragData: details.data,
          toTarget: '__loose__',
          targetIndex: -1,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: NavigationTheme.itemsColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                )
              : const BoxDecoration(),
          child: _buildLooseItemsSection(),
        );
      },
    );
  }

  Future<void> _handleContainerDropAt(
      Map<String, dynamic> dragData, int targetIndex) async {
    try {
      final source = dragData['source']?.toString();
      if (source != 'container_card') return;

      final containerId = dragData['containerId']?.toString();
      if (containerId == null || containerId.isEmpty) return;

      final containers = List<Map<String, dynamic>>.from(_containers);
      final fromIndex = containers.indexWhere((c) => c['id'] == containerId);
      if (fromIndex == -1) return;

      var insertIndex =
          targetIndex.clamp(0, containers.length) as int;
      if (fromIndex < insertIndex) {
        insertIndex -= 1;
      }
      if (fromIndex == insertIndex) return;

      final moved = containers.removeAt(fromIndex);
      containers.insert(insertIndex, moved);

      final heroRepo = ref.read(heroRepositoryProvider);
      await heroRepo.saveInventoryContainers(widget.heroId, containers);
      setState(() {
        _containers = containers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.updateContainerFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle item drag-drop with optional positional insertion.
  Future<void> _handleItemDropAt({
    required Map<String, dynamic> dragData,
    required String toTarget,
    required int targetIndex,
  }) async {
    try {
      final source = dragData['source']?.toString();
      if (source != 'loose' && source != 'container') return;

      final itemRaw = dragData['item'];
      if (itemRaw is! Map) return;
      final draggedItem = Map<String, dynamic>.from(itemRaw);
      final itemId = draggedItem['id']?.toString();
      if (itemId == null || itemId.isEmpty) return;

      final containers = List<Map<String, dynamic>>.from(_containers);
      final looseItems = List<Map<String, dynamic>>.from(_looseItems);

      List<Map<String, dynamic>> sourceList;
      List<Map<String, dynamic>> destinationList;
      int removedIndex = -1;

      if (source == 'loose') {
        sourceList = looseItems;
      } else {
        final fromContainerId = dragData['containerId']?.toString();
        if (fromContainerId == null) return;
        final srcContainerIndex =
            containers.indexWhere((c) => c['id'] == fromContainerId);
        if (srcContainerIndex == -1) return;
        final srcContainer = Map<String, dynamic>.from(containers[srcContainerIndex]);
        sourceList =
            List<Map<String, dynamic>>.from(srcContainer['items'] as List? ?? []);
        srcContainer['items'] = sourceList;
        containers[srcContainerIndex] = srcContainer;
      }

      removedIndex = sourceList.indexWhere((i) => i['id']?.toString() == itemId);
      if (removedIndex == -1) return;
      final movedItem = Map<String, dynamic>.from(sourceList.removeAt(removedIndex));

      if (toTarget == '__loose__') {
        destinationList = looseItems;
      } else {
        final destContainerIndex = containers.indexWhere((c) => c['id'] == toTarget);
        if (destContainerIndex == -1) return;
        final destContainer = Map<String, dynamic>.from(containers[destContainerIndex]);
        destinationList =
            List<Map<String, dynamic>>.from(destContainer['items'] as List? ?? []);
        destContainer['items'] = destinationList;
        containers[destContainerIndex] = destContainer;
      }

      var insertIndex = targetIndex < 0 ? destinationList.length : targetIndex;
      final sameList = identical(sourceList, destinationList);
      if (sameList && removedIndex < insertIndex) {
        insertIndex -= 1;
      }
      insertIndex = insertIndex.clamp(0, destinationList.length) as int;
      destinationList.insert(insertIndex, movedItem);

      final heroRepo = ref.read(heroRepositoryProvider);
      await heroRepo.saveInventoryContainers(widget.heroId, containers);
      await heroRepo.saveLooseItems(widget.heroId, looseItems);

      setState(() {
        _containers = containers;
        _looseItems = looseItems;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${InventoryTabText.moveItemFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLooseItemsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: NavigationTheme.itemsColor.withAlpha(18),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: NavigationTheme.itemsColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        InventoryTabText.looseItemsTitle,
                        style: TextStyle(
                          color: FormTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        InventoryTabText.looseItemsSubtitle,
                        style: TextStyle(
                          color: FormTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search,
                      color: NavigationTheme.itemsColor, size: 22),
                  onPressed: _addLooseItemFromCatalog,
                  tooltip: InventoryWidgetsText.addFromCatalogTooltip,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: NavigationTheme.itemsColor, size: 22),
                  onPressed: _addLooseItem,
                  tooltip: InventoryWidgetsText.addItemTooltip,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Items list
          if (_looseItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < _looseItems.length; index++) ...[
                    _buildLooseItemDropZone(index),
                    Builder(builder: (context) {
                      final itemMap = _looseItems[index];
                      final itemId = itemMap['id'] as String;
                      final qty = itemMap['quantity'];
                      final quantity = qty is int
                          ? qty
                          : int.tryParse(qty?.toString() ?? '1') ?? 1;
                      final description = itemMap['description'] as String?;
                      final category =
                          itemMap['category'] as String? ?? 'custom';
                      final itemColor =
                          ItemsCatalogService.categoryColor(category);

                      final itemWidget = Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FormTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FormTheme.borderDim),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: FormTheme.borderLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: itemColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              ItemsCatalogService.categoryIcon(category),
                              color: itemColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name, description, and actions stacked
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item name
                              Text(
                                itemMap['name'] as String? ??
                                    InventoryWidgetsText.defaultItemName,
                                style: TextStyle(
                                  color: FormTheme.textBright,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Description
                              if (description != null &&
                                  description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: FormTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              // Actions row: quantity, move, edit, delete
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    // Quantity controls
                                    Container(
                                      decoration: BoxDecoration(
                                        color: FormTheme.surfaceMuted,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(8)),
                                            onTap: quantity > 1
                                                ? () => _updateLooseItemQuantity(
                                                    itemId, quantity - 1)
                                                : null,
                                            child: Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Icon(
                                                Icons.remove,
                                                size: 14,
                                                color: quantity > 1
                                                    ? NavigationTheme.itemsColor
                                                    : FormTheme.borderLight,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10.0),
                                            child: Text(
                                              '$quantity',
                                              style: TextStyle(
                                                color: FormTheme.textBright,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(8)),
                                            onTap: quantity < 999
                                                ? () => _updateLooseItemQuantity(
                                                    itemId, quantity + 1)
                                                : null,
                                            child: Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Icon(
                                                Icons.add,
                                                size: 14,
                                                color: quantity < 999
                                                    ? NavigationTheme.itemsColor
                                                    : FormTheme.borderLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Move button
                                    if (_containers.isNotEmpty)
                                      IconButton(
                                        icon: Icon(Icons.drive_file_move_outline,
                                            size: 18, color: FormTheme.textSecondary),
                                        onPressed: () => _moveItemFromLoose(itemMap),
                                        tooltip: InventoryWidgetsText.moveItemTooltip,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    // Edit button
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined,
                                          size: 18, color: FormTheme.textSecondary),
                                      onPressed: () =>
                                          _editLooseItem(itemId, itemMap),
                                      tooltip: InventoryWidgetsText.editItemTooltip,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          size: 18, color: Colors.red.shade400),
                                      onPressed: () => _deleteLooseItem(itemId),
                                      tooltip: InventoryWidgetsText.deleteItemTooltip,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                      );

                      return LongPressDraggable<Map<String, dynamic>>(
                        delay: const Duration(milliseconds: 150),
                        data: {
                          'item': itemMap,
                          'source': 'loose',
                          'containerId': null,
                          'itemIndex': index,
                        },
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.85,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: itemWidget,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: itemWidget,
                        ),
                        child: itemWidget,
                      );
                    }),
                  ],
                  _buildLooseItemDropZone(_looseItems.length),
                ],
              ),
            ),
          if (_looseItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                InventoryTabText.emptyLooseItems,
                style: TextStyle(color: FormTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLooseItemDropZone(int targetIndex) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final source = details.data['source']?.toString();
        return source == 'loose' || source == 'container';
      },
      onAcceptWithDetails: (details) {
        _handleItemDropAt(
          dragData: details.data,
          toTarget: '__loose__',
          targetIndex: targetIndex,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovering ? 16 : 8,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHovering
                ? NavigationTheme.itemsColor.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isHovering
                ? Border.all(
                    color: NavigationTheme.itemsColor.withValues(alpha: 0.8),
                    width: 1.5,
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Catalog Search Dialog — search and pick items from the global catalog
// ---------------------------------------------------------------------------

class _CatalogSearchDialog extends StatefulWidget {
  const _CatalogSearchDialog({required this.ref});

  final WidgetRef ref;

  @override
  State<_CatalogSearchDialog> createState() => _CatalogSearchDialogState();
}

class _CatalogSearchDialogState extends State<_CatalogSearchDialog> {
  List<model.Component> _allItems = [];
  List<model.Component> _filteredItems = [];
  String _query = '';
  String _selectedCategory = 'all';
  bool _isLoading = true;

  static const _categoryFilters = <(String, String)>[
    ('all', 'All'),
    ('project_material', 'Project Material'),
    ('treasure_component', 'Treasure Component'),
    ('equipment', 'Equipment'),
    ('consumable', 'Consumable'),
    ('custom', 'Custom'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final service = widget.ref.read(itemsCatalogServiceProvider);
    final items = await service.getAllItems();
    if (mounted) {
      setState(() {
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      var results = _allItems;

      // Category filter
      if (_selectedCategory != 'all') {
        results = results
            .where((item) =>
                (item.data['category']?.toString() ?? 'custom') ==
                _selectedCategory)
            .toList();
      }

      // Text search
      if (_query.isNotEmpty) {
        final lower = _query.toLowerCase();
        results = results
            .where((item) =>
                item.name.toLowerCase().contains(lower) ||
                (item.data['description']?.toString() ?? '')
                    .toLowerCase()
                    .contains(lower))
            .toList();
      }

      _filteredItems = results;
    });
  }

  void _filter(String query) {
    _query = query;
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NavigationTheme.itemsColor.withValues(alpha: 0.3),
                    NavigationTheme.itemsColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                      color:
                          NavigationTheme.itemsColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: NavigationTheme.itemsColor, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      InventoryTabText.searchCatalogTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: FormTheme.textBright,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: FormTheme.textBright),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: FormTheme.textBright),
                decoration: InputDecoration(
                  hintText: InventoryTabText.searchCatalogHint,
                  hintStyle: TextStyle(color: FormTheme.textMuted),
                  prefixIcon:
                      Icon(Icons.search, color: FormTheme.textSecondary),
                  filled: true,
                  fillColor: FormTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: FormTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: FormTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: NavigationTheme.itemsColor),
                  ),
                  isDense: true,
                ),
                onChanged: _filter,
              ),
            ),

            // Category filter chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categoryFilters.length,
                itemBuilder: (context, index) {
                  final (filterKey, filterLabel) = _categoryFilters[index];
                  final isSelected = _selectedCategory == filterKey;
                  final chipColor = filterKey == 'all'
                      ? NavigationTheme.itemsColor
                      : ItemsCatalogService.categoryColor(filterKey);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(filterLabel),
                      selected: isSelected,
                      onSelected: (_) {
                        _selectedCategory = filterKey;
                        _applyFilters();
                      },
                      selectedColor: chipColor.withValues(alpha: 0.3),
                      checkmarkColor: chipColor,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? chipColor : FormTheme.textSecondary,
                        fontSize: 12,
                      ),
                      backgroundColor: FormTheme.surface,
                      side: BorderSide(
                        color: isSelected ? chipColor : FormTheme.borderDim,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),

            // Items list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: NavigationTheme.itemsColor))
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                AppIcons.gear.item,
                                size: 48,
                                color: FormTheme.borderLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _query.isNotEmpty
                                    ? InventoryTabText.searchCatalogEmpty
                                    : InventoryTabText
                                        .searchCatalogEmptySubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: FormTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final description =
                                item.data['description']?.toString() ?? '';
                            final category =
                                item.data['category']?.toString() ?? 'custom';
                            final catColor =
                                ItemsCatalogService.categoryColor(category);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: FormTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: catColor.withValues(alpha: 0.3)),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: catColor
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    ItemsCatalogService.categoryIcon(category),
                                    color: catColor,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: FormTheme.textBright,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: description.isNotEmpty
                                    ? Text(
                                        description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: FormTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ItemsCatalogService.categoryLabel(
                                        category),
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                onTap: () =>
                                    Navigator.of(context).pop(item),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
