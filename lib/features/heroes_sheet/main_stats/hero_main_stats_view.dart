import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/models/hero_mod_keys.dart';
import '../../../core/models/stat_modification_model.dart';
import '../../../core/repositories/hero_repository.dart';
import '../../../core/services/heroic_resource_progression_service.dart';
import '../../../core/services/resource_generation_service.dart';
import '../../../core/text/heroes_sheet/main_stats/hero_main_stats_view_text.dart';
import '../../../core/theme/ability_colors.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/semantic/hero_entry_tokens.dart';
import '../../../widgets/heroic resource stacking tables/heroic_resource_stacking_tables.dart';
import '../../../widgets/psi boosts/psi_boosts.dart';
import '../../../widgets/creature stat block/hero_green_form_widget.dart';
import '../downtime/hero_downtime_tracking_page.dart';
import 'hero_main_stats_providers.dart';
import 'coin_purse_model.dart';
import 'conditions_tracker_widget.dart';
import 'damage_resistance_tracker_widget.dart';
import 'hero_main_stats_models.dart';
import 'hero_stat_insights.dart';
import 'hero_stamina_helpers.dart';
import 'heroic_resource_details_provider.dart';
import 'stamina_bar_widget.dart';
import 'progression_row_widget.dart';
import 'respite_downtime_row_widget.dart';
import 'combined_stats_card_widget.dart';
import 'heroic_resource_section_widget.dart';
import 'surges_section_widget.dart';
import 'hero_tokens_section_widget.dart';
import 'stat_edit_dialogs.dart';

class HeroMainStatsView extends ConsumerStatefulWidget {
  const HeroMainStatsView({
    super.key,
    required this.heroId,
    required this.heroName,
  });

  final String heroId;
  final String heroName;

  @override
  ConsumerState<HeroMainStatsView> createState() => _HeroMainStatsViewState();
}

// NumericField enum moved to hero_main_stats_models.dart
typedef _NumericField = NumericField;

class _HeroMainStatsViewState extends ConsumerState<HeroMainStatsView> {
  final Map<_NumericField, TextEditingController> _numberControllers = {
    for (final field in _NumericField.values) field: TextEditingController(),
  };
  ProviderSubscription<AsyncValue<HeroMainStats>>? _statsSub;

  final Map<_NumericField, FocusNode> _numberFocusNodes = {
    for (final field in _NumericField.values) field: FocusNode(),
  };

  final Map<_NumericField, Timer?> _numberDebounce = {};

  static const List<String> _modKeys = [
    HeroModKeys.wealth,
    HeroModKeys.renown,
    HeroModKeys.might,
    HeroModKeys.agility,
    HeroModKeys.reason,
    HeroModKeys.intuition,
    HeroModKeys.presence,
    HeroModKeys.size,
    HeroModKeys.speed,
    HeroModKeys.disengage,
    HeroModKeys.stability,
    HeroModKeys.staminaMax,
    HeroModKeys.recoveriesMax,
    HeroModKeys.surges,
  ];

  final Map<String, TextEditingController> _modControllers = {
    for (final key in _modKeys) key: TextEditingController(),
  };

  final Map<String, FocusNode> _modFocusNodes = {
    for (final key in _modKeys) key: FocusNode(),
  };

  final Map<String, Timer?> _modDebounce = {};

  HeroMainStats? _latestStats;
  HeroStatModifications _ancestryMods = const HeroStatModifications.empty();
  bool _isApplying = false;

  /// The minimum value the heroic resource can reach (0 for most classes, negative for Talent).
  /// This is dynamically calculated based on class features and the hero's Reason score.
  int _heroicResourceMinValue = 0;

  /// Cached resource details for calculating min value
  HeroicResourceDetails? _cachedResourceDetails;

  @override
  void initState() {
    super.initState();
    _statsSub = ref.listenManual<AsyncValue<HeroMainStats>>(
      heroMainStatsProvider(widget.heroId),
      _handleStatsChanged,
      fireImmediately: true,
    );
    for (final entry in _numberControllers.entries) {
      entry.value.addListener(() => _handleNumberChanged(entry.key));
    }
    for (final entry in _modControllers.entries) {
      entry.value.addListener(() => _handleModChanged(entry.key));
    }
  }

