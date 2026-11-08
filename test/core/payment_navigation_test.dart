import 'package:atlas/core/utils/payment_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes only an HTTPS return on the exact host', () {
    const hosts = ['atlas.com.tm'];
    expect(isPaymentReturnUrl('https://atlas.com.tm/payment/return', hosts),
        isTrue);
    for (final url in [
      'http://atlas.com.tm/payment/return',
      'https://atlas.com.tm.evil.example/return',
      'https://evil.example/?next=atlas.com.tm',
      'https://atlas.com.tm@evil.example/return',
    ]) {
      expect(isPaymentReturnUrl(url, hosts), isFalse, reason: url);
    }
  });

  test('rejects HTTP payment pages', () {
    expect(isSecureWebUrl('https://bank.example/pay'), isTrue);
    expect(isSecureWebUrl('http://bank.example/pay'), isFalse);
  });
}
