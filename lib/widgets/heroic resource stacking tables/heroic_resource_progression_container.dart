import 'package:flutter/material.dart';

import '../../core/models/heroic_resource_progression.dart';
import '../../core/theme/heroic_resource_theme.dart';
import '../../core/services/heroic_resource_progression_service.dart';
import '../../core/theme/app_colors.dart';
import 'heroic_resource_gauge.dart';

/// A smart container widget that automatically determines and displays
/// the appropriate heroic resource progression table based on class,
/// subclass, and kit selection.
///
/// This widget handles the complex logic for:
/// - Fury class: Berserker/Reaver use subclass progression, Stormwight uses kit-based progression
/// - Null class: Uses subclass-based discipline mastery
/// - Other classes: Shows nothing (not applicable)
class HeroicResourceProgressionContainer extends StatefulWidget {
  const HeroicResourceProgressionContainer({
    super.key,
    required this.className,
    required this.subclassName,
    this.kitId,
    this.currentResource = 0,
    required this.heroLevel,
    this.showCompact = false,
    this.onProgressionLoaded,
  });

  /// The hero's class name (e.g., "Fury", "Null")
  final String? className;

  /// The hero's subclass name (e.g., "Berserker", "Stormwight", "Chronokinetic")
  final String? subclassName;

  /// The selected kit ID (required for Stormwight subclass)
  final String? kitId;

  /// Current heroic resource value
  final int currentResource;

  /// Hero's current level
  final int heroLevel;

  /// Whether to display in compact mode
  final bool showCompact;

  /// Callback when a progression is successfully loaded
  final ValueChanged<HeroicResourceProgression?>? onProgressionLoaded;

  @override
  State<HeroicResourceProgressionContainer> createState() =>
      _HeroicResourceProgressionContainerState();
}

class _HeroicResourceProgressionContainerState
    extends State<HeroicResourceProgressionContainer> {
  final HeroicResourceProgressionService _service =
      HeroicResourceProgressionService();

  HeroicResourceProgression? _progression;
  bool _isLoading = true;
  bool _isInitialLoad = true; // Track first load vs subsequent updates
  String? _error;
  bool _awaitingKitSelection = false;

  // Cache the last loaded config to avoid redundant loads
  String? _lastClassName;
  String? _lastSubclassName;
  String? _lastKitId;

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  @override
  void didUpdateWidget(covariant HeroicResourceProgressionContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reload if class/subclass/kit changed (not currentResource or heroLevel)
    final configChanged = oldWidget.className != widget.className ||
        oldWidget.subclassName != widget.subclassName ||
        oldWidget.kitId != widget.kitId;
        
    if (configChanged) {
      _loadProgression();
    }
  }

  Future<void> _loadProgression() async {
    if (!mounted) return;

    // Skip reload if config hasn't actually changed
    if (_lastClassName == widget.className &&
        _lastSubclassName == widget.subclassName &&
        _lastKitId == widget.kitId &&
        _progression != null) {
      return;
    }

    // Only show loading indicator on initial load, not on config changes
    // to avoid jarring visual updates
    if (_isInitialLoad) {
      setState(() {
        _isLoading = true;
        _error = null;
        _awaitingKitSelection = false;
      });
    } else {
      // For subsequent loads, update silently
      _error = null;
      _awaitingKitSelection = false;
    }

    try {
      // Check if this class even uses progression tables
      if (!_service.classUsesProgressionTable(widget.className)) {
        if (mounted) {
          setState(() {
            _progression = null;
            _isLoading = false;
            _isInitialLoad = false;
            _lastClassName = widget.className;
            _lastSubclassName = widget.subclassName;
            _lastKitId = widget.kitId;
          });
          widget.onProgressionLoaded?.call(null);
        }
        return;
      }

      // For Fury with Stormwight subclass, we need a kit selection
      final isFury = widget.className?.trim().toLowerCase() == 'fury';
      final isStormwight = _service.isStormwightSubclass(widget.subclassName);

      if (isFury && isStormwight && (widget.kitId == null || widget.kitId!.isEmpty)) {
        if (mounted) {
          setState(() {
            _awaitingKitSelection = true;
            _progression = null;
            _isLoading = false;
            _isInitialLoad = false;
            _lastClassName = widget.className;
            _lastSubclassName = widget.subclassName;
            _lastKitId = widget.kitId;
          });
          widget.onProgressionLoaded?.call(null);
        }
        return;
      }

      // Load the appropriate progression
      final progression = await _service.getProgression(
        className: widget.className,
        subclassName: widget.subclassName,
        kitId: widget.kitId,
      );

      if (mounted) {
        setState(() {
          _progression = progression;
          _isLoading = false;
          _isInitialLoad = false;
          // Update cache
          _lastClassName = widget.className;
          _lastSubclassName = widget.subclassName;
          _lastKitId = widget.kitId;
        });
        widget.onProgressionLoaded?.call(progression);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load progression: $e';
          _isLoading = false;
          _isInitialLoad = false;
        });
        widget.onProgressionLoaded?.call(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if this class doesn't use progression tables
    if (!_service.classUsesProgressionTable(widget.className)) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_awaitingKitSelection) {
      return _buildAwaitingKitState();
    }

    if (_progression == null) {
      return _buildNoProgressionState();
    }

    return HeroicResourceGauge(
      progression: _progression!,
      currentResource: widget.currentResource,
      heroLevel: widget.heroLevel,
      showCompact: widget.showCompact,
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resourceColor = _getResourceColor();

    return Container(
      padding: EdgeInsets.all(widget.showCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? HeroicResourceTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resourceColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(resourceColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading progression...',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(widget.showCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? HeroicResourceTheme.alertSurface : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'An error occurred',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadProgression,
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.red.shade400,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingKitState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resourceColor = AppColors.ferocityColor;

    return Container(
      padding: EdgeInsets.all(widget.showCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? HeroicResourceTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resourceColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resourceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pets_rounded,
              color: resourceColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stormwight Progression',
            style: TextStyle(
              fontSize: widget.showCompact ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a Stormwight kit to view your Growing Ferocity progression',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.showCompact ? 11 : 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: resourceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: resourceColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: resourceColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Choose kit below',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: resourceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProgressionState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resourceColor = _getResourceColor();

    return Container(
      padding: EdgeInsets.all(widget.showCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? HeroicResourceTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: resourceColor.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select a subclass to view your ${_getResourceName()} progression',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResourceColor() {
    final resourceType = _service.getResourceType(widget.className);
    switch (resourceType) {
      case HeroicResourceType.ferocity:
        return AppColors.ferocityColor;
      case HeroicResourceType.discipline:
        return AppColors.disciplineColor;
      default:
        return AppColors.primary;
    }
  }

  String _getResourceName() {
    final resourceType = _service.getResourceType(widget.className);
    return resourceType?.displayName ?? 'resource';
  }
}
