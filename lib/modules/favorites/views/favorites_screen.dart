import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:atlas/core/theme/app_motion.dart';
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

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesController _ctrl;

  /// Ids currently playing their exit. This replaced a map of per-card
  /// `AnimationController`s that grew with every removal and was only ever
  /// disposed when the whole screen went away — a set of strings costs nothing
  /// and is emptied as each card leaves.
  final Set<String> _removingIds = <String>{};

  static const Duration _exitDuration = AppMotion.fast;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<FavoritesController>();
  }

  Future<void> _unlike(Map<String, dynamic> product) async {
    final id = product['id']?.toString() ?? '';
    if (id.isEmpty || _removingIds.contains(id)) return;

    if (AppMotion.reduceMotion(context)) {
      _ctrl.removeFromFavorites(product);
      return;
    }

    setState(() => _removingIds.add(id));
    // The card stays in the model for exactly as long as its exit runs, so the
    // grid does not reflow underneath the animation.
    await Future<void>.delayed(_exitDuration);
    if (!mounted) return;
    setState(() => _removingIds.remove(id));
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
        return AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.standard),
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: _buildBody(context),
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context) {
    // First load — shimmer
    if (_ctrl.isLoading.value && _ctrl.likedProducts.isEmpty) {
      return const SingleChildScrollView(
        key: ValueKey('loading'),
        physics: NeverScrollableScrollPhysics(),
        child: ProductCardShimmerGrid(),
      );
    }

    // Empty state
    if (_ctrl.likedProducts.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
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
      key: const ValueKey('grid'),
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
          final leaving = _removingIds.contains(id);

          // A short settle out, not a 320 ms easeIn shrink that made the
          // tap feel like it had not registered.
          return AnimatedScale(
            scale: leaving ? AppMotion.enterScale : 1,
            duration: _exitDuration,
            curve: AppMotion.easeOut,
            child: AnimatedOpacity(
              opacity: leaving ? 0 : 1,
              duration: _exitDuration,
              curve: AppMotion.easeOut,
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
            ),
          );
        },
      ),
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
            // Plays once and holds its last frame — an empty state has nothing
            // left to say after the first pass, and a hidden tab should not be
            // paying for a loop.
            child: Lottie.asset(
              'assets/images/like.json',
              repeat: false,
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
