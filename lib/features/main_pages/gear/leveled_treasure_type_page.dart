import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../widgets/treasures/treasures.dart';

class LeveledTreasureTypePage extends ConsumerWidget {
  final String leveledType;
  final String displayName;

  const LeveledTreasureTypePage({
    super.key,
    required this.leveledType,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
      ),
      body: _LeveledTreasureList(
        stream: ref.watch(componentsByTypeProvider('leveled_treasure')),
        leveledType: leveledType,
      ),
    );
  }
}

class _LeveledTreasureList extends StatelessWidget {
  final AsyncValue<List<model.Component>> stream;
  final String leveledType;

  const _LeveledTreasureList({
    required this.stream,
    required this.leveledType,
  });

  @override
  Widget build(BuildContext context) {
    return stream.when(
      data: (items) {
        // Filter items by leveled_type
        final filteredItems = items
            .where((item) => item.data['leveled_type'] == leveledType)
            .toList();
        
        if (filteredItems.isEmpty) {
          return const Center(child: Text('No treasures available for this type'));
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => TreasureCard(component: filteredItems[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: filteredItems.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}