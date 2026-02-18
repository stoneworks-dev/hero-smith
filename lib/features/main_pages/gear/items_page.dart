import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/services/items_catalog_service.dart';
import '../../../core/text/main_pages/gear/items_page_text.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';

class GearItemsPage extends ConsumerStatefulWidget {
  const GearItemsPage({super.key});

  @override
  ConsumerState<GearItemsPage> createState() => _GearItemsPageState();
}

class _GearItemsPageState extends ConsumerState<GearItemsPage> {
  List<model.Component> _allItems = [];
  List<model.Component> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  static const _categoryFilters = [
    ('all', ItemsPageText.filterAll),
    ('project_material', ItemsPageText.filterProjectMaterial),
    ('treasure_component', ItemsPageText.filterTreasureComponent),
    ('equipment', ItemsPageText.filterEquipment),
    ('consumable', ItemsPageText.filterConsumable),
    ('custom', ItemsPageText.filterCustom),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final service = ref.read(itemsCatalogServiceProvider);
    final items = await service.getAllItems();
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    _filteredItems = _allItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.data['description']?.toString() ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final category = item.data['category']?.toString() ?? 'custom';
      final matchesCategory =
          _selectedCategory == 'all' || category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _createItem() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateItemDialog(),
    );

    if (result == null || !mounted) return;

