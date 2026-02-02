import 'package:flutter/material.dart';
import '../../../core/models/feature.dart';
import '../../../core/repositories/feature_repository.dart';
import '../../../core/theme/feature_tokens.dart';
import '../../../widgets/features/class_navigation_card.dart';
import '../../../widgets/features/features_overview_stats.dart';
import 'class_detail_page.dart';

class StrifeFeaturesPage extends StatefulWidget {
  const StrifeFeaturesPage({super.key});

  @override
  State<StrifeFeaturesPage> createState() => _StrifeFeaturesPageState();
}

class _StrifeFeaturesPageState extends State<StrifeFeaturesPage> {
  Map<String, List<Feature>> _classFeatures = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    try {
      final features = await FeatureRepository.loadAllClassFeatures();
      setState(() {
        _classFeatures = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Class Features'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: FeatureTokens.getClassColor('elementalist'),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading class features...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load features',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadFeatures();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_classFeatures.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
            ),
            SizedBox(height: 24),
            Text(
              'No class features found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  FeatureTokens.getClassColor('elementalist').withValues(alpha: 0.1),
                  FeatureTokens.getClassColor('censor').withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 48,
                  color: FeatureTokens.getClassColor('elementalist'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Your Class',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: FeatureTokens.getClassColor('elementalist'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore features and abilities for each class',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Overview stats
        SliverToBoxAdapter(
          child: FeaturesOverviewStats(classFeatures: _classFeatures),
        ),

        // Class navigation cards
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = _classFeatures.entries.elementAt(index);
                return ClassNavigationCard(
                  className: entry.key,
                  featureCount: entry.value.length,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClassDetailPage(
                          className: entry.key,
                          features: entry.value,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: _classFeatures.length,
            ),
          ),
        ),
      ],
    );
  }
}
