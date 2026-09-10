import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/shared/no_internet_screen.dart';
import 'fcm_token_provider.dart';
import 'package:atlas/core/utils/app_log.dart';

class FcmTokenSynchronizer {
  const FcmTokenSynchronizer(this._fcmTokenProvider);

  final FcmTokenProvider _fcmTokenProvider;

  void init() {
    AppLog.d('FcmTokenSynchronizer initializing...');
    _attachFcmTokenUpdateListener();

    if (_fcmTokenProvider.token.value != null) {
      _sendTokenToServer(fcmToken: _fcmTokenProvider.token.value);
    }
  }

  void _attachFcmTokenUpdateListener() {
    _fcmTokenProvider.token.addListener(() {
      _sendTokenToServer(fcmToken: _fcmTokenProvider.token.value);
    });
  }

  Future<void> setTokenForUser() async {
    final fcmToken = _fcmTokenProvider.token.value;
    if (fcmToken == null) return;
    await _sendTokenToServer(fcmToken: fcmToken);
  }

  Future<void> _sendTokenToServer({required String? fcmToken}) async {
    if (fcmToken == null) {
      if (kDebugMode) AppLog.d('FCM token null, skipping sync.');
      return;
    }

    final userToken = AuthStorage().token;
    if (userToken == null) {
      AppLog.d('User not logged in, skipping FCM sync.');
      return;
    }

    AppLog.d('Sending FCM token to server: $fcmToken');

    try {
      await CallApi().patchToken(
        {'fcm_token': fcmToken},
        Api2.fcmToken,
        userToken,
      );
    } on SocketException catch (_) {
      _goNoInternet();
    } on TimeoutException catch (_) {
      _goNoInternet();
    } catch (e, s) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('no address associated') ||
          msg.contains('connection refused') ||
          msg.contains('network is unreachable')) {
        _goNoInternet();
      } else {
        AppLog.e('FcmTokenSynchronizer', e, s);
      }
    }
  }

  void _goNoInternet() {
    if (Get.context == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        Get.offAll(() => const NoInternetScreen());
      }
    });
  }
}
