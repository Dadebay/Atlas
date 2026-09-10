import 'package:flutter/material.dart';

import 'package:atlas/core/init/app_bootstrap.dart';
import 'package:atlas/core/services/push_registration.dart';
import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/modules/main/bindings/main_binding.dart';
import 'package:atlas/modules/main/views/main_screen.dart';
import 'package:atlas/modules/splash/views/splash_brand.dart';

/// The app's first route.
///
/// It replaces the old splash screen, which spent a fixed 2800 ms on a fake
/// percentage bar and then a DNS lookup before anything could be used. Here the
/// shell is registered and built immediately; the branded frame exists only to
/// cross-fade out of the native launch screen, and the background services
/// attach underneath it.
class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  bool _showShell = false;

  @override
  void initState() {
    super.initState();

    // Synchronous and cheap — everything here is lazy except the catalogue
    // service and AuthController, so the shell can build on the next frame.
    MainBinding().dependencies();

    // Non-blocking. Firebase failing must not keep the catalogue off screen.
    AppBootstrap.instance.start().then((_) {
      // Silent: this only registers a token when permission already exists.
      // The prompt itself is asked for later, in context.
      PushRegistration.instance.ensureRegistered();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showShell = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.standard),
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      child: _showShell ? const MainScreen(key: ValueKey('shell')) : const SplashBrand(key: ValueKey('brand')),
    );
  }
}
