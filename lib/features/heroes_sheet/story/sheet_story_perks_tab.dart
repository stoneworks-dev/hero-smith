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
          _errorMessage = 'Failed to load data: $e';
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
    final languageIds =
        await db.getHeroComponentIds(widget.heroId, 'language');
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
                foregroundColor: Colors.white,
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
                  border: Border.all(color: Colors.grey.shade800),
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
                      child:
                          const Icon(Icons.star, color: _perksColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            SheetStoryPerksTabText.headerTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedPerkIds.length} perks selected',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
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
      builder: (context) => _AddPerkDialog(
        heroId: widget.heroId,
        selectedPerkIds: selectedPerkIds,
        onPerkSelected: (perkId) async {
          Navigator.of(context).pop();
          final newSelection = Set<String>.from(selectedPerkIds)..add(perkId);
          await _handleSelectionChanged(newSelection);

          // Persist the new perk
          final db = ref.read(appDatabaseProvider);
          await db.addHeroComponentId(
            heroId: widget.heroId,
            componentId: perkId,
            category: 'perk',
          );
        },
      ),
    );
  }
}

// Add Perk Dialog widget
class _AddPerkDialog extends ConsumerStatefulWidget {
  final String heroId;
  final Set<String> selectedPerkIds;
  final Function(String) onPerkSelected;

  const _AddPerkDialog({
    required this.heroId,
    required this.selectedPerkIds,
    required this.onPerkSelected,
  });

  @override
  ConsumerState<_AddPerkDialog> createState() => _AddPerkDialogState();
}

class _AddPerkDialogState extends ConsumerState<_AddPerkDialog> {
  String _searchQuery = '';
  String? _selectedGroup;
  List<model.Component> _allPerks = [];
  List<model.Component> _filteredPerks = [];
  Set<String> _groups = {};

  @override
  void initState() {
    super.initState();
    _loadPerks();
  }

  Future<void> _loadPerks() async {
    final perks = await ref.read(componentsByTypeProvider('perk').future);
    final available = perks
        .where((perk) => !widget.selectedPerkIds.contains(perk.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final groups = <String>{};
    for (final perk in available) {
      final group = perk.data['group'] as String?;
      if (group != null && group.isNotEmpty) {
        groups.add(group);
      }
    }

    if (mounted) {
      setState(() {
        _allPerks = available;
        _filteredPerks = available;
        _groups = groups;
      });
    }
  }

  void _filterPerks() {
    setState(() {
      _filteredPerks = _allPerks.where((perk) {
        final matchesSearch = _searchQuery.isEmpty ||
            perk.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (perk.data['description'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;

        final perkGroup = perk.data['group'] as String?;
        final matchesGroup = _selectedGroup == null ||
            (perkGroup?.toLowerCase() == _selectedGroup?.toLowerCase());

        return matchesSearch && matchesGroup;
      }).toList();
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
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
                    _perksColor.withAlpha(51),
                    _perksColor.withAlpha(13),
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
                    child: const Icon(Icons.star, color: _perksColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Perk',
                      style: TextStyle(
                        color: Colors.white,
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
            // Search and filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Search perks',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: StoryTheme.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _perksColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterPerks();
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', null),
                        const SizedBox(width: 8),
                        ..._groups.map((group) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child:
                                  _buildFilterChip(_capitalize(group), group),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Perks list
            Expanded(
              child: _filteredPerks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            Text(
                              'No perks found',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredPerks.length,
                      itemBuilder: (context, index) {
                        final perk = _filteredPerks[index];
                        final group = perk.data['group'] as String? ?? '';
                        final description =
                            perk.data['description'] as String? ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: StoryTheme.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _perksColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.add_circle_outline,
                                  color: _perksColor, size: 18),
                            ),
                            title: Text(
                              perk.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                if (group.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _capitalize(group),
                                    style: const TextStyle(
                                      color: _perksColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () => widget.onPerkSelected(perk.id),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? group) {
    final isSelected = _selectedGroup == group;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGroup = group;
        });
        _filterPerks();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? _perksColor.withAlpha(51) : StoryTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _perksColor : Colors.grey.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _perksColor : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
