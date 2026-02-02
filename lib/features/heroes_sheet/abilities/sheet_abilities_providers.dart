import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/theme/semantic/hero_entry_tokens.dart';

/// Provider that watches hero ability IDs for a specific hero.
/// 
/// All abilities are now stored in hero_entries with entryType='ability'.
/// Sources include:
/// - manual_choice: abilities chosen directly (class ability picks)
/// - ancestry: abilities from ancestry traits
/// - complication: abilities from complications
/// - kit: abilities from equipped kits
/// - perk: abilities from perks
/// - title: abilities from title benefits
/// - class_feature: abilities from class features
final heroAbilityIdsProvider =
    StreamProvider.family<List<String>, String>((ref, heroId) {
  final db = ref.watch(appDatabaseProvider);

  // Watch all abilities from hero_entries table
  // This automatically includes all sources (ancestry, complication, kit, perk, title, etc.)
  return db.watchHeroComponentIds(heroId, HeroEntryTypes.ability);
});

/// Provider that watches hero equipment IDs for a specific hero
final heroEquipmentIdsProvider =
    StreamProvider.family<List<String?>, String>((ref, heroId) {
  final db = ref.watch(appDatabaseProvider);

  // Watch equipment.slots from hero_config (primary storage)
  return db
      .watchHeroConfigValue(heroId, HeroConfigKeys.equipmentSlots)
      .asyncMap((config) async {
    if (config != null && config['ids'] is List) {
      return (config['ids'] as List)
          .map<String?>((e) => e == null ? null : e.toString())
          .toList();
    }

    // Fall back to hero_entries for equipment without slot ordering
    final entryIds = await db.getHeroEntryIds(heroId, HeroEntryTypes.equipment);
    if (entryIds.isNotEmpty) return entryIds.map<String?>((e) => e).toList();

    // Fall back to legacy kit entry
    final kitEntry = await db.getSingleHeroEntryId(heroId, HeroEntryTypes.kit);
    if (kitEntry != null) return <String?>[kitEntry];

    // Final fallback: legacy hero_values
    final legacyValues = await db.getHeroValues(heroId);
    for (final value in legacyValues) {
      if (value.key == HeroConfigKeys.basicsEquipment) {
        if (value.jsonValue != null) {
          try {
            final decoded = jsonDecode(value.jsonValue!);
            if (decoded is Map && decoded['ids'] is List) {
              return (decoded['ids'] as List)
                  .map<String?>((e) => e == null ? null : e.toString())
                  .toList();
            }
          } catch (_) {}
        }
      } else if (value.key == HeroConfigKeys.basicsKit) {
        final kitId = value.textValue;
        if (kitId != null && kitId.isNotEmpty) {
          return <String?>[kitId];
        }
      }
    }
    return <String?>[];
  });
});
