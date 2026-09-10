import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:atlas/core/init/firebase_messaging_service.dart';
import 'package:atlas/core/init/local_notifications_service.dart';
import 'package:atlas/core/utils/app_log.dart';
import 'package:atlas/firebase_options.dart';

/// Everything the app needs that the first frame does NOT.
///
/// None of this blocks `runApp`: the shopping shell is drawn immediately and
/// these services attach underneath it. A failure here is non-fatal by design —
/// a broken Firebase config must never cost the customer the catalogue.
class AppBootstrap {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  Future<void>? _running;

  /// True once Firebase came up. Read it to decide whether push is available;
  /// never to decide whether the app can be used.
  bool get isFirebaseReady => _firebaseReady;
  bool _firebaseReady = false;

  /// Idempotent: calling this from several places (or twice from the same
  /// gate rebuilding) initialises the services exactly once and hands every
  /// caller the same future.
  Future<void> start() => _running ??= _start();

  Future<void> _start() async {
    await _initLocalNotifications();
    await _initFirebase();
  }

  Future<void> _initLocalNotifications() async {
    try {
      await LocalNotificationsService.instance().init();
    } catch (e) {
      AppLog.e('AppBootstrap.localNotifications', e);
    }
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (e) {
      AppLog.e('AppBootstrap.firebase', e);
      return;
    }

    try {
      // Foreground presentation is muted because LocalNotificationsService
      // renders these itself; changing it here would double every alert.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      await FirebaseMessagingService.instance().init(
        localNotificationsService: LocalNotificationsService.instance(),
      );

      // Fire and forget: topic subscription must not hold up the bootstrap.
      unawaited(
        FirebaseMessaging.instance.subscribeToTopic('ALL').catchError((_) {}),
      );
    } catch (e) {
      AppLog.e('AppBootstrap.messaging', e);
    }
  }
}
