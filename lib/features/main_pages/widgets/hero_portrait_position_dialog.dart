import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/services/hero_portrait_service.dart';
import '../../../core/text/main_pages/heroes_page_text.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';

/// Modal that lets the user drag a portrait to set its focal point.
///
/// Renders the image in the same aspect ratio the card band uses (so the crop
/// previewed here matches the card), and pops the chosen [Alignment] — or
/// `null` if cancelled.
class HeroPortraitPositionDialog extends StatefulWidget {
  const HeroPortraitPositionDialog({
    super.key,
    required this.image,
    required this.initialAlignment,
    required this.accent,
  });

  final File image;
  final Alignment initialAlignment;
  final Color accent;

  /// Shows the dialog and returns the chosen alignment, or `null` if cancelled.
  static Future<Alignment?> show(
    BuildContext context, {
    required File image,
    required Alignment initialAlignment,
    required Color accent,
  }) {
    return showDialog<Alignment>(
      context: context,
      builder: (_) => HeroPortraitPositionDialog(
        image: image,
        initialAlignment: initialAlignment,
        accent: accent,
      ),
    );
  }

  @override
  State<HeroPortraitPositionDialog> createState() =>
      _HeroPortraitPositionDialogState();
}

class _HeroPortraitPositionDialogState
    extends State<HeroPortraitPositionDialog> {
  late Alignment _alignment = widget.initialAlignment;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    final stream = Image.file(widget.image).image.resolve(
          const ImageConfiguration(),
        );
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
      stream.removeListener(listener);
    }, onError: (_, __) {
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  final GlobalKey _bandKey = GlobalKey();

  void _onPanUpdate(DragUpdateDetails details) {
    final imageSize = _imageSize;
    if (imageSize == null) return;

    // Read the band's laid-out size at drag time (instead of a LayoutBuilder,
    // which breaks AlertDialog's intrinsic-width measurement).
    final box = _bandKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final bandSize = box.size;

    // Displayed image size under BoxFit.cover, and the resulting overflow (the
    // hidden pixels we can pan across) on each axis.
    final scale = (bandSize.width / imageSize.width)
        .clamp(bandSize.height / imageSize.height, double.infinity);
    final overflowX = imageSize.width * scale - bandSize.width;
    final overflowY = imageSize.height * scale - bandSize.height;

    setState(() {
      var x = _alignment.x;
      var y = _alignment.y;
      // 2 alignment units span the full overflow, so pixels -> alignment is
      // (2 / overflow). Dragging the image one way reveals the opposite edge.
      if (overflowX > 0) {
        x = (x - 2 * details.delta.dx / overflowX).clamp(-1.0, 1.0);
      }
      if (overflowY > 0) {
        y = (y - 2 * details.delta.dy / overflowY).clamp(-1.0, 1.0);
      }
      _alignment = Alignment(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      title: Text(
        HeroesPageText.positionPhotoTitle,
        style: TextStyle(color: Colors.grey.shade100),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                key: _bandKey,
                aspectRatio: HeroPortraitService.bandAspectRatio,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        widget.image,
                        fit: BoxFit.cover,
                        alignment: _alignment,
                        gaplessPlayback: true,
                      ),
                      // Subtle framing so the drag target reads as adjustable.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.open_with, size: 16, color: FormTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    HeroesPageText.positionPhotoHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: FormTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(HeroesPageText.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_alignment),
          style: FilledButton.styleFrom(backgroundColor: widget.accent),
          child: Text(HeroesPageText.save),
        ),
      ],
    );
  }
}
