part of 'sheet_story.dart';

// Titles accent color
const _titlesColor = StoryTheme.titlesAccent;

// Titles Tab Widget
class _TitlesTab extends ConsumerStatefulWidget {
  final String heroId;

  const _TitlesTab({required this.heroId});

  @override
  ConsumerState<_TitlesTab> createState() => _TitlesTabState();
}

class _TitlesTabState extends ConsumerState<_TitlesTab> {
  List<Map<String, dynamic>> _availableTitles = [];
  Map<String, Map<String, dynamic>> _selectedTitles =
      {}; // titleId -> {title, selectedBenefitIndex}
  Map<String, String> _charChoices = {}; // choiceKey -> chosen characteristic
  Map<String, List<String>> _ancestryTraitSelections =
      {}; // titleId -> [traitIds]
  Map<String, String> _ancestryTraitSubChoices = {}; // titleId.traitId -> value
  Map<String, List<String>> _skillChoices = {}; // choiceKey -> [skillIds]
  Map<String, List<String>> _languageChoices = {}; // titleId -> [langIds]
  Map<String, String> _heroicAbilityChoices = {}; // titleId -> abilityId
  Map<String, String> _damageTypeChoices = {}; // titleId -> damageType
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load titles from JSON
      final titlesData = await rootBundle.loadString('data/story/titles.json');
      final titlesList = json.decode(titlesData) as List;
      _availableTitles = titlesList.cast<Map<String, dynamic>>();

      // Load selected titles for this hero from database
      final db = ref.read(appDatabaseProvider);
      final storedTitles = await db.getHeroComponentIds(widget.heroId, 'title');

      // Parse stored titles - format: "titleId:benefitIndex"
      _selectedTitles = {};
      for (final storedTitle in storedTitles) {
        final parts = storedTitle.split(':');
        if (parts.length == 2) {
          final titleId = parts[0];
          final benefitIndex = int.tryParse(parts[1]) ?? 0;
          final title = _availableTitles.firstWhere(
            (t) => t['id'] == titleId,
            orElse: () => <String, dynamic>{},
          );
          if (title.isNotEmpty) {
            _selectedTitles[titleId] = {
              'title': title,
              'selectedBenefitIndex': benefitIndex,
            };
          }
        }
      }

      // Load stored characteristic choices
      final service = ref.read(titleGrantsServiceProvider);
      _charChoices =
          await service.getAllCharacteristicChoices(heroId: widget.heroId);

      // Load stored ancestry trait selections
      _ancestryTraitSelections = {};
      _ancestryTraitSubChoices =
          await service.getAllAncestryTraitSubChoices(heroId: widget.heroId);
      for (final titleId in _selectedTitles.keys) {
        final traitIds = await service.getAncestryTraitSelections(
            heroId: widget.heroId, titleId: titleId);
        if (traitIds.isNotEmpty) {
          _ancestryTraitSelections[titleId] = traitIds;
        }
      }

      // Load stored skill choices
      _skillChoices = {};
      for (final titleId in _selectedTitles.keys) {
        // Check each potential group key
        for (final suffix in [
          '',
          '__interpersonal',
          '__lore',
          '__crafting',
          '__exploration'
        ]) {
          final key = '$titleId$suffix';
          final chosen = await service.getSkillChoice(
            heroId: widget.heroId,
            titleId: titleId,
            group: suffix.isEmpty ? null : suffix.substring(2),
          );
          if (chosen.isNotEmpty) {
            _skillChoices[key] = chosen;
          }
        }
        // Also check without group (any skill)
        final anyChosen = await service.getSkillChoice(
            heroId: widget.heroId, titleId: titleId);
        if (anyChosen.isNotEmpty && !_skillChoices.containsKey(titleId)) {
          _skillChoices[titleId] = anyChosen;
        }
      }

      // Load stored language choices
      _languageChoices = {};
      for (final titleId in _selectedTitles.keys) {
        final chosen = await service.getLanguageChoice(
            heroId: widget.heroId, titleId: titleId);
        if (chosen.isNotEmpty) {
          _languageChoices[titleId] = chosen;
        }
      }

      // Load stored heroic ability choices
      _heroicAbilityChoices = {};
      for (final titleId in _selectedTitles.keys) {
        final chosen = await service.getHeroicAbilityChoice(
            heroId: widget.heroId, titleId: titleId);
        if (chosen != null) {
          _heroicAbilityChoices[titleId] = chosen;
        }
      }

