import 'package:flutter/material.dart';
import '../../core/theme/kit_theme.dart';

/// Reusable components for kit cards with consistent theming
class KitComponents {
  
  /// Creates a themed chip for preview and equipment display
  static Widget themedChip({
    required BuildContext context,
    required String text,
    required MaterialColor primaryColor,
    bool isBold = false,
  }) {
    return Chip(
      label: Text(
        text,
        style: (isBold ? KitTheme.chipBoldTextStyle : KitTheme.chipTextStyle).copyWith(
          color: KitTheme.getChipTextColor(context, primaryColor),
        ),
      ),
      backgroundColor: KitTheme.getChipBackgroundColor(context, primaryColor),
      side: BorderSide(
        color: KitTheme.getChipBorderColor(context, primaryColor),
        width: 0.8,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  /// Creates a themed chip for bonus display (like stamina, speed, etc.)
  static Widget bonusChip({
    required BuildContext context,
    required String text,
    required MaterialColor primaryColor,
  }) {
    return Chip(
      label: Text(
        text,
        style: KitTheme.chipBoldTextStyle.copyWith(
          color: KitTheme.getChipRowTextColor(context, primaryColor),
        ),
      ),
      backgroundColor: KitTheme.getChipRowBackgroundColor(context, primaryColor),
      side: BorderSide(
        color: KitTheme.getChipRowBorderColor(context, primaryColor),
        width: 0.8,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    );
  }

  /// Creates a themed section header
  static Widget sectionHeader({
    required BuildContext context,
    required String label,
    required MaterialColor primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KitTheme.getSectionHeaderBackgroundColor(context, primaryColor),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: KitTheme.getSectionHeaderBorderColor(context, primaryColor),
            width: 3,
          ),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: KitTheme.sectionHeaderStyle.copyWith(
          color: KitTheme.getSectionHeaderTextColor(context, primaryColor),
        ),
      ),
    );
  }

  /// Creates a complete themed section with header and content
  static Widget section({
    required BuildContext context,
    required String label,
    required Widget child,
    required MaterialColor primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(
            context: context,
            label: label,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  /// Creates a themed echelon table with box/tab layout
  static Widget echelonTable({
    required BuildContext context,
    required Map<String, dynamic> data,
    required MaterialColor primaryColor,
  }) {
    final entries = [
      MapEntry('1st', data['1st_echelon']),
      MapEntry('2nd', data['2nd_echelon']),
      MapEntry('3rd', data['3rd_echelon']),
    ];

    final validEntries = entries.where((e) => e.value != null).toList();
    
    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: validEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final mapEntry = entry.value;
        final isFirst = index == 0;
        final isLast = index == validEntries.length - 1;
        
        return Container(
          margin: EdgeInsets.only(right: isLast ? 0 : 0), // No gap between boxes
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: KitTheme.getEchelonBoxBackgroundColor(context, primaryColor),
              border: Border.all(
                color: KitTheme.getEchelonBoxBorderColor(context, primaryColor),
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst ? 6 : 0),
                bottomLeft: Radius.circular(isFirst ? 6 : 0),
                topRight: Radius.circular(isLast ? 6 : 0),
                bottomRight: Radius.circular(isLast ? 6 : 0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mapEntry.key,
                  style: KitTheme.echelonLabelStyle.copyWith(
                    color: KitTheme.getEchelonLabelColor(context, primaryColor),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mapEntry.value}',
                  style: KitTheme.echelonValueStyle.copyWith(
                    color: KitTheme.getEchelonValueColor(context, primaryColor),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Creates a grouped tier bonus box with title and connected tabs (for damage bonuses)
  static Widget tierBonusBox({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> data,
    required MaterialColor primaryColor,
  }) {  
    final entries = [
      MapEntry('Tier 1\n(11<)', data['1st_tier']),
      MapEntry('Tier 2\n(12-16)', data['2nd_tier']),
      MapEntry('Tier 3\n(17+)', data['3rd_tier']),
    ];

    final validEntries = entries.where((e) => e.value != null).toList();
    
    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KitTheme.getSectionHeaderBackgroundColor(context, primaryColor).withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: KitTheme.getSectionHeaderBorderColor(context, primaryColor).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title header
            Text(
              title.toUpperCase(),
              style: KitTheme.sectionHeaderStyle.copyWith(
                color: KitTheme.getSectionHeaderTextColor(context, primaryColor),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Connected tier boxes
            Row(
              children: validEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final isFirst = index == 0;
                final isLast = index == validEntries.length - 1;
                
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: KitTheme.getEchelonInnerBoxBackgroundColor(context, primaryColor),
                      border: Border.all(
                        color: KitTheme.getEchelonInnerBoxBorderColor(context, primaryColor),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isFirst ? 4 : 0),
                        bottomLeft: Radius.circular(isFirst ? 4 : 0),
                        topRight: Radius.circular(isLast ? 4 : 0),
                        bottomRight: Radius.circular(isLast ? 4 : 0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mapEntry.key,
                          style: KitTheme.echelonLabelStyle.copyWith(
                            color: KitTheme.getEchelonInnerLabelColor(context, primaryColor),
                            fontSize: 8.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '+${mapEntry.value}',
                          style: KitTheme.echelonValueStyle.copyWith(
                            color: KitTheme.getEchelonInnerValueColor(context, primaryColor),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
    );
  }

  /// Creates a grouped echelon bonus box with title and connected tabs (for distance bonuses)
  static Widget echelonBonusBox({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> data,
    required MaterialColor primaryColor,
  }) {
    final entries = [
      MapEntry('1st\nEchelon', data['1st_echelon']),
      MapEntry('2nd\nEchelon', data['2nd_echelon']),
      MapEntry('3rd\nEchelon', data['3rd_echelon']),
    ];

    final validEntries = entries.where((e) => e.value != null).toList();
    
    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KitTheme.getSectionHeaderBackgroundColor(context, primaryColor).withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: KitTheme.getSectionHeaderBorderColor(context, primaryColor).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title header
            Text(
              title.toUpperCase(),
              style: KitTheme.sectionHeaderStyle.copyWith(
                color: KitTheme.getSectionHeaderTextColor(context, primaryColor),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Connected echelon boxes
            Row(
              children: validEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final isFirst = index == 0;
                final isLast = index == validEntries.length - 1;
                
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: KitTheme.getEchelonInnerBoxBackgroundColor(context, primaryColor),
                      border: Border.all(
                        color: KitTheme.getEchelonInnerBoxBorderColor(context, primaryColor),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isFirst ? 4 : 0),
                        bottomLeft: Radius.circular(isFirst ? 4 : 0),
                        topRight: Radius.circular(isLast ? 4 : 0),
                        bottomRight: Radius.circular(isLast ? 4 : 0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mapEntry.key,
                          style: KitTheme.echelonLabelStyle.copyWith(
                            color: KitTheme.getEchelonInnerLabelColor(context, primaryColor),
                            fontSize: 9,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '+${mapEntry.value}',
                          style: KitTheme.echelonValueStyle.copyWith(
                            color: KitTheme.getEchelonInnerValueColor(context, primaryColor),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
    );
  }

  /// Creates a row of themed bonus chips
  static Widget chipRow({
    required BuildContext context,
    required List<String> items,
    required MaterialColor primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((item) => bonusChip(
          context: context,
          text: item,
          primaryColor: primaryColor,
        )).toList(),
      ),
    );
  }

  /// Creates a wrap of themed preview chips
  static Widget previewChips({
    required BuildContext context,
    required List<String> items,
    required MaterialColor primaryColor,
  }) {
    return items.isEmpty
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items.map((item) => themedChip(
              context: context,
              text: item,
              primaryColor: primaryColor,
            )).toList(),
          );
  }

  /// Creates a themed badge for kit types
  static Widget kitBadge({
    required String kitType,
    required String displayName,
  }) {
    final colorScheme = KitTheme.getColorScheme(kitType);
    final emoji = KitTheme.getKitTypeEmoji(kitType);
    
    return Chip(
      label: Text(
        '$emoji $displayName',
        style: KitTheme.badgeTextStyle,
      ),
      backgroundColor: colorScheme.badgeBackground,
      side: BorderSide(
        color: colorScheme.borderColor,
        width: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Helper method to format bonus text with emoji
  static String formatBonusWithEmoji(String bonusType, dynamic value) {
    final emoji = KitTheme.getBonusEmoji(bonusType);
    final label = _getBonusLabel(bonusType);
    
    // For characteristics, don't add a plus sign since it's a score, not a bonus
    if (bonusType.toLowerCase() == 'characteristic_score' || bonusType.toLowerCase() == 'characteristic') {
      return '$emoji $label $value';
    }
    
    return '$emoji $label +$value';
  }

  /// Helper method to get human-readable bonus labels
  static String _getBonusLabel(String bonusType) {
    switch (bonusType.toLowerCase()) {
      case 'stamina_bonus':
      case 'stamina':
        return 'Stamina';
      case 'speed_bonus':
      case 'speed':
        return 'Speed';
      case 'disengage_bonus':
      case 'disengage':
        return 'Disengage';
      case 'damage_bonus':
      case 'bonus_damage':
      case 'damage':
        return 'Damage';
      case 'ranged_distance_bonus':
      case 'ranged_distance':
        return 'Ranged Distance';
      case 'melee_distance_bonus':
      case 'melee_distance':
        return 'Melee Distance';
      case 'stability_bonus':
      case 'stability':
        return 'Stability';
      case 'characteristic_score':
      case 'characteristic':
        return 'Characteristic';
      default:
        return bonusType.replaceAll('_', ' ').split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }
}