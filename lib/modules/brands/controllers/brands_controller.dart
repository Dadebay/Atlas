// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/modules/brands/models/brand_model.dart';

class BrandsController extends GetxController {
  final CallApi _api = CallApi();

  final brands = <BrandModel>[].obs;
  final isLoading = true.obs;
  final errorMsg = ''.obs;

  final selectedBrand = Rxn<BrandModel>();
  final isDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    isLoading.value = true;
    errorMsg.value = '';
    try {
      final response = await _api.getData(Api2.brands);
      print('brands response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final rawList = body['data'] as List;
        print('[Brands] Total count: ${rawList.length}');
        if (rawList.isNotEmpty) {
          print('[Brands] First item keys: ${(rawList[0] as Map).keys.toList()}');
          print('[Brands] First item: ${rawList[0]}');
        }
        final list = rawList
            .map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
        if (list.isNotEmpty) {
          print('[Brands] First brand image URL: "${list[0].image}"');
        }
        brands.value = list;
      } else {
        errorMsg.value = 'error'.tr;
      }
    } catch (e) {
      print('brands error: $e');
      errorMsg.value = 'connection_error'.tr;
    }
    isLoading.value = false;
  }

  Future<void> fetchBrandById(int id) async {
    isDetailLoading.value = true;
    selectedBrand.value = null;
    try {
      final response = await _api.getData(Api2.brandById(id));
      print('brand detail response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        selectedBrand.value =
            BrandModel.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('brand detail error: $e');
    }
    isDetailLoading.value = false;
  }
}
