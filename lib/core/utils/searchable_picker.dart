import 'package:flutter/material.dart';

import '../theme/navigation_theme.dart';
import '../theme/form_theme.dart';
import '../theme/picker_theme.dart';
import '../text/common/searchable_picker_text.dart';

/// Represents an option in a searchable picker.
class SearchableOption<T> {
  const SearchableOption({
    required this.label,
    required this.value,
    this.subtitle,
    this.isDisabled = false,
    this.disabledReason,
  });

  final String label;
  final T? value;
  final String? subtitle;
  
  /// If true, this option is shown but cannot be selected.
  final bool isDisabled;
  
  /// Reason shown when the option is disabled (e.g., "Already selected").
  final String? disabledReason;
}

/// Result from a searchable picker selection.
class SearchablePickerResult<T> {
  const SearchablePickerResult({required this.value});

  final T? value;
}

/// Configuration for conflict detection in pickers.
class PickerConflictConfig {
  const PickerConflictConfig({
    this.existingIds = const {},
    this.pageSelectedIds = const {},
    this.staticGrantIds = const {},
    this.currentSlotId,
  });

  /// IDs already saved in the database for this hero (from hero_entries).
  final Set<String> existingIds;
  
  /// IDs currently selected in other pickers on this page.
  final Set<String> pageSelectedIds;
  
  /// IDs that are statically granted (cannot be changed) from features/subclasses.
  final Set<String> staticGrantIds;
  
  /// The current ID in this slot (should not be excluded from its own picker).
  final String? currentSlotId;

  /// Returns all IDs that should be excluded from selection.
  Set<String> get allExcludedIds {
    final excluded = <String>{};
    excluded.addAll(existingIds);
    excluded.addAll(pageSelectedIds);
    excluded.addAll(staticGrantIds);
    // Don't exclude the current selection from its own picker
    if (currentSlotId != null) {
      excluded.remove(currentSlotId);
    }
    return excluded;
  }

  /// Checks if an ID is blocked and returns the reason.
  String? getBlockReason(String? id) {
    if (id == null || id.isEmpty) return null;
    if (id == currentSlotId) return null;
    
    if (staticGrantIds.contains(id)) {
      return SearchablePickerText.grantedByFeature;
    }
    if (existingIds.contains(id)) {
      return SearchablePickerText.alreadyOwned;
    }
    if (pageSelectedIds.contains(id)) {
      return SearchablePickerText.alreadySelectedOnPage;
    }
    return null;
  }
}

/// A notification widget that shows when there are static grant conflicts.
class StaticGrantConflictNotice extends StatelessWidget {
  const StaticGrantConflictNotice({
    super.key,
    required this.conflictingIds,
    required this.itemType,
    this.onDismiss,
  });

  final Set<String> conflictingIds;
  final String itemType; // e.g., "skill", "language"
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (conflictingIds.isEmpty) return const SizedBox.shrink();

    const errorColor = PickerTheme.errorColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SearchablePickerText.duplicateDetected(
                    itemType,
                    multiple: conflictingIds.length > 1,
                  ),
                  style: const TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SearchablePickerText.duplicateDescription(itemType),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade500),
              onPressed: onDismiss,
              iconSize: 20,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

