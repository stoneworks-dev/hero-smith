part of 'class_features_widget.dart';

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({super.key, required this.feature, required this.widget});

  final Feature feature;
  final ClassFeaturesWidget widget;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true;

  Feature get feature => widget.feature;
  ClassFeaturesWidget get w => widget.widget;

  String get _storageKey => 'feature_card_expanded_${feature.id}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final bucket = PageStorage.of(context);
      final stored = bucket.readState(context, identifier: _storageKey);
      if (stored is bool) {
        _isExpanded = stored;
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      PageStorage.of(context).writeState(context, _isExpanded, identifier: _storageKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = w.featureDetailsById[feature.id];
    final grantType = _resolveGrantType();
    
    // Check if this feature has options that require a user choice
    final hasOptionsRequiringChoice = _hasOptionsRequiringChoice(details);
    final featureStyle = _FeatureStyle.fromGrantType(
      grantType,
      feature.isSubclassFeature,
      hasOptionsRequiringChoice: hasOptionsRequiringChoice,
    );
    
    // Check if this is a progression feature (Growing Ferocity / Discipline Mastery)
    if (w._isProgressionFeature(feature)) {
      return _buildProgressionFeatureCard(context, theme, scheme, featureStyle);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: FormTheme.surfaceDark,
        border: Border.all(
          color: featureStyle.borderColor.withValues(alpha: _isExpanded ? 0.7 : 0.4),
          width: _isExpanded ? 2 : 1.5,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: featureStyle.borderColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (always visible)
          _FeatureHeader(
            feature: feature,
            featureStyle: featureStyle,
            grantType: grantType,
            isExpanded: _isExpanded,
            onToggle: _toggleExpanded,
            widget: w,
          ),
          // Expandable content with animated size
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(
                          height: 1,
                          color: featureStyle.borderColor.withValues(alpha: 0.3),
                        ),
                        _FeatureContent(
                          feature: feature,
                          details: details,
                          grantType: grantType,
                          widget: w,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveGrantType() {
    final featureKey = feature.name.toLowerCase().trim();
    return w.grantTypeByFeatureName[featureKey] ?? '';
  }
  
  /// Determines if this feature has options that require a user choice.
  /// Returns true if:
  /// - Feature has 'options' or 'options_X' with multiple entries and user hasn't selected enough
  /// - OR Feature has options with skill_group that haven't been selected yet
  /// - Feature doesn't use 'grants' (which are auto-applied)
  bool _hasOptionsRequiringChoice(Map<String, dynamic>? details) {
    if (details == null) return false;
    
    // Check if it uses grants (auto-applied, no choice needed for the main selection)
    final grants = details['grants'];
    final isGrantsFeature = grants is List && grants.isNotEmpty;
    
    // Extract options using the service
    final options = ClassFeatureDataService.extractOptionMaps(details);
    if (options.isEmpty) return false;
    
    // Check for pending skill_group selections in any option
    // (even auto-applied options can have skill_group pickers)
    if (_hasPendingSkillGroupSelections(options)) {
      return true;
    }
    
    // For grants features, no further choice is needed
    if (isGrantsFeature) return false;
    
    // If there's only one option, it's auto-applied (no choice needed)
    if (options.length <= 1) return false;
    
    // Check if user already made a selection
    final currentSelections = w.selectedOptions[feature.id] ?? const <String>{};
    final minimumRequired = ClassFeatureDataService.minimumSelections(details);
    final effectiveMinimum = minimumRequired <= 0 ? 1 : minimumRequired;
    
    return currentSelections.length < effectiveMinimum;
  }
  
  /// Checks if any ACTIVE option has a skill_group that hasn't been selected yet.
  /// Only considers options that match the current subclass/domain selection.
  bool _hasPendingSkillGroupSelections(List<Map<String, dynamic>> options) {
    for (final option in options) {
      final skillGroup = option['skill_group']?.toString().trim();
      if (skillGroup == null || skillGroup.isEmpty) continue;
      
      // Only check options that are active for the current selection
      if (!_isOptionActiveForCurrentSelection(option)) continue;
      
      // Check if user has made a skill_group selection for this option
      final grantKey = ClassFeatureDataService.optionGrantKey(option);
      final featureSelections = w.skillGroupSelections[feature.id];
      final selectedSkillId = featureSelections?[grantKey];
      
      if (selectedSkillId == null || selectedSkillId.isEmpty) {
        return true; // Found a pending skill_group selection
      }
    }
    return false;
  }
  
  /// Checks if an option is active based on current subclass/domain selection.
  bool _isOptionActiveForCurrentSelection(Map<String, dynamic> option) {
    return ClassFeatureDataService.isOptionActiveForSelection(
      option,
      activeSubclassSlugs: w.activeSubclassSlugs,
      selectedDomainSlugs: w.selectedDomainSlugs,
      selectedDeitySlugs: w.selectedDeitySlugs,
    );
  }
  
  /// Build a special card for progression features (Growing Ferocity / Discipline Mastery)
  Widget _buildProgressionFeatureCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    _FeatureStyle featureStyle,
  ) {
    return _HeroicResourceProgressionFeature(
      feature: feature,
      featureStyle: featureStyle,
      isExpanded: _isExpanded,
      onToggle: () => setState(() => _isExpanded = !_isExpanded),
      widget: w,
    );
  }
}

class _FeatureStyle {
  final Color borderColor;
  final IconData icon;
  final String label;

  const _FeatureStyle({
    required this.borderColor,
    required this.icon,
    required this.label,
  });

  factory _FeatureStyle.fromGrantType(
    String grantType,
    bool isSubclass, {
    bool hasOptionsRequiringChoice = false,
  }) {
    switch (grantType) {
      case 'granted':
        return _FeatureStyle(
          borderColor: Colors.green.shade600,
          icon: Icons.check_circle_outline,
          label: ClassFeatureCardText.grantedLabel,
        );
      case 'pick':
        // Only show "Choice Required" styling while a required choice is still pending.
        // Once the user has satisfied the selection(s), fall back to the normal feature styling.
        if (hasOptionsRequiringChoice) {
          return _FeatureStyle(
            borderColor: Colors.orange.shade600,
            icon: Icons.touch_app_outlined,
            label: ClassFeatureCardText.choiceRequiredLabel,
          );
        }
        if (isSubclass) {
          return _FeatureStyle(
            borderColor: Colors.purple.shade500,
            icon: Icons.star_outline_rounded,
            label: ClassFeatureCardText.subclassFeatureLabel,
          );
        }
        return _FeatureStyle(
          borderColor: Colors.blueGrey.shade400,
          icon: Icons.category_outlined,
          label: ClassFeatureCardText.classFeatureLabel,
        );
      case 'ability':
        return _FeatureStyle(
          borderColor: Colors.blue.shade600,
          icon: Icons.auto_awesome_outlined,
          label: ClassFeatureCardText.abilityGrantedLabel,
        );
      default:
        // If no explicit grantType but feature has options requiring choice
        if (hasOptionsRequiringChoice) {
          return _FeatureStyle(
            borderColor: Colors.orange.shade600,
            icon: Icons.touch_app_outlined,
            label: ClassFeatureCardText.choiceRequiredLabel,
          );
        }
        if (isSubclass) {
          return _FeatureStyle(
            borderColor: Colors.purple.shade500,
            icon: Icons.star_outline_rounded,
            label: ClassFeatureCardText.subclassFeatureLabel,
          );
        }
        return _FeatureStyle(
          borderColor: Colors.blueGrey.shade400,
          icon: Icons.category_outlined,
          label: ClassFeatureCardText.classFeatureLabel,
        );
    }
  }
}

