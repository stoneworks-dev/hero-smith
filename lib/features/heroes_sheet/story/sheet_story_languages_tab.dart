part of 'sheet_story.dart';

// Languages accent color
const _languagesColor = StoryTheme.languagesAccent;

// Languages Tab Widget
class _LanguagesTab extends ConsumerStatefulWidget {
  final String heroId;

  const _LanguagesTab({required this.heroId});

  @override
  ConsumerState<_LanguagesTab> createState() => _LanguagesTabState();
}

class _LanguagesTabState extends ConsumerState<_LanguagesTab> {
  List<_LanguageOption> _availableLanguages = [];
  List<String> _selectedLanguageIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load languages from JSON - it's a direct array, not wrapped in an object
      final languagesData = await rootBundle.loadString('data/story/languages.json');
      final languagesList = json.decode(languagesData) as List;

      _availableLanguages = languagesList.map((lang) {
        final langMap = lang as Map<String, dynamic>;
        return _LanguageOption(
          id: langMap['id'] as String,
          name: langMap['name'] as String,
          languageType: langMap['language_type'] as String? ?? '',
          region: langMap['region'] as String? ?? '',
          ancestry: langMap['ancestry'] as String? ?? '',
        );
      }).toList();

      // Load selected languages for this hero
      final db = ref.read(appDatabaseProvider);
      _selectedLanguageIds = await db.getHeroComponentIds(widget.heroId, 'language');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load languages: $e';
      });
    }
  }

  Future<void> _addLanguage(String languageId) async {
    if (_selectedLanguageIds.contains(languageId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SheetStoryLanguagesTabText.languageAlreadyAdded)),
        );
      }
      return;
    }
    try {
      final db = ref.read(appDatabaseProvider);
      final updatedIds = [..._selectedLanguageIds, languageId];
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'language',
        componentIds: updatedIds,
      );

      setState(() {
        _selectedLanguageIds = updatedIds;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add language: $e')),
        );
      }
    }
  }

  Future<void> _removeLanguage(String languageId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final updatedIds = _selectedLanguageIds.where((id) => id != languageId).toList();
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'language',
        componentIds: updatedIds,
      );

      setState(() {
        _selectedLanguageIds = updatedIds;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove language: $e')),
        );
      }
    }
  }

  void _showAddLanguageDialog() {
    final unselectedLanguages = _availableLanguages
        .where((lang) => !_selectedLanguageIds.contains(lang.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddLanguageDialog(
        availableLanguages: unselectedLanguages,
        onLanguageSelected: (languageId) {
          _addLanguage(languageId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _languagesColor),
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
                backgroundColor: _languagesColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    final selectedLanguages = _availableLanguages
        .where((lang) => _selectedLanguageIds.contains(lang.id))
        .toList();

    // Group languages by type
    final groupedLanguages = <String, List<_LanguageOption>>{};
    for (final lang in selectedLanguages) {
      final groupKey = lang.languageType.isNotEmpty
          ? lang.languageType
          : SheetStoryLanguagesTabText.otherGroup;
      groupedLanguages.putIfAbsent(groupKey, () => []).add(lang);
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
                  border: Border.all(color: Colors.grey.shade800),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _languagesColor.withAlpha(38),
                      _languagesColor.withAlpha(10),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _languagesColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.translate, color: _languagesColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            SheetStoryLanguagesTabText.languagesTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedLanguages.length} languages known',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedLanguages.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.language_outlined, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          SheetStoryLanguagesTabText.emptyState,
                          style: TextStyle(color: Colors.grey.shade400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groupedLanguages.entries.map((entry) {
                  final groupName = entry.key;
                  final languages = entry.value;

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
                                color: _languagesColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              groupName,
                              style: const TextStyle(
                                color: _languagesColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...languages.map((lang) => _buildLanguageCard(lang)),
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
            onPressed: _showAddLanguageDialog,
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: _languagesColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _languagesColor, width: 2),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(_LanguageOption lang) {
    String subtitle = '';
    if (lang.region.isNotEmpty) {
      subtitle = 'Region: ${lang.region}';
    }
    if (lang.ancestry.isNotEmpty) {
      subtitle = subtitle.isEmpty
          ? 'Ancestry: ${lang.ancestry}'
          : '$subtitle • Ancestry: ${lang.ancestry}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _languagesColor.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.record_voice_over, color: _languagesColor, size: 18),
        ),
        title: Text(
          lang.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
          onPressed: () => _removeLanguage(lang.id),
          tooltip: SheetStoryLanguagesTabText.removeLanguageTooltip,
        ),
      ),
    );
  }
}

class _AddLanguageDialog extends StatefulWidget {
  final List<_LanguageOption> availableLanguages;
  final Function(String) onLanguageSelected;

  const _AddLanguageDialog({
    required this.availableLanguages,
    required this.onLanguageSelected,
  });

  @override
  State<_AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends State<_AddLanguageDialog> {
  // ignore: unused_field
  String _searchQuery = '';
  List<_LanguageOption> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = widget.availableLanguages;
  }

  void _filterLanguages(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredLanguages = widget.availableLanguages;
      } else {
        _filteredLanguages = widget.availableLanguages
            .where((lang) =>
                lang.name.toLowerCase().contains(query.toLowerCase()) ||
                lang.region.toLowerCase().contains(query.toLowerCase()) ||
                lang.ancestry.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group filtered languages by type
    final groupedLanguages = <String, List<_LanguageOption>>{};
    for (final lang in _filteredLanguages) {
      final groupKey = lang.languageType.isNotEmpty
          ? lang.languageType
          : SheetStoryLanguagesTabText.otherGroup;
      groupedLanguages.putIfAbsent(groupKey, () => []).add(lang);
    }

    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
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
                    _languagesColor.withAlpha(51),
                    _languagesColor.withAlpha(13),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _languagesColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.translate, color: _languagesColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      SheetStoryLanguagesTabText.addLanguageDialogTitle,
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
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: SheetStoryLanguagesTabText.searchLanguagesLabel,
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: StoryTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _languagesColor, width: 2),
                  ),
                ),
                onChanged: _filterLanguages,
              ),
            ),
            // Languages list
            Flexible(
              child: _filteredLanguages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            Text(
                              SheetStoryLanguagesTabText.noLanguagesFound,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: groupedLanguages.entries.expand((entry) {
                        final groupName = entry.key;
                        final languages = entry.value;
                        return [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _languagesColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  groupName,
                                  style: const TextStyle(
                                    color: _languagesColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...languages.map((lang) {
                            String subtitle = '';
                            if (lang.region.isNotEmpty) {
                              subtitle = 'Region: ${lang.region}';
                            }
                            if (lang.ancestry.isNotEmpty) {
                              subtitle = subtitle.isEmpty
                                  ? 'Ancestry: ${lang.ancestry}'
                                  : '$subtitle • Ancestry: ${lang.ancestry}';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: StoryTheme.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _languagesColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add_circle_outline, color: _languagesColor, size: 18),
                                ),
                                title: Text(
                                  lang.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                subtitle: subtitle.isNotEmpty
                                    ? Text(
                                        subtitle,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      )
                                    : null,
                                onTap: () => widget.onLanguageSelected(lang.id),
                              ),
                            );
                          }),
                        ];
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String id;
  final String name;
  final String languageType;
  final String region;
  final String ancestry;

  _LanguageOption({
    required this.id,
    required this.name,
    required this.languageType,
    required this.region,
    required this.ancestry,
  });
}
