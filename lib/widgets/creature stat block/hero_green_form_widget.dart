import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/services/green_forms_service.dart';
import '../../../core/theme/creature_theme.dart';
import 'green_forms_selector.dart';

/// Key used to store the selected green form ID in HeroValues
const String kGreenFormSelectedKey = 'elementalist.green_form_selected';

/// Multiple hero value keys can represent the same concept depending on where
/// the hero was edited (Strife creator vs. the newer Basics tabs). Support both
/// so the auto widget works regardless of the workflow the user followed.
const Set<String> _classKeys = {'strife.class', 'basics.className'};
const Set<String> _subclassKeys = {'strife.subclass', 'basics.subclass'};
const Set<String> _levelKeys = {'strife.level', 'basics.level'};

bool _isGreenElementalistClass(String? classId, String? subclassName) {
  final classNormalized = classId?.toLowerCase().trim() ?? '';
  final subclassNormalized = subclassName?.toLowerCase().trim() ?? '';
  if (classNormalized.isEmpty || subclassNormalized.isEmpty) {
    return false;
  }
  final isElementalist = classNormalized.contains('elementalist');
  final isGreen = subclassNormalized.contains('green');
  return isElementalist && isGreen;
}

/// A widget that displays the Green Elementalist animal form selector.
/// 
/// This widget:
/// - Checks if the hero is a Green Elementalist
/// - Shows the GreenFormsSelector if they are
/// - Persists the selected form to HeroValues
/// - Loads the previously selected form on init
class HeroGreenFormWidget extends ConsumerStatefulWidget {
  const HeroGreenFormWidget({
    super.key,
    required this.heroId,
    required this.heroLevel,
    required this.classId,
    required this.subclassName,
  });

  final String heroId;
  final int heroLevel;
  final String? classId;
  final String? subclassName;

  @override
  ConsumerState<HeroGreenFormWidget> createState() => _HeroGreenFormWidgetState();
}

