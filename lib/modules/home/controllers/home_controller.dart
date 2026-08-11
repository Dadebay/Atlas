import 'dart:convert';

import 'package:get/get.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';

class HomeController extends GetxController {
  final _api = CallApi();

  var heroSlides = <Map<String, dynamic>>[].obs;
  var isLoadingBanner = false.obs;

  var discountProducts = <Map<String, dynamic>>[].obs;
  var newProducts = <Map<String, dynamic>>[].obs;
  var allProducts = <Map<String, dynamic>>[].obs;
  var isLoadingDiscount = false.obs;
  var isLoadingNew = false.obs;
  var isLoadingAll = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHeroSlides();
    fetchDiscountProducts();
    fetchNewProducts();
    fetchAllProducts();
  }

  Future<void> fetchHeroSlides() async {
    isLoadingBanner.value = true;
    try {
      final response = await _api.getData('hero-slides');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data'] as List? ?? [];
        heroSlides.value = items
            .where((e) => e['is_active'] == true)
            .map((e) {
              final item = e as Map<String, dynamic>;
              final lang = Get.locale?.languageCode ?? 'tk';
              final alt = (item['image_alt'] as Map<String, dynamic>?) ?? {};
              final imageUrl =
                  ApiConstants.fileUrl(item['image_large']?.toString() ?? '');
              print('[Banner] id=${item['id']} is_active=${item['is_active']} '
                  'imageUrl=$imageUrl alt=${alt[lang] ?? alt['tk'] ?? ''}');
              return {
                'id': item['id'] as int,
                'imageUrl': imageUrl,
                'alt': alt[lang] ?? alt['tk'] ?? alt['ru'] ?? '',
                'productId': item['product_id']?.toString(),
                'category': item['category'] as Map<String, dynamic>?,
                '_raw': item,
              };
            })
            .toList();
        print('[Banner] total active slides: ${heroSlides.value.length}');
      }
    } catch (_) {}
    isLoadingBanner.value = false;
  }

  Future<void> fetchDiscountProducts() async {
    isLoadingDiscount.value = true;
    try {
      final response = await _api.getData('products/all?page=1&size=10&discount=true');
      print('[Discount] status: ${response.statusCode}');
      print('[Discount] body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        discountProducts.value =
            items.map((e) => _toProductMap(e as Map<String, dynamic>, lang)).toList();
      }
    } catch (_) {}
    isLoadingDiscount.value = false;
  }

  Future<void> fetchNewProducts() async {
    isLoadingNew.value = true;
    try {
      final response = await _api.getData('products/all?page=1&size=10&new_in_come=true');
      print('[NewProducts] status: ${response.statusCode}');
      print('[NewProducts] body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        newProducts.value =
            items.map((e) => _toProductMap(e as Map<String, dynamic>, lang)).toList();
      }
    } catch (_) {}
    isLoadingNew.value = false;
  }

  Future<void> fetchAllProducts() async {
    isLoadingAll.value = true;
    try {
      final response = await _api.getData('products/all?page=1&size=20');
      print('[AllProducts] status: ${response.statusCode}');
      print('[AllProducts] body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        allProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
      }
    } catch (_) {}
    isLoadingAll.value = false;
  }

  Future<void> refreshData() async {
    await Future.wait([
      fetchHeroSlides(),
      fetchDiscountProducts(),
      fetchNewProducts(),
      fetchAllProducts(),
    ]);
  }

  Map<String, dynamic> _toProductMap(Map<String, dynamic> item, String lang) {
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
    final oldPriceVal =
        discountRaw > 0 && salePrice > 0 ? salePrice + salePrice * discountRaw / 100 : null;
    print('[ProductCard] id=${item['id']} sale=$salePrice discount=$discountRaw oldPrice=$oldPriceVal');

    final categoryName = item['category_name']?.toString() ?? '';
    final categoryId = item['category_id'] is int
        ? item['category_id'] as int
        : int.tryParse(item['category_id']?.toString() ?? '');

    final brandName = item['brand_name']?.toString() ?? '';
    final brandId = item['brand_id'] is int
        ? item['brand_id'] as int
        : int.tryParse(item['brand_id']?.toString() ?? '');

    return {
      'id': item['id'].toString(),
      'title': title,
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPriceVal,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'rating': 0.0,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'brandId': brandId,
      'brandName': brandName,
    };
  }
}
