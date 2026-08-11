// ignore_for_file: deprecated_member_use

import 'dart:ui' as ui;

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final cartCtx = cartIconKey.currentContext;
    if (cartCtx == null) return;
    final box = cartCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final endCenter = box.localToGlobal(box.size.center(Offset.zero));
    final overlayState = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingItem(
        start: startCenter,
        end: endCenter,
        onCompleted: () => entry.remove(),
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
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
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
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        final dx = ui.lerpDouble(widget.start.dx, widget.end.dx, t)!;
        final baseY = ui.lerpDouble(widget.start.dy, widget.end.dy, t)!;
        // Upward arc — bulges up mid-flight instead of a straight line.
        final arcBulge = 130 * t * (1 - t);
        final dy = baseY - arcBulge;
        final scale = ui.lerpDouble(1.0, 0.25, t)!;
        final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);

        return Positioned(
          left: dx - 21,
          top: dy - 21,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
