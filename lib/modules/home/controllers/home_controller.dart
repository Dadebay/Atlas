import 'dart:convert';

import 'package:flutter/widgets.dart';
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

  // ── "all products" pagination — infinite scroll on the home page ───────
  final scrollController = ScrollController();
  static const int _allProductsPageSize = 20;
  int _allProductsPage = 1;
  int _allProductsTotal = 0;
  var isLoadingMoreAll = false.obs;
  var hasMoreAllProducts = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHeroSlides();
    fetchDiscountProducts();
    fetchNewProducts();
    fetchAllProducts();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    print('[Scroll] pixels=${position.pixels} maxScrollExtent=${position.maxScrollExtent} '
        'nearBottom=${position.pixels >= position.maxScrollExtent - 400} '
        'isLoadingMoreAll=${isLoadingMoreAll.value} isLoadingAll=${isLoadingAll.value} '
        'hasMoreAllProducts=${hasMoreAllProducts.value} page=$_allProductsPage '
        'loaded=${allProducts.length} total=$_allProductsTotal');
    if (position.pixels >= position.maxScrollExtent - 400) {
      fetchMoreAllProducts();
    }
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
    _allProductsPage = 1;
    hasMoreAllProducts.value = true;
    try {
      final response =
          await _api.getData('products/all?page=$_allProductsPage&size=$_allProductsPageSize');
      print('[AllProducts] status: ${response.statusCode}');
      print('[AllProducts] body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        _allProductsTotal = (body['data']['total'] as num?)?.toInt() ?? items.length;
        final lang = Get.locale?.languageCode ?? 'tk';
        allProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
        _allProductsPage++;
        hasMoreAllProducts.value = allProducts.length < _allProductsTotal;
      }
    } catch (_) {}
    isLoadingAll.value = false;
  }

  // Appends the next page of "all products" — triggered when the home
  // page's main scroll nears the bottom.
  Future<void> fetchMoreAllProducts() async {
    if (isLoadingMoreAll.value || isLoadingAll.value || !hasMoreAllProducts.value) {
      print('[MoreProducts] skipped: isLoadingMoreAll=${isLoadingMoreAll.value} '
          'isLoadingAll=${isLoadingAll.value} hasMoreAllProducts=${hasMoreAllProducts.value}');
      return;
    }
    print('[MoreProducts] fetching page=$_allProductsPage size=$_allProductsPageSize '
        'currentlyLoaded=${allProducts.length} total=$_allProductsTotal');
    isLoadingMoreAll.value = true;
    try {
      final url = 'products/all?page=$_allProductsPage&size=$_allProductsPageSize';
      final response = await _api.getData(url);
      print('[MoreProducts] GET $url -> status=${response.statusCode}');
      print('[MoreProducts] body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        _allProductsTotal = (body['data']['total'] as num?)?.toInt() ?? _allProductsTotal;
        final lang = Get.locale?.languageCode ?? 'tk';
        final fetched = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
        for (final p in fetched) {
          print('[MoreProducts] item id=${p['id']} title=${p['title']} price=${p['price']} '
              'oldPrice=${p['oldPrice']} discount=${p['discount']} category=${p['categoryName']} '
              'brand=${p['brandName']} imageUrl=${p['imageUrl']}');
        }
        allProducts.addAll(fetched);
        _allProductsPage++;
        hasMoreAllProducts.value = allProducts.length < _allProductsTotal;
        print('[MoreProducts] fetched=${fetched.length} totalLoaded=${allProducts.length} '
            'total=$_allProductsTotal hasMore=${hasMoreAllProducts.value} nextPage=$_allProductsPage');
      } else {
        print('[MoreProducts] non-200 response, aborting page increment');
      }
    } catch (e, st) {
      print('[MoreProducts] ERROR: $e');
      print(st);
    }
    isLoadingMoreAll.value = false;
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
