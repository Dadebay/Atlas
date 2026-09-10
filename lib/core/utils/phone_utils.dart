import 'package:flutter/services.dart';

/// Turkmenistan phone numbers: the +993 country code is fixed and never part of
/// what the user types, so input fields only ever hold the 8 local digits.
class PhoneUtils {
  const PhoneUtils._();

  static const String countryCode = '993';
  static const String displayPrefix = '+993';
  static const int localLength = 8;

  /// Strips formatting and the country code → the 8 digits shown in the field.
  static String toLocal(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    // Only strip 993 when there is more than a local number's worth of digits.
    // A perfectly valid local number can itself begin with 993, and stripping
    // that would silently key the OTP cache to the wrong phone.
    if (digits.length > localLength && digits.startsWith(countryCode)) {
      digits = digits.substring(countryCode.length);
    }
    if (digits.length > localLength) {
      digits = digits.substring(digits.length - localLength);
    }
    return digits;
  }

  /// Full number in the exact E.164 form the API expects: `+993XXXXXXXX`.
  ///
  /// The server uses this string verbatim as the cache key for the issued OTP,
  /// so `send-code` and `otp-login` must be given the identical string.
  /// Returns an empty string when the number is not complete.
  static String toApi(String? raw) {
    final local = toLocal(raw);
    return local.length == localLength ? '+$countryCode$local' : '';
  }

  /// Human readable: `+993 65 01 02 03`.
  static String toDisplay(String? raw) {
    final local = toLocal(raw);
    if (local.isEmpty) return '';
    final groups = <String>[];
    for (var i = 0; i < local.length; i += 2) {
      groups.add(local.substring(i, (i + 2).clamp(0, local.length)));
    }
    return '$displayPrefix ${groups.join(' ')}';
  }

  static bool isValidLocal(String? localDigits) =>
      toLocal(localDigits).length == localLength;

  /// Keeps the field digits-only and capped at the local length, so the
  /// prefix can neither be typed over nor deleted.
  static final List<TextInputFormatter> inputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(localLength),
  ];
}
