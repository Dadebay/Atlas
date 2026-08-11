// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:atlas/core/init/firebase_messaging_service.dart';
import 'package:atlas/core/init/local_notifications_service.dart';
import 'package:atlas/core/lang/app_translations.dart';
import 'package:atlas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:atlas/core/services/navigation_service.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/modules/auth/views/login_view.dart';
import 'package:atlas/modules/splash/views/splash_screen.dart';
import 'package:atlas/utils/global_safe_area_wrapper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('FCM background message received');
  print('Data: ${message.data}');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

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
    print('Background notification error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(GetStorage());
  NavigationService.setLoginBuilder(() => const LoginView());

  // Local notifications başlatmak
  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  bool firebaseReady = false;

  try {
    print('Firebase initializing...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
    print('Firebase ready.');
  } catch (e) {
    print('Firebase init error: $e');
  }

  if (firebaseReady) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      unawaited(
        FirebaseMessaging.instance.subscribeToTopic('ALL').catchError((_) {}),
      );

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      final firebaseMessagingService = FirebaseMessagingService.instance();
      await firebaseMessagingService.init(
        localNotificationsService: localNotificationsService,
      );
    } catch (e) {
      print('Firebase services error: $e');
    }
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const AtlasApp());
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<GetStorage>();
    String langCode = storage.read('langCode') ?? 'tk';

    return GetMaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: Locale(langCode),
      fallbackLocale: const Locale('tk'),
      home: const SplashScreen(),
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        return GlobalSafeAreaWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
