// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/themes/colors.dart';

class LoginController extends GetxController {
  final CallApi _callApi = CallApi();

  ProfileController get _profileController => Get.find<ProfileController>();

  var isLoading = false.obs;

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final fullPhone = _formatPhone(phone);
      final response = await _callApi.postData({
        'phone': fullPhone,
        'password': password,
      }, Api2.login);
      final body = jsonDecode(response.body);
      print('login response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = body['data'] ?? {};
        final token = data['accessToken'] ?? data['access_token'] ?? body['access_token'] ?? body['token'];
        final user = data['user'] ?? data ?? {};
        final name = user['username'] ?? user['name'] ?? 'User';

        if (token != null) {
          _profileController.saveLogin(token.toString(), name.toString(), fullPhone);
          isLoading.value = false;
          return true;
        }
      } else {
        final rawMsg = body['message']?.toString() ?? '';
        _showErrorDialog(_translateError(rawMsg));
      }
    } catch (e) {
      _showErrorDialog('connection_error'.tr);
    }
    isLoading.value = false;
    return false;
  }

  String _translateError(String rawMsg) {
    final lower = rawMsg.toLowerCase();
    if (lower.contains('invalid password') || lower.contains('wrong password')) {
      return 'wrong_password'.tr;
    }
    if (lower.contains('not found') || lower.contains('not registered') || lower.contains('no user')) {
      return 'phone_not_registered'.tr;
    }
    if (lower.contains('unauthorized')) {
      return 'wrong_credentials'.tr;
    }
    if (rawMsg.isEmpty) return 'unknown_error'.tr;
    return rawMsg;
  }

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
            const SizedBox(height: 12),
            Text(
              'attention'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Gilroy',
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'ok'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('993') ? digits : '993$digits';
  }
}
