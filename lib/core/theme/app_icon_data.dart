import 'package:flutter/widgets.dart';

/// Represents an icon that can be either a Material [IconData] or an SVG asset.
///
/// Used throughout [AppIcons] so that domain-specific icons (classes,
/// characteristics, combat stats, etc.) can use game-icons.net SVGs while
/// generic UI chrome icons keep using Material Design icons.
sealed class AppIconData {
  const AppIconData();
}

/// A Material Design icon backed by [IconData].
class MaterialIcon extends AppIconData {
  final IconData iconData;
  const MaterialIcon(this.iconData);
}

/// An SVG asset icon backed by a Flutter asset path string.
class SvgAppIcon extends AppIconData {
  final String assetPath;
  const SvgAppIcon(this.assetPath);
}
