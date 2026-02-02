import 'package:flutter/material.dart';
import '../../core/models/feature.dart';

class FeatureSearchDelegate extends SearchDelegate<Feature?> {
  final List<Feature> features;
  final String className;

  FeatureSearchDelegate({
    required this.features,
    required this.className,
  }) : super(
    searchFieldLabel: 'Search $className features...',
    searchFieldStyle: const TextStyle(fontSize: 16),
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredFeatures = _filterFeatures();
    
    if (filteredFeatures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty 
                  ? 'Enter a search term to find features'
                  : 'No features found for "$query"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredFeatures.length,
      itemBuilder: (context, index) {
        final feature = filteredFeatures[index];
        return ListTile(
          title: Text(
            feature.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Chip(
                    label: Text('Level ${feature.level}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  if (feature.isSubclassFeature && feature.subclassName != null)
                    Chip(
                      label: Text(feature.subclassName!),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _truncateDescription(feature.description),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => close(context, feature),
        );
      },
    );
  }

  List<Feature> _filterFeatures() {
    if (query.isEmpty) return [];
    
    final searchQuery = query.toLowerCase();
    
    return features.where((feature) {
      // Search in name
      if (feature.name.toLowerCase().contains(searchQuery)) return true;
      
      // Search in description
      if (feature.description.toLowerCase().contains(searchQuery)) return true;
      
      // Search in subclass name
      if (feature.subclassName?.toLowerCase().contains(searchQuery) ?? false) return true;
      
      // Search by level
      if (feature.level.toString().contains(searchQuery)) return true;
      
      return false;
    }).toList();
  }

  String _truncateDescription(String description) {
    if (description.length <= 120) return description;
    return '${description.substring(0, 120)}...';
  }
}