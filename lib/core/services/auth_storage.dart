import 'package:get_storage/get_storage.dart';

class AuthStorage {
  final GetStorage _storage = GetStorage();

  String? get token => _storage.read<String>('AccessToken');
  void saveToken(String token) => _storage.write('AccessToken', token);

  String? get name => _storage.read<String>('UserName');
  void saveName(String name) => _storage.write('UserName', name);

  String? get phone => _storage.read<String>('UserPhone');
  void savePhone(String phone) => _storage.write('UserPhone', phone);

  void clear() {
    _storage.remove('AccessToken');
    _storage.remove('UserName');
    _storage.remove('UserPhone');
  }

  bool get isLoggedIn => token != null;
}
