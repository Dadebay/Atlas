import 'dart:convert';

import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CallApi _api = CallApi();

  String _query = '';
  bool _isLoading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _results = [];

  // Shown before the user has typed/searched anything — picked from
  // discounted items so it doubles as an incentive to browse.
  List<Map<String, dynamic>> _recommended = [];
  bool _isLoadingRecommended = false;

  @override
  void initState() {
    super.initState();
    _fetchRecommended();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommended() async {
    setState(() => _isLoadingRecommended = true);
    try {
      final response =
          await _api.getData('products/all?page=1&size=20&discount=true');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        setState(() {
          _recommended = items
              .map((e) => _toProductMap(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('[Recommended API] Exception: $e');
    }
    if (mounted) setState(() => _isLoadingRecommended = false);
  }

  Future<void> _searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final encoded = Uri.encodeQueryComponent(trimmed);
      final response =
          await _api.getData('products/all?page=1&size=20&search=$encoded');
      print('[Search API] GET status code: ${response.statusCode}');
      print('[Search API] GET response body: ${response.body}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        setState(() {
          _results = items
              .map((e) => _toProductMap(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('[Search API] Exception: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, dynamic> _toProductMap(Map<String, dynamic> item) {
    final title = item['name']?.toString() ?? '';

    final rawImageUrl = item['image_url']?.toString() ?? '';
    final String imageUrl = rawImageUrl.isEmpty
        ? ''
        : rawImageUrl.startsWith('http')
            ? rawImageUrl
            : ApiConstants.fileUrl(rawImageUrl);

    final salePrice =
        double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0.0;
    final discountRaw =
        (double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0).round();
    final oldPrice = discountRaw > 0 && salePrice > 0
        ? salePrice + salePrice * discountRaw / 100
        : null;

    return {
      'id': item['id'].toString(),
      'title': title,
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPrice,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'categoryName': item['category_name']?.toString() ?? '',
      'brandName': item['brand_name']?.toString() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cartCtrl = Get.find<CartController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: AppColors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'search'.tr,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6ECE8)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _query = value),
                      onSubmitted: _searchProducts,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'search_hint'.tr,
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                    _results = [];
                                    _hasSearched = false;
                                  });
                                },
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedCancel01,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.green,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _hasSearched && _results.isEmpty
                      ? _buildNoResults()
                      : !_hasSearched
                          ? _buildRecommended(cartCtrl)
                          : _buildProductGrid(_results, cartCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommended(CartController cartCtrl) {
    if (_isLoadingRecommended && _recommended.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.green,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_recommended.isEmpty) return const SizedBox.shrink();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              'recommended_products'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
          sliver: _buildProductSliverGrid(_recommended, cartCtrl),
        ),
      ],
    );
  }

  Widget _buildProductGrid(
      List<Map<String, dynamic>> items, CartController cartCtrl) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 260,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildProductCard(items[index], cartCtrl),
    );
  }

  Widget _buildProductSliverGrid(
      List<Map<String, dynamic>> items, CartController cartCtrl) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 260,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildProductCard(items[index], cartCtrl),
        childCount: items.length,
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, CartController cartCtrl) {
    return ProductCard(
      id: item['id'] as String?,
      title: item['title'] as String,
      imageUrl: item['imageUrl'] as String,
      price: item['price'] as double,
      oldPrice: item['oldPrice'] as double?,
      discount: item['discount'] as String?,
      brandName: item['brandName'] as String?,
      categoryName: item['categoryName'] as String? ?? '',
      onTap: () => Get.to(
        () => ProductDetailScreen(id: item['id'] as String?),
        binding: ProductDetailBinding(),
      ),
      onCartPressed: () => cartCtrl.addItem({
        'id': item['id'],
        'title': item['title'],
        'imageUrl': item['imageUrl'],
        'price': item['price'],
      }),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedSearchRemove,
              color: Colors.grey,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'no_results'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
