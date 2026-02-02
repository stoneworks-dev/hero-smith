part of 'sheet_story.dart';

/// Tab showing class features (read-only)
class _FeaturesTab extends ConsumerStatefulWidget {
  const _FeaturesTab({required this.heroId});

  final String heroId;

  @override
  ConsumerState<_FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends ConsumerState<_FeaturesTab> {
  final ClassDataService _classDataService = ClassDataService();
  final SubclassDataService _subclassDataService = SubclassDataService();

  bool _isLoading = true;
  String? _error;
  ClassData? _classData;
  int _level = 1;
  SubclassSelectionResult? _subclassSelection;
  DeityOption? _selectedDeity;
  List<String> _selectedDomains = const <String>[];
  String? _characteristicArrayDescription;
  Map<String, Set<String>> _featureSelections = const {};
  List<String?> _equipmentIds = const [];
  Map<String, Map<String, String>> _skillGroupSelections = const {};
  Set<String> _reservedSkillIds = const {};

  @override
  void initState() {
    super.initState();
    _loadHeroData();
  }

  Future<void> _loadHeroData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _classDataService.initialize();
      final repo = ref.read(heroRepositoryProvider);
      final db = ref.read(appDatabaseProvider);
      final hero = await repo.load(widget.heroId);

      if (hero == null || hero.className == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = SheetStoryFeaturesTabText.noClassAssignedToHero;
          });
        }
        return;
      }

      final classData = _classDataService
          .getAllClasses()
          .firstWhere((c) => c.classId == hero.className);

      // Capture characteristic array description if stored in hero values
      String? arrayDescription;
      final heroValues = await db.getHeroValues(widget.heroId);
      for (final value in heroValues) {
        if (value.key == 'strife.characteristic_array') {
          arrayDescription = value.textValue;
          break;
        }
      }

      final domainNames = hero.domain == null
          ? <String>[]
          : hero.domain!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      DeityOption? deityOption;
      if (hero.deityId != null && hero.deityId!.trim().isNotEmpty) {
        final deities = await _subclassDataService.loadDeities();
        final target = hero.deityId!.trim();
        final targetLower = target.toLowerCase();
        final targetSlug = ClassFeatureDataService.slugify(target);
        deityOption = deities.firstWhereOrNull((deity) {
          final idLower = deity.id.toLowerCase();
          if (idLower == targetLower) return true;
          final slugId = ClassFeatureDataService.slugify(deity.id);
          final slugName = ClassFeatureDataService.slugify(deity.name);
          if (slugId == targetSlug || slugName == targetSlug) {
            return true;
          }
          return false;
        });
      }

      SubclassSelectionResult? selection;
      final subclassName = hero.subclass?.trim();
      if ((subclassName != null && subclassName.isNotEmpty) ||
          (hero.deityId != null && hero.deityId!.trim().isNotEmpty) ||
          domainNames.isNotEmpty) {
        final subclassKey = (subclassName != null && subclassName.isNotEmpty)
            ? ClassFeatureDataService.slugify(subclassName)
            : null;
        selection = SubclassSelectionResult(
          subclassKey: subclassKey,
          subclassName: subclassName,
          deityId: hero.deityId?.trim(),
          deityName: deityOption?.name ?? hero.deityId?.trim(),
          domainNames: domainNames,
        );
      }

      final savedFeatureSelections = await repo.getFeatureSelections(widget.heroId);
      final equipmentIds = await repo.getEquipmentIds(widget.heroId);
      
      // Load skill_group selections
      Map<String, Map<String, String>> skillGroupSelections = const {};
      Set<String> reservedSkillIds = const {};
      try {
        final grantService = ClassFeatureGrantsService(db);
        skillGroupSelections = await grantService.loadSkillGroupSelections(widget.heroId);
        
        // Get reserved skill IDs (skills from all sources)
        final allSkillEntries = await repo.getSkillEntries(widget.heroId);
        reservedSkillIds = allSkillEntries.map((e) => e.entryId).toSet();
      } catch (_) {
        // Best-effort: continue without skill group data
      }

      if (mounted) {
        setState(() {
          _classData = classData;
          _level = hero.level;
          _subclassSelection = selection;
          _selectedDeity = deityOption;
          _selectedDomains = domainNames;
          _characteristicArrayDescription = arrayDescription;
          _featureSelections = savedFeatureSelections.isNotEmpty
              ? savedFeatureSelections
              : const {};
          _equipmentIds = equipmentIds;
          _skillGroupSelections = skillGroupSelections;
          _reservedSkillIds = reservedSkillIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = SheetStoryFeaturesTabText.failedToLoadFeatures(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_classData == null) {
      return const Center(
        child: Text(SheetStoryFeaturesTabText.noFeaturesAvailable),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHeroData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildSelectionChips(theme),
          ),
          const SizedBox(height: 12),
          ClassFeaturesSection(
            classData: _classData!,
            selectedLevel: _level,
            selectedSubclass: _subclassSelection,
            initialSelections: _featureSelections,
            equipmentIds: _equipmentIds,
            onSelectionsChanged: _handleSelectionsChanged,
            skillGroupSelections: _skillGroupSelections,
            onSkillGroupSelectionChanged: _handleSkillGroupSelectionChanged,
            reservedSkillIds: _reservedSkillIds,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelectionsChanged(
    Map<String, Set<String>> selections,
  ) async {
    setState(() {
      _featureSelections = selections;
    });

    try {
      final repo = ref.read(heroRepositoryProvider);
      await repo.saveFeatureSelections(widget.heroId, selections);
      if (_classData != null) {
        final db = ref.read(appDatabaseProvider);
        final grantService = ClassFeatureGrantsService(db);
        await grantService.applyClassFeatureSelections(
          heroId: widget.heroId,
          classData: _classData!,
          level: _level,
          selections: selections,
          subclassSelection: _subclassSelection,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SheetStoryFeaturesTabText.failedToSaveFeatureSelections(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSkillGroupSelectionChanged(
    String featureId,
    String grantKey,
    String? skillId,
  ) async {
    // Update local state immediately for responsiveness
    setState(() {
      final updated = Map<String, Map<String, String>>.from(_skillGroupSelections);
      if (skillId == null || skillId.isEmpty) {
        if (updated.containsKey(featureId)) {
          updated[featureId]!.remove(grantKey);
          if (updated[featureId]!.isEmpty) {
            updated.remove(featureId);
          }
        }
      } else {
        updated.putIfAbsent(featureId, () => {});
        updated[featureId]![grantKey] = skillId;
      }
      _skillGroupSelections = updated;
      
      // Update reserved skill IDs
      final updatedReserved = Set<String>.from(_reservedSkillIds);
      if (skillId != null && skillId.isNotEmpty) {
        updatedReserved.add(skillId);
      }
      _reservedSkillIds = updatedReserved;
    });
    
    // Save to database
    try {
      final db = ref.read(appDatabaseProvider);
      final grantService = ClassFeatureGrantsService(db);
      await grantService.setSkillGroupSelection(
        heroId: widget.heroId,
        featureId: featureId,
        grantKey: grantKey,
        skillId: skillId,
      );
      
      // Reload reserved skills to ensure consistency
      final repo = ref.read(heroRepositoryProvider);
      final allSkillEntries = await repo.getSkillEntries(widget.heroId);
      if (mounted) {
        setState(() {
          _reservedSkillIds = allSkillEntries.map((e) => e.entryId).toSet();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SheetStoryFeaturesTabText.failedToSaveSkillSelection(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildSelectionChips(ThemeData theme) {
    final chips = <Widget>[];

    final subclassName = _subclassSelection?.subclassName;
    if (subclassName != null && subclassName.trim().isNotEmpty) {
      chips.add(_buildCompactChip(theme, subclassName.trim(), Icons.star));
    }

    if (_selectedDomains.isNotEmpty) {
      for (final domain in _selectedDomains) {
        if (domain.trim().isEmpty) continue;
        chips.add(_buildCompactChip(theme, domain.trim(), Icons.account_tree));
      }
    }

    final deityDisplay = _selectedDeity?.name ?? _subclassSelection?.deityName;
    if (deityDisplay != null && deityDisplay.trim().isNotEmpty) {
      chips.add(_buildCompactChip(theme, deityDisplay.trim(), Icons.church));
    }

    if (_characteristicArrayDescription != null &&
        _characteristicArrayDescription!.trim().isNotEmpty) {
      chips.add(_buildCompactChip(theme, _characteristicArrayDescription!.trim(), Icons.view_module));
    }

    return chips;
  }

  Widget _buildCompactChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
