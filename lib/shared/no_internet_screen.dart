import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:atlas/modules/splash/views/bootstrap_gate.dart';
import 'package:atlas/shared/connection_error_view.dart';

/// The whole-app offline screen.
///
/// Reserved for the case where nothing at all can be shown. Normal fetch
/// failures use [ConnectionErrorView] inside the screen that failed, so the
/// tabs and anything already loaded stay usable — the app no longer replaces
/// itself with this page just because one request did not come back.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  Future<void> _retry() async {
    var reachable = false;
    try {
      // Atlas' own host, not google.com — that one is blocked in Turkmenistan,
      // so it would report "no internet" on a perfectly working connection.
      final result = await InternetAddress.lookup('atlas.com.tm')
          .timeout(const Duration(milliseconds: 1500));
      reachable = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on TimeoutException catch (_) {
      reachable = false;
    } catch (_) {
      reachable = false;
    }

    if (reachable) {
      Get.offAll(() => const BootstrapGate());
    } else {
      Get.snackbar(
        'connection_error_title'.tr,
        'connection_error_desc'.tr,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: ConnectionErrorView(onRetry: _retry)),
    );
  }
}