      // Load stored damage type choices
      _damageTypeChoices =
          await service.getAllDamageTypeChoices(heroId: widget.heroId);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = SheetStoryTitlesTabText.failedToLoadTitles(e);
      });
    }
  }

  Future<void> _addTitle(String titleId, int benefitIndex) async {
    if (_selectedTitles.containsKey(titleId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(SheetStoryTitlesTabText.titleAlreadyAdded)),
        );
      }
      return;
    }
    try {
      final db = ref.read(appDatabaseProvider);
      final title = _availableTitles.firstWhere((t) => t['id'] == titleId);

      _selectedTitles[titleId] = {
        'title': title,
        'selectedBenefitIndex': benefitIndex,
      };

      // Store as "titleId:benefitIndex"
      final updatedIds = _selectedTitles.entries
          .map((e) => '${e.key}:${e.value['selectedBenefitIndex']}')
          .toList();

      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'title',
        componentIds: updatedIds,
      );

      // Apply title grants (abilities, etc.)
      final service = ref.read(titleGrantsServiceProvider);
      await service.applyTitleGrants(
        heroId: widget.heroId,
        selectedTitleIds: updatedIds,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SheetStoryTitlesTabText.failedToAddTitle(e))),
        );
      }
    }
  }

  Future<void> _removeTitle(String titleId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      _selectedTitles.remove(titleId);

      final updatedIds = _selectedTitles.entries
          .map((e) => '${e.key}:${e.value['selectedBenefitIndex']}')
          .toList();

      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'title',
        componentIds: updatedIds,
      );

      // Reapply title grants with updated list
      final service = ref.read(titleGrantsServiceProvider);
      await service.applyTitleGrants(
        heroId: widget.heroId,
        selectedTitleIds: updatedIds,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(SheetStoryTitlesTabText.failedToRemoveTitle(e))),
        );
      }
    }
  }

  Future<void> _changeBenefit(String titleId, int newBenefitIndex) async {
    if (_selectedTitles.containsKey(titleId)) {
      _selectedTitles[titleId]!['selectedBenefitIndex'] = newBenefitIndex;

      final db = ref.read(appDatabaseProvider);
      final updatedIds = _selectedTitles.entries
          .map((e) => '${e.key}:${e.value['selectedBenefitIndex']}')
          .toList();

      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'title',
        componentIds: updatedIds,
      );

      // Reapply title grants with new benefit selection
      final service = ref.read(titleGrantsServiceProvider);
      await service.applyTitleGrants(
        heroId: widget.heroId,
        selectedTitleIds: updatedIds,
      );

      if (mounted) setState(() {});
    }
  }

  void _showAddTitleDialog() {
    final unselectedTitles = _availableTitles
        .where((title) => !_selectedTitles.containsKey(title['id']))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AddTitleDialog(
        availableTitles: unselectedTitles,
        onTitleSelected: (titleId, benefitIndex) {
          _addTitle(titleId, benefitIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openProgressPage() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => TitleProgressPage(
          heroId: widget.heroId,
          earnedTitleIds: _selectedTitles.keys.toSet(),
          onTitleEarned: (titleId) {
            // When a title is earned from the progress page, show the add dialog
            // pre-filtered to that title so the user can pick a benefit.
            final title = _availableTitles.firstWhere(
              (t) => t['id'] == titleId,
              orElse: () => <String, dynamic>{},
            );
            if (title.isNotEmpty) {
              final benefits = title['benefits'] as List? ?? [];
              // Count chooseable (non-auto) benefits
              final choiceCount = benefits
                  .where((b) => b is Map<String, dynamic> && b['auto'] != true)
                  .length;
              if (choiceCount <= 1) {
                // Find the single chooseable index, or -1 if all auto
                final choiceIdx = benefits.indexWhere(
                    (b) => b is Map<String, dynamic> && b['auto'] != true);
                _addTitle(titleId, choiceIdx);
              } else {
                // Show benefit selection via the add dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AddTitleDialog(
                    availableTitles: [title],
                    onTitleSelected: (id, benefitIndex) {
                      _addTitle(id, benefitIndex);
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }
            }
          },
        ),
      ),
    )
        .then((_) {
      // Refresh data when returning from progress page
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _titlesColor),
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
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _titlesColor,
                foregroundColor: Colors.black,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    // Group titles by echelon
    final groupedTitles = <int, List<MapEntry<String, Map<String, dynamic>>>>{};
    for (final entry in _selectedTitles.entries) {
      final echelon = entry.value['title']['echelon'] as int? ?? 1;
      groupedTitles.putIfAbsent(echelon, () => []).add(entry);
    }

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
                      _titlesColor.withAlpha(38),
                      _titlesColor.withAlpha(10),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _titlesColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppIcon(TitleIcons.tab,
                          color: _titlesColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            SheetStoryTitlesTabText.titlesTitle,
                            style: TextStyle(
                              color: FormTheme.textBright,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            SheetStoryTitlesTabText.titlesEarned(
                                _selectedTitles.length),
                            style: TextStyle(
                                color: FormTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Track Progress banner
              GestureDetector(
                onTap: _openProgressPage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _titlesColor.withAlpha(16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _titlesColor.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.track_changes, color: _titlesColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Track Title Progress',
                              style: TextStyle(
                                color: _titlesColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View prerequisites and track your journey',
                              style: TextStyle(
                                  color: FormTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: _titlesColor.withAlpha(180), size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedTitles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 48, color: FormTheme.borderLight),
                        const SizedBox(height: 16),
                        Text(
                          SheetStoryTitlesTabText.noTitlesSelected,
                          style: TextStyle(color: FormTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groupedTitles.entries.map((group) {
                  final echelon = group.key;
                  final titles = group.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _titlesColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppIcon(TitleIcons.fromEchelon(echelon),
                                color: _titlesColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              SheetStoryTitlesTabText.echelonLabel(echelon),
                              style: const TextStyle(
                                color: _titlesColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...titles.map((entry) =>
                          _buildTitleCard(context, entry.key, entry.value)),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'titles_tab_fab',
            onPressed: _showAddTitleDialog,
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: _titlesColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _titlesColor, width: 2),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleCard(
      BuildContext context, String titleId, Map<String, dynamic> data) {
    final title = data['title'] as Map<String, dynamic>;
    final selectedBenefitIndex = data['selectedBenefitIndex'] as int;
    final benefits = title['benefits'] as List? ?? [];
    final echelon = title['echelon'] as int? ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _titlesColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppIcon(TitleIcons.fromEchelon(echelon),
                      color: _titlesColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title['name'] as String? ??
                            SheetStoryTitlesTabText.unknown,
                        style: const TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (title['prerequisite'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          SheetStoryTitlesTabText.prerequisite(
                              title['prerequisite'].toString()),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: FormTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                  onPressed: () => _removeTitle(titleId),
                  tooltip: SheetStoryTitlesTabText.removeTitleTooltip,
                ),
              ],
            ),
            if (title['description_text'] != null) ...[
              const SizedBox(height: 12),
              Text(
                title['description_text'] as String,
                style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            // Title-level grants (characteristic increases, languages, etc.)
            ..._buildTitleLevelGrants(context, titleId, title),
            // Separate auto benefits from chooseable ones
            ..._buildBenefitsSections(
                context, titleId, benefits, selectedBenefitIndex),
            if (title['special'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Colors.blue.shade300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        SheetStoryTitlesTabText.special(
                            title['special'].toString()),
                        style: TextStyle(
                            color: FormTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the benefits display sections for a title card.
  /// Auto benefits are shown first as "Granted", then the chosen benefit
  /// (if any chooseable benefits exist) with a change button.
  List<Widget> _buildBenefitsSections(
    BuildContext context,
    String titleId,
    List benefits,
    int selectedBenefitIndex,
  ) {
    final autoBenefits = <MapEntry<int, Map<String, dynamic>>>[];
    final choiceBenefits = <MapEntry<int, Map<String, dynamic>>>[];

    for (int i = 0; i < benefits.length; i++) {
      final b = benefits[i];
      if (b is! Map<String, dynamic>) continue;
      if (b['auto'] == true) {
        autoBenefits.add(MapEntry(i, b));
      } else {
        choiceBenefits.add(MapEntry(i, b));
      }
    }

    final widgets = <Widget>[];

    // Show auto benefits
    if (autoBenefits.isNotEmpty) {
      widgets.add(
        Text(
          'Granted Benefits',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: FormTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      for (final entry in autoBenefits) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withAlpha(51)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade400),
                    const SizedBox(width: 6),
                    Text(
                      entry.value['name'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildBenefitContent(context, entry.value, titleId: titleId),
              ],
            ),
          ),
        );
      }
    }

    // Show chosen benefit (if there are chooseable benefits and the
    // stored index actually points to a non-auto benefit)
    final hasValidChoice = selectedBenefitIndex >= 0 &&
        selectedBenefitIndex < benefits.length &&
        !((benefits[selectedBenefitIndex] is Map<String, dynamic>) &&
            (benefits[selectedBenefitIndex] as Map<String, dynamic>)['auto'] ==
                true);

    if (choiceBenefits.isNotEmpty && hasValidChoice) {
      widgets.add(
        Text(
          SheetStoryTitlesTabText.selectedBenefit,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: FormTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      if (true) {
        widgets.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _titlesColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _titlesColor.withAlpha(51)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (benefits[selectedBenefitIndex] is Map<String, dynamic> &&
                    (benefits[selectedBenefitIndex] as Map)['name'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      (benefits[selectedBenefitIndex] as Map)['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _titlesColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                _buildBenefitContent(context, benefits[selectedBenefitIndex],
                    titleId: titleId),
                if (choiceBenefits.length > 1) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        _showChangeBenefitDialog(titleId, benefits),
                    style: TextButton.styleFrom(
                      foregroundColor: _titlesColor,
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text(SheetStoryTitlesTabText.changeBenefit),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Build widgets for title-level grants (not inside a benefit).
  List<Widget> _buildTitleLevelGrants(
    BuildContext context,
    String titleId,
    Map<String, dynamic> title,
  ) {
    final grants = title['grants'] as List?;
    if (grants == null || grants.isEmpty) return [];

    final widgets = <Widget>[];
    for (final grant in grants) {
      final grantMap = _titleGrantViewMap(grant);
      if (grantMap == null) continue;
      final type = grantMap['type'] as String?;
      if (type == 'characteristic_increase') {
        widgets.add(_buildCharacteristicPicker(context, titleId, grantMap));
      } else if (type == 'languages') {
        final specific =
            (grantMap['specific'] as List?)?.whereType<String>().toList();
        if (specific != null && specific.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.translate, size: 16, color: Colors.teal.shade300),
                  const SizedBox(width: 4),
                  Text(
                    'Grants: ${specific.map((l) => l[0].toUpperCase() + l.substring(1)).join(', ')}',
                    style: TextStyle(color: Colors.teal.shade300, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    if (widgets.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Map<String, dynamic>? _titleGrantViewMap(dynamic rawGrant) {
    if (rawGrant is! Map) return null;
    final grantMap = rawGrant.cast<String, dynamic>();
    if (!grantMap.containsKey('kind')) return grantMap;

    try {
      return _legacyTitleGrantView(CanonicalGrant.fromJson(grantMap));
    } catch (_) {
      return grantMap;
    }
  }

  Map<String, dynamic>? _legacyTitleGrantView(CanonicalGrant grant) {
    switch (grant) {
      case CanonicalChoiceGrant():
        return switch (grant.choiceType) {
          'characteristic' => {
              'type': 'characteristic_increase',
              'choices': grant.options,
              'value': _canonicalPayloadInt(grant, 'value') ?? 1,
              if (_canonicalPayloadInt(grant, 'max') != null)
                'max': _canonicalPayloadInt(grant, 'max'),
              if (_canonicalPayloadString(grant, 'tag') != null)
                'tag': _canonicalPayloadString(grant, 'tag'),
            },
          'ancestry_trait' => {
              'type': 'ancestry_points',
              if (_canonicalPayloadString(grant, 'ancestry') != null)
                'ancestry': _canonicalPayloadString(grant, 'ancestry'),
              'value': _canonicalPayloadInt(grant, 'points') ?? grant.count,
            },
          'skill' => {
              'type': 'skill_choice',
              if (grant.groups.isNotEmpty) 'group': grant.groups.first,
              'count': grant.count,
              if (_canonicalPayloadString(grant, 'mode') != null)
                'mode': _canonicalPayloadString(grant, 'mode'),
            },
          'language' => {
              'type': 'languages',
              'count': grant.count,
            },
          'ability' => {
              'type': 'heroic_ability_choice',
              'count': grant.count,
              if (_canonicalPayloadString(grant, 'source') != null)
                'source': _canonicalPayloadString(grant, 'source'),
            },
          'damage_type' => {
              'type': 'damage_immunity',
              'damage_type': 'choose',
              'damage_type_options': grant.options,
              if (_canonicalPayloadString(grant, 'value_source') != null)
                'value_source': _canonicalPayloadString(grant, 'value_source'),
              if (_canonicalPayloadInt(grant, 'value') != null)
                'value': _canonicalPayloadInt(grant, 'value'),
              if (_canonicalPayloadString(grant, 'note') != null)
                'note': _canonicalPayloadString(grant, 'note'),
            },
          _ => null,
        };

      case CanonicalEntryGrant():
        return switch (grant.entryType) {
          HeroEntryTypes.conditionImmunity => {
              'type': 'condition_immunity',
              'condition': grant.entryId,
            },
          HeroEntryTypes.itemPrerequisite => {
              'type': 'item_prerequisite',
              'category': grant.payload?['category'],
              'tag': grant.payload?['tag'],
              'count': grant.payload?['count'],
            },
          HeroEntryTypes.skill => {
              'type': 'skill_choice',
              'skill': grant.entryId,
              'count': grant.payload?['count'] ?? 1,
              if (grant.payload?['mode'] != null)
                'mode': grant.payload?['mode'],
            },
          HeroEntryTypes.language => {
              'type': 'languages',
              'count': grant.payload?['count'] ?? 1,
              'specific': [grant.entryId],
            },
          _ => null,
        };

      case CanonicalStatModGrant():
        final value = grant.modifications.isEmpty
            ? null
            : grant.modifications.first.baseValue;
        return {
          'type': grant.entryId ?? grant.stat,
          if (value != null) 'value': value,
        };

      case CanonicalResistanceGrant():
        return {
          'type': 'damage_immunity',
          'damage_type': grant.damageType,
          if (grant.dynamicImmunity != null)
            'value_source': grant.dynamicImmunity,
          if (grant.immunity != 0) 'value': grant.immunity,
        };

      case CanonicalTokenGrant():
      case CanonicalTreasureGrant():
      case CanonicalEquipmentBonusesGrant():
        return null;
    }
  }

  String? _canonicalPayloadString(CanonicalChoiceGrant grant, String key) {
    final value = grant.payload?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  int? _canonicalPayloadInt(CanonicalChoiceGrant grant, String key) {
    final value = grant.payload?[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Build an interactive characteristic choice dropdown for a title grant.
  Widget _buildCharacteristicPicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final choices =
        (grant['choices'] as List?)?.whereType<String>().toList() ?? [];
    final value = (grant['value'] as num?)?.toInt() ?? 1;
    final tag = grant['tag'] as String?;

    // Read the stored choice from _charChoices cache
    final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
    final selected = _charChoices[choiceKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 16, color: Colors.amber.shade300),
          const SizedBox(width: 6),
          Text(
            '+$value ',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: StoryTheme.cardBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected != null
                      ? Colors.amber.shade700
                      : Colors.orange.shade700,
                  width: selected != null ? 1 : 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  dropdownColor: NavigationTheme.cardBackgroundDark,
                  hint: Text(
                    'Choose characteristic…',
                    style:
                        TextStyle(color: Colors.orange.shade300, fontSize: 12),
                  ),
                  style: TextStyle(color: Colors.amber.shade200, fontSize: 13),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.amber.shade400, size: 20),
                  items: choices.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c[0].toUpperCase() + c.substring(1),
                        style: TextStyle(
                            color: Colors.amber.shade200, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    _onCharacteristicChosen(titleId, newValue, tag: tag);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle characteristic choice selection: save, re-apply grants, refresh.
  Future<void> _onCharacteristicChosen(
    String titleId,
    String characteristic, {
    String? tag,
  }) async {
    final service = ref.read(titleGrantsServiceProvider);
    await service.setCharacteristicChoice(
      heroId: widget.heroId,
      titleId: titleId,
      characteristic: characteristic,
      tag: tag,
    );

    // Re-apply all title grants with updated choice
    await _reapplyGrants();

    // Update local cache
    final choiceKey = tag != null ? '${titleId}__$tag' : titleId;
    _charChoices[choiceKey] = characteristic;

    if (mounted) setState(() {});
  }

  Widget _buildBenefitContent(BuildContext context, dynamic benefit,
      {String? titleId}) {
    if (benefit is! Map<String, dynamic>) return const SizedBox.shrink();

    final description = benefit['description'] as String?;
    final ability = benefit['ability'] as String?;
    final grantsRaw = benefit['grants'];
    // Normalize grants to a List (can be Map or List)
    final grants =
        grantsRaw is List ? grantsRaw : (grantsRaw is Map ? [grantsRaw] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null && description.isNotEmpty)
          Text(description,
              style: TextStyle(color: FormTheme.textSecondary, fontSize: 13)),
        if (ability != null && ability.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAbilityCard(ability),
        ],
        if (grants != null && grants.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...grants.map((grant) {
            final grantMap = _titleGrantViewMap(grant);
            if (grantMap != null) {
              final type = grantMap['type'] as String?;
              if (type == 'characteristic_increase' && titleId != null) {
                return _buildCharacteristicPicker(context, titleId, grantMap);
              }
              if (type == 'ancestry_points' && titleId != null) {
                return _buildAncestryPointsPicker(context, titleId, grantMap);
              }
              if (type == 'skill_choice' &&
                  titleId != null &&
                  grantMap['skill'] == null) {
                return _buildSkillChoicePicker(context, titleId, grantMap);
              }
              if (type == 'languages' &&
                  titleId != null &&
                  grantMap['specific'] == null) {
                return _buildLanguageChoicePicker(context, titleId, grantMap);
              }
              if (type == 'heroic_ability_choice' && titleId != null) {
                return _buildHeroicAbilityPicker(context, titleId, grantMap);
              }
              if (type == 'damage_immunity' && titleId != null) {
                final damageType = grantMap['damage_type'] as String?;
                if (damageType == 'choose') {
                  return _buildDamageImmunityPicker(context, titleId, grantMap);
                }
                return _buildDamageImmunityBadge(grantMap);
              }
              if (type == 'condition_immunity') {
                final condition = grantMap['condition'] as String? ?? '';
                return _buildConditionImmunityBadge(condition);
              }
              if (type == 'item_prerequisite') {
                final category = grantMap['category'] as String? ?? '';
                final tag = grantMap['tag'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2,
                          size: 16, color: Colors.purple.shade300),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          SheetStoryTitlesTabText.itemPrerequisite(
                              category, tag),
                          style: TextStyle(
                              color: Colors.purple.shade300, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final value = grantMap['value'];
              if (type != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 16, color: Colors.teal.shade300),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          SheetStoryTitlesTabText.grantsLabel(
                              _formatGrant(type, value)),
                          style: TextStyle(
                            color: Colors.teal.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          }),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Ancestry Points Picker
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAncestryPointsPicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final ancestry = grant['ancestry'] as String? ?? '';
    final points = (grant['value'] as num?)?.toInt() ?? 0;
    final selected = _ancestryTraitSelections[titleId] ?? [];
    final hasSelection = selected.isNotEmpty;
    final ancestryLabel = ancestry.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openAncestryTraitsDialog(titleId, ancestry, points),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasSelection
                ? _titlesColor.withAlpha(20)
                : Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? _titlesColor.withAlpha(80)
                  : Colors.orange.withAlpha(80),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: hasSelection ? _titlesColor : Colors.orange.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SheetStoryTitlesTabText.ancestryTraitsTitle(
                          ancestryLabel),
                      style: TextStyle(
                        color: hasSelection
                            ? _titlesColor
                            : Colors.orange.shade300,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      hasSelection
                          ? SheetStoryTitlesTabText.traitsSelected(
                              selected.length)
                          : SheetStoryTitlesTabText.noTraitsSelected,
                      style: TextStyle(
                        color: hasSelection
                            ? FormTheme.textSecondary
                            : Colors.orange.shade200,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${points}pts',
                style: TextStyle(
                  color: hasSelection ? _titlesColor : Colors.orange.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: hasSelection ? _titlesColor : Colors.orange.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAncestryTraitsDialog(
    String titleId,
    String ancestryId,
    int pointsBudget,
  ) async {
    // Filter sub-choices for this title
    final subChoices = <String, String>{};
    for (final entry in _ancestryTraitSubChoices.entries) {
      if (entry.key.startsWith('$titleId.')) {
        final traitId = entry.key.substring(titleId.length + 1);
        subChoices[traitId] = entry.value;
      }
    }

    final result = await showDialog<TitleAncestryTraitsResult>(
      context: context,
      builder: (context) => TitleAncestryTraitsDialog(
        heroId: widget.heroId,
        titleId: titleId,
        ancestryId: ancestryId,
        pointsBudget: pointsBudget,
        initialSelectedTraitIds: _ancestryTraitSelections[titleId] ?? [],
        initialSubChoices: subChoices,
      ),
    );

    if (result == null) return;

    final service = ref.read(titleGrantsServiceProvider);

    // Save trait selections
    await service.setAncestryTraitSelections(
      heroId: widget.heroId,
      titleId: titleId,
      traitIds: result.selectedTraitIds,
    );

    // Save sub-choices
    for (final entry in result.subChoices.entries) {
      await service.setAncestryTraitSubChoice(
        heroId: widget.heroId,
        titleId: titleId,
        traitId: entry.key,
        value: entry.value,
      );
    }

    // Re-apply grants
    await _reapplyGrants();

    // Update local cache
    _ancestryTraitSelections[titleId] = result.selectedTraitIds;
    for (final entry in result.subChoices.entries) {
      _ancestryTraitSubChoices['$titleId.${entry.key}'] = entry.value;
    }

    if (mounted) setState(() {});
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Skill Choice Picker (group-based or any)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSkillChoicePicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final group = grant['group'] as String?;
    final count = (grant['count'] as num?)?.toInt() ?? 1;
    final choiceKey = group != null ? '${titleId}__$group' : titleId;
    final chosen = _skillChoices[choiceKey] ?? [];
    final hasSelection = chosen.isNotEmpty;

    final label = group != null
        ? SheetStoryTitlesTabText.chooseSkillFromGroup(group)
        : SheetStoryTitlesTabText.chooseAnySkill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openSkillPicker(titleId, grant),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasSelection
                ? Colors.blue.withAlpha(20)
                : Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? Colors.blue.withAlpha(80)
                  : Colors.orange.withAlpha(80),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.school,
                size: 16,
                color: hasSelection
                    ? Colors.blue.shade300
                    : Colors.orange.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSelection
                      ? chosen.map((s) => s.replaceAll('_', ' ')).join(', ')
                      : '$label ($count)',
                  style: TextStyle(
                    color: hasSelection
                        ? Colors.blue.shade300
                        : Colors.orange.shade300,
                    fontWeight:
                        hasSelection ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.edit,
                size: 16,
                color: hasSelection
                    ? Colors.blue.shade300
                    : Colors.orange.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSkillPicker(
    String titleId,
    Map<String, dynamic> grant,
  ) async {
    final group = grant['group'] as String?;
    final count = (grant['count'] as num?)?.toInt() ?? 1;
    final choiceKey = group != null ? '${titleId}__$group' : titleId;

    // Load skills
    final allSkills = await SkillDataService().loadSkills();
    final filteredSkills = group != null
        ? allSkills.where((s) => s.group == group.toLowerCase()).toList()
        : allSkills;

    if (!mounted) return;

    final options = filteredSkills
        .map((s) => SearchableOption<String>(
              label: s.name,
              value: s.id,
              subtitle: s.group.isNotEmpty
                  ? '${s.group[0].toUpperCase()}${s.group.substring(1)}'
                  : null,
            ))
        .toList();

    // For single-pick, use searchable picker
    if (count == 1) {
      final current = (_skillChoices[choiceKey] ?? []).firstOrNull;
      final result = await showSearchablePicker<String>(
        context: context,
        title: group != null
            ? SheetStoryTitlesTabText.chooseSkillFromGroup(group)
            : SheetStoryTitlesTabText.chooseAnySkill,
        options: options,
        selected: current,
        accentColor: Colors.blue.shade300,
        icon: Icons.school,
      );
      if (result == null || result.value == null) return;

      final service = ref.read(titleGrantsServiceProvider);
      await service.setSkillChoice(
        heroId: widget.heroId,
        titleId: titleId,
        skillIds: [result.value!],
        group: group,
      );
      await _reapplyGrants();
      _skillChoices[choiceKey] = [result.value!];
      if (mounted) setState(() {});
    } else {
      // Multi-pick: show picker repeatedly for each slot
      final chosen = <String>[];
      for (int i = 0; i < count; i++) {
        if (!mounted) return;
        final result = await showSearchablePicker<String>(
          context: context,
          title: '${SheetStoryTitlesTabText.chooseAnySkill} (${i + 1}/$count)',
          options: options.where((o) => !chosen.contains(o.value)).toList(),
          accentColor: Colors.blue.shade300,
          icon: Icons.school,
        );
        if (result == null || result.value == null) break;
        chosen.add(result.value!);
      }
      if (chosen.isEmpty) return;

      final service = ref.read(titleGrantsServiceProvider);
      await service.setSkillChoice(
        heroId: widget.heroId,
        titleId: titleId,
        skillIds: chosen,
        group: group,
      );
      await _reapplyGrants();
      _skillChoices[choiceKey] = chosen;
      if (mounted) setState(() {});
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Language Choice Picker
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildLanguageChoicePicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final count = (grant['count'] as num?)?.toInt() ?? 1;
    final chosen = _languageChoices[titleId] ?? [];
    final hasSelection = chosen.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openLanguagePicker(titleId, count),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasSelection
                ? Colors.teal.withAlpha(20)
                : Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? Colors.teal.withAlpha(80)
                  : Colors.orange.withAlpha(80),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.translate,
                size: 16,
                color: hasSelection
                    ? Colors.teal.shade300
                    : Colors.orange.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSelection
                      ? chosen.map((l) => l.replaceAll('_', ' ')).join(', ')
                      : SheetStoryTitlesTabText.chooseLanguages(count),
                  style: TextStyle(
                    color: hasSelection
                        ? Colors.teal.shade300
                        : Colors.orange.shade300,
                    fontWeight:
                        hasSelection ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.edit,
                size: 16,
                color: hasSelection
                    ? Colors.teal.shade300
                    : Colors.orange.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguagePicker(String titleId, int count) async {
    final db = ref.read(appDatabaseProvider);
    final languages = await db.getComponentsByType('language');

    if (!mounted) return;

    final options = languages.map((l) {
      final data = l.dataJson.isNotEmpty
          ? json.decode(l.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};
      final langType = data['language_type'] as String?;
      return SearchableOption<String>(
        label: l.name,
        value: l.id,
        subtitle: langType != null
            ? '${langType[0].toUpperCase()}${langType.substring(1)}'
            : null,
      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final chosen = <String>[];
    for (int i = 0; i < count; i++) {
      if (!mounted) return;
      final result = await showSearchablePicker<String>(
        context: context,
        title:
            '${SheetStoryTitlesTabText.chooseLanguageHint} (${i + 1}/$count)',
        options: options.where((o) => !chosen.contains(o.value)).toList(),
        accentColor: Colors.teal.shade300,
        icon: Icons.translate,
      );
      if (result == null || result.value == null) break;
      chosen.add(result.value!);
    }
    if (chosen.isEmpty) return;

    final service = ref.read(titleGrantsServiceProvider);
    await service.setLanguageChoice(
      heroId: widget.heroId,
      titleId: titleId,
      languageIds: chosen,
    );
    await _reapplyGrants();
    _languageChoices[titleId] = chosen;
    if (mounted) setState(() {});
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Heroic Ability Choice Picker
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeroicAbilityPicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final chosenId = _heroicAbilityChoices[titleId];
    final hasSelection = chosenId != null && chosenId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openHeroicAbilityPicker(titleId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasSelection
                    ? Colors.purple.withAlpha(20)
                    : Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasSelection
                      ? Colors.purple.withAlpha(80)
                      : Colors.orange.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    size: 16,
                    color: hasSelection
                        ? Colors.purple.shade300
                        : Colors.orange.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasSelection
                          ? SheetStoryTitlesTabText.heroicAbilityLabel
                          : SheetStoryTitlesTabText.chooseHeroicAbility,
                      style: TextStyle(
                        color: hasSelection
                            ? Colors.purple.shade300
                            : Colors.orange.shade300,
                        fontWeight:
                            hasSelection ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: hasSelection
                        ? Colors.purple.shade300
                        : Colors.orange.shade300,
                  ),
                ],
              ),
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(height: 4),
            _buildAbilityCard(chosenId),
          ],
        ],
      ),
    );
  }

  Future<void> _openHeroicAbilityPicker(String titleId) async {
    // Load all heroic abilities from DB (cost >= 3 or keyword "heroic")
    final db = ref.read(appDatabaseProvider);
    final allAbilities = await db.getComponentsByType('ability');

    if (!mounted) return;

    // Filter to heroic abilities (resource_value >= 3, which typically indicates heroic tier)
    final heroicAbilities = allAbilities.where((a) {
      final data = a.dataJson.isNotEmpty
          ? json.decode(a.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};
      final cost = data['resource_value'];
      if (cost is int && cost >= 3) return true;
      // Also check the keywords for "heroic"
      final kw = data['keywords'];
      final keywords = kw is String
          ? kw.toLowerCase()
          : (kw is List ? kw.join('/').toLowerCase() : '');
      if (keywords.contains('heroic')) return true;
      return false;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final options = heroicAbilities.map((a) {
      final data = a.dataJson.isNotEmpty
          ? json.decode(a.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};
      final resource = data['resource'] as String?;
      final cost = data['resource_value'];
      final subtitle =
          resource != null && cost != null ? '$resource $cost' : null;
      return SearchableOption<String>(
        label: a.name,
        value: a.id,
        subtitle: subtitle,
      );
    }).toList();

    final current = _heroicAbilityChoices[titleId];
    final result = await showSearchablePicker<String>(
      context: context,
      title: SheetStoryTitlesTabText.chooseHeroicAbility,
      options: options,
      selected: current,
      accentColor: Colors.purple.shade300,
      icon: Icons.flash_on,
      autofocusSearch: true,
    );

    if (result == null || result.value == null) return;

    final service = ref.read(titleGrantsServiceProvider);
    await service.setHeroicAbilityChoice(
      heroId: widget.heroId,
      titleId: titleId,
      abilityId: result.value!,
    );
    await _reapplyGrants();
    _heroicAbilityChoices[titleId] = result.value!;
    if (mounted) setState(() {});
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Damage Immunity Picker & Badges
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildDamageImmunityPicker(
    BuildContext context,
    String titleId,
    Map<String, dynamic> grant,
  ) {
    final chosen = _damageTypeChoices[titleId];
    final hasSelection = chosen != null && chosen.isNotEmpty;
    final valueSource = grant['value_source']?.toString();
    final staticValue = grant['value'];

    String subtitle;
    if (hasSelection) {
      final label = chosen[0].toUpperCase() + chosen.substring(1);
      if (valueSource == 'level') {
        subtitle = SheetStoryTitlesTabText.damageImmunityLevel(label);
      } else if (valueSource == 'highest_characteristic') {
        subtitle = SheetStoryTitlesTabText.damageImmunityHighestChar(label);
      } else if (staticValue != null) {
        subtitle =
            SheetStoryTitlesTabText.damageImmunityStatic(label, staticValue);
      } else {
        subtitle = label;
      }
    } else {
      subtitle = SheetStoryTitlesTabText.chooseDamageTypeHint;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openDamageTypePicker(titleId, grant),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasSelection
                ? Colors.red.withAlpha(20)
                : Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? Colors.red.withAlpha(80)
                  : Colors.orange.withAlpha(80),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield,
                size: 16,
                color:
                    hasSelection ? Colors.red.shade300 : Colors.orange.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SheetStoryTitlesTabText.damageImmunityTitle,
                      style: TextStyle(
                        color: hasSelection
                            ? Colors.red.shade300
                            : Colors.orange.shade300,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: hasSelection
                            ? FormTheme.textSecondary
                            : Colors.orange.shade200,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                size: 16,
                color:
                    hasSelection ? Colors.red.shade300 : Colors.orange.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDamageTypePicker(
    String titleId,
    Map<String, dynamic> grant,
  ) async {
    final options = (grant['damage_type_options'] as List?)
            ?.cast<String>()
            .map((dt) => SearchableOption<String>(
                  label: dt[0].toUpperCase() + dt.substring(1),
                  value: dt,
                ))
            .toList() ??
        [];

    final current = _damageTypeChoices[titleId];
    final result = await showSearchablePicker<String>(
      context: context,
      title: SheetStoryTitlesTabText.chooseDamageType,
      options: options,
      selected: current,
      accentColor: Colors.red.shade300,
      icon: Icons.shield,
    );

    if (result == null || result.value == null) return;

    final service = ref.read(titleGrantsServiceProvider);
    await service.setDamageTypeChoice(
      heroId: widget.heroId,
      titleId: titleId,
      damageType: result.value!,
    );
    await _reapplyGrants();
    _damageTypeChoices[titleId] = result.value!;
    if (mounted) setState(() {});
  }

  Widget _buildDamageImmunityBadge(Map<String, dynamic> grant) {
    final damageType = grant['damage_type'] as String? ?? '';
    final valueSource = grant['value_source']?.toString();
    final staticValue = grant['value'];
    final label = damageType[0].toUpperCase() + damageType.substring(1);

    String text;
    if (valueSource == 'level') {
      text = SheetStoryTitlesTabText.damageImmunityLevel(label);
    } else if (valueSource == 'highest_characteristic') {
      text = SheetStoryTitlesTabText.damageImmunityHighestChar(label);
    } else if (staticValue != null) {
      text = SheetStoryTitlesTabText.damageImmunityStatic(label, staticValue);
    } else {
      text = '$label immunity';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.shield, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionImmunityBadge(String condition) {
    final label = condition[0].toUpperCase() + condition.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, size: 16, color: Colors.teal.shade300),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              SheetStoryTitlesTabText.conditionImmunity(label),
              style: TextStyle(color: Colors.teal.shade300, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Shared Helpers
  // ════════════════════════════════════════════════════════════════════════════

  /// Re-apply all title grants after a choice change.
  Future<void> _reapplyGrants() async {
    final service = ref.read(titleGrantsServiceProvider);
    final updatedIds = _selectedTitles.entries
        .map((e) => '${e.key}:${e.value['selectedBenefitIndex']}')
        .toList();
    await service.applyTitleGrants(
      heroId: widget.heroId,
      selectedTitleIds: updatedIds,
    );
  }

  String _formatGrant(String type, dynamic value) {
    switch (type) {
      case 'renown':
        return SheetStoryTitlesTabText.plusRenown(value);
      case 'wealth':
        return SheetStoryTitlesTabText.plusWealth(value);
      case 'followers_cap':
        return SheetStoryTitlesTabText.plusFollowersCap(value);
      case 'skill_choice':
        return SheetStoryTitlesTabText.chooseSkill(value);
      case 'languages':
        return SheetStoryTitlesTabText.language(value);
      default:
        return SheetStoryTitlesTabText.grantFallback(type, value);
    }
  }

  Widget _buildAbilityCard(String abilityNameOrId) {
    final abilityAsync = ref.watch(abilityByNameProvider(abilityNameOrId));

    return abilityAsync.when(
      data: (ability) {
        if (ability == null) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: Colors.purple.shade300),
                const SizedBox(width: 4),
                Text(
                  SheetStoryTitlesTabText.abilityLabel(abilityNameOrId),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade300,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }
        return AbilityExpandableItem(component: ability, embedded: true);
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: _titlesColor),
            ),
            const SizedBox(width: 8),
            Text(SheetStoryTitlesTabText.loadingAbility(abilityNameOrId),
                style: TextStyle(fontSize: 10, color: FormTheme.textSecondary)),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Icon(Icons.flash_on, size: 16, color: Colors.purple.shade300),
            const SizedBox(width: 4),
            Text(
              SheetStoryTitlesTabText.abilityLabel(abilityNameOrId),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade300,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeBenefitDialog(String titleId, List benefits) {
    // Only show chooseable (non-auto) benefits
    final choiceEntries = <MapEntry<int, dynamic>>[];
    for (int i = 0; i < benefits.length; i++) {
      final b = benefits[i];
      if (b is Map<String, dynamic> && b['auto'] == true) continue;
      choiceEntries.add(MapEntry(i, b));
    }
    if (choiceEntries.length <= 1) return; // Nothing to change

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _titlesColor.withAlpha(51),
                      _titlesColor.withAlpha(13),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _titlesColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz,
                          color: _titlesColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        SheetStoryTitlesTabText.changeBenefit,
                        style: TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Benefits list (only chooseable)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: choiceEntries.length,
                  itemBuilder: (context, listIndex) {
                    final originalIndex = choiceEntries[listIndex].key;
                    final benefit = choiceEntries[listIndex].value;
                    final isSelected =
                        _selectedTitles[titleId]!['selectedBenefitIndex'] ==
                            originalIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _titlesColor.withAlpha(38)
                            : StoryTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected ? _titlesColor : FormTheme.borderDim,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _changeBenefit(titleId, originalIndex);
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    (benefit is Map<String, dynamic> &&
                                            benefit['name'] != null)
                                        ? benefit['name'] as String
                                        : SheetStoryTitlesTabText.benefitLabel(
                                            listIndex),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? _titlesColor
                                          : FormTheme.textBright,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: _titlesColor,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildBenefitContent(context, benefit,
                                  titleId: titleId),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