class _HeroGreenFormWidgetState extends ConsumerState<HeroGreenFormWidget> {
  String? _selectedFormId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedForm();
  }

  @override
  void didUpdateWidget(HeroGreenFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroId != widget.heroId) {
      _loadSelectedForm();
    }
  }

  /// Check if this hero is a Green Elementalist
  bool get _isGreenElementalist {
    return _isGreenElementalistClass(widget.classId, widget.subclassName);
  }

  /// Check if the hero has reached level 2 (when Disciple of the Green is available)
  bool get _hasGreenFormAccess {
    return widget.heroLevel >= 2;
  }

  Future<void> _loadSelectedForm() async {
    if (!_isGreenElementalist || !_hasGreenFormAccess) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final db = ref.read(appDatabaseProvider);
      final values = await db.getHeroValues(widget.heroId);
      
      String? formId;
      for (final value in values) {
        if (value.key == kGreenFormSelectedKey) {
          formId = value.textValue;
          break;
        }
      }
      
      if (mounted) {
        setState(() {
          _selectedFormId = formId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onFormSelected(String? formId) async {
    setState(() => _selectedFormId = formId);
    
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertHeroValue(
        heroId: widget.heroId,
        key: kGreenFormSelectedKey,
        textValue: formId,
      );
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save form selection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if not a Green Elementalist or level too low
    if (!_isGreenElementalist) {
      return const SizedBox.shrink();
    }

    if (!_hasGreenFormAccess) {
      return _buildLockedMessage(context);
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return GreenFormsSelector(
      heroLevel: widget.heroLevel,
      selectedFormId: _selectedFormId,
      onFormSelected: _onFormSelected,
      accentColor: CreatureTheme.greenFormAccent, // Softer green for readability
    );
  }

  Widget _buildLockedMessage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Animal Forms',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Available at level 2 (Disciple of the Green)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
}

/// A provider to load the hero's subclass name
final heroSubclassProvider = FutureProvider.family<String?, String>((ref, heroId) async {
  final db = ref.watch(appDatabaseProvider);
  final values = await db.getHeroValues(heroId);
  
  for (final value in values) {
    if (_subclassKeys.contains(value.key)) {
      return value.textValue;
    }
  }
  return null;
});

/// A simpler auto-detecting version that loads its own data
class AutoHeroGreenFormWidget extends ConsumerStatefulWidget {
  const AutoHeroGreenFormWidget({
    super.key,
    required this.heroId,
    this.sectionTitle,
    this.sectionSpacing = 0,
    this.sectionTopSpacing = 0,
  });

  final String heroId;

  /// Optional section title to render above the selector. When null, only the
  /// raw selector (or locked message) is rendered.
  final String? sectionTitle;

  /// Extra spacing to add below the rendered section (only when shown).
  final double sectionSpacing;

  /// Extra spacing to add before the section header (only when shown).
  final double sectionTopSpacing;

  @override
  ConsumerState<AutoHeroGreenFormWidget> createState() => _AutoHeroGreenFormWidgetState();
}

class _AutoHeroGreenFormWidgetState extends ConsumerState<AutoHeroGreenFormWidget> 
    with AutomaticKeepAliveClientMixin {
  int _heroLevel = 1;
  String? _selectedFormId;
  bool _isLoading = true;
  bool _isGreenElementalist = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the service
    GreenFormsService.instance.loadAllForms();
    _loadHeroData();
  }

  @override
  void didUpdateWidget(AutoHeroGreenFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroId != widget.heroId) {
      _loadHeroData();
    }
  }

  Future<void> _loadHeroData() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(heroRepositoryProvider);
      final hero = await repo.load(widget.heroId);

      String? classId = hero?.className?.trim();
      String? subclass = hero?.subclass?.trim();
      final int? repoLevel = hero?.level;
      int level = repoLevel != null && repoLevel > 0 ? repoLevel : 1;
      final bool hasReliableLevel = repoLevel != null && repoLevel > 0;
      String? formId;

      final db = ref.read(appDatabaseProvider);
      final values = await db.getHeroValues(widget.heroId);
      for (final value in values) {
        if (_classKeys.contains(value.key) && (classId == null || classId.isEmpty)) {
          classId = value.textValue?.trim();
          continue;
        }
        if (_subclassKeys.contains(value.key) && (subclass == null || subclass.isEmpty)) {
          subclass = value.textValue?.trim();
          continue;
        }
        if (_levelKeys.contains(value.key) && !hasReliableLevel) {
          level = value.value ?? int.tryParse(value.textValue ?? '') ?? level;
          continue;
        }
        if (value.key == kGreenFormSelectedKey) {
          formId = value.textValue;
        }
      }
      
      // Check if this is a Green Elementalist
      final isGreenElementalist = _isGreenElementalistClass(classId, subclass);
      
      if (mounted) {
        setState(() {
          _heroLevel = level;
          _selectedFormId = formId;
          _isGreenElementalist = isGreenElementalist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onFormSelected(String? formId) async {
    setState(() => _selectedFormId = formId);
    
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertHeroValue(
        heroId: widget.heroId,
        key: kGreenFormSelectedKey,
        textValue: formId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save form selection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final content = _buildContent(context);
    if (content == null) {
      return const SizedBox.shrink();
    }
    return _wrapInSection(context, content);
  }

  Widget? _buildContent(BuildContext context) {
    if (_isLoading) {
      return widget.sectionTitle == null ? null : _buildLoadingCard(context);
    }

    if (!_isGreenElementalist) {
      return null;
    }

    if (_heroLevel < 2) {
      return _buildLockedMessage(context);
    }

    return GreenFormsSelector(
      heroLevel: _heroLevel,
      selectedFormId: _selectedFormId,
      onFormSelected: _onFormSelected,
      accentColor: CreatureTheme.greenFormAccent,
    );
  }

  Widget _wrapInSection(BuildContext context, Widget content) {
    if (widget.sectionTitle == null) {
      return content;
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.sectionTopSpacing > 0)
          SizedBox(height: widget.sectionTopSpacing),
        Text(
          widget.sectionTitle!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        content,
        if (widget.sectionSpacing > 0)
          SizedBox(height: widget.sectionSpacing),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading animal forms...',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedMessage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Animal Forms',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Available at level 2 (Disciple of the Green)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
}
