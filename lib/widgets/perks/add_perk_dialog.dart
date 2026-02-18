import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/component.dart' as model;
import '../../core/text/heroes_sheet/story/sheet_story_perks_tab_text.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/story_theme.dart';

/// Accent color for perk dialogs.
const _perksColor = StoryTheme.perksAccent;

/// Dialog for adding a perk to a hero.
class AddPerkDialog extends ConsumerStatefulWidget {
  final String heroId;
  final Set<String> selectedPerkIds;
  final Function(String) onPerkSelected;

  const AddPerkDialog({
    super.key,
    required this.heroId,
    required this.selectedPerkIds,
    required this.onPerkSelected,
  });

  @override
  ConsumerState<AddPerkDialog> createState() => _AddPerkDialogState();
}

class _AddPerkDialogState extends ConsumerState<AddPerkDialog> {
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
                    child: AppIcon(PerkGroupIcons.tab, color: _perksColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      SheetStoryPerksTabText.addPerk,
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
            // Search and filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(color: FormTheme.textBright),
                    decoration: InputDecoration(
                      labelText: SheetStoryPerksTabText.searchPerks,
                      labelStyle: TextStyle(color: FormTheme.textSecondary),
                      prefixIcon:
                          Icon(Icons.search, color: FormTheme.textSecondary),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', null),
                      ..._groups.map((group) =>
                          _buildFilterChip(_capitalize(group), group)),
                    ],
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
                                size: 48, color: FormTheme.borderLight),
                            const SizedBox(height: 16),
                            Text(
                              SheetStoryPerksTabText.noPerksFound,
                              style: TextStyle(color: FormTheme.textSecondary),
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
                            border: Border.all(color: FormTheme.borderDim),
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
                              style: TextStyle(
                                  color: FormTheme.textBright,
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
                                        color: FormTheme.textMuted,
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
            color: isSelected ? _perksColor : FormTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _perksColor : FormTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
