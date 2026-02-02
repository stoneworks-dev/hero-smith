/// Example page showing how to use simplified abilities
/// 
/// To display abilities using the new simplified format:
/// 
/// 1. Load simplified abilities for a class:
///    ```dart
///    final abilities = await AbilityDataService().loadClassAbilitiesSimplified('fury');
///    ```
/// 
/// 2. Create AbilityData from simplified ability:
///    ```dart
///    final abilityData = AbilityData.fromSimplified(simplifiedAbility);
///    ```
/// 
/// 3. Use with existing widgets (they already support both formats):
///    - AbilityExpandableItem (requires Component, see note below)
///    - AbilitySummary (can use abilityData parameter)
///    - AbilityFullView (can use abilityData parameter)
/// 
/// Note: AbilityExpandableItem currently requires a Component.
/// For simplified abilities, you can use AbilitySummary and AbilityFullView directly
/// by passing the AbilityData instance.
/// 
/// Example:
/// ```dart
/// class SimplifiedAbilitiesExample extends StatefulWidget {
///   @override
///   State<SimplifiedAbilitiesExample> createState() => _SimplifiedAbilitiesExampleState();
/// }
/// 
/// class _SimplifiedAbilitiesExampleState extends State<SimplifiedAbilitiesExample> {
///   List<AbilitySimplified> _abilities = [];
///   bool _loading = true;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _loadAbilities();
///   }
/// 
///   Future<void> _loadAbilities() async {
///     final abilities = await AbilityDataService().loadClassAbilitiesSimplified('censor');
///     setState(() {
///       _abilities = abilities;
///       _loading = false;
///     });
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     if (_loading) {
///       return const Center(child: CircularProgressIndicator());
///     }
/// 
///     return ListView.builder(
///       itemCount: _abilities.length,
///       itemBuilder: (context, index) {
///         final ability = _abilities[index];
///         final abilityData = AbilityData.fromSimplified(ability);
///         
///         return Card(
///           child: ExpansionTile(
///             title: Text(ability.name),
///             subtitle: Text('Level ${ability.level} • ${ability.actionType ?? 'No action'}'),
///             children: [
///               Padding(
///                 padding: const EdgeInsets.all(16.0),
///                 child: Column(
///                   crossAxisAlignment: CrossAxisAlignment.start,
///                   children: [
///                     if (ability.storyText != null && ability.storyText!.isNotEmpty)
///                       Padding(
///                         padding: const EdgeInsets.only(bottom: 8.0),
///                         child: Text(
///                           ability.storyText!,
///                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
///                                 fontStyle: FontStyle.italic,
///                               ),
///                         ),
///                       ),
///                     if (abilityData.hasPowerRoll)
///                       ...abilityData.tiers.map((tier) => Padding(
///                             padding: const EdgeInsets.symmetric(vertical: 4.0),
///                             child: Row(
///                               crossAxisAlignment: CrossAxisAlignment.start,
///                               children: [
///                                 SizedBox(
///                                   width: 60,
///                                   child: Text(
///                                     tier.label,
///                                     style: Theme.of(context).textTheme.labelSmall,
///                                   ),
///                                 ),
///                                 Expanded(child: Text(tier.primaryText)),
///                               ],
///                             ),
///                           )),
///                     if (ability.effect != null && ability.effect!.isNotEmpty)
///                       Padding(
///                         padding: const EdgeInsets.only(top: 8.0),
///                         child: Text(ability.effect!),
///                       ),
///                   ],
///                 ),
///               ),
///             ],
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```

class SimplifiedAbilitiesUsageGuide {
  // This class is just a placeholder for documentation
  // See the comments above for usage examples
}
