import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/kit_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/choose_equipment_widget_text.dart';
import '../../../../widgets/kits/equipment_card.dart';

/// Configuration for a single equipment slot rendered inside the unified section.
class EquipmentSlot {
  const EquipmentSlot({
    required this.label,
    required this.allowedTypes,
    required this.selectedItemId,
    required this.onChanged,
    this.helperText,
    this.classId,
    this.excludeItemIds = const [],
  });

  final String label;
  final List<String> allowedTypes;
  final String? selectedItemId;
  final ValueChanged<String?> onChanged;
  final String? helperText;

  /// The class ID to filter equipment that has class restrictions (e.g., psionic_augmentation)
  final String? classId;

  /// Item IDs to exclude from selection (e.g., already selected in other slots)
  final List<String> excludeItemIds;
}

/// Compact section that renders all equipment and modification requirements together.
class EquipmentAndModificationsWidget extends ConsumerWidget {
  const EquipmentAndModificationsWidget({
    super.key,
    required this.slots,
  });

  static const _accent = CreatorTheme.equipmentAccent;
  
  final List<EquipmentSlot> slots;

  static const List<String> _allEquipmentTypes = <String>[
    'kit',
    'psionic_augmentation',
    'enchantment',
    'prayer',
    'ward',
    'stormwight_kit',
  ];

  static const Map<String, String> _equipmentTypeTitles = <String, String>{
    'kit': ChooseEquipmentWidgetText.equipmentTypeTitleKit,
    'psionic_augmentation': ChooseEquipmentWidgetText.equipmentTypeTitlePsionic,
    'enchantment': ChooseEquipmentWidgetText.equipmentTypeTitleEnchantment,
    'prayer': ChooseEquipmentWidgetText.equipmentTypeTitlePrayer,
    'ward': ChooseEquipmentWidgetText.equipmentTypeTitleWard,
    'stormwight_kit': ChooseEquipmentWidgetText.equipmentTypeTitleStormwight,
  };

  static const Map<String, String> _equipmentTypeChipTitles = <String, String>{
    'kit': ChooseEquipmentWidgetText.equipmentTypeChipTitleKit,
    'psionic_augmentation':
        ChooseEquipmentWidgetText.equipmentTypeChipTitlePsionic,
    'enchantment': ChooseEquipmentWidgetText.equipmentTypeChipTitleEnchantment,
    'prayer': ChooseEquipmentWidgetText.equipmentTypeChipTitlePrayer,
    'ward': ChooseEquipmentWidgetText.equipmentTypeChipTitleWard,
    'stormwight_kit':
        ChooseEquipmentWidgetText.equipmentTypeChipTitleStormwight,
  };

  static const Map<String, IconData> _equipmentTypeIcons = <String, IconData>{
    'kit': Icons.backpack_outlined,
    'psionic_augmentation': Icons.auto_awesome,
    'enchantment': Icons.auto_fix_high,
    'prayer': Icons.self_improvement,
    'ward': Icons.shield_outlined,
    'stormwight_kit': Icons.pets_outlined,
  };

