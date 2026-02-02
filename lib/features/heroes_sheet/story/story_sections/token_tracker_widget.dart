import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hero_smith/core/text/heroes_sheet/story/sheet_story_token_tracker_text.dart';
import 'package:hero_smith/core/theme/story_theme.dart';

import '../../../../core/services/complication_grants_service.dart';

part '../../../../widgets/heroes_sheet/story/story_sections/token_tracker/_token_row.dart';

/// Widget for tracking complication tokens (e.g., antihero tokens).
/// Shows current/max values with +/- buttons.
class TokenTrackerWidget extends ConsumerStatefulWidget {
  const TokenTrackerWidget({
    super.key,
    required this.heroId,
  });

  final String heroId;

  @override
  ConsumerState<TokenTrackerWidget> createState() => _TokenTrackerWidgetState();
}

class _TokenTrackerWidgetState extends ConsumerState<TokenTrackerWidget> {
  Map<String, int> _maxTokens = {};
  Map<String, int> _currentTokens = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    try {
      final service = ref.read(complicationGrantsServiceProvider);
      final max = await service.loadTokenGrants(widget.heroId);
      final current = await service.loadCurrentTokenValues(widget.heroId);

      if (mounted) {
        setState(() {
          _maxTokens = max;
          _currentTokens = current;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateToken(String tokenType, int delta) async {
    final current = _currentTokens[tokenType] ?? 0;
    final max = _maxTokens[tokenType] ?? 0;
    final newValue = (current + delta).clamp(0, max);

    if (newValue != current) {
      setState(() {
        _currentTokens[tokenType] = newValue;
      });

      final service = ref.read(complicationGrantsServiceProvider);
      await service.updateTokenValue(widget.heroId, tokenType, newValue);
    }
  }

  Future<void> _resetTokens() async {
    final service = ref.read(complicationGrantsServiceProvider);
    await service.resetTokensToMax(widget.heroId);
    await _loadTokens();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: StoryTheme.storyAccent)),
      );
    }

    if (_maxTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    const storyColor = StoryTheme.storyAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.token_outlined, size: 18, color: storyColor),
            const SizedBox(width: 8),
            Text(
              SheetStoryTokenTrackerText.sectionTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade300,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resetTokens,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(SheetStoryTokenTrackerText.resetLabel),
              style: TextButton.styleFrom(
                foregroundColor: storyColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._maxTokens.entries.map((entry) {
          final tokenType = entry.key;
          final max = entry.value;
          final current = _currentTokens[tokenType] ?? 0;
          final displayName = _formatTokenName(tokenType);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TokenRow(
              name: displayName,
              current: current,
              max: max,
              onDecrement: () => _updateToken(tokenType, -1),
              onIncrement: () => _updateToken(tokenType, 1),
            ),
          );
        }),
      ],
    );
  }

  String _formatTokenName(String tokenType) {
    return tokenType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
