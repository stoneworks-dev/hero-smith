import 'package:flutter/material.dart';

import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';

class AbilityFilterDropdown extends StatelessWidget {
  const AbilityFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.allLabelPrefix,
    this.enabled = true,
    this.accentColor,
  });

  final String label;
  final String? value;
  final List<String> options;
  final void Function(String?) onChanged;
  final String allLabelPrefix;
  final bool enabled;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? FormTheme.textSecondary;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: NavigationTheme.cardBackgroundDark,
        border: Border.all(
          color: value != null
              ? accent
              : (enabled
                    ? FormTheme.border
                    : FormTheme.borderDim),
          width: value != null ? 2 : 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          label,
          style: TextStyle(
            color: enabled ? FormTheme.textSecondary : FormTheme.borderLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        underline: const SizedBox.shrink(),
        isDense: true,
        isExpanded: true,
        dropdownColor: NavigationTheme.cardBackgroundDark,
        style: TextStyle(
          color: FormTheme.textSecondary,
          fontSize: 14,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: value != null ? accent : FormTheme.textMuted,
        ),
        items: enabled
            ? [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('$allLabelPrefix$label', overflow: TextOverflow.ellipsis),
                ),
                ...options.map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ]
            : null,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
