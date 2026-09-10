import 'package:atlas/core/lang/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:atlas/core/services/navigation_service.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/modules/auth/views/phone_auth_view.dart';
import 'package:atlas/modules/splash/views/bootstrap_gate.dart';
import 'package:atlas/utils/global_safe_area_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The only work allowed before the first frame: the local store, because the
  // locale and the session are read synchronously while building the app.
  // Firebase, messaging and notifications now start under BootstrapGate.
  await GetStorage.init();
  Get.put(GetStorage());

  NavigationService.setLoginBuilder(() => const PhoneAuthView());

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
      home: const BootstrapGate(),
      // Platform-native page transitions: Cupertino (with its interactive
      // back swipe) on iOS, the Material 3 transition on Android. Forcing
      // Cupertino everywhere gave Android an edge-swipe it does not expect.
      defaultTransition: Transition.native,
      builder: (context, child) {
        return GlobalSafeAreaWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
