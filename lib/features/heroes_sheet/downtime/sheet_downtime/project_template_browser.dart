import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/downtime_data_source.dart';
import '../../../../core/db/providers.dart';
import '../../../../core/models/downtime.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icon_data.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/project_template_browser_text.dart';

/// Accent color for projects
const Color _projectsColor = NavigationTheme.projectsTabColor;

/// Provider for loading project templates from JSON
final projectTemplatesProvider = FutureProvider<List<DowntimeEntry>>((ref) async {
  final dataSource = DowntimeDataSource();
  return await dataSource.loadProjects();
});

/// Provider for loading imbuement templates from JSON
final imbuementTemplatesProvider = FutureProvider<List<DowntimeEntry>>((ref) async {
  final dataSource = DowntimeDataSource();
  return await dataSource.loadImbuements();
});

/// Provider for loading craftable treasures from JSON
final craftableTreasuresProvider = FutureProvider<List<CraftableTreasure>>((ref) async {
  final dataSource = DowntimeDataSource();
  return await dataSource.loadAllCraftableTreasures();
});

/// Unified search result that can hold any type of project
class SearchableProject {
  final String id;
  final String name;
  final String description;
  final int? projectGoal;
  final String category; // 'project', 'imbuement', 'treasure'
  final dynamic source; // Original DowntimeEntry or CraftableTreasure
  
  SearchableProject({
    required this.id,
    required this.name,
    required this.description,
    this.projectGoal,
    required this.category,
    required this.source,
  });
  
  factory SearchableProject.fromDowntimeEntry(DowntimeEntry entry, String category) {
    final projectGoalRaw = entry.raw['project_goal'];
    final projectGoal = projectGoalRaw is int 
        ? projectGoalRaw 
        : (projectGoalRaw is String ? int.tryParse(projectGoalRaw) : null);
    
    return SearchableProject(
      id: entry.id,
      name: entry.name,
      description: entry.raw['description'] as String? ?? '',
      projectGoal: projectGoal,
      category: category,
      source: entry,
    );
  }
  
  factory SearchableProject.fromCraftableTreasure(CraftableTreasure treasure) {
    return SearchableProject(
      id: treasure.id,
      name: treasure.name,
      description: treasure.description,
      projectGoal: treasure.projectGoal,
      category: 'treasure',
      source: treasure,
    );
  }
}

