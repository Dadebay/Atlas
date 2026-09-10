import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/core/utils/app_log.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/pressable.dart';

/// What the customer sees when a screen could not reach the server.
///
/// This is deliberately an in-screen state rather than a dialog or a full-app
/// lock: a dialog has to be dismissed before anything can be read, and locking
/// the whole app behind a DNS check meant a slow network looked like a broken
/// app. Here the rest of the shell — the tabs, the cart, anything already
/// loaded — stays usable, and the failed area explains itself and offers the
/// one action that helps.
class ConnectionErrorView extends StatefulWidget {
  const ConnectionErrorView({
    super.key,
    required this.onRetry,
    this.title,
    this.description,
    this.compact = false,
  });

  /// Awaited, so the button can show progress for as long as the retry runs.
  final Future<void> Function() onRetry;

  final String? title;
  final String? description;

  /// Tighter spacing for use inside a section rather than a whole page.
  final bool compact;

  @override
  State<ConnectionErrorView> createState() => _ConnectionErrorViewState();
}

class _ConnectionErrorViewState extends State<ConnectionErrorView> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } catch (e) {
      // A retry that fails is the expected case here, not an error to escape
      // into the gesture callback — letting it through would put a red screen
      // over an offline device. The caller keeps this view on screen when the
      // retry did not help, which is how the customer learns it failed.
      AppLog.e('ConnectionErrorView.retry', e);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 68.0 : 92.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: widget.compact ? 24 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedWifiDisconnected01,
                  color: AppColors.green,
                  size: widget.compact ? 32 : 44,
                ),
              ),
            ),
            SizedBox(height: widget.compact ? 18 : 26),
            Text(
              widget.title ?? 'connection_error_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.compact ? 18 : 22,
                height: 1.25,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
                color: const Color(0xFF14181F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description ?? 'connection_error_desc'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A828F),
              ),
            ),
            SizedBox(height: widget.compact ? 22 : 30),
            Pressable(
              onTap: _retrying ? null : _retry,
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.fast),
                curve: AppMotion.easeOut,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_retrying) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else ...[
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'retry'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
