import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:atlas/core/init/local_notifications_service.dart';
import 'package:atlas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:atlas/core/utils/app_log.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._internal();
  factory FirebaseMessagingService.instance() => _instance;
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  LocalNotificationsService? _localNotificationsService;

  Future<void> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    AppLog.d('Foreground message received: ${message.data.toString()}');
    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        message.data.toString(),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    AppLog.d('Notification caused the app to open: ${message.data.toString()}');
  }
}

/// Runs in its own isolate, so it initialises what it needs from scratch and
/// shares no state with the app.
///
/// Data-only pushes carry no `notification` payload, which means the OS will
/// not display anything: those are rendered here through the local
/// notifications plugin.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    AppLog.e('backgroundHandler.firebase', e);
  }

  try {
    final localNotifications = LocalNotificationsService.instance();
    await localNotifications.init();

    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;

    if (message.notification == null && (title != null || body != null)) {
      await localNotifications.showNotification(
        title,
        body,
        jsonEncode(message.data),
      );
    }
  } catch (e) {
    AppLog.e('backgroundHandler.notification', e);
  }
}
