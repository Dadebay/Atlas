import 'dart:async';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/core/services/api_result.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/push_registration.dart';
import 'package:atlas/core/utils/phone_utils.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/core/utils/app_log.dart';

/// Outcome of verifying an SMS code.
enum OtpResult {
  /// Signed in. A phone the server had never seen was registered on the way
  /// through, which is why there is no separate outcome for a new account.
  signedIn,

  /// The code was wrong, already used or expired.
  invalidCode,

  /// Network or server failure; a message has already been shown.
  failed,
}

/// Passwordless authentication.
///
/// The SMS code is the only credential: an unknown phone number is registered
/// automatically the first time its code is verified, so there is no separate
/// registration step and no password anywhere in the customer flow.
class AuthController extends GetxController {
  final CallApi _callApi = CallApi();
  final AuthStorage _authStorage = AuthStorage();

  ProfileController get _profileController => Get.find<ProfileController>();

  /// Codes live 180 seconds from the *first* request for a number — the window
  /// does not extend on resend.
  static const int codeLifetimeSeconds = 180;

  /// The 5th request inside a window is rejected by the server.
  static const int maxSendAttempts = 4;

  final RxBool isSendingCode = false.obs;
  final RxBool isVerifying = false.obs;
  final RxBool isSavingProfile = false.obs;

  /// Seconds left on the current code window; 0 when there is no live code.
  final RxInt secondsLeft = 0.obs;

  /// How many codes have been requested inside the current window.
  final RxInt sendAttempts = 0.obs;

  /// The last error worth showing inline on the OTP screen.
  final RxnString codeError = RxnString();

  /// Phone in API format (`+993XXXXXXXX`) for the flow in progress.
  String phone = '';

  Timer? _ticker;

  bool get isWindowOpen => secondsLeft.value > 0;

  /// Resending inside a live window is capped at [maxSendAttempts]; once the
  /// window has expired a fresh request always starts a new one.
  bool get canResend => !isWindowOpen || sendAttempts.value < maxSendAttempts;

