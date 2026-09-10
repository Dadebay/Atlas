import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/themes/colors.dart';

/// The one celebratory moment in the app.
///
/// It runs only after the backend has confirmed the order, exactly once, and
/// nowhere else — a delight beat earns its keep by being rare. Under reduced
/// motion it becomes a plain static confirmation, because the information is
/// the word "confirmed", not the movement.
class OrderSuccessOverlay {
  OrderSuccessOverlay._();

  static Future<void> show({
    required String title,
    required String subtitle,
  }) {
    return Get.dialog<void>(
      _OrderSuccessDialog(title: title, subtitle: subtitle),
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: AppMotion.standard,
      transitionCurve: AppMotion.easeOut,
    );
  }
}

class _OrderSuccessDialog extends StatefulWidget {
  const _OrderSuccessDialog({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<_OrderSuccessDialog>
    with SingleTickerProviderStateMixin {
  static const Duration _celebration = Duration(milliseconds: 520);
  static const Duration _visibleFor = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _celebration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppMotion.reduceMotion(context)) _controller.forward();
      // The dialog closes itself so a confirmed order never blocks the way
      // back to the catalogue.
      _dismissTimer = Timer(_visibleFor, () {
        if (mounted && Get.isDialogOpen == true) Get.back<void>();
      });
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    // Reduced motion holds the badge at its final state instead of animating.
    final progress =
        reduce ? const AlwaysStoppedAnimation<double>(1.0) : _controller;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: progress,
              builder: (context, child) {
                final t = AppMotion.easeOut.transform(progress.value);
                return Transform.scale(
                  // Starts at 0.88, not 0 — a badge that grows out of nothing
                  // reads as a glitch rather than an arrival.
                  scale: 0.88 + 0.12 * t,
                  child: Opacity(opacity: t, child: child),
                );
              },
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: AppColors.green,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
                color: Color(0xFF14181F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                fontFamily: 'Gilroy',
                color: Color(0xFF7A828F),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back<void>(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'ok'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
