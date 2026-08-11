// ignore_for_file: deprecated_member_use

import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/modules/category/models/category_model.dart';
import 'package:atlas/modules/category/views/sub_category_product_screen.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/modules/category/controllers/category_controller.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/modules/brands/models/brand_model.dart';
import 'package:atlas/modules/brands/views/brand_product_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final CategoryController _ctrl;
  late final BrandsController _brandsCtrl;

  final TextEditingController _categorySearchCtrl = TextEditingController();
  final TextEditingController _brandSearchCtrl = TextEditingController();
  final FocusNode _categoryFocus = FocusNode();
  final FocusNode _brandFocus = FocusNode();

  bool _categorySearchActive = false;
  bool _brandSearchActive = false;
  String _categoryQuery = '';
  String _brandQuery = '';
  int _tabDirection = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CategoryController>();
    _brandsCtrl = Get.put(BrandsController());
    _categorySearchCtrl.addListener(
        () => setState(() => _categoryQuery = _categorySearchCtrl.text));
    _brandSearchCtrl
        .addListener(() => setState(() => _brandQuery = _brandSearchCtrl.text));
  }

  @override
  void dispose() {
    _categorySearchCtrl.dispose();
    _brandSearchCtrl.dispose();
    _categoryFocus.dispose();
    _brandFocus.dispose();
    super.dispose();
  }

  void _toggleCategorySearch() {
    setState(() {
      _categorySearchActive = !_categorySearchActive;
      if (!_categorySearchActive) {
        _categorySearchCtrl.clear();
        _categoryQuery = '';
      } else {
        Future.delayed(const Duration(milliseconds: 80),
            () => _categoryFocus.requestFocus());
      }
    });
  }

  void _toggleBrandSearch() {
    setState(() {
      _brandSearchActive = !_brandSearchActive;
      if (!_brandSearchActive) {
        _brandSearchCtrl.clear();
        _brandQuery = '';
      } else {
        Future.delayed(
            const Duration(milliseconds: 80), () => _brandFocus.requestFocus());
      }
    });
  }

  void _onTabChanged(int index) {
    if (index == _ctrl.selectedTab.value) return;
    _tabDirection = index > _ctrl.selectedTab.value ? 1 : -1;
    _ctrl.selectedTab.value = index;
    // Reset search on tab switch
    setState(() {
      _categorySearchActive = false;
      _categorySearchCtrl.clear();
      _categoryQuery = '';
      _brandSearchActive = false;
      _brandSearchCtrl.clear();
      _brandQuery = '';
    });
    if (index == 1 &&
        _brandsCtrl.brands.isEmpty &&
        !_brandsCtrl.isLoading.value) {
      _brandsCtrl.fetchBrands();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          final isCategory = _ctrl.selectedTab.value == 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── Header: title + search icon ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCategory ? 'categories'.tr : 'brands'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: isCategory
                          ? _toggleCategorySearch
                          : _toggleBrandSearch,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isCategory
                                  ? _categorySearchActive
                                  : _brandSearchActive)
                              ? AppColors.green.withOpacity(0.1)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: (isCategory
                                    ? _categorySearchActive
                                    : _brandSearchActive)
                                ? HugeIcons.strokeRoundedCancel01
                                : HugeIcons.strokeRoundedSearch01,
                            color: (isCategory
                                    ? _categorySearchActive
                                    : _brandSearchActive)
                                ? AppColors.green
                                : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Tab bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabBar(),
              ),
              // ── Search field ──────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: (isCategory ? _categorySearchActive : _brandSearchActive)
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          controller: isCategory
                              ? _categorySearchCtrl
                              : _brandSearchCtrl,
                          focusNode: isCategory ? _categoryFocus : _brandFocus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: isCategory
                                ? (_ctrl.currentLang == 'ru'
                                    ? 'Поиск категорий...'
                                    : 'Kategoriýa gözle...')
                                : (_ctrl.currentLang == 'ru'
                                    ? 'Поиск брендов...'
                                    : 'Brend gözle...'),
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                color: AppColors.green,
                                size: 18,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                                minWidth: 44, minHeight: 44),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE8EAED)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE8EAED)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.green, width: 1.5),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final childKey = child.key as ValueKey<bool>;
                      final isIncoming = childKey.value == isCategory;
                      final beginOffset = isIncoming
                          ? Offset(_tabDirection * 0.25, 0)
                          : Offset(-_tabDirection * 0.25, 0);
                      final offsetAnimation = Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<bool>(isCategory),
                      child: isCategory ? _buildCategoryTab() : _buildBrandTab(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;
          return Obx(() {
            final selectedIndex = _ctrl.selectedTab.value;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex,
                  width: segmentWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _buildTabButton(0, 'categories'.tr, selectedIndex)),
                    Expanded(child: _buildTabButton(1, 'brands'.tr, selectedIndex)),
                  ],
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabChanged(index),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          color: isSelected ? Colors.black : const Color(0xFF8E8E93),
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'Gilroy',
        ),
        child: Center(child: Text(label)),
      ),
    );
  }

  // ── Category tab ───────────────────────────────────────────────────────────

  Widget _buildCategoryTab() {
    return Obx(() {
      if (_ctrl.isLoading.value) return const CategoryShimmer();

      final lang = _ctrl.currentLang;
      final query = _categoryQuery.trim().toLowerCase();

      // When searching: flatten all subcategories
      if (query.isNotEmpty) {
        final all = <CategoryModel>[];
        for (final parent in _ctrl.categories) {
          final children = parent.children.isEmpty ? [parent] : parent.children;
          for (final child in children) {
            if (child.localName(lang).toLowerCase().contains(query)) {
              all.add(child);
            }
          }
        }

        if (all.isEmpty) {
          return Center(
            child: Text(
              'no_data_found'.tr,
              style: const TextStyle(
                  color: Colors.black45, fontSize: 14, fontFamily: 'Gilroy'),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.83,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: all.length,
          itemBuilder: (_, i) => _buildCategoryCard(all[i], i, 0),
        );
      }

      // Normal view
      final cats = _ctrl.categories;
      return RefreshIndicator(
        onRefresh: _ctrl.refreshData,
        color: AppColors.green,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        displacement: 20,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...cats.asMap().entries.expand((entry) {
                final sectionIndex = entry.key;
                final cat = entry.value;
                return [
                  _buildSectionHeader(cat.localName(lang), cat),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(cat, sectionIndex),
                  const SizedBox(height: 32),
                ];
              }),
            ],
          ),
        ),
      );
    });
  }

  // ── Brand tab ──────────────────────────────────────────────────────────────

  Widget _buildBrandTab() {
    return Obx(() {
      if (_brandsCtrl.isLoading.value) return const BrandShimmer();

      if (_brandsCtrl.errorMsg.value.isNotEmpty) {
        return _buildBrandError();
      }

      if (_brandsCtrl.brands.isEmpty) return _buildBrandEmpty();

      final query = _brandQuery.trim().toLowerCase();
      final filtered = query.isEmpty
          ? _brandsCtrl.brands
          : _brandsCtrl.brands
              .where((b) => b.name.toLowerCase().contains(query))
              .toList();

      if (filtered.isEmpty) {
        return Center(
          child: Text(
            'no_data_found'.tr,
            style: const TextStyle(
                color: Colors.black45, fontSize: 14, fontFamily: 'Gilroy'),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _ctrl.refreshData,
        color: AppColors.green,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        displacement: 20,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.83,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _buildBrandCard(filtered[i]),
        ),
      );
    });
  }

  // ── Brand card ─────────────────────────────────────────────────────────────

  Widget _buildBrandCard(BrandModel brand) {
    return GestureDetector(
      onTap: () => Get.to(() => BrandProductScreen(brand: brand)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _BrandImage(imageUrl: brand.image, name: brand.name),
              ),
            ),
            Container(
              height: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: Text(
                brand.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWifiDisconnected01,
            size: 48,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            _brandsCtrl.errorMsg.value,
            style: const TextStyle(
                color: Colors.black45, fontSize: 14, fontFamily: 'Gilroy'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _brandsCtrl.fetchBrands,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWardrobe01,
            size: 48,
            color: Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            'no_data_found'.tr,
            style: const TextStyle(
                color: Colors.black38, fontSize: 14, fontFamily: 'Gilroy'),
          ),
        ],
      ),
    );
  }

  // ── Category helpers ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, CategoryModel cat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedGridView,
                color: Color(0xFF0D1B3E),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B3E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Get.to(() => SubCategoryProductScreen(category: cat)),
          child: Row(
            children: [
              Text(
                'show_all'.tr,
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
    );
  }

  Widget _buildCategoryGrid(CategoryModel parent, int sectionIndex) {
    final children = parent.children;
    final items = children.isEmpty ? [parent] : children;

    const maxVisible = 5;
    final showMore = items.length > maxVisible;
    final visibleItems = showMore
        ? items.take(maxVisible).toList()
        : List<CategoryModel>.from(items);
    final extraCount = showMore ? items.length - maxVisible : 0;
    final totalCount = visibleItems.length + (showMore ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.83,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (showMore && index == maxVisible) {
          return _buildShowMoreCard(extraCount, parent, sectionIndex);
        }
        return _buildCategoryCard(visibleItems[index], index, sectionIndex);
      },
    );
  }

  Widget _buildCategoryCard(
    CategoryModel cat,
    int itemIndex,
    int sectionIndex, {
    VoidCallback? onTapOverride,
  }) {
    final color = _ctrl.colorFor(sectionIndex, itemIndex);
    final lang = _ctrl.currentLang;

    return GestureDetector(
      onTap: onTapOverride ??
          () => Get.to(() => SubCategoryProductScreen(category: cat)),
      child: Container(
        decoration: BoxDecoration(
          color: Color(color),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              bottom: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withAlpha(100), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withAlpha(100), width: 1),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.localName(lang),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      color: Color(0xFF0D1B3E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _buildCategoryImage(cat),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(CategoryModel cat) {
    final imageUrl =
        cat.imageSmall.isNotEmpty ? cat.imageSmall : cat.imageLarge;
    if (imageUrl.isEmpty) {
      return const Icon(Icons.category, color: Colors.grey, size: 60);
    }
    return CachedNetworkImage(
      imageUrl: ApiConstants.fileUrl(imageUrl),
      height: 52,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox(
        width: 24,
        height: 24,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
      ),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.category, color: Colors.grey, size: 60),
    );
  }

  Widget _buildShowMoreCard(int count, CategoryModel parent, int sectionIndex) {
    return GestureDetector(
      onTap: () => _showAllSubcategoriesSheet(parent, sectionIndex),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedGridView,
                color: Color(0xFF0D1B3E),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _ctrl.currentLang == 'ru'
                    ? 'Ещё $count'
                    : 'Ýene-de $count sany',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D1B3E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSubcategoriesSheet(CategoryModel parent, int sectionIndex) {
    final lang = _ctrl.currentLang;
    final items = parent.children.isEmpty ? [parent] : parent.children;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.78),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    parent.localName(lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF0D1B3E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.83,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cat = items[index];
                  return _buildCategoryCard(
                    cat,
                    index,
                    sectionIndex,
                    onTapOverride: () {
                      Get.back();
                      Get.to(() => SubCategoryProductScreen(category: cat));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ── Brand shimmer ──────────────────────────────────────────────────────────────

class BrandShimmer extends StatefulWidget {
  const BrandShimmer({super.key});

  @override
  State<BrandShimmer> createState() => _BrandShimmerState();
}

class _BrandShimmerState extends State<BrandShimmer>
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
        final g = LinearGradient(
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: const [0.1, 0.45, 0.8],
          begin: Alignment(-2.0 + _ctrl.value * 4, 0),
          end: Alignment(0.0 + _ctrl.value * 4, 0),
          tileMode: TileMode.clamp,
        );

        return GridView.builder(
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
        );
      },
    );
  }
}

class _BrandImage extends StatelessWidget {
  final String imageUrl;
  final String name;
  const _BrandImage({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
        ),
      ),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.green,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}
