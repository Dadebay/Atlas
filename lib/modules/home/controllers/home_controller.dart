import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// True only when the catalogue could not be reached AND there is nothing on
  /// screen to fall back to. Drives the in-screen retry state.
  ///
  /// It is deliberately narrow: a failed banner request while products are
  /// showing is not worth replacing a working page over, and this flag flips
  /// rarely so the widget watching it almost never rebuilds.
  final RxBool showConnectionError = false.obs;

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

  // Runs on every scroll frame — it must stay allocation free and silent.
  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
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
        heroSlides.value = items.where((e) => e['is_active'] == true).map((e) {
          final item = e as Map<String, dynamic>;
          final lang = Get.locale?.languageCode ?? 'tk';
          final alt = (item['image_alt'] as Map<String, dynamic>?) ?? {};
          final imageUrl =
              ApiConstants.fileUrl(item['image_large']?.toString() ?? '');
          return {
            'id': item['id'] as int,
            'imageUrl': imageUrl,
            'alt': alt[lang] ?? alt['tk'] ?? alt['ru'] ?? '',
            'productId': item['product_id']?.toString(),
            'category': item['category'] as Map<String, dynamic>?,
            '_raw': item,
          };
        }).toList();
      }
    } catch (e) {
      _logError('heroSlides', e);
    }
    isLoadingBanner.value = false;
  }

  Future<void> fetchDiscountProducts() async {
    isLoadingDiscount.value = true;
    try {
      final response =
          await _api.getData('products/all?page=1&size=10&discount=true');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        discountProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
      }
    } catch (e) {
      _logError('discountProducts', e);
    }
    isLoadingDiscount.value = false;
  }

  Future<void> fetchNewProducts() async {
    isLoadingNew.value = true;
    try {
      final response =
          await _api.getData('products/all?page=1&size=10&new_in_come=true');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        newProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
      }
    } catch (e) {
      _logError('newProducts', e);
    }
    isLoadingNew.value = false;
  }

  Future<void> fetchAllProducts() async {
    isLoadingAll.value = true;
    _allProductsPage = 1;
    hasMoreAllProducts.value = true;
    var failed = false;
    try {
      final response = await _api.getData(
          'products/all?page=$_allProductsPage&size=$_allProductsPageSize');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        _allProductsTotal =
            (body['data']['total'] as num?)?.toInt() ?? items.length;
        final lang = Get.locale?.languageCode ?? 'tk';
        allProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
        _allProductsPage++;
        hasMoreAllProducts.value = allProducts.length < _allProductsTotal;
      } else {
        failed = true;
      }
    } catch (e) {
      failed = true;
      _logError('allProducts', e);
    }
    showConnectionError.value = failed && allProducts.isEmpty;
    isLoadingAll.value = false;
  }

  // Appends the next page of "all products" — triggered when the home
  // page's main scroll nears the bottom.
  Future<void> fetchMoreAllProducts() async {
    // This guard is the whole debounce: _onScroll can fire many frames in a row
    // while a page is in flight, and every one of them lands here.
    if (isLoadingMoreAll.value ||
        isLoadingAll.value ||
        !hasMoreAllProducts.value) {
      return;
    }
    isLoadingMoreAll.value = true;
    try {
      final url =
          'products/all?page=$_allProductsPage&size=$_allProductsPageSize';
      final response = await _api.getData(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        _allProductsTotal =
            (body['data']['total'] as num?)?.toInt() ?? _allProductsTotal;
        final lang = Get.locale?.languageCode ?? 'tk';
        final fetched = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();
        allProducts.addAll(fetched);
        _allProductsPage++;
        hasMoreAllProducts.value = allProducts.length < _allProductsTotal;
      }
    } catch (e) {
      _logError('moreAllProducts', e);
    }
    isLoadingMoreAll.value = false;
  }

  /// Retried from the connection-error state as well as from pull-to-refresh,
  /// so it has to be safe to call while nothing has ever loaded.
  Future<void> refreshData() async {
    await Future.wait([
      fetchHeroSlides(),
      fetchDiscountProducts(),
      fetchNewProducts(),
      fetchAllProducts(),
    ]);
  }

  /// Debug-only and deliberately terse: never log response bodies, tokens or
  /// anything from the customer's account.
  void _logError(String source, Object error) {
    if (kDebugMode) debugPrint('HomeController.$source failed: $error');
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
    final oldPriceVal = discountRaw > 0 && salePrice > 0
        ? salePrice + salePrice * discountRaw / 100
        : null;

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
