import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/providers.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/theme/hero_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/sources_tab_text.dart';

/// Accent color for sources
const Color _sourcesColor = NavigationTheme.projectsTabColor;

/// Provider for hero project sources
final heroSourcesProvider =
    FutureProvider.family<List<ProjectSource>, String>((ref, heroId) async {
  final repo = ref.read(downtimeRepositoryProvider);
  return await repo.getHeroSources(heroId);
});

class SourcesTab extends ConsumerWidget {
  const SourcesTab({super.key, required this.heroId});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(heroSourcesProvider(heroId));

    return sourcesAsync.when(
      data: (sources) => _buildContent(context, ref, sources),
      loading: () => const Center(child: CircularProgressIndicator(color: _sourcesColor)),
      error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: Colors.red.shade400))),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ProjectSource> sources,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildAddButton(context, ref),
        ),
        if (sources.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, ref),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSourceCard(
                context,
                ref,
                sources[index],
              ),
              childCount: sources.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        onPressed: () => _addSource(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(SourcesTabText.addSourceButtonLabel),
        style: FilledButton.styleFrom(
          backgroundColor: _sourcesColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSourceCard(BuildContext context, WidgetRef ref, ProjectSource source) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;

    switch (source.type) {
      case 'source':
        icon = Icons.menu_book;
        iconColor = Colors.blue.shade400;
        break;
      case 'item':
        icon = Icons.inventory_2;
        iconColor = Colors.amber.shade400;
        break;
      case 'guide':
        icon = Icons.person;
        iconColor = Colors.green.shade400;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey.shade400;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withAlpha(40),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          source.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.type.toUpperCase(),
              style: TextStyle(color: _sourcesColor, fontWeight: FontWeight.w500, fontSize: 12),
            ),
            if (source.language != null) ...[
              const SizedBox(height: 2),
              Text('Language: ${source.language}', style: TextStyle(color: Colors.grey.shade400)),
            ],
            if (source.description != null && source.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                source.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
          color: NavigationTheme.cardBackgroundDark,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(SourcesTabText.editMenuLabel, style: TextStyle(color: Colors.grey.shade300)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(SourcesTabText.deleteMenuLabel, style: TextStyle(color: Colors.red.shade400)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _editSource(context, ref, source);
            } else if (value == 'delete') {
              _deleteSource(context, ref, source);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return HeroTheme.buildEmptyState(
      context,
      icon: Icons.book_outlined,
      title: SourcesTabText.emptyTitle,
      subtitle: SourcesTabText.emptySubtitle,
      action: FilledButton.icon(
        onPressed: () => _addSource(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(SourcesTabText.emptyActionLabel),
        style: FilledButton.styleFrom(
          backgroundColor: _sourcesColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _addSource(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<ProjectSource>(
      context: context,
      builder: (context) => _SourceEditorDialog(heroId: heroId),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.createSource(
        heroId: heroId,
        name: result.name,
        type: result.type,
        language: result.language,
        description: result.description,
      );
      ref.invalidate(heroSourcesProvider(heroId));
    }
  }

  void _editSource(BuildContext context, WidgetRef ref, ProjectSource source) async {
    final result = await showDialog<ProjectSource>(
      context: context,
      builder: (context) => _SourceEditorDialog(
        heroId: heroId,
        existingSource: source,
      ),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.updateSource(result);
      ref.invalidate(heroSourcesProvider(heroId));
    }
  }

  void _deleteSource(BuildContext context, WidgetRef ref, ProjectSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        title: Text(
          SourcesTabText.deleteDialogTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove ${source.name}?',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text(SourcesTabText.deleteDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text(SourcesTabText.deleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.deleteSource(source.id);
      ref.invalidate(heroSourcesProvider(heroId));
    }
  }
}

class _SourceEditorDialog extends StatefulWidget {
  const _SourceEditorDialog({
    required this.heroId,
    this.existingSource,
  });

  final String heroId;
  final ProjectSource? existingSource;

  @override
  State<_SourceEditorDialog> createState() => _SourceEditorDialogState();
}

class _SourceEditorDialogState extends State<_SourceEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _languageController;
  late final TextEditingController _descriptionController;
  late String _selectedType;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final source = widget.existingSource;
    
    _nameController = TextEditingController(text: source?.name ?? '');
    _languageController = TextEditingController(text: source?.language ?? '');
    _descriptionController = TextEditingController(text: source?.description ?? '');
    _selectedType = source?.type ?? 'source';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _languageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _sourcesColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.existingSource == null ? Icons.add_circle : Icons.edit,
              color: _sourcesColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingSource == null
                  ? SourcesTabText.dialogTitleAdd
                  : SourcesTabText.dialogTitleEdit,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: SourcesTabText.nameLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _sourcesColor)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
                validator: (v) => v == null || v.isEmpty
                    ? SourcesTabText.nameRequiredError
                    : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: NavigationTheme.cardBackgroundDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: SourcesTabText.typeLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _sourcesColor)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'source',
                    child: Text(SourcesTabText.typeOptionSource),
                  ),
                  DropdownMenuItem(
                    value: 'item',
                    child: Text(SourcesTabText.typeOptionItem),
                  ),
                  DropdownMenuItem(
                    value: 'guide',
                    child: Text(SourcesTabText.typeOptionGuide),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _languageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: SourcesTabText.languageLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _sourcesColor)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: SourcesTabText.descriptionLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _sourcesColor)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
          child: const Text(SourcesTabText.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _sourcesColor,
            foregroundColor: Colors.white,
          ),
          child: const Text(SourcesTabText.saveButtonLabel),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final source = widget.existingSource?.copyWith(
      name: _nameController.text,
      type: _selectedType,
      language: _languageController.text.isEmpty ? null : _languageController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    ) ?? ProjectSource(
      id: '',
      heroId: widget.heroId,
      name: _nameController.text,
      type: _selectedType,
      language: _languageController.text.isEmpty ? null : _languageController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    Navigator.pop(context, source);
  }
}
