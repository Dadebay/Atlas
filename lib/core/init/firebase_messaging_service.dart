import 'package:atlas/core/init/local_notifications_service.dart';
import 'package:atlas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._internal();
  factory FirebaseMessagingService.instance() => _instance;
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
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

  Future<void> _handlePushNotificationsToken() async {
    // iOS'ta APNs token hazır olana kadar bekle (max 10 deneme)
    String? apnsToken;
    for (int i = 0; i < 10; i++) {
      try {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      } catch (_) {}
      if (apnsToken != null) break;
      await Future.delayed(const Duration(seconds: 1));
    }
    print('========== APNS TOKEN ==========');
    print(apnsToken ?? 'null (real device required / not ready)');
    print('=================================');

    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      print('========== FCM TOKEN ==========');
      print(fcmToken ?? 'null');
      print('================================');
    } catch (error) {
      print('Failed to fetch FCM token: $error');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      print('========== FCM TOKEN (refreshed) ==========');
      print(fcmToken);
      print('===========================================');
    }).onError((error) {});
  }

  Future<void> _requestPermission() async {
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${result.authorizationStatus}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.data.toString()}');
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
    print('Notification caused the app to open: ${message.data.toString()}');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  print('Background message received: ${message.data.toString()}');
}
