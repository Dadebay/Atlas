import 'package:get_storage/get_storage.dart';

const _fcmTokenKey = 'fcm_token';

class FcmTokenLocalStorage {
  const FcmTokenLocalStorage();

  GetStorage _getStorage() => GetStorage();

  String? getToken() => _getStorage().read<String>(_fcmTokenKey);

  Future<void> setToken(String token) async =>
      await _getStorage().write(_fcmTokenKey, token);

  Future<void> clearToken() async => await _getStorage().remove(_fcmTokenKey);
}
