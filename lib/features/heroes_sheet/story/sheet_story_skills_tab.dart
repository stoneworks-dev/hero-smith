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

class _SkillsTabState extends ConsumerState<_SkillsTab> {
  final SkillDataService _skillService = SkillDataService();
  List<_SkillOption> _availableSkills = [];
  List<String> _selectedSkillIds = [];
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

      // Load skills from service
      final skills = await _skillService.loadSkills();

      _availableSkills = skills.map((skill) {
        return _SkillOption(
          id: skill.id,
          name: skill.name,
          group: skill.group,
          description: skill.description,
        );
      }).toList();

      final grantsService = ref.read(complicationGrantsServiceProvider);
      await grantsService.syncSkillGrants(widget.heroId);

      // Load selected skills for this hero
      final db = ref.read(appDatabaseProvider);
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
      final updatedIds = [..._selectedSkillIds, skillId];
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'skill',
        componentIds: updatedIds,
      );

      setState(() {
        _selectedSkillIds = updatedIds;
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
      final updatedIds = _selectedSkillIds.where((id) => id != skillId).toList();
      await db.setHeroComponentIds(
        heroId: widget.heroId,
        category: 'skill',
        componentIds: updatedIds,
      );

      setState(() {
        _selectedSkillIds = updatedIds;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove skill: $e')),
        );
      }
    }
  }

  void _showAddSkillDialog() {
    final unselectedSkills = _availableSkills
        .where((skill) => !_selectedSkillIds.contains(skill.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddSkillDialog(
        availableSkills: unselectedSkills,
        onSkillSelected: (skillId) {
          _addSkill(skillId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final selectedSkills = _availableSkills
        .where((skill) => _selectedSkillIds.contains(skill.id))
        .toList();

    // Group skills by category
    final groupedSkills = <String, List<_SkillOption>>{};
    for (final skill in selectedSkills) {
      groupedSkills.putIfAbsent(skill.group, () => []).add(skill);
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
                            '${selectedSkills.length} skills learned',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedSkills.isEmpty)
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
                ...groupedSkills.entries.map((entry) {
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
                                groupName,
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
                      ...skills.map((skill) => _buildSkillCard(skill)),
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

  Widget _buildSkillCard(_SkillOption skill) {
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
            color: _skillsColor.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check_circle, color: _skillsColor, size: 18),
        ),
        title: Text(
          skill.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: skill.description.isNotEmpty
            ? Text(
                skill.description,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
          onPressed: () => _removeSkill(skill.id),
          tooltip: SheetStorySkillsTabText.removeSkillTooltip,
        ),
      ),
    );
  }
}

class _AddSkillDialog extends StatefulWidget {
  final List<_SkillOption> availableSkills;
  final Function(String) onSkillSelected;

  const _AddSkillDialog({
    required this.availableSkills,
    required this.onSkillSelected,
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
                      children: groupedSkills.entries.expand((entry) {
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
                                    groupName,
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
