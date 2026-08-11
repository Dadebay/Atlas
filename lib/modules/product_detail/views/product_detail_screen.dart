// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/modules/product_detail/controllers/product_detail_controller.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/widgets/app_dialogs.dart';
import 'package:atlas/widgets/cart_fly_animation.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';

const _kGreen = AppColors.green;

class ProductDetailScreen extends StatefulWidget {
  final String? id;

  const ProductDetailScreen({super.key, this.id});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailController _ctrl;
  late final CartController _cartCtrl;
  late final FavoritesController _favCtrl;

  String get _tag => widget.id ?? 'default';

  final GlobalKey _addButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Her ürün için ayrı controller — singleton paylaşım sorununu önler
    Get.put(ProductDetailController(), tag: _tag, permanent: false);
    _ctrl = Get.find<ProductDetailController>(tag: _tag);
    _cartCtrl = Get.find<CartController>();
    _favCtrl = Get.find<FavoritesController>();
    if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ctrl.fetchProduct(widget.id!),
      );
    }
  }

  @override
  void dispose() {
    Get.delete<ProductDetailController>(tag: _tag, force: true);
    super.dispose();
  }

  // ── utils ──────────────────────────────────────────────────────────────

  String _loc(dynamic raw, String lang) {
    if (raw is Map) {
      return raw[lang]?.toString() ??
          raw['tk']?.toString() ??
          raw['ru']?.toString() ??
          '';
    }
    return raw?.toString() ?? '';
  }

  String _imageUrl(Map<String, dynamic> data) {
    final imagesRaw = data['images'];
    String url = '';
    if (imagesRaw is String && imagesRaw.isNotEmpty) {
      url = imagesRaw;
    } else if (imagesRaw is List && imagesRaw.isNotEmpty) {
      final first = imagesRaw[0];
      url = first is String
          ? first
          : (first is Map ? first['url']?.toString() ?? '' : '');
    }
    if (url.isNotEmpty && !url.startsWith('http')) {
      url = ApiConstants.fileUrl(url);
    }
    return url;
  }

  List<String> _imageUrls(Map<String, dynamic> data) {
    final raw = data['images'];
    if (raw is String && raw.isNotEmpty) {
      return [raw.startsWith('http') ? raw : ApiConstants.fileUrl(raw)];
    }
    if (raw is List) {
      return raw
          .map((e) {
            String u =
                e is String ? e : (e is Map ? e['url']?.toString() ?? '' : '');
            if (u.isNotEmpty && !u.startsWith('http')) {
              u = ApiConstants.fileUrl(u);
            }
            return u;
          })
          .where((u) => u.isNotEmpty)
          .toList();
    }
    return [];
  }

  int get _cartIndex => _cartCtrl.cartItems.indexWhere(
      (e) => widget.id != null ? e['id']?.toString() == widget.id : false);

  void _guardedFavorite(VoidCallback action) {
    if (AuthStorage().isLoggedIn) {
      action();
    } else {
      AppDialogs.showLoginRequiredSnackbar();
    }
  }

  void _guardedCart(VoidCallback action) {
    if (AuthStorage().isLoggedIn) {
      action();
    } else {
      AppDialogs.showLoginRequiredDialog();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────

  String _productWebLink(Map<String, dynamic> data) {
    final lang = Get.locale?.languageCode ?? 'ru';
    final name = _loc(data['name'], lang).trim();
    // Prefer explicit slug if available
    final slugRaw = data['slug']?.toString() ?? data['url']?.toString() ?? '';
    final slug = slugRaw.isNotEmpty ? slugRaw : name;
    final encoded = Uri.encodeComponent(slug);
    return '${ApiConstants.webBaseUrl}/$lang/products/$encoded';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
          );
        }
        final data = _ctrl.productData.value;
        if (data == null) {
          return Center(
            child: Text('no_products_found'.tr,
                style: const TextStyle(color: Colors.grey)),
          );
        }
        return _buildContent(data);
      }),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: Get.back,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: _kGreen,
            size: 24,
          ),
        ),
      ),
      actions: [
        // Favourite
        Obx(() {
          final data = _ctrl.productData.value;
          final lang = Get.locale?.languageCode ?? 'tk';
          final title = _loc(data?['name'], lang);
          final price =
              double.tryParse(data?['sale_price']?.toString() ?? '0') ?? 0.0;
          final imgUrl = data != null ? _imageUrl(data) : '';
          final isFav = _favCtrl.isFavorited(widget.id, title);
          return GestureDetector(
            onTap: () => _guardedFavorite(() => _favCtrl.toggleFavorite({
                  'id': widget.id,
                  'title': title,
                  'imageUrl': imgUrl,
                  'price': price,
                })),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: isFav
                  ? const Icon(Icons.favorite_rounded,
                      color: Colors.red, size: 26)
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      color: _kGreen,
                      size: 26,
                    ),
            ),
          );
        }),
        // Share
        // Share
        GestureDetector(
          onTap: () {
            final data = _ctrl.productData.value;
            final link = data != null
                ? _productWebLink(data)
                : '${ApiConstants.webBaseUrl}/ru/product/${widget.id ?? ''}';
            Share.share(link);
          },
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              color: _kGreen,
              size: 26,
            ),
          ),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  // ── Content ────────────────────────────────────────────────────────────

  Widget _buildContent(Map<String, dynamic> data) {
    final lang = Get.locale?.languageCode ?? 'tk';

    final title = _loc(data['name'], lang);
    final description = _loc(data['description'], lang);
    final imageUrls = _imageUrls(data);

    final salePrice =
        double.tryParse(data['sale_price']?.toString() ?? '0') ?? 0.0;
    final discountRaw =
        (double.tryParse(data['discount']?.toString() ?? '0') ?? 0.0).round();
    final hasDiscount = discountRaw > 0;
    final discountPct = discountRaw;
    final oldPrice = hasDiscount && salePrice > 0
        ? salePrice + salePrice * discountRaw / 100
        : null;

    final catData = data['category'] as Map<String, dynamic>?;
    final categoryName = _loc(catData?['name'], lang);
    final parentCatData = catData?['parent'] as Map<String, dynamic>?;
    final parentCatName =
        parentCatData != null ? _loc(parentCatData['name'], lang) : '';

    final brandData = data['brand'] as Map<String, dynamic>?;
    final brandName = _loc(brandData?['name'], lang);

    final specs = data['specifications'] as List? ?? [];
    final article = data['article']?.toString() ?? '';
    final barcode = data['barcode']?.toString() ?? '';
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image carousel (dots overlaid on the image) ──
                _buildImageCarousel(imageUrls, title),

                const Divider(height: 1, color: Color(0xFFF0F0F0)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand name ──────────────────────────────
                      if (brandName.isNotEmpty) ...[
                        Text(
                          brandName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kGreen,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Category breadcrumb ─────────────────────
                      if (categoryName.isNotEmpty) ...[
                        Row(
                          children: [
                            if (parentCatName.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  parentCatName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kGreen,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '>',
                                  style: TextStyle(
                                      color: _kGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // ── Discount badge ──────────────────────────
                      if (hasDiscount) ...[
                        _badge('-$discountPct%', const Color(0xFFE53935)),
                        const SizedBox(height: 10),
                      ],

                      // ── Title ───────────────────────────────────
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.35,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Price ───────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${salePrice.toStringAsFixed(salePrice % 1 == 0 ? 0 : 2)} TMT',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _kGreen,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          if (oldPrice != null) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '${oldPrice.toStringAsFixed(oldPrice % 1 == 0 ? 0 : 2)} TMT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 14),

                      // ── Details ─────────────────────────────────
                      if (article.isNotEmpty) ...[
                        _detailRow('article'.tr, article),
                        const SizedBox(height: 8),
                      ],
                      if (barcode.isNotEmpty) ...[
                        _detailRow('barcode'.tr, barcode),
                        const SizedBox(height: 8),
                      ],
                      _detailRow('stock'.tr, stock.toString()),

                      // ── Description ─────────────────────────────
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 14),
                        Text(
                          'description'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.65),
                            height: 1.65,
                          ),
                        ),
                      ],

                      // ── Specs ────────────────────────────────────
                      if (specs.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 14),
                        Text(
                          'product_features'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...specs.map((s) {
                          final spec = s as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _detailRow(
                              _loc(spec['name'], lang),
                              _loc(spec['value'], lang),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ── Similar products ──────────────────────────────────
                _buildSimilarSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Bottom bar ──────────────────────────────────────────────────
        _buildBottomBar(data, title, salePrice, oldPrice),
      ],
    );
  }

  // ── Image carousel ─────────────────────────────────────────────────────

  Widget _buildImageCarousel(List<String> imageUrls, String title) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 340,
        width: double.infinity,
        color: const Color(0xFFF9F9F9),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 64, color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        children: [
          // Positioned.fill so the page view always fills the full 340px
          // box — a plain (non-positioned) child in a Stack shrinks to its
          // own intrinsic size and gets pinned per Stack.alignment, which
          // was leaving a blank gap above the image.
          Positioned.fill(
            child: PageView.builder(
              onPageChanged: _ctrl.changeImage,
              itemCount: imageUrls.length,
              itemBuilder: (_, index) => GestureDetector(
                onTap: () => _showFullScreen(imageUrls, index),
                child: Hero(
                  tag: 'product_image_${widget.id ?? title}_$index',
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: _kGreen, strokeWidth: 2.5),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Dots — overlaid on the image, not below it ──────────
          if (imageUrls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(imageUrls.length, (i) {
                          final sel = _ctrl.selectedImage.value == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: sel ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    )),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(Map<String, dynamic> data, String title,
      double salePrice, double? oldPrice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${salePrice.toStringAsFixed(salePrice % 1 == 0 ? 0 : 2)} TMT',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _kGreen,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  if (oldPrice != null) ...[
                    Text(
                      '${oldPrice.toStringAsFixed(oldPrice % 1 == 0 ? 0 : 2)} TMT',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.grey,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ],
                ],
              ),

              // Button or Stepper — artık Expanded yok
              Obx(() {
                // 👈 Expanded kaldırıldı
                final idx = _cartIndex;
                final inCart = idx != -1;
                final qty = inCart
                    ? (_cartCtrl.cartItems[idx]['quantity'] as num?)?.toInt() ??
                        1
                    : 0;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: inCart
                      ? _buildStepper(idx, qty)
                      : _buildAddButton(data, title, salePrice),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
      Map<String, dynamic> data, String title, double salePrice) {
    return SizedBox(
      key: const ValueKey('add_btn'),
      height: 52,
      width: 180,
      child: ElevatedButton(
        key: _addButtonKey,
        onPressed: () => _guardedCart(() {
          final imgUrl = _imageUrl(data);
          _cartCtrl.addItem({
            'id': widget.id,
            'title': title,
            'imageUrl': imgUrl,
            'price': salePrice,
          });
          final box =
              _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.attached) {
            CartFlyAnimation.run(
              context: context,
              startCenter: box.localToGlobal(box.size.center(Offset.zero)),
              imageUrl: imgUrl,
            );
          }
        }),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'add_to_cart'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(int idx, int qty) {
    return Container(
      key: const ValueKey('stepper'),
      height: 52,
      decoration: BoxDecoration(
        color: _kGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _cartCtrl.updateQuantity(idx, -1),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.remove, color: Colors.white, size: 22),
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFamily: 'Gilroy',
            ),
          ),
          GestureDetector(
            onTap: () => _cartCtrl.updateQuantity(idx, 1),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy')),
      );

  Widget _detailRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      );

  // ── Similar products ───────────────────────────────────────────────────

  Widget _buildSimilarSection() {
    return Obx(() {
      final loading = _ctrl.isLoadingSimilar.value;
      final products = _ctrl.similarProducts;

      if (!loading && products.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'similar_products'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: Colors.black87,
                  ),
                ),
                if (products.isNotEmpty)
                  Text(
                    '${products.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kGreen,
                      fontFamily: 'Gilroy',
                    ),
                  ),
              ],
            ),
          ),
          if (loading && products.isEmpty)
            const ProductCardShimmerGrid(
              count: 4,
              mainAxisExtent: 260,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              gridPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 260,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return ProductCard(
                  title: p['title'] as String,
                  imageUrl: p['imageUrl'] as String,
                  price: (p['price'] as num).toDouble(),
                  oldPrice: p['oldPrice'] != null
                      ? (p['oldPrice'] as num).toDouble()
                      : null,
                  discount: p['discount'] as String?,
                  id: p['id'] as String?,
                  categoryName: p['categoryName'] as String,
                  brandName: p['brandName'] as String?,
                  rating: (p['rating'] as num).toDouble(),
                  onTap: () => Get.to(
                    () => ProductDetailScreen(id: p['id'] as String),
                    preventDuplicates: false,
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  void _showFullScreen(List<String> imageUrls, int initialIndex) {
    Get.to(
      () =>
          _FullScreenGallery(imageUrls: imageUrls, initialIndex: initialIndex),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }
}

// ── Full screen gallery ───────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullScreenGallery(
      {required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 6.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: Get.back,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
