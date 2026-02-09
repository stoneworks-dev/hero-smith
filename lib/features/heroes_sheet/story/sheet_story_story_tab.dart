part of 'sheet_story.dart';

extension _StoryTabBuilders on _SheetStoryState {
  
  Widget _buildStoryTab(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: StoryTheme.storyAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade300),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadStoryData,
                icon: const Icon(Icons.refresh),
                label: const Text(SheetStoryCommonText.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoryTheme.storyAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_storyData == null) {
      return Center(
        child: Text(
          SheetStoryStoryTabText.noStoryDataAvailable,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    // Extract data from _storyData for the section widgets
    final hero = _storyData.hero;
    final ancestryId = hero?.ancestry as String?;
    final traitIds = (_storyData.ancestryTraitIds as List<dynamic>? ?? [])
        .map((id) => id.toString())
        .toList();
    
    final culture = _storyData.cultureSelection;
    final cultureData = CultureSelectionData(
      environmentId: culture.environmentId,
      organisationId: culture.organisationId,
      upbringingId: culture.upbringingId,
      environmentSkillId: culture.environmentSkillId,
      organisationSkillId: culture.organisationSkillId,
      upbringingSkillId: culture.upbringingSkillId,
    );

    final career = _storyData.careerSelection;
    final careerData = CareerSelectionData(
      careerId: career.careerId,
      incitingIncidentName: career.incitingIncidentName,
      chosenSkillIds: List<String>.from(career.chosenSkillIds),
      chosenPerkIds: List<String>.from(career.chosenPerkIds),
    );

    final complicationId = _storyData.complicationId as String?;
    final complicationChoices = 
        (_storyData.complicationChoices as Map<String, String>?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroNameSection(context),
        const SizedBox(height: 16),
        AncestrySection(
          ancestryId: ancestryId,
          traitIds: traitIds,
        ),
        const SizedBox(height: 16),
        CultureSection(culture: cultureData),
        const SizedBox(height: 16),
        CareerSection(
          career: careerData,
          heroId: widget.heroId,
        ),
        const SizedBox(height: 16),
        ComplicationSection(
          complicationId: complicationId,
          complicationChoices: complicationChoices,
          heroId: widget.heroId,
        ),
      ],
    );
  }

  Widget _buildHeroNameSection(BuildContext context) {
    final hero = _storyData.hero;

    if (hero == null) {
      return const SizedBox.shrink();
    }

    final classAsync = (hero.className != null && (hero.className as String).isNotEmpty)
        ? ref.watch(componentByIdProvider(hero.className as String))
        : null;
    final subclassAsync = (hero.subclass != null && (hero.subclass as String).isNotEmpty)
        ? ref.watch(componentByIdProvider(hero.subclass as String))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  StoryTheme.storyAccent.withAlpha(51),
                  StoryTheme.storyAccent.withAlpha(13),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StoryTheme.storyAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: StoryTheme.storyAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hero.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${hero.level}',
                        style: TextStyle(
                          color: StoryTheme.storyAccent.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Class and Subclass info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (classAsync != null)
                  classAsync.when(
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent),
                    ),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    data: (classComp) => _buildInfoRow(
                      Icons.shield,
                      SheetStoryStoryTabText.classLabel,
                      classComp?.name ?? SheetStoryStoryTabText.unknown,
                    ),
                  ),
                if (subclassAsync != null) ...[
                  const SizedBox(height: 8),
                  subclassAsync.when(
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent),
                    ),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    data: (subclassComp) => _buildInfoRow(
                      Icons.bolt,
                      SheetStoryStoryTabText.subclassLabel,
                      subclassComp?.name ?? SheetStoryStoryTabText.unknown,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: StoryTheme.storyAccent),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
