import 'dart:convert';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';

class AuthController extends GetxController {
  final CallApi _callApi = CallApi();

  ProfileController get _profileController => Get.find<ProfileController>();

  var isLoading = false.obs;

  // Send OTP code to phone number
  Future<bool> sendCode(String phone) async {
    isLoading.value = true;
    try {
      final formattedPhone = phone.replaceAll(RegExp(r'\D'), ''); // Ensure digits only
      final fullPhone = formattedPhone.startsWith('993') ? formattedPhone : '993$formattedPhone';

      final response = await _callApi.postData({'phone': fullPhone}, Api2.sendCode);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        isLoading.value = false;
        return true;
      } else {
        final errorMsg = body['error']?['phone'] ?? body['message'] ?? 'Error occurred';
        Get.snackbar('attention'.tr, errorMsg.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('attention'.tr, 'connection_error'.tr, snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
    return false;
  }

  // Register user
  Future<bool> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = formattedPhone.startsWith('993') ? formattedPhone : '993$formattedPhone';

      final response = await _callApi.postData({
        'phone': fullPhone,
        'code': code,
        'password': password,
      }, Api2.register);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['access_token'] ?? body['token'];
        final user = body['data'] ?? body['user'] ?? {};
        final name = user['username'] ?? user['name'] ?? 'User';
        
        if (token != null) {
          _profileController.saveLogin(token.toString(), name.toString(), fullPhone);
          isLoading.value = false;
          return true;
        }
      } else {
        final errorMsg = body['error']?['phone'] ?? body['message'] ?? 'Registration failed';
        Get.snackbar('attention'.tr, errorMsg.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('attention'.tr, 'connection_error'.tr, snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
    return false;
  }

  // Login user
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = formattedPhone.startsWith('993') ? formattedPhone : '993$formattedPhone';

      final response = await _callApi.postData({
        'phone': fullPhone,
        'password': password,
      }, Api2.login);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['access_token'] ?? body['token'];
        final user = body['data'] ?? body['user'] ?? {};
        final name = user['username'] ?? user['name'] ?? 'User';

        if (token != null) {
          _profileController.saveLogin(token.toString(), name.toString(), fullPhone);
          isLoading.value = false;
          return true;
        }
      } else {
        final errorMsg = body['error']?['phone'] ?? body['message'] ?? 'wrong_credentials'.tr;
        Get.snackbar('attention'.tr, errorMsg.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('attention'.tr, 'connection_error'.tr, snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
    return false;
  }
}