  static const String _removeSignal = '__remove_item__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: ChooseEquipmentWidgetText.sectionTitle,
            subtitle: ChooseEquipmentWidgetText.sectionSubtitle,
            icon: Icons.inventory_2,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < slots.length; i++) ...[
                  _EquipmentSlotTile(
                    key: ValueKey('slot_$i'),
                    slot: slots[i],
                  ),
                  if (i != slots.length - 1) Divider(height: 32, color: Colors.grey.shade700),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<Component?> _findItemById(WidgetRef ref, String itemId) async {
    for (final type in _allEquipmentTypes) {
      final components = await ref.read(componentsByTypeProvider(type).future);
      for (final component in components) {
        if (component.id == itemId) {
          return component;
        }
      }
    }
    return null;
  }

  static List<String> _normalizeAllowedTypes(List<String> types) {
    final normalized = <String>{};
    for (final type in types) {
      final trimmed = type.trim().toLowerCase();
      if (trimmed.isNotEmpty) {
        normalized.add(trimmed);
      }
    }
    if (normalized.isEmpty) {
      normalized.addAll(_allEquipmentTypes);
    }
    return normalized.toList();
  }

  static List<String> _sortEquipmentTypes(Iterable<String> types) {
    final seen = <String>{};
    final sorted = <String>[];
    for (final type in _allEquipmentTypes) {
      if (types.contains(type) && seen.add(type)) {
        sorted.add(type);
      }
    }
    for (final type in types) {
      if (seen.add(type)) {
        sorted.add(type);
      }
    }
    return sorted;
  }

  static String _titleize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value
        .split(RegExp(r'[_\s]+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _EquipmentSlotTile extends ConsumerStatefulWidget {
  const _EquipmentSlotTile({
    super.key,
    required this.slot,
  });

  final EquipmentSlot slot;

  @override
  ConsumerState<_EquipmentSlotTile> createState() => _EquipmentSlotTileState();
}

class _EquipmentSlotTileState extends ConsumerState<_EquipmentSlotTile> {
  static const _accent = EquipmentAndModificationsWidget._accent;
  
  Future<Component?>? _cachedFuture;
  String? _cachedItemId;

  Color _getBorderColorForType(String type) {
    final colorScheme = KitTheme.getColorScheme(type);
    return colorScheme.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final allowedTypes = EquipmentAndModificationsWidget._normalizeAllowedTypes(
        slot.allowedTypes);

    // Only create a new Future if the selected item ID has changed
    // This prevents FutureBuilder from resetting to loading state on every rebuild
    if (_cachedItemId != slot.selectedItemId) {
      _cachedItemId = slot.selectedItemId;
      _cachedFuture = slot.selectedItemId == null
          ? Future<Component?>.value(null)
          : EquipmentAndModificationsWidget._findItemById(
              ref,
              slot.selectedItemId!,
            );
    }

    return FutureBuilder<Component?>(
      future: _cachedFuture,
      builder: (context, snapshot) {
        final selectedItem = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            slot.selectedItemId != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<String?>(
                    context: context,
                    builder: (dialogContext) => _EquipmentSelectionDialog(
                      slotLabel: slot.label,
                      allowedTypes: allowedTypes,
                      currentItemId: slot.selectedItemId,
                      canRemove: slot.selectedItemId != null,
                      classId: slot.classId,
                      excludeItemIds: slot.excludeItemIds,
                    ),
                  );
                  if (result == null) {
                    return;
                  }
                  if (result == EquipmentAndModificationsWidget._removeSignal) {
                    slot.onChanged(null);
                  } else {
                    slot.onChanged(result);
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  isLoading
                      ? ChooseEquipmentWidgetText.buttonLoadingLabel
                      : (selectedItem == null
                          ? '${ChooseEquipmentWidgetText.buttonSelectPrefix}${slot.label}'
                          : '${ChooseEquipmentWidgetText.buttonChangePrefix}${slot.label}'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.withValues(alpha: 0.2),
                  foregroundColor: _accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            if (slot.helperText != null) ...[
              const SizedBox(height: 6),
              Text(
                slot.helperText!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
            if (selectedItem != null && !isLoading) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => _KitPreviewDialog(
                      item: selectedItem,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: FormTheme.surface,
                    border: Border.all(
                      color: _getBorderColorForType(selectedItem.type),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedItem.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.visibility_outlined,
                        color: _getBorderColorForType(selectedItem.type),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (snapshot.hasError) ...[
              const SizedBox(height: 8),
              Text(
                ChooseEquipmentWidgetText.unableToLoadSelectedItem,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.redAccent.shade200,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _KitPreviewDialog extends StatelessWidget {
  const _KitPreviewDialog({
    required this.item,
  });

  final Component item;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: _buildCardForComponent(item),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForComponent(Component item) {
    // Determine badge label for modifiers
    String? badgeLabel;
    if (item.type == 'psionic_augmentation' ||
        item.type == 'enchantment' ||
        item.type == 'prayer') {
      badgeLabel = EquipmentAndModificationsWidget._titleize(item.type);
    }
    
    return EquipmentCard(
      component: item,
      badgeLabel: badgeLabel,
      initiallyExpanded: true,
    );
  }
}

class _EquipmentCategoryData {
  _EquipmentCategoryData({
    required this.type,
    required this.label,
    required this.chipLabel,
    required this.icon,
    required this.data,
  });

  final String type;
  final String label;
  final String chipLabel;
  final IconData icon;
  final AsyncValue<List<Component>> data;

  String get tabTitle {
    final count = data.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );
    return count == null
        ? label
        : '$label${ChooseEquipmentWidgetText.categoryCountPrefix}$count${ChooseEquipmentWidgetText.categoryCountSuffix}';
  }
}

class _EquipmentSelectionDialog extends ConsumerStatefulWidget {
  const _EquipmentSelectionDialog({
    required this.slotLabel,
    required this.allowedTypes,
    required this.currentItemId,
    required this.canRemove,
    this.classId,
    this.excludeItemIds = const [],
  });

  final String slotLabel;
  final List<String> allowedTypes;
  final String? currentItemId;
  final bool canRemove;

  /// The class ID to filter equipment with class restrictions (e.g., psionic_augmentation)
  final String? classId;

  /// Item IDs to exclude from selection (e.g., already selected in other slots)
  final List<String> excludeItemIds;

  @override
  ConsumerState<_EquipmentSelectionDialog> createState() =>
      _EquipmentSelectionDialogState();
}

class _EquipmentSelectionDialogState
    extends ConsumerState<_EquipmentSelectionDialog> {
  static const _accent = EquipmentAndModificationsWidget._accent;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_EquipmentCategoryData> _buildCategories() {
    final normalized = EquipmentAndModificationsWidget._normalizeAllowedTypes(
      widget.allowedTypes,
    );
    final sorted =
        EquipmentAndModificationsWidget._sortEquipmentTypes(normalized);

    return [
      for (final type in sorted)
        _EquipmentCategoryData(
          type: type,
          label: EquipmentAndModificationsWidget._equipmentTypeTitles[type] ??
              EquipmentAndModificationsWidget._titleize(type),
          chipLabel:
              EquipmentAndModificationsWidget._equipmentTypeChipTitles[type] ??
                  EquipmentAndModificationsWidget._titleize(type),
          icon: EquipmentAndModificationsWidget._equipmentTypeIcons[type] ??
              Icons.inventory_2_outlined,
          data: ref.watch(componentsByTypeProvider(type)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories();
    final navigator = Navigator.of(context);

    if (categories.isEmpty) {
      return Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accent.withValues(alpha: 0.3),
                      _accent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: _accent.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: _accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${ChooseEquipmentWidgetText.selectionDialogTitlePrefix}${widget.slotLabel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => navigator.pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  ChooseEquipmentWidgetText.noItemsAvailable,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMultipleCategories = categories.length > 1;

    return DefaultTabController(
      length: categories.length,
      child: Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accent.withValues(alpha: 0.3),
                      _accent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: _accent.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: _accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${ChooseEquipmentWidgetText.selectionDialogTitlePrefix}${widget.slotLabel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.canRemove)
                      TextButton.icon(
                        onPressed: () => navigator
                            .pop(EquipmentAndModificationsWidget._removeSignal),
                        icon: Icon(Icons.clear, color: Colors.redAccent.shade200),
                        label: Text(
                          ChooseEquipmentWidgetText.removeLabel,
                          style: TextStyle(color: Colors.redAccent.shade200),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => navigator.pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: ChooseEquipmentWidgetText.searchHint,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade400),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          ),
                    filled: true,
                    fillColor: FormTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
                      borderSide: const BorderSide(color: _accent),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              if (hasMultipleCategories)
                Material(
                  color: FormTheme.surface,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: _accent,
                    labelColor: _accent,
                    unselectedLabelColor: Colors.grey.shade400,
                    tabs: categories
                        .map(
                          (cat) => Tab(
                            text: cat.tabTitle,
                            icon: Icon(cat.icon, size: 18),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Expanded(
                child: hasMultipleCategories
                    ? TabBarView(
                        children: [
                          for (final category in categories)
                            _buildCategoryList(context, category),
                        ],
                      )
                    : _buildCategoryList(context, categories.first),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    _EquipmentCategoryData category,
  ) {
    final query = _searchQuery;

    return category.data.when(
      data: (items) {
        // First, filter by class restrictions (available_to_classes)
        var classFiltered = items;
        if (widget.classId != null) {
          classFiltered = items.where((item) {
            final availableToClasses = item.data['available_to_classes'];
            if (availableToClasses == null) {
              // No class restriction, available to all
              return true;
            }
            if (availableToClasses is List) {
              // Normalize the class ID for comparison (strip 'class_' prefix, lowercase)
              final normalizedClassId =
                  widget.classId!.toLowerCase().replaceFirst('class_', '');
              return availableToClasses
                  .map((e) => e.toString().toLowerCase())
                  .contains(normalizedClassId);
            }
            return true;
          }).toList();
        }

        // Filter out items already selected in other slots
        // (but keep the current slot's selection visible)
        var excludeFiltered = classFiltered;
        if (widget.excludeItemIds.isNotEmpty) {
          excludeFiltered = classFiltered.where((item) {
            return !widget.excludeItemIds.contains(item.id);
          }).toList();
        }

        // Then filter by search query
        final filtered = query.isEmpty
            ? excludeFiltered
            : excludeFiltered.where((item) {
                final name = item.name.toLowerCase();
                final description =
                    (item.data['description'] as String?)?.toLowerCase() ?? '';
                return name.contains(query) || description.contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                query.isEmpty
                    ? '${ChooseEquipmentWidgetText.noItemsPrefix}${category.label.toLowerCase()}${ChooseEquipmentWidgetText.noItemsSuffix}'
                    : '${ChooseEquipmentWidgetText.noResultsPrefix}${_searchController.text}${ChooseEquipmentWidgetText.noResultsSuffix}',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final isSelected = item.id == widget.currentItemId;
            final description = item.data['description'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(item.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.15)
                        : FormTheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? _accent
                          : Colors.grey.shade700,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: _accent,
                                size: 20,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? _accent : Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  EquipmentAndModificationsWidget
                                          ._equipmentTypeIcons[item.type] ??
                                      Icons.inventory_2_outlined,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  EquipmentAndModificationsWidget
                                          ._equipmentTypeChipTitles[item.type] ??
                                      EquipmentAndModificationsWidget._titleize(
                                          item.type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => Center(child: CreatorTheme.loadingIndicator(_accent)),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CreatorTheme.errorMessage(
            '${ChooseEquipmentWidgetText.errorLoadingPrefix}${category.label.toLowerCase()}${ChooseEquipmentWidgetText.errorLoadingSuffix}$error',
          ),
        ),
      ),
    );
  }
}

