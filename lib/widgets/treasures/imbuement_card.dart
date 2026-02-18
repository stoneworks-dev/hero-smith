import 'package:flutter/material.dart';

import '../../core/models/downtime.dart';
import '../../core/text/heroes_sheet/gear/gear_widgets_text.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icon_data.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../../features/heroes_sheet/gear/gear_utils.dart';

/// Unified imbuement card with a magical styling similar to treasure cards.
///
/// Features:
/// - Left accent stripe in purple / magical hue
/// - Dark background with magical shimmer gradient
/// - SVG type icons (rune-sword, vibrating-shield, burning-book)
/// - Smooth expand/collapse animation
/// - Optional remove callback for hero sheet usage
/// - Optional onTap for dialog/picker usage
class ImbuementCard extends StatefulWidget {
  final DowntimeEntry imbuement;

  /// Called when the card is tapped (for picker dialogs).
  final VoidCallback? onTap;

  /// Called to remove this imbuement from the hero.
  final VoidCallback? onRemove;

  const ImbuementCard({
    super.key,
    required this.imbuement,
    this.onTap,
    this.onRemove,
  });

  @override
  State<ImbuementCard> createState() => _ImbuementCardState();
}

class _ImbuementCardState extends State<ImbuementCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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

  /// Returns (accent, glow) color pair based on imbuement type.
  static (Color, Color) _getTypeColors(String imbuementType) {
    switch (imbuementType) {
      case 'weapon_imbuement':
        return (const Color(0xFFC62828), const Color(0xFFEF5350)); // aggressive red
      case 'implement_imbuement':
        return (const Color(0xFF6A1B9A), const Color(0xFF9C27B0)); // magical purple
      case 'armor_imbuement':
      case 'shield_imbuement':
        return (const Color(0xFF1565C0), const Color(0xFF42A5F5)); // protective blue
      default:
        return (NavigationTheme.imbuementsTabColor, const Color(0xFF9C27B0));
    }
  }

  String _getTypeDisplay(String imbuementType) {
    switch (imbuementType) {
      case 'armor_imbuement':
        return GearWidgetsText.imbuementTypeArmor;
      case 'weapon_imbuement':
        return GearWidgetsText.imbuementTypeWeapon;
      case 'implement_imbuement':
        return GearWidgetsText.imbuementTypeImplement;
      case 'shield_imbuement':
        return GearWidgetsText.imbuementTypeShield;
      default:
        return imbuementType.replaceAll('_', ' ');
    }
  }

  AppIconData _getTypeIcon(String imbuementType) {
    return ImbuementIcons.fromType(imbuementType);
  }

  /// Level group label for the level badges (1, 5, 9).
  String _getLevelTier(int level) {
    if (level <= 4) return 'Tier I';
    if (level <= 8) return 'Tier II';
    return 'Tier III';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final imbuementType = widget.imbuement.raw['type'] as String? ?? '';
    final level = widget.imbuement.raw['level'] as int?;
    final description = widget.imbuement.raw['description'] as String? ?? '';
    final (accentColor, glowColor) = _getTypeColors(imbuementType);

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? _toggleExpanded,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent stripe with type-based gradient
              Container(
                width: NavigationTheme.cardAccentStripeWidth,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      glowColor,
                      accentColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(NavigationTheme.cardBorderRadius),
                    bottomLeft:
                        Radius.circular(NavigationTheme.cardBorderRadius),
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
                      _buildHeader(imbuementType, level, accentColor, glowColor),
                      const SizedBox(height: 10),
                      _buildDescription(description),
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child:
                            _buildExpandedContent(imbuementType, description, accentColor, glowColor),
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

  Widget _buildHeader(String imbuementType, int? level, Color accentColor, Color glowColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container with type-colored glow
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.25),
                glowColor.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: AppIcon(
            _getTypeIcon(imbuementType),
            color: glowColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        // Name and badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.imbuement.name,
                style: const TextStyle(
                  color: FormTheme.textBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              _buildBadges(imbuementType, level, accentColor, glowColor),
            ],
          ),
        ),
        // Remove button or expand indicator
        if (widget.onRemove != null)
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.white70, size: 20),
            onPressed: widget.onRemove,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          )
        else if (widget.onTap == null)
          RotationTransition(
            turns: _rotationAnimation,
            child: const Icon(
              Icons.expand_more,
              color: FormTheme.textMuted,
              size: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildBadges(String imbuementType, int? level, Color accentColor, Color glowColor) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Type badge with icon
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accentColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                _getTypeIcon(imbuementType),
                color: glowColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                _getTypeDisplay(imbuementType).toUpperCase(),
                style: TextStyle(
                  color: glowColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Level badge
        if (level != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: getLevelColor(level).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: getLevelColor(level).withOpacity(0.4)),
            ),
            child: Text(
              '${GearWidgetsText.imbuementLevelPrefix}$level',
              style: TextStyle(
                color: getLevelColor(level),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    if (description.isEmpty) return const SizedBox.shrink();
    return Text(
      description,
      maxLines: _isExpanded ? null : 2,
      overflow: _isExpanded ? null : TextOverflow.ellipsis,
      style: const TextStyle(
        color: FormTheme.textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildExpandedContent(String imbuementType, String description, Color accentColor, Color glowColor) {
    final effect = widget.imbuement.raw['effect'] as String?;
    final abilities = widget.imbuement.raw['abilities'] as List?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Effect section
        if (effect != null && effect.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.08),
                  glowColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(
                      ImbuementIcons.fallback,
                      color: glowColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      GearWidgetsText.imbuementEffectLabel,
                      style: TextStyle(
                        color: glowColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  effect,
                  style: const TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Abilities section (if present)
        if (abilities != null && abilities.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...abilities.map((ability) {
            final abilityName =
                (ability is Map) ? ability['name']?.toString() ?? '' : '';
            final abilityDesc =
                (ability is Map) ? ability['description']?.toString() ?? '' : '';
            if (abilityName.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    abilityName,
                    style: TextStyle(
                      color: glowColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (abilityDesc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      abilityDesc,
                      style: const TextStyle(
                        color: FormTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
