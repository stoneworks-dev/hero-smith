import 'package:flutter/material.dart';
import '../../core/text/heroes_sheet/story/sheet_story_titles_tab_text.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/theme/story_theme.dart';

/// Accent color for title dialogs.
const _titlesColor = StoryTheme.titlesAccent;

/// Dialog for adding a title to a hero.
class AddTitleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableTitles;
  final Function(String, int) onTitleSelected;

  const AddTitleDialog({
    super.key,
    required this.availableTitles,
    required this.onTitleSelected,
  });

  @override
  State<AddTitleDialog> createState() => _AddTitleDialogState();
}

class _AddTitleDialogState extends State<AddTitleDialog> {
  String _searchQuery = '';
  int? _selectedEchelon;
  List<Map<String, dynamic>> _filteredTitles = [];

  @override
  void initState() {
    super.initState();
    _filteredTitles = widget.availableTitles;
  }

  void _filterTitles() {
    setState(() {
      _filteredTitles = widget.availableTitles.where((title) {
        final matchesSearch = _searchQuery.isEmpty ||
            (title['name'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            (title['description_text'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;

        final matchesEchelon =
            _selectedEchelon == null || title['echelon'] == _selectedEchelon;

        return matchesSearch && matchesEchelon;
      }).toList();
    });
  }

  void _showBenefitSelectionDialog(Map<String, dynamic> title) {
    final benefits = title['benefits'] as List? ?? [];

    if (benefits.isEmpty) {
      widget.onTitleSelected(title['id'] as String, -1);
      return;
    }

    // Separate auto vs chooseable benefits
    final choiceIndices = <int>[];
    for (int i = 0; i < benefits.length; i++) {
      final b = benefits[i];
      if (b is Map<String, dynamic> && b['auto'] != true) {
        choiceIndices.add(i);
      }
    }

    // If no choices needed (all auto or director-assigned), auto-select with -1
    if (choiceIndices.isEmpty) {
      widget.onTitleSelected(title['id'] as String, -1);
      return;
    }

    // If only one chooseable benefit, auto-select it
    if (choiceIndices.length == 1) {
      widget.onTitleSelected(title['id'] as String, choiceIndices.first);
      return;
    }

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
                      child: const AppIcon(
                        TitleIcons.tab,
                        size: 24,
                        color: _titlesColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        SheetStoryTitlesTabText.selectBenefitFor(
                            title['name'].toString()),
                        style: const TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 16,
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
              // Benefits list — only chooseable (non-auto) benefits
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: choiceIndices.length,
                  itemBuilder: (context, listIndex) {
                    final originalIndex = choiceIndices[listIndex];
                    final benefit = benefits[originalIndex];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: StoryTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FormTheme.borderDim),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          widget.onTitleSelected(title['id'] as String, originalIndex);
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _titlesColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const AppIcon(
                                      TitleIcons.benefits,
                                      size: 16,
                                      color: _titlesColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (benefit is Map<String, dynamic> && benefit['name'] != null)
                                        ? benefit['name'] as String
                                        : SheetStoryTitlesTabText.benefitLabel(listIndex),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: FormTheme.textBright,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (benefit is Map<String, dynamic>) ...[
                                if (benefit['description'] != null)
                                  Text(
                                    benefit['description'] as String,
                                    style: TextStyle(
                                      color: FormTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
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
                    child: const AppIcon(
                      TitleIcons.tab,
                      size: 24,
                      color: _titlesColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      SheetStoryTitlesTabText.addTitleDialogTitle,
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
                    style: const TextStyle(color: FormTheme.textBright),
                    decoration: InputDecoration(
                      labelText: SheetStoryTitlesTabText.searchTitlesLabel,
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
                            const BorderSide(color: _titlesColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterTitles();
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                          SheetStoryTitlesTabText.allFilter, null),
                      ...List.generate(4, (index) {
                        final echelon = index + 1;
                        return _buildFilterChip(
                            SheetStoryTitlesTabText.echelonLabel(echelon),
                            echelon);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            // Titles list
            Expanded(
              child: _filteredTitles.isEmpty
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
                              SheetStoryTitlesTabText.noTitlesFound,
                              style:
                                  TextStyle(color: FormTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTitles.length,
                      itemBuilder: (context, index) {
                        final title = _filteredTitles[index];

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
                                color: _titlesColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AppIcon(
                                TitleIcons.fromEchelon(
                                    title['echelon'] as int? ?? 1),
                                size: 18,
                                color: _titlesColor,
                              ),
                            ),
                            title: Text(
                              title['name'] as String? ??
                                  SheetStoryTitlesTabText.unknown,
                              style: const TextStyle(
                                  color: FormTheme.textBright,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (title['description_text'] != null)
                                  Text(
                                    title['description_text'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: FormTheme.textMuted,
                                        fontSize: 12),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  SheetStoryTitlesTabText
                                      .echelonWithBenefits(
                                          title['echelon'],
                                          (title['benefits'] as List?)
                                                  ?.length ??
                                              0),
                                  style: const TextStyle(
                                    color: _titlesColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showBenefitSelectionDialog(title),
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

  Widget _buildFilterChip(String label, int? echelon) {
    final isSelected = _selectedEchelon == echelon;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEchelon = echelon;
        });
        _filterTitles();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _titlesColor.withAlpha(51)
              : StoryTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _titlesColor : FormTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _titlesColor : FormTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
