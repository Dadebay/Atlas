import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/themes/colors.dart';

/// Drives the "fly to cart" animation: when a product is added to the cart,
/// a small thumbnail flies from the tapped button toward the cart icon on
/// the bottom nav bar. [cartIconKey] must be attached to that icon so its
/// screen position can be resolved via [RenderBox.localToGlobal].
class CartFlyAnimation {
  CartFlyAnimation._();

  static final GlobalKey cartIconKey = GlobalKey();

  static void run({
    required BuildContext context,
    required Offset startCenter,
    String? imageUrl,
  }) {
    // Reduced motion: no flying thumbnail at all. The cart badge updates
    // instantly anyway, which is the part that carries the information.
    if (AppMotion.reduceMotion(context)) return;

    final cartCtx = cartIconKey.currentContext;
    if (cartCtx == null) return;
    final box = cartCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final endCenter = box.localToGlobal(box.size.center(Offset.zero));
    final overlayState = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    var removed = false;
    // Three fast taps put three entries in the overlay at once; each one has to
    // remove itself exactly once, whether it finished or was disposed early.
    void removeOnce() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _FlyingItem(
        start: startCenter,
        end: endCenter,
        onCompleted: removeOnce,
        child: _FlyingThumb(imageUrl: imageUrl),
      ),
    );
    overlayState.insert(entry);
  }
}

class _FlyingThumb extends StatelessWidget {
  final String? imageUrl;
  const _FlyingThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final isAsset = hasImage && imageUrl!.startsWith('assets');

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.green, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
        ],
        image: !hasImage
            ? null
            : DecorationImage(
                image: isAsset
                    ? AssetImage(imageUrl!) as ImageProvider
                    : CachedNetworkImageProvider(imageUrl!),
                fit: BoxFit.cover,
              ),
      ),
      child: hasImage
          ? null
          : const Icon(Icons.shopping_cart_rounded,
              color: AppColors.green, size: 18),
    );
  }
}

class _FlyingItem extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Widget child;
  final VoidCallback onCompleted;

  const _FlyingItem({
    required this.start,
    required this.end,
    required this.child,
    required this.onCompleted,
  });

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem>
    with SingleTickerProviderStateMixin {
  static const Duration _flightDuration = Duration(milliseconds: 400);

  late final AnimationController _controller;
  late final Animation<double> _curve;
  late final double _arcHeight;

  @override
  void initState() {
    super.initState();
    // 650 ms of easeInCubic meant the thumbnail crawled away from the finger
    // before it ever got going. 400 ms of easeInOut leaves immediately and
    // still lands softly.
    _controller = AnimationController(vsync: this, duration: _flightDuration);
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.easeInOut);

    // A fixed 130 px bulge looked absurd on a short hop from a card near the
    // bottom of the screen; scale the arc to the distance actually travelled.
    final distance = (widget.end - widget.start).distance;
    _arcHeight = math.min(distance * 0.22, 96.0);

    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    // Removing the entry is what disposes this state, so the removal is driven
    // by the completion callback only — calling it from here as well would try
    // to remove an entry that is already on its way out.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The entry is positioned once, at the start point. Every frame after that
    // only writes a transform, so the overlay never re-lays-out mid-flight.
    return Positioned(
      left: widget.start.dx - 21,
      top: widget.start.dy - 21,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final t = _curve.value;
          final dx = (widget.end.dx - widget.start.dx) * t;
          final baseDy = (widget.end.dy - widget.start.dy) * t;
          // Upward arc — bulges up mid-flight instead of a straight line.
          final dy = baseDy - _arcHeight * 4 * t * (1 - t);
          final scale = ui.lerpDouble(1.0, 0.35, t)!;
          // Stays solid until it is nearly home, then fades into the badge.
          final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
