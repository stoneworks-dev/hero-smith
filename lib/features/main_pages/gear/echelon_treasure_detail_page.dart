import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../widgets/treasures/treasures.dart';

class EchelonTreasureDetailPage extends ConsumerWidget {
  final int echelon;
  final String treasureType;
  final String displayName;

  const EchelonTreasureDetailPage({
    super.key,
    required this.echelon,
    required this.treasureType,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getEchelonName(echelon)} $displayName'),
      ),
      body: _TreasureList(
        stream: ref.watch(componentsByTypeProvider(treasureType)),
        echelon: echelon,
        itemBuilder: (c) => _buildTreasureCard(c),
      ),
    );
  }

  Widget _buildTreasureCard(model.Component component) {
    // Use the unified TreasureCard for all treasure types
    return TreasureCard(component: component);
  }

  String _getEchelonName(int echelon) {
    switch (echelon) {
      case 1:
        return '1st Echelon';
      case 2:
        return '2nd Echelon';
      case 3:
        return '3rd Echelon';
      case 4:
        return '4th Echelon';
      default:
        return '${echelon}th Echelon';
    }
  }
}

class _TreasureList extends StatelessWidget {
  final AsyncValue<List<model.Component>> stream;
  final int echelon;
  final Widget Function(model.Component) itemBuilder;

  const _TreasureList({
    required this.stream,
    required this.echelon,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return stream.when(
      data: (items) {
        // Filter items by echelon
        final filteredItems = items
            .where((item) => item.data['echelon'] == echelon)
            .toList();
        
        if (filteredItems.isEmpty) {
          return const Center(child: Text('No treasures available for this echelon'));
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => itemBuilder(filteredItems[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: filteredItems.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}