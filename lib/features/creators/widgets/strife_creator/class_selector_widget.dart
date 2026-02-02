import 'package:flutter/material.dart';

import '../../../../core/models/class_data.dart';
import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/class_selector_widget_text.dart';

// Helper classes for picker
class _SearchOption {
  final String value;
  final String label;
  final String? subtitle;

  const _SearchOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class _PickerSelection {
  final String? value;
  final String? label;
  final String? subtitle;

  const _PickerSelection({
    this.value,
    this.label,
    this.subtitle,
  });
}

const Color _accent = CreatorTheme.classAccent;

// Helper function to show searchable picker dialog
Future<_PickerSelection?> _showSearchablePicker({
  required BuildContext context,
  required List<_SearchOption> options,
  required String title,
  String? currentValue,
  Color accentColor = _accent,
  IconData icon = Icons.auto_awesome,
}) async {
  String searchQuery = '';

  return showDialog<_PickerSelection>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredOptions = options.where((option) {
            final query = searchQuery.toLowerCase();
            return option.label.toLowerCase().contains(query) ||
                (option.subtitle?.toLowerCase().contains(query) ?? false);
          }).toList();

          return Dialog(
            backgroundColor: NavigationTheme.cardBackgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: accentColor.withValues(alpha: 0.3),
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
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      autofocus: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: ClassSelectorWidgetText.searchHint,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: FormTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: accentColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  // Options list
                  Flexible(
                    child: filteredOptions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                ClassSelectorWidgetText.noMatchesFound,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredOptions.length,
                            itemBuilder: (context, index) {
                              final option = filteredOptions[index];
                              final isSelected = option.value == currentValue;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(
                                        context,
                                        _PickerSelection(
                                          value: option.value,
                                          label: option.label,
                                          subtitle: option.subtitle,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accentColor.withValues(alpha: 0.15)
                                            : FormTheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? accentColor.withValues(alpha: 0.5)
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option.label,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? accentColor
                                                        : Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (option.subtitle != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    option.subtitle!,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade400,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: accentColor,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Cancel button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        ClassSelectorWidgetText.cancelButton,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
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

/// Widget for selecting hero class
class ClassSelectorWidget extends StatelessWidget {
  final List<ClassData> availableClasses;
  final ClassData? selectedClass;
  final int selectedLevel;
  final ValueChanged<ClassData> onClassChanged;

  const ClassSelectorWidget({
    super.key,
    required this.availableClasses,
    required this.selectedClass,
    required this.selectedLevel,
    required this.onClassChanged,
  });

  static const _accent = CreatorTheme.classAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(_accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: ClassSelectorWidgetText.title,
            subtitle: ClassSelectorWidgetText.subtitle,
            icon: Icons.school,
            accent: _accent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final options = availableClasses
                        .map((classData) => _SearchOption(
                              value: classData.name,
                              label: classData.name,
                              subtitle: classData.startingCharacteristics.heroicResourceName,
                            ))
                        .toList();

                    final result = await _showSearchablePicker(
                      context: context,
                      options: options,
                      title: ClassSelectorWidgetText.selectClassTitle,
                      currentValue: selectedClass?.name,
                      accentColor: _accent,
                      icon: Icons.school,
                    );

                    if (result?.value != null) {
                      final selected = availableClasses.firstWhere(
                        (c) => c.name == result!.value,
                      );
                      onClassChanged(selected);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: CreatorTheme.dropdownDecoration(
                      label: ClassSelectorWidgetText.classLabel,
                      accent: _accent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedClass?.name ?? ClassSelectorWidgetText.selectClassHint,
                          style: TextStyle(
                            color: selectedClass != null
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedClass != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _accent.withValues(alpha: 0.2),
                                border: Border.all(color: _accent.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: _accent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedClass!.startingCharacteristics.heroicResourceName,
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedClass!.startingCharacteristics.motto != null)
                          Text(
                            selectedClass!.startingCharacteristics.motto!,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (selectedClass!.startingCharacteristics.motto != null)
                          const SizedBox(height: 12),
                        if (selectedClass!.startingCharacteristics.motto == null)
                          const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _buildStatChip(
                              ClassSelectorWidgetText.staminaLabel,
                              '${_calculateStamina(selectedClass!.startingCharacteristics.baseStamina, selectedClass!.startingCharacteristics.staminaPerLevel, selectedLevel)}${ClassSelectorWidgetText.staminaValueSuffixPrefix}${selectedClass!.startingCharacteristics.baseStamina}${ClassSelectorWidgetText.staminaValueSuffixMiddle}${selectedClass!.startingCharacteristics.staminaPerLevel}${ClassSelectorWidgetText.staminaValueSuffixSuffix}',
                            ),
                            _buildStatChip(
                              ClassSelectorWidgetText.recoveriesLabel,
                              '${selectedClass!.startingCharacteristics.baseRecoveries}',
                            ),
                          ],
                        ),
                      ],
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

  int _calculateStamina(int baseStamina, int staminaPerLevel, int level) {
    return baseStamina + (staminaPerLevel * (level - 1));
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label${ClassSelectorWidgetText.statLabelSuffix}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

