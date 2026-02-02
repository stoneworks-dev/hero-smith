import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/gear/inventory_tab_text.dart';
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
      if (mounted) {
        setState(() {
          _containers = containers;
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

      items.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': itemData['name'],
        'description': itemData['description'],
        'quantity': int.tryParse(itemData['quantity']?.toString() ?? '1') ?? 1,
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
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _containers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            InventoryTabText.emptyContainersMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _containers.length,
                      itemBuilder: (context, index) {
                        final container = _containers[index];
                        final containerId = container['id'] as String;
                        return ContainerCard(
                          container: container,
                          onAddItem: () => _addItemToContainer(containerId),
                          onDeleteContainer: () =>
                              _deleteContainer(containerId),
                          onDeleteItem: (itemId) =>
                              _deleteItem(containerId, itemId),
                          onEditItem: (itemId, itemMap) =>
                              _editItem(containerId, itemId, itemMap),
                          onEditContainer: () => _editContainer(containerId),
                          onUpdateItemQuantity: (itemId, newQty) =>
                              _updateItemQuantity(containerId, itemId, newQty),
                        );
                      },
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
            child: Icon(Icons.create_new_folder,
                color: NavigationTheme.itemsColor, size: 20),
          ),
        ),
      ],
    );
  }
}
