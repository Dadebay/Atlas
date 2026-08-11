import 'dart:convert';
import 'package:get/get.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';

class ProductDetailController extends GetxController {
  final _api = CallApi();

  var selectedImage = 0.obs;
  var quantity = 1.obs;
  var isLoading = false.obs;
  var productData = Rxn<Map<String, dynamic>>();

  var similarProducts = <Map<String, dynamic>>[].obs;
  var isLoadingSimilar = false.obs;

  void changeImage(int index) => selectedImage.value = index;
  void increment() => quantity.value++;
  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }

  Future<void> fetchProduct(String id) async {
    isLoading.value = true;
    productData.value = null;
    selectedImage.value = 0;
    similarProducts.clear();
    try {
      final response = await _api.getData('products/$id');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as Map<String, dynamic>;
        productData.value = data;

        final catData = data['category'] as Map<String, dynamic>?;
        final categoryId = catData?['id']?.toString();
        if (categoryId != null) {
          Future.microtask(() => fetchSimilarProducts(categoryId, id));
        }
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> fetchSimilarProducts(
      String categoryId, String currentId) async {
    isLoadingSimilar.value = true;
    try {
      final response = await _api
          .getData('products/all?page=1&size=10&category_id=$categoryId');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        similarProducts.value = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .where((e) => e['id'] != currentId)
            .toList();
      }
    } catch (_) {}
    isLoadingSimilar.value = false;
  }

  Map<String, dynamic> _toProductMap(
      Map<String, dynamic> item, String lang) {
    final rawUrl = item['image_url']?.toString() ?? '';
    final imageUrl = rawUrl.isEmpty
        ? ''
        : rawUrl.startsWith('http')
            ? rawUrl
            : ApiConstants.fileUrl(rawUrl);
    final salePrice =
        double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0.0;
    final discountRaw =
        (double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0)
            .round();
    final oldPrice = discountRaw > 0 && salePrice > 0
        ? salePrice + salePrice * discountRaw / 100
        : null;
    return {
      'id': item['id'].toString(),
      'title': item['name']?.toString() ?? '',
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPrice,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'categoryName': item['category_name']?.toString() ?? '',
      'brandName': item['brand_name']?.toString() ?? '',
      'rating': 0.0,
    };
  }
}
