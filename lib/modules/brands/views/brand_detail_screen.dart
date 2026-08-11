import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/modules/brands/models/brand_model.dart';

class BrandDetailScreen extends StatefulWidget {
  final BrandModel brand;
  const BrandDetailScreen({super.key, required this.brand});

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  late final BrandsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BrandsController>()
        ? Get.find<BrandsController>()
        : Get.put(BrandsController());
    _controller.fetchBrandById(widget.brand.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Obx(() {
        final brand = _controller.selectedBrand.value ?? widget.brand;
        final loading = _controller.isDetailLoading.value;

        return CustomScrollView(
          slivers: [
            // ─── SliverAppBar with brand image ───────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 22,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(32, 80, 32, 16),
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.green),
                        )
                      : _buildHeroImage(brand.image, brand.name),
                ),
              ),
            ),

            // ─── Content ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      brand.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Gilroy',
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          _infoRow(
                            icon: HugeIcons.strokeRoundedTag01,
                            label: 'ID',
                            value: '#${brand.id}',
                          ),
                          const Divider(height: 24, color: Color(0xFFF0F0F0)),
                          _infoRow(
                            icon: HugeIcons.strokeRoundedWardrobe01,
                            label: 'brands'.tr,
                            value: brand.name,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeroImage(String imageUrl, String name) {
    if (imageUrl.isEmpty) return _placeholder(name);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      errorWidget: (_, __, ___) => _placeholder(name),
    );
  }

  Widget _placeholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w900,
          color: AppColors.green,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HugeIcon(icon: icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
