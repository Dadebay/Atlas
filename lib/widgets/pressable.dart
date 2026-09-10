import 'package:flutter/material.dart';

import 'package:atlas/core/theme/app_motion.dart';

/// Press feedback for a control that cannot show a ripple — a coloured button
/// or an icon on its own surface.
///
/// It is deliberately the *only* feedback such a control gets: a ripple plus a
/// scale plus a haptic on the same tap reads as noise. Scale bottoms out at
/// [AppMotion.pressedScale], and the whole thing collapses to a plain tap
/// target when the platform asks for reduced motion.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.behavior = HitTestBehavior.opaque,
    this.scale = AppMotion.pressedScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduce = AppMotion.reduceMotion(context);

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: enabled && !reduce ? (_) => _setPressed(true) : null,
      onTapUp: enabled && !reduce ? (_) => _setPressed(false) : null,
      onTapCancel: enabled && !reduce ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppMotion.duration(context, AppMotion.instant),
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
