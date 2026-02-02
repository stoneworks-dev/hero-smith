import 'package:flutter/material.dart';

import 'green_animal_form.dart';

/// A reusable widget to display creature statistics in a stat block format.
/// 
/// This widget is designed to be generic and can be used for:
/// - Green Elementalist animal forms
/// - Summoned creatures
/// - Monster stat blocks
/// - Any other creature statistics
class CreatureStatBlock extends StatelessWidget {
  const CreatureStatBlock({
    super.key,
    required this.name,
    this.level,
    this.size,
    this.speed,
    this.movementDescription,
    this.stability,
    this.temporaryStamina,
    this.meleeDamageBonus,
    this.special,
    this.accentColor,
    this.isCompact = false,
  });

  /// The name of the creature/form
  final String name;

  /// The level requirement (optional)
  final int? level;

  /// Size category string (e.g., "1M", "2", "3")
  final String? size;

  /// Base speed value
  final int? speed;

  /// Full movement description (e.g., "Walk 5, Fly 7")
  final String? movementDescription;

  /// Stability value
  final int? stability;

  /// Temporary stamina granted
  final int? temporaryStamina;

  /// Melee damage bonus object
  final MeleeDamageBonus? meleeDamageBonus;

  /// Special ability text
  final String? special;

  /// Accent color for the stat block
  final Color? accentColor;

  /// Whether to show a compact version
  final bool isCompact;

  /// Create a CreatureStatBlock from a GreenAnimalForm
  factory CreatureStatBlock.fromGreenForm(
    GreenAnimalForm form, {
    Color? accentColor,
    bool isCompact = false,
  }) {
    return CreatureStatBlock(
      name: form.name,
      level: form.level,
      size: form.size,
      speed: form.baseSpeed,
      movementDescription: form.movementDescription,
      stability: form.stabilityBonus,
      temporaryStamina: form.temporaryStamina,
      meleeDamageBonus: form.meleeDamageBonus,
      special: form.special,
      accentColor: accentColor,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    if (isCompact) {
      return _buildCompactView(context, theme, color);
    }
    return _buildFullView(context, theme, color);
  }

  Widget _buildCompactView(BuildContext context, ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and level header
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (level != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lvl $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick stats row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (size != null) _buildStatChip(theme, 'Size', size!, color),
              if (speed != null) _buildStatChip(theme, 'Speed', '$speed', color),
              if (stability != null && stability! > 0)
                _buildStatChip(theme, 'Stab', '+$stability', color),
              if (temporaryStamina != null && temporaryStamina! > 0)
                _buildStatChip(theme, 'THP', '$temporaryStamina', color),
            ],
          ),
          if (special != null && special!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              special!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.pets, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level $level',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Stats grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary stats row
                Row(
                  children: [
                    if (size != null)
                      Expanded(
                        child: _buildStatTile(
                          theme, 
                          'Size', 
                          size!, 
                          Icons.straighten, 
                          color,
                        ),
                      ),
                    if (speed != null)
                      Expanded(
                        child: _buildStatTile(
                          theme, 
                          'Speed', 
                          '$speed', 
                          Icons.speed, 
                          color,
                        ),
                      ),
                    if (stability != null)
                      Expanded(
                        child: _buildStatTile(
                          theme, 
                          'Stability', 
                          stability == 0 ? '0' : '+$stability', 
                          Icons.anchor, 
                          color,
                        ),
                      ),
                    if (temporaryStamina != null && temporaryStamina! > 0)
                      Expanded(
                        child: _buildStatTile(
                          theme, 
                          'Temp HP', 
                          '$temporaryStamina', 
                          Icons.favorite, 
                          color,
                        ),
                      ),
                  ],
                ),
                
                // Movement description
                if (movementDescription != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    theme, 
                    Icons.directions_run, 
                    'Movement', 
                    movementDescription!, 
                    color,
                  ),
                ],
                
                // Melee damage bonus
                if (meleeDamageBonus != null && meleeDamageBonus!.hasDamageBonus) ...[
                  const SizedBox(height: 8),
                  _buildMeleeDamageSection(theme, color),
                ],
                
                // Special ability
                if (special != null && special!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSpecialSection(theme, color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, 
    IconData icon, 
    String label, 
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeleeDamageSection(ThemeData theme, Color color) {
    final bonus = meleeDamageBonus!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            'Melee Damage Bonus:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTierChip(theme, '11-', bonus.tier1, Colors.grey),
                _buildTierChip(theme, '12-16', bonus.tier2, Colors.blue),
                _buildTierChip(theme, '17+', bonus.tier3, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip(ThemeData theme, String tier, int? bonus, Color tierColor) {
    final hasBonus = bonus != null && bonus > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasBonus ? tierColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tierColor.withOpacity(hasBonus ? 0.5 : 0.2),
        ),
      ),
      child: Text(
        hasBonus ? '+$bonus' : '-',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: hasBonus ? tierColor : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSpecialSection(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  special!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
