import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/providers.dart';
import '../../../core/models/component.dart' as model;
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/kit_page_theme.dart';
import '../../../widgets/kits/equipment_card.dart';

class KitsPage extends ConsumerStatefulWidget {
  const KitsPage({super.key});

  @override
  ConsumerState<KitsPage> createState() => _KitsPageState();
}

class _KitsPageState extends ConsumerState<KitsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: KitPageTheme.tabData.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        backgroundColor: NavigationTheme.navBarBackground,
        title: const Text('Kits & Equipment'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom tab bar
          Container(
            color: NavigationTheme.navBarBackground,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(KitPageTheme.tabData.length, (index) {
                  final tab = KitPageTheme.tabData[index];
                  final isSelected = _tabController.index == index;
                  final color = tab.color;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade700,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: isSelected ? color : Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('kit')),
                  itemBuilder: (c) => EquipmentCard(component: c),
                ),
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('stormwight_kit')),
                  itemBuilder: (c) => EquipmentCard(component: c),
                ),
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('psionic_augmentation')),
                  itemBuilder: (c) => EquipmentCard(component: c, badgeLabel: 'Augmentation'),
                ),
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('enchantment')),
                  itemBuilder: (c) => EquipmentCard(component: c, badgeLabel: 'Enchantment'),
                ),
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('prayer')),
                  itemBuilder: (c) => EquipmentCard(component: c, badgeLabel: 'Prayer'),
                ),
                _ComponentsList(
                  stream: ref.watch(componentsByTypeProvider('ward')),
                  itemBuilder: (c) => EquipmentCard(component: c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentsList extends StatelessWidget {
  final AsyncValue<List<model.Component>> stream;
  final Widget Function(model.Component) itemBuilder;

  const _ComponentsList({
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NavigationTheme.navBarBackground,
      child: stream.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'None available',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) => itemBuilder(items[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error: $e', style: TextStyle(color: Colors.grey.shade400)),
        ),
      ),
    );
  }
}