  @override
  void onInit() {
    super.onInit();
    // `otp-login` may omit the optional columns on a brand new account, so the
    // canonical record is pulled once per launch for an existing session.
    if (_authStorage.isLoggedIn) unawaited(fetchMe());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  //==================== 1. Request an SMS code ====================//

  /// Sends a 4 digit code to [rawPhone] (accepts the 8 local digits or a full
  /// number). Returns true when the SMS was accepted for delivery.
  ///
  /// A resend inside a live window does NOT restart the countdown — the server
  /// expires every code 180 seconds after the *first* request for the number.
  Future<bool> sendCode(String rawPhone) async {
    final apiPhone = PhoneUtils.toApi(rawPhone);
    if (apiPhone.isEmpty) {
      _showError('invalid_phone_number'.tr);
      return false;
    }

    // A different number means a fresh window.
    if (apiPhone != phone) {
      _resetWindow();
      phone = apiPhone;
    }

    isSendingCode.value = true;
    codeError.value = null;
    try {
      final wasWindowOpen = isWindowOpen;
      final response = await _callApi.postData({'phone': phone}, Api2.sendCode);
      if (ApiResult.isSuccess(response)) {
        // `data.random` echoes the OTP back — a known server side hole that is
        // being removed. Never read it, never prefill the field with it.
        if (wasWindowOpen) {
          sendAttempts.value += 1;
        } else {
          // The expired window took the old request counter with it.
          _startWindow();
          sendAttempts.value = 1;
        }
        return true;
      }

      final message = ApiResult.errorMessage(response, 'unknown_error'.tr);
      _showError(_translateSendError(message, response.statusCode));
      return false;
    } catch (e) {
      AppLog.d('sendCode error: $e');
      _showError('connection_error'.tr);
      return false;
    } finally {
      isSendingCode.value = false;
    }
  }

  String _translateSendError(String raw, int status) {
    final lower = raw.toLowerCase();
    if (lower.contains('out of try')) return 'otp_too_many_requests'.tr;
    if (status == 503 || lower.contains('failed to send sms')) {
      return 'otp_sms_failed'.tr;
    }
    return raw;
  }

  //==================== 2. Verify the code ====================//

  /// Verifies [code] against the stored [phone], signing the customer in and
  /// registering them when the number is new.
  Future<OtpResult> verifyCode(String code) async {
    if (phone.isEmpty) return OtpResult.failed;

    isVerifying.value = true;
    codeError.value = null;
    try {
      final response = await _callApi.postData(
        // The API rejects a numeric `code`; it must be sent as a string.
        {'phone': phone, 'code': code},
        Api2.otpLogin,
      );

      // A wrong or expired code arrives as 404 — not 401 or 400. Both are
      // handled so the client survives the server side fix that is planned.
      if (response.statusCode == 404 || response.statusCode == 401) {
        codeError.value = 'otp_invalid_code'.tr;
        return OtpResult.invalidCode;
      }

      if (!ApiResult.isSuccess(response)) {
        _showError(ApiResult.errorMessage(response, 'unknown_error'.tr));
        return OtpResult.failed;
      }

      final data = ApiResult.unwrap(response);
      if (data is! Map) {
        _showError('unknown_error'.tr);
        return OtpResult.failed;
      }

      final token = data['accessToken'];
      if (token is! String || token.isEmpty) {
        _showError('unknown_error'.tr);
        return OtpResult.failed;
      }

      final user = data['user'];
      // On a brand new account the optional columns are absent from the JSON
      // entirely rather than present-and-null, so read them defensively.
      final username = user is Map ? user['username'] as String? : null;
      final id = user is Map ? user['id'] : null;

      _authStorage.saveToken(token);
      if (id is int) _authStorage.saveUserId(id);
      _profileController.saveLogin(token, username ?? '', phone);

      // A successful login wipes every code for the number.
      _resetWindow();

      unawaited(registerForPush());

      return OtpResult.signedIn;
    } catch (e) {
      AppLog.d('verifyCode error: $e');
      _showError('connection_error'.tr);
      return OtpResult.failed;
    } finally {
      isVerifying.value = false;
    }
  }

  //==================== 3. Profile ====================//

  /// GET /users/me — the canonical record for the signed in customer.
  Future<Map<String, dynamic>?> fetchMe() async {
    if (!_authStorage.isLoggedIn) return null;
    try {
      final response = await _callApi.getData(Api2.me);
      if (response.statusCode == 401) {
        handleUnauthorized();
        return null;
      }
      if (!ApiResult.isSuccess(response)) return null;

      final data = ApiResult.unwrap(response);
      if (data is! Map) return null;

      // The endpoint still returns a bcrypt `password` hash. It is meaningless
      // for passwordless accounts and is being removed — drop it here so it
      // never reaches the rest of the app.
      final user = Map<String, dynamic>.from(data)..remove('password');

      final username = user['username'] as String?;
      final userPhone = user['phone'] as String?;
      final id = user['id'];
      if (username != null && username.isNotEmpty) {
        _authStorage.saveName(username);
      }
      if (userPhone != null && userPhone.isNotEmpty) {
        _authStorage.savePhone(userPhone);
      }
      if (id is int) _authStorage.saveUserId(id);
      _profileController.checkLoginState();

      return user;
    } catch (e) {
      AppLog.d('fetchMe error: $e');
      return null;
    }
  }

  /// PATCH /users — `username` is the only writable field. First and last name
  /// are stored joined together in this single string.
  Future<bool> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;

    isSavingProfile.value = true;
    try {
      final response =
          await _callApi.patchData({'username': trimmed}, Api2.updateUser);
      if (response.statusCode == 401) {
        handleUnauthorized();
        return false;
      }
      if (!ApiResult.isSuccess(response)) {
        _showError(ApiResult.errorMessage(response, 'unknown_error'.tr));
        return false;
      }

      _authStorage.saveName(trimmed);
      _profileController.checkLoginState();
      return true;
    } catch (e) {
      AppLog.d('updateUsername error: $e');
      _showError('connection_error'.tr);
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  /// Asks for notification permission and registers the token.
  ///
  /// This is the contextual moment the cold-start prompt was moved to: the
  /// customer has just created or opened an account, so order updates are an
  /// answer they can actually weigh.
  Future<void> registerForPush() =>
      PushRegistration.instance.requestAndRegister();

  //==================== Session ====================//

  /// Clears the dead session. There is no refresh endpoint, so the customer has
  /// to go through the SMS flow again.
  void handleUnauthorized() {
    _profileController.logout();
    _resetWindow();
  }

  void logout() => handleUnauthorized();

  //==================== Countdown ====================//

  void _startWindow() {
    _ticker?.cancel();
    secondsLeft.value = codeLifetimeSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        timer.cancel();
      } else {
        secondsLeft.value -= 1;
      }
    });
  }

  void _resetWindow() {
    _ticker?.cancel();
    _ticker = null;
    secondsLeft.value = 0;
    sendAttempts.value = 0;
    codeError.value = null;
  }

  /// Starts the flow over for a new number.
  void reset() {
    _resetWindow();
    phone = '';
  }

  String get countdownLabel {
    final total = secondsLeft.value;
    final minutes = (total ~/ 60).toString();
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showError(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      'attention'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE53935),
      colorText: const Color(0xFFFFFFFF),
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Color(0xFFFFFFFF), size: 26),
      duration: const Duration(seconds: 3),
    );
  }
}
