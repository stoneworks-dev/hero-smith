import 'package:flutter/material.dart';
import '../../core/models/component.dart';
import '../../core/services/ability_data_service.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icon_data.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/kit_page_theme.dart';
import '../../core/theme/form_theme.dart';
import '../../core/text/widgets/equipment_card_text.dart';
import '../abilities/ability_expandable_item.dart';

/// Modern equipment card with clean styling matching the TreasureCard design.
/// 
/// Handles: kits, stormwight kits, modifiers (augmentations, enchantments, prayers), wards
class EquipmentCard extends StatefulWidget {
  final Component component;
  final String? badgeLabel;
  final bool initiallyExpanded;

  const EquipmentCard({
    super.key,
    required this.component,
    this.badgeLabel,
    this.initiallyExpanded = false,
  });

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Component> _signatureAbilities = [];
  bool _loadingAbility = false;
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadSignatureAbility();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _loadSignatureAbility() async {
    final signatureAbilityData = widget.component.data['signature_ability'];
    if (signatureAbilityData == null) return;

    final List<String> abilityNames;
    if (signatureAbilityData is String) {
      if (signatureAbilityData.isEmpty) return;
      abilityNames = [signatureAbilityData];
    } else if (signatureAbilityData is List) {
      abilityNames = signatureAbilityData.cast<String>();
      if (abilityNames.isEmpty) return;
    } else {
      return;
    }

    setState(() => _loadingAbility = true);

    try {
      final abilityService = AbilityDataService();
      final library = await abilityService.loadLibrary();
      final loadedAbilities = <Component>[];

      for (final abilityName in abilityNames) {
        final ability = library.find(abilityName);
        if (ability != null) {
          loadedAbilities.add(ability);
        }
      }

      if (mounted) {
        setState(() {
          _signatureAbilities = loadedAbilities;
          _loadingAbility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAbility = false);
      }
    }
  }

  Color _getAccentColor() {
    final type = widget.component.type.toLowerCase();
    return KitPageTheme.accentForType(type);
  }

  AppIconData _getTypeIcon() {
    final type = widget.component.type.toLowerCase();
    return KitIcons.fromType(type);
  }

  String _getTypeLabel() {
    if (widget.badgeLabel != null) return widget.badgeLabel!.toUpperCase();
    final type = widget.component.type.toLowerCase();
    switch (type) {
      case 'kit':
        return 'KIT';
      case 'stormwight_kit':
        return 'STORMWIGHT KIT';
      case 'psionic_augmentation':
        return 'AUGMENTATION';
      case 'enchantment':
        return 'ENCHANTMENT';
      case 'prayer':
        return 'PRAYER';
      case 'ward':
        return 'WARD';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final accentColor = _getAccentColor();

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent stripe
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                    bottomLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, accentColor),
                      const SizedBox(height: 10),
                      _buildQuickStats(context, accentColor),
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: _buildExpandedContent(context, accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIcon(
            _getTypeIcon(),
            color: accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        // Name and badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.component.name,
                style: const TextStyle(
                  color: FormTheme.textBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              _buildBadge(_getTypeLabel(), accentColor),
            ],
          ),
        ),
        // Expand/collapse indicator
        RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.expand_more,
            color: FormTheme.textMuted,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Color accentColor) {
    final data = widget.component.data;
    final stamina = data['stamina_bonus'] as int?;
    final speed = data['speed_bonus'] as int?;
    final stability = data['stability_bonus'] as int?;
    final disengage = data['disengage_bonus'] as int?;
    final characteristicScore = data['characteristic_score'] as String?;

    final stats = <Widget>[];

    if (stamina != null && stamina > 0) {
      stats.add(_buildStatChip('STM', '+$stamina', KitPageTheme.statColors['STM']!));
    }
    if (speed != null && speed > 0) {
      stats.add(_buildStatChip('SPD', '+$speed', KitPageTheme.statColors['SPD']!));
    }
    if (stability != null && stability > 0) {
      stats.add(_buildStatChip('STB', '+$stability', KitPageTheme.statColors['STB']!));
    }
    if (disengage != null && disengage > 0) {
      stats.add(_buildStatChip('DSG', '+$disengage', KitPageTheme.statColors['DSG']!));
    }
    if (characteristicScore != null && characteristicScore.isNotEmpty) {
      stats.add(_buildStatChip('CHAR', characteristicScore, accentColor));
    }

    // Add equipment chips if collapsed
    if (!_isExpanded) {
      final equipment = data['equipment'] as Map<String, dynamic>?;
      if (equipment != null) {
        stats.addAll(_buildEquipmentChips(equipment, accentColor));
      }
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: stats,
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEquipmentChips(Map<String, dynamic> equipment, Color accentColor) {
    final armor = (equipment['armor'] as Map?)?.cast<String, dynamic>() ?? {};
    final weapons = (equipment['weapons'] as Map?)?.cast<String, dynamic>() ?? {};
    final chips = <Widget>[];

    for (final entry in armor.entries) {
      if (entry.value == true) {
        chips.add(_buildEquipmentIconChip(
          KitEquipmentIcons.fromArmorType(entry.key),
          _humanReadableEquipment(entry.key),
          KitPageTheme.statColors['SPD']!,
        ));
      }
    }

    for (final entry in weapons.entries) {
      if (entry.value == true) {
        chips.add(_buildEquipmentIconChip(
          KitEquipmentIcons.fromWeaponType(entry.key),
          _humanReadableEquipment(entry.key),
          KitPageTheme.statColors['STM']!,
        ));
      }
    }
    return chips;
  }

  Widget _buildEquipmentChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEquipmentIconChip(AppIconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTierRow(AppIconData icon, String label, Map<String, dynamic> data, bool isTier) {
    final key1 = isTier ? '1st_tier' : '1st_echelon';
    final key2 = isTier ? '2nd_tier' : '2nd_echelon';
    final key3 = isTier ? '3rd_tier' : '3rd_echelon';

    final v1 = data[key1];
    final v2 = data[key2];
    final v3 = data[key3];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(icon, size: 14, color: FormTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FormTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (v1 != null) _buildTierBox(isTier ? 'T1' : 'E1', '+$v1', isTier ? '≤11' : '1st'),
            if (v2 != null) _buildTierBox(isTier ? 'T2' : 'E2', '+$v2', isTier ? '12-16' : '2nd'),
            if (v3 != null) _buildTierBox(isTier ? 'T3' : 'E3', '+$v3', isTier ? '17+' : '3rd'),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, Color accentColor) {
    final data = widget.component.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Description
        if (data['description'] != null) ...[
          _buildSection(
            title: EquipmentCardText.description,
            icon: KitIcons.fromType(widget.component.type.toLowerCase()),
            accentColor: accentColor,
            content: Text(
              data['description'] as String,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],

        // Equipment section
        _buildEquipmentSection(context, data, accentColor),

        // Damage bonuses
        _buildDamageBonusSection(context, data, accentColor),

        // Distance bonuses
        _buildDistanceBonusSection(context, data, accentColor),

        // Stormwight-specific: lightning damage
        if (data['lightning_damage'] != null)
          _buildLightningDamageSection(context, data, accentColor),

        // Ward-specific: characteristic and effect
        if (data['ward_effect'] != null)
          _buildSection(
            title: EquipmentCardText.wardEffect,
            icon: KitIcons.ward,
            accentColor: accentColor,
            content: Text(
              data['ward_effect'] as String,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

        // Modifier-specific: effect
        if (data['effect'] != null)
          _buildSection(
            title: EquipmentCardText.effect,
            icon: KitIcons.enchantment,
            accentColor: accentColor,
            content: Text(
              data['effect'] as String,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

        // Keywords
        _buildKeywordsSection(context, data, accentColor),

        // Signature abilities - given more space
        _buildSignatureAbilitySection(context, data, accentColor),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required AppIconData icon,
    required Color accentColor,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top border
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 10),
          // Header
          Row(
            children: [
              AppIcon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Content
          content,
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final equipment = data['equipment'] as Map<String, dynamic>?;
    final equipmentDescription = data['equipment_description'] as String?;

    if (equipment == null && equipmentDescription == null) {
      return const SizedBox.shrink();
    }

    final equipmentChips = equipment != null ? _buildEquipmentChips(equipment, accentColor) : <Widget>[];

    return _buildSection(
      title: EquipmentCardText.equipment,
      icon: AppIcons.gear.kitsTab,
      accentColor: accentColor,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (equipmentDescription != null) ...[
            Text(
              equipmentDescription,
              style: TextStyle(
                color: FormTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (equipmentChips.isNotEmpty) const SizedBox(height: 10),
          ],
          if (equipmentChips.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: equipmentChips),
        ],
      ),
    );
  }

  Widget _buildDamageBonusSection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final meleeDamage = data['melee_damage_bonus'] as Map<String, dynamic>?;
    final rangedDamage = data['ranged_damage_bonus'] as Map<String, dynamic>?;

    if ((meleeDamage == null || !_hasNonNullValues(meleeDamage)) &&
        (rangedDamage == null || !_hasNonNullValues(rangedDamage))) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: EquipmentCardText.damageBonuses,
      icon: KitEquipmentIcons.meleeDamage,
      accentColor: accentColor,
      content: Column(
        children: [
          if (meleeDamage != null && _hasNonNullValues(meleeDamage))
            _buildIconTierRow(KitEquipmentIcons.meleeDamage, 'Melee', meleeDamage, true),
          if (rangedDamage != null && _hasNonNullValues(rangedDamage)) ...[
            if (meleeDamage != null && _hasNonNullValues(meleeDamage))
              const SizedBox(height: 10),
            _buildIconTierRow(KitEquipmentIcons.rangedDamage, 'Ranged', rangedDamage, true),
          ],
        ],
      ),
    );
  }

  Widget _buildDistanceBonusSection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final meleeDistance = data['melee_distance_bonus'] as Map<String, dynamic>?;
    final rangedDistance = data['ranged_distance_bonus'] as Map<String, dynamic>?;

    if ((meleeDistance == null || !_hasNonNullValues(meleeDistance)) &&
        (rangedDistance == null || !_hasNonNullValues(rangedDistance))) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: EquipmentCardText.distanceBonuses,
      icon: KitEquipmentIcons.meleeRange,
      accentColor: accentColor,
      content: Column(
        children: [
          if (meleeDistance != null && _hasNonNullValues(meleeDistance))
            _buildIconTierRow(KitEquipmentIcons.meleeRange, 'Melee', meleeDistance, false),
          if (rangedDistance != null && _hasNonNullValues(rangedDistance)) ...[
            if (meleeDistance != null && _hasNonNullValues(meleeDistance))
              const SizedBox(height: 10),
            _buildIconTierRow(KitEquipmentIcons.rangedRange, 'Ranged', rangedDistance, false),
          ],
        ],
      ),
    );
  }

  Widget _buildLightningDamageSection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final lightningDamage = data['lightning_damage'] as Map<String, dynamic>?;
    if (lightningDamage == null || !_hasNonNullValues(lightningDamage)) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: EquipmentCardText.lightningDamage,
      icon: KitIcons.stormwightKit,
      accentColor: accentColor,
      content: _buildTierRow('⚡ Damage', lightningDamage, false),
    );
  }

  Widget _buildTierRow(String label, Map<String, dynamic> data, bool isTier) {
    final key1 = isTier ? '1st_tier' : '1st_echelon';
    final key2 = isTier ? '2nd_tier' : '2nd_echelon';
    final key3 = isTier ? '3rd_tier' : '3rd_echelon';
    
    final v1 = data[key1];
    final v2 = data[key2];
    final v3 = data[key3];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FormTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (v1 != null) _buildTierBox(isTier ? 'T1' : 'E1', '+$v1', isTier ? '≤11' : '1st'),
            if (v2 != null) _buildTierBox(isTier ? 'T2' : 'E2', '+$v2', isTier ? '12-16' : '2nd'),
            if (v3 != null) _buildTierBox(isTier ? 'T3' : 'E3', '+$v3', isTier ? '17+' : '3rd'),
          ],
        ),
      ],
    );
  }

  Widget _buildEchelonRow(String label, Map<String, dynamic> data) {
    return _buildTierRow(label, data, false);
  }

  Widget _buildTierBox(String tier, String value, String subtitle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: FormTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: FormTheme.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: FormTheme.textBright,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: FormTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordsSection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    final keywords = data['keywords'] as List?;
    if (keywords == null || keywords.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: EquipmentCardText.keywords,
      icon: KitIcons.fromType(widget.component.type.toLowerCase()),
      accentColor: accentColor,
      content: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: keywords.map((k) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: accentColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Text(
            k.toString(),
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSignatureAbilitySection(BuildContext context, Map<String, dynamic> data, Color accentColor) {
    if (_signatureAbilities.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top border
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 10),
            // Header
            Row(
              children: [
                AppIcon(KitIcons.fromType(widget.component.type.toLowerCase()), size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  _signatureAbilities.length > 1 ? 'SIGNATURE ABILITIES' : 'SIGNATURE ABILITY',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Abilities - full width with more breathing room
            ..._signatureAbilities.map((ability) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AbilityExpandableItem(component: ability, embedded: true),
            )),
          ],
        ),
      );
    } else if (_loadingAbility) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor,
            ),
          ),
        ),
      );
    } else if (data['signature_ability'] != null) {
      final signatureAbilityData = data['signature_ability'];
      final List<String> abilityNames;
      if (signatureAbilityData is String) {
        abilityNames = [signatureAbilityData];
      } else if (signatureAbilityData is List) {
        abilityNames = signatureAbilityData.cast<String>();
      } else {
        return const SizedBox.shrink();
      }

      return _buildSection(
        title: abilityNames.length > 1 ? 'SIGNATURE ABILITIES' : 'SIGNATURE ABILITY',
        icon: KitIcons.fromType(widget.component.type.toLowerCase()),
        accentColor: accentColor,
        content: Column(
          children: abilityNames.map((name) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: name != abilityNames.last ? 8 : 0),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          )).toList(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool _hasNonNullValues(Map<String, dynamic> map) {
    return map.values.any((v) => v != null);
  }

  String _humanReadableEquipment(String key) {
    switch (key) {
      case 'ensnaring_weapon':
        return 'Ensnaring';
      case 'bow':
        return 'Bow';
      case 'light':
        return 'Light';
      case 'medium':
        return 'Medium';
      case 'heavy':
        return 'Heavy';
      case 'polearm':
        return 'Polearm';
      case 'unarmed_strikes':
        return 'Unarmed';
      case 'whip':
        return 'Whip';
      case 'none':
        return 'None';
      case 'shield':
        return 'Shield';
      default:
        return key.replaceAll('_', ' ').split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
    }
  }
}
