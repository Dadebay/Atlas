import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class AuthStorage {
  final GetStorage _storage = GetStorage();

  /// JWT issued by `users/otp-login`. HS256, 30 day lifetime, no refresh token —
  /// once it expires the customer goes back through the SMS flow.
  String? get token => _storage.read<String>('AccessToken');
  void saveToken(String token) => _storage.write('AccessToken', token);

  String? get name => _storage.read<String>('UserName');
  void saveName(String name) => _storage.write('UserName', name);

  /// Stored in the exact API format: `+993XXXXXXXX`.
  String? get phone => _storage.read<String>('UserPhone');
  void savePhone(String phone) => _storage.write('UserPhone', phone);

  int? get userId => _storage.read<int>('UserId');
  void saveUserId(int id) => _storage.write('UserId', id);

  void clear() {
    _storage.remove('AccessToken');
    _storage.remove('UserName');
    _storage.remove('UserPhone');
    _storage.remove('UserId');
  }

  bool get isLoggedIn => token != null && !isTokenExpired;

  /// Decodes the JWT `exp` locally so an obviously dead session never costs a
  /// round trip. A token we cannot parse is treated as still valid and left for
  /// the server to reject with a 401.
  bool get isTokenExpired {
    final raw = _storage.read<String>('AccessToken');
    if (raw == null) return true;
    final expiry = _expiryOf(raw);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  static DateTime? _expiryOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }
}
