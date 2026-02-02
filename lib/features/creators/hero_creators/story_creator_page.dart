import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/db/providers.dart';
import 'package:hero_smith/core/models/hero_model.dart';
import 'package:hero_smith/core/models/story_creator_models.dart';
import 'package:hero_smith/core/services/story_creator_service.dart';
import 'package:hero_smith/core/text/creators/hero_creators/story_creator_page_text.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_ancestry_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_career_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_complication_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_culture_section.dart';
import 'package:hero_smith/features/creators/widgets/story_creator/story_name_section.dart';

class StoryCreatorTab extends ConsumerStatefulWidget {
  const StoryCreatorTab({
    super.key,
    required this.heroId,
    required this.onDirtyChanged,
    required this.onTitleChanged,
  });

  final String heroId;
  final ValueChanged<bool> onDirtyChanged;
  final ValueChanged<String> onTitleChanged;

  @override
  ConsumerState<StoryCreatorTab> createState() => StoryCreatorTabState();
}

class StoryCreatorTabState extends ConsumerState<StoryCreatorTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _nameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  HeroModel? _hero;
  bool _dirty = false;

  String? _selectedAncestryId;
  final LinkedHashSet<String> _selectedTraitIds = LinkedHashSet<String>();
  final Map<String, String> _ancestryTraitChoices = {};

  String? _environmentId;
  String? _organisationId;
  String? _upbringingId;
  String? _environmentSkillId;
  String? _organisationSkillId;
  String? _upbringingSkillId;
  String? _selectedLanguageId;

  int _careerLanguageSlots = 0;
  List<String?> _careerLanguageIds = <String?>[];

  String? _careerId;
  final LinkedHashSet<String> _careerSkillIds = LinkedHashSet<String>();
  final LinkedHashSet<String> _careerPerkIds = LinkedHashSet<String>();
  String? _careerIncidentName;

  String? _complicationId;
  final Map<String, String> _complicationChoices = {};

  bool get isDirty => _dirty;

  Set<String> get _selectedLanguageIdsForPerks {
    final ids = <String>{};
    ids.addAll(_hero?.languages ?? const <String>[]);
    if (_selectedLanguageId != null && _selectedLanguageId!.trim().isNotEmpty) {
      ids.add(_selectedLanguageId!.trim());
    }
    for (final lang in _careerLanguageIds) {
      if (lang != null && lang.trim().isNotEmpty) {
        ids.add(lang.trim());
      }
    }
    return ids;
  }

  Set<String> get _selectedSkillIdsForPerks {
    final ids = <String>{};
    ids.addAll(_hero?.skills ?? const <String>[]);
    if (_environmentSkillId != null && _environmentSkillId!.isNotEmpty) {
      ids.add(_environmentSkillId!);
    }
    if (_organisationSkillId != null && _organisationSkillId!.isNotEmpty) {
      ids.add(_organisationSkillId!);
    }
    if (_upbringingSkillId != null && _upbringingSkillId!.isNotEmpty) {
      ids.add(_upbringingSkillId!);
    }
    ids.addAll(_careerSkillIds);
    return ids;
  }

  // Cache for DB-saved IDs during save operation to prevent flicker
  Set<String> _cachedDbLanguageIds = const {};
  Set<String> _cachedDbSkillIds = const {};
  Set<String> _cachedDbPerkIds = const {};

  /// Gets all language IDs saved in the database for this hero.
  Set<String> get _dbSavedLanguageIds {
    if (_saving) return _cachedDbLanguageIds;
    final result = ref.watch(
      heroEntryIdsByTypeProvider((heroId: widget.heroId, entryType: 'language')),
    );
    _cachedDbLanguageIds = result;
    return result;
  }

  /// Gets all skill IDs saved in the database for this hero.
  Set<String> get _dbSavedSkillIds {
    if (_saving) return _cachedDbSkillIds;
    final result = ref.watch(
      heroEntryIdsByTypeProvider((heroId: widget.heroId, entryType: 'skill')),
    );
    _cachedDbSkillIds = result;
    return result;
  }

  /// Gets all perk IDs saved in the database for this hero.
  Set<String> get _dbSavedPerkIds {
    if (_saving) return _cachedDbPerkIds;
    final result = ref.watch(
      heroEntryIdsByTypeProvider((heroId: widget.heroId, entryType: 'perk')),
    );
    _cachedDbPerkIds = result;
    return result;
  }

  Set<String> get _reservedLanguageIds => {
        ..._selectedLanguageIdsForPerks,
        ..._dbSavedLanguageIds,
      };

  Set<String> get _reservedSkillIds => {
        ..._selectedSkillIdsForPerks,
        ..._dbSavedSkillIds,
      };

  Set<String> get _reservedPerkIds => {
        ...(_hero?.perks ?? const <String>[]),
        ..._careerPerkIds,
        ..._dbSavedPerkIds,
      };

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_handleNameChanged);
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_handleNameChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    // Set saving flag to prevent rebuild flicker during save
    _saving = true;

    final service = ref.read(storyCreatorServiceProvider);
    final languageIds = <String>{
      if (_selectedLanguageId != null && _selectedLanguageId!.trim().isNotEmpty)
        _selectedLanguageId!,
      ..._careerLanguageIds
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty),
    };

    final payload = StoryCreatorSavePayload(
      heroId: widget.heroId,
      name: _nameCtrl.text.trim().isEmpty ? 'New Hero' : _nameCtrl.text.trim(),
      ancestryId: _selectedAncestryId,
      ancestryTraitIds: LinkedHashSet<String>.of(_selectedTraitIds),
      ancestryTraitChoices: Map<String, String>.from(_ancestryTraitChoices),
      environmentId: _environmentId,
      organisationId: _organisationId,
      upbringingId: _upbringingId,
      environmentSkillId: _environmentSkillId,
      organisationSkillId: _organisationSkillId,
      upbringingSkillId: _upbringingSkillId,
      languageIds: languageIds,
      careerId: _careerId,
      careerSkillIds: LinkedHashSet<String>.of(_careerSkillIds),
      careerPerkIds: LinkedHashSet<String>.of(_careerPerkIds),
      careerIncidentName: _careerIncidentName,
      complicationId: _complicationId,
      complicationChoices: Map<String, String>.from(_complicationChoices),
    );

    try {
      await service.saveStory(payload);
    } finally {
      _saving = false;
    }
    if (!mounted) return;

    final wasDirty = _dirty;
    setState(() {
      _dirty = false;
      _hero?.name = payload.name;
      _hero?.ancestry = payload.ancestryId;
      _hero?.career = payload.careerId;
    });
    if (wasDirty) {
      widget.onDirtyChanged(false);
    }
    widget.onTitleChanged(
      payload.name.isNotEmpty
          ? payload.name
          : StoryCreatorPageText.heroTitleFallbackOnSave,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(storyCreatorServiceProvider);
      final result = await service.loadInitialData(widget.heroId);
      final hero = result.hero;
      final languages = hero?.languages ?? const <String>[];
      final primaryLanguage = languages.isNotEmpty ? languages.first : null;
      final additionalLanguages = languages.length > 1
          ? List<String?>.from(languages.skip(1))
          : <String?>[];

      setState(() {
        _hero = hero;
        _nameCtrl.text = hero?.name ?? '';
        _selectedAncestryId = hero?.ancestry;
        _selectedTraitIds
          ..clear()
          ..addAll(result.ancestryTraitIds);
        _ancestryTraitChoices
          ..clear()
          ..addAll(result.ancestryTraitChoices);
        _environmentId = result.cultureSelection.environmentId;
        _organisationId = result.cultureSelection.organisationId;
        _upbringingId = result.cultureSelection.upbringingId;
        _environmentSkillId = result.cultureSelection.environmentSkillId;
        _organisationSkillId = result.cultureSelection.organisationSkillId;
        _upbringingSkillId = result.cultureSelection.upbringingSkillId;
        _selectedLanguageId = primaryLanguage;
        _careerLanguageIds = additionalLanguages;
        _careerLanguageSlots = additionalLanguages.length;
        _careerId = result.careerSelection.careerId ?? hero?.career;
        _careerSkillIds
          ..clear()
          ..addAll(result.careerSelection.chosenSkillIds);
        _careerPerkIds
          ..clear()
          ..addAll(result.careerSelection.chosenPerkIds);
        _careerIncidentName = result.careerSelection.incitingIncidentName;
        _complicationId = result.complicationId;
        _complicationChoices
          ..clear()
          ..addAll(result.complicationChoices);
        _dirty = false;
        _loading = false;
      });
      widget.onDirtyChanged(false);
      _handleNameChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _handleNameChanged() {
    final fallback =
        _hero?.name ?? StoryCreatorPageText.heroTitleFallbackOnNameChanged;
    final trimmed = _nameCtrl.text.trim();
    widget.onTitleChanged(trimmed.isNotEmpty ? trimmed : fallback);
  }

  void _handleDirty() {
    if (_dirty) return;
    setState(() {
      _dirty = true;
    });
    widget.onDirtyChanged(true);
  }

  void _onAncestryChanged(String? value) {
    setState(() {
      _selectedAncestryId = value;
      _selectedTraitIds.clear();
      _ancestryTraitChoices.clear();
    });
  }

  void _onTraitSelectionChanged(String traitId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTraitIds.add(traitId);
      } else {
        _selectedTraitIds.remove(traitId);
        // Remove any choice associated with this trait
        _ancestryTraitChoices.remove(traitId);
      }
    });
  }

  void _onTraitChoiceChanged(String traitOrSignatureId, String choiceValue) {
    setState(() {
      _ancestryTraitChoices[traitOrSignatureId] = choiceValue;
    });
  }

  void _onLanguageChanged(String? value) {
    setState(() {
      _selectedLanguageId = value;
      for (var i = 0; i < _careerLanguageIds.length; i++) {
        if (_careerLanguageIds[i] == value) {
          _careerLanguageIds[i] = null;
        }
      }
    });
  }

  void _onEnvironmentChanged(String? value) {
    setState(() {
      _environmentId = value;
    });
  }

  void _onOrganisationChanged(String? value) {
    setState(() {
      _organisationId = value;
    });
  }

  void _onUpbringingChanged(String? value) {
    setState(() {
      _upbringingId = value;
    });
  }

  void _onEnvironmentSkillChanged(String? value) {
    setState(() {
      _environmentSkillId = value;
    });
  }

  void _onOrganisationSkillChanged(String? value) {
    setState(() {
      _organisationSkillId = value;
    });
  }

  void _onUpbringingSkillChanged(String? value) {
    setState(() {
      _upbringingSkillId = value;
    });
  }

  void _onCareerChanged(String? value) {
    setState(() {
      _careerId = value;
      _careerSkillIds.clear();
      _careerPerkIds.clear();
      _careerIncidentName = null;
      _careerLanguageIds = <String?>[];
      _careerLanguageSlots = 0;
    });
  }

  void _onCareerLanguageSlotsChanged(int slots) {
    final normalized = slots.clamp(0, 10);
    if (normalized == _careerLanguageSlots) return;
    setState(() {
      _careerLanguageSlots = normalized;
      if (_careerLanguageIds.length > normalized) {
        _careerLanguageIds = _careerLanguageIds.take(normalized).toList();
      } else {
        _careerLanguageIds = List<String?>.of(_careerLanguageIds)
          ..addAll(List<String?>.filled(
            normalized - _careerLanguageIds.length,
            null,
            growable: false,
          ));
      }
    });
  }

  void _onCareerLanguageChanged(int index, String? value) {
    if (index < 0) return;
    if (index >= _careerLanguageIds.length) {
      setState(() {
        while (_careerLanguageIds.length <= index) {
          _careerLanguageIds.add(null);
        }
        _careerLanguageIds[index] = value;
      });
      return;
    }
    if (_careerLanguageIds[index] == value) return;
    setState(() {
      _careerLanguageIds[index] = value;
    });
  }

  void _onCareerSkillsChanged(Set<String> ids) {
    setState(() {
      _careerSkillIds
        ..clear()
        ..addAll(ids);
    });
  }

  void _onCareerPerksChanged(Set<String> ids) {
    setState(() {
      _careerPerkIds
        ..clear()
        ..addAll(ids);
    });
  }

  void _onIncidentChanged(String? value) {
    setState(() {
      _careerIncidentName = value;
    });
  }

  void _onComplicationChanged(String? value) {
    setState(() {
      _complicationId = value;
      // Clear choices when complication changes
      _complicationChoices.clear();
    });
  }

  void _onComplicationChoicesChanged(Map<String, String> choices) {
    setState(() {
      _complicationChoices
        ..clear()
        ..addAll(choices);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    if (_hero == null) {
      return _ErrorView(
        message: StoryCreatorPageText.heroNotFoundMessage,
        onRetry: _load,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: StoryNameSection(
            nameController: _nameCtrl,
            selectedAncestryId: _selectedAncestryId,
            onDirty: _handleDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryAncestrySection(
            selectedAncestryId: _selectedAncestryId,
            selectedTraitIds: _selectedTraitIds,
            traitChoices: _ancestryTraitChoices,
            onAncestryChanged: _onAncestryChanged,
            onTraitSelectionChanged: _onTraitSelectionChanged,
            onTraitChoiceChanged: _onTraitChoiceChanged,
            onDirty: _handleDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryCultureSection(
            selectedAncestryId: _selectedAncestryId,
            environmentId: _environmentId,
            organisationId: _organisationId,
            upbringingId: _upbringingId,
            selectedLanguageId: _selectedLanguageId,
            reservedLanguageIds: _reservedLanguageIds,
            environmentSkillId: _environmentSkillId,
            organisationSkillId: _organisationSkillId,
            upbringingSkillId: _upbringingSkillId,
            reservedSkillIds: _reservedSkillIds,
            onLanguageChanged: _onLanguageChanged,
            onEnvironmentChanged: _onEnvironmentChanged,
            onOrganisationChanged: _onOrganisationChanged,
            onUpbringingChanged: _onUpbringingChanged,
            onEnvironmentSkillChanged: _onEnvironmentSkillChanged,
            onOrganisationSkillChanged: _onOrganisationSkillChanged,
            onUpbringingSkillChanged: _onUpbringingSkillChanged,
            onDirty: _handleDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryCareerSection(
            heroId: widget.heroId,
            careerId: _careerId,
            chosenSkillIds: _careerSkillIds,
            chosenPerkIds: _careerPerkIds,
            incidentName: _careerIncidentName,
            careerLanguageIds: _careerLanguageIds,
            primaryLanguageId: _selectedLanguageId,
            selectedLanguageIds: _selectedLanguageIdsForPerks,
            selectedSkillIds: _selectedSkillIdsForPerks,
            reservedLanguageIds: _reservedLanguageIds,
            reservedSkillIds: _reservedSkillIds,
            reservedPerkIds: _reservedPerkIds,
            onCareerChanged: _onCareerChanged,
            onCareerLanguageSlotsChanged: _onCareerLanguageSlotsChanged,
            onCareerLanguageChanged: _onCareerLanguageChanged,
            onSkillSelectionChanged: _onCareerSkillsChanged,
            onPerkSelectionChanged: _onCareerPerksChanged,
            onIncidentChanged: _onIncidentChanged,
            onDirty: _handleDirty,
          ),
        ),
        SliverToBoxAdapter(
          child: StoryComplicationSection(
            selectedComplicationId: _complicationId,
            complicationChoices: _complicationChoices,
            onComplicationChanged: _onComplicationChanged,
            onChoicesChanged: _onComplicationChoicesChanged,
            onDirty: _handleDirty,
            heroAncestryTraitIds: _selectedTraitIds,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(StoryCreatorPageText.errorViewRetry),
            ),
          ],
        ),
      ),
    );
  }
}
