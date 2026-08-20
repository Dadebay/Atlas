// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/widgets/app_dialogs.dart';
import 'package:atlas/widgets/cart_fly_animation.dart';

const _kCardGreen = AppColors.green;

class ProductCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final double price;
  final double? oldPrice;
  final String? discount;
  final double rating;
  final String location;
  final String categoryName;
  final String? brandName;
  final bool showNewTag;
  final String? id;
  final double? width;
  final VoidCallback onTap;
  final VoidCallback? onCartPressed;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({
    super.key,
    this.title = 'Ýumoş Extra "Amber" konsentrirlenen geýim ...',
    this.imageUrl = 'assets/images/galam.jpg',
    this.price = 65.0,
    this.oldPrice,
    this.discount,
    this.rating = 0.0,
    this.location = 'Aşgabat',
    this.categoryName = '',
    this.brandName,
    this.showNewTag = true,
    this.id,
    this.width,
    required this.onTap,
    this.onCartPressed,
    this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with TickerProviderStateMixin {
  late CartController _cartCtrl;
  late FavoritesController _favCtrl;

  late AnimationController _addAnim;
  late Animation<double> _scaleAnim;

  final GlobalKey _cartButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cartCtrl = Get.find<CartController>();
    _favCtrl = Get.find<FavoritesController>();

    _addAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _addAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _addAnim.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────

  int get _cartIndex => _cartCtrl.cartItems.indexWhere((e) => widget.id != null ? e['id']?.toString() == widget.id : e['title'] == widget.title);

  bool get _isInCart => _cartIndex != -1;

  int get _quantity => (_cartCtrl.cartItems.elementAtOrNull(_cartIndex)?['quantity'] as num?)?.toInt() ?? 0;

  void _addToCart() {
    _addAnim.forward().then((_) => _addAnim.reverse());
    _cartCtrl.addItem({
      'id': widget.id,
      'title': widget.title,
      'imageUrl': widget.imageUrl,
      'price': widget.price,
    });
    _flyToCart();
    _showAddedSnackbar();
  }

  void _flyToCart() {
    final box = _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    CartFlyAnimation.run(
      context: context,
      startCenter: box.localToGlobal(box.size.center(Offset.zero)),
      imageUrl: widget.imageUrl,
    );
  }

  void _showAddedSnackbar() {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    final lang = Get.locale?.languageCode ?? 'tk';
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'ru' ? 'Добавлено в корзину' : 'Sebede goşuldy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.greenn,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  void _increment() {
    final idx = _cartIndex;
    if (idx != -1) _cartCtrl.updateQuantity(idx, 1);
  }

  void _decrement() {
    final idx = _cartIndex;
    if (idx != -1) _cartCtrl.updateQuantity(idx, -1);
  }

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

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width ?? 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + discount badge ───────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.white,
                    // padding: const EdgeInsets.all(8),
                    child: widget.imageUrl.isEmpty
                        ? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))
                        : widget.imageUrl.startsWith('assets')
                            ? Image.asset(widget.imageUrl, width: double.infinity, height: 140, fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                memCacheWidth: ((widget.width ?? 170) * dpr).round(),
                                memCacheHeight: (140 * dpr).round(),
                                placeholder: (_, __) => const Center(
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: RepaintBoundary(
                                      child: _ImageLoadingAnimation(),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Divider(
                    color: Colors.grey.shade200,
                    thickness: 1,
                    height: 1,
                  ),
                ),
                if (widget.discount != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${widget.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, right: 2),
                    child: SizedBox(
                      height: 34,
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: Colors.black54,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Price row
                  Padding(
                    padding: const EdgeInsets.only(left: 2, right: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.price.toStringAsFixed(widget.price % 1 == 0 ? 0 : 2)} TMT',
                          style: const TextStyle(
                            color: Color(0xFF1D1B20),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (widget.oldPrice != null) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              widget.oldPrice!.toStringAsFixed(widget.oldPrice! % 1 == 0 ? 0 : 2),
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.black38,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // ── Buttons / Stepper ──────────────────────────
                  Obx(() {
                    final inCart = _isInCart;
                    final qty = inCart ? _quantity : 0;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: inCart ? _buildStepper(qty) : _buildButtons(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stepper [- qty +] ─────────────────────────────────────────────────

  Widget _buildStepper(int qty) {
    return ScaleTransition(
      key: const ValueKey('stepper'),
      scale: _scaleAnim,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _kCardGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // minus
            GestureDetector(
              onTap: _decrement,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(Icons.remove, color: Colors.white, size: 20),
              ),
            ),
            // count
            Expanded(
              child: Center(
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ),
            // plus
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── [fav] [cart] buttons ──────────────────────────────────────────────

  Widget _buildButtons() {
    return Row(
      key: const ValueKey('buttons'),
      children: [
        // Favorite button
        Obx(() {
          final isFav = _favCtrl.isFavorited(widget.id, widget.title);
          return GestureDetector(
            onTap: () => _guardedFavorite(
              widget.onFavoriteToggle ??
                  () => _favCtrl.toggleFavorite({
                        'id': widget.id,
                        'title': widget.title,
                        'imageUrl': widget.imageUrl,
                        'price': widget.price,
                        'rating': widget.rating,
                      }),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 37.5,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
              child: Center(
                child: isFav
                    ? const Icon(Icons.favorite_rounded, color: Colors.red, size: 20)
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedFavourite,
                        color: _kCardGreen,
                        size: 20,
                      ),
              ),
            ),
          );
        }),

        const SizedBox(width: 4),

        // Cart / Add button
        Expanded(
          child: GestureDetector(
            onTap: () => _guardedCart(_addToCart),
            child: AnimatedContainer(
              key: _cartButtonKey,
              duration: const Duration(milliseconds: 200),
              height: 36,
              decoration: BoxDecoration(
                color: _kCardGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedShoppingCart01,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Shown inside the image area while the network image is still loading.
class _ImageLoadingAnimation extends StatelessWidget {
  const _ImageLoadingAnimation();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/images/pencil_drawing_loading.json',
      repeat: true,
      animate: true,
      fit: BoxFit.contain,
    );
  }
}
