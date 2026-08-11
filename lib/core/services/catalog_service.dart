import 'dart:convert';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';

class CatalogService extends GetxService {
  static CatalogService get to => Get.find();

  final _api = CallApi();
  final _categoryNames = <int, Map<String, String>>{};
  final _brandNames = <int, String>{};
  final _loaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    await Future.wait([_fetchCategories(), _fetchBrands()]);
    _loaded.value = true;
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _api.getData('categories');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data'] as List? ?? [];
        for (final item in items) {
          _addCategory(item as Map<String, dynamic>);
        }
      }
    } catch (_) {}
  }

  void _addCategory(Map<String, dynamic> item) {
    final id = item['id'] as int?;
    if (id != null) {
      final rawName = item['name'];
      Map<String, String> nameMap;
      if (rawName is Map) {
        nameMap = rawName.map((k, v) => MapEntry(k.toString(), v.toString()));
      } else {
        final n = rawName?.toString() ?? '';
        nameMap = {'tk': n, 'ru': n};
      }
      _categoryNames[id] = nameMap;
    }
    final children = item['children'] as List? ?? [];
    for (final child in children) {
      _addCategory(child as Map<String, dynamic>);
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final response = await _api.getData('brands');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data'] as List? ?? [];
        for (final item in items) {
          final id = item['id'] as int?;
          final name = item['name']?.toString() ?? '';
          if (id != null) _brandNames[id] = name;
        }
      }
    } catch (_) {}
  }

  String categoryName(int? id) {
    _loaded.value;
    if (id == null) return '';
    final lang = Get.locale?.languageCode ?? 'tk';
    final names = _categoryNames[id];
    if (names == null) return '';
    return names[lang] ?? names['tk'] ?? names['ru'] ?? '';
  }

  String brandName(int? id) {
    _loaded.value;
    if (id == null) return '';
    return _brandNames[id] ?? '';
  }
}
