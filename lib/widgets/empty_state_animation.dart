import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/themes/colors.dart';

/// A Lottie illustration for an empty state.
///
/// It owns its controller rather than relying on `Lottie.asset`'s implicit one,
/// for two reasons:
///
/// * The composition loads asynchronously. Driving playback from [onLoaded]
///   means the animation starts when the frames actually exist, instead of
///   depending on a rebuild landing at the right moment.
/// * Every tab lives in an `IndexedStack` under a `TickerMode`, so a screen the
///   customer has not opened yet is built with its ticker muted. An explicit
///   controller makes that behaviour deliberate: the animation waits, then runs
///   from the start when the tab is actually shown.
///
/// It also renders a visible fallback when the asset cannot be loaded. The bare
/// `Lottie.asset` draws nothing at all in that case, which turns a missing or
/// unbundled file into an invisible bug.
class EmptyStateAnimation extends StatefulWidget {
  const EmptyStateAnimation({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.size = 170,
    this.repeat = false,
  });

  final String asset;
  final IconData fallbackIcon;
  final double size;

  /// An empty state has nothing more to say after the first pass, so this
  /// defaults to playing once and resting on the last frame.
  final bool repeat;

  @override
  State<EmptyStateAnimation> createState() => _EmptyStateAnimationState();
}

class _EmptyStateAnimationState extends State<EmptyStateAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (AppMotion.reduceMotion(context)) {
      // Hold the finished illustration instead of moving it.
      _controller.value = 1;
      return;
    }
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        widget.asset,
        controller: _controller,
        onLoaded: _onLoaded,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            widget.fallbackIcon,
            size: widget.size * 0.45,
            color: AppColors.green.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
