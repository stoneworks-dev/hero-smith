import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/retainer.dart';
import '../../../core/text/main_pages/strife/retainers_page_text.dart';
import '../../../core/theme/form_theme.dart';
import '../../../widgets/retainers/retainer_template_card.dart';

/// Browse all seeded retainers, grouped by role.
class RetainersPage extends ConsumerWidget {
  const RetainersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retainersAsync = ref.watch(allRetainerTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(RetainersPageText.appBarTitle)),
      body: retainersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(RetainersPageText.errorMessage(e))),
        data: (retainers) {
          if (retainers.isEmpty) {
            return const Center(
                child: Text(RetainersPageText.noRetainersFound));
          }

          // Group by role
          final Map<String, List<Retainer>> grouped = {};
          for (final r in retainers) {
            final role = r.role.isNotEmpty ? r.role : 'other';
            grouped.putIfAbsent(role, () => []).add(r);
          }

          // Sort roles alphabetically; put 'other' last
          final roles = grouped.keys.toList()
            ..sort((a, b) {
              if (a == 'other') return 1;
              if (b == 'other') return -1;
              return a.compareTo(b);
            });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roles
                  .map((role) => _buildGroup(context, role, grouped[role]!))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(
      BuildContext context, String role, List<Retainer> retainers) {
    retainers.sort((a, b) => a.name.compareTo(b.name));
    final title = role == 'other'
        ? RetainersPageText.otherRetainers
        : RetainersPageText.roleGroup(role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: retainerRoleColor(role).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: retainerRoleColor(role).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${retainers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FormTheme.textBright,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...retainers.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: RetainerTemplateCard(retainer: r),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}
