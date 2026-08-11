// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  late final FavoritesController _ctrl;

  // Per-card animation controllers keyed by product id
  final Map<String, AnimationController> _anims = {};

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<FavoritesController>();
  }

  @override
  void dispose() {
    for (final c in _anims.values) {
      c.dispose();
    }
    super.dispose();
  }

  AnimationController _animFor(String id) {
    return _anims.putIfAbsent(
      id,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
      ),
    );
  }

  Future<void> _unlike(Map<String, dynamic> product) async {
    final id = product['id']?.toString() ?? '';
    final anim = _animFor(id);
    if (anim.isAnimating) return;
    // Play exit animation to completion, then remove
    await anim.forward();
    _ctrl.removeFromFavorites(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'favorites'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Obx(() {
        // First load — shimmer
        if (_ctrl.isLoading.value && _ctrl.likedProducts.isEmpty) {
          return const SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: ProductCardShimmerGrid(),
          );
        }

        // Empty state
        if (_ctrl.likedProducts.isEmpty) {
          return RefreshIndicator(
            onRefresh: _ctrl.fetchLikedProducts,
            color: AppColors.green,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 160,
                child: _buildEmptyState(),
              ),
            ),
          );
        }

        // Grid with cards
        return RefreshIndicator(
          onRefresh: _ctrl.fetchLikedProducts,
          color: AppColors.green,
          backgroundColor: Colors.white,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 258,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _ctrl.likedProducts.length,
            itemBuilder: (context, index) {
              final product = _ctrl.likedProducts[index];
              final id = product['id']?.toString() ?? '';
              final anim = _animFor(id);

              return AnimatedBuilder(
                animation: anim,
                builder: (_, child) {
                  final t = Curves.easeIn.transform(anim.value);
                  return Transform.scale(
                    scale: 1.0 - (t * 0.22),
                    child: Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: ProductCard(
                  id: product['id'],
                  title: product['title'] as String,
                  imageUrl: product['imageUrl'] as String,
                  price: (product['price'] as num).toDouble(),
                  oldPrice: (product['oldPrice'] as num?)?.toDouble(),
                  discount: product['discount'] as String?,
                  rating: (product['rating'] ?? 0.0) as double,
                  onTap: () => Get.to(
                    () => ProductDetailScreen(id: product['id']),
                    binding: ProductDetailBinding(),
                  ),
                  onFavoriteToggle: () => _unlike(product),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Lottie.asset(
              'assets/images/like.json',
              repeat: true,
              animate: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'favorites_empty'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'favorites_empty_desc'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
