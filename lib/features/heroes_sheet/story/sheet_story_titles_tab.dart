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
  Map<String, Map<String, dynamic>> _selectedTitles = {}; // titleId -> {title, selectedBenefitIndex}
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
          const SnackBar(content: Text(SheetStoryTitlesTabText.titleAlreadyAdded)),
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
          SnackBar(content: Text(SheetStoryTitlesTabText.failedToRemoveTitle(e))),
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
    Navigator.of(context).push(
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
              if (benefits.length <= 1) {
                _addTitle(titleId, 0);
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
    ).then((_) {
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
                      child: AppIcon(TitleIcons.tab, color: _titlesColor, size: 24),
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
                            SheetStoryTitlesTabText.titlesEarned(_selectedTitles.length),
                            style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              style: TextStyle(color: FormTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _titlesColor.withAlpha(180), size: 22),
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
                        Icon(Icons.emoji_events_outlined, size: 48, color: FormTheme.borderLight),
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
                            AppIcon(TitleIcons.fromEchelon(echelon), color: _titlesColor, size: 18),
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
                      ...titles.map((entry) => _buildTitleCard(context, entry.key, entry.value)),
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

  Widget _buildTitleCard(BuildContext context, String titleId, Map<String, dynamic> data) {
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
                  child: AppIcon(TitleIcons.fromEchelon(echelon), color: _titlesColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title['name'] as String? ?? SheetStoryTitlesTabText.unknown,
                        style: const TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (title['prerequisite'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          SheetStoryTitlesTabText.prerequisite(title['prerequisite'].toString()),
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
            Text(
              SheetStoryTitlesTabText.selectedBenefit,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: FormTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            if (benefits.isNotEmpty && selectedBenefitIndex < benefits.length)
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
                    _buildBenefitContent(context, benefits[selectedBenefitIndex]),
                    if (benefits.length > 1) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showChangeBenefitDialog(titleId, benefits),
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
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        SheetStoryTitlesTabText.special(title['special'].toString()),
                        style: TextStyle(color: FormTheme.textSecondary, fontSize: 12),
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

  Widget _buildBenefitContent(BuildContext context, dynamic benefit) {
    if (benefit is! Map<String, dynamic>) return const SizedBox.shrink();
    
    final description = benefit['description'] as String?;
    final ability = benefit['ability'] as String?;
    final grantsRaw = benefit['grants'];
    // Normalize grants to a List (can be Map or List)
    final grants = grantsRaw is List ? grantsRaw : (grantsRaw is Map ? [grantsRaw] : null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null && description.isNotEmpty)
          Text(description, style: TextStyle(color: FormTheme.textSecondary, fontSize: 13)),
        if (ability != null && ability.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAbilityCard(ability),
        ],
        if (grants != null && grants.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...grants.map((grant) {
            if (grant is Map<String, dynamic>) {
              final type = grant['type'] as String?;
              final value = grant['value'];
              if (type != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 16, color: Colors.teal.shade300),
                      const SizedBox(width: 4),
                      Text(
                        SheetStoryTitlesTabText.grantsLabel(_formatGrant(type, value)),
                        style: TextStyle(
                          color: Colors.teal.shade300,
                          fontSize: 12,
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
              child: CircularProgressIndicator(strokeWidth: 1.5, color: _titlesColor),
            ),
            const SizedBox(width: 8),
            Text(SheetStoryTitlesTabText.loadingAbility(abilityNameOrId), style: TextStyle(fontSize: 10, color: FormTheme.textSecondary)),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                      child: const Icon(Icons.swap_horiz, color: _titlesColor, size: 24),
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
              // Benefits list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: benefits.length,
                  itemBuilder: (context, index) {
                    final benefit = benefits[index];
                    final isSelected = _selectedTitles[titleId]!['selectedBenefitIndex'] == index;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _titlesColor.withAlpha(38)
                            : StoryTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? _titlesColor : FormTheme.borderDim,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _changeBenefit(titleId, index);
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
                                    SheetStoryTitlesTabText.benefitLabel(index),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? _titlesColor : FormTheme.textBright,
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
                              _buildBenefitContent(context, benefit),
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
