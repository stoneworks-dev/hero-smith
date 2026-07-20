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

class _LanguagesTabState extends ConsumerState<_LanguagesTab>
    with AutomaticKeepAliveClientMixin {
  List<_LanguageOption> _availableLanguages = [];
  Map<String, model.Component> _componentMap = {};
  List<String> _selectedLanguageIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

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

      final db = ref.read(appDatabaseProvider);

      // Load ALL languages from the components table (seed + user)
      final allLangRows = await db.getComponentsByType('language');

      _availableLanguages = [];
      _componentMap = {};

      for (final comp in allLangRows) {
        final data = comp.dataJson.isNotEmpty
            ? json.decode(comp.dataJson) as Map<String, dynamic>
            : <String, dynamic>{};

        _availableLanguages.add(_LanguageOption(
          id: comp.id,
          name: comp.name,
          languageType: data['language_type'] as String? ?? '',
          region: data['region'] as String? ?? '',
          ancestry: data['ancestry'] as String? ?? '',
        ));

        _componentMap[comp.id] = model.Component(
          id: comp.id,
          type: comp.type,
          name: comp.name,
          data: data,
          source: comp.source,
        );
      }

      // Load selected languages for this hero
      _selectedLanguageIds =
          await db.getHeroComponentIds(widget.heroId, 'language');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = SheetStoryLanguagesTabText.failedToLoadLanguages(e);
      });
    }
  }

  Future<void> _reloadAvailableLanguages() async {
    final db = ref.read(appDatabaseProvider);
    final allLangRows = await db.getComponentsByType('language');

    final updatedOptions = <_LanguageOption>[];
    final updatedMap = <String, model.Component>{};

    for (final comp in allLangRows) {
      final data = comp.dataJson.isNotEmpty
          ? json.decode(comp.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};

      updatedOptions.add(_LanguageOption(
        id: comp.id,
        name: comp.name,
        languageType: (data['language_type'] as String? ?? '').trim(),
        region: data['region'] as String? ?? '',
        ancestry: data['ancestry'] as String? ?? '',
      ));

      updatedMap[comp.id] = model.Component(
        id: comp.id,
        type: comp.type,
        name: comp.name,
        data: data,
        source: comp.source,
      );
    }

    if (!mounted) return;
    setState(() {
      _availableLanguages = updatedOptions;
      _componentMap = updatedMap;
    });
  }

  Future<void> _addLanguage(String languageId) async {
    final entryRepository = ref.read(heroEntryRepositoryProvider);
    final existingEntries = await entryRepository.listEntriesByType(
      widget.heroId,
      HeroEntryTypes.language,
    );
    final isClaimed = ref.read(heroDuplicateGuardServiceProvider).isReserved(
          candidateId: languageId,
          entries: existingEntries,
          entryType: HeroEntryTypes.language,
        );
    if (isClaimed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(SheetStoryLanguagesTabText.languageAlreadyAdded)),
        );
      }
      return;
    }
    try {
      await entryRepository.addEntry(
        heroId: widget.heroId,
        entryType: HeroEntryTypes.language,
        entryId: languageId,
        sourceType: HeroEntrySourceTypes.heroSheet,
        sourceId: HeroEntryTypes.language,
        gainedBy: HeroEntryGainedBy.choice,
      );

      setState(() {
        _selectedLanguageIds = [..._selectedLanguageIds, languageId];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(SheetStoryLanguagesTabText.failedToAddLanguage(e))),
        );
      }
    }
  }

  Future<void> _removeLanguage(String languageId) async {
    try {
      final removed =
          await ref.read(heroEntryRepositoryProvider).removeEntryFromSource(
                heroId: widget.heroId,
                entryType: HeroEntryTypes.language,
                entryId: languageId,
                sourceType: HeroEntrySourceTypes.heroSheet,
                sourceId: HeroEntryTypes.language,
              );

      if (removed == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                SheetStoryLanguagesTabText.languageOwnedElsewhere,
              ),
            ),
          );
        }
        return;
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(SheetStoryLanguagesTabText.failedToRemoveLanguage(e))),
        );
      }
    }
  }

  Future<void> _showAddLanguageDialog() async {
    await _reloadAvailableLanguages();
    if (!mounted) return;
    final claimedLanguageIds = ref.read(
      heroClaimedEntryIdsProvider(
        (heroId: widget.heroId, entryType: HeroEntryTypes.language),
      ),
    );
    final unselectedLanguages = _availableLanguages
        .where((lang) => !claimedLanguageIds.contains(lang.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddLanguageDialog(
        availableLanguages: unselectedLanguages,
        onLanguageSelected: (languageId) async {
          Navigator.of(context).pop();
          await _addLanguage(languageId);
        },
        onCreateCustom: () {
          Navigator.of(context).pop();
          _showCreateCustomLanguageDialog();
        },
      ),
    );
  }

  void _showCreateCustomLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateCustomLanguageDialog(
        onLanguageCreated: (langOption, extraData) async {
          // Save to Components table with source='user'
          final db = ref.read(appDatabaseProvider);
          await db.upsertComponentModel(
            id: langOption.id,
            type: 'language',
            name: langOption.name,
            dataMap: {
              'language_type': langOption.languageType,
              if (langOption.region.isNotEmpty) 'region': langOption.region,
              if (langOption.ancestry.isNotEmpty)
                'ancestry': langOption.ancestry,
              ...extraData,
            },
            source: 'user',
          );

          // Add to available languages + component map, then select for this hero
          setState(() {
            _availableLanguages.add(langOption);
            _componentMap[langOption.id] = model.Component(
              id: langOption.id,
              type: 'language',
              name: langOption.name,
              data: {
                'language_type': langOption.languageType,
                if (langOption.region.isNotEmpty) 'region': langOption.region,
                if (langOption.ancestry.isNotEmpty)
                  'ancestry': langOption.ancestry,
                ...extraData,
              },
              source: 'user',
            );
          });
          await _addLanguage(langOption.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                foregroundColor: FormTheme.textBright,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    final selectedComponents = _selectedLanguageIds
        .where((id) => _componentMap.containsKey(id))
        .map((id) => _componentMap[id]!)
        .toList();

    // Group languages by type
    final groupedLanguages = <String, List<model.Component>>{};
    for (final comp in selectedComponents) {
      final raw = (comp.data['language_type'] as String? ?? '').trim();
      final groupKey = raw.isNotEmpty
          ? raw.toLowerCase()
          : SheetStoryLanguagesTabText.otherGroup;
      groupedLanguages.putIfAbsent(groupKey, () => []).add(comp);
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
                      child: AppIcon(LanguageTypeIcons.tab,
                          color: _languagesColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SheetStoryLanguagesTabText.languagesTitle,
                            style: TextStyle(
                              color: FormTheme.textBright,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            SheetStoryLanguagesTabText.languagesKnown(
                                selectedComponents.length),
                            style: TextStyle(
                                color: FormTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedComponents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.language_outlined,
                            size: 48, color: FormTheme.borderLight),
                        const SizedBox(height: 16),
                        Text(
                          SheetStoryLanguagesTabText.emptyState,
                          style: TextStyle(color: FormTheme.textSecondary),
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
                            AppIcon(LanguageTypeIcons.fromType(groupName),
                                color: _languagesColor, size: 18),
                            const SizedBox(width: 6),
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
                      ...languages.map((comp) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LanguageCard(
                              language: comp,
                              onRemove: () => _removeLanguage(comp.id),
                            ),
                          )),
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
            heroTag: 'languages_tab_fab',
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
}

class _AddLanguageDialog extends StatefulWidget {
  final List<_LanguageOption> availableLanguages;
  final Function(String) onLanguageSelected;
  final VoidCallback onCreateCustom;

  const _AddLanguageDialog({
    required this.availableLanguages,
    required this.onLanguageSelected,
    required this.onCreateCustom,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
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
                    child: const Icon(Icons.translate,
                        color: _languagesColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      SheetStoryLanguagesTabText.addLanguageDialogTitle,
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
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: TextStyle(color: FormTheme.textBright),
                decoration: InputDecoration(
                  labelText: SheetStoryLanguagesTabText.searchLanguagesLabel,
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
                        const BorderSide(color: _languagesColor, width: 2),
                  ),
                ),
                onChanged: _filterLanguages,
              ),
            ),
            // Create custom language button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: widget.onCreateCustom,
                icon: const Icon(Icons.edit_note, size: 18),
                label:
                    const Text(SheetStoryLanguagesTabText.createCustomLanguage),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _languagesColor,
                  side: BorderSide(color: _languagesColor.withAlpha(128)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Languages list
            Flexible(
              child: _filteredLanguages.isEmpty
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
                              SheetStoryLanguagesTabText.noLanguagesFound,
                              style: TextStyle(color: FormTheme.textSecondary),
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
                              subtitle = SheetStoryLanguagesTabText.region(
                                  lang.region);
                            }
                            if (lang.ancestry.isNotEmpty) {
                              subtitle = subtitle.isEmpty
                                  ? SheetStoryLanguagesTabText.ancestry(
                                      lang.ancestry)
                                  : '$subtitle • ${SheetStoryLanguagesTabText.ancestry(lang.ancestry)}';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: StoryTheme.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: FormTheme.borderDim),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _languagesColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add_circle_outline,
                                      color: _languagesColor, size: 18),
                                ),
                                title: Text(
                                  lang.name,
                                  style: TextStyle(
                                      color: FormTheme.textBright,
                                      fontSize: 14),
                                ),
                                subtitle: subtitle.isNotEmpty
                                    ? Text(
                                        subtitle,
                                        style: TextStyle(
                                            color: FormTheme.textMuted,
                                            fontSize: 11),
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

// --- Custom Language Creation Dialog ---

class _CreateCustomLanguageDialog extends StatefulWidget {
  final Future<void> Function(
          _LanguageOption langOption, Map<String, dynamic> extraData)
      onLanguageCreated;

  const _CreateCustomLanguageDialog({required this.onLanguageCreated});

  @override
  State<_CreateCustomLanguageDialog> createState() =>
      _CreateCustomLanguageDialogState();
}

class _CreateCustomLanguageDialogState
    extends State<_CreateCustomLanguageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _ancestryController = TextEditingController();
  final _commonTopicsController = TextEditingController();
  final _relatedLanguagesController = TextEditingController();
  String? _selectedType;
  final _customTypeController = TextEditingController();
  bool _useCustomType = false;
  bool _isSaving = false;

  static const _knownTypes = ['human', 'ancestral', 'dead'];

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _ancestryController.dispose();
    _commonTopicsController.dispose();
    _relatedLanguagesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  String _generateId(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'custom_language_$slug';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final languageType = _useCustomType
        ? _customTypeController.text.trim().toLowerCase()
        : (_selectedType ?? SheetStoryLanguagesTabText.customType);
    final region = _regionController.text.trim();
    final ancestry = _ancestryController.text.trim();
    final commonTopics = _commonTopicsController.text.trim();
    final relatedLanguages = _relatedLanguagesController.text.trim();

    final langOption = _LanguageOption(
      id: _generateId(name),
      name: name,
      languageType: languageType,
      region: region,
      ancestry: ancestry,
    );

    final extraData = <String, dynamic>{};
    if (commonTopics.isNotEmpty) {
      extraData['common_topics'] = commonTopics
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (relatedLanguages.isNotEmpty) {
      extraData['related_languages'] = relatedLanguages
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    await widget.onLanguageCreated(langOption, extraData);

    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: FormTheme.textBright),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: FormTheme.textSecondary),
        hintStyle: TextStyle(color: FormTheme.borderLight),
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
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                        child: const Icon(Icons.edit_note,
                            color: _languagesColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          SheetStoryLanguagesTabText.createCustomLanguageTitle,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field (required)
                      _buildTextField(
                        controller: _nameController,
                        label: SheetStoryLanguagesTabText.languageNameLabel,
                        hint: SheetStoryLanguagesTabText.languageNameHint,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return SheetStoryLanguagesTabText
                                .languageNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Language type dropdown / custom input
                      if (!_useCustomType)
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          dropdownColor: NavigationTheme.cardBackgroundDark,
                          style: TextStyle(color: FormTheme.textBright),
                          decoration: InputDecoration(
                            labelText:
                                SheetStoryLanguagesTabText.languageTypeLabel,
                            hintText:
                                SheetStoryLanguagesTabText.languageTypeHint,
                            labelStyle:
                                TextStyle(color: FormTheme.textSecondary),
                            hintStyle: TextStyle(color: FormTheme.borderLight),
                            filled: true,
                            fillColor: StoryTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _languagesColor, width: 2),
                            ),
                          ),
                          items: _knownTypes
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                        t[0].toUpperCase() + t.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedType = val),
                        )
                      else
                        _buildTextField(
                          controller: _customTypeController,
                          label: SheetStoryLanguagesTabText.languageTypeLabel,
                          hint: SheetStoryLanguagesTabText.languageTypeHint,
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _useCustomType = !_useCustomType),
                          icon: Icon(
                            _useCustomType ? Icons.list : Icons.edit,
                            size: 16,
                            color: _languagesColor,
                          ),
                          label: Text(
                            _useCustomType
                                ? SheetStoryLanguagesTabText.pickFromList
                                : SheetStoryLanguagesTabText.customType,
                            style: const TextStyle(
                                color: _languagesColor, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Region field (optional)
                      _buildTextField(
                        controller: _regionController,
                        label: SheetStoryLanguagesTabText.regionLabel,
                        hint: SheetStoryLanguagesTabText.regionHint,
                      ),
                      const SizedBox(height: 16),

                      // Ancestry field (optional)
                      _buildTextField(
                        controller: _ancestryController,
                        label: SheetStoryLanguagesTabText.ancestryLabel,
                        hint: SheetStoryLanguagesTabText.ancestryHint,
                      ),
                      const SizedBox(height: 16),

                      // Common topics field (optional)
                      _buildTextField(
                        controller: _commonTopicsController,
                        label: SheetStoryLanguagesTabText.commonTopicsLabel,
                        hint: SheetStoryLanguagesTabText.commonTopicsHint,
                      ),
                      const SizedBox(height: 16),

                      // Related languages field (optional)
                      _buildTextField(
                        controller: _relatedLanguagesController,
                        label: SheetStoryLanguagesTabText.relatedLanguagesLabel,
                        hint: SheetStoryLanguagesTabText.relatedLanguagesHint,
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              SheetStoryLanguagesTabText.cancelButton,
                              style: TextStyle(color: FormTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _languagesColor,
                              foregroundColor: FormTheme.textBright,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FormTheme.textBright,
                                    ),
                                  )
                                : const Text(
                                    SheetStoryLanguagesTabText.createButton),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
