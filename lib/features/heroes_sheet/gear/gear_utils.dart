import 'package:flutter/material.dart';

/// Display name for a kit type identifier.
String kitTypeDisplayName(String type) {
  switch (type) {
    case 'psionic_augmentation':
      return 'Psionic Augmentation';
    case 'enchantment':
      return 'Enchantment';
    case 'prayer':
      return 'Prayer';
    case 'ward':
      return 'Ward';
    case 'stormwight_kit':
      return 'Stormwight Kit';
    default:
      if (type.isEmpty) return 'Kit';
      return type[0].toUpperCase() + type.substring(1);
  }
}

/// Icon for a kit type identifier.
IconData kitTypeIcon(String type) {
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
const Map<String, String> kitTypeLabels = {
  'kit': 'Kits',
  'stormwight_kit': 'Stormwight Kits',
  'psionic_augmentation': 'Augmentations',
  'ward': 'Wards',
  'prayer': 'Prayers',
  'enchantment': 'Enchantments',
};

/// Icons for kit type dropdown items.
const Map<String, IconData> kitTypeIcons = {
  'kit': Icons.shield,
  'stormwight_kit': Icons.flash_on,
  'psionic_augmentation': Icons.psychology,
  'ward': Icons.security,
  'prayer': Icons.auto_fix_high,
  'enchantment': Icons.auto_awesome,
};

/// Get display name for treasure type.
String getTreasureGroupName(String type) {
  switch (type) {
    case 'consumable':
      return 'Consumables';
    case 'trinket':
      return 'Trinkets';
    case 'artifact':
      return 'Artifacts';
    case 'leveled_treasure':
      return 'Leveled Equipment';
    default:
      return 'Other';
  }
}

/// Get user-friendly name for treasure type.
String getTreasureTypeName(String type) {
  switch (type) {
    case 'consumable':
      return 'Consumable';
    case 'trinket':
      return 'Trinket';
    case 'artifact':
      return 'Artifact';
    case 'leveled_treasure':
      return 'Leveled Equipment';
    default:
      return type;
  }
}

/// Get icon for treasure type.
IconData getTreasureIcon(String type) {
  switch (type) {
    case 'consumable':
      return Icons.local_drink;
    case 'trinket':
      return Icons.diamond;
    case 'artifact':
      return Icons.auto_awesome;
    case 'leveled_treasure':
      return Icons.shield;
    default:
      return Icons.category;
  }
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
