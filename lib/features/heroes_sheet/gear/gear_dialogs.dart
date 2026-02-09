import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/db/app_database.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/models/downtime.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/text/heroes_sheet/gear/gear_dialogs_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';
import 'gear_utils.dart';

/// Dialog for adding treasures and imbuements.
class AddTreasureDialog extends StatefulWidget {
  final List<model.Component> availableTreasures;
  final List<DowntimeEntry> availableImbuements;
  final Function(String) onTreasureSelected;
  final Function(String) onImbuementSelected;

  const AddTreasureDialog({
    super.key,
    required this.availableTreasures,
    required this.onTreasureSelected,
    this.availableImbuements = const [],
    required this.onImbuementSelected,
  });

  @override
  State<AddTreasureDialog> createState() => _AddTreasureDialogState();
}

class _AddTreasureDialogState extends State<AddTreasureDialog>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterType = 'all';
  String _imbuementFilterType = 'all';
  List<model.Component> _filteredTreasures = [];
  List<DowntimeEntry> _filteredImbuements = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _filteredTreasures = widget.availableTreasures;
    _filteredImbuements = widget.availableImbuements;
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Get the color for a treasure type.
  Color _getTreasureTypeColor(String type) {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterTreasures() {
    setState(() {
      _filteredTreasures = widget.availableTreasures.where((treasure) {
        final description = treasure.data['description']?.toString() ?? '';
        final matchesSearch = _searchQuery.isEmpty ||
            treasure.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            description.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesType =
            _filterType == 'all' || treasure.type == _filterType;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _filterImbuements() {
    setState(() {
      _filteredImbuements = widget.availableImbuements.where((imbuement) {
        final description = imbuement.raw['description']?.toString() ?? '';
        final matchesSearch = _searchQuery.isEmpty ||
            imbuement.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            description.toLowerCase().contains(_searchQuery.toLowerCase());

        final imbuementType = imbuement.raw['type']?.toString() ?? '';
        final matchesType = _imbuementFilterType == 'all' ||
            imbuementType == _imbuementFilterType;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NavigationTheme.treasureColor.withValues(alpha: 0.3),
                    NavigationTheme.treasureColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                      color:
                          NavigationTheme.treasureColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: NavigationTheme.treasureColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      GearDialogsText.addTreasureOrImbuementTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: GearDialogsText.addTreasureSearchLabel,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: FormTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: NavigationTheme.treasureColor),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterTreasures();
                  _filterImbuements();
                },
              ),
            ),
            // Tab bar
            Material(
              color: FormTheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: NavigationTheme.treasureColor,
                labelColor: NavigationTheme.treasureColor,
                unselectedLabelColor: Colors.grey.shade400,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.diamond, size: 18),
                    text:
                        '${GearDialogsText.treasuresTabLabel} (${widget.availableTreasures.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    text:
                        '${GearDialogsText.imbuementsTabLabel} (${widget.availableImbuements.length})',
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTreasuresTab(theme),
                  _buildImbuementsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreasuresTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Filter dropdown
          DropdownButtonFormField<String>(
            value: _filterType,
            dropdownColor: FormTheme.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: GearDialogsText.treasureFilterLabel,
              labelStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: FormTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text(GearDialogsText.treasureFilterAllTypesLabel),
              ),
              DropdownMenuItem(
                value: 'consumable',
                child: Row(
                  children: [
                    Icon(Icons.science_outlined,
                        color: NavigationTheme.consumablesColor, size: 18),
                    const SizedBox(width: 8),
                    Text(GearDialogsText.treasureFilterConsumablesLabel,
                        style:
                            TextStyle(color: NavigationTheme.consumablesColor)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'trinket',
                child: Row(
                  children: [
                    Icon(Icons.diamond_outlined,
                        color: NavigationTheme.trinketsColor, size: 18),
                    const SizedBox(width: 8),
                    Text(GearDialogsText.treasureFilterTrinketsLabel,
                        style: TextStyle(color: NavigationTheme.trinketsColor)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'artifact',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: NavigationTheme.artifactsColor, size: 18),
                    const SizedBox(width: 8),
                    Text(GearDialogsText.treasureFilterArtifactsLabel,
                        style:
                            TextStyle(color: NavigationTheme.artifactsColor)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'leveled_treasure',
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: NavigationTheme.leveledColor, size: 18),
                    const SizedBox(width: 8),
                    Text(GearDialogsText.treasureFilterLeveledEquipmentLabel,
                        style: TextStyle(color: NavigationTheme.leveledColor)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _filterType = value;
                _filterTreasures();
              }
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredTreasures.isEmpty
                ? Center(
                    child: Text(
                      GearDialogsText.treasuresEmptyMessage,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTreasures.length,
                    itemBuilder: (context, index) {
                      final treasure = _filteredTreasures[index];
                      final echelon = treasure.data['echelon'] as int?;
                      final description =
                          treasure.data['description']?.toString() ?? '';
                      final treasureColor =
                          _getTreasureTypeColor(treasure.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: FormTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: treasureColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: treasureColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              getTreasureIcon(treasure.type),
                              color: treasureColor,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            treasure.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTreasureTypeName(treasure.type),
                                style: TextStyle(color: treasureColor),
                              ),
                              if (echelon != null)
                                Text(
                                  '${GearDialogsText.treasureEchelonPrefix}$echelon',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              if (description.isNotEmpty)
                                Text(
                                  description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                            ],
                          ),
                          onTap: () => widget.onTreasureSelected(treasure.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImbuementsTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Filter dropdown
          DropdownButtonFormField<String>(
            value: _imbuementFilterType,
            dropdownColor: FormTheme.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: GearDialogsText.imbuementFilterLabel,
              labelStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: FormTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text(GearDialogsText.imbuementFilterAllTypesLabel),
              ),
              DropdownMenuItem(
                value: 'armor_imbuement',
                child: Text(GearDialogsText.imbuementFilterArmorLabel),
              ),
              DropdownMenuItem(
                value: 'weapon_imbuement',
                child: Text(GearDialogsText.imbuementFilterWeaponLabel),
              ),
              DropdownMenuItem(
                value: 'implement_imbuement',
                child: Text(GearDialogsText.imbuementFilterImplementLabel),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _imbuementFilterType = value;
                _filterImbuements();
              }
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredImbuements.isEmpty
                ? Center(
                    child: Text(
                      GearDialogsText.imbuementsEmptyMessage,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredImbuements.length,
                    itemBuilder: (context, index) {
                      final imbuement = _filteredImbuements[index];
                      final level = imbuement.raw['level'] as int?;
                      final imbuementType =
                          imbuement.raw['type']?.toString() ?? '';
                      final description =
                          imbuement.raw['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: FormTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getImbuementTypeIcon(imbuementType),
                            color: NavigationTheme.imbuementsTabColor,
                          ),
                          title: Text(
                            imbuement.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getImbuementTypeDisplay(imbuementType),
                                    style: TextStyle(
                                        color:
                                            NavigationTheme.imbuementsTabColor),
                                  ),
                                  if (level != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            getLevelColor(level).withAlpha(51),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${GearDialogsText.imbuementLevelPrefix}$level',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: getLevelColor(level),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (description.isNotEmpty)
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                            ],
                          ),
                          isThreeLine: description.isNotEmpty,
                          onTap: () => widget.onImbuementSelected(imbuement.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getImbuementTypeIcon(String type) {
    switch (type) {
      case 'armor_imbuement':
        return Icons.shield;
      case 'weapon_imbuement':
        return Icons.sports_martial_arts;
      case 'implement_imbuement':
        return Icons.auto_awesome;
      default:
        return Icons.auto_fix_high;
    }
  }

  String _getImbuementTypeDisplay(String type) {
    switch (type) {
      case 'armor_imbuement':
        return GearDialogsText.imbuementTypeArmorDisplay;
      case 'weapon_imbuement':
        return GearDialogsText.imbuementTypeWeaponDisplay;
      case 'implement_imbuement':
        return GearDialogsText.imbuementTypeImplementDisplay;
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

/// Dialog for creating a new inventory container.
class CreateContainerDialog extends StatefulWidget {
  const CreateContainerDialog({super.key});

  @override
  State<CreateContainerDialog> createState() => _CreateContainerDialogState();
}

class _CreateContainerDialogState extends State<CreateContainerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                const Icon(Icons.create_new_folder,
                    color: NavigationTheme.itemsColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    GearDialogsText.createContainerTitle,
                    style: TextStyle(
                      color: Colors.white,
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
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: GearDialogsText.createContainerNameLabel,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                hintText: GearDialogsText.createContainerNameHint,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: FormTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: NavigationTheme.itemsColor),
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    GearDialogsText.createContainerCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  child:
                      const Text(GearDialogsText.createContainerCreateAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a new inventory item.
class CreateItemDialog extends StatefulWidget {
  const CreateItemDialog({super.key});

  @override
  State<CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<CreateItemDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _darkInputDecoration(String label, String hint,
      {int maxLines = 1}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: FormTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
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
                const Icon(Icons.add_box,
                    color: NavigationTheme.itemsColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    GearDialogsText.createItemTitle,
                    style: TextStyle(
                      color: Colors.white,
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
              style: const TextStyle(color: Colors.white),
              decoration: _darkInputDecoration(
                GearDialogsText.createItemNameLabel,
                GearDialogsText.createItemNameHint,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // Description field
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: _darkInputDecoration(
                GearDialogsText.createItemDescriptionLabel,
                GearDialogsText.createItemDescriptionHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Quantity row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FormTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    GearDialogsText.createItemQuantityLabel,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _quantity > 1
                          ? NavigationTheme.itemsColor
                          : Colors.grey.shade600,
                    ),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  InkWell(
                    onTap: () => _showQuantityInput(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: FormTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _quantity < 999
                          ? NavigationTheme.itemsColor
                          : Colors.grey.shade600,
                    ),
                    onPressed: _quantity < 999
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    GearDialogsText.createItemCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop({
                      'name': name,
                      'description': _descController.text.trim(),
                      'quantity': _quantity.toString(),
                    });
                  },
                  child: const Text(GearDialogsText.createItemAddAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuantityInput() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _QuantityInputDialog(currentQuantity: _quantity),
    );
    if (result != null) {
      setState(() => _quantity = result);
    }
  }
}

/// Dialog for editing an existing inventory item.
class EditItemDialog extends StatefulWidget {
  const EditItemDialog({
    super.key,
    required this.item,
  });

  final Map<String, dynamic> item;

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.item['name'] as String? ?? '');
    _descController = TextEditingController(
        text: widget.item['description'] as String? ?? '');
    final qty = widget.item['quantity'];
    _quantity = qty is int ? qty : int.tryParse(qty?.toString() ?? '1') ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _darkInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: FormTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
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
                const Icon(Icons.edit,
                    color: NavigationTheme.itemsColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    GearDialogsText.editItemTitle,
                    style: TextStyle(
                      color: Colors.white,
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
              style: const TextStyle(color: Colors.white),
              decoration: _darkInputDecoration(
                GearDialogsText.editItemNameLabel,
                GearDialogsText.editItemNameHint,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // Description field
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: _darkInputDecoration(
                GearDialogsText.editItemDescriptionLabel,
                GearDialogsText.editItemDescriptionHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Quantity row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FormTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    GearDialogsText.editItemQuantityLabel,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _quantity > 1
                          ? NavigationTheme.itemsColor
                          : Colors.grey.shade600,
                    ),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  InkWell(
                    onTap: () => _showQuantityInput(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: FormTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _quantity < 999
                          ? NavigationTheme.itemsColor
                          : Colors.grey.shade600,
                    ),
                    onPressed: _quantity < 999
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    GearDialogsText.editItemCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop({
                      'name': name,
                      'description': _descController.text.trim(),
                      'quantity': _quantity,
                    });
                  },
                  child: const Text(GearDialogsText.editItemSaveAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuantityInput() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _QuantityInputDialog(currentQuantity: _quantity),
    );
    if (result != null) {
      setState(() => _quantity = result);
    }
  }
}

/// Dialog for editing a container name.
class EditContainerDialog extends StatefulWidget {
  const EditContainerDialog({super.key, required this.currentName});

  final String currentName;

  @override
  State<EditContainerDialog> createState() => _EditContainerDialogState();
}

class _EditContainerDialogState extends State<EditContainerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                const Icon(Icons.edit,
                    color: NavigationTheme.itemsColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    GearDialogsText.editContainerTitle,
                    style: TextStyle(
                      color: Colors.white,
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
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: GearDialogsText.editContainerNameLabel,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                hintText: GearDialogsText.editContainerNameHint,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: FormTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: NavigationTheme.itemsColor),
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    GearDialogsText.editContainerCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  child: const Text(GearDialogsText.editContainerSaveAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding favorite kits, wards, prayers, enchantments, or augmentations.
/// Loads available options based on the hero's class and subclass.
class AddFavoriteKitDialog extends StatefulWidget {
  final String heroId;
  final AppDatabase db;
  final Set<String> existingFavoriteIds;
  final Function(String) onKitSelected;

  const AddFavoriteKitDialog({
    super.key,
    required this.heroId,
    required this.db,
    required this.existingFavoriteIds,
    required this.onKitSelected,
  });

  @override
  State<AddFavoriteKitDialog> createState() => _AddFavoriteKitDialogState();
}

class _AddFavoriteKitDialogState extends State<AddFavoriteKitDialog> {
  bool _isLoading = true;
  String? _error;
  List<model.Component> _availableKits = [];
  List<model.Component> _filteredKits = [];
  String _searchQuery = '';
  String _filterType = 'all';
  Set<String> _availableTypes = {};
  String? _heroClassName;

  @override
  void initState() {
    super.initState();
    _loadAvailableKits();
  }

  Future<void> _loadAvailableKits() async {
    try {
      // 1. Get hero's class from hero_entries table
      final classId =
          await widget.db.getSingleHeroEntryId(widget.heroId, 'class');
      final subclassId =
          await widget.db.getSingleHeroEntryId(widget.heroId, 'subclass');

      if (classId == null || classId.isEmpty) {
        setState(() {
          _error = GearDialogsText.addFavoriteNoClassError;
          _isLoading = false;
        });
        return;
      }

      // 2. Normalize class ID and get class data
      final normalizedClassId = _normalizeClassId(classId);
      final classDataService = ClassDataService();
      await classDataService.initialize();
      final classData = classDataService.getClassById(normalizedClassId);

      if (classData == null) {
        setState(() {
          _error =
              '${GearDialogsText.addFavoriteClassDataNotFoundPrefix}$classId${GearDialogsText.addFavoriteClassDataNotFoundSuffix}';
          _isLoading = false;
        });
        return;
      }

      _heroClassName = classData.name;
      final normalizedClassName =
          normalizedClassId.replaceFirst('class_', '').toLowerCase();

      // 3. Check for Fury Stormwight special case
      final normalizedSubclass = subclassId?.toLowerCase().trim() ?? '';
      final isStormwight = normalizedClassId == 'class_fury' &&
          normalizedSubclass.contains('stormwight');

      if (isStormwight) {
        // Only load stormwight kits
        final stormwightKits = await _loadKitsFromJson('stormwight_kits.json');
        setState(() {
          _availableKits = stormwightKits
              .where((k) => !widget.existingFavoriteIds.contains(k.id))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          _filteredKits = _availableKits;
          _availableTypes = {'stormwight_kit'};
          _isLoading = false;
        });
        return;
      }

      // 4. Parse level 1 features to find allowed equipment types
      final allowedKitTypes = _parseAllowedKitTypes(classData);

      if (allowedKitTypes.isEmpty) {
        setState(() {
          _error = GearDialogsText.addFavoriteNoOptionsError;
          _isLoading = false;
        });
        return;
      }

      // 5. Load items from corresponding JSON files
      final allKits = <model.Component>[];

      for (final kitType in allowedKitTypes) {
        final jsonFile = _getJsonFileForType(kitType);
        if (jsonFile != null) {
          final kits = await _loadKitsFromJson(jsonFile);
          // Filter by available_to_classes
          final filteredByClass = kits.where((kit) {
            final availableToClasses = kit.data['available_to_classes'];
            if (availableToClasses == null) return true;
            if (availableToClasses is List) {
              return availableToClasses
                  .map((e) => e.toString().toLowerCase())
                  .contains(normalizedClassName);
            }
            return true;
          }).toList();
          allKits.addAll(filteredByClass);
        }
      }

      // Remove duplicates and already favorited items
      final uniqueKits = <String, model.Component>{};
      for (final kit in allKits) {
        if (!widget.existingFavoriteIds.contains(kit.id)) {
          uniqueKits[kit.id] = kit;
        }
      }

      setState(() {
        _availableKits = uniqueKits.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _filteredKits = _availableKits;
        _availableTypes = allowedKitTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${GearDialogsText.addFavoriteLoadKitsFailedPrefix}$e';
        _isLoading = false;
      });
    }
  }

  String _normalizeClassId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.startsWith('class_')) return trimmed;
    return 'class_$trimmed';
  }

  Set<String> _parseAllowedKitTypes(dynamic classData) {
    final types = <String>{};

    // Access level 1 features
    final levels = classData.levels as List<dynamic>;
    if (levels.isEmpty) return types;

    for (final level in levels) {
      final features = level.features as List<dynamic>;
      for (final feature in features) {
        final name = (feature.name as String).trim().toLowerCase();

        // Check for kit-related features
        if (name == 'kit') {
          types.add('kit');
        } else if (name.contains('prayer')) {
          types.add('prayer');
        } else if (name.contains('ward')) {
          types.add('ward');
        } else if (name.contains('enchantment')) {
          types.add('enchantment');
        } else if (name.contains('augmentation') ||
            name.contains('psionic augmentation')) {
          types.add('psionic_augmentation');
        }
      }
    }

    return types;
  }

  String? _getJsonFileForType(String type) {
    switch (type) {
      case 'kit':
        return 'kits.json';
      case 'prayer':
        return 'prayers.json';
      case 'ward':
        return 'wards.json';
      case 'enchantment':
        return 'enchantments.json';
      case 'psionic_augmentation':
        return 'augmentations.json';
      case 'stormwight_kit':
        return 'stormwight_kits.json';
      default:
        return null;
    }
  }

  Future<List<model.Component>> _loadKitsFromJson(String filename) async {
    try {
      final jsonString = await rootBundle.loadString('data/kits/$filename');
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      return jsonData
          .map((item) => model.Component.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // File might not exist or be malformed
      return [];
    }
  }

  void _filterKits() {
    setState(() {
      _filteredKits = _availableKits.where((kit) {
        final description = kit.data['description']?.toString() ?? '';
        final matchesSearch = _searchQuery.isEmpty ||
            kit.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            description.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesType = _filterType == 'all' || kit.type == _filterType;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: NavigationTheme.kitsColor),
              const SizedBox(height: 16),
              const Text(
                GearDialogsText.addFavoriteLoadingTitle,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  GearDialogsText.addFavoriteLoadingCancelAction,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                GearDialogsText.addFavoriteErrorTitle,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  GearDialogsText.addFavoriteErrorCloseAction,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build filter dropdown items
    final filterItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'all',
        child: Text(GearDialogsText.addFavoriteFilterAllTypesLabel),
      ),
    ];
    for (final type in _availableTypes) {
      final label = kitTypeLabels[type] ?? kitTypeDisplayName(type);
      final icon = kitTypeIcons[type] ?? kitTypeIcon(type);
      filterItems.add(
        DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        height: 550,
        child: Column(
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NavigationTheme.kitsColor.withAlpha(77),
                    NavigationTheme.kitsColor.withAlpha(26),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: NavigationTheme.kitsColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          GearDialogsText.addFavoriteMainTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_heroClassName != null)
                          Text(
                            '${GearDialogsText.addFavoriteMainTitleClassPrefix}$_heroClassName${GearDialogsText.addFavoriteMainTitleClassSuffix}',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
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
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: GearDialogsText.addFavoriteSearchLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: FormTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: NavigationTheme.kitsColor),
                  ),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterKits();
                },
              ),
            ),
            // Filter dropdown (if multiple types)
            if (_availableTypes.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: DropdownButtonFormField<String>(
                  value: _filterType,
                  dropdownColor: FormTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: GearDialogsText.addFavoriteFilterLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: FormTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                  ),
                  items: filterItems,
                  onChanged: (value) {
                    if (value != null) {
                      _filterType = value;
                      _filterKits();
                    }
                  },
                ),
              ),
            // List of kits
            Expanded(
              child: _filteredKits.isEmpty
                  ? Center(
                      child: Text(
                        _availableKits.isEmpty
                            ? GearDialogsText
                                .addFavoriteAllItemsAlreadyFavoritedMessage
                            : GearDialogsText.addFavoriteNoItemsMatchMessage,
                        style: TextStyle(color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shrinkWrap: true,
                      itemCount: _filteredKits.length,
                      itemBuilder: (context, index) {
                        final kit = _filteredKits[index];
                        final description =
                            kit.data['description']?.toString() ?? '';
                        final icon =
                            kitTypeIcons[kit.type] ?? kitTypeIcon(kit.type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: FormTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: ListTile(
                            leading:
                                Icon(icon, color: NavigationTheme.kitsColor),
                            title: Text(
                              kit.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kitTypeDisplayName(kit.type),
                                  style: const TextStyle(
                                    color: NavigationTheme.kitsColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(color: Colors.grey.shade400),
                                  ),
                              ],
                            ),
                            isThreeLine: description.isNotEmpty,
                            onTap: () {
                              widget.onKitSelected(kit.id);
                              Navigator.of(context).pop();
                            },
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

/// Dialog for inputting a quantity value.
class _QuantityInputDialog extends StatefulWidget {
  const _QuantityInputDialog({required this.currentQuantity});

  final int currentQuantity;

  @override
  State<_QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<_QuantityInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentQuantity}');
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_controller.text);
    if (qty != null && qty >= 1 && qty <= 999) {
      Navigator.of(context).pop(qty);
    }
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
            const Text(
              GearDialogsText.quantityDialogTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: GearDialogsText.quantityDialogLabel,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: FormTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: NavigationTheme.itemsColor),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    GearDialogsText.quantityDialogCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child: const Text(GearDialogsText.quantityDialogSetAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