  @override
  void didUpdateWidget(covariant HeroMainStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroId != widget.heroId) {
      _statsSub?.close();
      _statsSub = ref.listenManual<AsyncValue<HeroMainStats>>(
        heroMainStatsProvider(widget.heroId),
        _handleStatsChanged,
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _statsSub?.close();
    for (final timer in _numberDebounce.values) {
      timer?.cancel();
    }
    for (final timer in _modDebounce.values) {
      timer?.cancel();
    }

    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    for (final node in _numberFocusNodes.values) {
      node.dispose();
    }
    for (final controller in _modControllers.values) {
      controller.dispose();
    }
    for (final node in _modFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _applyStats(HeroMainStats stats) {
    if (!mounted) return;
    _latestStats = stats;
    _isApplying = true;

    void setNumber(_NumericField field, int value) {
      final controller = _numberControllers[field]!;
      final focusNode = _numberFocusNodes[field]!;
      final text = value.toString();
      if (!focusNode.hasFocus && controller.text != text) {
        controller.text = text;
      }
    }

    void setMod(String key, int value) {
      final controller = _modControllers[key]!;
      final focusNode = _modFocusNodes[key]!;
      final text = value.toString();
      if (!focusNode.hasFocus && controller.text != text) {
        controller.text = text;
      }
    }

    // Check if current stamina exceeds max and clamp if needed
    final maxStamina = stats.staminaMaxEffective;
    var currentStamina = stats.staminaCurrent;
    if (currentStamina > maxStamina) {
      currentStamina = maxStamina;
      // Persist the clamped value asynchronously
      _clampStaminaToMax(currentStamina);
    }

    setNumber(_NumericField.victories, stats.victories);
    setNumber(_NumericField.exp, stats.exp);
    setNumber(_NumericField.level, stats.level);
    setNumber(_NumericField.staminaCurrent, currentStamina);
    setNumber(_NumericField.staminaTemp, stats.staminaTemp);
    setNumber(_NumericField.recoveriesCurrent, stats.recoveriesCurrent);
    setNumber(_NumericField.heroicResourceCurrent, stats.heroicResourceCurrent);
    setNumber(_NumericField.surgesCurrent, stats.surgesCurrent);
    setNumber(_NumericField.heroTokensCurrent, stats.heroTokensCurrent);

    for (final key in _modKeys) {
      setMod(key, stats.userModValue(key));
    }

    _isApplying = false;
  }

  /// Persists the clamped stamina value when current exceeds max.
  Future<void> _clampStaminaToMax(int clampedValue) async {
    final repo = ref.read(heroRepositoryProvider);
    await repo.updateVitals(widget.heroId, staminaCurrent: clampedValue);
    // Invalidate to refresh provider state
    ref.invalidate(heroValuesProvider(widget.heroId));
  }

  void _handleStatsChanged(
    AsyncValue<HeroMainStats>? previous,
    AsyncValue<HeroMainStats> next,
  ) {
    next.whenData(_applyStats);
  }

  void _handleNumberChanged(_NumericField field) {
    if (_isApplying) return;
    _numberDebounce[field]?.cancel();
    _numberDebounce[field] = Timer(
      const Duration(milliseconds: 300),
      () => _persistNumberField(field, _numberControllers[field]!.text),
    );
  }

  Future<void> _persistNumberField(
    _NumericField field,
    String rawValue,
  ) async {
    final repo = ref.read(heroRepositoryProvider);
    final stats = _latestStats;
    int value = int.tryParse(rawValue) ?? 0;

    switch (field) {
      case _NumericField.victories:
      case _NumericField.exp:
        value = value.clamp(0, 999);
        break;
      case _NumericField.level:
        value = value.clamp(1, 10);
        break;
      case _NumericField.staminaCurrent:
        value = value.clamp(-999, 999);
        break;
      case _NumericField.staminaTemp:
        value = value.clamp(0, 999);
        break;
      case _NumericField.recoveriesCurrent:
        final max = stats?.recoveriesMaxEffective ?? 999;
        value = value.clamp(0, max);
        break;
      case _NumericField.heroicResourceCurrent:
        // Use dynamic min value based on class (can be negative for Talent)
        value = value.clamp(_heroicResourceMinValue, 999);
        break;
      case _NumericField.surgesCurrent:
        value = value.clamp(0, 999);
        break;
      case _NumericField.heroTokensCurrent:
        value = value.clamp(0, 99);
        break;
    }

    if (stats != null && _numberValueFromStats(stats, field) == value) {
      return;
    }

    try {
      switch (field) {
        case _NumericField.victories:
          await repo.updateMainStats(widget.heroId, victories: value);
          break;
        case _NumericField.exp:
          await repo.updateMainStats(widget.heroId, exp: value);
          break;
        case _NumericField.level:
          await repo.updateMainStats(widget.heroId, level: value);
          break;
        case _NumericField.staminaCurrent:
          await repo.updateVitals(widget.heroId, staminaCurrent: value);
          break;
        case _NumericField.staminaTemp:
          await repo.updateVitals(widget.heroId, staminaTemp: value);
          break;
        case _NumericField.recoveriesCurrent:
          await repo.updateVitals(widget.heroId, recoveriesCurrent: value);
          break;
        case _NumericField.heroicResourceCurrent:
          await repo.updateVitals(widget.heroId, heroicResourceCurrent: value);
          break;
        case _NumericField.surgesCurrent:
          await repo.updateVitals(widget.heroId, surgesCurrent: value);
          break;
        case _NumericField.heroTokensCurrent:
          await repo.updateVitals(widget.heroId, heroTokensCurrent: value);
          break;
      }
    } catch (err) {
      if (!mounted) return;
      _showSnack(
        '${HeroMainStatsViewText.updateNumberFieldErrorPrefix}${field.label.toLowerCase()}${HeroMainStatsViewText.updateNumberFieldErrorSuffix}$err',
      );
    }
  }

  void _handleModChanged(String key) {
    if (_isApplying) return;
    _modDebounce[key]?.cancel();
    _modDebounce[key] = Timer(
      const Duration(milliseconds: 300),
      () => _persistModification(key, _modControllers[key]!.text),
    );
  }

  Future<void> _persistModification(String key, String rawValue) async {
    final repo = ref.read(heroRepositoryProvider);
    int value = int.tryParse(rawValue) ?? 0;
    value = value.clamp(-99, 99);
    if (_latestStats?.userModValue(key) == value) {
      return;
    }
    try {
      await repo.setModification(widget.heroId, key: key, value: value);
    } catch (err) {
      if (!mounted) return;
      _showSnack(
        '${HeroMainStatsViewText.updateModifierErrorPrefix}$err',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(heroMainStatsProvider(widget.heroId));
    final ancestryModsAsync =
        ref.watch(heroAncestryStatModsProvider(widget.heroId));

    // Update ancestry mods state
    _ancestryMods =
        ancestryModsAsync.valueOrNull ?? const HeroStatModifications.empty();

    // Use valueOrNull to prevent flicker - show stale data during refresh
    final stats = statsAsync.valueOrNull;

    // Only show loading if we have no cached stats at all
    if (stats == null && _latestStats == null) {
      if (statsAsync.hasError) {
        return _buildErrorState(context, statsAsync.error!);
      }
      return const Center(child: CircularProgressIndicator());
    }

    // Use fresh stats if available, otherwise fall back to cached
    final effectiveStats = stats ?? _latestStats!;

    if (_latestStats == null) {
      _applyStats(effectiveStats);
    }

    final resourceDetailsAsync = ref.watch(
      heroicResourceDetailsProvider(
        HeroicResourceRequest(
          classId: effectiveStats.classId,
          fallbackName: effectiveStats.heroicResourceName,
        ),
      ),
    );

    // Update heroic resource min value when details or reason score changes
    final resourceDetails = resourceDetailsAsync.valueOrNull;
    if (resourceDetails != null) {
      final newMinValue = resourceDetails.calculateMinValue(
        reasonScore: effectiveStats.reasonTotal,
      );
      if (_heroicResourceMinValue != newMinValue ||
          _cachedResourceDetails != resourceDetails) {
        _heroicResourceMinValue = newMinValue;
        _cachedResourceDetails = resourceDetails;
      }
    }

    return _buildContent(context, effectiveStats, resourceDetailsAsync);
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              HeroMainStatsViewText.errorStateTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(heroMainStatsProvider(widget.heroId)),
              icon: const Icon(Icons.refresh),
              label: const Text(HeroMainStatsViewText.errorStateRetryLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HeroMainStats stats,
    AsyncValue<HeroicResourceDetails?> resourceDetails,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressionRowWidget(
            stats: _latestStats,
            onEditNumberField: (label, field) =>
                _showNumberEditDialog(context, label, field),
            onEditXp: (currentXp) => _showXpEditDialog(context, currentXp),
            onEditMod: ({
              required String title,
              required String modKey,
              required int baseValue,
              required int currentModValue,
              required List<String> insights,
              Color? accentColor,
              IconData? icon,
            }) =>
                _showModEditDialog(
              context,
              title: title,
              modKey: modKey,
              baseValue: baseValue,
              currentModValue: currentModValue,
              insights: insights,
              accentColor: accentColor,
              icon: icon,
            ),
          ),
          const SizedBox(height: 8),
          RespiteDowntimeRowWidget(
            stats: stats,
            onTakeRespite: () => _showRespiteConfirmDialog(context, stats),
            onNavigateDowntime: () => _navigateToDowntime(context),
          ),
          const SizedBox(height: 12),
          CombinedStatsCardWidget(
            stats: stats,
            onEditStat: ({
              required String label,
              required String modKey,
              required int baseValue,
              required int currentModValue,
              int featureBonus = 0,
              Color? accentColor,
            }) =>
                _showStatEditDialog(
              context,
              label: label,
              modKey: modKey,
              baseValue: baseValue,
              currentModValue: currentModValue,
              featureBonus: featureBonus,
              accentColor: accentColor,
            ),
            onEditSize: ({
              required String sizeBase,
              required int currentModValue,
            }) =>
                _showSizeEditDialog(
              context,
              sizeBase: sizeBase,
              currentModValue: currentModValue,
            ),
            getUserModValue: (modKey) => _getUserModValue(modKey),
          ),
          const SizedBox(height: 12),
          _buildVitalsCard(context, stats, resourceDetails),
          const SizedBox(height: 12),
          AutoHeroGreenFormWidget(
            heroId: widget.heroId,
            sectionTitle: HeroMainStatsViewText.greenElementalistFormsTitle,
            sectionSpacing: 12,
          ),
          ConditionsTrackerWidget(heroId: widget.heroId),
          const SizedBox(height: 12),
          DamageResistanceTrackerWidget(heroId: widget.heroId),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _navigateToDowntime(BuildContext context) {
    // Navigate to the downtime page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HeroDowntimeTrackingPage(
          heroId: widget.heroId,
          heroName: widget.heroName,
          isEmbedded: false,
        ),
      ),
    );
  }

  Future<void> _showRespiteConfirmDialog(
      BuildContext context, HeroMainStats stats) async {
    final victories = stats.victories;
    final currentXp = stats.exp;
    final newXp = currentXp + victories;
    final recoveriesMax = stats.recoveriesMaxEffective;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                  color: Colors.indigo.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bedtime_outlined, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              const Text(
                HeroMainStatsViewText.respiteDialogTitle,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HeroMainStatsViewText.respiteDialogIntro,
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 12),
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
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            size: 16, color: Colors.amber.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${HeroMainStatsViewText.respiteDialogConvertPrefix}$victories ${victories == 1 ? HeroMainStatsViewText.respiteDialogConvertSingular : HeroMainStatsViewText.respiteDialogConvertPlural}${HeroMainStatsViewText.respiteDialogConvertSuffix}',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 16, color: Colors.amber.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${HeroMainStatsViewText.respiteDialogXpPrefix}$currentXp${HeroMainStatsViewText.respiteDialogArrowSeparator}$newXp',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite,
                            size: 16, color: Colors.green.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${HeroMainStatsViewText.respiteDialogRecoveriesPrefix}${HeroMainStatsViewText.respiteDialogRecoveriesArrow}$recoveriesMax${HeroMainStatsViewText.respiteDialogRecoveriesSuffix}',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
              child: const Text(HeroMainStatsViewText.respiteDialogCancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
              ),
              child:
                  const Text(HeroMainStatsViewText.respiteDialogConfirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _handleTakeRespite(stats);
    }
  }

  Future<void> _handleTakeRespite(HeroMainStats stats) async {
    // Convert victories to XP
    final victories = stats.victories;
    final currentXp = stats.exp;
    final newXp = currentXp + victories;

    // Regain all recoveries
    final recoveriesMax = stats.recoveriesMaxEffective;

    // Restore stamina to max
    final staminaMax = stats.staminaMaxEffective;

    // Apply changes
    await _persistNumberField(_NumericField.exp, newXp.toString());
    await _persistNumberField(_NumericField.victories, '0');
    await _persistNumberField(
        _NumericField.recoveriesCurrent, recoveriesMax.toString());
    await _persistNumberField(
        _NumericField.staminaCurrent, staminaMax.toString());

    if (mounted) {
      _showSnack(
        '${HeroMainStatsViewText.respiteCompletePrefix}$victories${HeroMainStatsViewText.respiteCompleteSuffix}',
      );
    }
  }

  /// Helper method to get user mod value for a given modKey
  int _getUserModValue(String modKey) {
    return _latestStats?.userModValue(modKey) ?? 0;
  }

  /// Combined vitals card: Stamina, Recoveries, Heroic Resource, Surges
  Widget _buildVitalsCard(
    BuildContext context,
    HeroMainStats stats,
    AsyncValue<HeroicResourceDetails?> resourceDetails,
  ) {
    final theme = Theme.of(context);
    final staminaState = calculateStaminaState(stats);
    final healAmount = _recoveryHealAmount(stats);
    final staminaChoice = stats.choiceModValue(HeroModKeys.staminaMax);
    final staminaUser = stats.userModValue(HeroModKeys.staminaMax);
    final staminaFeatureBonus = stats.staminaFeatureBonus;
    final recoveriesChoice = stats.choiceModValue(HeroModKeys.recoveriesMax);
    final recoveriesUser = stats.userModValue(HeroModKeys.recoveriesMax);
    final recoveriesFeatureBonus = stats.recoveriesFeatureBonus;
    final equipmentStaminaBonus =
        stats.equipmentBonusFor(HeroModKeys.staminaMax);
    final treasureStaminaBonus = stats.treasureStaminaBonus;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stamina Section with visual bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: staminaState.color.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.favorite_outline,
                      size: 16, color: staminaState.color),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.staminaSectionTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: staminaState.color,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  staminaState.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: staminaState.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stamina bar and values
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom stamina bar showing -halfMax to max with temp HP
                      StaminaBarWidget(
                        stats: stats,
                        staminaState: staminaState,
                      ),
                      const SizedBox(height: 6),
                      // Current / Temp / Max row
                      Row(
                        children: [
                          _buildVitalItem(
                            context,
                            label:
                                HeroMainStatsViewText.vitalsStaminaCurrentLabel,
                            value: stats.staminaCurrent,
                            field: _NumericField.staminaCurrent,
                            allowNegative: true,
                          ),
                          const SizedBox(width: 12),
                          _buildVitalItem(
                            context,
                            label: HeroMainStatsViewText.vitalsStaminaTempLabel,
                            value: stats.staminaTemp,
                            field: _NumericField.staminaTemp,
                          ),
                          const SizedBox(width: 12),
                          _buildMaxVitalItem(
                            context,
                            label: HeroMainStatsViewText.vitalsStaminaMaxLabel,
                            value: stats.staminaMaxEffective,
                            modKey: HeroModKeys.staminaMax,
                            choiceValue: staminaChoice,
                            userValue: staminaUser,
                            baseValue: stats.staminaMaxBase,
                            equipmentBonus: equipmentStaminaBonus,
                            featureBonus: staminaFeatureBonus,
                            treasureBonus: treasureStaminaBonus,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactActionButton(
                      context,
                      icon: Icons.flash_on,
                      label: HeroMainStatsViewText.vitalsDamageLabel,
                      onPressed: () => _handleDealDamage(stats),
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(height: 4),
                    _buildCompactActionButton(
                      context,
                      icon: Icons.healing,
                      label: HeroMainStatsViewText.vitalsHealLabel,
                      onPressed: () => _handleApplyHealing(stats),
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // Recoveries row
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 16, color: AbilityColors.recovery),
                const SizedBox(width: 6),
                Text(
                  HeroMainStatsViewText.recoveriesSectionTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AbilityColors.recovery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildVitalItem(
                  context,
                  label: HeroMainStatsViewText.vitalsRecoveriesCurrentLabel,
                  value: stats.recoveriesCurrent,
                  field: _NumericField.recoveriesCurrent,
                ),
                const SizedBox(width: 12),
                _buildMaxVitalItem(
                  context,
                  label: HeroMainStatsViewText.vitalsRecoveriesMaxLabel,
                  value: stats.recoveriesMaxEffective,
                  modKey: HeroModKeys.recoveriesMax,
                  choiceValue: recoveriesChoice,
                  userValue: recoveriesUser,
                  baseValue: stats.recoveriesMaxBase,
                  featureBonus: recoveriesFeatureBonus,
                ),
                const SizedBox(width: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        HeroMainStatsViewText.vitalsRecoveriesHealValueLabel,
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        '+$healAmount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: healAmount > 0
                              ? Colors.green
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => _handleUseRecovery(stats),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: const Color.fromARGB(255, 37, 42, 40),
                    foregroundColor: AbilityColors.recoveryDark,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        HeroMainStatsViewText.vitalsRecoveriesUseLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Hero Tokens section
            HeroTokensSectionWidget(
              stats: stats,
              onEditNumberField: (label, field) =>
                  _showNumberEditDialog(context, label, field),
              onGainHeroToken: _gainHeroToken,
              onSpendForSurges: _spendHeroTokenForSurges,
              onSpendForStamina: _spendHeroTokensForStamina,
              onSpendHeroTokens: _spendHeroTokens,
              onShowInfo: (ctx) => showHeroTokensInfoDialog(ctx),
            ),
            const Divider(height: 20),
            // Heroic Resource and Surges row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HeroicResourceSectionWidget(
                    stats: stats,
                    resourceDetails: resourceDetails,
                    minValue: 0,
                    onEditNumberField: (label, field) =>
                        _showNumberEditDialog(context, label, field),
                    onSpendResource: _spendHeroicResource,
                    onHandleResourceGeneration: _handleResourceGeneration,
                    onShowResourceDetails: _showResourceDetailsDialog,
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: SurgesSectionWidget(
                    stats: stats,
                    onEditNumberField: (label, field) =>
                        _showNumberEditDialog(context, label, field),
                    onSpendSurges: _spendSurges,
                    onAddSurges: _addSurges,
                    onShowInfo: (ctx) => showSurgesInfoDialog(ctx),
                  ),
                ),
              ],
            ),
            // Heroic Resource Progression Widget (Fury/Null only)
            _buildHeroicResourceProgression(context, stats),
            // Psi Boost Widget (Talent/Null only)
            _buildPsiBoostSection(context, stats),
            const SizedBox(height: 12),
            // End of Combat button
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _handleEndOfCombat(stats),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text(HeroMainStatsViewText.endOfCombatLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                      color: theme.colorScheme.error.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(
    BuildContext context, {
    required String label,
    required int value,
    required _NumericField field,
    bool allowNegative = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final controller = TextEditingController(text: value.toString());
        try {
          final result = await showDialog<String>(
            context: context,
            builder: (dialogContext) {
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
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${HeroMainStatsViewText.vitalItemEditTitlePrefix}$label',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                content: TextField(
                  controller: controller,
                  keyboardType:
                      TextInputType.numberWithOptions(signed: allowNegative),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.vitalItemValueLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                  ),
                  inputFormatters: _formatters(allowNegative, 4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                    ),
                    child:
                        const Text(HeroMainStatsViewText.vitalItemCancelLabel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(controller.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(HeroMainStatsViewText.vitalItemSaveLabel),
                  ),
                ],
              );
            },
          );
          if (result != null && result.isNotEmpty && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              await _persistNumberField(field, result);
            });
          }
        } finally {
          await Future.delayed(const Duration(milliseconds: 50));
          controller.dispose();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxVitalItem(
    BuildContext context, {
    required String label,
    required int value,
    required String modKey,
    required int baseValue,
    required int choiceValue,
    required int userValue,
    int equipmentBonus = 0,
    int featureBonus = 0,
    int treasureBonus = 0,
  }) {
    final theme = Theme.of(context);
    final otherChoice = choiceValue - equipmentBonus;
    final hasBreakdown = equipmentBonus != 0 ||
        treasureBonus != 0 ||
        otherChoice != 0 ||
        userValue != 0 ||
        featureBonus != 0;

    return InkWell(
      onTap: () async {
        // Show breakdown dialog
        await _showMaxVitalBreakdownDialog(
          context,
          label: label,
          modKey: modKey,
          classBase: baseValue,
          equipmentBonus: equipmentBonus,
          featureBonus: featureBonus,
          choiceValue: otherChoice,
          userValue: userValue,
          total: value,
          treasureBonus: treasureBonus,
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                if (hasBreakdown)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 10,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasBreakdown)
                  Text(
                    ' ($baseValue'
                    '${equipmentBonus != 0 ? _formatSigned(equipmentBonus) : ''}'
                    '${treasureBonus != 0 ? _formatSigned(treasureBonus) : ''}'
                    '${featureBonus != 0 ? _formatSigned(featureBonus) : ''}'
                    '${otherChoice != 0 ? _formatSigned(otherChoice) : ''}'
                    '${userValue != 0 ? _formatSigned(userValue) : ''})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMaxVitalBreakdownDialog(
    BuildContext context, {
    required String label,
    required String modKey,
    required int classBase,
    required int equipmentBonus,
    required int featureBonus,
    required int choiceValue,
    required int userValue,
    required int total,
    int treasureBonus = 0,
  }) async {
    final hasChoice = equipmentBonus != 0 || choiceValue != 0;
    final hasUser = userValue != 0;
    final hasFeature = featureBonus != 0;
    final hasTreasure = treasureBonus != 0;

    await showDialog(
      context: context,
      builder: (dialogContext) {
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
                  color: Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text(
                '$label${HeroMainStatsViewText.maxVitalBreakdownTitleSuffix}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownClassBaseLabel,
                classBase,
              ),
              if (equipmentBonus > 0)
                _buildBreakdownRow(
                  HeroMainStatsViewText.breakdownEquipmentLabel,
                  equipmentBonus,
                  isBonus: equipmentBonus > 0,
                ),
              if (hasTreasure)
                _buildBreakdownRow(
                  HeroMainStatsViewText.breakdownTreasureLabel,
                  treasureBonus,
                  isBonus: treasureBonus > 0,
                ),
              if (hasFeature)
                _buildBreakdownRow(
                  HeroMainStatsViewText.breakdownFeaturesLabel,
                  featureBonus,
                  isBonus: featureBonus > 0,
                ),
              if (hasChoice)
                _buildBreakdownRow(
                  HeroMainStatsViewText.breakdownChoiceModsLabel,
                  choiceValue,
                  isBonus: choiceValue >= 0,
                ),
              if (hasUser)
                _buildBreakdownRow(
                  HeroMainStatsViewText.breakdownManualModsLabel,
                  userValue,
                  isBonus: userValue >= 0,
                ),
              Divider(color: Colors.grey.shade700),
              _buildBreakdownRow(
                HeroMainStatsViewText.breakdownTotalLabel,
                total,
                isBold: true,
              ),
              const SizedBox(height: 16),
              Text(
                HeroMainStatsViewText.breakdownEditHint,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
              child: const Text(HeroMainStatsViewText.breakdownCloseLabel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _showStatEditDialog(
                  context,
                  label:
                      '$label${HeroMainStatsViewText.breakdownModifierSuffix}',
                  modKey: modKey,
                  baseValue:
                      classBase + equipmentBonus + featureBonus + choiceValue,
                  currentModValue: userValue,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child:
                  const Text(HeroMainStatsViewText.breakdownEditModifierLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreakdownRow(String label, int value,
      {bool isBonus = false, bool isBold = false}) {
    final valueText = isBonus ? '+$value' : value.toString();
    final color = isBonus
        ? Colors.green.shade400
        : (value < 0 ? Colors.red.shade400 : Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.white : Colors.grey.shade300,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 56,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResourceGeneration(
    BuildContext context,
    HeroMainStats stats,
    String optionKey,
  ) async {
    final result = ResourceGenerationService.instance.calculateGeneration(
      optionKey: optionKey,
      victories: stats.victories,
      classId: stats.classId,
      heroLevel: stats.level,
    );

    if (result.requiresConfirmation && result.alternativeValues != null) {
      // Show dice roll confirmation dialog
      final selectedValue = await _showDiceRollDialog(
        context,
        rolledValue: result.value,
        alternatives: result.alternativeValues!,
        diceType: HeroMainStatsViewText.diceTypeOneDThree,
        diceToValueMapping: result.diceToValueMapping,
      );

      if (selectedValue != null && mounted) {
        await _applyResourceGeneration(stats, selectedValue);
      }
    } else {
      // Apply directly
      await _applyResourceGeneration(stats, result.value);
    }
  }

  Future<int?> _showDiceRollDialog(
    BuildContext context, {
    required int rolledValue,
    required List<int> alternatives,
    required String diceType,
    Map<int, int>? diceToValueMapping,
  }) async {
    // Find which dice roll corresponds to the rolled value
    int? rolledDice;
    if (diceToValueMapping != null) {
      for (final entry in diceToValueMapping.entries) {
        if (entry.value == rolledValue) {
          rolledDice = entry.key;
          break;
        }
      }
    }

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
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
                child: const Icon(Icons.casino, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Text(
                '$diceType${HeroMainStatsViewText.diceRollTitleSuffix}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rolledDice != null && diceToValueMapping != null) ...[
                Text(
                  '${HeroMainStatsViewText.diceRolledDicePrefix}$rolledDice',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${HeroMainStatsViewText.diceGainPrefix}$rolledValue${HeroMainStatsViewText.diceGainSuffix}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber.shade400,
                  ),
                ),
              ] else
                Text(
                  '${HeroMainStatsViewText.diceRolledValuePrefix}$rolledValue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade300,
                  ),
                ),
              const SizedBox(height: 16),
              // Show the dice-to-value mapping table if available
              if (diceToValueMapping != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        HeroMainStatsViewText.diceRollValuesTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: diceToValueMapping.entries.map((entry) {
                          final isRolled = entry.key == rolledDice;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isRolled
                                  ? Colors.purple.withAlpha(60)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isRolled
                                  ? Border.all(
                                      color: Colors.purple,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${entry.key}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isRolled
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '+${entry.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade300,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                HeroMainStatsViewText.diceAcceptPrompt,
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: alternatives.map((value) {
                  final isRolled = value == rolledValue;
                  return ActionChip(
                    label: Text(
                      '+$value',
                      style: TextStyle(
                        fontWeight:
                            isRolled ? FontWeight.bold : FontWeight.normal,
                        color: isRolled ? Colors.white : Colors.grey.shade300,
                      ),
                    ),
                    backgroundColor: isRolled
                        ? Colors.purple.withAlpha(60)
                        : Colors.grey.shade800,
                    side: isRolled
                        ? const BorderSide(color: Colors.purple, width: 2)
                        : BorderSide(color: Colors.grey.shade700),
                    onPressed: () => Navigator.of(dialogContext).pop(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
              child: const Text(HeroMainStatsViewText.diceCancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(rolledValue),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                '${HeroMainStatsViewText.diceAcceptPrefix}$rolledValue',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyResourceGeneration(HeroMainStats stats, int amount) async {
    if (!mounted || amount <= 0) return;

    final newValue = stats.heroicResourceCurrent + amount;

    try {
      await ref.read(heroRepositoryProvider).updateVitals(
            widget.heroId,
            heroicResourceCurrent: newValue,
          );
      _showSnack(
        '${HeroMainStatsViewText.resourceAddedPrefix}$amount${HeroMainStatsViewText.resourceAddedSuffix}',
      );
    } catch (err) {
      if (!mounted) return;
      _showSnack('${HeroMainStatsViewText.resourceAddErrorPrefix}$err');
    }
  }

  /// Build the heroic resource progression widget for Fury and Null classes
  Widget _buildHeroicResourceProgression(
      BuildContext context, HeroMainStats stats) {
    final progressionAsync =
        ref.watch(heroResourceProgressionProvider(widget.heroId));
    final progressionContextAsync =
        ref.watch(heroProgressionContextProvider(widget.heroId));

    // Keep showing the previous progression/context while Riverpod refreshes to avoid UI flicker.
    final progression = progressionAsync.valueOrNull;
    final progressionContext = progressionContextAsync.valueOrNull;

    if (progression == null || progressionContext == null) {
      return const SizedBox.shrink();
    }

    // Check if Stormwight without kit
    final service = HeroicResourceProgressionService();
    if (service.isStormwightSubclass(progressionContext.subclassName) &&
        (progressionContext.kitId == null ||
            progressionContext.kitId!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Divider(height: 20),
        HeroicResourceGauge(
          progression: progression,
          currentResource: stats.heroicResourceCurrent,
          heroLevel: stats.level,
          showCompact: true,
        ),
      ],
    );
  }

  /// Build the Psi Boost widget for Talent and Null classes
  Widget _buildPsiBoostSection(BuildContext context, HeroMainStats stats) {
    final hasPsiBoostAsync = ref.watch(heroPsiBoostProvider(widget.heroId));

    // Only show if hero has the psi boost feature
    final hasPsiBoost = hasPsiBoostAsync.valueOrNull ?? false;
    if (!hasPsiBoost) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Divider(height: 20),
        PsiBoostWidget(
          currentResource: stats.heroicResourceCurrent,
          resourceName: stats.heroicResourceName ??
              HeroMainStatsViewText.psiBoostResourceFallbackName,
          onSpendResource: (cost, boostName) {
            final newValue = stats.heroicResourceCurrent - cost;
            if (newValue >= 0) {
              _persistNumberField(
                  _NumericField.heroicResourceCurrent, newValue.toString());
              _showSnack(
                '${HeroMainStatsViewText.psiBoostUsedPrefix}$boostName${HeroMainStatsViewText.psiBoostUsedCostPrefix}$cost ${stats.heroicResourceName ?? HeroMainStatsViewText.psiBoostSnackResourceFallbackName}${HeroMainStatsViewText.psiBoostUsedSuffix}',
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _spendHeroicResource(int amount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final current = stats.heroicResourceCurrent;
    final newValue = current - amount;

    // Check against dynamic minimum (can be negative for classes like Talent)
    if (newValue < _heroicResourceMinValue) return;

    await _persistNumberField(
        _NumericField.heroicResourceCurrent, newValue.toString());
  }

  Future<void> _spendSurges(int amount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final current = stats.surgesCurrent;
    if (current < amount) return;

    final newValue = current - amount;
    await _persistNumberField(_NumericField.surgesCurrent, newValue.toString());
  }

  Future<void> _addSurges(int amount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final current = stats.surgesCurrent;
    final newValue = current + amount;
    await _persistNumberField(_NumericField.surgesCurrent, newValue.toString());
  }

  Future<void> _gainHeroToken(int amount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final current = stats.heroTokensCurrent;
    final newValue = (current + amount).clamp(0, 99);
    await _persistNumberField(
        _NumericField.heroTokensCurrent, newValue.toString());
  }

  Future<void> _spendHeroTokenForSurges(int tokenCost, int surgesGained) async {
    final stats = _latestStats;
    if (stats == null) return;

    final currentTokens = stats.heroTokensCurrent;
    if (currentTokens < tokenCost) return;

    // Deduct tokens
    final newTokens = currentTokens - tokenCost;
    await _persistNumberField(
        _NumericField.heroTokensCurrent, newTokens.toString());

    // Add surges
    final currentSurges = stats.surgesCurrent;
    final newSurges = currentSurges + surgesGained;
    await _persistNumberField(
        _NumericField.surgesCurrent, newSurges.toString());
  }

  Future<void> _spendHeroTokensForStamina(
      int tokenCost, int staminaAmount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final currentTokens = stats.heroTokensCurrent;
    if (currentTokens < tokenCost) return;

    // Deduct tokens
    final newTokens = currentTokens - tokenCost;
    await _persistNumberField(
        _NumericField.heroTokensCurrent, newTokens.toString());

    // Add stamina up to max
    final currentStamina = stats.staminaCurrent;
    final maxStamina = stats.staminaMaxEffective;
    final newStamina = (currentStamina + staminaAmount).clamp(0, maxStamina);
    await _persistNumberField(
        _NumericField.staminaCurrent, newStamina.toString());
  }

  Future<void> _spendHeroTokens(int amount) async {
    final stats = _latestStats;
    if (stats == null) return;

    final currentTokens = stats.heroTokensCurrent;
    if (currentTokens < amount) return;

    final newTokens = currentTokens - amount;
    await _persistNumberField(
        _NumericField.heroTokensCurrent, newTokens.toString());
  }

  Future<void> _handleEndOfCombat(HeroMainStats stats) async {
    // Reset heroic resource and surges to 0
    await _persistNumberField(_NumericField.heroicResourceCurrent, '0');
    await _persistNumberField(_NumericField.surgesCurrent, '0');
  }

  // ignore: unused_element
  Widget _buildSummaryCard(BuildContext context) {
    final level = _latestStats?.level ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCompactNumberDisplay(
              context,
              label: HeroMainStatsViewText.summaryVictoriesLabel,
              field: _NumericField.victories,
            ),
            _buildCompactNumberDisplay(
              context,
              label: HeroMainStatsViewText.summaryXpLabel,
              field: _NumericField.exp,
            ),
            // Level - read-only display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    HeroMainStatsViewText.summaryLevelLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWealthRenownCard(BuildContext context, HeroMainStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _buildCompactEconomyTile(
                context,
                title: HeroMainStatsViewText.wealthCardTitle,
                baseValue: stats.wealthBase,
                totalValue: stats.wealthTotal,
                modKey: HeroModKeys.wealth,
                insights: _wealthInsights(stats.wealthTotal),
                accentColor: Colors.purple.shade400,
                icon: Icons.paid_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactEconomyTile(
                context,
                title: HeroMainStatsViewText.renownCardTitle,
                baseValue: stats.renownBase,
                totalValue: stats.renownTotal,
                modKey: HeroModKeys.renown,
                insights: _renownInsights(stats.renownTotal),
                accentColor: Colors.purple.shade400,
                icon: Icons.military_tech_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEconomyTile(
    BuildContext context, {
    required String title,
    required int baseValue,
    required int totalValue,
    required String modKey,
    required List<String> insights,
  }) {
    final theme = Theme.of(context);
    final currentMod = _latestStats?.modValue(modKey) ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            totalValue.toString(),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(
                  '${HeroMainStatsViewText.economyTileBasePrefix}$baseValue',
                ),
              ),
              Chip(
                label: Text(
                  '${HeroMainStatsViewText.economyTileModPrefix}${_formatSigned(currentMod)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModificationInput(
            context,
            label: HeroMainStatsViewText.economyTileAdjustModLabel,
            modKey: modKey,
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final line in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPrimaryStatsCard(BuildContext context, HeroMainStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HeroMainStatsViewText.primaryStatsTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.primaryStatsMightLabel,
                  stats.mightBase,
                  stats.mightTotal,
                  HeroModKeys.might,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.primaryStatsAgilityLabel,
                  stats.agilityBase,
                  stats.agilityTotal,
                  HeroModKeys.agility,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.primaryStatsReasonLabel,
                  stats.reasonBase,
                  stats.reasonTotal,
                  HeroModKeys.reason,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.primaryStatsIntuitionLabel,
                  stats.intuitionBase,
                  stats.intuitionTotal,
                  HeroModKeys.intuition,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.primaryStatsPresenceLabel,
                  stats.presenceBase,
                  stats.presenceTotal,
                  HeroModKeys.presence,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSecondaryStatsCard(BuildContext context, HeroMainStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HeroMainStatsViewText.secondaryStatsTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactSizeTile(
                    context, stats.sizeBase, stats.sizeTotal, HeroModKeys.size),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.secondaryStatsSpeedLabel,
                  stats.speedBase,
                  stats.speedTotal,
                  HeroModKeys.speed,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.secondaryStatsDisengageLabel,
                  stats.disengageBase,
                  stats.disengageTotal,
                  HeroModKeys.disengage,
                ),
                _buildCompactStatTile(
                  context,
                  HeroMainStatsViewText.secondaryStatsStabilityLabel,
                  stats.stabilityBase,
                  stats.stabilityTotal,
                  HeroModKeys.stability,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatCollection(
    BuildContext context,
    String title,
    List<_StatTileData> data,
  ) {
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final item in data) _buildStatTile(context, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, _StatTileData data) {
    final theme = Theme.of(context);
    final currentMod = _latestStats?.modValue(data.modKey) ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _formatSigned(data.totalValue),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(
                  '${HeroMainStatsViewText.statTileBasePrefix}${_formatSigned(data.baseValue)}',
                ),
              ),
              Chip(
                label: Text(
                  '${HeroMainStatsViewText.statTileModPrefix}${_formatSigned(currentMod)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildModificationInput(
            context,
            label: HeroMainStatsViewText.statTileAdjustModLabel,
            modKey: data.modKey,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStaminaAndRecoveries(
    BuildContext context,
    HeroMainStats stats,
  ) {
    final children = [
      Expanded(child: _buildStaminaCard(context, stats)),
      const SizedBox(width: 16),
      Expanded(child: _buildRecoveriesCard(context, stats)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(children: children);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStaminaCard(context, stats),
            const SizedBox(height: 16),
            _buildRecoveriesCard(context, stats),
          ],
        );
      },
    );
  }

  Widget _buildStaminaCard(BuildContext context, HeroMainStats stats) {
    final theme = Theme.of(context);
    final state = calculateStaminaState(stats);
    final equipmentStaminaBonus =
        stats.equipmentBonusFor(HeroModKeys.staminaMax);
    final treasureStaminaBonus = stats.treasureStaminaBonus;
    final staminaFeatureBonus = stats.staminaFeatureBonus;
    final effectiveMax = stats.staminaMaxEffective;
    final staminaChoiceMod = stats.choiceModValue(HeroModKeys.staminaMax);
    final staminaManualMod = stats.userModValue(HeroModKeys.staminaMax);
    final staminaMaxMod =
        staminaChoiceMod + staminaManualMod + staminaFeatureBonus;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: state.color.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.favorite, size: 14, color: state.color),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.staminaCardTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  state.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: state.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactVitalDisplay(
                    context,
                    label: HeroMainStatsViewText.staminaCardCurrentLabel,
                    field: _NumericField.staminaCurrent,
                    allowNegative: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactVitalDisplay(
                    context,
                    label: HeroMainStatsViewText.staminaCardTempLabel,
                    field: _NumericField.staminaTemp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      if (!mounted) return;
                      await _showMaxVitalBreakdownDialog(
                        context,
                        label: HeroMainStatsViewText.staminaCardMaxLabel,
                        modKey: HeroModKeys.staminaMax,
                        classBase: stats.staminaMaxBase,
                        equipmentBonus: equipmentStaminaBonus,
                        treasureBonus: treasureStaminaBonus,
                        featureBonus: staminaFeatureBonus,
                        choiceValue: staminaChoiceMod,
                        userValue: staminaManualMod,
                        total: effectiveMax,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            HeroMainStatsViewText.staminaCardMaxShortLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            effectiveMax.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildModValueWithSources(
                            modValue: staminaMaxMod,
                            modKey: HeroModKeys.staminaMax,
                            ancestryMods: _ancestryMods,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDealDamage(stats),
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text(
                      HeroMainStatsViewText.staminaCardDamageLabel,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApplyHealing(stats),
                    icon: const Icon(Icons.healing, size: 16),
                    label: const Text(
                      HeroMainStatsViewText.staminaCardHealLabel,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveriesCard(BuildContext context, HeroMainStats stats) {
    final theme = Theme.of(context);
    final healAmount = _recoveryHealAmount(stats);
    final recoveriesFeatureBonus = stats.recoveriesFeatureBonus;
    final recoveriesChoiceMod = stats.choiceModValue(HeroModKeys.recoveriesMax);
    final recoveriesManualMod = stats.userModValue(HeroModKeys.recoveriesMax);
    final recoveriesMaxMod =
        recoveriesChoiceMod + recoveriesManualMod + recoveriesFeatureBonus;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.local_hospital,
                      size: 14, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.recoveriesCardTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCompactVitalDisplay(
                    context,
                    label: HeroMainStatsViewText.recoveriesCardCurrentLabel,
                    field: _NumericField.recoveriesCurrent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      if (!mounted) return;
                      await _showMaxVitalBreakdownDialog(
                        context,
                        label: HeroMainStatsViewText.recoveriesCardMaxLabel,
                        modKey: HeroModKeys.recoveriesMax,
                        classBase: stats.recoveriesMaxBase,
                        equipmentBonus: 0,
                        featureBonus: recoveriesFeatureBonus,
                        choiceValue: recoveriesChoiceMod,
                        userValue: recoveriesManualMod,
                        total: stats.recoveriesMaxEffective,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            HeroMainStatsViewText.recoveriesCardMaxShortLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stats.recoveriesMaxEffective.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildModValueWithSources(
                            modValue: recoveriesMaxMod,
                            modKey: HeroModKeys.recoveriesMax,
                            ancestryMods: _ancestryMods,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: () => _handleUseRecovery(stats),
                    icon: const Icon(Icons.local_hospital, size: 16),
                    label: Text(
                      '${HeroMainStatsViewText.recoveriesCardUsePrefix}$healAmount${HeroMainStatsViewText.recoveriesCardUseSuffix}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildResourceAndSurges(
    BuildContext context,
    HeroMainStats stats,
    AsyncValue<HeroicResourceDetails?> resourceDetails,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildHeroicResourceCard(context, stats, resourceDetails),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSurgesCard(context, stats),
        ),
      ],
    );
  }

  Widget _buildHeroicResourceCard(
    BuildContext context,
    HeroMainStats stats,
    AsyncValue<HeroicResourceDetails?> resourceDetails,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: resourceDetails.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 14, color: Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stats.heroicResourceName ??
                        HeroMainStatsViewText
                            .heroicResourceCardFallbackNameError,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCompactVitalDisplay(
                context,
                label:
                    HeroMainStatsViewText.heroicResourceCardCurrentLabelError,
                field: _NumericField.heroicResourceCurrent,
              ),
            ],
          ),
          data: (details) {
            final resourceName = details?.name ??
                stats.heroicResourceName ??
                HeroMainStatsViewText.heroicResourceCardFallbackName;
            final hasDetails = (details?.description ?? '').isNotEmpty ||
                (details?.inCombatDescription ?? '').isNotEmpty ||
                (details?.outCombatDescription ?? '').isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 14, color: Colors.purple),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resourceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasDetails)
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showResourceDetailsDialog(
                          context,
                          resourceName,
                          details,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCompactVitalDisplay(
                  context,
                  label: HeroMainStatsViewText.heroicResourceCardCurrentLabel,
                  field: _NumericField.heroicResourceCurrent,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResourceDetailsDialog(
    BuildContext context,
    String name,
    HeroicResourceDetails? details,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                child: const Icon(Icons.auto_awesome, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((details?.description ?? '').isNotEmpty) ...[
                  Text(
                    details!.description!,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((details?.inCombatDescription ?? '').isNotEmpty) ...[
                  Text(
                    details?.inCombatName ??
                        HeroMainStatsViewText.resourceDetailsInCombatFallback,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details!.inCombatDescription!,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((details?.outCombatDescription ?? '').isNotEmpty) ...[
                  Text(
                    details?.outCombatName ??
                        HeroMainStatsViewText.resourceDetailsOutCombatFallback,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details!.outCombatDescription!,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((details?.strainDescription ?? '').isNotEmpty) ...[
                  Text(
                    details?.strainName ??
                        HeroMainStatsViewText.resourceDetailsStrainFallback,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details!.strainDescription!,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
              child:
                  const Text(HeroMainStatsViewText.resourceDetailsCloseLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurgesCard(BuildContext context, HeroMainStats stats) {
    // Calculate surge damage based on highest attribute
    final highestAttribute = [
      stats.mightTotal,
      stats.agilityTotal,
      stats.reasonTotal,
      stats.intuitionTotal,
      stats.presenceTotal,
    ].reduce((a, b) => a > b ? a : b);

    final surgeDamage = highestAttribute;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.flash_on,
                      size: 14, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Text(
                  HeroMainStatsViewText.surgesCardTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${HeroMainStatsViewText.surgesCardTotalPrefix}${stats.surgesTotal}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCompactVitalDisplay(
              context,
              label: HeroMainStatsViewText.surgesCardCurrentLabel,
              field: _NumericField.surgesCurrent,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          HeroMainStatsViewText.surgesCardOneSurgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          '$surgeDamage${HeroMainStatsViewText.surgesCardDamageSuffix}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          HeroMainStatsViewText.surgesCardTwoSurgesLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          HeroMainStatsViewText.surgesCardPotencyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Delegates to extracted helper function
  int _numberValueFromStats(HeroMainStats stats, _NumericField field) {
    return getNumberValueFromStats(stats, field);
  }

  Widget _buildModificationInput(
    BuildContext context, {
    required String label,
    required String modKey,
  }) {
    final theme = Theme.of(context);
    final controller = _modControllers[modKey]!;
    final focusNode = _modFocusNodes[modKey]!;

    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            maxLength: 4,
            buildCounter: (_,
                    {int? currentLength, bool? isFocused, int? maxLength}) =>
                null,
            inputFormatters: _formatters(true, 4),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNumberDisplay(
    BuildContext context, {
    required String label,
    required _NumericField field,
  }) {
    final theme = Theme.of(context);
    final value =
        _latestStats != null ? _numberValueFromStats(_latestStats!, field) : 0;

    return InkWell(
      onTap: () async {
        if (!mounted) return;
        await _showNumberEditDialog(context, label, field);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 2),
            Text(
              value.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactEconomyTile(
    BuildContext context, {
    required String title,
    required int baseValue,
    required int totalValue,
    required String modKey,
    required List<String> insights,
    Color? accentColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final modValue = totalValue - baseValue;

    return InkWell(
      onTap: () async {
        if (!mounted) return;
        await _showModEditDialog(
          context,
          title: title,
          modKey: modKey,
          baseValue: baseValue,
          currentModValue: modValue,
          insights: insights,
          accentColor: accentColor,
          icon: icon,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  totalValue.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (modValue != 0) ...[
                  const SizedBox(width: 4),
                  _buildModValueWithSources(
                    modValue: modValue,
                    modKey: modKey,
                    ancestryMods: _ancestryMods,
                    theme: theme,
                  ),
                ],
              ],
            ),
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                insights.first,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showNumberEditDialog(
    BuildContext context,
    String label,
    _NumericField field,
  ) async {
    if (!mounted) return;

    // Use amber for victories (like XP), blue for other number fields
    final isVictories = field == _NumericField.victories;
    final color = isVictories ? Colors.amber : Colors.blue;
    final icon = isVictories ? Icons.emoji_events : Icons.edit;

    final controller = TextEditingController(
      text: _numberValueFromStats(_latestStats!, field).toString(),
    );

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${HeroMainStatsViewText.numberEditTitlePrefix}$label',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
              ),
              inputFormatters: field == _NumericField.staminaCurrent
                  ? _formatters(true, 4)
                  : _formatters(false, 3),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(HeroMainStatsViewText.numberEditCancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text(HeroMainStatsViewText.numberEditSaveLabel),
              ),
            ],
          );
        },
      );

      // Ensure dialog is fully dismissed before persisting
      if (result != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _persistNumberField(field, result.toString());
        });
      }
    } finally {
      // Brief delay to ensure dialog animation completes
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  Future<void> _showXpEditDialog(BuildContext context, int currentXp) async {
    if (!mounted) return;

    final controller = TextEditingController(text: currentXp.toString());
    final currentLevel = _latestStats?.level ?? 1;

    // Load saved XP speed from config
    final configService = ref.read(heroConfigServiceProvider);
    final savedConfig = await configService.getConfigValue(
        widget.heroId, HeroConfigKeys.xpSpeed);
    final initialSpeed = XpSpeed.fromString(savedConfig?['speed'] as String?);

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Text(
                  HeroMainStatsViewText.xpEditTitle,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: _XpEditDialogContent(
              controller: controller,
              currentLevel: currentLevel,
              currentXp: currentXp,
              initialSpeed: initialSpeed,
              formatters: _formatters(false, 3),
              onSpeedChanged: (speed) async {
                // Save the new speed to config
                await configService.setConfigValue(
                  heroId: widget.heroId,
                  key: HeroConfigKeys.xpSpeed,
                  value: {'speed': speed.name},
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(HeroMainStatsViewText.xpEditCancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(HeroMainStatsViewText.xpEditSaveLabel),
              ),
            ],
          );
        },
      );

      // Ensure dialog is fully dismissed before persisting
      if (result != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _persistNumberField(_NumericField.exp, result.toString());
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  Future<void> _showModEditDialog(
    BuildContext context, {
    required String title,
    required String modKey,
    required int baseValue,
    required int currentModValue,
    required List<String> insights,
    Color? accentColor,
    IconData? icon,
  }) async {
    if (!mounted) return;

    // Special handling for wealth to show coin purse
    if (modKey == HeroModKeys.wealth) {
      await _showWealthEditDialog(
        context,
        baseValue: baseValue,
        currentModValue: currentModValue,
        insights: insights,
      );
      return;
    }

    final color = accentColor ?? Colors.teal;
    final dialogIcon = icon ?? Icons.tune;
    final controller = TextEditingController(text: currentModValue.toString());
    final sourcesDesc = _getModSourceDescription(
      modKey,
      _ancestryMods,
      includeEquipment: false,
    );

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(dialogIcon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${HeroMainStatsViewText.modEditTitlePrefix}$title',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${HeroMainStatsViewText.modEditBasePrefix}$baseValue',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
                if (sourcesDesc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.purple.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sourcesDesc,
                            style: TextStyle(
                              color: Colors.purple.shade200,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.modEditModificationLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    helperText: HeroMainStatsViewText.modEditHelperText,
                    helperStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                  inputFormatters: _formatters(true, 4),
                ),
                if (insights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...insights.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          insight,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(HeroMainStatsViewText.modEditCancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text(HeroMainStatsViewText.modEditSaveLabel),
              ),
            ],
          );
        },
      );

      // Ensure dialog is fully dismissed before persisting
      if (result != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _persistModification(modKey, result.toString());
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  Widget _buildCompactStatTile(
    BuildContext context,
    String label,
    int baseValue,
    int totalValue,
    String modKey,
  ) {
    final theme = Theme.of(context);
    final modValue = totalValue - baseValue;
    final manualMod = _latestStats?.userModValue(modKey) ?? 0;

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (!mounted) return;
          await _showStatEditDialog(
            context,
            label: label,
            modKey: modKey,
            baseValue: baseValue,
            currentModValue: manualMod,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                totalValue.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildModValueWithSources(
                modValue: modValue,
                modKey: modKey,
                ancestryMods: _ancestryMods,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact tile for Size which uses string values (e.g., "1M", "2")
  Widget _buildCompactSizeTile(
    BuildContext context,
    String sizeBase,
    String sizeTotal,
    String modKey,
  ) {
    final theme = Theme.of(context);
    // Use progression index difference to calculate mod value
    final baseIndex = HeroMainStats.sizeToIndex(sizeBase);
    final totalIndex = HeroMainStats.sizeToIndex(sizeTotal);
    final modValue = totalIndex - baseIndex;
    final manualMod = _latestStats?.userModValue(modKey) ?? 0;

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (!mounted) return;
          await _showSizeEditDialog(
            context,
            sizeBase: sizeBase,
            currentModValue: manualMod,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                HeroMainStatsViewText.compactSizeLabel,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                sizeTotal,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildModValueWithSources(
                modValue: modValue,
                modKey: modKey,
                ancestryMods: _ancestryMods,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactVitalDisplay(
    BuildContext context, {
    required String label,
    required _NumericField field,
    bool allowNegative = false,
  }) {
    final theme = Theme.of(context);
    final value =
        _latestStats != null ? _numberValueFromStats(_latestStats!, field) : 0;

    return InkWell(
      onTap: () async {
        if (!mounted) return;

        final controller = TextEditingController(text: value.toString());

        try {
          final result = await showDialog<String>(
            context: context,
            builder: (dialogContext) {
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
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${HeroMainStatsViewText.compactVitalEditTitlePrefix}$label',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                content: TextField(
                  controller: controller,
                  keyboardType:
                      TextInputType.numberWithOptions(signed: allowNegative),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.compactVitalValueLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                  ),
                  inputFormatters: _formatters(allowNegative, 4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                    ),
                    child: const Text(
                        HeroMainStatsViewText.compactVitalCancelLabel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(controller.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        const Text(HeroMainStatsViewText.compactVitalSaveLabel),
                  ),
                ],
              );
            },
          );

          // Ensure dialog is fully dismissed before persisting
          if (result != null && result.isNotEmpty && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              await _persistNumberField(field, result);
            });
          }
        } finally {
          await Future.delayed(const Duration(milliseconds: 50));
          controller.dispose();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatEditDialog(
    BuildContext context, {
    required String label,
    required String modKey,
    required int baseValue,
    required int currentModValue,
    int featureBonus = 0,
    Color? accentColor,
  }) async {
    if (!mounted) return;

    final color = accentColor ?? Colors.blue;
    final controller = TextEditingController(text: currentModValue.toString());
    final sourcesDesc = _getModSourceDescription(
      modKey,
      _ancestryMods,
      includeEquipment: false,
    );
    final equipmentBonus = _latestStats?.equipmentBonusFor(modKey) ?? 0;
    final choiceTotal = _latestStats?.choiceModValue(modKey) ?? 0;
    // remainingChoice = other choice bonuses (ancestry, etc.) excluding equipment
    // featureBonus is separate (from dynamic modifiers), not part of choiceTotal
    final remainingChoice = choiceTotal - equipmentBonus;

    final autoBonusParts = <String>[];
    if (equipmentBonus != 0) {
      autoBonusParts.add(
        '${_formatSigned(equipmentBonus)}${HeroMainStatsViewText.statEditFromEquipmentSuffix}',
      );
    }
    if (featureBonus != 0) {
      autoBonusParts.add(
        '${_formatSigned(featureBonus)}${HeroMainStatsViewText.statEditFromFeaturesSuffix}',
      );
    }
    if (sourcesDesc.isNotEmpty) {
      autoBonusParts.add(sourcesDesc);
    } else if (remainingChoice != 0) {
      autoBonusParts.add(
        '${_formatSigned(remainingChoice)}${HeroMainStatsViewText.statEditFromBonusesSuffix}',
      );
    }
    final autoBonusDescription = autoBonusParts.join('; ');

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${HeroMainStatsViewText.statEditTitlePrefix}$label',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${HeroMainStatsViewText.statEditBasePrefix}$baseValue',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
                if (autoBonusDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.purple.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            autoBonusDescription,
                            style: TextStyle(
                              color: Colors.purple.shade200,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.statEditModificationLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    helperText: HeroMainStatsViewText.statEditHelperText,
                    helperStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                  inputFormatters: _formatters(true, 4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(HeroMainStatsViewText.statEditCancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text(HeroMainStatsViewText.statEditSaveLabel),
              ),
            ],
          );
        },
      );

      // Ensure dialog is fully dismissed before persisting
      if (result != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _persistModification(modKey, result.toString());
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  Future<void> _showSizeEditDialog(
    BuildContext context, {
    required String sizeBase,
    required int currentModValue,
  }) async {
    if (!mounted) return;

    final controller = TextEditingController(text: currentModValue.toString());
    final sourcesDesc =
        _getModSourceDescription(HeroModKeys.size, _ancestryMods);
    final parsed = HeroMainStats.parseSize(sizeBase);
    final categoryName = switch (parsed.category) {
      'T' => HeroMainStatsViewText.sizeCategoryTiny,
      'S' => HeroMainStatsViewText.sizeCategorySmall,
      'M' => HeroMainStatsViewText.sizeCategoryMedium,
      'L' => HeroMainStatsViewText.sizeCategoryLarge,
      _ => '',
    };
    final baseDisplay =
        categoryName.isNotEmpty ? '$sizeBase ($categoryName)' : sizeBase;

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.straighten, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  HeroMainStatsViewText.sizeEditTitle,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${HeroMainStatsViewText.sizeEditBasePrefix}$baseDisplay',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
                if (sourcesDesc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.purple.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sourcesDesc,
                            style: TextStyle(
                              color: Colors.purple.shade200,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.sizeEditModificationLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    helperText: HeroMainStatsViewText.sizeEditHelperText,
                    helperStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange.shade400),
                    ),
                  ),
                  inputFormatters: _formatters(true, 4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text(HeroMainStatsViewText.sizeEditCancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(HeroMainStatsViewText.sizeEditSaveLabel),
              ),
            ],
          );
        },
      );

      // Ensure dialog is fully dismissed before persisting
      if (result != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _persistModification(HeroModKeys.size, result.toString());
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    }
  }

  // Delegates to extracted insight generators
  List<String> _wealthInsights(int wealth) => generateWealthInsights(wealth);

  List<String> _renownInsights(int renown) => generateRenownInsights(renown);

  // Delegates to extracted helper
  int _recoveryHealAmount(HeroMainStats stats) =>
      calculateRecoveryHealAmount(stats);

  Future<void> _handleUseRecovery(HeroMainStats stats) async {
    if (!mounted) return;
    if (stats.recoveriesCurrent <= 0) {
      _showSnack(HeroMainStatsViewText.noRecoveriesRemainingMessage);
      return;
    }
    final healAmount = _recoveryHealAmount(stats);
    if (healAmount <= 0) {
      _showSnack(HeroMainStatsViewText.cannotSpendRecoveryMessage);
      return;
    }
    final newRecoveries = stats.recoveriesCurrent - 1;
    final maxStamina = stats.staminaMaxEffective;
    final newStamina = math.min(
      stats.staminaCurrent + healAmount,
      maxStamina,
    );
    try {
      await ref.read(heroRepositoryProvider).updateVitals(
            widget.heroId,
            recoveriesCurrent: newRecoveries,
            staminaCurrent: newStamina,
          );
    } catch (err) {
      if (!mounted) return;
      _showSnack('${HeroMainStatsViewText.spendRecoveryErrorPrefix}$err');
    }
  }

  Future<void> _handleDealDamage(HeroMainStats stats) async {
    final amount = await _promptForAmount(
      title: HeroMainStatsViewText.applyDamageTitle,
      description: HeroMainStatsViewText.applyDamageDescription,
    );
    if (amount == null || amount <= 0) return;
    if (!mounted) return;

    var temp = stats.staminaTemp;
    var current = stats.staminaCurrent;

    if (amount <= temp) {
      temp -= amount;
    } else {
      final remaining = amount - temp;
      temp = 0;
      current -= remaining;
    }

    try {
      await ref.read(heroRepositoryProvider).updateVitals(
            widget.heroId,
            staminaTemp: temp,
            staminaCurrent: current,
          );
    } catch (err) {
      if (!mounted) return;
      _showSnack('${HeroMainStatsViewText.applyDamageErrorPrefix}$err');
    }
  }

  Future<void> _handleApplyHealing(HeroMainStats stats) async {
    final result = await _promptForHealingAmount(
      title: HeroMainStatsViewText.applyHealingTitle,
      description: HeroMainStatsViewText.applyHealingDescription,
    );
    if (result == null || result.amount <= 0) return;
    if (!mounted) return;

    try {
      if (result.applyToTemp) {
        // Temp stamina: replace the value (not add to it)
        await ref.read(heroRepositoryProvider).updateVitals(
              widget.heroId,
              staminaTemp: result.amount,
            );
      } else {
        // Regular stamina: add to current (capped at max)
        final maxStamina = stats.staminaMaxEffective;
        final newCurrent = math.min(
          stats.staminaCurrent + result.amount,
          maxStamina,
        );
        await ref.read(heroRepositoryProvider).updateVitals(
              widget.heroId,
              staminaCurrent: newCurrent,
            );
      }
    } catch (err) {
      if (!mounted) return;
      _showSnack('${HeroMainStatsViewText.applyHealingErrorPrefix}$err');
    }
  }

  Future<({int amount, bool applyToTemp})?> _promptForHealingAmount({
    required String title,
    String? description,
  }) async {
    if (!mounted) return null;

    final controller = TextEditingController(text: '1');

    try {
      final result = await showDialog<({int amount, bool applyToTemp})>(
        context: context,
        builder: (dialogContext) {
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
                    color: Colors.green.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.healing,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _formatters(false, 3),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.promptAmountLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade400),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  HeroMainStatsViewText.promptCancelLabel,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                ),
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    Navigator.of(dialogContext).pop();
                  } else {
                    Navigator.of(dialogContext).pop(
                      (amount: value, applyToTemp: true),
                    );
                  }
                },
                child: const Text(HeroMainStatsViewText.promptApplyTempLabel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    Navigator.of(dialogContext).pop();
                  } else {
                    Navigator.of(dialogContext).pop(
                      (amount: value, applyToTemp: false),
                    );
                  }
                },
                child: const Text(HeroMainStatsViewText.promptApplyLabel),
              ),
            ],
          );
        },
      );

      // Wait for dialog animation to complete before returning result
      if (result != null) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return result;
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.dispose();
    }
  }

  Future<int?> _promptForAmount({
    required String title,
    String? description,
  }) async {
    if (!mounted) return null;

    final controller = TextEditingController(text: '1');

    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
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
                    color: Colors.red.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _formatters(false, 3),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: HeroMainStatsViewText.promptAmountLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  HeroMainStatsViewText.promptCancelLabel,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    Navigator.of(dialogContext).pop();
                  } else {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: const Text(HeroMainStatsViewText.promptApplyLabel),
              ),
            ],
          );
        },
      );

      // Wait for dialog animation to complete before returning result
      if (result != null) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return result;
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.dispose();
    }
  }

  List<TextInputFormatter> _formatters(bool allowNegative, int maxLength) {
    return [
      allowNegative
          ? FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))
          : FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  void _showSnack(String message) {
    // Intentionally no-op: hero sheet should not show snack notifications.
    // (Errors are still logged/handled via other UI patterns.)
    return;
  }

  // Delegates to extracted helper
  String _formatSigned(int value) => formatSigned(value);

  /// Maps HeroModKeys to ancestry stat names for looking up sources.
  String? _modKeyToAncestryStatName(String modKey) {
    return switch (modKey) {
      HeroModKeys.might => 'might',
      HeroModKeys.agility => 'agility',
      HeroModKeys.reason => 'reason',
      HeroModKeys.intuition => 'intuition',
      HeroModKeys.presence => 'presence',
      HeroModKeys.size => 'size',
      HeroModKeys.speed => 'speed',
      HeroModKeys.disengage => 'disengage',
      HeroModKeys.stability => 'stability',
      HeroModKeys.staminaMax => 'stamina',
      HeroModKeys.recoveriesMax => 'recoveries',
      HeroModKeys.surges => 'surges',
      HeroModKeys.wealth => 'wealth',
      HeroModKeys.renown => 'renown',
      _ => null,
    };
  }

  /// Gets the source description for a given modification key.
  String _getModSourceDescription(
    String modKey,
    HeroStatModifications ancestryMods, {
    bool includeEquipment = true,
  }) {
    final statName = _modKeyToAncestryStatName(modKey);
    final parts = <String>[];
    if (statName != null) {
      final ancestryDesc = ancestryMods.getSourcesDescription(statName);
      if (ancestryDesc.isNotEmpty) {
        parts.add(ancestryDesc);
      }
    }
    if (includeEquipment) {
      final equipmentBonus = _latestStats?.equipmentBonusFor(modKey) ?? 0;
      if (equipmentBonus != 0) {
        parts.add(
          '${_formatSigned(equipmentBonus)}${HeroMainStatsViewText.modSourceEquipmentSuffix}',
        );
      }
    }
    return parts.join('; ');
  }

  /// Shows the wealth edit dialog with coin purse
  Future<void> _showWealthEditDialog(
    BuildContext context, {
    required int baseValue,
    required int currentModValue,
    required List<String> insights,
  }) async {
    if (!mounted) return;

    final repo = ref.read(heroRepositoryProvider);
    final coinPurseJson = await repo.getCoinPurse(widget.heroId);
    final coinPurse = CoinPurse.fromJson(coinPurseJson);

    final sourcesDesc = _getModSourceDescription(
      HeroModKeys.wealth,
      _ancestryMods,
      includeEquipment: false,
    );

    final result = await showWealthEditDialog(
      context,
      baseValue: baseValue,
      currentModValue: currentModValue,
      coinPurse: coinPurse,
      insights: insights,
      sourcesDescription: sourcesDesc,
    );

    if (result != null && mounted) {
      final (modValue, newPurse) = result;
      await repo.saveCoinPurse(widget.heroId, newPurse.toJson());
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _persistModification(HeroModKeys.wealth, modValue.toString());
      });
    }
  }

  /// Builds a widget showing the modification value.
  Widget _buildModValueWithSources({
    required int modValue,
    required String modKey,
    required HeroStatModifications ancestryMods,
    required ThemeData theme,
  }) {
    if (modValue == 0) return const SizedBox.shrink();

    return Text(
      _formatSigned(modValue),
      style: theme.textTheme.labelSmall?.copyWith(
        color: modValue > 0 ? Colors.green : Colors.red,
      ),
    );
  }
}

// Internal type aliases for backward compatibility with private types
// The actual classes are now in hero_main_stats_models.dart
typedef _StatTileData = StatTileData;

/// Stateful content widget for the XP edit dialog.
///
/// This widget manages its own state for the XP speed selector,
/// allowing the insights to update dynamically when the speed changes.
class _XpEditDialogContent extends StatefulWidget {
  const _XpEditDialogContent({
    required this.controller,
    required this.currentLevel,
    required this.currentXp,
    required this.initialSpeed,
    required this.formatters,
    required this.onSpeedChanged,
  });

  final TextEditingController controller;
  final int currentLevel;
  final int currentXp;
  final XpSpeed initialSpeed;
  final List<TextInputFormatter> formatters;
  final void Function(XpSpeed speed) onSpeedChanged;

  @override
  State<_XpEditDialogContent> createState() => _XpEditDialogContentState();
}

class _XpEditDialogContentState extends State<_XpEditDialogContent> {
  late XpSpeed _selectedSpeed;
  late int _displayXp;

  @override
  void initState() {
    super.initState();
    _selectedSpeed = widget.initialSpeed;
    _displayXp = int.tryParse(widget.controller.text) ?? widget.currentXp;
    widget.controller.addListener(_onXpChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onXpChanged);
    super.dispose();
  }

  void _onXpChanged() {
    final text = widget.controller.text;
    final newXp = text.isEmpty ? 0 : (int.tryParse(text) ?? 0);
    // Always update to ensure UI refreshes
    setState(() {
      _displayXp = newXp;
    });
  }

  void _onSpeedChanged(XpSpeed speed) {
    setState(() {
      _selectedSpeed = speed;
    });
    widget.onSpeedChanged(speed);
  }

  @override
  Widget build(BuildContext context) {
    final insights =
        generateXpInsights(_displayXp, widget.currentLevel, _selectedSpeed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${HeroMainStatsViewText.xpEditCurrentLevelPrefix}${widget.currentLevel}',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        const SizedBox(height: 12),
        // XP Speed selector
        Row(
          children: [
            Text(
              HeroMainStatsViewText.xpEditSpeedLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            const Spacer(),
            _buildSpeedButton(XpSpeed.doubleSpeed),
            const SizedBox(width: 4),
            _buildSpeedButton(XpSpeed.normal),
            const SizedBox(width: 4),
            _buildSpeedButton(XpSpeed.halfSpeed),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: HeroMainStatsViewText.xpEditExperienceLabel,
            labelStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.amber.shade400),
            ),
          ),
          inputFormatters: widget.formatters,
        ),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_graph,
                      size: 16,
                      color: Colors.amber.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      HeroMainStatsViewText.xpEditInsightsTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        insight,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpeedButton(XpSpeed speed) {
    final isSelected = _selectedSpeed == speed;
    return InkWell(
      onTap: () => _onSpeedChanged(speed),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withAlpha(60) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade600,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          speed.shortLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.amber : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
