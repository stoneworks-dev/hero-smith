import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/dice_roller_provider.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icon_data.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';

// ─── SVG icon asset paths ───────────────────────────────────────────────────

const _kIconD3 = 'assets/icons/delapouite/perspective-dice-two.svg';
const _kIconD6 = 'assets/icons/delapouite/perspective-dice-six.svg';
const _kIconD10 = 'assets/icons/skoll/d10.svg';
const _kIcon2D10 = 'assets/icons/delapouite/dice-twenty-faces-twenty.svg';
const _kIconD100 = 'assets/icons/lorc/cubes.svg';

// ─── Overlay FAB + persistent panel ─────────────────────────────────────────

const _kMaxTabs = 10;

class DiceRollerOverlay extends ConsumerStatefulWidget {
  const DiceRollerOverlay({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<DiceRollerOverlay> createState() => _DiceRollerOverlayState();
}

class _DiceRollerOverlayState extends ConsumerState<DiceRollerOverlay> {
  // FAB position state — starts lower-left.
  double _dx = 0;
  double _dy = double.infinity; // sentinel: "not yet laid out"

  // Panel open/close.
  bool _panelOpen = false;

  // Persistent tab state (survives panel close/open).
  final List<_TabData> _tabs = [_TabData()];
  int _activeIndex = 0;

  _TabData get _active => _tabs[_activeIndex];

  void _onFabTap() {
    setState(() {
      if (!_panelOpen) {
        // First tap — open the panel.
        _panelOpen = true;
      } else if (_tabs.length < _kMaxTabs) {
        // Already open — add a new tab.
        _tabs.add(_TabData());
        _activeIndex = _tabs.length - 1;
      }
    });
  }

  void _closePanel() => setState(() => _panelOpen = false);

  void _addTab() {
    if (_tabs.length >= _kMaxTabs) return;
    setState(() {
      _tabs.add(_TabData());
      _activeIndex = _tabs.length - 1;
    });
  }

  void _removeTab(int index) {
    if (_tabs.length <= 1) return;
    setState(() {
      _tabs.removeAt(index);
      if (_activeIndex >= _tabs.length) {
        _activeIndex = _tabs.length - 1;
      } else if (_activeIndex > index) {
        _activeIndex--;
      }
    });
  }

  void _selectTab(int index) => setState(() => _activeIndex = index);

  void _onTabDataChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final showRoller =
        ref.watch(diceRollerPreferencesProvider).valueOrNull ?? true;
    if (!showRoller) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        const fabW = 52.0;
        const fabH = 48.0;
        final maxX = max(0.0, constraints.maxWidth - fabW);
        final maxY = max(0.0, constraints.maxHeight - fabH);

        // First layout: park on the lower-left.
        if (_dy == double.infinity) _dy = max(0.0, maxY - 80);

        // Clamp so it never goes off screen.
        _dx = _dx.clamp(0.0, maxX);
        _dy = _dy.clamp(0.0, maxY);

        // Determine which edge the FAB is closest to for border-radius.
        final onLeft = _dx < (maxX / 2);

        final borderRadius = onLeft
            ? const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              );

        // FAB icon matches the active tab's dice mode.
        final fabIcon = _active.rollMode.icon;

        return Stack(
          children: [
            widget.child,

            // ── Scrim (when panel open) ──
            if (_panelOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePanel,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),

            // ── Persistent bottom panel ──
            if (_panelOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _DiceRollerPanel(
                  tabs: _tabs,
                  activeIndex: _activeIndex,
                  canAddTab: _tabs.length < _kMaxTabs,
                  onAddTab: _addTab,
                  onRemoveTab: _removeTab,
                  onSelectTab: _selectTab,
                  onClose: _closePanel,
                  onChanged: _onTabDataChanged,
                ),
              ),

            // ── Draggable FAB ──
            Positioned(
              left: _dx,
              top: _dy,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _dx += d.delta.dx;
                    _dy += d.delta.dy;
                  });
                },
                onPanEnd: (_) {
                  // Snap to nearest horizontal edge.
                  setState(() {
                    _dx = _dx < (maxX / 2) ? 0.0 : maxX;
                  });
                },
                child: Material(
                  elevation: 8,
                  shadowColor:
                      NavigationTheme.strifeColor.withValues(alpha: 0.3),
                  color: NavigationTheme.cardBackgroundDark,
                  borderRadius: borderRadius,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: _onFabTap,
                    child: Padding(
                      padding: onLeft
                          ? const EdgeInsets.fromLTRB(12, 12, 16, 12)
                          : const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: AppIcon(
                        SvgAppIcon(fabIcon),
                        size: 24,
                        color: NavigationTheme.strifeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Enums ──────────────────────────────────────────────────────────────────

enum _DoubleMode { flat, tierShift }

enum _RollMode {
  d3(label: 'd3', sides: 3, icon: _kIconD3),
  d6(label: 'd6', sides: 6, icon: _kIconD6),
  d10(label: 'd10', sides: 10, icon: _kIconD10),
  twoD10(label: '2d10', sides: 10, icon: _kIcon2D10),
  d100(label: 'd100', sides: 100, icon: _kIconD100);

  const _RollMode({
    required this.label,
    required this.sides,
    required this.icon,
  });
  final String label;
  final int sides;
  final String icon;

  bool get supportsQuantity => this != twoD10;
}

// ─── Edge / Bane resolution (Draw Steel rules) ─────────────────────────────

class _ResolvedEdgeBane {
  const _ResolvedEdgeBane({
    required this.modifier,
    required this.tierShift,
    required this.label,
  });
  final int modifier;
  final int tierShift;
  final String label;
}

/// Resolves edges vs banes using Draw Steel cancellation rules:
///  • 1 edge + 1 bane → cancel (normal roll)
///  • 2 edges + 2 banes → cancel (normal roll)
///  • 2 edges + 1 bane → net 1 edge (+2)
///  • 2 banes + 1 edge → net 1 bane (−2)
///  • 2 net edges → double edge (+4 or tier +1 depending on mode)
///  • 2 net banes → double bane (−4 or tier −1 depending on mode)
_ResolvedEdgeBane _resolveEdgeBane(
  int edges,
  int banes,
  _DoubleMode doubleMode,
) {
  final netEdges = max(0, edges - banes);
  final netBanes = max(0, banes - edges);

  if (netEdges == 0 && netBanes == 0) {
    final cancelled = edges > 0 || banes > 0;
    return _ResolvedEdgeBane(
      modifier: 0,
      tierShift: 0,
      label: cancelled ? 'Cancelled' : 'None',
    );
  }

  if (netEdges == 1) {
    return const _ResolvedEdgeBane(
        modifier: 2, tierShift: 0, label: 'Edge (+2)');
  }
  if (netBanes == 1) {
    return const _ResolvedEdgeBane(
        modifier: -2, tierShift: 0, label: 'Bane (−2)');
  }

  if (netEdges >= 2) {
    return doubleMode == _DoubleMode.flat
        ? const _ResolvedEdgeBane(
            modifier: 4, tierShift: 0, label: 'Double Edge (+4)')
        : const _ResolvedEdgeBane(
            modifier: 0, tierShift: 1, label: 'Double Edge (Tier +1)');
  }

  // netBanes >= 2
  return doubleMode == _DoubleMode.flat
      ? const _ResolvedEdgeBane(
          modifier: -4, tierShift: 0, label: 'Double Bane (−4)')
      : const _ResolvedEdgeBane(
          modifier: 0, tierShift: -1, label: 'Double Bane (Tier −1)');
}

// ─── Roll result ────────────────────────────────────────────────────────────

class _RollResult {
  const _RollResult({
    required this.mode,
    required this.quantity,
    required this.diceValues,
    required this.baseTotal,
    required this.edgeBaneModifier,
    required this.quickModifier,
    required this.adjustedTotal,
    required this.tierShift,
    this.landedTier,
    this.finalTier,
    this.isCritical = false,
  });

  final _RollMode mode;
  final int quantity;
  final List<int> diceValues;
  final int baseTotal;
  final int edgeBaneModifier;
  final int quickModifier;
  final int adjustedTotal;
  final int tierShift;
  final int? landedTier;
  final int? finalTier;
  final bool isCritical;
}

// ─── Per-tab state ──────────────────────────────────────────────────────────

class _TabData {
  _RollMode rollMode = _RollMode.twoD10;
  int edgeCount = 0;
  int baneCount = 0;
  _DoubleMode doubleMode = _DoubleMode.tierShift;
  int quickModifier = 0;
  int quantity = 1;
  _RollResult? lastRoll;
}

// ─── Dice Roller Panel (persistent, managed by overlay) ─────────────────────

class _DiceRollerPanel extends StatefulWidget {
  const _DiceRollerPanel({
    required this.tabs,
    required this.activeIndex,
    required this.canAddTab,
    required this.onAddTab,
    required this.onRemoveTab,
    required this.onSelectTab,
    required this.onClose,
    required this.onChanged,
  });

  final List<_TabData> tabs;
  final int activeIndex;
  final bool canAddTab;
  final VoidCallback onAddTab;
  final ValueChanged<int> onRemoveTab;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onClose;
  final VoidCallback onChanged;

  @override
  State<_DiceRollerPanel> createState() => _DiceRollerPanelState();
}

class _DiceRollerPanelState extends State<_DiceRollerPanel> {
  final _rng = Random();

  _TabData get _active => widget.tabs[widget.activeIndex];

  _RollMode get _rollMode => _active.rollMode;
  set _rollMode(_RollMode v) => _active.rollMode = v;
  int get _edgeCount => _active.edgeCount;
  set _edgeCount(int v) => _active.edgeCount = v;
  int get _baneCount => _active.baneCount;
  set _baneCount(int v) => _active.baneCount = v;
  _DoubleMode get _doubleMode => _active.doubleMode;
  set _doubleMode(_DoubleMode v) => _active.doubleMode = v;
  int get _quickModifier => _active.quickModifier;
  set _quickModifier(int v) => _active.quickModifier = v;
  int get _quantity => _active.quantity;
  set _quantity(int v) => _active.quantity = v;
  _RollResult? get _lastRoll => _active.lastRoll;
  set _lastRoll(_RollResult? v) => _active.lastRoll = v;

  bool get _supportsTiers => _rollMode == _RollMode.twoD10;

  void _notifyChanged() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = _resolveEdgeBane(_edgeCount, _baneCount, _doubleMode);
    final netIsDouble = (max(0, _edgeCount - _baneCount) >= 2) ||
        (max(0, _baneCount - _edgeCount) >= 2);

    return Material(
      color: NavigationTheme.navBarBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      elevation: 16,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag handle ──
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FormTheme.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Title row ──
                  Row(
                    children: [
                      const SizedBox(width: 36), // balance close button
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              const SvgAppIcon(
                                  'assets/icons/lorc/crossed-axes.svg'),
                              size: 18,
                              color: NavigationTheme.strifeColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'DICE ROLLER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.5,
                                color: NavigationTheme.strifeColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AppIcon(
                              const SvgAppIcon(
                                  'assets/icons/lorc/crossed-axes.svg'),
                              size: 18,
                              color: NavigationTheme.strifeColor,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: FormTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: NavigationTheme.accentStripeGradient(
                          NavigationTheme.strifeColor,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Tab bar ──
                  _buildTabBar(theme),
                  const SizedBox(height: 12),

              // ── Dice Selection ──
              _sectionLabel(theme, 'Dice'),
              const SizedBox(height: 8),
              _buildDiceSelector(theme),
              const SizedBox(height: 16),

              // ── Quantity (non-2d10 only) ──
              if (_rollMode.supportsQuantity) ...[
                _sectionLabel(theme, 'Quantity'),
                const SizedBox(height: 8),
                _buildQuantitySelector(theme),
                const SizedBox(height: 16),
              ],

              // ── Edge / Bane (2d10 only) ──
              if (_supportsTiers) ...[
                Row(
                  children: [
                    Expanded(child: _sectionLabel(theme, 'Edge / Bane')),
                    if (netIsDouble) _buildDoubleModeToggle(theme),
                  ],
                ),
                const SizedBox(height: 8),
                _buildEdgeBaneCounters(theme, resolved),
                const SizedBox(height: 16),
              ],

              // ── Bonus / Penalty ──
              _sectionLabel(theme, 'Bonus / Penalty'),
              const SizedBox(height: 8),
              _buildQuickModifierPad(theme),
              const SizedBox(height: 24),

              // ── Roll Button ──
              _buildRollButton(theme),
              const SizedBox(height: 24),

              // ── Result (always visible — prevents layout shift) ──
              _buildResultArea(theme),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: FormTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar(ThemeData theme) {
    const accent = NavigationTheme.strifeColor;
    final tabs = widget.tabs;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (int i = 0; i < tabs.length; i++)
          () {
            final selected = i == widget.activeIndex;
            final tab = tabs[i];
            final label = tab.lastRoll != null
                ? '${tab.rollMode.label} = ${tab.lastRoll!.adjustedTotal}'
                : tab.rollMode.label;
            return GestureDetector(
              onTap: () => widget.onSelectTab(i),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.15)
                      : NavigationTheme.cardBackgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: 0.6)
                        : FormTheme.borderDim,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      SvgAppIcon(tab.rollMode.icon),
                      size: 14,
                      color: selected ? accent : FormTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? accent : FormTheme.textSecondary,
                      ),
                    ),
                    if (tabs.length > 1) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => widget.onRemoveTab(i),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: selected
                              ? accent.withValues(alpha: 0.7)
                              : FormTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }(),
        if (widget.canAddTab)
          GestureDetector(
            onTap: widget.onAddTab,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(Icons.add, size: 18, color: accent),
            ),
          ),
      ],
    );
  }

  // ── Dice selector (icon cards) ────────────────────────────────────────────

  Widget _buildDiceSelector(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: Row(
        children: _RollMode.values
            .map((mode) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _diceCard(theme, mode),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _diceCard(ThemeData theme, _RollMode mode) {
    final selected = _rollMode == mode;
    const accent = NavigationTheme.strifeColor;

    return Material(
      color: selected
          ? accent.withValues(alpha: 0.15)
          : NavigationTheme.cardBackgroundDark,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _rollMode = mode;
          if (!mode.supportsQuantity) _quantity = 1;
          _notifyChanged();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.6)
                  : FormTheme.borderDim,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                SvgAppIcon(mode.icon),
                size: 28,
                color: selected ? accent : FormTheme.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                mode.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? accent : FormTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quantity selector ─────────────────────────────────────────────────────

  Widget _buildQuantitySelector(ThemeData theme) {
    return Row(
      children: [
        _styledIconButton(
          Icons.remove,
          onTap: _quantity > 1 ? () { _quantity--; _notifyChanged(); } : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FormTheme.borderDim),
            ),
            child: Text(
              '$_quantity${_rollMode.label}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: FormTheme.textBright,
              ),
            ),
          ),
        ),
        if (_quantity > 1)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () { _quantity = 1; _notifyChanged(); },
              child: const Icon(
                Icons.refresh,
                size: 20,
                color: FormTheme.textMuted,
              ),
            ),
          ),
        const SizedBox(width: 12),
        _styledIconButton(
          Icons.add,
          onTap: _quantity < 99 ? () { _quantity++; _notifyChanged(); } : null,
        ),
      ],
    );
  }

  // ── Edge / Bane counters ──────────────────────────────────────────────────

  Widget _buildEdgeBaneCounters(ThemeData theme, _ResolvedEdgeBane resolved) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _counterRow(
                theme,
                label: 'Edges',
                value: _edgeCount,
                color: NavigationTheme.heroesColor,
                onChanged: (v) { _edgeCount = v.clamp(0, 2); _notifyChanged(); },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _counterRow(
                theme,
                label: 'Banes',
                value: _baneCount,
                color: theme.colorScheme.error,
                onChanged: (v) { _baneCount = v.clamp(0, 2); _notifyChanged(); },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Resolved net effect
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: FormTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FormTheme.borderDim),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                resolved.modifier > 0
                    ? Icons.arrow_upward
                    : resolved.modifier < 0
                        ? Icons.arrow_downward
                        : resolved.tierShift != 0
                            ? (resolved.tierShift > 0
                                ? Icons.keyboard_double_arrow_up
                                : Icons.keyboard_double_arrow_down)
                            : Icons.horizontal_rule,
                size: 16,
                color: FormTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Net: ${resolved.label}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FormTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counterRow(
    ThemeData theme, {
    required String label,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: value > 0
            ? color.withValues(alpha: 0.1)
            : NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value > 0
              ? color.withValues(alpha: 0.4)
              : FormTheme.borderDim,
          width: value > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => onChanged(value - 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child:
                  Icon(Icons.remove_circle_outline, size: 22, color: color),
            ),
          ),
          Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: value > 0 ? color : FormTheme.textMuted,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: FormTheme.textMuted,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => onChanged(value + 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add_circle_outline, size: 22, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Double mode toggle ────────────────────────────────────────────────────

  Widget _buildDoubleModeToggle(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        _doubleMode = _doubleMode == _DoubleMode.flat
            ? _DoubleMode.tierShift
            : _DoubleMode.flat;
        _notifyChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: NavigationTheme.strifeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: NavigationTheme.strifeColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _doubleMode == _DoubleMode.flat ? 'Flat ±4' : 'Tier ±1',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FormTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz,
                size: 14, color: NavigationTheme.strifeColor),
          ],
        ),
      ),
    );
  }

