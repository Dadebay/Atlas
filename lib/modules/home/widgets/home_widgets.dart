import 'dart:async';
import 'dart:convert';

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/modules/home/controllers/home_controller.dart';
import 'package:atlas/modules/category/models/category_model.dart';
import 'package:atlas/modules/category/views/sub_category_product_screen.dart';
import 'package:atlas/modules/home/views/hero_slide_detail_screen.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  // Infinite-loop trick: PageView holds a huge (but finite) virtual item
  // count, and each virtual index maps back to a real slide via `% count`.
  // Auto-scroll always moves forward (`_virtualPage++`), so 4→1 continues
  // as a plain forward slide instead of animating backward through 3,2,1.
  static const int _virtualMultiplier = 5000;

  final PageController _pageController = PageController();
  int _virtualPage = 0;
  bool _initialized = false;
  Timer? _autoTimer;
  HomeController get _ctrl => Get.find<HomeController>();

  void _initLoopIfNeeded(int count) {
    if (_initialized || count < 1) return;
    _initialized = true;
    // An exact multiple of `count`, so it maps to real slide 0 — the same
    // slide already showing — meaning the jump below is visually a no-op.
    _virtualPage = count * (_virtualMultiplier ~/ 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_virtualPage);
      }
    });
    if (count >= 2) _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _virtualPage++;
      _pageController.animateToPage(
        _virtualPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _bannerPlaceholder() => Container(
        color: const Color(0xFFF2F4F3),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Color(0xFFB0B0B0),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slides = _ctrl.heroSlides;
      final isLoading = _ctrl.isLoadingBanner.value;

      if (isLoading && slides.isEmpty) {
        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.green,
              strokeWidth: 2.5,
            ),
          ),
        );
      }

      if (slides.isEmpty) {
        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _bannerPlaceholder(),
          ),
        );
      }

      _initLoopIfNeeded(slides.length);

      return Column(
        children: [
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => _virtualPage = index,
              itemCount: slides.length * (_virtualMultiplier + 1),
              itemBuilder: (context, index) {
                final realIndex = index % slides.length;
                final slide = slides[realIndex];
                final imageUrl = slide['imageUrl'] as String;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    print('======== BANNER TAP [$realIndex] ========');
                    final raw = slide['_raw'] as Map<String, dynamic>?;
                    if (raw != null) {
                      print('[Banner] API RAW JSON:');
                      print(const JsonEncoder.withIndent('  ').convert(raw));
                    }
                    print('=====================================');

                    final productId = slide['productId'] as String?;
                    final categoryRaw =
                        slide['category'] as Map<String, dynamic>?;

                    if (productId != null && productId.isNotEmpty) {
                      Get.to(
                        () => ProductDetailScreen(id: productId),
                        binding: ProductDetailBinding(),
                      );
                    } else if (categoryRaw != null) {
                      final category = CategoryModel.fromJson(categoryRaw);
                      Get.to(
                          () => SubCategoryProductScreen(category: category));
                    } else {
                      Get.to(() => HeroSlideDetailScreen(
                            slideId: slide['id'] as int,
                            previewUrl: imageUrl,
                          ));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl.isEmpty
                          ? _bannerPlaceholder()
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: (MediaQuery.of(context).size.width *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .round(),
                              memCacheHeight:
                                  (180 * MediaQuery.of(context).devicePixelRatio).round(),
                              placeholder: (_, __) => Container(
                                color: const Color(0xFFF2F4F3),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.green,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _bannerPlaceholder(),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class QuickCategory extends StatelessWidget {
  final String title;
  final Color color;
  final String imageUrl;

  const QuickCategory({
    super.key,
    required this.title,
    required this.color,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
                height: 1.1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Image.network(
              imageUrl,
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
