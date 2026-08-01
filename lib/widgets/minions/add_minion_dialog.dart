import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/providers.dart';
import '../../core/models/minion.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';
import '../retainers/retainer_template_card.dart' show retainerRoleColor;
import 'minion_template_card.dart';

/// Dialog for selecting a minion species to summon as a new squad.
///
/// Mirrors [AddRetainerDialog] (role filter chips, since minions share the
/// retainer role vocabulary). Portfolio-based filtering (only the hero's
/// chosen Portfolio) is deferred until the Portfolio subclass feature
/// exists — for now every seeded minion template is offered.
class AddMinionDialog extends ConsumerStatefulWidget {
  final void Function(Minion minion) onMinionSelected;

  const AddMinionDialog({
    super.key,
    required this.onMinionSelected,
  });

  @override
  ConsumerState<AddMinionDialog> createState() => _AddMinionDialogState();
}

class _AddMinionDialogState extends ConsumerState<AddMinionDialog> {
  String _searchQuery = '';
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final minionsAsync = ref.watch(allMinionTemplatesProvider);

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: minionAccent.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  const AppIcon(GreenFormIcons.widget,
                      color: minionAccent, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Summon Minion Squad',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: FormTheme.textBright, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search minions...',
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
            minionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (minions) {
                final roles = minions
                    .map((m) => m.stats.role)
                    .where((r) => r.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _filterChip('All', null),
                      ...roles.map((r) => _filterChip(
                            '${r[0].toUpperCase()}${r.substring(1)}',
                            r,
                          )),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Expanded(
              child: minionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: FormTheme.textMuted)),
                ),
                data: (minions) {
                  final filtered = _applyFilters(minions);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No minions match your search',
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
                      final minion = filtered[index];
                      final roleColor = retainerRoleColor(minion.stats.role);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MinionTemplateCard(minion: minion),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.onMinionSelected(minion);
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(Icons.person_add_alt_1_rounded,
                                    size: 16, color: roleColor),
                                label: Text(
                                  'Summon ${minion.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: roleColor,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      roleColor.withValues(alpha: 0.1),
                                  foregroundColor: roleColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: roleColor.withValues(alpha: 0.3),
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

  List<Minion> _applyFilters(List<Minion> minions) {
    return minions.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.stats.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.keywords
              .any((k) => k.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesRole = _selectedRole == null || m.stats.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Widget _filterChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    final color = role != null ? retainerRoleColor(role) : minionAccent;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : FormTheme.textMuted,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedRole = role),
        selectedColor: color.withOpacity(0.3),
        backgroundColor: Colors.white.withOpacity(0.05),
        side: BorderSide(
          color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
