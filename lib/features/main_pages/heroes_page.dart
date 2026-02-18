import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/services/hero_export_service.dart';
import '../../core/services/hero_file_service.dart';
import '../../core/theme/ability_colors.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/text/main_pages/heroes_page_text.dart';
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
              HeroesPageText.aboutHeroSmith,
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
                  child: AppIcon(StoryIcons.yourHeroes, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HeroesPageText.yourHeroes,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        HeroesPageText.heroesSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: FormTheme.textSecondary,
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
                  label: Text(HeroesPageText.createNewHero),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: FormTheme.textBright,
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: accent),
                color: NavigationTheme.cardBackgroundDark,
                tooltip: HeroesPageText.importExportTooltip,
                onSelected: (value) async {
                  switch (value) {
                    case 'import_code':
                      await _showImportDialog(context, ref);
                    case 'import_file':
                      await _importHeroFile(context, ref);
                    case 'export_all':
                      await _exportAllHeroes(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'import_code',
                    child: Row(
                      children: [
                        Icon(Icons.content_paste, color: FormTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(HeroesPageText.importFromCode,
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import_file',
                    child: Row(
                      children: [
                        Icon(Icons.file_open, color: FormTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(HeroesPageText.importFromFile,
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'export_all',
                    child: Row(
                      children: [
                        Icon(Icons.save_alt, color: FormTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(HeroesPageText.exportAllHeroes,
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                ],
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
                  _buildChip(context, HeroesPageText.heroLevel(hero.level), accent),
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: NavigationTheme.cardIconDecoration(accent),
                    child: AppIcon(
                      StoryIcons.heroAvatar,
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
                icon: AppIcon(StoryIcons.editHero, color: FormTheme.textSecondary),
                tooltip: HeroesPageText.editHeroTooltip,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HeroCreatorPage(heroId: hero.id),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: FormTheme.textSecondary),
                color: NavigationTheme.cardBackgroundDark,
                onSelected: (value) async {
                  if (value == 'export') {
                    await _exportHeroCode(context, ref, hero);
                  } else if (value == 'export_file') {
                    await _exportHeroFile(context, ref, hero);
                  } else if (value == 'delete') {
                    await _deleteHero(context, ref, hero);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: FormTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(HeroesPageText.exportCode,
                            style: TextStyle(color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_file',
                    child: Row(
                      children: [
                        Icon(Icons.save_alt, color: FormTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(HeroesPageText.exportFile,
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
                        Text(HeroesPageText.delete,
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
    return Stack(
      children: [
        // About button in top-right corner
        Positioned(
          top: 16,
          right: 16,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
            icon: Icon(Icons.info_outline, color: accent, size: 18),
            label: Text(
              HeroesPageText.about,
              style: TextStyle(color: accent, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        // Main empty state content
        HeroTheme.buildEmptyState(
          context,
          icon: Icons.person_add,
          title: HeroesPageText.noHeroesYet,
          subtitle: HeroesPageText.emptySubtitle,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
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
                label: Text(HeroesPageText.createFirstHero),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: FormTheme.textBright,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showImportDialog(context, ref),
                    icon: Icon(Icons.content_paste, color: accent),
                    label:
                        Text(HeroesPageText.importCode, style: TextStyle(color: accent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _importHeroFile(context, ref),
                    icon: Icon(Icons.file_open, color: accent),
                    label:
                        Text(HeroesPageText.importFile, style: TextStyle(color: accent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
              HeroesPageText.failedToLoadHeroes,
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
                color: FormTheme.textSecondary,
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
              label: Text(HeroesPageText.retry),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: FormTheme.textBright,
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
            HeroesPageText.loadingHeroes,
            style: TextStyle(
              fontSize: 16,
              color: FormTheme.textSecondary,
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
        title: Text(HeroesPageText.deleteHero),
        content: Text(
            HeroesPageText.deleteConfirmation(hero.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(HeroesPageText.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete),
            label: Text(HeroesPageText.delete),
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
        SnackBar(content: Text(HeroesPageText.deletedHero(hero.name))),
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
                Expanded(child: Text(HeroesPageText.exportName(hero.name))),
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
                  HeroesPageText.exportShareMessage,
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
                  HeroesPageText.codeInfo(codeLength, selectedTier.description),
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
                child: Text(HeroesPageText.close),
              ),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: FormTheme.textBright),
                          const SizedBox(width: 12),
                          Text(HeroesPageText.codeCopied),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.copy),
                label: Text(HeroesPageText.copyCode),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(HeroesPageText.failedToExportHero(e))),
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
                Text(HeroesPageText.importHero),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HeroesPageText.importPasteMessage,
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
                    hintText: HeroesPageText.importHintText,
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: HeroesPageText.pasteFromClipboard,
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
                    HeroesPageText.characterCount(controller.text.length),
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
                child: Text(HeroesPageText.cancel),
              ),
              FilledButton.icon(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(ctx).pop(controller.text.trim()),
                icon: const Icon(Icons.download),
                label: Text(HeroesPageText.import_),
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
            content: Row(
              children: [
                Icon(Icons.error_outline, color: FormTheme.textBright),
                const SizedBox(width: 12),
                Text(HeroesPageText.invalidHeroCodeFormat),
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
                Icon(Icons.warning_amber, color: FormTheme.textBright),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    HeroesPageText.incompatibleVersion(preview.formatVersion),
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
              Icon(Icons.check_circle, color: FormTheme.textBright),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      Text(HeroesPageText.importedSuccessfully(preview.name, tierInfo))),
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
              Icon(Icons.error_outline, color: FormTheme.textBright),
              const SizedBox(width: 12),
              Expanded(child: Text(HeroesPageText.failedToImport(e))),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportHeroFile(
      BuildContext context, WidgetRef ref, dynamic hero) async {
    // Show tier selection dialog first
    final selectedTier = await showDialog<ExportTier>(
      context: context,
      builder: (ctx) => _ExportOptionsDialog(heroName: hero.name),
    );

    if (selectedTier == null || !context.mounted) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final fileService = HeroFileService(db);
      final success = await fileService.exportHeroToFile(
        hero.id,
        heroName: hero.name,
        tier: selectedTier,
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: FormTheme.textBright),
                const SizedBox(width: 12),
                Expanded(child: Text(HeroesPageText.exportedToFile(hero.name))),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(HeroesPageText.failedToExportFile(e))),
      );
    }
  }

  Future<void> _importHeroFile(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final fileService = HeroFileService(db);
      final heroId = await fileService.importHeroFromFile();

      if (heroId == null || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: FormTheme.textBright),
              const SizedBox(width: 12),
              Text(HeroesPageText.heroImportedSuccessfully),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HeroCreatorPage(heroId: heroId)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: FormTheme.textBright),
              const SizedBox(width: 12),
              Expanded(child: Text(HeroesPageText.failedToImportFile(e))),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportAllHeroes(BuildContext context, WidgetRef ref) async {
    // Show tier selection for all heroes
    final selectedTier = await showDialog<ExportTier>(
      context: context,
      builder: (ctx) => _ExportOptionsDialog(heroName: HeroesPageText.allHeroes),
    );

    if (selectedTier == null || !context.mounted) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final fileService = HeroFileService(db);
      final count = await fileService.exportAllHeroesToFiles(tier: selectedTier);

      if (!context.mounted) return;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: FormTheme.textBright),
                const SizedBox(width: 12),
                Expanded(child: Text(HeroesPageText.exportedHeroesToFiles(count))),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(HeroesPageText.noHeroesToExport)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(HeroesPageText.failedToExportHeroes(e))),
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
          Expanded(child: Text(HeroesPageText.exportName(widget.heroName))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HeroesPageText.chooseExportContent,
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
          child: Text(HeroesPageText.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTier),
          child: Text(HeroesPageText.export_),
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
