import 'package:flutter/material.dart';

import 'package:atlas/core/theme/app_motion.dart';

/// The number inside a cart stepper.
///
/// The old value leaves upward and the new one arrives from below, so holding
/// down "+" reads as counting rather than flickering. The switcher retargets
/// mid-flight, so fast taps stay legible instead of queueing up.
///
/// Under reduced motion it degrades to a plain crossfade — the value change is
/// information, so it is never dropped entirely.
class AnimatedQuantityText extends StatelessWidget {
  const AnimatedQuantityText({
    super.key,
    required this.quantity,
    required this.style,
  });

  final int quantity;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, anim) {
        final fade = FadeTransition(opacity: anim, child: child);
        if (reduce) return fade;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(anim),
          child: fade,
        );
      },
      child: Text('$quantity', key: ValueKey(quantity), style: style),
    );
  }
}
