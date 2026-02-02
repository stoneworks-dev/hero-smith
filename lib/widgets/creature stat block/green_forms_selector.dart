import 'package:flutter/material.dart';

import '../../core/services/green_forms_service.dart';
import '../../core/theme/creature_theme.dart';
import 'creature_stat_block.dart';
import 'green_animal_form.dart';

/// A widget that displays and allows selection of Green Elementalist animal forms.
/// 
/// Features:
/// - Expandable card showing current form or "True Form" when no form is selected
/// - Level-based filtering: available forms are selectable, higher-level forms are grayed out
/// - Persists selection through callback
/// - Option to revert to "True Form"
class GreenFormsSelector extends StatefulWidget {
  const GreenFormsSelector({
    super.key,
    required this.heroLevel,
    this.selectedFormId,
    required this.onFormSelected,
    this.accentColor,
    this.enabled = true,
  });

  /// Current hero level (determines which forms are available)
  final int heroLevel;

  /// ID of the currently selected form (null = True Form)
  final String? selectedFormId;

  /// Callback when a form is selected or deselected
  final ValueChanged<String?> onFormSelected;

  /// Accent color for the widget
  final Color? accentColor;

  /// Whether the widget is interactive
  final bool enabled;

  @override
  State<GreenFormsSelector> createState() => _GreenFormsSelectorState();
}

class _GreenFormsSelectorState extends State<GreenFormsSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  bool _isLoading = true;
  
  List<GreenAnimalForm> _allForms = [];
  GreenAnimalForm? _selectedForm;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadForms();
  }

  @override
  void didUpdateWidget(GreenFormsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFormId != widget.selectedFormId ||
        oldWidget.heroLevel != widget.heroLevel) {
      _loadForms();
    }
  }

  Future<void> _loadForms() async {
    setState(() => _isLoading = true);
    
    try {
      final forms = await GreenFormsService.instance.loadAllForms();
      GreenAnimalForm? selected;
      
      if (widget.selectedFormId != null) {
        selected = await GreenFormsService.instance.getFormById(widget.selectedFormId!);
      }
      
      if (mounted) {
        setState(() {
          _allForms = forms;
          _selectedForm = selected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleExpanded() {
    if (!widget.enabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectForm(GreenAnimalForm? form) {
    widget.onFormSelected(form?.id);
    setState(() {
      _selectedForm = form;
      _isExpanded = false;
    });
    _animationController.reverse();
  }

  /// Use a softer, less saturated green that's easier on the eyes
  Color get _accentColor =>
      widget.accentColor ?? CreatureTheme.greenFormAccent;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _accentColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - Always visible, shows current form name + revert button
          _buildHeader(theme),
          
          // Current form stats (compact when collapsed)
          if (!_isExpanded) _buildCurrentFormDisplay(theme),
          
          // Expandable form list
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildFormsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.08),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.pets,
              color: _accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedForm == null ? 'True Form' : _selectedForm!.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Always-visible revert button when in animal form
            if (_selectedForm != null && widget.enabled)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _selectForm(null),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Revert',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.enabled)
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFormDisplay(ThemeData theme) {
    if (_selectedForm == null) {
      // Compact True Form indicator
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'You are in your natural form',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Show compact stat block for selected form
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: CreatureStatBlock.fromGreenForm(
        _selectedForm!,
        accentColor: _accentColor,
        isCompact: true,
      ),
    );
  }

  Widget _buildFormsList(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            
            // Revert to True Form option
            _buildTrueFormOption(theme),
            
            const SizedBox(height: 8),
            
            // Available forms section
            _buildSectionHeader(theme, 'Available Forms'),
            const SizedBox(height: 8),
            ..._buildAvailableForms(theme),
            
            // Locked forms section (if any)
            if (_getLockedForms().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(theme, 'Locked Forms (Higher Level Required)'),
              const SizedBox(height: 8),
              ..._buildLockedForms(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrueFormOption(ThemeData theme) {
    final isSelected = _selectedForm == null;
    
    return InkWell(
      onTap: () => _selectForm(null),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Revert to True Form',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  List<GreenAnimalForm> _getAvailableForms() {
    return _allForms.where((f) => f.level <= widget.heroLevel).toList();
  }

  List<GreenAnimalForm> _getLockedForms() {
    return _allForms.where((f) => f.level > widget.heroLevel).toList();
  }

  List<Widget> _buildAvailableForms(ThemeData theme) {
    final available = _getAvailableForms();
    
    if (available.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No forms available at your current level',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return available.map((form) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _FormListItem(
        form: form,
        isSelected: _selectedForm?.id == form.id,
        isLocked: false,
        accentColor: _accentColor,
        onTap: () => _selectForm(form),
      ),
    )).toList();
  }

  List<Widget> _buildLockedForms(ThemeData theme) {
    final locked = _getLockedForms();

    return locked.map((form) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _FormListItem(
        form: form,
        isSelected: false,
        isLocked: true,
        accentColor: _accentColor,
        onTap: null,
      ),
    )).toList();
  }
}

/// A list item widget for displaying a single form option.
class _FormListItem extends StatelessWidget {
  const _FormListItem({
    required this.form,
    required this.isSelected,
    required this.isLocked,
    required this.accentColor,
    this.onTap,
  });

  final GreenAnimalForm form;
  final bool isSelected;
  final bool isLocked;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLocked ? Colors.grey : accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? color.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outlineVariant.withOpacity(isLocked ? 0.3 : 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Form icon and level
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLocked ? Icons.lock : Icons.pets,
                      size: 20,
                      color: color,
                    ),
                    Text(
                      'L${form.level}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Form details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLocked
                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip(theme, 'Size ${form.size}', color),
                        _buildMiniChip(theme, 'Speed ${form.baseSpeed}', color),
                        if (form.temporaryStamina > 0)
                          _buildMiniChip(theme, 'THP ${form.temporaryStamina}', color),
                        if (form.stabilityBonus > 0)
                          _buildMiniChip(theme, 'Stab +${form.stabilityBonus}', color),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Icon(Icons.check_circle, color: color)
              else if (isLocked)
                Icon(Icons.lock, color: Colors.grey.withOpacity(0.5))
              else
                Icon(Icons.circle_outlined, color: color.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
