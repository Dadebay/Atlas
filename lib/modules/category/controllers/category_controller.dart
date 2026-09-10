import 'dart:convert';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/modules/category/models/category_model.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/core/utils/app_log.dart';

class CategoryController extends GetxController {
  final _api = CallApi();

  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;
  final selectedTab = 0.obs;

  static const List<int> _cardColors = [
    0xFFEBF4FF,
    0xFFFFF1EB,
    0xFFFEF9E7,
    0xFFFFEEF2,
    0xFFE7F9F5,
    0xFFF3E8FF,
    0xFFE8F5E9,
    0xFFFFF8E1,
  ];

  String get currentLang => Get.locale?.languageCode ?? 'tk';

  int colorFor(int sectionIndex, int itemIndex) =>
      _cardColors[(sectionIndex * 3 + itemIndex) % _cardColors.length];

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      // categories/tree her iki dili {"tk":...,"ru":...} olarak döndürür
      // Content-Language header CallApi tarafından otomatik gönderilir
      final response = await _api.getData('categories/tree');
      AppLog.d(
          '[Category] GET categories/tree  status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = (body['data'] as List?) ?? [];
        categories.value = rawList
            .whereType<Map<String, dynamic>>()
            .map(CategoryModel.fromJson)
            .toList();
      }
    } catch (e) {
      AppLog.d('[Category] fetchCategories error: $e');
    }
    isLoading.value = false;
  }

  Future<void> refreshData() async {
    if (selectedTab.value == 0) {
      await fetchCategories();
    } else {
      try {
        final brandsController = Get.find<BrandsController>();
        await brandsController.fetchBrands();
      } catch (e) {
        final brandsController = Get.put(BrandsController());
        await brandsController.fetchBrands();
      }
    }
  }
}