/// Shows a searchable picker dialog with exclusion support.
/// 
/// Parameters:
/// - [context]: Build context for the dialog.
/// - [title]: Title shown at the top of the picker.
/// - [options]: List of options to display.
/// - [selected]: Currently selected value.
/// - [conflictConfig]: Optional configuration for excluding already-selected items.
/// - [autofocusSearch]: Whether to auto-focus the search field (default: false).
/// - [showDisabledOptions]: Whether to show disabled options in the list (default: true).
/// - [emptyOptionLabel]: Label for an empty/clear option (e.g., "None").
/// - [accentColor]: Optional accent color (defaults to blue).
/// - [icon]: Optional header icon (defaults to search icon).
Future<SearchablePickerResult<T>?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<SearchableOption<T>> options,
  T? selected,
  PickerConflictConfig? conflictConfig,
  bool autofocusSearch = false,
  bool showDisabledOptions = true,
  String? emptyOptionLabel,
  Color? accentColor,
  IconData? icon,
}) {
  final effectiveAccent = accentColor ?? PickerTheme.defaultAccent;
  final effectiveIcon = icon ?? Icons.search;
  
  return showDialog<SearchablePickerResult<T>>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = query.trim().toLowerCase();
          
          // Filter by search query
          List<SearchableOption<T>> filtered = normalizedQuery.isEmpty
              ? options
              : options
                  .where(
                    (option) =>
                        option.label.toLowerCase().contains(normalizedQuery) ||
                        (option.subtitle?.toLowerCase().contains(normalizedQuery) ?? false),
                  )
                  .toList();

          // Apply conflict config to mark disabled options
          if (conflictConfig != null) {
            filtered = filtered.map((option) {
              final id = option.value?.toString();
              final blockReason = conflictConfig.getBlockReason(id);
              if (blockReason != null && !option.isDisabled) {
                return SearchableOption<T>(
                  label: option.label,
                  value: option.value,
                  subtitle: option.subtitle,
                  isDisabled: true,
                  disabledReason: blockReason,
                );
              }
              return option;
            }).toList();
          }

          // Optionally hide disabled options
          if (!showDisabledOptions) {
            filtered = filtered.where((o) => !o.isDisabled).toList();
          }

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
                          effectiveAccent.withValues(alpha: 0.2),
                          effectiveAccent.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: FormTheme.surfaceMuted,
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
                            color: effectiveAccent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: effectiveAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(effectiveIcon, color: effectiveAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: effectiveAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
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
                      autofocus: autofocusSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: SearchablePickerText.searchHint,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: effectiveAccent, width: 2),
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
                                  color: Colors.grey.shade600,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  SearchablePickerText.noMatchesFound,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
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
                            itemCount: filtered.length + (emptyOptionLabel != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Handle empty option at the top
                              if (emptyOptionLabel != null && index == 0) {
                                final isSelected = selected == null;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: isSelected
                                        ? effectiveAccent.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border.all(
                                            color: effectiveAccent.withValues(alpha: 0.4),
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      emptyOptionLabel,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: isSelected
                                            ? effectiveAccent
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle, color: effectiveAccent, size: 22)
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    onTap: () => Navigator.of(context).pop(
                                      SearchablePickerResult<T>(value: null),
                                    ),
                                  ),
                                );
                              }
                              
                              final optionIndex = emptyOptionLabel != null ? index - 1 : index;
                              final option = filtered[optionIndex];
                              final isSelected = option.value == selected ||
                                  (option.value == null && selected == null);
                              
                              if (option.isDisabled) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: FormTheme.surface,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      option.label,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      option.disabledReason ?? SearchablePickerText.unavailable,
                                      style: TextStyle(
                                        color: Colors.red.shade300.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    enabled: false,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSelected
                                      ? effectiveAccent.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: effectiveAccent.withValues(alpha: 0.4),
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  title: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? effectiveAccent
                                          : Colors.grey.shade200,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: option.subtitle != null
                                      ? Text(
                                          option.subtitle!,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle, color: effectiveAccent, size: 22)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    SearchablePickerResult<T>(value: option.value),
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
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                      ),
                      child: const Text('Cancel'),
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

/// Helper to build options from components, automatically marking excluded ones.
List<SearchableOption<String?>> buildComponentOptions({
  required Iterable<dynamic> components,
  required String Function(dynamic) idSelector,
  required String Function(dynamic) labelSelector,
  String Function(dynamic)? subtitleSelector,
  PickerConflictConfig? conflictConfig,
  bool includeNoneOption = false,
  String noneLabel = 'None',
}) {
  final options = <SearchableOption<String?>>[];
  
  if (includeNoneOption) {
    options.add(SearchableOption<String?>(
      label: noneLabel,
      value: null,
    ));
  }
  
  for (final component in components) {
    final id = idSelector(component);
    final label = labelSelector(component);
    final subtitle = subtitleSelector?.call(component);
    
    String? disabledReason;
    if (conflictConfig != null) {
      disabledReason = conflictConfig.getBlockReason(id);
    }
    
    options.add(SearchableOption<String?>(
      label: label,
      value: id,
      subtitle: subtitle,
      isDisabled: disabledReason != null,
      disabledReason: disabledReason,
    ));
  }
  
  return options;
}
