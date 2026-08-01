import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/models/companion_instance.dart';
import '../../core/models/heroic_resource_progression.dart';
import '../../core/services/heroic_resource_progression_service.dart';
import '../../core/theme/app_icon.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/form_theme.dart';
import '../heroic resource stacking tables/heroic_resource_gauge.dart';
import 'companion_template_card.dart' show companionAccent;

/// Tracks a companion's Rampage — a companion resource that builds as ferocity
/// is spent and is lost at the end of an encounter. Unlike the class heroic
/// resource, it is **not** auto-generated: it's adjusted manually here.
///
/// Reuses [HeroicResourceGauge] (the same table widget Fury's Growing Ferocity
/// uses) for the tier display, tinted with the companion's earthy-brown accent,
/// and adds a manual +/-/reset stepper. The rampage value lives on the
/// companion instance (see [CompanionInstance.currentRampage]).
class CompanionRampageWidget extends ConsumerStatefulWidget {
  const CompanionRampageWidget({
    super.key,
    required this.instance,
    required this.heroLevel,
  });

  final CompanionInstance instance;
  final int heroLevel;

  @override
  ConsumerState<CompanionRampageWidget> createState() =>
      _CompanionRampageWidgetState();
}

class _CompanionRampageWidgetState
    extends ConsumerState<CompanionRampageWidget> {
  late final Future<HeroicResourceProgression?> _progressionFuture;

  @override
  void initState() {
    super.initState();
    _progressionFuture =
        HeroicResourceProgressionService().getRampageProgression();
  }

  void _setRampage(int value) {
    ref
        .read(companionRepositoryProvider)
        .updateRampage(widget.instance.id, value);
  }

  @override
  Widget build(BuildContext context) {
    final rampage = widget.instance.currentRampage;

    return FutureBuilder<HeroicResourceProgression?>(
      future: _progressionFuture,
      builder: (context, snapshot) {
        final progression = snapshot.data;
        if (progression == null) {
          // Still loading, or the asset is missing — render nothing rather
          // than a spinner, so the companion card stays clean.
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControls(rampage, progression.maxResourceValue),
            const SizedBox(height: 6),
            HeroicResourceGauge(
              progression: progression,
              currentResource: rampage,
              heroLevel: widget.heroLevel,
              showCompact: true,
              accentColorOverride: companionAccent,
              showHeader: false,
              showContainer: false,
              collapseTierDetails: true,
              expandTierDetailsLabel: 'Expand rampage',
              hideTierDetailsLabel: 'Hide rampage',
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(int rampage, int maxValue) {
    final rampaging = rampage >= 8;
    return Row(
      children: [
        const AppIcon(GreenFormIcons.widget, color: companionAccent, size: 16),
        const SizedBox(width: 6),
        Text(
          'Rampage',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: companionAccent,
          ),
        ),
        const SizedBox(width: 8),
        if (rampaging)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: companionAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: companionAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              'RAMPAGING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: companionAccent,
              ),
            ),
          ),
        const Spacer(),
        _stepButton(
          icon: Icons.remove_circle_outline,
          onPressed: rampage > 0 ? () => _setRampage(rampage - 1) : null,
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$rampage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: rampaging ? companionAccent : FormTheme.textSecondary,
            ),
          ),
        ),
        _stepButton(
          icon: Icons.add_circle_outline,
          onPressed:
              rampage < maxValue ? () => _setRampage(rampage + 1) : null,
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: rampage > 0 ? () => _setRampage(0) : null,
          style: TextButton.styleFrom(
            foregroundColor: companionAccent,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Reset', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _stepButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: companionAccent,
      disabledColor: FormTheme.textMuted,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
