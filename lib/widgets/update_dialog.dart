import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/update_provider.dart';
import '../core/services/update_service.dart';
import '../core/theme/navigation_theme.dart';

/// Shows an update dialog when a new version is available on startup.
///
/// Wrap your main content with this widget. It listens to [updateCheckProvider]
/// and shows a dialog once when a newer version is detected.
class UpdateChecker extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UpdateInfo?>>(updateCheckProvider, (prev, next) {
      final update = next.valueOrNull;
      if (update != null && !_dialogShown) {
        _dialogShown = true;
        // Show after frame to avoid build-phase issues.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showUpdateDialog(context, ref, update);
          }
        });
      }
    });

    return widget.child;
  }
}

/// Standalone function to show the update dialog.
/// Can be called from [UpdateChecker] or from the About page.
void showUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  UpdateInfo update,
) {
  final accent = NavigationTheme.heroesColor;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      title: Row(
        children: [
          Icon(Icons.system_update, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update Available',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${update.version} is available.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              border: Border.all(color: Colors.orange.withAlpha(100)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Back up your heroes before updating! You can export them from the Heroes page.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade200,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (update.releaseNotes != null &&
              update.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "What's new:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  update.releaseNotes!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DontShowAgainCheckbox(ref: ref),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Later',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
        if (update.downloadUrl != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(updateServiceProvider)
                  .downloadUpdate(update.downloadUrl!);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
            ),
          )
        else
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(updateServiceProvider)
                  .openReleasesPage(htmlUrl: update.htmlUrl);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View Release'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
            ),
          ),
      ],
    ),
  );
}

/// Checkbox that lets the user suppress future update prompts.
class _DontShowAgainCheckbox extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _DontShowAgainCheckbox({required this.ref});

  @override
  ConsumerState<_DontShowAgainCheckbox> createState() =>
      _DontShowAgainCheckboxState();
}

class _DontShowAgainCheckboxState
    extends ConsumerState<_DontShowAgainCheckbox> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _dontShowAgain = !_dontShowAgain;
        });
        // Invert: "don't show" = setShowPrompts(false)
        ref
            .read(updatePreferencesProvider.notifier)
            .setShowPrompts(!_dontShowAgain);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _dontShowAgain,
              onChanged: (v) {
                setState(() {
                  _dontShowAgain = v ?? false;
                });
                ref
                    .read(updatePreferencesProvider.notifier)
                    .setShowPrompts(!_dontShowAgain);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Don't remind me again",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
