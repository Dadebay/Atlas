import 'package:flutter/services.dart';

/// Turkmenistan phone numbers: the +993 country code is fixed and never part of
/// what the user types, so input fields only ever hold the 8 local digits.
class PhoneUtils {
  const PhoneUtils._();

  static const String countryCode = '993';
  static const String displayPrefix = '+993 ';
  static const int localLength = 8;

  /// Strips formatting and the country code → the 8 digits shown in the field.
  static String toLocal(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(countryCode)) {
      digits = digits.substring(countryCode.length);
    }
    if (digits.length > localLength) {
      digits = digits.substring(digits.length - localLength);
    }
    return digits;
  }

  /// Full number in the format the API expects: 993XXXXXXXX.
  static String toApi(String localDigits) =>
      '$countryCode${toLocal(localDigits)}';

  static bool isValidLocal(String? localDigits) =>
      toLocal(localDigits).length == localLength;

  /// Keeps the field digits-only and capped at the local length, so the
  /// prefix can neither be typed over nor deleted.
  static final List<TextInputFormatter> inputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(localLength),
  ];
}
