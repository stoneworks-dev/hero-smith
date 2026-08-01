import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/providers.dart';
import '../../../../core/models/component.dart' as model;
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icon_data.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/story_creator/story_culture_section_text.dart';
import '../../../hero_builder/domain/hero_claim.dart';
import '../../../hero_builder/domain/hero_conflict_index.dart';
import '../../../hero_builder/domain/hero_draft_claims.dart';

class _SearchOption<T> {
  const _SearchOption({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final T? value;
  final String? subtitle;
}

class _PickerSelection<T> {
  const _PickerSelection({required this.value});

  final T? value;
}

Future<_PickerSelection<T>?> _showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<_SearchOption<T>> options,
  T? selected,
  Color? accent,
  AppIconData? icon,
}) {
  final accentColor = accent ?? CreatorTheme.cultureAccent;
  final effectiveIcon = icon ?? const MaterialIcon(Icons.search);

  return showDialog<_PickerSelection<T>>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = query.trim().toLowerCase();
          final List<_SearchOption<T>> filtered = normalizedQuery.isEmpty
              ? options
              : options
                  .where(
                    (option) =>
                        option.label.toLowerCase().contains(normalizedQuery) ||
                        (option.subtitle?.toLowerCase().contains(
                                  normalizedQuery,
                                ) ??
                            false),
                  )
                  .toList();

          return Dialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: accentColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: AppIcon(effectiveIcon,
                              color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              Icon(Icons.close, color: FormTheme.textSecondary),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: controller,
                      autofocus: false,
                      style: TextStyle(color: FormTheme.textBright),
                      decoration: InputDecoration(
                        hintText: StoryCultureSectionText.searchHint,
                        hintStyle: TextStyle(color: FormTheme.textMuted),
                        prefixIcon:
                            Icon(Icons.search, color: FormTheme.textMuted),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: FormTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: FormTheme.borderLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  StoryCultureSectionText.noMatchesFound,
                                  style: TextStyle(
                                    color: FormTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final isNoneOption = option.value == null;
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isNoneOption
                                      ? FormTheme.surfaceMuted
                                      : isSelected
                                          ? accentColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: accentColor.withValues(
                                              alpha: 0.4),
                                        )
                                      : isNoneOption
                                          ? Border.all(
                                              color: FormTheme.border,
                                            )
                                          : null,
                                ),
                                child: ListTile(
                                  leading: isNoneOption
                                      ? Icon(Icons.remove_circle_outline,
                                          size: 20, color: FormTheme.textMuted)
                                      : null,
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isNoneOption
                                          ? FormTheme.textSecondary
                                          : isSelected
                                              ? accentColor
                                              : Colors.grey.shade200,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontStyle: isNoneOption
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                  subtitle: option.subtitle != null
                                      ? Text(
                                          option.subtitle!,
                                          style: TextStyle(
                                            color: FormTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: accentColor, size: 22)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    _PickerSelection<T>(value: option.value),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Cancel button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: FormTheme.borderDim),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: FormTheme.textSecondary,
                      ),
                      child: const Text(StoryCultureSectionText.cancelLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class StoryCultureSection extends ConsumerWidget {
  const StoryCultureSection({
    super.key,
    required this.selectedAncestryId,
    required this.environmentId,
    required this.organisationId,
    required this.upbringingId,
    required this.selectedLanguageId,
    required this.languageConflictIndex,
    required this.environmentSkillId,
    required this.organisationSkillId,
    required this.upbringingSkillId,
    required this.skillConflictIndex,
    required this.onLanguageChanged,
    required this.onEnvironmentChanged,
    required this.onOrganisationChanged,
    required this.onUpbringingChanged,
    required this.onEnvironmentSkillChanged,
    required this.onOrganisationSkillChanged,
    required this.onUpbringingSkillChanged,
    required this.onDirty,
  });

  final String? selectedAncestryId;
  final String? environmentId;
  final String? organisationId;
  final String? upbringingId;
  final String? selectedLanguageId;
  final HeroConflictIndex languageConflictIndex;
  final String? environmentSkillId;
  final String? organisationSkillId;
  final String? upbringingSkillId;
  final HeroConflictIndex skillConflictIndex;

  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onEnvironmentChanged;
  final ValueChanged<String?> onOrganisationChanged;
  final ValueChanged<String?> onUpbringingChanged;
  final ValueChanged<String?> onEnvironmentSkillChanged;
  final ValueChanged<String?> onOrganisationSkillChanged;
  final ValueChanged<String?> onUpbringingSkillChanged;
  final VoidCallback onDirty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envAsync =
        ref.watch(selectableComponentsByTypeProvider('culture_environment'));
    final orgAsync =
        ref.watch(selectableComponentsByTypeProvider('culture_organisation'));
    final upAsync =
        ref.watch(selectableComponentsByTypeProvider('culture_upbringing'));
    final langsAsync =
        ref.watch(selectableComponentsByTypeProvider('language'));
    final skillsAsync = ref.watch(selectableComponentsByTypeProvider('skill'));

    const accent = CreatorTheme.cultureAccent;

    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(accent),
      child: Column(
        children: [
          CreatorTheme.sectionHeader(
            title: StoryCultureSectionText.sectionTitle,
            subtitle: StoryCultureSectionText.sectionSubtitle,
            appIcon: StoryIcons.culture,
            accent: accent,
          ),
          Padding(
            padding: CreatorTheme.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                langsAsync.when(
                  loading: () => CreatorTheme.loadingIndicator(accent),
                  error: (e, _) => CreatorTheme.errorMessage(
                    '${StoryCultureSectionText.failedToLoadLanguagesPrefix}$e',
                    accent: accent,
                  ),
                  data: (langs) => _LanguageDropdown(
                    languages: langs,
                    selectedLanguageId: selectedLanguageId,
                    conflictIndex: languageConflictIndex,
                    onChanged: (val) {
                      onLanguageChanged(val);
                      onDirty();
                    },
                  ),
                ),
                // Environment subsection
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CultureDropdown(
                        label: StoryCultureSectionText.environmentLabel,
                        icon: SkillGroupIcons.exploration,
                        asyncList: envAsync,
                        selectedId: environmentId,
                        accent: const Color(0xFF66BB6A),
                        onChanged: (value) {
                          onEnvironmentChanged(value);
                          onEnvironmentSkillChanged(null);
                          onDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      skillsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (skills) => envAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (envs) => _CultureSkillChooser(
                            label:
                                StoryCultureSectionText.environmentSkillLabel,
                            selectedCultureId: environmentId,
                            cultureItems: envs,
                            selectedSkillId: environmentSkillId,
                            conflictIndex: skillConflictIndex,
                            slotKey:
                                HeroDraftClaims.cultureEnvironmentSkillSlot,
                            allSkills: skills,
                            accent: const Color(0xFF66BB6A),
                            onChanged: (value) {
                              onEnvironmentSkillChanged(value);
                              onDirty();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Organisation subsection
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CultureDropdown(
                        label: StoryCultureSectionText.organizationLabel,
                        icon: StoryIcons.culture,
                        asyncList: orgAsync,
                        selectedId: organisationId,
                        accent: const Color(0xFFFFB74D),
                        onChanged: (value) {
                          onOrganisationChanged(value);
                          onOrganisationSkillChanged(null);
                          onDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      skillsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (skills) => orgAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (orgs) => _CultureSkillChooser(
                            label:
                                StoryCultureSectionText.organizationSkillLabel,
                            selectedCultureId: organisationId,
                            cultureItems: orgs,
                            selectedSkillId: organisationSkillId,
                            conflictIndex: skillConflictIndex,
                            slotKey:
                                HeroDraftClaims.cultureOrganisationSkillSlot,
                            allSkills: skills,
                            accent: const Color(0xFFFFB74D),
                            onChanged: (value) {
                              onOrganisationSkillChanged(value);
                              onDirty();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Upbringing subsection
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFAB47BC).withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CultureDropdown(
                        label: StoryCultureSectionText.upbringingLabel,
                        icon: StoryIcons.ancestry,
                        asyncList: upAsync,
                        selectedId: upbringingId,
                        accent: const Color(0xFFAB47BC),
                        onChanged: (value) {
                          onUpbringingChanged(value);
                          onUpbringingSkillChanged(null);
                          onDirty();
                        },
                      ),
                      const SizedBox(height: 8),
                      skillsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (skills) => upAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (ups) => _CultureSkillChooser(
                            label: StoryCultureSectionText.upbringingSkillLabel,
                            selectedCultureId: upbringingId,
                            cultureItems: ups,
                            selectedSkillId: upbringingSkillId,
                            conflictIndex: skillConflictIndex,
                            slotKey: HeroDraftClaims.cultureUpbringingSkillSlot,
                            allSkills: skills,
                            accent: const Color(0xFFAB47BC),
                            onChanged: (value) {
                              onUpbringingSkillChanged(value);
                              onDirty();
                            },
                          ),
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
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.languages,
    required this.selectedLanguageId,
    required this.conflictIndex,
    required this.onChanged,
  });

  final List<model.Component> languages;
  final String? selectedLanguageId;
  final HeroConflictIndex conflictIndex;
  final ValueChanged<String?> onChanged;

  static const _accent = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    const slotKey = HeroDraftClaims.cultureLanguageSlot;
    final conflict = selectedLanguageId == null
        ? null
        : conflictIndex.conflictFor(
            HeroEntryKey(
              entryType: 'language',
              canonicalEntryId: selectedLanguageId!,
            ),
            ignoredDraftSlotKey: slotKey,
          );
    final filteredLanguages = languages.where((language) {
      if (language.id == selectedLanguageId) return true;
      return !conflictIndex.isClaimed(
        HeroEntryKey(
          entryType: 'language',
          canonicalEntryId: language.id,
        ),
        ignoredDraftSlotKey: slotKey,
      );
    }).toList(growable: false);

    if (filteredLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = <String, List<model.Component>>{
      'human': [],
      'ancestral': [],
      'dead': [],
    };
    for (final lang in filteredLanguages) {
      final type = lang.data['language_type'] as String? ?? 'human';
      if (groups.containsKey(type)) {
        groups[type]!.add(lang);
      }
    }
    for (final list in groups.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    final selected = selectedLanguageId != null &&
            filteredLanguages.any((lang) => lang.id == selectedLanguageId)
        ? selectedLanguageId
        : null;

    Future<void> openSearch() async {
      final options = <_SearchOption<String?>>[
        _SearchOption<String?>(
          label: StoryCultureSectionText.chooseLanguageOption,
          value: null,
          subtitle: StoryCultureSectionText.noneSelected,
        ),
      ];

      for (final key in ['human', 'ancestral', 'dead']) {
        for (final lang in groups[key]!) {
          options.add(
            _SearchOption<String?>(
              label: lang.name,
              value: lang.id,
              subtitle: _buildLanguageSubtitle(lang, key),
            ),
          );
        }
      }

      final result = await _showSearchablePicker<String?>(
        context: context,
        title: StoryCultureSectionText.selectLanguageTitle,
        options: options,
        selected: selected,
        accent: _accent,
      );

      if (result == null) return;
      onChanged(result.value);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: FormTheme.surfaceDark,
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _accent.withValues(alpha: 0.2),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: const AppIcon(StoryIcons.languages,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  StoryCultureSectionText.languageLabel,
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: openSearch,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: FormTheme.surface,
                border: Border.all(color: FormTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected != null
                          ? filteredLanguages
                              .firstWhere((l) => l.id == selected)
                              .name
                          : StoryCultureSectionText.chooseLanguagePlaceholder,
                      style: TextStyle(
                        fontSize: 15,
                        color: selected != null
                            ? FormTheme.textSecondary
                            : FormTheme.textMuted,
                      ),
                    ),
                  ),
                  Icon(Icons.search, color: FormTheme.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (conflict != null) ...[
            const SizedBox(height: 6),
            Text(
              '${StoryCultureSectionText.languageConflictPrefix}${_conflictLabels(conflict)}',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _conflictLabels(HeroConflict conflict) {
    final labels = conflict.owners
        .map((owner) => owner.displayLabel ?? owner.source.toString())
        .toSet()
        .toList()
      ..sort();
    return labels.join(', ');
  }

  String _languageGroupTitle(String key) {
    switch (key) {
      case 'ancestral':
        return StoryCultureSectionText.ancestralLanguagesGroup;
      case 'dead':
        return StoryCultureSectionText.deadLanguagesGroup;
      default:
        return StoryCultureSectionText.humanLanguagesGroup;
    }
  }

  String _buildLanguageSubtitle(model.Component lang, String groupKey) {
    final data = lang.data;
    final parts = <String>[];

    // Add language type/group
    parts.add(_languageGroupTitle(groupKey));

    // Add region if available
    final region = data['region'] as String?;
    if (region != null && region.isNotEmpty) {
      parts.add(StoryCultureSectionText.regionSubtitle(region));
    }

    // Add ancestry if available
    final ancestry = data['ancestry'] as String?;
    if (ancestry != null && ancestry.isNotEmpty) {
      parts.add(StoryCultureSectionText.ancestrySubtitle(ancestry));
    }

    // Add common topics if available
    final topics = (data['common_topics'] as List?)?.cast<String>();
    if (topics != null && topics.isNotEmpty) {
      parts.add(StoryCultureSectionText.topicsSubtitle(
          '${topics.take(3).join(', ')}${topics.length > 3 ? '...' : ''}'));
    }

    return parts.join(' • ');
  }
}

class _CultureDropdown extends StatelessWidget {
  const _CultureDropdown({
    required this.label,
    required this.icon,
    required this.asyncList,
    required this.selectedId,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final AppIconData icon;
  final AsyncValue<List<model.Component>> asyncList;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return asyncList.when(
      loading: () => CreatorTheme.loadingIndicator(accent),
      error: (e, _) => CreatorTheme.errorMessage(
        '${StoryCultureSectionText.failedToLoadLabelPrefix}$label${StoryCultureSectionText.failedToLoadLabelSeparator}$e',
        accent: accent,
      ),
      data: (items) {
        items = List.of(items)..sort((a, b) => a.name.compareTo(b.name));
        final validSelected =
            selectedId != null && items.any((item) => item.id == selectedId)
                ? selectedId
                : null;
        final selectedItem = validSelected == null
            ? null
            : items.firstWhere((item) => item.id == validSelected,
                orElse: () => items.first);

        Future<void> openSearch() async {
          final options = <_SearchOption<String?>>[
            _SearchOption<String?>(
              label: StoryCultureSectionText.noneLabelText,
              value: null,
              subtitle: StoryCultureSectionText.noSelection,
            ),
            ...items.map(
              (item) => _SearchOption<String?>(
                label: item.name,
                value: item.id,
              ),
            ),
          ];

          final result = await _showSearchablePicker<String?>(
            context: context,
            title: '${StoryCultureSectionText.selectLabelPrefix}$label',
            options: options,
            selected: validSelected,
            accent: accent,
          );

          if (result == null) return;
          onChanged(result.value);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(icon, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: openSearch,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: FormTheme.surface,
                    border: Border.all(
                      color: validSelected != null
                          ? accent.withValues(alpha: 0.5)
                          : FormTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedItem != null
                              ? selectedItem.name
                              : StoryCultureSectionText.choosePlaceholder,
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedItem != null
                                ? FormTheme.textSecondary
                                : FormTheme.textMuted,
                          ),
                        ),
                      ),
                      Icon(Icons.search, color: FormTheme.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              if (selectedItem != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accent.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    (selectedItem.data['description'] as String?) ?? '',
                    style: TextStyle(
                      color: FormTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CultureSkillChooser extends StatelessWidget {
  const _CultureSkillChooser({
    required this.label,
    required this.selectedCultureId,
    required this.cultureItems,
    required this.allSkills,
    required this.selectedSkillId,
    required this.conflictIndex,
    required this.slotKey,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final String? selectedCultureId;
  final List<model.Component> cultureItems;
  final List<model.Component> allSkills;
  final String? selectedSkillId;
  final HeroConflictIndex conflictIndex;
  final String slotKey;
  final ValueChanged<String?> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (selectedCultureId == null) {
      return const SizedBox.shrink();
    }
    final selected = cultureItems.firstWhere(
      (c) => c.id == selectedCultureId,
      orElse: () => cultureItems.isNotEmpty
          ? cultureItems.first
          : const model.Component(id: '', type: '', name: ''),
    );
    if (selected.id.isEmpty) return const SizedBox.shrink();

    final groups =
        ((selected.data['skillGroups'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toSet();
    final specifics =
        ((selected.data['specificSkills'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .toSet();
    final eligible = <model.Component>{};
    for (final skill in allSkills) {
      final group = skill.data['group']?.toString();
      if (group != null && groups.contains(group)) {
        eligible.add(skill);
      }
      if (specifics.contains(skill.name) || specifics.contains(skill.id)) {
        eligible.add(skill);
      }
    }

    final allowedSkills = eligible.where((skill) {
      if (skill.id == selectedSkillId) return true;
      return !conflictIndex.isClaimed(
        HeroEntryKey(
          entryType: 'skill',
          canonicalEntryId: skill.id,
        ),
        ignoredDraftSlotKey: slotKey,
      );
    }).toList();

    if (allowedSkills.isEmpty) return const SizedBox.shrink();

    final helper = (selected.data['skillDescription'] as String?) ?? '';
    final skillGroups = <String, List<model.Component>>{};
    final ungrouped = <model.Component>[];

    for (final skill in allowedSkills) {
      final group = skill.data['group']?.toString();
      if (group != null && group.isNotEmpty) {
        skillGroups.putIfAbsent(group, () => []).add(skill);
      } else {
        ungrouped.add(skill);
      }
    }

    final sortedGroupKeys = skillGroups.keys.toList()..sort();
    for (final list in skillGroups.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    ungrouped.sort((a, b) => a.name.compareTo(b.name));

    final validSelected = selectedSkillId != null &&
            allowedSkills.any((s) => s.id == selectedSkillId)
        ? selectedSkillId
        : null;
    final selectedConflict = validSelected == null
        ? null
        : conflictIndex.conflictFor(
            HeroEntryKey(
              entryType: 'skill',
              canonicalEntryId: validSelected,
            ),
            ignoredDraftSlotKey: slotKey,
          );
    final selectedConflictOwners = selectedConflict?.owners
            .map(
              (owner) => owner.displayLabel ?? owner.source.toString(),
            )
            .join(', ') ??
        '';

    Future<void> openSearch() async {
      final options = <_SearchOption<String?>>[
        const _SearchOption<String?>(
          label: StoryCultureSectionText.chooseSkillOption,
          value: null,
        ),
      ];

      for (final groupKey in sortedGroupKeys) {
        for (final skill in skillGroups[groupKey]!) {
          options.add(
            _SearchOption<String?>(
              label: skill.name,
              value: skill.id,
              subtitle: skill.id == validSelected && selectedConflict != null
                  ? '${StoryCultureSectionText.skillConflictPrefix}$selectedConflictOwners'
                  : groupKey,
            ),
          );
        }
      }

      for (final skill in ungrouped) {
        options.add(
          _SearchOption<String?>(
            label: skill.name,
            value: skill.id,
            subtitle: skill.id == validSelected && selectedConflict != null
                ? '${StoryCultureSectionText.skillConflictPrefix}$selectedConflictOwners'
                : StoryCultureSectionText.otherGroupLabel,
          ),
        );
      }

      final result = await _showSearchablePicker<String?>(
        context: context,
        title: label,
        options: options,
        selected: validSelected,
        accent: accent,
      );

      if (result == null) return;
      onChanged(result.value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: FormTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: openSearch,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: FormTheme.surface,
              border: Border.all(
                color: validSelected != null
                    ? accent.withValues(alpha: 0.5)
                    : FormTheme.border,
              ),
            ),
            child: Row(
              children: [
                AppIcon(SkillGroupIcons.lore,
                    color: FormTheme.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    validSelected != null
                        ? eligible.firstWhere((s) => s.id == validSelected).name
                        : StoryCultureSectionText.chooseSkillPlaceholder,
                    style: TextStyle(
                      fontSize: 14,
                      color: validSelected != null
                          ? FormTheme.textSecondary
                          : FormTheme.textMuted,
                    ),
                  ),
                ),
                Icon(Icons.search, color: FormTheme.textMuted, size: 18),
              ],
            ),
          ),
        ),
        if (selectedConflict != null) ...[
          const SizedBox(height: 6),
          Text(
            '${StoryCultureSectionText.skillConflictPrefix}$selectedConflictOwners',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (helper.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            style: TextStyle(
              color: FormTheme.borderLight,
              fontSize: 11,
              height: 1.3,
              fontStyle: FontStyle.italic,
            ),
            softWrap: true,
          ),
        ],
      ],
    );
  }
}