    try {
      final service = ref.read(itemsCatalogServiceProvider);
      await service.createItem(
        name: result['name']!,
        description: result['description'] ?? '',
        category: result['category'] ?? 'custom',
      );
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemsPageText.itemCreated(result['name']!)),
            backgroundColor: NavigationTheme.itemsColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemsPageText.failedToCreate(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(model.Component item) async {
    if (item.source != 'user') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ItemsPageText.cannotDeleteSeeded),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ItemsPageText.deleteItemTitle),
        content: const Text(ItemsPageText.deleteItemMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(ItemsPageText.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(ItemsPageText.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final service = ref.read(itemsCatalogServiceProvider);
    final deleted = await service.deleteItem(item.id);
    if (deleted) {
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemsPageText.itemDeleted(item.name)),
          ),
        );
      }
    }
  }

  Future<void> _editItem(model.Component item) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CreateItemDialog(
        initialName: item.name,
        initialDescription: item.data['description']?.toString() ?? '',
        initialCategory: item.data['category']?.toString() ?? 'custom',
        isEditing: true,
      ),
    );

    if (result == null || !mounted) return;

    final service = ref.read(itemsCatalogServiceProvider);
    await service.updateItem(
      id: item.id,
      name: result['name']!,
      description: result['description'] ?? '',
      category: result['category'] ?? item.data['category']?.toString() ?? 'custom',
    );
    await _loadItems();
  }

  Color _categoryColor(String? category) =>
      ItemsCatalogService.categoryColor(category);

  IconData _categoryIcon(String? category) =>
      ItemsCatalogService.categoryIcon(category);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        title: const Text(ItemsPageText.appBarTitle),
        backgroundColor: NavigationTheme.navBarBackground,
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: NavigationTheme.itemsColor))
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    style: const TextStyle(color: FormTheme.textBright),
                    decoration: InputDecoration(
                      hintText: ItemsPageText.searchHint,
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                // Category filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _categoryFilters.map((filter) {
                      final (filterKey, filterLabel) = filter;
                      final isSelected = _selectedCategory == filterKey;
                      final chipColor = filterKey == 'all'
                          ? NavigationTheme.itemsColor
                          : ItemsCatalogService.categoryColor(filterKey);
                      return FilterChip(
                        label: Text(filterLabel),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = filterKey;
                            _applyFilters();
                          });
                        },
                        selectedColor: chipColor
                            .withValues(alpha: 0.3),
                        checkmarkColor: chipColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? chipColor
                              : FormTheme.textSecondary,
                          fontSize: 13,
                        ),
                        backgroundColor: FormTheme.surface,
                        side: BorderSide(
                          color: isSelected
                              ? chipColor
                              : FormTheme.borderDim,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Items list
                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) =>
                              _buildItemCard(_filteredItems[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'items_page_fab',
        onPressed: _createItem,
        tooltip: ItemsPageText.addItem,
        backgroundColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              const BorderSide(color: NavigationTheme.itemsColor, width: 1.5),
        ),
        child: const Icon(Icons.add, color: NavigationTheme.itemsColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty || _selectedCategory != 'all';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            AppIcons.gear.item,
            size: 64,
            color: FormTheme.borderLight,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? ItemsPageText.noSearchResults
                : ItemsPageText.emptyItems,
            style: TextStyle(
              color: FormTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 8),
            Text(
              ItemsPageText.emptyItemsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: FormTheme.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(model.Component item) {
    final category = item.data['category']?.toString();
    final description = item.data['description']?.toString() ?? '';
    final usedBy = item.data['used_by_projects'] as List?;
    final color = _categoryColor(category);
    final isUserItem = item.source == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Could open detail in future
        onLongPress: isUserItem ? () => _showItemActions(item) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: FormTheme.textBright,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ItemsCatalogService.categoryLabel(category),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FormTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          ItemsCatalogService.categoryLabel(category),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (usedBy != null && usedBy.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.link, size: 14, color: FormTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ItemsPageText.usedByProjects(usedBy.length),
                            style: TextStyle(
                              color: FormTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions for user items
              if (isUserItem)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: FormTheme.textSecondary, size: 20),
                  color: NavigationTheme.cardBackgroundDark,
                  onSelected: (value) {
                    if (value == 'edit') _editItem(item);
                    if (value == 'delete') _deleteItem(item);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: FormTheme.textSecondary),
                          const SizedBox(width: 8),
                          const Text(ItemsPageText.editItem,
                              style: TextStyle(color: FormTheme.textBright)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Text(ItemsPageText.deleteItem,
                              style: TextStyle(color: Colors.red.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemActions(model.Component item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FormTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  Icon(Icons.edit_outlined, color: FormTheme.textSecondary),
              title: const Text(ItemsPageText.editItem,
                  style: TextStyle(color: FormTheme.textBright)),
              onTap: () {
                Navigator.of(context).pop();
                _editItem(item);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(ItemsPageText.deleteItem,
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / Edit Item Dialog
// ---------------------------------------------------------------------------

class _CreateItemDialog extends StatefulWidget {
  const _CreateItemDialog({
    this.initialName = '',
    this.initialDescription = '',
    this.initialCategory = 'custom',
    this.isEditing = false,
  });

  final String initialName;
  final String initialDescription;
  final String initialCategory;
  final bool isEditing;

  @override
  State<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<_CreateItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _selectedCategory;

  static const _categoryOptions = <(String, String)>[
    ('custom', 'Custom'),
    ('equipment', 'Equipment'),
    ('consumable', 'Consumable'),
    ('project_material', 'Project Material'),
    ('treasure_component', 'Treasure Component'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: FormTheme.textSecondary),
      hintText: hint,
      hintStyle: TextStyle(color: FormTheme.borderLight),
      filled: true,
      fillColor: FormTheme.surface,
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
        borderSide: const BorderSide(color: NavigationTheme.itemsColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.isEditing ? Icons.edit : Icons.add_box,
                  color: NavigationTheme.itemsColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isEditing
                        ? ItemsPageText.editItemTitle
                        : ItemsPageText.createItemTitle,
                    style: const TextStyle(
                      color: FormTheme.textBright,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: FormTheme.textBright),
              decoration: _inputDecoration(
                ItemsPageText.createItemNameLabel,
                ItemsPageText.createItemNameHint,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descController,
              style: const TextStyle(color: FormTheme.textBright),
              decoration: _inputDecoration(
                ItemsPageText.createItemDescriptionLabel,
                ItemsPageText.createItemDescriptionHint,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category picker
            if (!widget.isEditing)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FormTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FormTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ItemsPageText.createItemCategoryLabel,
                      style: TextStyle(
                          color: FormTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _categoryOptions.map((option) {
                        final (key, label) = option;
                        final isSelected = _selectedCategory == key;
                        final catColor =
                            ItemsCatalogService.categoryColor(key);
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.2)
                                  : FormTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? catColor
                                    : FormTheme.borderDim,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ItemsCatalogService.categoryIcon(key),
                                  color: isSelected
                                      ? catColor
                                      : FormTheme.textMuted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? catColor
                                        : FormTheme.textMuted,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (!widget.isEditing) const SizedBox(height: 16),

            const SizedBox(height: 4),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    ItemsPageText.cancel,
                    style: TextStyle(color: FormTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: FormTheme.textBright,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop({
                      'name': name,
                      'description': _descController.text.trim(),
                      'category': _selectedCategory,
                    });
                  },
                  child: Text(
                    widget.isEditing
                        ? ItemsPageText.save
                        : ItemsPageText.create,
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
