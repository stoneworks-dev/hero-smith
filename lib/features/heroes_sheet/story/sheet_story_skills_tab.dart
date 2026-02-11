part of 'sheet_story.dart';

// Skills accent color
const _skillsColor = StoryTheme.skillsAccent;

// Skills Tab Widget
class _SkillsTab extends ConsumerStatefulWidget {
  final String heroId;

  const _SkillsTab({required this.heroId});

  @override
  ConsumerState<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends ConsumerState<_SkillsTab>
    with AutomaticKeepAliveClientMixin {
  List<_SkillOption> _availableSkills = [];
  Map<String, model.Component> _componentMap = {};
  List<String> _selectedSkillIds = [];
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

      // Load ALL skills from the components table (seed + user)
      final allSkillRows = await db.getComponentsByType('skill');

      _availableSkills = [];
      _componentMap = {};

      for (final comp in allSkillRows) {
        final data = comp.dataJson.isNotEmpty
            ? jsonDecode(comp.dataJson) as Map<String, dynamic>
            : <String, dynamic>{};

        _availableSkills.add(_SkillOption(
          id: comp.id,
          name: comp.name,
          group: (data['group'] as String?)?.toLowerCase() ?? 'other',
          description: data['description'] as String? ?? '',
        ));

        _componentMap[comp.id] = model.Component(
          id: comp.id,
          type: comp.type,
          name: comp.name,
          data: data,
          source: comp.source,
        );
      }

      final grantsService = ref.read(complicationGrantsServiceProvider);
      await grantsService.syncSkillGrants(widget.heroId);

      // Load selected skills for this hero
      _selectedSkillIds = await db.getHeroComponentIds(widget.heroId, 'skill');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load skills: $e';
      });
    }
  }

  Future<void> _reloadAvailableSkills() async {
    final db = ref.read(appDatabaseProvider);
    final allSkillRows = await db.getComponentsByType('skill');

    final updatedOptions = <_SkillOption>[];
    final updatedMap = <String, model.Component>{};

    for (final comp in allSkillRows) {
      final data = comp.dataJson.isNotEmpty
          ? jsonDecode(comp.dataJson) as Map<String, dynamic>
          : <String, dynamic>{};

      updatedOptions.add(_SkillOption(
        id: comp.id,
        name: comp.name,
        group: (data['group'] as String?)?.toLowerCase().trim().isNotEmpty == true
            ? (data['group'] as String).toLowerCase().trim()
            : 'other',
        description: data['description'] as String? ?? '',
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
      _availableSkills = updatedOptions;
      _componentMap = updatedMap;
    });
  }

  Future<void> _addSkill(String skillId) async {
    if (_selectedSkillIds.contains(skillId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SheetStorySkillsTabText.skillAlreadyAdded)),
        );
      }
      return;
    }
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertHeroEntry(
        heroId: widget.heroId,
        entryType: 'skill',
        entryId: skillId,
        sourceType: 'hero_sheet',
        sourceId: 'skill',
        gainedBy: 'choice',
      );

      setState(() {
        _selectedSkillIds = [..._selectedSkillIds, skillId];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add skill: $e')),
        );
      }
    }
  }

  Future<void> _removeSkill(String skillId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.removeSingleHeroEntry(
        heroId: widget.heroId,
        entryType: 'skill',
        entryId: skillId,
      );

      setState(() {
        _selectedSkillIds = _selectedSkillIds.where((id) => id != skillId).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove skill: $e')),
        );
      }
    }
  }

  Future<void> _showAddSkillDialog() async {
    await _reloadAvailableSkills();
    if (!mounted) return;
    final unselectedSkills = _availableSkills
        .where((skill) => !_selectedSkillIds.contains(skill.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddSkillDialog(
        availableSkills: unselectedSkills,
        onSkillSelected: (skillId) async {
          Navigator.of(context).pop();
          await _addSkill(skillId);
        },
        onCreateCustom: () {
          Navigator.of(context).pop();
          _showCreateCustomSkillDialog();
        },
      ),
    );
  }

  void _showCreateCustomSkillDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateCustomSkillDialog(
        onSkillCreated: (skillOption) async {
          // Save to Components table with source='user'
          final db = ref.read(appDatabaseProvider);
          await db.upsertComponentModel(
            id: skillOption.id,
            type: 'skill',
            name: skillOption.name,
            dataMap: {
              'group': skillOption.group,
              'description': skillOption.description,
            },
            source: 'user',
          );

          // Add to available skills + component map, then select for this hero
          setState(() {
            _availableSkills.add(skillOption);
            _componentMap[skillOption.id] = model.Component(
              id: skillOption.id,
              type: 'skill',
              name: skillOption.name,
              data: {
                'group': skillOption.group,
                'description': skillOption.description,
              },
              source: 'user',
            );
          });
          await _addSkill(skillOption.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _skillsColor),
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
                backgroundColor: _skillsColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(SheetStoryCommonText.retry),
            ),
          ],
        ),
      );
    }

    final selectedComponents = _selectedSkillIds
        .where((id) => _componentMap.containsKey(id))
        .map((id) => _componentMap[id]!)
        .toList();

    String displayGroupName(String raw) {
      final g = raw.trim();
      if (g.isEmpty || g.toLowerCase() == 'other') return 'Other';
      // Title-case words for custom group labels
      return g
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }

    // Group skills by category
    final groupedSkills = <String, List<model.Component>>{};
    for (final comp in selectedComponents) {
      final group = ((comp.data['group'] as String?) ?? 'other').toLowerCase().trim();
      groupedSkills.putIfAbsent(group, () => []).add(comp);
    }

    // Desired group order + remaining custom groups alphabetically
    const order = ['crafting', 'exploration', 'interpersonal', 'intrigue', 'lore', 'other'];
    final sortedEntries = <MapEntry<String, List<model.Component>>>[];
    for (final g in order) {
      if (groupedSkills.containsKey(g)) {
        sortedEntries.add(MapEntry(g, groupedSkills[g]!));
      }
    }
    final remaining = groupedSkills.keys.where((k) => !order.contains(k)).toList()..sort();
    for (final g in remaining) {
      sortedEntries.add(MapEntry(g, groupedSkills[g]!));
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
                      _skillsColor.withAlpha(38),
                      _skillsColor.withAlpha(10),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _skillsColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: _skillsColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            SheetStorySkillsTabText.skillsTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedComponents.length} skills learned',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                        Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          SheetStorySkillsTabText.emptyState,
                          style: TextStyle(color: Colors.grey.shade400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...sortedEntries.map((entry) {
                  final groupName = entry.key;
                  final skills = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (groupName.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _skillsColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                displayGroupName(groupName),
                                style: const TextStyle(
                                  color: _skillsColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ...skills.map((comp) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SkillCard(
                          skill: comp,
                          onRemove: () => _removeSkill(comp.id),
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
            heroTag: 'skills_tab_fab',
            onPressed: _showAddSkillDialog,
            backgroundColor: NavigationTheme.cardBackgroundDark,
            foregroundColor: _skillsColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _skillsColor, width: 2),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

}

class _AddSkillDialog extends StatefulWidget {
  final List<_SkillOption> availableSkills;
  final Function(String) onSkillSelected;
  final VoidCallback onCreateCustom;

  const _AddSkillDialog({
    required this.availableSkills,
    required this.onSkillSelected,
    required this.onCreateCustom,
  });

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  // ignore: unused_field
  String _searchQuery = '';
  List<_SkillOption> _filteredSkills = [];

  @override
  void initState() {
    super.initState();
    _filteredSkills = widget.availableSkills;
  }

  void _filterSkills(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSkills = widget.availableSkills;
      } else {
        _filteredSkills = widget.availableSkills
            .where((skill) =>
                skill.name.toLowerCase().contains(query.toLowerCase()) ||
                skill.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group filtered skills
    final groupedSkills = <String, List<_SkillOption>>{};
    for (final skill in _filteredSkills) {
      groupedSkills.putIfAbsent(skill.group, () => []).add(skill);
    }

    // Desired order + remaining custom groups
    const order = ['crafting', 'exploration', 'interpersonal', 'intrigue', 'lore', 'other'];
    final sortedGroups = <MapEntry<String, List<_SkillOption>>>[];
    for (final g in order) {
      if (groupedSkills.containsKey(g)) {
        sortedGroups.add(MapEntry(g, groupedSkills[g]!));
      }
    }
    final remaining = groupedSkills.keys.where((k) => !order.contains(k)).toList()..sort();
    for (final g in remaining) {
      sortedGroups.add(MapEntry(g, groupedSkills[g]!));
    }

    String displayGroupName(String raw) {
      final g = raw.trim();
      if (g.isEmpty || g.toLowerCase() == 'other') return 'Other';
      return g
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
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
                    _skillsColor.withAlpha(51),
                    _skillsColor.withAlpha(13),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _skillsColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: _skillsColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      SheetStorySkillsTabText.addSkillDialogTitle,
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
                  labelText: SheetStorySkillsTabText.searchSkillsLabel,
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
                    borderSide: const BorderSide(color: _skillsColor, width: 2),
                  ),
                ),
                onChanged: _filterSkills,
              ),
            ),
            // Create custom skill button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: widget.onCreateCustom,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text(SheetStorySkillsTabText.createCustomSkill),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _skillsColor,
                  side: BorderSide(color: _skillsColor.withAlpha(128)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Skills list
            Flexible(
              child: _filteredSkills.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            Text(
                              SheetStorySkillsTabText.noSkillsFound,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: sortedGroups.expand((entry) {
                        final groupName = entry.key;
                        final skills = entry.value;
                        return [
                          if (groupName.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _skillsColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    displayGroupName(groupName),
                                    style: const TextStyle(
                                      color: _skillsColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ...skills.map((skill) => Container(
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
                                      color: _skillsColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add_circle_outline, color: _skillsColor, size: 18),
                                  ),
                                  title: Text(
                                    skill.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  subtitle: skill.description.isNotEmpty
                                      ? Text(
                                          skill.description,
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  onTap: () => widget.onSkillSelected(skill.id),
                                ),
                              )),
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

class _SkillOption {
  final String id;
  final String name;
  final String group;
  final String description;

  _SkillOption({
    required this.id,
    required this.name,
    required this.group,
    required this.description,
  });
}

// --- Custom Skill Creation Dialog ---

class _CreateCustomSkillDialog extends StatefulWidget {
  final Future<void> Function(_SkillOption skillOption) onSkillCreated;

  const _CreateCustomSkillDialog({required this.onSkillCreated});

  @override
  State<_CreateCustomSkillDialog> createState() =>
      _CreateCustomSkillDialogState();
}

class _CreateCustomSkillDialogState extends State<_CreateCustomSkillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGroup;
  final _customGroupController = TextEditingController();
  bool _useCustomGroup = false;
  bool _isSaving = false;

  static const _knownGroups = [
    'crafting',
    'exploration',
    'interpersonal',
    'intrigue',
    'lore',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customGroupController.dispose();
    super.dispose();
  }

  String _generateId(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'custom_skill_$slug';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final group = _useCustomGroup
        ? _customGroupController.text.trim().toLowerCase()
        : (_selectedGroup ?? SheetStorySkillsTabText.customGroup);
    final description = _descriptionController.text.trim();

    final skillOption = _SkillOption(
      id: _generateId(name),
      name: name,
      group: group,
      description: description,
    );

    await widget.onSkillCreated(skillOption);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 520),
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
                        _skillsColor.withAlpha(51),
                        _skillsColor.withAlpha(13),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _skillsColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note,
                            color: _skillsColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          SheetStorySkillsTabText.createCustomSkillTitle,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field (required)
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: SheetStorySkillsTabText.skillNameLabel,
                          hintText: SheetStorySkillsTabText.skillNameHint,
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: StoryTheme.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: _skillsColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return SheetStorySkillsTabText.skillNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Group dropdown + custom toggle
                      if (!_useCustomGroup)
                        DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          dropdownColor: NavigationTheme.cardBackgroundDark,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: SheetStorySkillsTabText.skillGroupLabel,
                            hintText: SheetStorySkillsTabText.skillGroupHint,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: StoryTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _skillsColor, width: 2),
                            ),
                          ),
                          items: _knownGroups
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g[0].toUpperCase() +
                                        g.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGroup = val),
                        )
                      else
                        TextFormField(
                          controller: _customGroupController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: SheetStorySkillsTabText.skillGroupLabel,
                            hintText: SheetStorySkillsTabText.skillGroupHint,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: StoryTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _skillsColor, width: 2),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _useCustomGroup = !_useCustomGroup),
                          icon: Icon(
                            _useCustomGroup ? Icons.list : Icons.edit,
                            size: 16,
                            color: _skillsColor,
                          ),
                          label: Text(
                            _useCustomGroup
                                ? 'Pick from list'
                                : 'Custom group',
                            style: const TextStyle(
                                color: _skillsColor, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description field (optional)
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText:
                              SheetStorySkillsTabText.skillDescriptionLabel,
                          hintText:
                              SheetStorySkillsTabText.skillDescriptionHint,
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: StoryTheme.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: _skillsColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              SheetStorySkillsTabText.cancelButton,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _skillsColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    SheetStorySkillsTabText.createButton),
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
