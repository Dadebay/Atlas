import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:atlas/core/init/app_bootstrap.dart';
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/utils/app_log.dart';

/// Owns the notification permission prompt and the FCM token round trip.
///
/// The prompt is deliberately NOT fired at cold start over the logo. A customer
/// who has not seen the app yet has no reason to say yes, so [ensureRegistered]
/// stays silent unless permission already exists and [requestAndRegister] is
/// called from a moment that explains itself — right after signing in, where
/// order updates are the obvious payoff.
class PushRegistration {
  PushRegistration._();

  static final PushRegistration instance = PushRegistration._();

  bool _syncing = false;

  /// Registers the token only if the customer has already granted permission.
  /// Never shows a system prompt.
  Future<void> ensureRegistered() async {
    if (!AppBootstrap.instance.isFirebaseReady) return;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      await _syncToken();
    } catch (e) {
      AppLog.e('PushRegistration.ensureRegistered', e);
    }
  }

  /// Shows the system prompt, then registers if the customer agreed.
  /// Call this from a screen that has just explained why it is asking.
  Future<bool> requestAndRegister() async {
    if (!AppBootstrap.instance.isFirebaseReady) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) await _syncToken();
      return granted;
    } catch (e) {
      AppLog.e('PushRegistration.requestAndRegister', e);
      return false;
    }
  }

  Future<void> _syncToken() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // On iOS the FCM token is only obtainable once APNs has handed one over.
      // Poll briefly instead of the old fixed ten-second wall.
      if (Platform.isIOS && await _awaitApnsToken() == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final storage = Get.find<GetStorage>();
      final alreadySent = storage.read<String>('fcm_token') == fcmToken;
      storage.write('fcm_token', fcmToken);

      final userToken = AuthStorage().token;
      if (userToken == null || alreadySent) return;

      await CallApi().patchToken(
        {'fcm_token': fcmToken},
        Api2.fcmToken,
        userToken,
      );
    } catch (e) {
      AppLog.e('PushRegistration.syncToken', e);
    } finally {
      _syncing = false;
    }
  }

  Future<String?> _awaitApnsToken() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }
}
