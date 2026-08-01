import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/companion.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import 'companion_template_card.dart';

/// Dialog for selecting a companion to add to a hero.
///
/// Mirrors [AddRetainerDialog] but simpler: companions have no role field, so
/// there is no role filter row.
class AddCompanionDialog extends ConsumerStatefulWidget {
  final void Function(Companion companion) onCompanionSelected;

  const AddCompanionDialog({
    super.key,
    required this.onCompanionSelected,
  });

  @override
  ConsumerState<AddCompanionDialog> createState() =>
      _AddCompanionDialogState();
}

class _AddCompanionDialogState extends ConsumerState<AddCompanionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final companionsAsync = ref.watch(allCompanionTemplatesProvider);

    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        width: 420,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: companionAccent.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const AppIcon(GreenFormIcons.widget,
                      color: companionAccent, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Add Companion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FormTheme.textBright,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: FormTheme.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: FormTheme.textBright, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search companions...',
                  hintStyle: TextStyle(color: FormTheme.textMuted),
                  prefixIcon:
                      Icon(Icons.search, color: FormTheme.textMuted, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Companion list
            Expanded(
              child: companionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: FormTheme.textMuted)),
                ),
                data: (companions) {
                  final filtered = _applyFilters(companions);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No companions match your search',
                        style: TextStyle(color: FormTheme.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final companion = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CompanionTemplateCard(companion: companion),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.onCompanionSelected(companion);
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 16, color: companionAccent),
                                label: Text(
                                  'Add ${companion.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: companionAccent,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      companionAccent.withValues(alpha: 0.1),
                                  foregroundColor: companionAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color:
                                          companionAccent.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Companion> _applyFilters(List<Companion> companions) {
    if (_searchQuery.isEmpty) return companions;
    final query = _searchQuery.toLowerCase();
    return companions.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.keywords.any((k) => k.toLowerCase().contains(query));
    }).toList();
  }
}
