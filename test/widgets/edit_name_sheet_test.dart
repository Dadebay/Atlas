import 'package:flutter_test/flutter_test.dart';

void main() {
  // The sheet splits `username` into two fields on the way in and joins them on
  // the way out, because the API stores both halves in one string.
  (String, String) split(String username) {
    final parts = username.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return ('', '');
    return (parts.first, parts.skip(1).join(' '));
  }

  String join(String first, String last) =>
      [first.trim(), last.trim()].where((p) => p.isNotEmpty).join(' ');

  group('username split/join', () {
    test('a two-part name round-trips', () {
      final (first, last) = split('Aman Amanow');
      expect(first, 'Aman');
      expect(last, 'Amanow');
      expect(join(first, last), 'Aman Amanow');
    });

    test('a three-part name keeps everything after the first as the surname',
        () {
      final (first, last) = split('Aman Baba Amanow');
      expect(first, 'Aman');
      expect(last, 'Baba Amanow');
      expect(join(first, last), 'Aman Baba Amanow');
    });

    test('an empty username yields two empty fields', () {
      expect(split(''), ('', ''));
      expect(split('   '), ('', ''));
    });

    test('a first name on its own is a valid username', () {
      expect(join('Aman', ''), 'Aman');
      expect(join('Aman', '   '), 'Aman');
    });

    test('extra whitespace does not survive the round trip', () {
      final (first, last) = split('  Aman    Amanow  ');
      expect(join(first, last), 'Aman Amanow');
    });
  });
}
