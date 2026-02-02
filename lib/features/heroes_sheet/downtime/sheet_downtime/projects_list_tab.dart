import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/providers.dart';
import '../../../../core/models/downtime.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/projects_list_tab_text.dart';
import '../../../../core/data/downtime_data_source.dart';
import 'project_editor_dialog.dart';
import 'project_detail_card.dart';
import 'project_roll_dialog.dart';
import 'project_template_browser.dart'; // Also provides craftableTreasuresProvider and imbuementTemplatesProvider

/// Accent color for projects
const Color _projectsColor = NavigationTheme.projectsTabColor;

/// Provider for hero's downtime projects
final heroProjectsProvider =
    StreamProvider.family<List<HeroDowntimeProject>, String>(
        (ref, heroId) async* {
  final repo = ref.read(downtimeRepositoryProvider);

  // Initial load
  yield await repo.getHeroProjects(heroId);

  // Poll for updates every 2 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
    yield await repo.getHeroProjects(heroId);
  }
});

class ProjectsListTab extends ConsumerWidget {
  const ProjectsListTab({super.key, required this.heroId});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(heroProjectsProvider(heroId));

    return projectsAsync.when(
      data: (projects) => _buildContent(context, ref, projects),
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  /// Try to find the matching treasure for a project (by templateProjectId or name)
  CraftableTreasure? _findMatchingTreasure(
    HeroDowntimeProject project,
    List<CraftableTreasure> treasures,
  ) {
    // First try by templateProjectId
    if (project.templateProjectId != null) {
      for (final t in treasures) {
        if (t.id == project.templateProjectId) {
          return t;
        }
      }
    }
    // Fall back to name matching (case-insensitive)
    final nameLower = project.name.toLowerCase();
    for (final t in treasures) {
      if (t.name.toLowerCase() == nameLower) {
        return t;
      }
    }
    return null;
  }

  /// Try to find the matching imbuement for a project (by templateProjectId or name)
  DowntimeEntry? _findMatchingImbuement(
    HeroDowntimeProject project,
    List<DowntimeEntry> imbuements,
  ) {
    // First try by templateProjectId
    if (project.templateProjectId != null) {
      for (final e in imbuements) {
        if (e.id == project.templateProjectId) {
          return e;
        }
      }
    }
    // Fall back to name matching (case-insensitive)
    final nameLower = project.name.toLowerCase();
    for (final e in imbuements) {
      if (e.name.toLowerCase() == nameLower) {
        return e;
      }
    }
    return null;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<HeroDowntimeProject> projects,
  ) {
    // Use the same provider that project_template_browser uses for treasures
    final treasuresAsync = ref.watch(craftableTreasuresProvider);
    final treasures = treasuresAsync.valueOrNull ?? <CraftableTreasure>[];

    // Also watch for imbuements
    final imbuementsAsync = ref.watch(imbuementTemplatesProvider);
    final imbuements = imbuementsAsync.valueOrNull ?? <DowntimeEntry>[];

    return CustomScrollView(
      slivers: [
        // Add project button
        SliverToBoxAdapter(
          child: _buildAddProjectButton(context, ref),
        ),

        // Active projects
        if (projects.where((p) => !p.isCompleted).isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _projectsColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.work_outline, size: 18, color: _projectsColor),
                  const SizedBox(width: 6),
                  Text(
                    ProjectsListTabText.activeProjectsHeader,
                    style: const TextStyle(
                      color: _projectsColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final activeProjects =
                    projects.where((p) => !p.isCompleted).toList();
                final project = activeProjects[index];
                final hasReachedGoal =
                    project.currentPoints >= project.projectGoal;
                final matchingTreasure =
                    _findMatchingTreasure(project, treasures);
                final matchingImbuement =
                    _findMatchingImbuement(project, imbuements);
                final isTreasureProject = matchingTreasure != null;
                final isImbuementProject = matchingImbuement != null;
                return ProjectDetailCard(
                  project: project,
                  heroId: heroId,
                  onTap: () => _editProject(context, ref, project),
                  onAddPoints: () => _addPointsToProject(context, ref, project),
                  onRoll: () => _rollForProject(context, ref, project),
                  onDelete: () => _deleteProject(context, ref, project),
                  isTreasureProject: isTreasureProject,
                  treasureData: matchingTreasure?.raw,
                  isImbuementProject: isImbuementProject,
                  imbuementData: matchingImbuement?.raw,
                  onAddToGear: (isTreasureProject && hasReachedGoal)
                      ? () => _addTreasureToGear(
                          context, ref, project, matchingTreasure)
                      : (isImbuementProject && hasReachedGoal)
                          ? () => _addImbuementToGear(
                              context, ref, project, matchingImbuement)
                          : null,
                );
              },
              childCount: projects.where((p) => !p.isCompleted).length,
            ),
          ),
        ],

        // Completed projects
        if (projects.where((p) => p.isCompleted).isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    ProjectsListTabText.completedProjectsHeader,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final completedProjects =
                    projects.where((p) => p.isCompleted).toList();
                final project = completedProjects[index];
                final matchingTreasure =
                    _findMatchingTreasure(project, treasures);
                final matchingImbuement =
                    _findMatchingImbuement(project, imbuements);
                final isTreasureProject = matchingTreasure != null;
                final isImbuementProject = matchingImbuement != null;
                return ProjectDetailCard(
                  project: project,
                  heroId: heroId,
                  onTap: () => _editProject(context, ref, project),
                  onDelete: () => _deleteProject(context, ref, project),
                  isTreasureProject: isTreasureProject,
                  treasureData: matchingTreasure?.raw,
                  isImbuementProject: isImbuementProject,
                  imbuementData: matchingImbuement?.raw,
                  onAddToGear: isTreasureProject
                      ? () => _addTreasureToGear(
                          context, ref, project, matchingTreasure)
                      : isImbuementProject
                          ? () => _addImbuementToGear(
                              context, ref, project, matchingImbuement)
                          : null,
                );
              },
              childCount: projects.where((p) => p.isCompleted).length,
            ),
          ),
        ],

        // Empty state
        if (projects.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, ref),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildAddProjectButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _createCustomProject(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _projectsColor),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: _projectsColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        ProjectsListTabText.createProjectButtonLabel,
                        style: TextStyle(
                          color: _projectsColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _browseTemplates(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books,
                          color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        ProjectsListTabText.browseProjectsButtonLabel,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              ProjectsListTabText.emptyTitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ProjectsListTabText.emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _projectsColor,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              ProjectsListTabText.errorTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Material(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => ref.invalidate(heroProjectsProvider(heroId)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _projectsColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: _projectsColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        ProjectsListTabText.retryButtonLabel,
                        style: TextStyle(
                            color: _projectsColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createCustomProject(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<HeroDowntimeProject>(
      context: context,
      builder: (context) => ProjectEditorDialog(heroId: heroId),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.createProject(
        heroId: heroId,
        name: result.name,
        description: result.description,
        projectGoal: result.projectGoal,
        prerequisites: result.prerequisites,
        projectSource: result.projectSource,
        sourceLanguage: result.sourceLanguage,
        guides: result.guides,
        rollCharacteristics: result.rollCharacteristics,
        isCustom: true,
      );

      // Refresh the list
      ref.invalidate(heroProjectsProvider(heroId));
    }
  }

  void _deleteProject(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ProjectsListTabText.deleteDialogTitle),
        content: Text(
          'Are you sure you want to remove "${project.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(ProjectsListTabText.deleteDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(ProjectsListTabText.deleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.deleteProject(project.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${project.name}"'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      // Refresh the list
      ref.invalidate(heroProjectsProvider(heroId));
    }
  }

  void _editProject(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
  ) async {
    final result = await showDialog<HeroDowntimeProject>(
      context: context,
      builder: (context) => ProjectEditorDialog(
        heroId: heroId,
        existingProject: project,
      ),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.updateProject(result);

      // Refresh the list
      ref.invalidate(heroProjectsProvider(heroId));
    }
  }

  void _addPointsToProject(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
  ) async {
    final pointsController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ProjectsListTabText.addPointsDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add points to: ${project.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${project.currentPoints} / ${project.projectGoal}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(
                labelText: ProjectsListTabText.addPointsFieldLabel,
                border: OutlineInputBorder(),
                hintText: ProjectsListTabText.addPointsFieldHint,
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(ProjectsListTabText.addPointsDialogCancel),
          ),
          FilledButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text);
              if (points != null && points > 0) {
                Navigator.of(context).pop(points);
              }
            },
            child: const Text(ProjectsListTabText.addPointsDialogConfirm),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      final repo = ref.read(downtimeRepositoryProvider);
      final newTotal = project.currentPoints + result;
      await repo.updateProjectPoints(project.id, newTotal);

      // Refresh the list
      ref.invalidate(heroProjectsProvider(heroId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $result points to ${project.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _rollForProject(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => ProjectRollDialog(
        heroId: heroId,
        project: project,
      ),
    );

    if (result != null && result > 0) {
      final repo = ref.read(downtimeRepositoryProvider);
      final newTotal = project.currentPoints + result;
      await repo.updateProjectPoints(project.id, newTotal);

      // Refresh the list
      ref.invalidate(heroProjectsProvider(heroId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $result points to ${project.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _browseTemplates(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ProjectTemplateBrowser(heroId: heroId),
    );
  }

  void _addTreasureToGear(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
    CraftableTreasure treasure,
  ) async {
    final treasureId = treasure.id;

    // Get current hero treasures
    final db = ref.read(appDatabaseProvider);
    final existingTreasures = await db.getHeroComponentIds(heroId, 'treasure');

    // Check if already added
    if (existingTreasures.contains(treasureId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${treasure.name}" is already in your gear!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Add treasure to hero's gear
    try {
      await db.addHeroComponentId(
        heroId: heroId,
        componentId: treasureId,
        category: 'treasure',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${treasure.name}" to your gear!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add treasure: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addImbuementToGear(
    BuildContext context,
    WidgetRef ref,
    HeroDowntimeProject project,
    DowntimeEntry imbuement,
  ) async {
    final imbuementId = imbuement.id;

    // Get current hero imbuements (stored in 'imbuement' category)
    final db = ref.read(appDatabaseProvider);
    final existingImbuements =
        await db.getHeroComponentIds(heroId, 'imbuement');

    // Check if already added
    if (existingImbuements.contains(imbuementId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${imbuement.name}" is already in your gear!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Add imbuement to hero's gear
    try {
      await db.addHeroComponentId(
        heroId: heroId,
        componentId: imbuementId,
        category: 'imbuement',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${imbuement.name}" to your gear!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add imbuement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
