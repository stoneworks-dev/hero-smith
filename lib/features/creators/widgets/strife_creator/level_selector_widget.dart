import 'package:flutter/material.dart';

import '../../../../core/theme/creator_theme.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/form_theme.dart';
import '../../../../core/text/creators/widgets/strife_creator/level_selector_widget_text.dart';

// Helper classes for picker
class _SearchOption {
  final String value;
  final String label;

  const _SearchOption({
    required this.value,
    required this.label,
  });
}

class _PickerSelection {
  final String? value;
  final String? label;

  const _PickerSelection({
    this.value,
    this.label,
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
  IconData icon = Icons.trending_up,
}) async {
  return showDialog<_PickerSelection>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
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
              // Options list (no search for levels since it's a small list)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
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
                                  child: Text(
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
                    LevelSelectorWidgetText.cancelButton,
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
}

/// Widget for selecting hero level (1-10)
class LevelSelectorWidget extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;

  const LevelSelectorWidget({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: CreatorTheme.sectionMargin,
      decoration: CreatorTheme.sectionDecoration(const Color.fromARGB(255, 53, 164, 229)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatorTheme.sectionHeader(
            title: LevelSelectorWidgetText.heroLevelLabel,
            subtitle: LevelSelectorWidgetText.levelSubtitle,
            icon: Icons.trending_up,
            accent: const Color.fromARGB(255, 53, 126, 229),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: InkWell(
              onTap: () async {
                final options = List.generate(10, (index) => index + 1)
                    .map((level) => _SearchOption(
                          value: level.toString(),
                          label: '${LevelSelectorWidgetText.levelOptionPrefix}$level',
                        ))
                    .toList();

                final result = await _showSearchablePicker(
                  context: context,
                  options: options,
                  title: LevelSelectorWidgetText.selectLevelTitle,
                  currentValue: selectedLevel.toString(),
                  accentColor: const Color.fromARGB(255, 53, 120, 229),
                  icon: Icons.trending_up,
                );

                if (result?.value != null) {
                  onLevelChanged(int.parse(result!.value!));
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: CreatorTheme.dropdownDecoration(
                  label: LevelSelectorWidgetText.heroLevelLabel,
                  accent: _accent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${LevelSelectorWidgetText.levelOptionPrefix}$selectedLevel',
                      style: const TextStyle(
                        color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}

