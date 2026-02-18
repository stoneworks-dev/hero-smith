import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_icon_data.dart';

/// A drop-in replacement for [Icon] that renders either a Material icon or an
/// SVG asset, depending on the [AppIconData] variant.
///
/// Respects [IconTheme] for default size and color, just like [Icon].
///
/// ```dart
/// AppIcon(AppIcons.classes.censor, size: 24, color: Colors.white)
/// ```
class AppIcon extends StatelessWidget {
  /// The icon data — either [MaterialIcon] or [SvgAppIcon].
  final AppIconData icon;

  /// Override the default icon size (from [IconTheme] or 24).
  final double? size;

  /// Override the default icon color (from [IconTheme]).
  final Color? color;

  const AppIcon(this.icon, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final iconSize = size ?? theme.size ?? 24.0;
    final iconColor = color ?? theme.color;

    return switch (icon) {
      MaterialIcon(:final iconData) => Icon(
          iconData,
          size: iconSize,
          color: iconColor,
        ),
      SvgAppIcon(:final assetPath) => _SvgIcon(
          assetPath: assetPath,
          size: iconSize,
          color: iconColor,
        ),
    };
  }
}

/// Internal widget that loads an SVG from the asset bundle with full async
/// error handling, preventing unhandled `Future` errors from crashing the app.
class _SvgIcon extends StatefulWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const _SvgIcon({
    required this.assetPath,
    required this.size,
    this.color,
  });

  @override
  State<_SvgIcon> createState() => _SvgIconState();
}

class _SvgIconState extends State<_SvgIcon> {
  String? _svgData;
  bool _hasError = false;

  /// Cache of already-loaded SVG strings, keyed by asset path.
  static final Map<String, String> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(_SvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _svgData = null;
      _hasError = false;
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    // Serve from cache immediately (synchronous path — no frame delay).
    final cached = _cache[widget.assetPath];
    if (cached != null) {
      if (mounted) setState(() => _svgData = cached);
      return;
    }

    try {
      final data =
          await DefaultAssetBundle.of(context).loadString(widget.assetPath);
      _cache[widget.assetPath] = data;
      if (mounted) setState(() => _svgData = data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠ AppIcon SVG load failed: ${widget.assetPath} — $e');
      }
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Icon(Icons.broken_image_outlined,
          size: widget.size, color: widget.color);
    }

    final data = _svgData;
    if (data == null) {
      // Still loading — reserve space to avoid layout jumps.
      return SizedBox(width: widget.size, height: widget.size);
    }

    return SvgPicture.string(
      data,
      width: widget.size,
      height: widget.size,
      colorFilter: widget.color != null
          ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
          : null,
    );
  }
}
