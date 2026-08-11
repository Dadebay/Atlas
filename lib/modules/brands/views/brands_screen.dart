import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/modules/brands/models/brand_model.dart';
import 'package:atlas/modules/brands/views/brand_product_screen.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrandsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            color: AppColors.green,
          ),
        ),
        title: Text(
          'brands'.tr,
          style: const TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }

        if (controller.errorMsg.value.isNotEmpty) {
          return _buildError(controller);
        }

        if (controller.brands.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          onRefresh: controller.fetchBrands,
          color: AppColors.green,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: controller.brands.length,
            itemBuilder: (_, i) => _BrandCard(brand: controller.brands[i]),
          ),
        );
      }),
    );
  }

  Widget _buildError(BrandsController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWifiDisconnected01,
            size: 56,
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMsg.value,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 15,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.fetchBrands,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWardrobe01,
            size: 56,
            color: Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'no_data_found'.tr,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 15,
              fontFamily: 'Gilroy',
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Get.to(() => BrandProductScreen(brand: brand)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _BrandImage(imageUrl: brand.image, name: brand.name),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Text(
                  brand.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
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
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.green,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}
