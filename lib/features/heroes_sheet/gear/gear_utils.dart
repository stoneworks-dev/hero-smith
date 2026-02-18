import 'package:flutter/material.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/text/heroes_sheet/gear_utils_text.dart';
import '../../../core/theme/app_icon_data.dart';
import '../../../core/theme/app_icons.dart';

/// Display name for a kit type identifier.
String kitTypeDisplayName(String type) {
  switch (type) {
    case 'psionic_augmentation':
      return GearUtilsText.psionicAugmentation;
    case 'enchantment':
      return GearUtilsText.enchantment;
    case 'prayer':
      return GearUtilsText.prayer;
    case 'ward':
      return GearUtilsText.ward;
    case 'stormwight_kit':
      return GearUtilsText.stormwightKit;
    default:
      if (type.isEmpty) return GearUtilsText.kit;
      return type[0].toUpperCase() + type.substring(1);
  }
}

/// Icon for a kit type identifier.
AppIconData kitTypeIcon(String type) => KitIcons.fromType(type);

/// Configuration for an equipment slot.
class EquipmentSlotConfig {
  const EquipmentSlotConfig({
    required this.label,
    required this.allowedTypes,
    required this.index,
  });

  final String label;
  final List<String> allowedTypes;
  final int index;
}

/// Mapping from kit feature names to equipment types.
const Map<String, List<String>> kitFeatureTypeMappings = {
  'kit': ['kit'],
  'psionic augmentation': ['psionic_augmentation'],
  'enchantment': ['enchantment'],
  'prayer': ['prayer'],
  'elementalist ward': ['ward'],
  'talent ward': ['ward'],
  'conduit ward': ['ward'],
  'ward': ['ward'],
};

/// Priority order for sorting kit types.
const List<String> kitTypePriority = [
  'kit',
  'psionic_augmentation',
  'enchantment',
  'prayer',
  'ward',
  'stormwight_kit',
];

/// Labels for kit type dropdown items.
final Map<String, String> kitTypeLabels = {
  'kit': GearUtilsText.kits,
  'stormwight_kit': GearUtilsText.stormwightKits,
  'psionic_augmentation': GearUtilsText.augmentations,
  'ward': GearUtilsText.wards,
  'prayer': GearUtilsText.prayers,
  'enchantment': GearUtilsText.enchantments,
};

/// Icons for kit type dropdown items.
const Map<String, AppIconData> kitTypeIcons = KitIcons.byType;

/// Get display name for treasure type.
String getTreasureGroupName(String type) {
  switch (type) {
    case 'consumable':
      return GearUtilsText.consumables;
    case 'trinket':
      return GearUtilsText.trinkets;
    case 'artifact':
      return GearUtilsText.artifacts;
    case 'leveled_treasure':
      return GearUtilsText.leveledEquipment;
    default:
      return GearUtilsText.other;
  }
}

/// Get user-friendly name for treasure type.
String getTreasureTypeName(String type) {
  switch (type) {
    case 'consumable':
      return GearUtilsText.consumable;
    case 'trinket':
      return GearUtilsText.trinket;
    case 'artifact':
      return GearUtilsText.artifact;
    case 'leveled_treasure':
      return GearUtilsText.leveledEquipment;
    default:
      return type;
  }
}

/// Get icon for treasure type.
AppIconData getTreasureIcon(String type) => TreasureIcons.fromType(type);

/// Get icon for a treasure component, resolving leveled subtypes and artifacts.
AppIconData getComponentTreasureIcon(model.Component component) {
  final type = component.type.toLowerCase();
  if (type == 'leveled_treasure') {
    final leveledType = component.data['leveled_type'] as String?;
    return TreasureIcons.fromLeveledType(leveledType);
  }
  if (type == 'artifact') {
    return TreasureIcons.fromArtifactId(component.id);
  }
  return TreasureIcons.fromType(type);
}

/// Get color based on item level.
Color getLevelColor(int level) {
  if (level <= 2) {
    return Colors.green.shade400;
  } else if (level <= 4) {
    return Colors.blue.shade400;
  } else if (level <= 6) {
    return Colors.purple.shade400;
  } else if (level <= 8) {
    return Colors.orange.shade400;
  } else {
    return Colors.red.shade400;
  }
}

/// Sort kit types by priority order.
List<String> sortKitTypesByPriority(Iterable<String> types) {
  final seen = <String>{};
  final sorted = <String>[];

  for (final type in kitTypePriority) {
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
