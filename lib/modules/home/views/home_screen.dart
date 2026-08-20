// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/home/controllers/home_controller.dart';
import 'package:atlas/modules/home/widgets/home_widgets.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';
import 'package:atlas/modules/search/views/search_screen.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/core/services/catalog_service.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';
import 'package:atlas/modules/category/controllers/category_controller.dart';
import 'package:atlas/modules/category/models/category_model.dart';
import 'package:atlas/modules/category/views/sub_category_product_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<CartController>();
    Get.find<MainController>();
    final categoryCtrl = Get.find<CategoryController>();
    final brandsController = Get.isRegistered<BrandsController>() ? Get.find<BrandsController>() : Get.put(BrandsController());
    // 2.3 kart görünür: 2 tam + 3. kartın peek'i
    final cardWidth = (MediaQuery.of(context).size.width - 24) / 2.15;

    final cartCtrl = Get.find<CartController>();
    void addToCart(String title, String imageUrl, double price, String? id) {
      cartCtrl.addItem({
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 55,
        centerTitle: false,
        titleSpacing: 15,
        title: Image.asset(
          'assets/images/logo.png',
          height: 50,
          errorBuilder: (_, __, ___) => const Text(
            'Atlas',
            style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
          ),
        ),
        actions: const [PremiumSearchButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            controller.refreshData(),
            brandsController.fetchBrands(),
            categoryCtrl.fetchCategories(),
          ]);
        },
        color: AppColors.green,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        displacement: 60,
        child: SingleChildScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Banner ────────────────────────────────────────────────
              const BannerCarousel(),

              // ─── Categories grid ───────────────────────────────────────
              const SizedBox(height: 14),

              _buildCategoriesSection(categoryCtrl),
              const SizedBox(height: 8),

              Obx(() {
                if (controller.isLoadingDiscount.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'discounts'.tr,
                        () => Get.to(() => SubCategoryProductScreen(overrideTitle: 'discounts'.tr, isDiscount: true)),
                      ),
                      const SizedBox(height: 7),
                      const SizedBox(height: 258, child: ProductCardShimmerList()),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                if (controller.discountProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                final discountCatNames = controller.discountProducts.map((p) => (p['categoryName'] as String?)?.isNotEmpty == true ? p['categoryName'] as String : CatalogService.to.categoryName(p['categoryId'] as int?)).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'discounts'.tr,
                      () => Get.to(() => SubCategoryProductScreen(overrideTitle: 'discounts'.tr, isDiscount: true)),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 258,
                      child: ListView.builder(
                        primary: false,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: controller.discountProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.discountProducts[index];
                          final price = (product['price'] as num).toDouble();
                          final isLast = index == controller.discountProducts.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 12),
                            child: ProductCard(
                              id: product['id'],
                              width: cardWidth,
                              title: product['title'] as String,
                              imageUrl: product['imageUrl'] as String,
                              price: price,
                              oldPrice: (product['oldPrice'] as num?)?.toDouble(),
                              discount: product['discount'] as String?,
                              brandName: product['brandName'] as String?,
                              categoryName: discountCatNames[index],
                              onTap: () => Get.to(
                                () => ProductDetailScreen(id: product['id'] as String?),
                                binding: ProductDetailBinding(),
                              ),
                              onCartPressed: () => addToCart(
                                product['title'] as String,
                                product['imageUrl'] as String,
                                price,
                                product['id'] as String?,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),

              // ─── New products ──────────────────────────────────────────
              Obx(() {
                if (controller.isLoadingNew.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'new_products'.tr,
                        () => Get.to(() => SubCategoryProductScreen(overrideTitle: 'new_products'.tr, isNew: true)),
                      ),
                      const SizedBox(height: 7),
                      const SizedBox(height: 258, child: ProductCardShimmerList()),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                if (controller.newProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                final newCatNames = controller.newProducts.map((p) => (p['categoryName'] as String?)?.isNotEmpty == true ? p['categoryName'] as String : CatalogService.to.categoryName(p['categoryId'] as int?)).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'new_products'.tr,
                      () => Get.to(() => SubCategoryProductScreen(overrideTitle: 'new_products'.tr, isNew: true)),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 258,
                      child: ListView.builder(
                        primary: false,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: controller.newProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.newProducts[index];
                          final price = (product['price'] as num).toDouble();
                          final isLast = index == controller.newProducts.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 12),
                            child: ProductCard(
                              id: product['id'],
                              width: cardWidth,
                              title: product['title'] as String,
                              imageUrl: product['imageUrl'] as String,
                              price: price,
                              oldPrice: (product['oldPrice'] as num?)?.toDouble(),
                              discount: product['discount'] as String?,
                              brandName: product['brandName'] as String?,
                              categoryName: newCatNames[index],
                              onTap: () => Get.to(
                                () => ProductDetailScreen(id: product['id'] as String?),
                                binding: ProductDetailBinding(),
                              ),
                              onCartPressed: () => addToCart(
                                product['title'] as String,
                                product['imageUrl'] as String,
                                price,
                                product['id'] as String?,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),

              // ─── Remaining / All products grid ─────────────────────────
              _buildSectionHeader('all_products'.tr, null),
              const SizedBox(height: 7),
              Obx(() {
                if (controller.isLoadingAll.value) {
                  return const ProductCardShimmerGrid(
                    mainAxisExtent: 260,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    gridPadding: EdgeInsets.symmetric(horizontal: 8),
                  );
                }
                final shownIds = {
                  ...controller.discountProducts.map((p) => p['id']),
                  ...controller.newProducts.map((p) => p['id']),
                };
                final remaining = controller.allProducts.where((p) => !shownIds.contains(p['id'])).toList();
                if (remaining.isEmpty) return const SizedBox.shrink();
                final catNames = remaining.map((p) => (p['categoryName'] as String?)?.isNotEmpty == true ? p['categoryName'] as String : CatalogService.to.categoryName(p['categoryId'] as int?)).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: remaining.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 260,
                    ),
                    itemBuilder: (context, index) {
                      final product = remaining[index];
                      final price = (product['price'] as num).toDouble();
                      return ProductCard(
                        id: product['id'],
                        title: product['title'] as String,
                        imageUrl: product['imageUrl'] as String,
                        price: price,
                        oldPrice: (product['oldPrice'] as num?)?.toDouble(),
                        discount: product['discount'] as String?,
                        brandName: product['brandName'] as String?,
                        categoryName: catNames[index],
                        onTap: () => Get.to(
                          () => ProductDetailScreen(id: product['id'] as String?),
                          binding: ProductDetailBinding(),
                        ),
                        onCartPressed: () => addToCart(
                          product['title'] as String,
                          product['imageUrl'] as String,
                          price,
                          product['id'] as String?,
                        ),
                      );
                    },
                  ),
                );
              }),
              // ─── Infinite-scroll footer loader ─────────────────────────
              Obx(() {
                if (!controller.isLoadingMoreAll.value) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: AppColors.green,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(CategoryController categoryCtrl) {
    final lang = Get.locale?.languageCode ?? 'tk';
    return Obx(() {
      final cats = categoryCtrl.categories;
      if (categoryCtrl.isLoading.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                lang == 'ru' ? 'Разделы' : 'Bölümler',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (_, __) => Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      if (cats.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              lang == 'ru' ? 'Разделы' : 'Bölümler',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              primary: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
                childAspectRatio: 0.83,
              ),
              itemBuilder: (_, i) => _buildCategoryCard(cats[i], lang),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryCard(CategoryModel cat, String lang) {
    final imgUrl = cat.imageSmall.isNotEmpty ? (cat.imageSmall.startsWith('http') ? cat.imageSmall : ApiConstants.fileUrl(cat.imageSmall)) : (cat.imageLarge.isNotEmpty ? (cat.imageLarge.startsWith('http') ? cat.imageLarge : ApiConstants.fileUrl(cat.imageLarge)) : '');

    return GestureDetector(
      onTap: () => Get.to(
        () => SubCategoryProductScreen(category: cat),
        transition: Transition.cupertino,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(8),
            child: imgUrl.isEmpty
                ? const Icon(Icons.category_outlined, color: AppColors.green, size: 32)
                : CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 210,
                    memCacheHeight: 210,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.category_outlined,
                      color: AppColors.green,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            cat.localName(lang),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1B20),
              fontFamily: 'Gilroy',
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    VoidCallback? onSeeAll, {
    String? tagLabel,
    Color? tagColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  letterSpacing: -0.5,
                ),
              ),
              if (tagLabel != null && tagColor != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'see_all'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: Colors.black26,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumSearchButton extends StatelessWidget {
  const PremiumSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Center(
        child: GestureDetector(
          onTap: () => Get.to(() => const SearchScreen()),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: AppColors.green,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
