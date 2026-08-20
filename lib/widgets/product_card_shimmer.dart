import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── Category screen shimmer ──────────────────────────────────────────────────

class CategoryShimmer extends StatefulWidget {
  const CategoryShimmer({super.key});

  @override
  State<CategoryShimmer> createState() => _CategoryShimmerState();
}

class _CategoryShimmerState extends State<CategoryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final g = _buildGradient(_ctrl.value);
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Search bar
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (b) => g.createShader(b),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Two sections
              for (int s = 0; s < 2; s++) ...[
                _buildSectionShimmer(g),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionShimmer(LinearGradient g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (b) => g.createShader(b),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 140,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 64,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 6 category cards in 3-column grid
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
          itemBuilder: (_, __) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (b) => g.createShader(b),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// grey[100] = 0xFFF5F5F5  — card background
// grey[200] = 0xFFEEEEEE  — image area, cart button, skeleton boxes
// grey[300] = 0xFFE0E0E0  — gradient edge (darker part of shimmer)

LinearGradient _buildGradient(double t) => LinearGradient(
      colors: const [
        Color(0xFFE0E0E0), // grey[300]
        Color(0xFFF5F5F5), // grey[100] — highlight
        Color(0xFFE0E0E0), // grey[300]
      ],
      stops: const [0.1, 0.45, 0.8],
      begin: Alignment(-2.0 + t * 4, 0),
      end: Alignment(0.0 + t * 4, 0),
      tileMode: TileMode.clamp,
    );

Widget _box({double? width, required double height, double radius = 6}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE), // grey[200]
        borderRadius: BorderRadius.circular(radius),
      ),
    );

/// Pixel-perfect skeleton of [ProductCard].
/// Mirrors: image 140 px, favourite circle, title 25 px,
/// category row, price, cart button 30 px.
class _ShimmerCard extends StatelessWidget {
  final LinearGradient gradient;
  final double? fixedWidth;

  const _ShimmerCard({required this.gradient, this.fixedWidth});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Container(
        width: fixedWidth,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
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
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
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
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Horizontal list shimmer (home screen) ───────────────────────────────────

class ProductCardShimmerList extends StatefulWidget {
  final int? count;
  const ProductCardShimmerList({super.key, this.count});

  @override
  State<ProductCardShimmerList> createState() => _ProductCardShimmerListState();
}

class _ProductCardShimmerListState extends State<ProductCardShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Matches home_screen card width: (screenWidth - 24) / 2.3
  double get _cardWidth => (Get.width - 24.0) / 2.3;

  int get _effectiveCount {
    if (widget.count != null) return widget.count!;
    final available = Get.width - 16.0;
    return (available / (_cardWidth + 8.0)).ceil() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final g = _buildGradient(_ctrl.value);
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _effectiveCount,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) =>
              _ShimmerCard(gradient: g, fixedWidth: _cardWidth),
        );
      },
    );
  }
}

// ─── Grid shimmer (category / favorites / home screen) ────────────────────────

class ProductCardShimmerGrid extends StatefulWidget {
  final int? count;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry gridPadding;

  const ProductCardShimmerGrid({
    super.key,
    this.count,
    this.mainAxisExtent = 258,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.gridPadding = const EdgeInsets.fromLTRB(16, 0, 16, 20),
  });

  @override
  State<ProductCardShimmerGrid> createState() => _ProductCardShimmerGridState();
}

class _ProductCardShimmerGridState extends State<ProductCardShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _effectiveCount {
    if (widget.count != null) return widget.count!;
    final available = Get.height - 200.0;
    final rows = (available / (widget.mainAxisExtent + widget.mainAxisSpacing)).ceil();
    return (rows * 2).clamp(4, 16);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final g = _buildGradient(_ctrl.value);
        return GridView.builder(
          primary: false,
          padding: widget.gridPadding,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: widget.mainAxisExtent,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
          ),
          itemCount: _effectiveCount,
          itemBuilder: (_, __) => _ShimmerCard(gradient: g),
        );
      },
    );
  }
}
