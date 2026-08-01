import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll behavior that allows mouse-drag scrolling in addition to the
/// default touch/stylus/trackpad devices.
///
/// Flutter's default [MaterialScrollBehavior] does not treat mouse drags as
/// a scroll gesture (desktop/web users are expected to use a scrollbar or
/// wheel), which makes horizontally-scrolling filter-chip rows feel broken
/// when clicked and dragged with a mouse. Wrap a scrollable with
/// `ScrollConfiguration(behavior: const DragScrollBehavior(), child: ...)`
/// to opt it into mouse-drag scrolling.
class DragScrollBehavior extends MaterialScrollBehavior {
  const DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}
