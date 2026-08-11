// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';

class RegisterController extends GetxController {
  final CallApi _callApi = CallApi();

  ProfileController get _profileController => Get.find<ProfileController>();

  var isLoading = false.obs;
  String? lastOtp;

  Future<bool> sendCode(String phone) async {
    isLoading.value = true;
    lastOtp = null;
    try {
      final fullPhone = _formatPhone(phone);
      final response =
          await _callApi.postData({'phone': fullPhone}, Api2.sendCode);
      final body = jsonDecode(response.body);
      print('[OTP] status: ${response.statusCode}');
      print('[OTP] raw body: ${response.body}');
      print('[OTP] body keys: ${body.keys.toList()}');
      if (body['data'] != null) print('[OTP] data: ${body['data']}');
      final otp = body['code'] ??
          body['otp'] ??
          body['data']?['code'] ??
          body['data']?['otp'] ??
          body['data']?['random'];
      print('[OTP] extracted otp: $otp');
      if (otp != null) {
        lastOtp = otp.toString();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        isLoading.value = false;
        return true;
      } else {
        final errorMsg =
            body['error']?['phone'] ?? body['message'] ?? 'Error occurred';
        _showError(errorMsg.toString());
      }
    } catch (e) {
      _showError('connection_error'.tr);
    }
    isLoading.value = false;
    return false;
  }

  Future<bool> register({
    required String phone,
    required String code,
    required String password,
    required String username,
  }) async {
    isLoading.value = true;
    try {
      final fullPhone = _formatPhone(phone);
      final response = await _callApi.postData({
        'phone': fullPhone,
        'code': code,
        'password': password,
        'username': username,
      }, Api2.register);
      final body = jsonDecode(response.body);
      print('register response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = body['data'] ?? {};
        final token = data['accessToken'] ??
            data['access_token'] ??
            body['access_token'] ??
            body['token'];
        final user = data['user'] ?? data ?? {};
        final name = user['username'] ?? user['name'] ?? username;

        if (token != null) {
          _profileController.saveLogin(
              token.toString(), name.toString(), fullPhone);
          isLoading.value = false;
          return true;
        }
      } else {
        final errorMsg = body['error']?['phone'] ??
            body['error']?['username'] ??
            body['message'] ??
            'Registration failed';
        _showError(errorMsg.toString());
      }
    } catch (e) {
      _showError('connection_error'.tr);
    }
    isLoading.value = false;
    return false;
  }

  void _showError(String message) {
    Get.snackbar(
      'attention'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      duration: const Duration(seconds: 3),
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('993') ? digits : '993$digits';
  }
}
