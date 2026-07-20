part of 'sheet_story.dart';

const _complicationsColor = NavigationTheme.complicationsColor;

class _ComplicationsTab extends ConsumerStatefulWidget {
  const _ComplicationsTab({
    required this.heroId,
    this.onChanged,
  });

  final String heroId;
  final VoidCallback? onChanged;

  @override
  ConsumerState<_ComplicationsTab> createState() => _ComplicationsTabState();
}

class _ComplicationsTabState extends ConsumerState<_ComplicationsTab> {
  Map<String, String> _complicationChoices = {};
  bool _isLoadingChoices = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    try {
      setState(() {
        _isLoadingChoices = true;
        _errorMessage = null;
      });

      final service = ref.read(complicationGrantsServiceProvider);
      final choices = await service.loadComplicationChoices(widget.heroId);

      if (!mounted) return;
      setState(() {
        _complicationChoices = choices;
        _isLoadingChoices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingChoices = false;
        _errorMessage = SheetStoryComplicationsTabText.failedToLoad(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(heroEntriesProvider(widget.heroId));
    final entries = entriesAsync.valueOrNull;
    final complicationsAsync =
        ref.watch(componentsByTypeProvider('complication'));
    final complications = complicationsAsync.valueOrNull;

    if (_isLoadingChoices ||
        (entries == null && entriesAsync.isLoading) ||
        (complications == null && complicationsAsync.isLoading)) {
      return const Center(
        child: CircularProgressIndicator(color: _complicationsColor),
      );
    }

    if (_errorMessage != null ||
        (entries == null && entriesAsync.hasError) ||
        (complications == null && complicationsAsync.hasError)) {
      final message = _errorMessage ??
          SheetStoryComplicationsTabText.failedToLoad(
            entriesAsync.error ?? complicationsAsync.error!,
          );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.red.shade300)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChoices,
              style: ElevatedButton.styleFrom(
                backgroundColor: _complicationsColor,
                foregroundColor: FormTheme.textBright,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    final complicationEntries = (entries ?? const [])
        .where((entry) => entry.entryType == HeroEntryTypes.complication)
        .toList();
    final selectedComplicationIds =
        complicationEntries.map((entry) => entry.entryId).toList();
    final complicationById = {
      for (final complication in complications ?? const <model.Component>[])
        complication.id: complication,
    };

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(selectedComplicationIds.length),
              const SizedBox(height: 16),
              if (_isSaving) ...[
                const LinearProgressIndicator(color: _complicationsColor),
                const SizedBox(height: 12),
              ],
              if (selectedComplicationIds.isEmpty)
                _buildEmptyState()
              else
                ...selectedComplicationIds.map(
                  (complicationId) {
                    final complication = complicationById[complicationId] ??
                        model.Component(
                          id: complicationId,
                          type: HeroEntryTypes.complication,
                          name: SheetStoryComplicationSectionText.notFound,
                          data: const {},
                        );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: StoryComplicationDetails(
                        complication: complication,
                        choices: _complicationChoices,
                        conflictIndex: _conflictIndexFor(
                          complicationId,
                          entries ?? const [],
                        ),
                        onChoicesChanged: (choices) {
                          _saveSelectionAndReapply(
                            selectedComplicationIds,
                            choices: choices,
                          );
                        },
                        trailing: IconButton(
                          tooltip:
                              SheetStoryComplicationsTabText.removeComplication,
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _removeComplication(
                                    complicationId,
                                    selectedComplicationIds,
                                  );
                                },
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'complications_tab_fab',
            onPressed: _isSaving
                ? null
                : () {
                    _showAddComplicationDialog(selectedComplicationIds);
                  },
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: _complicationsColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _complicationsColor, width: 2),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  HeroConflictIndex _conflictIndexFor(
    String complicationId,
    List<app_db.HeroEntry> entries,
  ) {
    final persistedClaims = entries
        .where(
          (entry) => HeroEntryTypes.componentBackedTypes.contains(
            entry.entryType,
          ),
        )
        .map(
          (entry) => HeroEntryClaim(
            key: HeroEntryKey(
              entryType: entry.entryType,
              canonicalEntryId: entry.entryId,
            ),
            owner: HeroClaimOwner.persisted(
              source: HeroClaimSource(
                sourceType: entry.sourceType,
                sourceId: entry.sourceId,
              ),
            ),
          ),
        );
    return HeroConflictIndex.projected(
      persistedClaims: persistedClaims,
      mutationScopes: [
        HeroMutationScope.single(
          HeroClaimSource(
            sourceType: HeroEntrySourceTypes.complication,
            sourceId: complicationId,
          ),
        ),
        HeroMutationScope.single(
          HeroClaimSource(
            sourceType: HeroEntrySourceTypes.complicationAncestryTrait,
            sourceId: complicationId,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int selectedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _complicationsColor.withAlpha(38),
            _complicationsColor.withAlpha(10),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _complicationsColor.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppIcon(
              StoryIcons.complication,
              color: _complicationsColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SheetStoryComplicationsTabText.headerTitle,
                  style: TextStyle(
                    color: FormTheme.textBright,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  SheetStoryComplicationsTabText.complicationsSelected(
                    selectedCount,
                  ),
                  style: TextStyle(
                    color: FormTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Text(
        SheetStoryComplicationsTabText.emptyState,
        textAlign: TextAlign.center,
        style: TextStyle(color: FormTheme.textSecondary, fontSize: 14),
      ),
    );
  }

  Future<void> _showAddComplicationDialog(
    List<String> selectedComplicationIds,
  ) async {
    try {
      final complications =
          await ref.read(componentsByTypeProvider('complication').future);
      final selectedIds = selectedComplicationIds.toSet();
      final availableComplications = complications
          .where((complication) => !selectedIds.contains(complication.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (availableComplications.isEmpty) {
        _showError(SheetStoryComplicationsTabText.noComplicationsAvailable);
        return;
      }

      if (!mounted) return;
      final result = await showSearchablePicker<String>(
        context: context,
        title: SheetStoryComplicationsTabText.addComplication,
        options: availableComplications
            .map(
              (complication) => SearchableOption<String>(
                label: complication.name,
                value: complication.id,
                subtitle: _shortDescription(complication),
              ),
            )
            .toList(),
        conflictConfig: PickerConflictConfig(existingIds: selectedIds),
        showDisabledOptions: false,
        accentColor: _complicationsColor,
        icon: Icons.warning_amber_rounded,
        autofocusSearch: true,
      );

      final complicationId = result?.value?.trim();
      if (complicationId == null || complicationId.isEmpty) return;

      await _saveSelectionAndReapply([
        ...selectedComplicationIds,
        complicationId,
      ]);
    } catch (e) {
      _showError(SheetStoryComplicationsTabText.failedToLoad(e));
    }
  }

  String? _shortDescription(model.Component complication) {
    final description = complication.data['description']?.toString().trim();
    if (description == null || description.isEmpty) return null;
    if (description.length <= 96) return description;
    return '${description.substring(0, 93)}...';
  }

  Future<void> _removeComplication(
    String complicationId,
    List<String> selectedComplicationIds,
  ) async {
    final nextIds = selectedComplicationIds
        .where((selectedId) => selectedId != complicationId)
        .toList();
    final nextChoices = Map<String, String>.from(_complicationChoices)
      ..removeWhere((key, _) => key.startsWith('${complicationId}_'));
    await _saveSelectionAndReapply(nextIds, choices: nextChoices);
  }

  Future<void> _saveSelectionAndReapply(
    List<String> complicationIds, {
    Map<String, String>? choices,
  }) async {
    if (_isSaving) return;

    final uniqueIds = <String>[];
    for (final id in complicationIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && !uniqueIds.contains(trimmed)) {
        uniqueIds.add(trimmed);
      }
    }
    final nextChoices = choices ?? _complicationChoices;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final service = ref.read(complicationGrantsServiceProvider);
      final heroLevel = await ref.read(heroRepositoryProvider).getHeroLevel(
            widget.heroId,
          );

      // Partition the desired complication ids into the creator-owned slot
      // (sourceId == 'complication') and the tab-managed slot (sourceId ==
      // 'sheet_add'), preserving any existing creator-picked complication so
      // tab edits never wipe it.
      final allEntries = await ref
          .read(heroEntryRepositoryProvider)
          .listEntriesByType(widget.heroId, HeroEntryTypes.complication);
      final existingCreatorIds = allEntries
          .where((e) =>
              e.entryType == HeroEntryTypes.complication &&
              e.sourceType == HeroEntrySourceTypes.manualChoice &&
              e.sourceId == HeroEntryTypes.complication)
          .map((e) => e.entryId)
          .toSet();
      final desired = uniqueIds.toSet();
      final nextCreatorIds =
          existingCreatorIds.where(desired.contains).toList();
      final nextSheetIds =
          uniqueIds.where((id) => !nextCreatorIds.contains(id)).toList();

      // Rewrite the creator slot only when its membership actually changes
      // (e.g. the user removed the creator-picked complication via the tab).
      if (existingCreatorIds.length != nextCreatorIds.length ||
          !existingCreatorIds.containsAll(nextCreatorIds)) {
        await db.setHeroEntryIds(
          heroId: widget.heroId,
          entryType: HeroEntryTypes.complication,
          entryIds: nextCreatorIds,
          sourceType: HeroEntrySourceTypes.manualChoice,
          sourceId: HeroEntryTypes.complication,
          gainedBy: HeroEntryGainedBy.choice,
        );
      }

      // Rewrite the tab-managed slot.
      await db.setHeroEntryIds(
        heroId: widget.heroId,
        entryType: HeroEntryTypes.complication,
        entryIds: nextSheetIds,
        sourceType: HeroEntrySourceTypes.manualChoice,
        sourceId: HeroEntrySourceIds.sheetAdd,
        gainedBy: HeroEntryGainedBy.choice,
      );

      await service.saveComplicationChoices(
        heroId: widget.heroId,
        choices: nextChoices,
      );

      await service.reapplyAllComplications(
        heroId: widget.heroId,
        complicationIds: uniqueIds,
        choices: nextChoices,
        heroLevel: heroLevel,
      );

      if (!mounted) return;
      setState(() {
        _complicationChoices = nextChoices;
      });
      widget.onChanged?.call();
    } catch (e) {
      _showError(SheetStoryComplicationsTabText.failedToSave(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
