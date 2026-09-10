import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:atlas/widgets/shimmer.dart';

// ─── Building blocks ─────────────────────────────────────────────────────────

/// A flat skeleton box. It carries no animation of its own — the sweep comes
/// from the single [Shimmer] wrapped around the whole skeleton.
Widget _box({double? width, required double height, double radius = 6}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Shimmer.base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

/// Pixel-perfect skeleton of `ProductCard`.
/// Mirrors: image 140 px, favourite circle, title 25 px,
/// category row, price, cart button 30 px.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({this.fixedWidth});

  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fixedWidth,
      decoration: BoxDecoration(
        color: Shimmer.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Shimmer.base),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + favourite button ──────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Shimmer.base,
                ),
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Shimmer.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),

                // Title: two lines
                SizedBox(
                  height: 25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(width: double.infinity, height: 11),
                      _box(width: 90, height: 11),
                    ],
                  ),
                ),

                // Category row
                Row(
                  children: [
                    _box(width: 11, height: 11, radius: 3),
                    const SizedBox(width: 3),
                    _box(width: 56, height: 10),
                  ],
                ),

                const SizedBox(height: 3),

                // Price
                _box(width: 64, height: 18),

                const SizedBox(height: 3),

                // Cart button
                Container(
                  width: double.infinity,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Shimmer.base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category screen shimmer ─────────────────────────────────────────────────

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Search bar
            _box(width: double.infinity, height: 50, radius: 12),
            const SizedBox(height: 24),
            for (int s = 0; s < 2; s++) ...[
              const _CategorySectionShimmer(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategorySectionShimmer extends StatelessWidget {
  const _CategorySectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 140, height: 20),
            _box(width: 64, height: 14),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.76,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => _box(height: double.infinity, radius: 12),
        ),
      ],
    );
  }
}

// ─── Brand grid shimmer ──────────────────────────────────────────────────────

class BrandShimmer extends StatelessWidget {
  const BrandShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.83,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => _box(height: double.infinity, radius: 12),
      ),
    );
  }
}

// ─── Horizontal list shimmer (home screen) ───────────────────────────────────

class ProductCardShimmerList extends StatelessWidget {
  const ProductCardShimmerList({super.key, this.count});

  final int? count;

  // Matches home_screen card width: (screenWidth - 24) / 2.3
  double get _cardWidth => (Get.width - 24.0) / 2.3;

  int get _effectiveCount {
    if (count != null) return count!;
    final available = Get.width - 16.0;
    return (available / (_cardWidth + 8.0)).ceil() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _effectiveCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _ShimmerCard(fixedWidth: _cardWidth),
      ),
    );
  }
}

// ─── Grid shimmer (category / favorites) ─────────────────────────────────────

class ProductCardShimmerGrid extends StatelessWidget {
  const ProductCardShimmerGrid({
    super.key,
    this.count,
    this.mainAxisExtent = 258,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.gridPadding = const EdgeInsets.fromLTRB(16, 0, 16, 20),
  });

  final int? count;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry gridPadding;

  int get _effectiveCount =>
      count ?? _fillScreenCount(mainAxisExtent, mainAxisSpacing);

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        primary: false,
        padding: gridPadding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: mainAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: _effectiveCount,
        itemBuilder: (_, __) => const _ShimmerCard(),
      ),
    );
  }
}

// ─── Sliver grid shimmer (home screen) ───────────────────────────────────────

/// The sliver form of [ProductCardShimmerGrid].
///
/// The home page is one `CustomScrollView`, so its loading state has to be a
/// sliver too — a boxed grid there would need `shrinkWrap`, which is exactly
/// the full-height layout pass the sliver conversion removed.
class SliverProductCardShimmerGrid extends StatelessWidget {
  const SliverProductCardShimmerGrid({
    super.key,
    this.count,
    this.mainAxisExtent = 258,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.gridPadding = const EdgeInsets.fromLTRB(16, 0, 16, 20),
  });

  final int? count;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry gridPadding;

  int get _effectiveCount =>
      count ?? _fillScreenCount(mainAxisExtent, mainAxisSpacing);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: gridPadding,
      // A sliver cannot be wrapped in a ShaderMask, so the sweep is applied to
      // each card here. They still share the one ticker from the enclosing
      // ShimmerScope, so they sweep in step rather than independently.
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: mainAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: _effectiveCount,
        itemBuilder: (_, __) => const Shimmer(child: _ShimmerCard()),
      ),
    );
  }
}

/// Roughly how many cards it takes to cover the screen, so the skeleton does
/// not stop halfway down a tall phone.
int _fillScreenCount(double extent, double spacing) {
  final rows = ((Get.height - 200.0) / (extent + spacing)).ceil();
  return (rows * 2).clamp(4, 16);
}
