import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:atlas/core/services/fcm_token_local_storage.dart';
import 'package:atlas/core/utils/app_log.dart';

class FcmTokenProvider {
  FcmTokenProvider();

  final _fcmTokenStorage = const FcmTokenLocalStorage();
  final _tokenNotifier = ValueNotifier<String?>(null);
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;

  ValueNotifier<String?> get token => _tokenNotifier;

  Future<void> init() async {
    AppLog.d('FcmTokenProvider initializing...');
    await _getToken();
    _attachTokenRefreshListener();
  }

  Future<void> _getToken() async {
    try {
      final savedToken = _fcmTokenStorage.getToken();
      if (savedToken != null) {
        _tokenNotifier.value = savedToken;
      }

      // iOS'ta APNs token hazır olmadan FCM token alınamaz, kısa bekle
      String? newToken;
      for (int i = 0; i < 5; i++) {
        try {
          newToken = await _fcm.getToken().timeout(
                const Duration(seconds: 5),
                onTimeout: () => null,
              );
        } catch (_) {}
        if (newToken != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (newToken != null) {
        if (newToken != savedToken) {
          AppLog.d('FCM new token: $newToken');
          await _fcmTokenStorage.setToken(newToken);
          _tokenNotifier.value = newToken;
        }
      } else {
        AppLog.d('FCM token unavailable (simulator or no network)');
      }
    } catch (e) {
      AppLog.d('FCM token error (non-fatal): $e');
    }
  }

  Future<void> removeToken() async {
    await _fcmTokenStorage.clearToken();
    _tokenNotifier.value = null;
  }

  void _attachTokenRefreshListener() {
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
      await _fcmTokenStorage.setToken(newToken);
      _tokenNotifier.value = newToken;
    });
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenNotifier.dispose();
  }
}
