import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/damage_resistance_model.dart';
import '../../../core/services/ancestry_bonus_service.dart';
import '../../../core/text/heroes_sheet/main_stats/damage_resistance_tracker_text.dart';
import '../../../core/theme/navigation_theme.dart';
import 'hero_main_stats_providers.dart';

/// Widget for tracking damage immunities and weaknesses.
/// Displays a merged view where immunity and weakness are additive:
/// e.g., 5 immunity + 3 weakness = 2 immunity (net).
/// Users can click on the net value to modify base immunity/weakness values.
class DamageResistanceTrackerWidget extends ConsumerStatefulWidget {
  const DamageResistanceTrackerWidget({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<DamageResistanceTrackerWidget> createState() =>
      _DamageResistanceTrackerWidgetState();
}

class _DamageResistanceTrackerWidgetState
    extends ConsumerState<DamageResistanceTrackerWidget> {
  HeroDamageResistances _resistances = HeroDamageResistances.empty;
  HeroDamageResistances _baseResistances = HeroDamageResistances.empty;
  int _heroLevel = 1;

  @override
  Widget build(BuildContext context) {
    // Watch the combined provider for display (includes treasure immunities)
    final combinedResistancesAsync = ref.watch(heroCombinedDamageResistancesProvider(widget.heroId));
    
    // Watch the base provider for saving (excludes treasure immunities)
    final baseResistancesAsync = ref.watch(heroDamageResistancesProvider(widget.heroId));
    baseResistancesAsync.whenData((base) {
      _baseResistances = base;
    });
    
    // Get hero level for dynamic resistance calculations
    final mainStats = ref.watch(heroMainStatsProvider(widget.heroId));
    mainStats.whenData((stats) {
      _heroLevel = stats.level;
    });
    
    return combinedResistancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${DamageResistanceTrackerText.errorLoadingResistancesPrefix}$error',
            ),
            ElevatedButton(
              onPressed: () => ref.invalidate(heroCombinedDamageResistancesProvider(widget.heroId)),
              child: const Text(DamageResistanceTrackerText.errorRetryLabel),
            ),
          ],
        ),
      ),
      data: (resistances) {
        // Update local state for display
        _resistances = resistances;
        return _buildContent(context);
      },
    );
  }

  Future<void> _save() async {
    try {
      final service = ref.read(ancestryBonusServiceProvider);
      // Save the base resistances, not the combined ones with treasure
      await service.saveDamageResistances(widget.heroId, _baseResistances);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${DamageResistanceTrackerText.saveErrorPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDamageTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, color: Colors.blue.shade400),
              ),
              const SizedBox(width: 12),
              const Text(
                DamageResistanceTrackerText.addDamageTypeDialogTitle,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: DamageTypes.all.length,
              itemBuilder: (context, index) {
                final type = DamageTypes.all[index];
                final existing = _resistances.forType(type);
                final isTracked = existing != null;
                
                return ListTile(
                  leading: Icon(
                    _getDamageTypeIcon(type),
                    color: _getDamageTypeColor(type),
                  ),
                  title: Text(
                    DamageTypes.displayName(type),
                    style: TextStyle(
                      color: isTracked ? Colors.grey.shade600 : Colors.white,
                    ),
                  ),
                  trailing: isTracked
                      ? Icon(Icons.check, color: Colors.green.shade400)
                      : null,
                  onTap: isTracked
                      ? null
                      : () {
                          _addDamageType(type);
                          Navigator.of(context).pop();
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text(
                DamageResistanceTrackerText.addDamageTypeCancelLabel,
              ),
            ),
            TextButton(
              onPressed: () => _showCustomDamageTypeDialog(context),
              style: TextButton.styleFrom(foregroundColor: Colors.blue.shade400),
              child: const Text(
                DamageResistanceTrackerText.addDamageTypeCustomLabel,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomDamageTypeDialog(BuildContext parentContext) async {
    final controller = TextEditingController();
    Navigator.of(parentContext).pop(); // Close the add dialog
    
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.create, color: Colors.purple.shade400),
                ),
                const SizedBox(width: 12),
                const Text(
                  DamageResistanceTrackerText.customDamageTypeDialogTitle,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText:
                    DamageResistanceTrackerText.customDamageTypeNameLabel,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                hintText: DamageResistanceTrackerText.customDamageTypeNameHint,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple.shade400),
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
                child: const Text(
                  DamageResistanceTrackerText.customDamageTypeCancelLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  DamageResistanceTrackerText.customDamageTypeAddLabel,
                ),
              ),
            ],
          );
        },
      );

      if (result == true && controller.text.trim().isNotEmpty) {
        _addDamageType(controller.text.trim().toLowerCase());
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.dispose();
    }
  }

  void _addDamageType(String type) {
    setState(() {
      _baseResistances = _baseResistances.upsertResistance(
        DamageResistance(damageType: type),
      );
    });
    _save();
  }

  void _removeDamageType(String type) {
    setState(() {
      _baseResistances = _baseResistances.removeResistance(type);
    });
    _save();
  }

  Future<void> _showEditResistanceDialog(DamageResistance resistance) async {
    final immunityController = TextEditingController(
      text: resistance.baseImmunity.toString(),
    );
    final weaknessController = TextEditingController(
      text: resistance.baseWeakness.toString(),
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDamageTypeColor(resistance.damageType).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDamageTypeIcon(resistance.damageType),
                    color: _getDamageTypeColor(resistance.damageType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${DamageResistanceTrackerText.editResistanceTitlePrefix}${DamageTypes.displayName(resistance.damageType)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                final baseImm =
                    int.tryParse(immunityController.text) ?? resistance.baseImmunity;
                final baseWeak =
                    int.tryParse(weaknessController.text) ?? resistance.baseWeakness;
                final totalImm = baseImm + resistance.bonusImmunity;
                final totalWeak = baseWeak + resistance.bonusWeakness;
                final net = totalImm - totalWeak;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DamageResistanceTrackerText.netResultPrefix}${_formatNetValue(net)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: net > 0
                                  ? Colors.green.shade400
                                  : net < 0
                                      ? Colors.red.shade400
                                      : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${DamageResistanceTrackerText.totalImmunityPrefix}$totalImm (Base: $baseImm + Bonus: ${resistance.bonusImmunity})',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                          Text(
                            '${DamageResistanceTrackerText.totalWeaknessPrefix}$totalWeak (Base: $baseWeak + Bonus: ${resistance.bonusWeakness})',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                        ],
                      ),
                    ),
                    if (resistance.sources.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        DamageResistanceTrackerText.sourcesLabel,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: resistance.sources
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(s, style: TextStyle(fontSize: 11, color: Colors.grey.shade300)),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Base values inputs
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: immunityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText:
                                  DamageResistanceTrackerText.baseImmunityLabel,
                              labelStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green.shade400),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weaknessController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText:
                                  DamageResistanceTrackerText.baseWeaknessLabel,
                              labelStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red.shade400),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
                child: const Text(
                  DamageResistanceTrackerText.editResistanceCancelLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  DamageResistanceTrackerText.editResistanceSaveLabel,
                ),
              ),
            ],
          );
        },
      );

      if (result == true && mounted) {
        final newBaseImm = int.tryParse(immunityController.text) ?? 0;
        final newBaseWeak = int.tryParse(weaknessController.text) ?? 0;
        
        // Get the base resistance (without treasure bonuses) and update it
        final baseResistance = _baseResistances.forType(resistance.damageType);
        setState(() {
          _baseResistances = _baseResistances.upsertResistance(
            (baseResistance ?? resistance).copyWith(
              baseImmunity: newBaseImm,
              baseWeakness: newBaseWeak,
            ),
          );
        });
        _save();
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      immunityController.dispose();
      weaknessController.dispose();
    }
  }

  String _formatNetValue(int net) {
    if (net > 0) {
      return '${DamageResistanceTrackerText.netImmunityPrefix}$net';
    }
    if (net < 0) {
      return '${DamageResistanceTrackerText.netWeaknessPrefix}${net.abs()}';
    }
    return DamageResistanceTrackerText.netNoneLabel;
  }

  IconData _getDamageTypeIcon(String type) {
    return switch (type.toLowerCase()) {
      'fire' => Icons.local_fire_department,
      'cold' => Icons.ac_unit,
      'lightning' => Icons.bolt,
      'acid' => Icons.science,
      'poison' => Icons.coronavirus,
      'psychic' => Icons.psychology,
      'corruption' => Icons.warning,
      'holy' => Icons.star,
      'sonic' => Icons.volume_up,
      'damage' => Icons.dangerous,
      _ => Icons.shield,
    };
  }

  Color _getDamageTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'fire' => Colors.orange,
      'cold' => Colors.lightBlue,
      'lightning' => Colors.yellow.shade700,
      'acid' => Colors.green,
      'poison' => Colors.purple,
      'psychic' => Colors.pink,
      'corruption' => Colors.deepPurple,
      'holy' => Colors.amber,
      'sonic' => Colors.cyan,
      'damage' => Colors.red,
      _ => Colors.grey,
    };
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.shield_outlined, size: 18, color: Colors.blue.shade400),
                ),
                const SizedBox(width: 8),
                const Text(
                  DamageResistanceTrackerText.damageResistancesTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, size: 20, color: Colors.blue.shade400),
                  tooltip: DamageResistanceTrackerText.addDamageTypeTooltip,
                  onPressed: _showAddDamageTypeDialog,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DamageResistanceTrackerText.damageResistancesFormulaLabel,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            // Resistances list
            if (_resistances.resistances.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    DamageResistanceTrackerText.emptyResistancesLabel,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _resistances.resistances
                    .map((r) => _buildResistanceTile(context, r))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResistanceTile(BuildContext context, DamageResistance resistance) {
    // Use netValueAtLevel to calculate dynamic resistances based on hero level
    final net = resistance.netValueAtLevel(_heroLevel);
    final color = net > 0 ? Colors.green.shade400 : net < 0 ? Colors.red.shade400 : null;
    final typeColor = _getDamageTypeColor(resistance.damageType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _showEditResistanceDialog(resistance),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade700,
            ),
          ),
          child: Row(
            children: [
              // Type icon
              Icon(
                _getDamageTypeIcon(resistance.damageType),
                size: 18,
                color: typeColor,
              ),
              const SizedBox(width: 8),
              // Type name
              Expanded(
                child: Text(
                  DamageTypes.displayName(resistance.damageType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              // Net value chip with fixed min width for alignment
              Container(
                constraints: const BoxConstraints(minWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color?.withAlpha(30) ?? Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                  border: color != null
                      ? Border.all(color: color.withAlpha(100))
                      : null,
                ),
                child: Text(
                  _formatNetValue(net),
                  style: TextStyle(
                    color: color ?? Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Delete button
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                onPressed: () => _removeDamageType(resistance.damageType),
                tooltip: DamageResistanceTrackerText.removeDamageTypeTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
