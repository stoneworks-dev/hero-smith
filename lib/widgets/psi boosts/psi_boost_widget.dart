import 'package:flutter/material.dart';

import '../../core/services/psi_boost_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/heroic_resource_theme.dart';

/// A compact widget that displays available Psi Boosts based on current heroic resource.
///
/// Only shows boosts the hero can afford with their current resource value,
/// with expandable section for higher-cost boosts not yet affordable.
class PsiBoostWidget extends StatefulWidget {
  const PsiBoostWidget({
    super.key,
    required this.currentResource,
    this.resourceName = 'Psi',
    this.onSpendResource,
  });

  /// The current heroic resource value.
  final int currentResource;

  /// The name of the resource (for display purposes).
  final String resourceName;

  /// Callback when a boost is activated - passes the cost to spend.
  final void Function(int cost, String boostName)? onSpendResource;

  @override
  State<PsiBoostWidget> createState() => _PsiBoostWidgetState();
}

class _PsiBoostWidgetState extends State<PsiBoostWidget> {
  final PsiBoostService _service = PsiBoostService();

  bool _isLoading = true;
  bool _isExpanded = false;
  PsiBoostData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.loadPsiBoostData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int get currentResource => widget.currentResource;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_error != null || _data == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final resourceColor = AppColors.psionicKeywordColor;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? HeroicResourceTheme.surface : Colors.white;
    final panel = isDark ? HeroicResourceTheme.panel : Colors.grey.shade50;

    // Split boosts into affordable and unaffordable
    final affordableBoosts = <PsiBoost>[];
    final unaffordableBoosts = <PsiBoost>[];

    for (final boost in _data!.boosts) {
      if (boost.cost <= currentResource) {
        affordableBoosts.add(boost);
      } else {
        unaffordableBoosts.add(boost);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resourceColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark, resourceColor),
            const SizedBox(height: 8),
            // Show affordable boosts
            if (affordableBoosts.isNotEmpty)
              ...affordableBoosts.map((boost) => _PsiBoostItem(
                    boost: boost,
                    isAffordable: true,
                    resourceColor: resourceColor,
                    isDark: isDark,
                    panel: panel,
                    onTap: widget.onSpendResource != null
                        ? () => widget.onSpendResource!(boost.cost, boost.name)
                        : null,
                  )),
            // Expandable section for unaffordable boosts
            if (unaffordableBoosts.isNotEmpty) ...[
              _buildExpandToggle(
                  isDark, resourceColor, unaffordableBoosts.length),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeOutCubic,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: unaffordableBoosts
                      .map((boost) => _PsiBoostItem(
                            boost: boost,
                            isAffordable: false,
                            resourceColor: resourceColor,
                            isDark: isDark,
                            panel: panel,
                          ))
                      .toList(),
                ),
              ),
            ],
            // Show message when no boosts are affordable
            if (affordableBoosts.isEmpty &&
                unaffordableBoosts.isNotEmpty &&
                !_isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Need at least 1 ${widget.resourceName} to use Psi Boosts',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color resourceColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: resourceColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.psychology_alt_rounded,
            color: resourceColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Psi Boosts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: resourceColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: resourceColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${_data!.boosts.where((b) => b.cost <= currentResource).length}/${_data!.boosts.length}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: resourceColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandToggle(bool isDark, Color resourceColor, int hiddenCount) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded
                  ? 'Hide'
                  : 'Show $hiddenCount more boost${hiddenCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PsiBoostItem extends StatelessWidget {
  const _PsiBoostItem({
    required this.boost,
    required this.isAffordable,
    required this.resourceColor,
    required this.isDark,
    required this.panel,
    this.onTap,
  });

  final PsiBoost boost;
  final bool isAffordable;
  final Color resourceColor;
  final bool isDark;
  final Color panel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isClickable = isAffordable && onTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClickable ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          splashColor: isClickable ? resourceColor.withOpacity(0.2) : null,
          highlightColor: isClickable ? resourceColor.withOpacity(0.1) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAffordable
                  ? resourceColor.withOpacity(isDark ? 0.12 : 0.08)
                          : panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAffordable
                    ? resourceColor.withOpacity(0.4)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: isAffordable ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCostBadge(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boost.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAffordable
                              ? (isDark ? Colors.white : Colors.grey.shade900)
                              : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        boost.effect,
                        style: TextStyle(
                          fontSize: 10,
                          color: isAffordable
                              ? (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700)
                              : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade500),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClickable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: resourceColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isAffordable
            ? resourceColor
            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isAffordable
            ? [
                BoxShadow(
                  color: resourceColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          boost.cost.toString(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isAffordable
                ? Colors.white
                : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}
