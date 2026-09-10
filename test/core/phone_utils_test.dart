import 'package:atlas/core/utils/phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneUtils.toApi', () {
    test('produces the exact E.164 string the OTP cache is keyed on', () {
      expect(PhoneUtils.toApi('65010203'), '+99365010203');
      expect(PhoneUtils.toApi('+993 65 01 02 03'), '+99365010203');
      expect(PhoneUtils.toApi('99365010203'), '+99365010203');
    });

    test('returns empty for an incomplete number rather than a bad key', () {
      expect(PhoneUtils.toApi('650102'), '');
      expect(PhoneUtils.toApi(''), '');
      expect(PhoneUtils.toApi(null), '');
    });
  });

  group('PhoneUtils.toLocal', () {
    test('keeps the eight local digits', () {
      expect(PhoneUtils.toLocal('+99365010203'), '65010203');
      expect(PhoneUtils.toLocal('65010203'), '65010203');
    });

    test('does not eat a local number that merely starts with 993', () {
      expect(PhoneUtils.toLocal('99312345'), '99312345');
    });
  });

  test('toDisplay groups the digits in pairs', () {
    expect(PhoneUtils.toDisplay('+99365010203'), '+993 65 01 02 03');
    expect(PhoneUtils.toDisplay(''), '');
  });
}
