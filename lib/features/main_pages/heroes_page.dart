import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/services/hero_export_service.dart';
import '../../core/theme/ability_colors.dart';
import '../../core/theme/hero_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../about/about_page.dart';
import '../creators/hero_creators/hero_creator_page.dart';
import '../heroes_sheet/hero_sheet_page.dart';
// import '../creators/hero_creators/strife_creator_page.dart';
// OutlinedButton.icon(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(builder: (_) => const StrifeCreatorPage2()),
//               );
//             },
//             icon: const Icon(Icons.science),
//             label: const Text('Test New Creator (Demo)'),
//           ),

class HeroesPage extends ConsumerWidget {
  const HeroesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(heroSummariesProvider);

    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      body: summariesAsync.when(
        data: (items) => _buildContent(context, ref, items),
        error: (e, st) => _buildErrorState(context, ref, e),
        loading: () => _buildLoadingState(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List items) {
    if (items.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return CustomScrollView(
      slivers: [
        // About app button
        SliverToBoxAdapter(
          child: _buildAboutSection(context),
        ),

        // Header section
        SliverToBoxAdapter(
          child: _buildHeader(context),
        ),

        // Create hero button
        SliverToBoxAdapter(
          child: _buildCreateHeroSection(context, ref),
        ),

        // Heroes list
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildHeroCard(context, ref, items[index]),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final accent = NavigationTheme.heroesColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
            icon: Icon(Icons.info_outline, color: accent, size: 18),
            label: Text(
              'About Hero Smith',
              style: TextStyle(color: accent, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final accent = NavigationTheme.heroesColor;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        color: NavigationTheme.cardBackgroundDark,
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.2),
                  accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom:
                    BorderSide(color: accent.withValues(alpha: 0.3), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: NavigationTheme.cardIconDecoration(accent),
                  child: Icon(Icons.shield, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Heroes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and manage your Draw Steel heroes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateHeroSection(BuildContext context, WidgetRef ref) {
    final accent = NavigationTheme.heroesColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final repo = ref.read(heroRepositoryProvider);
                    final id = await repo.createHero(name: '');
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => HeroCreatorPage(heroId: id)),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Hero'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showImportDialog(context, ref),
                icon: Icon(Icons.download, color: accent),
                label: Text('Import', style: TextStyle(color: accent)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WidgetRef ref, dynamic hero) {
    final accent = hero.heroicResourceName != null
        ? AbilityColors.getHeroicResourceColor(hero.heroicResourceName!)
        : NavigationTheme.heroesColor;
    final chips = <Widget>[];

    // Add class/subclass chip - combined into one
    if (hero.className != null && hero.className!.isNotEmpty) {
      final resourceColor = hero.heroicResourceName != null
          ? AbilityColors.getHeroicResourceColor(hero.heroicResourceName!)
          : HeroTheme.primarySection;
      
      // Combine class and subclass: "Class: Subclass" or just "Class"
      final hasSubclass = hero.subclassName != null && hero.subclassName!.isNotEmpty;
      final classLabel = hasSubclass
          ? '${hero.className!}: ${hero.subclassName!}'
          : hero.className!;
      
      chips.add(_buildChip(context, classLabel, resourceColor));
    }
    if (hero.ancestryName != null && hero.ancestryName!.isNotEmpty) {
      chips
          .add(_buildChip(context, hero.ancestryName!, HeroTheme.ancestryStep));
    }
    if (hero.careerName != null && hero.careerName!.isNotEmpty) {
      chips.add(_buildChip(context, hero.careerName!, HeroTheme.careerStep));
    }
    if (hero.complicationName != null && hero.complicationName!.isNotEmpty) {
      chips.add(_buildChip(
          context, hero.complicationName!, NavigationTheme.conditionsColor));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      color: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HeroSheetPage(
                heroId: hero.id,
                heroName: hero.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(NavigationTheme.cardBorderRadius),
            border: Border(
              left: BorderSide(
                color: accent,
                width: NavigationTheme.cardAccentStripeWidth,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChip(context, 'Lvl ${hero.level}', accent),
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: NavigationTheme.cardIconDecoration(accent),
                    child: Icon(
                      Icons.person,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade100,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chips,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade400),
                tooltip: 'Edit Hero',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HeroCreatorPage(heroId: hero.id),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                color: NavigationTheme.cardBackgroundDark,
                onSelected: (value) async {
                  if (value == 'export') {
                    await _exportHeroCode(context, ref, hero);
                  } else if (value == 'delete') {
                    await _deleteHero(context, ref, hero);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.grey.shade300),
                        const SizedBox(width: 8),
                        Text('Export Code',
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final accent = NavigationTheme.heroesColor;
    return HeroTheme.buildEmptyState(
      context,
      icon: Icons.person_add,
      title: 'No Heroes Yet',
      subtitle: 'Create your first hero to begin your Draw Steel adventure',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final repo = ref.read(heroRepositoryProvider);
              final id = await repo.createHero(name: '');
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HeroCreatorPage(heroId: id)),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Hero'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showImportDialog(context, ref),
            icon: Icon(Icons.download, color: accent),
            label: Text('Import Hero', style: TextStyle(color: accent)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final accent = NavigationTheme.heroesColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Heroes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Refresh by rebuilding the provider
                ref.invalidate(heroSummariesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final accent = NavigationTheme.heroesColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: accent,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading heroes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHero(
      BuildContext context, WidgetRef ref, dynamic hero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hero'),
        content: Text(
            'Are you sure you want to delete "${hero.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(heroRepositoryProvider);
      await repo.deleteHero(hero.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${hero.name}')),
      );
    }
  }

  Future<void> _exportHeroCode(
      BuildContext context, WidgetRef ref, dynamic hero) async {
    // Show tier selection dialog first
    final selectedTier = await showDialog<ExportTier>(
      context: context,
      builder: (ctx) => _ExportOptionsDialog(heroName: hero.name),
    );

    if (selectedTier == null || !context.mounted) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final exportService = HeroExportService(db);

      // Generate compressed database snapshot with selected tier
      final code = await exportService.exportHeroToCode(
        hero.id,
        tier: selectedTier,
      );

      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final codeLength = code.length;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.upload_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Export ${hero.name}')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier info chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedTier.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Share this code with a friend so they can import your hero build.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Code preview container with scroll
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Code info
                Text(
                  '$codeLength characters • ${selectedTier.description}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Code copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export hero: $e')),
      );
    }
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Import Hero'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste a hero code from a friend to add their build to your heroes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                  decoration: InputDecoration(
                    hintText: 'HS2:...',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          controller.text = data!.text!;
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (controller.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${controller.text.length} characters',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(ctx).pop(controller.text.trim()),
                icon: const Icon(Icons.download),
                label: const Text('Import'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final exportService = HeroExportService(db);

      // Validate first
      final preview = exportService.validateCode(result);
      if (preview == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Invalid hero code format'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!preview.isCompatible) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Incompatible version (v${preview.formatVersion}). Please ask for an updated code.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Import the hero
      final newHeroId = await exportService.importHeroFromCode(result);

      if (!context.mounted) return;

      // Show success message with tier info
      final tierInfo = preview.exportTier != null
          ? ' (${preview.tierDescription})'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      Text('Imported "${preview.name}"$tierInfo successfully!')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to the imported hero
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HeroCreatorPage(heroId: newHeroId)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to import: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Dialog for selecting export tier options
class _ExportOptionsDialog extends StatefulWidget {
  const _ExportOptionsDialog({required this.heroName});

  final String heroName;

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  ExportTier _selectedTier = ExportTier.full;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('Export ${widget.heroName}')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose what to include in the export:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...ExportTier.values.map((tier) => _buildTierOption(tier, theme)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTier),
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildTierOption(ExportTier tier, ThemeData theme) {
    final isSelected = _selectedTier == tier;

    return InkWell(
      onTap: () => setState(() => _selectedTier = tier),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Radio<ExportTier>(
              value: tier,
              groupValue: _selectedTier,
              onChanged: (val) {
                if (val != null) setState(() => _selectedTier = val);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
