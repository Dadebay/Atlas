import 'package:flutter/foundation.dart';

/// Debug-only logging.
///
/// Every call compiles down to nothing outside a debug build, so a log can
/// never cost a frame in profile or release. Two rules go with it:
///
/// * Never log a response body, a token, a phone number or anything else the
///   customer would not want in a crash report.
/// * Never log from a scroll listener, a build method or an item builder —
///   even a free call still builds the interpolated string.
abstract final class AppLog {
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void e(String source, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('$source failed: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
