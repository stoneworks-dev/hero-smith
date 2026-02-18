import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/text/main_pages/strife/conditions_page_text.dart';
import '../../../widgets/conditions/condition_card.dart';

class ConditionsPage extends ConsumerWidget {
  const ConditionsPage({super.key});

  Future<void> _deleteCondition(BuildContext context, WidgetRef ref, String conditionId, String conditionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ConditionsPageText.deleteConditionTitle),
          content: Text(ConditionsPageText.deleteConfirmation(conditionName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(ConditionsPageText.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(ConditionsPageText.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(componentRepositoryProvider);
        await repo.delete(conditionId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ConditionsPageText.conditionDeleted(conditionName)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ConditionsPageText.errorDeletingCondition(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(componentsByTypeProvider('condition'));

    return Scaffold(
      appBar: AppBar(
        title: Text(ConditionsPageText.appBarTitle),
      ),
      body: conditionsAsync.when(
        data: (conditions) {
          if (conditions.isEmpty) {
            return Center(
              child: Text(ConditionsPageText.noConditionsAvailable),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ConditionsPageText.countAvailable(conditions.length),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: conditions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final condition = conditions[index];
                      return ConditionCard(
                        condition: condition,
                        onDelete: condition.source == 'user'
                            ? () => _deleteCondition(context, ref, condition.id, condition.name)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(ConditionsPageText.errorLoading(error)),
            ],
          ),
        ),
      ),
    );
  }
}