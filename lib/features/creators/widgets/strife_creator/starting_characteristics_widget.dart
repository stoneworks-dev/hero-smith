import 'package:flutter/material.dart';

import '../../../../core/controllers/starting_characteristics_controller.dart';
import '../../../../core/models/class_data.dart';
import '../../../../core/models/characteristics_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/starting_characteristics_widget_text.dart';

// Helper classes for picker
class _SearchOption {
  final String value;
  final String label;
  final CharacteristicArray? arrayData;

  const _SearchOption({
    required this.value,
    required this.label,
    this.arrayData,
  });
}

class _PickerSelection {
  final String? value;
  final String? label;
  final CharacteristicArray? arrayData;

  const _PickerSelection({
    this.value,
    this.label,
    this.arrayData,
  });
}

class StartingCharacteristicsWidget extends StatefulWidget {
  const StartingCharacteristicsWidget({
    super.key,
    required this.classData,
    required this.selectedLevel,
    this.selectedArray,
    required this.assignedCharacteristics,
    this.initialLevelChoiceSelections,
    required this.onArrayChanged,
    required this.onAssignmentsChanged,
    this.onFinalTotalsChanged,
    this.onLevelChoiceSelectionsChanged,
  });

  final ClassData classData;
  final int selectedLevel;
  final CharacteristicArray? selectedArray;
  final Map<String, int> assignedCharacteristics;
  final Map<String, String?>? initialLevelChoiceSelections;
  final ValueChanged<CharacteristicArray?> onArrayChanged;
  final ValueChanged<Map<String, int>> onAssignmentsChanged;
  final ValueChanged<Map<String, int>>? onFinalTotalsChanged;
  final ValueChanged<Map<String, String?>>? onLevelChoiceSelectionsChanged;

  @override
  State<StartingCharacteristicsWidget> createState() =>
      _StartingCharacteristicsWidgetState();
}

