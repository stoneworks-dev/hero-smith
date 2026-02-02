part of 'package:hero_smith/features/heroes_sheet/story/story_sections/token_tracker_widget.dart';

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.name,
    required this.current,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String name;
  final int current;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    const storyColor = StoryTheme.storyAccent;
    final canDecrement = current > 0;
    final canIncrement = current < max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StoryTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$current / $max',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDecrement ? onDecrement : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 28,
            color: canDecrement
                ? Colors.red.shade400
                : Colors.grey.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              current.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: current == 0
                    ? Colors.red.shade400
                    : current == max
                        ? storyColor
                        : Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: canIncrement ? onIncrement : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 28,
            color: canIncrement
                ? storyColor
                : Colors.grey.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
