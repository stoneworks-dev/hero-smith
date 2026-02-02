import 'package:flutter/material.dart';

/// Accent colors for kits page tabs and equipment types.
class KitPageTheme {
  KitPageTheme._();

  static const Color kits = Color(0xFF00ACC1);
  static const Color stormwight = Color(0xFF5C6BC0);
  static const Color augmentation = Color(0xFF7E57C2);
  static const Color enchantment = Color(0xFFFFB300);
  static const Color prayer = Color(0xFFFF8A65);
  static const Color ward = Color(0xFFAB47BC);

  static const tabData = [
    (label: 'Kits', color: kits),
    (label: 'Stormwight', color: stormwight),
    (label: 'Augmentations', color: augmentation),
    (label: 'Enchantments', color: enchantment),
    (label: 'Prayers', color: prayer),
    (label: 'Wards', color: ward),
  ];

  static Color accentForType(String type) {
    switch (type.toLowerCase()) {
      case 'kit':
        return kits;
      case 'stormwight_kit':
        return stormwight;
      case 'psionic_augmentation':
        return augmentation;
      case 'enchantment':
        return enchantment;
      case 'prayer':
        return prayer;
      case 'ward':
        return ward;
      default:
        return kits;
    }
  }

  static const Map<String, Color> statColors = {
    'STM': Color(0xFFEF5350),
    'SPD': Color(0xFF42A5F5),
    'STB': Color(0xFF66BB6A),
    'DSG': Color(0xFFFFB74D),
  };
}