class _StartingCharacteristicsWidgetState
    extends State<StartingCharacteristicsWidget> {
  static const _accent = CreatorTheme.characteristicsAccent;
  late StartingCharacteristicsController _controller;
  Map<String, int> _lastAssignments = const {};
  Map<String, int> _lastTotals = const {};
  Map<String, String?> _lastLevelChoiceSelections = const {};
  int _assignmentsCallbackVersion = 0;
  int _totalsCallbackVersion = 0;
  int _levelChoiceSelectionsCallbackVersion = 0;

  @override
  void initState() {
    super.initState();
    _controller = StartingCharacteristicsController(
      classData: widget.classData,
      selectedLevel: widget.selectedLevel,
      selectedArray: widget.selectedArray,
      initialAssignments: widget.assignedCharacteristics,
      initialLevelChoiceSelections: widget.initialLevelChoiceSelections,
    );
    _lastAssignments = Map<String, int>.from(
      _controller.assignedCharacteristics,
    );
    _lastLevelChoiceSelections = Map<String, String?>.from(
      _controller.levelChoiceSelections,
    );
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyParent();
    });
  }

  @override
  void didUpdateWidget(covariant StartingCharacteristicsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classData.classId != widget.classData.classId) {
      _controller.updateClass(widget.classData);
    }

    if (oldWidget.selectedLevel != widget.selectedLevel) {
      _controller.updateLevel(widget.selectedLevel);
    }

    if (oldWidget.selectedArray != widget.selectedArray) {
      _controller.updateArray(widget.selectedArray);
    }

    if (!CharacteristicUtils.intMapEquality.equals(
      oldWidget.assignedCharacteristics,
      widget.assignedCharacteristics,
    )) {
      _controller.updateExternalAssignments(widget.assignedCharacteristics);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _notifyParent();
  }

  void _notifyParent() {
    final assignments = _controller.assignedCharacteristics;
    if (!CharacteristicUtils.intMapEquality.equals(
      _lastAssignments,
      assignments,
    )) {
      final snapshot = Map<String, int>.from(assignments);
      _lastAssignments = snapshot;
      _assignmentsCallbackVersion += 1;
      final version = _assignmentsCallbackVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || version != _assignmentsCallbackVersion) return;
        widget.onAssignmentsChanged(Map<String, int>.from(snapshot));
      });
    }

    if (widget.onFinalTotalsChanged != null) {
      final totals = _controller.summary.totals;
      if (!CharacteristicUtils.intMapEquality.equals(_lastTotals, totals)) {
        final snapshot = Map<String, int>.from(totals);
        _lastTotals = snapshot;
        _totalsCallbackVersion += 1;
        final version = _totalsCallbackVersion;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || version != _totalsCallbackVersion) return;
          widget.onFinalTotalsChanged?.call(Map<String, int>.from(snapshot));
        });
      }
    }

    // Notify parent of level choice selection changes
    if (widget.onLevelChoiceSelectionsChanged != null) {
      final levelSelections = _controller.levelChoiceSelections;
      if (!_levelChoiceSelectionsEqual(_lastLevelChoiceSelections, levelSelections)) {
        final snapshot = Map<String, String?>.from(levelSelections);
        _lastLevelChoiceSelections = snapshot;
        _levelChoiceSelectionsCallbackVersion += 1;
        final version = _levelChoiceSelectionsCallbackVersion;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || version != _levelChoiceSelectionsCallbackVersion) return;
          widget.onLevelChoiceSelectionsChanged?.call(Map<String, String?>.from(snapshot));
        });
      }
    }
  }

  bool _levelChoiceSelectionsEqual(Map<String, String?> a, Map<String, String?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  String _displayName(String key) => CharacteristicUtils.displayName(key);

  String _formatSigned(int value) => CharacteristicUtils.formatSigned(value);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    final summary = _controller.summary;
    final potencyValues = _controller.computePotency();
    final assignments = _controller.assignments;
    final levelChoices = _controller.levelChoices;
    final levelSelections = _controller.levelChoiceSelections;
    final selectedArray = _controller.selectedArray;

    final assignmentsComplete = selectedArray == null ||
        assignments.values.every((token) => token != null);
    final choicesComplete = levelChoices.isEmpty ||
        levelChoices.every(
          (choice) => (levelSelections[choice.id] ?? '').isNotEmpty,
        );

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: StartingCharacteristicsWidgetText.title,
            subtitle: StartingCharacteristicsWidgetText.sectionSubtitle,
            icon: Icons.bar_chart,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Array picker first (if arrays exist)
                if (_controller.classData.startingCharacteristics
                    .startingCharacteristicsArrays.isNotEmpty) ...[
                  _buildArrayPicker(),
                  const SizedBox(height: 16),
                ],
                
                // Characteristics display
                _buildCharacteristicsGrid(summary),
                
                // Assignment status warning
                _buildAssignmentStatus(assignmentsComplete, choicesComplete),
                
                // Available values to drag (only if array selected)
                if (selectedArray != null) ...[
                  const SizedBox(height: 16),
                  _buildAvailableTokensSection(),
                ],
                
                // Potency section
                const SizedBox(height: 16),
                _buildPotencySection(potencyValues),
                
                // Level choices (if any)
                if (_controller.levelChoices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildLevelChoicesSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicsGrid(CharacteristicSummary summary) {
    const desiredOrder = ['might', 'agility', 'reason', 'intuition', 'presence'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < desiredOrder.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == desiredOrder.length - 1 ? 0 : 4),
                child: _buildCharacteristicCard(desiredOrder[i], summary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicCard(String stat, CharacteristicSummary summary) {
    final color = AppColors.getCharacteristicColor(stat);
    final isLocked = _controller.lockedStats.contains(stat);
    final total = summary.totals[stat] ?? 0;
    final assignedToken = _controller.assignments[stat];
    final isPending = _controller.selectedArray != null && assignedToken == null && !isLocked;

    if (isLocked) {
      return _buildLockedCharacteristicCard(stat, total, color);
    }

    return DragTarget<CharacteristicValueToken>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          _controller.assignToken(stat, details.data),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPending 
                  ? Colors.orangeAccent 
                  : isActive 
                      ? color 
                      : color.withOpacity(0.4),
              width: isPending || isActive ? 2 : 1,
            ),
            color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.08),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stat name
              Text(
                _displayName(stat),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Total value
              Text(
                total.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Assigned token or drop zone
              if (assignedToken != null)
                _buildAssignedTokenChip(assignedToken, color)
              else
                _buildDropZone(color, isActive: isActive),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedCharacteristicCard(String stat, int total, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        color: color.withOpacity(0.12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 8, color: color),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  _displayName(stat),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Fixed',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(Color color, {bool isActive = false}) {
    final hasArray = _controller.selectedArray != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? color : color.withOpacity(0.5),
          width: isActive ? 1.5 : 1,
          style: hasArray ? BorderStyle.solid : BorderStyle.none,
        ),
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
      ),
      child: Text(
        hasArray ? 'Drop' : '?',
        style: TextStyle(
          color: hasArray ? Colors.white70 : Colors.grey.shade600,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildArrayPicker() {
    final arrays = _controller
        .classData.startingCharacteristics.startingCharacteristicsArrays;
    if (arrays.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          color: Colors.grey.withOpacity(0.12),
        ),
        child: Text(
          StartingCharacteristicsWidgetText.allFixedMessage,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      );
    }

    final currentPreview = _controller.selectedArray != null
        ? _controller.selectedArray!.values.map(_formatSigned).join(' / ')
        : null;

    return InkWell(
      onTap: () => _showArrayPickerDialog(arrays),
      borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: StartingCharacteristicsWidgetText.arrayLabel,
          labelStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
            borderSide: BorderSide(color: _accent),
          ),
          filled: true,
          fillColor: FormTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentPreview ?? StartingCharacteristicsWidgetText.arrayPlaceholder,
              style: TextStyle(
                color: currentPreview != null
                    ? Colors.white
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showArrayPickerDialog(List<CharacteristicArray> arrays) async {
    final options = [
      const _SearchOption(
        value: '',
        label: StartingCharacteristicsWidgetText.arrayPlaceholder,
        arrayData: null,
      ),
      ...arrays.map((array) {
        final preview = array.values.map(_formatSigned).join(' / ');
        return _SearchOption(
          value: preview,
          label: preview,
          arrayData: array,
        );
      }),
    ];

    final currentValue = _controller.selectedArray != null
        ? _controller.selectedArray!.values.map(_formatSigned).join(' / ')
        : '';

    final result = await showDialog<_PickerSelection>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: NavigationTheme.cardBackgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accent.withValues(alpha: 0.2),
                        _accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: _accent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _accent.withValues(alpha: 0.2),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          StartingCharacteristicsWidgetText.selectArrayTitle,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Options list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == currentValue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(
                                context,
                                _PickerSelection(
                                  value: option.value,
                                  label: option.label,
                                  arrayData: option.arrayData,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _accent.withValues(alpha: 0.15)
                                    : FormTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? _accent.withValues(alpha: 0.5)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? _accent
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: _accent,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Cancel button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      StartingCharacteristicsWidgetText.cancelButton,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      _controller.updateArray(result.arrayData);
      widget.onArrayChanged(result.arrayData);
    }
  }

  Widget _buildTokenVisual(
    CharacteristicValueToken token,
    Color color, {
    bool filled = false,
    bool isFeedback = false,
    bool expanded = false,
  }) {
    final background = filled ? color : color.withOpacity(0.18);
    final borderColor = color.withOpacity(filled ? 0.9 : 0.45);
    final textColor = filled ? AppColors.textPrimary : color;

    final content = Text(
      _formatSigned(token.value),
      style: TextStyle(
        fontSize: expanded ? 16 : 11,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      textAlign: TextAlign.center,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(expanded ? 8 : 6),
        color: background,
        border: Border.all(color: borderColor, width: expanded ? 2 : 1),
        boxShadow: isFeedback
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 16 : 8,
        vertical: expanded ? 14 : 4,
      ),
      child: expanded ? Center(child: content) : content,
    );
  }

  Widget _buildDraggableTokenChip(CharacteristicValueToken token) {
    final color = AppColors.secondary;
    final chip = _buildTokenVisual(token, color, expanded: true);
    final feedbackWidget = _buildTokenVisual(token, color, filled: true, isFeedback: true);

    // Fixed chip dimensions: width = 60, height = 60
    const estimatedWidth = 60.0;
    const estimatedHeight = 60.0;

    return Draggable<CharacteristicValueToken>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: feedbackWidget,
      ),
      feedbackOffset: Offset(-estimatedWidth / 2, -estimatedHeight / 2),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: chip,
      ),
      child: chip,
    );
  }

  Widget _buildAssignedTokenChip(
    CharacteristicValueToken token,
    Color color,
  ) {
    final chip = _buildTokenVisual(token, color, filled: true);
    final feedbackWidget = _buildTokenVisual(token, color, filled: true, isFeedback: true);

    // Smaller chip dimensions: horizontal padding = 8*2 = 16, vertical padding = 4*2 = 8
    // Text width is roughly 25-30px for typical values, so total ~45px wide, ~25px tall
    const estimatedWidth = 45.0;
    const estimatedHeight = 25.0;

    return Draggable<CharacteristicValueToken>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: feedbackWidget,
      ),
      feedbackOffset: Offset(-estimatedWidth / 2, -estimatedHeight / 2),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: chip,
      ),
      child: chip,
    );
  }

  Widget _buildAssignmentStatus(
      bool assignmentsComplete, bool choicesComplete) {
    if (assignmentsComplete && choicesComplete) {
      return const SizedBox.shrink();
    }
    final parts = <String>[];
    if (!assignmentsComplete) {
      parts.add(StartingCharacteristicsWidgetText.assignmentMissingArray);
    }
    if (!choicesComplete) {
      parts.add(StartingCharacteristicsWidgetText.assignmentMissingChoices);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(StartingCharacteristicsWidgetText.assignmentStatusSeparator),
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTokensSection() {
    final available = _controller.unassignedTokens;
    final accent = AppColors.secondary;
    return DragTarget<CharacteristicValueToken>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _controller.clearToken(details.data),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        final background = accent.withOpacity(isActive ? 0.18 : 0.1);
        final border = accent.withOpacity(isActive ? 0.6 : 0.4);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            color: background,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StartingCharacteristicsWidgetText.availableValuesTitle,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (available.isEmpty)
                Text(
                  isActive
                      ? StartingCharacteristicsWidgetText.releaseToClearValue
                      : StartingCharacteristicsWidgetText.allValuesAssigned,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                )
              else ...[
                Text(
                  StartingCharacteristicsWidgetText.holdAndDragToAssign,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < available.length; i++) ...[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: _buildDraggableTokenChip(available[i]),
                        ),
                      ),
                      if (i < available.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
              if (isActive) ...[
                const SizedBox(height: 8),
                Text(
                  StartingCharacteristicsWidgetText.releaseToClearSlot,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPotencySection(Map<String, int> potencyValues) {
    final progression =
        _controller.classData.startingCharacteristics.potencyProgression;
    final baseKey =
        CharacteristicUtils.normalizeKey(progression.characteristic) ??
            progression.characteristic;
    final baseName = _displayName(baseKey);
    const order = ['strong', 'average', 'weak'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        color: AppColors.accent.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${StartingCharacteristicsWidgetText.potencyTitlePrefix}$baseName${StartingCharacteristicsWidgetText.potencyTitleSuffix}',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: order.map((strength) {
              final value = potencyValues[strength] ?? 0;
              final label = strength[0].toUpperCase() + strength.substring(1);
              final color = AppColors.getPotencyColor(strength);
              return _buildPotencyChip(label, value, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPotencyChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.7)),
        color: color.withOpacity(0.2),
      ),
      child: Text(
        '$label ${_formatSigned(value)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLevelChoicesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withOpacity(0.4)),
        color: _accent.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StartingCharacteristicsWidgetText.levelBonusesTitle,
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ..._controller.levelChoices.map(_buildLevelChoiceDropdown),
        ],
      ),
    );
  }

  Widget _buildLevelChoiceDropdown(LevelChoice choice) {
    final current = _controller.levelChoiceSelections[choice.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        value: current,
        dropdownColor: FormTheme.surface,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText:
              '${StartingCharacteristicsWidgetText.levelBonusLabelPrefix}${choice.level}${StartingCharacteristicsWidgetText.levelBonusLabelSuffix}',
          labelStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CreatorTheme.inputBorderRadius),
            borderSide: BorderSide(color: _accent),
          ),
          filled: true,
          fillColor: FormTheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child:
                Text(StartingCharacteristicsWidgetText.selectCharacteristicPlaceholder),
          ),
          ...CharacteristicUtils.characteristicOrder.map((stat) {
            final label = _displayName(stat);
            return DropdownMenuItem<String?>(
              value: stat,
              child: Text(label),
            );
          }),
        ],
        onChanged: (value) => _controller.selectLevelChoice(choice.id, value),
      ),
    );
  }
}

