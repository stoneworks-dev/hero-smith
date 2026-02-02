import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/class_data.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/class_data_service.dart';
import '../../../core/services/kit_grants_service.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/gear/kits_tab_text.dart';
import '../main_stats/hero_main_stats_providers.dart';
import 'gear_dialogs.dart';
import 'gear_utils.dart';
import 'kit_widgets.dart';

/// Kits tab for the gear sheet.
class KitsTab extends ConsumerStatefulWidget {
  const KitsTab({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<KitsTab> createState() => _KitsTabState();
}

class _KitsTabState extends ConsumerState<KitsTab> {
  List<model.Component> _allKits = [];
  List<String> _allowedEquipmentTypes = ['kit']; // Default to standard kit
  List<String> _favoriteKitIds = [];
  List<String> _equippedKitIds = [];
  List<EquipmentSlotConfig> _equipmentSlots = [];
  List<String?> _equippedSlotIds = [];
  String? _classId;
  String? _normalizedClassId;
  final Map<String, model.Component> _kitCache = {};
  bool _isLoading = true;
  String? _error;

  /// Safely parse JSON string to Map
  Future<Map<String, dynamic>?> _parseJson(String jsonString) async {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final values = await db.getHeroValues(widget.heroId);

      // Get class and subclass info
      String? className;
      String? subclassName;

      for (final value in values) {
        if (value.key == 'basics.className') {
          className = value.textValue;
        } else if (value.key == 'basics.subclass') {
          subclassName = value.textValue;
        }
      }

      // Normalize class id to match stored class data ids (e.g., class_conduit)
      String? resolvedClassId = _normalizeClassId(className);

      // Load class data to determine allowed equipment types
      final classDataService = ClassDataService();
      await classDataService.initialize();
      final classData = resolvedClassId != null
          ? classDataService.getClassById(resolvedClassId)
          : null;
      final slots = _determineEquipmentSlots(classData, subclassName);
      final allowedTypes = slots.isEmpty
          ? ['kit']
          : sortKitTypesByPriority(
              slots.expand((slot) => slot.allowedTypes).toSet());

      // Load all kit-type components that match allowed types
      final allComponents = await ref.read(allComponentsProvider.future);

      // Normalize class name for comparison (strip 'class_' prefix, lowercase)
      final normalizedClassName =
          resolvedClassId?.toLowerCase().replaceFirst('class_', '');

      final kits = allComponents.where((c) {
        // First check if type is allowed
        if (!allowedTypes.contains(c.type)) return false;

        // Then check class restrictions (available_to_classes)
        final availableToClasses = c.data['available_to_classes'];
        if (availableToClasses == null) {
          // No class restriction, available to all
          return true;
        }
        if (availableToClasses is List && normalizedClassName != null) {
          return availableToClasses
              .map((e) => e.toString().toLowerCase())
              .contains(normalizedClassName);
        }
        return true;
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      // Load favorite and equipped kits
      final heroRepo = ref.read(heroRepositoryProvider);
      final favorites = await heroRepo.getFavoriteKitIds(widget.heroId);
      final equipped = await heroRepo.getEquipmentIds(widget.heroId);
      final alignedEquipped = await _alignEquipmentToSlots(
        slots: slots,
        equipmentIds: equipped,
        db: db,
      );

      // Use ALL equipped IDs for the "is equipped" check, not just aligned ones
      // This ensures all equipped kits show the equipped badge even if slots < kits
      final equippedActive =
          equipped.whereType<String>().where((id) => id.isNotEmpty).toList();

      // Load any equipped/favorited items that aren't in the filtered kits list
      // This ensures equipped items always show up even if they're from a different type
      final allKitIds = kits.map((k) => k.id).toSet();
      final missingIds = <String>{
        ...equippedActive,
        ...favorites,
      }.where((id) => !allKitIds.contains(id)).toList();

      for (final id in missingIds) {
        final component = await db.getComponentById(id);
        if (component != null) {
          kits.add(model.Component(
            id: component.id,
            name: component.name,
            type: component.type,
            data: component.dataJson.isNotEmpty
                ? (await _parseJson(component.dataJson)) ?? {}
                : {},
          ));
        }
      }

      // Auto-add equipped kit IDs to favorites so they always show up on the page
      final mergedFavorites =
          <String>{...favorites, ...equippedActive}.toList();

      // Save the merged favorites so equipped kits persist as favorites
      if (equippedActive.isNotEmpty &&
          !favorites.toSet().containsAll(equippedActive)) {
        await heroRepo.saveFavoriteKitIds(widget.heroId, mergedFavorites);
      }

      final cache = {for (final kit in kits) kit.id: kit};

      if (mounted) {
        setState(() {
          _allKits = kits;
          _allowedEquipmentTypes = allowedTypes;
          _favoriteKitIds = mergedFavorites;
          _equipmentSlots = slots;
          _equippedSlotIds = alignedEquipped;
          _equippedKitIds = equippedActive;
          _classId = resolvedClassId ?? className;
          _normalizedClassId = normalizedClassName;
          _kitCache
            ..clear()
            ..addAll(cache);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${KitsTabText.loadKitsFailedPrefix}$e';
          _isLoading = false;
        });
      }
    }
  }

  List<EquipmentSlotConfig> _determineEquipmentSlots(
    ClassData? classData,
    String? subclassName,
  ) {
    if (classData == null) {
      return [
        const EquipmentSlotConfig(
          label: KitsTabText.equipmentSlotKitLabel,
          allowedTypes: ['kit'],
          index: 0,
        ),
      ];
    }

    final subclass = subclassName?.toLowerCase() ?? '';
    if (classData.classId == 'class_fury' && subclass == 'stormwight') {
      return [
        const EquipmentSlotConfig(
          label: KitsTabText.equipmentSlotStormwightLabel,
          allowedTypes: ['stormwight_kit'],
          index: 0,
        ),
      ];
    }

    final kitFeatures = <Map<String, dynamic>>[];
    final typesList = <String>[];

    for (final level in classData.levels) {
      for (final feature in level.features) {
        final name = feature.name.trim().toLowerCase();
        if (name == 'kit' || kitFeatureTypeMappings.containsKey(name)) {
          kitFeatures.add({'name': name, 'count': feature.count ?? 1});

          final mapped = kitFeatureTypeMappings[name];
          if (mapped != null) {
            typesList.addAll(mapped);
          } else {
            typesList.add('kit');
          }
        }
      }
    }

    if (kitFeatures.isEmpty) {
      return [
        const EquipmentSlotConfig(
          label: KitsTabText.equipmentSlotKitLabel,
          allowedTypes: ['kit'],
          index: 0,
        ),
      ];
    }

    final uniqueTypes = <String>[];
    final seen = <String>{};
    for (final type in typesList) {
      if (seen.add(type)) {
        uniqueTypes.add(type);
      }
    }

    final totalCount = kitFeatures.fold<int>(0, (sum, feature) {
      return sum + (feature['count'] as int);
    });

    if (totalCount <= 0) {
      return [
        const EquipmentSlotConfig(
          label: KitsTabText.equipmentSlotKitLabel,
          allowedTypes: ['kit'],
          index: 0,
        ),
      ];
    }

    final slots = <EquipmentSlotConfig>[];
    var index = 0;

    if (uniqueTypes.length > 1 && totalCount >= uniqueTypes.length) {
      for (final type in uniqueTypes) {
        slots.add(EquipmentSlotConfig(
          label: kitTypeDisplayName(type),
          allowedTypes: [type],
          index: index++,
        ));
      }
    } else {
      final sortedTypes = sortKitTypesByPriority(uniqueTypes);
      final displayName = sortedTypes.isNotEmpty
          ? kitTypeDisplayName(sortedTypes.first)
          : KitsTabText.equipmentSlotKitLabel;
      for (var i = 0; i < totalCount; i++) {
        final label = totalCount > 1 ? '$displayName ${i + 1}' : displayName;
        slots.add(EquipmentSlotConfig(
          label: label,
          allowedTypes: sortedTypes.isEmpty ? ['kit'] : sortedTypes,
          index: index++,
        ));
      }
    }

    return slots.isEmpty
        ? [
            const EquipmentSlotConfig(
              label: KitsTabText.equipmentSlotKitLabel,
              allowedTypes: ['kit'],
              index: 0,
            ),
          ]
        : slots;
  }

  /// Best-effort normalization of class ids from hero values.
  /// The data files use ids like "class_conduit"; hero values may store "conduit" or already the id.
  String? _normalizeClassId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.startsWith('class_')) return trimmed;
    return 'class_$trimmed';
  }

  Future<List<String?>> _alignEquipmentToSlots({
    required List<EquipmentSlotConfig> slots,
    required List<String?> equipmentIds,
    required dynamic db,
  }) async {
    if (slots.isEmpty) {
      return equipmentIds
          .where((id) => id != null && id.isNotEmpty)
          .cast<String?>()
          .toList();
    }

    final slotCount = slots.length;
    final result = List<String?>.filled(slotCount, null);
    final usedIds = <String>{};
    final equipmentTypes = <String, String>{};
    final normalizedIds = equipmentIds
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    for (final id in normalizedIds) {
      final component = await db.getComponentById(id);
      if (component != null) {
        equipmentTypes[id] = component.type;
      }
    }

    for (var i = 0; i < slotCount; i++) {
      final allowedTypes = slots[i].allowedTypes;
      for (final id in normalizedIds) {
        if (usedIds.contains(id)) continue;
        final type = equipmentTypes[id];
        if (type != null && allowedTypes.contains(type)) {
          result[i] = id;
          usedIds.add(id);
          break;
        }
      }
    }

    for (var i = 0; i < slotCount; i++) {
      if (result[i] != null) continue;
      for (final id in normalizedIds) {
        if (usedIds.contains(id)) continue;
        result[i] = id;
        usedIds.add(id);
        break;
      }
    }

    return result;
  }

  Future<void> _toggleFavorite(String kitId) async {
    final heroRepo = ref.read(heroRepositoryProvider);
    final newFavorites = _favoriteKitIds.contains(kitId)
        ? _favoriteKitIds.where((id) => id != kitId).toList()
        : [..._favoriteKitIds, kitId];

    try {
      await heroRepo.saveFavoriteKitIds(widget.heroId, newFavorites);
      setState(() {
        _favoriteKitIds = newFavorites;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${KitsTabText.updateFavoritesFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _swapToKit(model.Component kit) async {
    if (_equipmentSlots.isEmpty && _equippedKitIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KitsTabText.noEquipModsSnack)),
        );
      }
      return;
    }

    // Count how many slots accept this kit type
    final slotsForType = _equipmentSlots
        .where((slot) => slot.allowedTypes.contains(kit.type))
        .length;

    // Find currently equipped kits of the same type
    final equippedOfSameType = _equippedKitIds.where((id) {
      final equippedKit = _findKitById(id);
      return equippedKit != null && equippedKit.type == kit.type;
    }).toList();

    // Check if there's an empty slot for this kit type
    final hasEmptySlot = slotsForType > equippedOfSameType.length;

    if (hasEmptySlot) {
      // There's an empty slot - just equip without replacing
      final confirm = await _showEquipConfirmation(kit);
      if (confirm == true) {
        await _applyKitSwapDirect(kit, null);
      }
      return;
    }

    // All slots are full - need to replace an existing kit
    if (equippedOfSameType.isEmpty) {
      // No kits of same type but no slots either - shouldn't happen, but handle it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${KitsTabText.cannotEquipKitPrefix}${kit.name}'
              '${KitsTabText.cannotEquipKitInfix}${kitTypeDisplayName(kit.type)}'
              '${KitsTabText.cannotEquipKitSuffix}',
            ),
          ),
        );
      }
      return;
    }

    // If only one kit of this type, swap it directly
    if (equippedOfSameType.length == 1) {
      final kitToReplace = _findKitById(equippedOfSameType.first);
      final confirm = await _showSwapConfirmation(kit, kitToReplace);
      if (confirm == true) {
        await _applyKitSwapDirect(kit, equippedOfSameType.first);
      }
      return;
    }

    // Multiple kits of same type - ask user which one to replace
    final kitIdToReplace = await _selectKitToReplace(kit, equippedOfSameType);
    if (kitIdToReplace == null) return;

    await _applyKitSwapDirect(kit, kitIdToReplace);
  }

  Future<bool?> _showEquipConfirmation(model.Component kit) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(KitsTabText.equipKitDialogTitle),
        content: Text(
          '${KitsTabText.equipKitDialogContentPrefix}${kit.name}${KitsTabText.equipKitDialogContentSuffix}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(KitsTabText.equipKitDialogCancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(KitsTabText.equipKitDialogConfirmAction),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSwapConfirmation(
      model.Component newKit, model.Component? existingKit) {
    final message = existingKit != null
        ? '${KitsTabText.swapKitDialogReplacePrefix}${existingKit.name}${KitsTabText.swapKitDialogReplaceInfix}${newKit.name}${KitsTabText.swapKitDialogReplaceSuffix}'
        : '${KitsTabText.swapKitDialogEquipPrefix}${newKit.name}${KitsTabText.swapKitDialogEquipSuffix}';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(KitsTabText.swapKitDialogTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(KitsTabText.swapKitDialogCancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(KitsTabText.swapKitDialogConfirmAction),
          ),
        ],
      ),
    );
  }

  Future<String?> _selectKitToReplace(
      model.Component newKit, List<String> equippedKitIds) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            '${KitsTabText.selectKitToReplaceTitlePrefix}${newKit.name}${KitsTabText.selectKitToReplaceTitleSuffix}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: equippedKitIds.length,
              itemBuilder: (context, index) {
                final kitId = equippedKitIds[index];
                final existingKit = _findKitById(kitId);
                final kitName =
                    existingKit?.name ?? KitsTabText.unknownKitLabel;
                final kitType = existingKit != null
                    ? kitTypeDisplayName(existingKit.type)
                    : '';

                return ListTile(
                  leading: Icon(
                    _getKitIcon(existingKit?.type ?? 'kit'),
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(kitName),
                  subtitle: Text(kitType),
                  onTap: () => Navigator.of(context).pop(kitId),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(KitsTabText.selectKitToReplaceCancelAction),
            ),
          ],
        );
      },
    );
  }

  IconData _getKitIcon(String type) {
    switch (type) {
      case 'kit':
        return Icons.shield;
      case 'stormwight_kit':
        return Icons.flash_on;
      case 'psionic_augmentation':
        return Icons.psychology;
      case 'ward':
        return Icons.security;
      case 'prayer':
        return Icons.auto_fix_high;
      case 'enchantment':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }

  Future<void> _applyKitSwapDirect(
      model.Component kit, String? kitIdToReplace) async {
    try {
      final heroRepo = ref.read(heroRepositoryProvider);
      final db = ref.read(appDatabaseProvider);

      // Work with the raw equipped IDs, not the slot-aligned ones
      final updatedKitIds = List<String>.from(_equippedKitIds);

      if (kitIdToReplace != null) {
        // Replace the specific kit
        final indexToReplace = updatedKitIds.indexOf(kitIdToReplace);
        if (indexToReplace >= 0) {
          updatedKitIds[indexToReplace] = kit.id;
        } else {
          updatedKitIds.add(kit.id);
        }
      } else {
        // No kit to replace, just add the new one
        updatedKitIds.add(kit.id);
      }

      // Convert to nullable list for saving
      final updatedSlots = updatedKitIds.map<String?>((id) => id).toList();

      await heroRepo.saveEquipmentIds(widget.heroId, updatedSlots);
      await db.upsertHeroValue(
        heroId: widget.heroId,
        key: 'basics.equipment',
        jsonMap: {'ids': updatedSlots},
      );

      await _recalculateAndSaveBonuses(heroRepo, updatedSlots);

      ref.invalidate(heroRepositoryProvider);
      ref.invalidate(heroEquipmentBonusesProvider(widget.heroId));
      ref.invalidate(heroValuesProvider(widget.heroId));

      _kitCache[kit.id] = kit;

      // Re-align for slot display
      final alignedEquipped = await _alignEquipmentToSlots(
        slots: _equipmentSlots,
        equipmentIds: updatedSlots,
        db: db,
      );

      if (mounted) {
        setState(() {
          _equippedSlotIds = alignedEquipped;
          _equippedKitIds = updatedKitIds;
        });

        final replacedName = kitIdToReplace != null
            ? _findKitById(kitIdToReplace)?.name ?? KitsTabText.previousKitLabel
            : null;
        final message = replacedName != null
            ? '${KitsTabText.replacedKitSnackPrefix}$replacedName${KitsTabText.replacedKitSnackInfix}${kit.name}${KitsTabText.replacedKitSnackSuffix}'
            : '${KitsTabText.equippedKitSnackPrefix}${kit.name}${KitsTabText.equippedKitSnackSuffix}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${KitsTabText.swapKitFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recalculateAndSaveBonuses(
      HeroRepository heroRepo, List<String?> equipmentSlotIds) async {
    final db = ref.read(appDatabaseProvider);
    final level = await heroRepo.getHeroLevel(widget.heroId);

    // Use KitGrantsService to apply all kit grants (including stat mods like decrease_total)
    final kitGrantsService = KitGrantsService(db);
    await kitGrantsService.applyKitGrants(
      heroId: widget.heroId,
      equipmentIds: equipmentSlotIds,
      heroLevel: level,
    );

    // Also invalidate hero assembly to reload stat mods
    ref.invalidate(heroAssemblyProvider(widget.heroId));
  }

  model.Component? _findKitById(String kitId) {
    final cached = _kitCache[kitId];
    if (cached != null) return cached;
    for (final kit in _allKits) {
      if (kit.id == kitId) {
        _kitCache[kitId] = kit;
        return kit;
      }
    }
    return null;
  }

  /// Gets the equipped slot index for a kit (for display purposes)
  int? _getEquippedSlotIndex(String kitId) {
    for (var i = 0; i < _equippedSlotIds.length; i++) {
      if (_equippedSlotIds[i] == kitId) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: NavigationTheme.kitsColor));
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

    final favoriteKits =
        _allKits.where((k) => _favoriteKitIds.contains(k.id)).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${KitsTabText.favoriteKitsHeaderPrefix}${favoriteKits.length}${KitsTabText.favoriteKitsHeaderSuffix}',
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
              child: favoriteKits.isEmpty
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
                            KitsTabText.noFavoriteKitsTitle,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            KitsTabText.noFavoriteKitsSubtitle,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: favoriteKits.length,
                      itemBuilder: (context, index) {
                        final kit = favoriteKits[index];
                        final isEquipped = _equippedKitIds.contains(kit.id);
                        final equippedSlotIndex = _getEquippedSlotIndex(kit.id);
                        final slotLabel = equippedSlotIndex != null
                            ? _equipmentSlots[equippedSlotIndex].label
                            : null;

                        return FavoriteKitCardWrapper(
                          kit: kit,
                          isEquipped: isEquipped,
                          equippedSlotLabel: slotLabel,
                          onSwap: () => _swapToKit(kit),
                          onRemoveFavorite: () => _toggleFavorite(kit.id),
                        );
                      },
                    ),
            ),
          ],
        ),
        // Floating Action Button for adding favorites
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'kits_tab_fab',
            onPressed: _showAddFavoriteDialog,
            tooltip: KitsTabText.addFavoriteFabTooltip,
            backgroundColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: NavigationTheme.kitsColor, width: 1.5),
            ),
            child: Icon(Icons.add, color: NavigationTheme.kitsColor, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddFavoriteDialog() async {
    final db = ref.read(appDatabaseProvider);

    await showDialog<void>(
      context: context,
      builder: (context) => AddFavoriteKitDialog(
        heroId: widget.heroId,
        db: db,
        existingFavoriteIds: _favoriteKitIds.toSet(),
        onKitSelected: (kitId) async {
          await _addKitToFavorites(kitId);
        },
      ),
    );
  }

  Future<void> _addKitToFavorites(String kitId) async {
    final heroRepo = ref.read(heroRepositoryProvider);
    final db = ref.read(appDatabaseProvider);

    // Add to favorites
    final newFavorites = [..._favoriteKitIds, kitId];

    try {
      await heroRepo.saveFavoriteKitIds(widget.heroId, newFavorites);

      // Load the kit component to add to cache
      final component = await db.getComponentById(kitId);
      if (component != null && mounted) {
        // Parse the JSON data from the DB component
        final Map<String, dynamic> parsedData = component.dataJson.isNotEmpty
            ? jsonDecode(component.dataJson) as Map<String, dynamic>
            : <String, dynamic>{};

        setState(() {
          _favoriteKitIds = newFavorites;
          // Add to allKits if not already present
          if (!_allKits.any((k) => k.id == kitId)) {
            _allKits.add(model.Component(
              id: component.id,
              name: component.name,
              type: component.type,
              data: parsedData,
              source: component.source,
              parentId: component.parentId,
            ));
          }
          _kitCache[kitId] = _allKits.firstWhere((k) => k.id == kitId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${KitsTabText.addedFavoriteSnackPrefix}${component.name}${KitsTabText.addedFavoriteSnackSuffix}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${KitsTabText.addFavoriteFailedPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
