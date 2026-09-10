import 'package:flutter/material.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:get/get.dart';

/// Owns the one ticker that every skeleton under it shares.
///
/// Put a scope around a screen and each skeleton inside it — the horizontal
/// rails, the grid, the section headers — sweeps from one animation value,
/// instead of each running its own 1100 ms controller out of phase.
///
/// The ticker only runs while at least one [Shimmer] is actually mounted
/// beneath it, so a scope wrapped around a whole screen costs nothing once the
/// content has loaded. `TickerMode` mutes it as well when the owning tab is off
/// screen, which is what stops hidden skeletons from driving frames.
///
/// A [Shimmer] with no scope above it quietly creates one for itself, so a
/// screen that forgets the scope still renders correctly.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({super.key, required this.child});

  final Widget child;

  static _ShimmerScopeState? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerTick>()?.state;

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  int _listeners = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void register() {
    _listeners++;
    if (_listeners == 1 && !controller.isAnimating) controller.repeat();
  }

  void unregister() {
    _listeners--;
    if (_listeners <= 0) {
      _listeners = 0;
      controller.stop();
      controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerTick(state: this, child: widget.child);
}

class _ShimmerTick extends InheritedWidget {
  const _ShimmerTick({required this.state, required super.child});

  final _ShimmerScopeState state;

  @override
  bool updateShouldNotify(_ShimmerTick oldWidget) => state != oldWidget.state;
}

/// Sweeps a highlight across everything inside it.
///
/// Wrap the whole skeleton once rather than each box: one `ShaderMask` over a
/// grid costs a single saveLayer per frame where a mask per card costs one
/// each, and a sweep crossing the screen as a whole reads better anyway.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  /// The flat colour the skeleton boxes are painted in.
  static const Color base = Color(0xFFEEEEEE);

  /// Card background behind those boxes.
  static const Color surface = Color(0xFFF5F5F5);

  static LinearGradient _gradient(double t) => LinearGradient(
        colors: const [
          Color(0xFFE0E0E0),
          Color(0xFFF5F5F5), // highlight
          Color(0xFFE0E0E0),
        ],
        stops: const [0.1, 0.45, 0.8],
        begin: Alignment(-2.0 + t * 4, 0),
        end: Alignment(0.0 + t * 4, 0),
        tileMode: TileMode.clamp,
      );

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> {
  _ShimmerScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) return;
    final scope = ShimmerScope._maybeOf(context);
    if (scope == _scope) return;
    _scope?.unregister();
    _scope = scope?..register();
  }

  @override
  void dispose() {
    _scope?.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion: a still grey skeleton says "loading" just as well.
    if (AppMotion.reduceMotion(context)) return _semantic(widget.child);

    final scope = _scope;
    // No scope above us — make our own, and let the rebuilt child find it.
    if (scope == null) return ShimmerScope(child: widget);

    return _semantic(AnimatedBuilder(
      animation: scope.controller,
      // The skeleton itself never changes, so it is built once and handed to
      // the builder — only the shader is recomputed per frame.
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) =>
            Shimmer._gradient(scope.controller.value).createShader(bounds),
        child: child,
      ),
    ));
  }

  /// The skeleton's boxes carry no information, so they are hidden from
  /// assistive tech and replaced by a single spoken "loading".
  Widget _semantic(Widget child) => Semantics(
        label: 'loading'.tr,
        container: true,
        child: ExcludeSemantics(child: child),
      );
}
