import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hero_main_stats_view.dart';

class SheetMainStats extends ConsumerWidget {
  const SheetMainStats({
    super.key,
    required this.heroId,
    required this.heroName,
  });

  final String heroId;
  final String heroName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HeroMainStatsView(heroId: heroId, heroName: heroName);
  }
}