  // ── Quick modifier pad ────────────────────────────────────────────────────

  Widget _buildQuickModifierPad(ThemeData theme) {
    const accent = NavigationTheme.strifeColor;
    return Row(
      children: [
        _styledIconButton(
          Icons.remove,
          onTap: () { _quickModifier--; _notifyChanged(); },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _quickModifier != 0
                    ? accent.withValues(alpha: 0.6)
                    : FormTheme.borderDim,
                width: _quickModifier != 0 ? 1.5 : 1,
              ),
            ),
            child: Text(
              _signed(_quickModifier),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _quickModifier != 0 ? accent : FormTheme.textMuted,
              ),
            ),
          ),
        ),
        if (_quickModifier != 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () { _quickModifier = 0; _notifyChanged(); },
              child: const Icon(Icons.refresh, size: 20, color: FormTheme.textMuted),
            ),
          ),
        const SizedBox(width: 8),
        _styledIconButton(
          Icons.add,
          onTap: () { _quickModifier++; _notifyChanged(); },
        ),
      ],
    );
  }

  // ── Roll button ───────────────────────────────────────────────────────────

  Widget _buildRollButton(ThemeData theme) {
    final rollLabel = _rollMode.supportsQuantity && _quantity > 1
        ? '$_quantity${_rollMode.label}'
        : _rollMode.label;
    const accent = NavigationTheme.strifeColor;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _roll,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                const SvgAppIcon(_kIcon2D10),
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'ROLL $rollLabel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Result area (always visible — prevents layout shift) ──────────────────

  Widget _buildResultArea(ThemeData theme) {
    final roll = _lastRoll;
    if (roll == null) {
      // Placeholder when no roll has been made yet
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: NavigationTheme.cardBackgroundDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FormTheme.borderDim),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              const SvgAppIcon(_kIcon2D10),
              size: 32,
              color: FormTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Roll the dice!',
              style: TextStyle(
                fontSize: 14,
                color: FormTheme.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return _buildResultCard(theme, roll);
  }

  Widget _buildResultCard(ThemeData theme, _RollResult roll) {
    final supportsTiers = roll.mode == _RollMode.twoD10;

    Color? statusColor;
    if (roll.isCritical) {
      statusColor = Colors.amber.shade700;
    } else if (supportsTiers && roll.finalTier != null) {
      statusColor = _tierColor(theme, roll.finalTier!);
    }

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor?.withValues(alpha: 0.6) ?? FormTheme.borderDim,
          width: statusColor != null ? 1.5 : 1,
        ),
        boxShadow: statusColor != null
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Critical banner
          if (roll.isCritical) ...[                        
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✦ CRITICAL ✦',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Dice values
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: roll.diceValues
                .map((d) => Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        color: FormTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FormTheme.borderDim),
                      ),
                      child: Text(
                        '$d',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: FormTheme.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Big total
          Text(
            '${roll.adjustedTotal}',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: statusColor ?? FormTheme.textBright,
            ),
          ),

          // Breakdown
          Text(
            _buildBreakdownString(roll),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: FormTheme.textMuted,
            ),
          ),

          // Tier visual (2d10 only)
          if (supportsTiers && roll.finalTier != null) ...[            
            const SizedBox(height: 20),
            _buildTierVisual(theme, roll),
          ],
        ],
      ),
    );
  }

  String _buildBreakdownString(_RollResult roll) {
    final parts = <String>[];
    parts.add('${roll.baseTotal} (dice)');
    if (roll.edgeBaneModifier != 0) {
      parts.add('${_signed(roll.edgeBaneModifier)} (E/B)');
    }
    if (roll.quickModifier != 0) {
      parts.add('${_signed(roll.quickModifier)} (bonus)');
    }
    if (parts.length == 1) return 'Natural result';
    return parts.join('  ');
  }

  Widget _buildTierVisual(ThemeData theme, _RollResult roll) {
    final tierColors = [
      theme.colorScheme.error,
      const Color(0xFF4CAF50),
      Colors.amber.shade700,
    ];
    final tierNames = ['Tier 1: ≤ 11', 'Tier 2: 12–16', 'Tier 3: 17+'];

    return Column(
      children: [
        if (roll.tierShift != 0 && roll.landedTier != roll.finalTier)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  roll.tierShift > 0
                      ? Icons.keyboard_double_arrow_up
                      : Icons.keyboard_double_arrow_down,
                  size: 16,
                  color: FormTheme.textSecondary,
                ),
                Text(
                  ' Shifted from T${roll.landedTier} → T${roll.finalTier}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FormTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else if (roll.tierShift != 0 && roll.landedTier == roll.finalTier)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Already at T${roll.finalTier} — shift had no effect',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FormTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Row(
          children: List.generate(3, (i) {
            final tier = i + 1;
            final isFinal = roll.finalTier == tier;
            return Expanded(
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isFinal
                      ? tierColors[i]
                      : tierColors[i].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: isFinal
                    ? Text('T$tier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ))
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          roll.isCritical
              ? 'CRITICAL! (Natural ${roll.baseTotal})'
              : tierNames[roll.finalTier! - 1],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: roll.isCritical
                ? Colors.amber.shade700
                : tierColors[roll.finalTier! - 1],
          ),
        ),
      ],
    );
  }

  // ── Styled helpers ──────────────────────────────────────────────────────

  Widget _styledIconButton(IconData icon, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Material(
      color: NavigationTheme.cardBackgroundDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FormTheme.borderDim),
          ),
          child: Icon(
            icon,
            color: enabled
                ? NavigationTheme.strifeColor
                : FormTheme.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }

  Color _tierColor(ThemeData theme, int tier) {
    switch (tier) {
      case 1:
        return theme.colorScheme.error;
      case 2:
        return const Color(0xFF4CAF50);
      case 3:
        return Colors.amber.shade700;
      default:
        return FormTheme.textBright;
    }
  }

  // ── Roll logic ────────────────────────────────────────────────────────────

  void _roll() {
    final mode = _rollMode;
    final qty = mode.supportsQuantity ? _quantity : 1;

    // Roll dice
    final List<int> diceValues;
    if (mode == _RollMode.twoD10) {
      diceValues = [_rng.nextInt(10) + 1, _rng.nextInt(10) + 1];
    } else {
      diceValues = List.generate(qty, (_) => _rng.nextInt(mode.sides) + 1);
    }

    final baseTotal = diceValues.fold<int>(0, (a, b) => a + b);

    // Edge/Bane resolution (only affects 2d10 mechanics)
    final resolved = _supportsTiers
        ? _resolveEdgeBane(_edgeCount, _baneCount, _doubleMode)
        : const _ResolvedEdgeBane(
            modifier: 0, tierShift: 0, label: 'None');

    final adjustedTotal = baseTotal + resolved.modifier + _quickModifier;

    // Tier & critical logic (2d10 only)
    int? landedTier;
    int? finalTier;
    bool isCritical = false;

    if (mode == _RollMode.twoD10) {
      // Natural 19 or 20 is an automatic crit (always Tier 3)
      isCritical = baseTotal >= 19;

      if (isCritical) {
        landedTier = 3;
        finalTier = 3;
      } else {
        landedTier = _tierFromTotal(adjustedTotal);
        finalTier = (landedTier + resolved.tierShift).clamp(1, 3);
      }
    }

    setState(() {
      _lastRoll = _RollResult(
        mode: mode,
        quantity: qty,
        diceValues: diceValues,
        baseTotal: baseTotal,
        edgeBaneModifier: resolved.modifier,
        quickModifier: _quickModifier,
        adjustedTotal: adjustedTotal,
        tierShift: resolved.tierShift,
        landedTier: landedTier,
        finalTier: finalTier,
        isCritical: isCritical,
      );
    });
    widget.onChanged();
  }

  static int _tierFromTotal(int total) {
    if (total <= 11) return 1;
    if (total <= 16) return 2;
    return 3;
  }

  static String _signed(int v) => v > 0 ? '+$v' : '$v';
}
