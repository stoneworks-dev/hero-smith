part of 'sheet_story.dart';

// Perks accent color
const _perksColor = StoryTheme.perksAccent;

// Perks Tab Widget
class _PerksTab extends ConsumerStatefulWidget {
  final String heroId;

  const _PerksTab({required this.heroId});

  @override
  ConsumerState<_PerksTab> createState() => _PerksTabState();
}

class _PerksTabState extends ConsumerState<_PerksTab> {
  List<model.Component> _languages = [];
  List<model.Component> _skills = [];
  Set<String> _reservedLanguageIds = {};
  Set<String> _reservedSkillIds = {};
  bool _isLoadingAuxData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuxData();
  }

  /// Load auxiliary data (languages, skills) that doesn't need reactive updates
  Future<void> _loadAuxData() async {
    try {
      setState(() {
        _isLoadingAuxData = true;
        _errorMessage = null;
      });

      // Load languages and skills for grant selections
      final languagesAsync =
          await ref.read(componentsByTypeProvider('language').future);
      final skillsAsync =
          await ref.read(componentsByTypeProvider('skill').future);

      if (mounted) {
        setState(() {
          _languages = languagesAsync;
          _skills = skillsAsync;
          _isLoadingAuxData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAuxData = false;
          _errorMessage = SheetStoryPerksTabText.failedToLoadData(e);
        });
      }
    }
  }

  Future<void> _handleSelectionChanged(Set<String> newSelection) async {
    // The PerksSelectionWidget handles database persistence when persistToDatabase is true
    // Just trigger a refresh of reserved languages/skills
    _refreshReservedEntries();
  }

  Future<void> _refreshReservedEntries() async {
    final db = ref.read(appDatabaseProvider);
    final languageIds = await db.getHeroComponentIds(widget.heroId, 'language');
    final skillIds = await db.getHeroComponentIds(widget.heroId, 'skill');
    if (mounted) {
      setState(() {
        _reservedLanguageIds = languageIds.toSet();
        _reservedSkillIds = skillIds.toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch perk entries reactively
    final selectedPerkIds = ref.watch(heroEntryIdsByTypeProvider(
      (heroId: widget.heroId, entryType: 'perk'),
    ));

    if (_isLoadingAuxData) {
      return const Center(
        child: CircularProgressIndicator(color: _perksColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade300)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAuxData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _perksColor,
                foregroundColor: FormTheme.textBright,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    return _buildContent(context, selectedPerkIds);
  }

  Widget _buildContent(BuildContext context, Set<String> selectedPerkIds) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NavigationTheme.cardBackgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FormTheme.borderDim),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _perksColor.withAlpha(38),
                      _perksColor.withAlpha(10),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _perksColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppIcon(PerkGroupIcons.tab,
                          color: _perksColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SheetStoryPerksTabText.headerTitle,
                            style: TextStyle(
                              color: FormTheme.textBright,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            SheetStoryPerksTabText.perksSelected(
                                selectedPerkIds.length),
                            style: TextStyle(
                                color: FormTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Perks selection widget
              PerksSelectionWidget(
                heroId: widget.heroId,
                selectedPerkIds: selectedPerkIds,
                onSelectionChanged: _handleSelectionChanged,
                onDirty: _refreshReservedEntries,
                languages: _languages,
                skills: _skills,
                reservedLanguageIds: _reservedLanguageIds,
                reservedSkillIds: _reservedSkillIds,
                showHeader: false,
                allowAddingNew: true,
                emptyStateMessage: SheetStoryPerksTabText.emptyState,
                persistToDatabase: true,
              ),
            ],
          ),
        ),
        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'perks_tab_fab',
            onPressed: () => _showAddPerkDialog(selectedPerkIds),
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: _perksColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _perksColor, width: 2),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showAddPerkDialog(Set<String> selectedPerkIds) {
    showDialog(
      context: context,
      builder: (context) => AddPerkDialog(
        heroId: widget.heroId,
        selectedPerkIds: selectedPerkIds,
        onPerkSelected: (perkId) async {
          Navigator.of(context).pop();
          final entries = ref.read(heroEntryRepositoryProvider);
          final existingPerks = await entries.listEntriesByType(
            widget.heroId,
            HeroEntryTypes.perk,
          );
          final isClaimed =
              ref.read(heroDuplicateGuardServiceProvider).isReserved(
                    candidateId: perkId,
                    entries: existingPerks,
                    entryType: HeroEntryTypes.perk,
                  );
          if (isClaimed) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(PerksWidgetText.perkAlreadyAdded),
                ),
              );
            }
            return;
          }
          await entries.addEntry(
            heroId: widget.heroId,
            entryType: HeroEntryTypes.perk,
            entryId: perkId,
            sourceType: HeroEntrySourceTypes.heroSheet,
            sourceId: HeroEntryTypes.perk,
            gainedBy: HeroEntryGainedBy.choice,
          );
          await ref.read(perkGrantsServiceProvider).ensureAllPerkGrantsApplied(
                heroId: widget.heroId,
              );
          await _refreshReservedEntries();
        },
      ),
    );
  }
}
