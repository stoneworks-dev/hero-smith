part of 'class_features_widget.dart';

class _FeatureContent extends StatelessWidget {
  const _FeatureContent({
    required this.feature,
    required this.details,
    required this.grantType,
    required this.widget,
  });

  final Feature feature;
  final Map<String, dynamic>? details;
  final String grantType;
  final ClassFeaturesWidget widget;

  @override
  Widget build(BuildContext context) {
    final description = _coalesceDescription();
    final allOptions = _extractOptionsOrGrants();
    final isGrantsFeature = _hasGrants();
    final originalSelections = widget.selectedOptions[feature.id] ?? const <String>{};

    final optionsContext = _prepareFeatureOptions(allOptions, originalSelections);
    final isAbilityFeature = grantType == 'ability';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (description?.isNotEmpty ?? false)
            _DescriptionSection(description: description!),

          // Ability card for ability features
          if (isAbilityFeature) ...[
            const SizedBox(height: 16),
            _buildAbilitySection(context),
          ],

          // Detail sections
          ..._buildDetailSections(context),

          // Options section
          if (allOptions.isNotEmpty || optionsContext.messages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _OptionsSection(
              feature: feature,
              details: details,
              optionsContext: optionsContext,
              originalSelections: originalSelections,
              isGrantsFeature: isGrantsFeature,
              widget: widget,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbilitySection(BuildContext context) {
    final ability = _resolveAbilityForFeature();
    if (ability == null) return const SizedBox.shrink();

    final component = _abilityMapToComponent(ability);
    return AbilityExpandableItem(component: component);
  }

  Map<String, dynamic>? _resolveAbilityForFeature() {
    if (details != null) {
      final abilityRef = details!['ability'];
      if (abilityRef is String && abilityRef.trim().isNotEmpty) {
        final ability = _resolveAbilityByName(abilityRef);
        if (ability != null) return ability;
      }
      final abilityId = details!['ability_id'];
      if (abilityId is String && abilityId.trim().isNotEmpty) {
        final ability = widget.abilityDetailsById[abilityId];
        if (ability != null) return ability;
      }
    }
    return _resolveAbilityByName(feature.name);
  }

  Map<String, dynamic>? _resolveAbilityByName(String name) {
    final slug = ClassFeatureDataService.slugify(name);
    final resolvedId = widget.abilityIdByName[slug] ?? slug;
    return widget.abilityDetailsById[resolvedId];
  }

  Component _abilityMapToComponent(Map<String, dynamic> abilityData) {
    final id = abilityData['id']?.toString() ??
        abilityData['resolved_id']?.toString() ??
        '';
    final name = abilityData['name']?.toString() ?? '';
    final type = abilityData['type']?.toString() ?? 'ability';

    return Component(
      id: id,
      type: type,
      name: name,
      data: abilityData,
      source: 'seed',
    );
  }

  String? _coalesceDescription() {
    final detailDescription = details?['description'];
    final fromDetails = _normalizeText(detailDescription);
    if (fromDetails?.isNotEmpty ?? false) return fromDetails;
    return _normalizeText(feature.description);
  }

  String? _normalizeText(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is List) {
      final parts = value
          .whereType<String>()
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('\n\n');
    }
    return value.toString();
  }

  /// Extracts options or grants from feature details.
  /// Returns the list from 'grants' if auto-applied, otherwise from 'options' or 'options_X'.
  /// The 'options_X' pattern (e.g., options_2, options_3) indicates X choices allowed.
  List<Map<String, dynamic>> _extractOptionsOrGrants() {
    return ClassFeatureDataService.extractOptionMaps(details);
  }

  /// Returns true if the feature uses 'grants' (auto-apply all matching)
  /// instead of 'options' or 'options_X' (user picks).
  bool _hasGrants() {
    if (details == null) return false;
    final grants = details!['grants'];
    return grants is List && grants.isNotEmpty;
  }

  _FeatureOptionsContext _prepareFeatureOptions(
    List<Map<String, dynamic>> allOptions,
    Set<String> currentSelections,
  ) {
    var filteredOptions = List<Map<String, dynamic>>.from(allOptions);
    var allowEditing = true;
    final messages = <String>[];
    var requiresExternalSelection = false;

    void applyFilter(_OptionFilterResult result) {
      filteredOptions = result.options;
      allowEditing = allowEditing && result.allowEditing;
      messages.addAll(result.messages);
      requiresExternalSelection =
          requiresExternalSelection || result.requiresExternalSelection;
    }

    if (widget.domainLinkedFeatureIds.contains(feature.id)) {
      final result = _applyDomainFilter(filteredOptions);
      applyFilter(result);
      if (filteredOptions.isEmpty && result.requiresExternalSelection) {
        return _FeatureOptionsContext(
          options: filteredOptions,
          selectedKeys: const <String>{},
          allowEditing: false,
          messages: messages,
          requiresExternalSelection: true,
          selectionLimit: 0,
          minimumRequired: 0,
        );
      }
    }

    if (widget.deityLinkedFeatureIds.contains(feature.id)) {
      final result = _applyDeityFilter(filteredOptions);
      applyFilter(result);
      if (filteredOptions.isEmpty && result.requiresExternalSelection) {
        return _FeatureOptionsContext(
          options: filteredOptions,
          selectedKeys: const <String>{},
          allowEditing: false,
          messages: messages,
          requiresExternalSelection: true,
          selectionLimit: 0,
          minimumRequired: 0,
        );
      }
    }

    if (feature.isSubclassFeature) {
      final result = _applySubclassFilter(filteredOptions);
      applyFilter(result);
    }

    final filteredKeys = filteredOptions
        .map((o) => ClassFeatureDataService.featureOptionKey(o))
        .toSet();

    final rawSelectionLimit = ClassFeatureDataService.selectionLimit(details);
    final rawMinimumRequired = ClassFeatureDataService.minimumSelections(details);

    final effectiveLimit = (rawSelectionLimit > 0 && filteredOptions.isNotEmpty)
        ? rawSelectionLimit.clamp(1, filteredOptions.length)
        : rawSelectionLimit;
    final effectiveMinimum = rawMinimumRequired.clamp(
      0,
      filteredOptions.isEmpty ? 0 : filteredOptions.length,
    );

    final selectedKeys = ClassFeatureDataService.clampSelectionKeys(
      currentSelections.where(filteredKeys.contains).toSet(),
      details,
    );

    return _FeatureOptionsContext(
      options: filteredOptions,
      selectedKeys: selectedKeys,
      allowEditing: allowEditing,
      messages: messages,
      requiresExternalSelection: requiresExternalSelection,
      selectionLimit: effectiveLimit,
      minimumRequired: effectiveMinimum,
    );
  }

  _OptionFilterResult _applyDomainFilter(List<Map<String, dynamic>> currentOptions) {
    final effectiveDomainSlugs =
        ClassFeatureDataService.remainingConduitDomainSlugsForFeature(
      featureId: feature.id,
      selectedDomainSlugs: widget.selectedDomainSlugs,
      selections: widget.selectedOptions,
      featureDetailsById: widget.featureDetailsById,
    );

    if (effectiveDomainSlugs.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.domainUnlockMessage],
        requiresExternalSelection: true,
      );
    }

    final allowedKeys = ClassFeatureDataService.domainOptionKeysFor(
      widget.featureDetailsById,
      feature.id,
      effectiveDomainSlugs,
    );

    if (allowedKeys.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.domainNoOptionsMessage],
      );
    }

    final filtered = currentOptions
        .where((o) => allowedKeys.contains(ClassFeatureDataService.featureOptionKey(o)))
        .toList();

    if (filtered.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.domainNoOptionsMessage],
      );
    }

    final allowEditing =
        effectiveDomainSlugs.length > 1 && filtered.length > 1;
    return _OptionFilterResult(
      options: filtered,
      allowEditing: allowEditing,
      messages: allowEditing
          ? [FeatureContentText.domainPickMessage]
          : [FeatureContentText.domainAutoMessage],
    );
  }

  _OptionFilterResult _applyDeityFilter(List<Map<String, dynamic>> currentOptions) {
    if (widget.selectedDeitySlugs.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.deityUnlockMessage],
        requiresExternalSelection: true,
      );
    }

    final filtered = <Map<String, dynamic>>[];
    var hasTaggedOption = false;
    for (final option in currentOptions) {
      final slugs = _optionDeitySlugs(option);
      if (slugs.isEmpty) continue;
      hasTaggedOption = true;
      if (slugs.intersection(widget.selectedDeitySlugs).isNotEmpty) {
        filtered.add(option);
      }
    }

    if (!hasTaggedOption) {
      return _OptionFilterResult(options: currentOptions, allowEditing: true);
    }

    if (filtered.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.deityNoOptionsMessage],
      );
    }

    final allowEditing = filtered.length > 1;
    final deityName = widget.subclassSelection?.deityName?.trim();
    final message = allowEditing
        ? FeatureContentText.deityPickMessage
        : (deityName?.isEmpty ?? true
            ? FeatureContentText.deityAutoMessage
            : '${FeatureContentText.deityAutoMessagePrefix}$deityName${FeatureContentText.deityAutoMessageSuffix}');

    return _OptionFilterResult(
      options: filtered,
      allowEditing: allowEditing,
      messages: [message],
    );
  }

  _OptionFilterResult _applySubclassFilter(List<Map<String, dynamic>> currentOptions) {
    if (widget.activeSubclassSlugs.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.subclassUnlockMessage],
        requiresExternalSelection: true,
      );
    }

    final filtered = <Map<String, dynamic>>[];
    var hasTaggedOption = false;
    for (final option in currentOptions) {
      final slugs = _optionSubclassSlugs(option);
      if (slugs.isEmpty) continue;
      hasTaggedOption = true;
      if (slugs.intersection(widget.activeSubclassSlugs).isNotEmpty) {
        filtered.add(option);
      }
    }

    if (!hasTaggedOption) {
      return _OptionFilterResult(options: currentOptions, allowEditing: true);
    }

    if (filtered.isEmpty) {
      return const _OptionFilterResult(
        options: [],
        allowEditing: false,
        messages: [FeatureContentText.subclassNoOptionsMessage],
      );
    }

    final allowEditing = filtered.length > 1;
    final subclassName = widget.subclassSelection?.subclassName?.trim();
    final message = allowEditing
        ? FeatureContentText.subclassPickMessage
        : (subclassName?.isEmpty ?? true
            ? FeatureContentText.subclassAutoMessage
            : '${FeatureContentText.subclassAutoMessagePrefix}$subclassName${FeatureContentText.subclassAutoMessageSuffix}');

    return _OptionFilterResult(
      options: filtered,
      allowEditing: allowEditing,
      messages: [message],
    );
  }

  Set<String> _optionSubclassSlugs(Map<String, dynamic> option) {
    return _extractOptionSlugs(option, ClassFeaturesWidget._widgetSubclassOptionKeys);
  }

  Set<String> _optionDeitySlugs(Map<String, dynamic> option) {
    return _extractOptionSlugs(option, ClassFeaturesWidget._widgetDeityOptionKeys);
  }

  /// Keys that explicitly indicate a subclass requirement (not fallbacks like 'name')
  static const List<String> _explicitSubclassKeys = [
    'subclass', 'subclass_name', 'tradition', 'order', 'doctrine',
    'mask', 'path', 'circle', 'college', 'element', 'role',
    'discipline', 'oath', 'school', 'guild', 'aspect',
  ];

  Set<String> _extractOptionSlugs(Map<String, dynamic> option, List<String> keys) {
    final slugs = <String>{};
    var hasExplicitSubclassKey = false;
    
    // First pass: collect slugs from explicit subclass keys
    for (final key in _explicitSubclassKeys) {
      if (!keys.contains(key)) continue;
      final value = option[key];
      if (value == null) continue;
      hasExplicitSubclassKey = true;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) continue;
        slugs.addAll(ClassFeatureDataService.slugVariants(trimmed));
      } else if (value is List) {
        for (final entry in value.whereType<String>()) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) continue;
          slugs.addAll(ClassFeatureDataService.slugVariants(trimmed));
        }
      }
    }
    
    // If no explicit subclass keys found, fall back to checking 'name' and 'domain'
    if (!hasExplicitSubclassKey) {
      for (final key in keys) {
        if (_explicitSubclassKeys.contains(key)) continue; // Skip already checked
        final value = option[key];
        if (value == null) continue;
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) continue;
          slugs.addAll(ClassFeatureDataService.slugVariants(trimmed));
        } else if (value is List) {
          for (final entry in value.whereType<String>()) {
            final trimmed = entry.trim();
            if (trimmed.isEmpty) continue;
            slugs.addAll(ClassFeatureDataService.slugVariants(trimmed));
          }
        }
      }
    }
    
    return slugs;
  }

  List<Widget> _buildDetailSections(BuildContext context) {
    if (details == null || details!.isEmpty) return const [];

    final sections = <Widget>[];
    void addSection(String title, IconData icon, dynamic value) {
      if (value == null) return;
      String? content;
      if (value is String) {
        content = value.trim();
      } else if (value is Map<String, dynamic>) {
        final name = value['name']?.toString().trim();
        final description = value['description']?.toString().trim();
        final pieces = <String>[];
        if (name?.isNotEmpty ?? false) pieces.add(name!);
        if (description?.isNotEmpty ?? false) pieces.add(description!);
        content = pieces.join('\n\n');
      }
      if (content?.isEmpty ?? true) return;
      sections.add(const SizedBox(height: 12));
      sections.add(_DetailBlock(title: title, icon: icon, content: content!));
    }

    addSection(
      FeatureContentText.detailTitleInCombat,
      Icons.sports_kabaddi,
      details!['in_combat'],
    );
    addSection(
      FeatureContentText.detailTitleOutOfCombat,
      Icons.explore,
      details!['out_of_combat'],
    );
    addSection(
      FeatureContentText.detailTitleSpecial,
      Icons.auto_awesome,
      details!['special'],
    );
    addSection(
      FeatureContentText.detailTitleNotes,
      Icons.sticky_note_2,
      details!['notes'],
    );

    return sections;
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: CreatorTheme.textSecondary,
        height: 1.5,
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FormTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CreatorTheme.strengthAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: CreatorTheme.strengthAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CreatorTheme.strengthAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CreatorTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureOptionsContext {
  const _FeatureOptionsContext({
    required this.options,
    required this.selectedKeys,
    required this.allowEditing,
    required this.messages,
    required this.requiresExternalSelection,
    required this.selectionLimit,
    required this.minimumRequired,
  });

  final List<Map<String, dynamic>> options;
  final Set<String> selectedKeys;
  final bool allowEditing;
  final List<String> messages;
  final bool requiresExternalSelection;
  final int selectionLimit;
  final int minimumRequired;
}

class _OptionFilterResult {
  const _OptionFilterResult({
    required this.options,
    required this.allowEditing,
    this.messages = const [],
    this.requiresExternalSelection = false,
  });

  final List<Map<String, dynamic>> options;
  final bool allowEditing;
  final List<String> messages;
  final bool requiresExternalSelection;
}

