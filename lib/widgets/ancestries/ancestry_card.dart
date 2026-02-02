import 'package:flutter/material.dart';
import 'package:hero_smith/core/models/component.dart';
import 'package:hero_smith/core/theme/ds_theme.dart';
import 'package:hero_smith/widgets/shared/expandable_card.dart';

class AncestryCard extends StatelessWidget {
  final Component ancestry;
  final Component? ancestryTraits;

  const AncestryCard({
    super.key,
    required this.ancestry,
    this.ancestryTraits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    final data = ancestry.data;
    final name = ancestry.name;
    final description = _getDescription();

    return ExpandableCard(
      title: name,
      borderColor: theme.ancestryBorder,
      badge: Chip(
        label: Text(
          '🧬 Ancestry',
          style: theme.badgeTextStyle,
        ),
        backgroundColor: theme.ancestryBorder.withOpacity(0.1),
        side: BorderSide(color: theme.ancestryBorder, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            _buildSection(
              context,
              '${theme.ancestrySectionEmoji['description']} Description',
              _buildDescriptionContent(description),
            ),
            const SizedBox(height: 16),
          ],
          _buildSection(
            context,
            '${theme.ancestrySectionEmoji['stats']} Physical Stats',
            _buildStatsContent(context, data),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '${theme.ancestrySectionEmoji['exampleNames']} Example Names',
            _buildExampleNamesContent(context, data),
          ),
          if (ancestryTraits != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              '${theme.ancestrySectionEmoji['signature']} Signature Ability',
              _buildSignatureContent(context, ancestryTraits!.data),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              '${theme.ancestrySectionEmoji['traits']} Optional Traits',
              _buildTraitsContent(context, ancestryTraits!.data),
            ),
          ],
        ],
      ),
    );
  }

  String _getDescription() {
    // For now, we'll generate a basic description from the physical stats
    // In a full implementation, you might have description data
    return 'A playable ancestry with unique physical characteristics and cultural traits.';
  }

  Widget _buildSection(BuildContext context, String label, Widget content) {
    final theme = DsTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: theme.sectionLabelStyle,
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildDescriptionContent(String description) {
    return Text(
      description,
      style: const TextStyle(height: 1.4),
    );
  }

  Widget _buildStatsContent(BuildContext context, Map<String, dynamic> data) {
    final height = data['height'] as Map<String, dynamic>?;
    final weight = data['weight'] as Map<String, dynamic>?;
    final lifeExpectancy = data['life_expectancy'] as Map<String, dynamic>?;
    final size = data['size'] as String? ?? 'Unknown';
    final speed = data['speed'] as int? ?? 0;
    final stability = data['stability'] as int? ?? 0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (height != null)
          _buildStatChip(
            'Height: ${height['min'] ?? '?'} - ${height['max'] ?? '?'}',
            Colors.blue,
          ),
        if (weight != null)
          _buildStatChip(
            'Weight: ${weight['min'] ?? '?'} - ${weight['max'] ?? '?'} lbs',
            Colors.green,
          ),
        if (lifeExpectancy != null)
          _buildStatChip(
            'Lifespan: ${lifeExpectancy['min'] ?? '?'} - ${lifeExpectancy['max'] ?? '?'} years',
            Colors.purple,
          ),
        _buildStatChip('Size: $size', Colors.orange),
        _buildStatChip('Speed: $speed', Colors.teal),
        _buildStatChip('Stability: $stability', Colors.red),
      ],
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildExampleNamesContent(BuildContext context, Map<String, dynamic> data) {
    final exampleNames = data['exampleNames'] as Map<String, dynamic>?;
    
    if (exampleNames == null) {
      return const Text('No example names available.');
    }

    final notes = exampleNames['notes'] as String?;
    final feminine = exampleNames['feminine'] as List<dynamic>?;
    final masculine = exampleNames['masculine'] as List<dynamic>?;
    final genderNeutral = exampleNames['genderNeutral'] as List<dynamic>?;
    final examples = exampleNames['examples'] as List<dynamic>?;
    final epithets = exampleNames['epithets'] as List<dynamic>?;
    final surnames = exampleNames['surnames'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notes != null && notes.isNotEmpty) ...[
          Text(
            notes,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (examples != null && examples.isNotEmpty) ...[
          _buildNameSection('Examples', examples, Colors.indigo),
          const SizedBox(height: 8),
        ],
        if (feminine != null && feminine.isNotEmpty) ...[
          _buildNameSection('Feminine', feminine, Colors.pink),
          const SizedBox(height: 8),
        ],
        if (masculine != null && masculine.isNotEmpty) ...[
          _buildNameSection('Masculine', masculine, Colors.blue),
          const SizedBox(height: 8),
        ],
        if (genderNeutral != null && genderNeutral.isNotEmpty) ...[
          _buildNameSection('Gender Neutral', genderNeutral, Colors.purple),
          const SizedBox(height: 8),
        ],
        if (epithets != null && epithets.isNotEmpty) ...[
          _buildNameSection('Epithets', epithets, Colors.amber),
          const SizedBox(height: 8),
        ],
        if (surnames != null && surnames.isNotEmpty) ...[
          _buildNameSection('Surnames', surnames, Colors.teal),
        ],
      ],
    );
  }

  Widget _buildNameSection(String title, List<dynamic> names, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: names
              .map((name) => _buildNameChip(name.toString(), color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNameChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSignatureContent(BuildContext context, Map<String, dynamic> traitsData) {
    final signatureData = traitsData['signature'];
    
    if (signatureData == null) {
      return const Text('No signature ability available.');
    }

    // Handle both single signature (Map) and multiple signatures (List)
    final List<Map<String, dynamic>> signatures;
    if (signatureData is List) {
      signatures = signatureData.cast<Map<String, dynamic>>();
    } else if (signatureData is Map<String, dynamic>) {
      signatures = [signatureData];
    } else {
      return const Text('No signature ability available.');
    }

    return Column(
      children: signatures.map((signature) {
        final name = signature['name'] as String? ?? 'Unknown';
        final description = signature['description'] as String? ?? '';

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: signatures.last == signature ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(0, 255, 248, 225),
            border: Border.all(color: Colors.amber.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                  fontSize: 14,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTraitsContent(BuildContext context, Map<String, dynamic> traitsData) {
    final traits = traitsData['traits'] as List<dynamic>?;
    final points = traitsData['points'] as int? ?? 0;
    
    if (traits == null || traits.isEmpty) {
      return const Text('No optional traits available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Available Points: $points',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...traits.map((trait) {
          final traitMap = trait as Map<String, dynamic>;
          return _AncestryTraitDropdown(
            name: traitMap['name'] as String? ?? 'Unknown Trait',
            description: traitMap['description'] as String? ?? '',
            cost: traitMap['cost'] as int? ?? 0,
          );
        }),
      ],
    );
  }
}

class _AncestryTraitDropdown extends StatefulWidget {
  final String name;
  final String description;
  final int cost;

  const _AncestryTraitDropdown({
    required this.name,
    required this.description,
    required this.cost,
  });

  @override
  State<_AncestryTraitDropdown> createState() => _AncestryTraitDropdownState();
}

class _AncestryTraitDropdownState extends State<_AncestryTraitDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.ancestryBorder.withOpacity(0.05),
        border: Border.all(color: theme.ancestryBorder.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.ancestryBorder.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.cost} pt${widget.cost != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && widget.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.description,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}