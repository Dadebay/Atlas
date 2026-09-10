// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/orders/views/checkout_screen.dart';
import 'package:atlas/widgets/animated_quantity_text.dart';
import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/widgets/empty_state_animation.dart';

const _kGreen = AppColors.green;

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'cart'.tr,
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
        actions: [
          Obx(() => controller.cartItems.isNotEmpty
              ? IconButton(
                  onPressed: () => _showDeleteConfirmation(context, -1),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete01,
                    color: Colors.red,
                    size: 20,
                  ),
                )
              : const SizedBox()),
        ],
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
    // Loading state
    if (controller.isLoading.value && controller.cartItems.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
      );
    }

    // Empty cart
    if (controller.cartItems.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
        color: _kGreen,
        backgroundColor: Colors.white,
        onRefresh: controller.fetchCart,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildEmptyCart(),
            ),
          ),
        ),
      );
    }

    // Non-empty cart
    return Column(
      key: const ValueKey('cart'),
      children: [
        Expanded(
          child: RefreshIndicator(
            color: _kGreen,
            backgroundColor: Colors.white,
            onRefresh: controller.fetchCart,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: controller.cartItems.length,
              itemBuilder: (context, index) {
                final item = controller.cartItems[index];
                return _buildCartItem(context, index, item);
              },
            ),
          ),
        ),
        _buildCartSummary(context),
      ],
    );
  }

  // ─── Empty cart ────────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The composition is square (1000x1000), so the box is too — a
          // 125x130 slot would letterbox it.
          const EmptyStateAnimation(
            asset: 'assets/images/empty_cart.json',
            fallbackIcon: Icons.shopping_cart_outlined,
            size: 170,
            // Loops on request. TickerMode keeps the cost bounded: this only
            // ticks while the cart tab is the one on screen.
            repeat: true,
          ),
          const SizedBox(height: 24),
          Text(
            'empty_cart'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_products'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ─── Cart item ─────────────────────────────────────────────────────────────

  Widget _buildCartItem(
      BuildContext context, int index, Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final image = item['imageUrl'] ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final totalLine = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Product image ──────────────────────────────────
          GestureDetector(
            onTap: () => _openFullScreen(image.toString()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: const Color(0xFFF5F5F5),
                child: image.toString().isEmpty ||
                        image.toString().startsWith('assets')
                    ? Image.asset(
                        image.toString(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image,
                            color: Colors.grey, size: 32),
                      )
                    : CachedNetworkImage(
                        imageUrl: image.toString(),
                        fit: BoxFit.contain,
                        memCacheWidth: 270,
                        memCacheHeight: 270,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kGreen,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(Icons.image,
                            color: Colors.grey, size: 32),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Info column ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, index),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete01,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Price per unit × qty  +  qty stepper
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left: unit price & total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)} TMT × $quantity',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${totalLine.toStringAsFixed(0)} TMT',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: stepper pill
                    Container(
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQtyBtn(
                            Icons.remove,
                            () => controller.updateQuantity(index, -1),
                            'decrease_quantity'.trParams({
                              'name': title,
                              'count': '${quantity - 1}',
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: AnimatedQuantityText(
                              quantity: quantity,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                          _buildQtyBtn(
                            Icons.add,
                            () => controller.updateQuantity(index, 1),
                            'increase_quantity'.trParams({
                              'name': title,
                              'count': '${quantity + 1}',
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cart summary ──────────────────────────────────────────────────────────

  Widget _buildCartSummary(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() {
                        final count = controller.cartItems.fold<int>(
                          0,
                          (s, e) => s + ((e['quantity'] as num?)?.toInt() ?? 1),
                        );
                        return Text(
                          '$count ${'items'.tr}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                            fontFamily: 'Gilroy',
                          ),
                        );
                      }),
                    ],
                  ),
                  Obx(() => Text(
                        '${controller.totalPrice.toStringAsFixed(0)} TMT',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _kGreen,
                          fontFamily: 'Gilroy',
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  if (controller.cartItems.isNotEmpty) {
                    Get.to(
                      () => const CheckoutScreen(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'order_now'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, String label) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          // 44x44 — the old 34 px padded icon was under the minimum target.
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _openFullScreen(String imageUrl) {
    if (imageUrl.isEmpty) return;
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: imageUrl.startsWith('assets')
                ? Image.asset(imageUrl, fit: BoxFit.contain)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
      ),
      // Full-screen image viewing is the one deliberate exception to the
      // platform route policy: a fade reads as the photo opening in place.
      transition: Transition.fadeIn,
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete01,
                    color: Colors.red,
                    size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                index == -1 ? 'clear_cart'.tr : 'remove_product'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1D1B20)),
              ),
              const SizedBox(height: 12),
              Text(
                index == -1
                    ? 'clear_cart_confirm'.tr
                    : 'remove_product_confirm'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    color: Colors.black54,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('no'.tr,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Gilroy',
                              color: Colors.black45)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (index == -1) {
                          controller.clearCart();
                        } else {
                          controller.removeItem(index);
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('yes'.tr,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Gilroy')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