/// Dialog to browse and select project templates
class ProjectTemplateBrowser extends ConsumerStatefulWidget {
  const ProjectTemplateBrowser({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<ProjectTemplateBrowser> createState() => _ProjectTemplateBrowserState();
}

class _ProjectTemplateBrowserState extends ConsumerState<ProjectTemplateBrowser>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: NavigationTheme.navBarBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FormTheme.borderDim),
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _projectsColor.withAlpha(60),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _projectsColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppIcon(DowntimeIcons.templateBrowser, size: 28, color: _projectsColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(color: FormTheme.textBright),
                            decoration: InputDecoration(
                              hintText: ProjectTemplateBrowserText.searchHint,
                              hintStyle: TextStyle(color: FormTheme.textMuted),
                              filled: true,
                              fillColor: NavigationTheme.cardBackgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: FormTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: FormTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _projectsColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: FormTheme.textMuted),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                            ),
                          )
                        : Text(
                            ProjectTemplateBrowserText.dialogTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: FormTheme.textBright,
                                ),
                          ),
                  ),
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search, color: FormTheme.textSecondary),
                    onPressed: _toggleSearch,
                    tooltip: _isSearching
                        ? ProjectTemplateBrowserText.closeSearchTooltip
                        : ProjectTemplateBrowserText.openSearchTooltip,
                  ),
                  if (!_isSearching)
                    IconButton(
                      icon: Icon(Icons.close, color: FormTheme.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Show search results or tabs
            if (_searchQuery.isNotEmpty)
              Expanded(child: _buildSearchResults())
            else ...[
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: FormTheme.borderDim),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: _projectsColor,
                  unselectedLabelColor: FormTheme.textMuted,
                  indicatorColor: _projectsColor,
                  tabs: const [
                    Tab(text: ProjectTemplateBrowserText.tabProjectsLabel),
                    Tab(text: ProjectTemplateBrowserText.tabImbuementsLabel),
                    Tab(text: ProjectTemplateBrowserText.tabTreasuresLabel),
                  ],
                ),
              ),
              

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectsTab(),
                    _buildImbuementsTab(),
                    _buildTreasuresTab(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    final projectsAsync = ref.watch(projectTemplatesProvider);
    final imbuementsAsync = ref.watch(imbuementTemplatesProvider);
    final treasuresAsync = ref.watch(craftableTreasuresProvider);
    
    // Check if any are still loading
    if (projectsAsync.isLoading || imbuementsAsync.isLoading || treasuresAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _projectsColor),
      );
    }
    
    // Collect all searchable projects
    final allProjects = <SearchableProject>[];
    
    // Add projects
    if (projectsAsync.hasValue) {
      for (final entry in projectsAsync.value!) {
        allProjects.add(SearchableProject.fromDowntimeEntry(entry, 'project'));
      }
    }
    
    // Add imbuements
    if (imbuementsAsync.hasValue) {
      for (final entry in imbuementsAsync.value!) {
        allProjects.add(SearchableProject.fromDowntimeEntry(entry, 'imbuement'));
      }
    }
    
    // Add treasures
    if (treasuresAsync.hasValue) {
      for (final treasure in treasuresAsync.value!) {
        allProjects.add(SearchableProject.fromCraftableTreasure(treasure));
      }
    }
    
    // Filter by search query
    final filteredProjects = allProjects.where((project) {
      return project.name.toLowerCase().contains(_searchQuery);
    }).toList();
    
    // Sort by name
    filteredProjects.sort((a, b) => a.name.compareTo(b.name));
    
    if (filteredProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FormTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.search_off,
                  size: 48,
                  color: FormTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ProjectTemplateBrowserText.noProjectsFound(_searchQuery),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FormTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectTemplateBrowserText.searchResults(filteredProjects.length, _searchQuery),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FormTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) {
                final project = filteredProjects[index];
                return _buildSearchResultCard(context, project);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResultCard(BuildContext context, SearchableProject project) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(project.category);
    final categoryIcon = ProjectCategoryIcons.fromName(project.category);
    final categoryLabel = _getCategoryLabel(project.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FormTheme.borderDim),
      ),
      child: InkWell(
        onTap: () => _takeOnSearchableProject(context, ref, project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge and name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(categoryIcon, size: 14, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          categoryLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FormTheme.textBright,
                      ),
                    ),
                  ),
                  if (project.projectGoal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _projectsColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ProjectTemplateBrowserText.goalBadge(project.projectGoal),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _projectsColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FormTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Take on button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _takeOnSearchableProject(context, ref, project),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    ProjectTemplateBrowserText.takeOnSearchResultButtonLabel,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _projectsColor,
                    foregroundColor: FormTheme.textBright,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'project':
        return NavigationTheme.projectsTabColor;
      case 'imbuement':
        return NavigationTheme.imbuementsTabColor;
      case 'treasure':
        return NavigationTheme.treasuresTabColor;
      default:
        return FormTheme.textMuted;
    }
  }
  
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'project':
        return ProjectTemplateBrowserText.categoryProjectLabel;
      case 'imbuement':
        return ProjectTemplateBrowserText.categoryImbuementLabel;
      case 'treasure':
        return ProjectTemplateBrowserText.categoryTreasureLabel;
      default:
        return category;
    }
  }
  
  void _takeOnSearchableProject(
    BuildContext context,
    WidgetRef ref,
    SearchableProject project,
  ) {
    if (project.source is DowntimeEntry) {
      _takeOnProject(context, ref, project.source as DowntimeEntry);
    } else if (project.source is CraftableTreasure) {
      _takeOnTreasureProject(context, ref, project.source as CraftableTreasure);
    }
  }

  Widget _buildProjectsTab() {
    final templatesAsync = ref.watch(projectTemplatesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectTemplateBrowserText.selectProjectPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FormTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: templatesAsync.when(
              data: (templates) => _buildTemplateList(context, templates),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _projectsColor),
              ),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImbuementsTab() {
    final imbuementsAsync = ref.watch(imbuementTemplatesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectTemplateBrowserText.selectImbuementPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FormTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: imbuementsAsync.when(
              data: (imbuements) => _buildImbuementsGrouped(context, imbuements),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _projectsColor),
              ),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuresTab() {
    final treasuresAsync = ref.watch(craftableTreasuresProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectTemplateBrowserText.selectTreasurePrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FormTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: treasuresAsync.when(
              data: (treasures) => _buildTreasuresGrouped(context, treasures),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _projectsColor),
              ),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuresGrouped(
    BuildContext context,
    List<CraftableTreasure> treasures,
  ) {
    if (treasures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FormTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(50),
              ),
              child: AppIcon(DowntimeIcons.emptyState, size: 48, color: FormTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              ProjectTemplateBrowserText.noCraftableTreasuresLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FormTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group treasures by type
    final grouped = <String, List<CraftableTreasure>>{};
    
    for (final treasure in treasures) {
      grouped.putIfAbsent(treasure.type, () => <CraftableTreasure>[]);
      grouped[treasure.type]!.add(treasure);
    }

    // Sort by type order
    final typeOrder = ['consumable', 'trinket', 'leveled_treasure'];
    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) {
        final indexA = typeOrder.indexOf(a);
        final indexB = typeOrder.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return ListView.builder(
      itemCount: sortedTypes.length,
      itemBuilder: (context, index) {
        final type = sortedTypes[index];
        final items = grouped[type]!;
        
        // Further group by echelon for consumables/trinkets, or by equipment type for leveled
        if (type == 'leveled_treasure') {
          return _buildLeveledTreasuresSection(context, items);
        } else {
          return _buildEchelonTreasuresSection(context, type, items);
        }
      },
    );
  }

  Widget _buildEchelonTreasuresSection(
    BuildContext context,
    String type,
    List<CraftableTreasure> treasures,
  ) {
    // Group by echelon
    final byEchelon = <int, List<CraftableTreasure>>{};
    for (final treasure in treasures) {
      final echelon = treasure.echelon ?? 0;
      byEchelon.putIfAbsent(echelon, () => <CraftableTreasure>[]);
      byEchelon[echelon]!.add(treasure);
    }
    
    final sortedEchelons = byEchelon.keys.toList()..sort();
    final typeColor = _getTreasureTypeColor(type);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: NavigationTheme.cardBackgroundDark,
          borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent stripe
            Container(
              width: NavigationTheme.cardAccentStripeWidth,
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    typeColor.withAlpha(220),
                    typeColor.withAlpha(140),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          typeColor.withAlpha(60),
                          typeColor.withAlpha(30),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: typeColor.withAlpha(80), width: 1),
                    ),
                    child: AppIcon(_getTreasureTypeIcon(type), color: typeColor, size: 20),
                  ),
                  title: Text(
                    _getTreasureTypeName(type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                  ),
                  subtitle: Text(
                    ProjectTemplateBrowserText.itemCount(treasures.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FormTheme.textMuted,
                    ),
                  ),
                  iconColor: typeColor,
                  collapsedIconColor: typeColor.withAlpha(160),
                  children: sortedEchelons.map((echelon) {
                    final items = byEchelon[echelon]!;
                    return _buildSubGroupTile(
                      context,
                      title: _getEchelonName(echelon),
                      count: items.length,
                      accentColor: typeColor,
                      children: items.map((treasure) => _buildTreasureCard(context, treasure)).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeveledTreasuresSection(
    BuildContext context,
    List<CraftableTreasure> treasures,
  ) {
    // Group by equipment type
    final byEquipType = <String, List<CraftableTreasure>>{};
    for (final treasure in treasures) {
      final equipType = treasure.leveledType ?? 'other';
      byEquipType.putIfAbsent(equipType, () => <CraftableTreasure>[]);
      byEquipType[equipType]!.add(treasure);
    }
    
    final typeOrder = ['armor', 'shield', 'weapon', 'implement', 'other'];
    final sortedTypes = byEquipType.keys.toList()
      ..sort((a, b) {
        final indexA = typeOrder.indexOf(a);
        final indexB = typeOrder.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    
    const leveledColor = NavigationTheme.leveledColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: NavigationTheme.cardBackgroundDark,
          borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent stripe
            Container(
              width: NavigationTheme.cardAccentStripeWidth,
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    leveledColor.withAlpha(220),
                    leveledColor.withAlpha(140),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          leveledColor.withAlpha(60),
                          leveledColor.withAlpha(30),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: leveledColor.withAlpha(80), width: 1),
                    ),
                    child: AppIcon(DowntimeIcons.leveledTreasure, color: leveledColor, size: 20),
                  ),
                  title: Text(
                    ProjectTemplateBrowserText.leveledTreasuresHeader,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: leveledColor,
                        ),
                  ),
                  subtitle: Text(
                    ProjectTemplateBrowserText.itemCount(treasures.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FormTheme.textMuted,
                    ),
                  ),
                  iconColor: leveledColor,
                  collapsedIconColor: leveledColor.withAlpha(160),
                  children: sortedTypes.map((equipType) {
                    final items = byEquipType[equipType]!;
                    return _buildSubGroupTile(
                      context,
                      title: _getEquipmentTypeName(equipType),
                      count: items.length,
                      accentColor: leveledColor,
                      children: items.map((treasure) => _buildTreasureCard(context, treasure)).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sub-group tile used inside both treasure type and imbuement level sections.
  Widget _buildSubGroupTile(
    BuildContext context, {
    required String title,
    required int count,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 4),
          iconColor: accentColor.withAlpha(160),
          collapsedIconColor: FormTheme.borderLight,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FormTheme.textSecondary,
                ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildTreasureCard(BuildContext context, CraftableTreasure treasure) {
    final theme = Theme.of(context);
    final typeColor = _getTreasureTypeColor(treasure.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _takeOnTreasureProject(context, ref, treasure),
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent stripe
            Container(
              width: 4,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [typeColor, typeColor.withAlpha(140)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Title and goal
              Row(
                children: [
                  Expanded(
                    child: Text(
                      treasure.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  if (treasure.projectGoal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ProjectTemplateBrowserText.goalBadge(treasure.projectGoal),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Keywords
              if (treasure.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: treasure.keywords.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        keyword,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: typeColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),

              // Description
              if (treasure.description.isNotEmpty) ...[
                Text(
                  treasure.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FormTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Prerequisites
              if (treasure.itemPrerequisite != null && treasure.itemPrerequisite!.isNotEmpty) ...[
                _buildSection(
                  context,
                  ProjectTemplateBrowserText.prerequisitesLabel,
                  [treasure.itemPrerequisite!],
                  DowntimeIcons.rewards,
                ),
                const SizedBox(height: 8),
              ],

              // Roll characteristics
              if (treasure.projectRollCharacteristics.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    AppIcon(DowntimeIcons.diceRoll, size: 16, color: FormTheme.textMuted),
                    Text(
                      ProjectTemplateBrowserText.rollLabel(treasure.projectRollCharacteristics.join(', ')),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FormTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Take on button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _takeOnTreasureProject(context, ref, treasure),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    ProjectTemplateBrowserText.takeOnTreasureButtonLabel,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _projectsColor,
                    foregroundColor: FormTheme.textBright,
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTreasureTypeColor(String type) {
    switch (type) {
      case 'consumable':
        return NavigationTheme.consumablesColor;
      case 'trinket':
        return NavigationTheme.trinketsColor;
      case 'leveled_treasure':
        return NavigationTheme.leveledColor;
      default:
        return NavigationTheme.treasureColor;
    }
  }

  AppIconData _getTreasureTypeIcon(String type) {
    switch (type) {
      case 'consumable':
        return DowntimeIcons.consumable;
      case 'trinket':
        return DowntimeIcons.trinket;
      case 'leveled_treasure':
        return DowntimeIcons.leveledTreasure;
      default:
        return DowntimeIcons.genericTreasure;
    }
  }

  String _getTreasureTypeName(String type) {
    switch (type) {
      case 'consumable':
        return ProjectTemplateBrowserText.treasureTypeConsumablesLabel;
      case 'trinket':
        return ProjectTemplateBrowserText.treasureTypeTrinketsLabel;
      case 'leveled_treasure':
        return ProjectTemplateBrowserText.treasureTypeLeveledLabel;
      default:
        return type;
    }
  }

  String _getEchelonName(int echelon) {
    switch (echelon) {
      case 0:
        return ProjectTemplateBrowserText.echelonNoneLabel;
      case 1:
        return ProjectTemplateBrowserText.echelon1Label;
      case 2:
        return ProjectTemplateBrowserText.echelon2Label;
      case 3:
        return ProjectTemplateBrowserText.echelon3Label;
      case 4:
        return ProjectTemplateBrowserText.echelon4Label;
      default:
        return ProjectTemplateBrowserText.echelonFallback(echelon);
    }
  }

  String _getEquipmentTypeName(String equipType) {
    switch (equipType) {
      case 'armor':
        return ProjectTemplateBrowserText.equipmentArmorLabel;
      case 'weapon':
        return ProjectTemplateBrowserText.equipmentWeaponsLabel;
      case 'implement':
        return ProjectTemplateBrowserText.equipmentImplementsLabel;
      case 'shield':
        return ProjectTemplateBrowserText.equipmentShieldsLabel;
      default:
        return equipType
            .split('_')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
            .join(' ');
    }
  }

  void _takeOnTreasureProject(
    BuildContext context,
    WidgetRef ref,
    CraftableTreasure treasure,
  ) async {
    try {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.createProject(
        heroId: widget.heroId,
        templateProjectId: treasure.id,
        name: treasure.name,
        description: treasure.description,
        projectGoal: treasure.projectGoal ?? 100,
        prerequisites: treasure.itemPrerequisite != null ? [treasure.itemPrerequisite!] : [],
        projectSource: treasure.projectSource,
        sourceLanguage: null,
        guides: [],
        rollCharacteristics: treasure.projectRollCharacteristics,
        isCustom: false,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ProjectTemplateBrowserText.addedCraftingProject(treasure.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ProjectTemplateBrowserText.failedToAddProject(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildImbuementsGrouped(
    BuildContext context,
    List<DowntimeEntry> imbuements,
  ) {
    if (imbuements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FormTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(50),
              ),
              child: AppIcon(DowntimeIcons.emptyState, size: 48, color: FormTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              ProjectTemplateBrowserText.noImbuementsLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FormTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group imbuements by level and type
    final grouped = <int, Map<String, List<DowntimeEntry>>>{};
    
    for (final imbuement in imbuements) {
      final level = imbuement.raw['level'] as int? ?? 1;
      final type = imbuement.raw['type'] as String? ?? 'unknown';
      
      grouped.putIfAbsent(level, () => <String, List<DowntimeEntry>>{});
      grouped[level]!.putIfAbsent(type, () => <DowntimeEntry>[]);
      grouped[level]![type]!.add(imbuement);
    }

    // Sort by level
    final sortedLevels = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedLevels.length,
      itemBuilder: (context, index) {
        final level = sortedLevels[index];
        final typeGroups = grouped[level]!;
        final imbuementColor = NavigationTheme.imbuementsTabColor;
        final totalItems = typeGroups.values.fold<int>(0, (sum, list) => sum + list.length);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent stripe
                Container(
                  width: NavigationTheme.cardAccentStripeWidth,
                  constraints: const BoxConstraints(minHeight: 72),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        imbuementColor.withAlpha(220),
                        imbuementColor.withAlpha(140),
                      ],
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              imbuementColor.withAlpha(60),
                              imbuementColor.withAlpha(30),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: imbuementColor.withAlpha(80), width: 1),
                        ),
                        child: AppIcon(DowntimeIcons.enchantment, color: imbuementColor, size: 20),
                      ),
                      title: Text(
                        _getLevelName(level),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: imbuementColor,
                            ),
                      ),
                      subtitle: Text(
                        ProjectTemplateBrowserText.itemCount(totalItems),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FormTheme.textMuted,
                        ),
                      ),
                      iconColor: imbuementColor,
                      collapsedIconColor: imbuementColor.withAlpha(160),
                      children: typeGroups.entries.map((entry) {
                        final type = entry.key;
                        final items = entry.value;
                        return _buildSubGroupTile(
                          context,
                          title: _getImbuementTypeName(type),
                          count: items.length,
                          accentColor: imbuementColor,
                          children: items.map((imbuement) => _buildTemplateCard(context, imbuement)).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return ProjectTemplateBrowserText.levelImbuements1Label;
      case 5:
        return ProjectTemplateBrowserText.levelImbuements5Label;
      case 9:
        return ProjectTemplateBrowserText.levelImbuements9Label;
      default:
        return ProjectTemplateBrowserText.levelImbuementsFallback(level);
    }
  }

  String _getImbuementTypeName(String type) {
    switch (type) {
      case 'armor_imbuement':
        return ProjectTemplateBrowserText.imbuementTypeArmorLabel;
      case 'weapon_imbuement':
        return ProjectTemplateBrowserText.imbuementTypeWeaponLabel;
      case 'implement_imbuement':
        return ProjectTemplateBrowserText.imbuementTypeImplementLabel;
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withAlpha(80),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ProjectTemplateBrowserText.failedToLoadTemplatesLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FormTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: FormTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(
    BuildContext context,
    List<DowntimeEntry> templates,
  ) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FormTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(50),
              ),
              child: AppIcon(DowntimeIcons.emptyState, size: 48, color: FormTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              ProjectTemplateBrowserText.noTemplatesFoundLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FormTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    DowntimeEntry template,
  ) {
    final theme = Theme.of(context);
    final prerequisites = template.raw['prerequisites'] as Map<String, dynamic>? ?? {};
    final itemPrereqs = (prerequisites['item_prerequisite'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final sourcePrereqs = (prerequisites['project_source'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rollChars = (template.raw['project_roll_characteristic'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    
    // Handle project_goal which might be stored as String or int in JSON
    final projectGoalRaw = template.raw['project_goal'];
    final projectGoal = projectGoalRaw is int 
        ? projectGoalRaw 
        : (projectGoalRaw is String ? int.tryParse(projectGoalRaw) : null) ?? 100;
    
    final description = template.raw['description'] as String? ?? '';
    final imbuementType = template.raw['type'] as String? ?? '';
    final accentColor = _getImbuementAccentColor(imbuementType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _takeOnProject(context, ref, template),
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent stripe
            Container(
              width: 4,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor, accentColor.withAlpha(140)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Title and goal
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: FormTheme.textBright,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _projectsColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ProjectTemplateBrowserText.goalBadge(projectGoal),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _projectsColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FormTheme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Prerequisites
              if (itemPrereqs.isNotEmpty) ...[
                _buildSection(
                  context,
                  ProjectTemplateBrowserText.itemPrerequisitesLabel,
                  itemPrereqs.map((p) => p['name'] as String? ?? '').toList(),
                  DowntimeIcons.rewards,
                ),
                const SizedBox(height: 8),
              ],

              // Sources
              if (sourcePrereqs.isNotEmpty) ...[
                _buildSection(
                  context,
                  ProjectTemplateBrowserText.sourcesLabel,
                  sourcePrereqs.map((p) {
                    final name = p['name'] as String? ?? '';
                    final lang = p['language'] as String? ?? '';
                    return lang.isNotEmpty ? '$name ($lang)' : name;
                  }).toList(),
                  DowntimeIcons.lore,
                ),
                const SizedBox(height: 8),
              ],

              // Roll characteristics
              if (rollChars.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    AppIcon(DowntimeIcons.diceRoll, size: 16, color: FormTheme.textMuted),
                    Text(
                      ProjectTemplateBrowserText.rollLabel(rollChars.map((c) => c['name'] as String? ?? '').join(', ')),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FormTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Take on button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _takeOnProject(context, ref, template),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    ProjectTemplateBrowserText.takeOnTemplateButtonLabel,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _projectsColor,
                    foregroundColor: FormTheme.textBright,
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get accent color for imbuement type.
  Color _getImbuementAccentColor(String type) {
    switch (type) {
      case 'weapon_imbuement':
        return NavigationTheme.weaponColor;
      case 'implement_imbuement':
        return NavigationTheme.implementColor;
      case 'armor_imbuement':
        return NavigationTheme.armorColor;
      case 'shield_imbuement':
        return NavigationTheme.shieldColor;
      default:
        return NavigationTheme.imbuementsTabColor;
    }
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    AppIconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(icon, size: 16, color: FormTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: FormTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                '• $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: FormTheme.textSecondary,
                ),
              ),
            )),
      ],
    );
  }

  void _takeOnProject(
    BuildContext context,
    WidgetRef ref,
    DowntimeEntry template,
  ) async {
    // Extract data from template
    final prerequisites = template.raw['prerequisites'] as Map<String, dynamic>? ?? {};
    final itemPrereqs = (prerequisites['item_prerequisite'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final sourcePrereqs = (prerequisites['project_source'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rollChars = (template.raw['project_roll_characteristic'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    
    // Handle project_goal which might be stored as String or int in JSON
    final projectGoalRaw = template.raw['project_goal'];
    int projectGoal;
    if (projectGoalRaw is int) {
      projectGoal = projectGoalRaw;
    } else if (projectGoalRaw is String) {
      projectGoal = int.tryParse(projectGoalRaw) ?? 100; // Default to 100 for "Varies" etc.
    } else {
      projectGoal = 100;
    }
    
    final description = template.raw['description'] as String? ?? '';

    // Create prerequisites list
    final prereqsList = itemPrereqs
        .map((p) => p['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    // Get first source if available
    final firstSource = sourcePrereqs.isNotEmpty ? sourcePrereqs.first : null;
    final sourceName = firstSource?['name'] as String?;
    final sourceLanguage = firstSource?['language'] as String?;

    // Create roll characteristics list
    final rollCharsList = rollChars
        .map((c) => c['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    try {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.createProject(
        heroId: widget.heroId,
        templateProjectId: template.id,
        name: template.name,
        description: description,
        projectGoal: projectGoal,
        prerequisites: prereqsList,
        projectSource: sourceName,
        sourceLanguage: sourceLanguage,
        guides: [],
        rollCharacteristics: rollCharsList,
        isCustom: false,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ProjectTemplateBrowserText.addedToProjects(template.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ProjectTemplateBrowserText.failedToAddProject(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
