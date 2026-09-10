import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/services/navigation_service.dart';
import 'package:atlas/core/utils/app_log.dart';

class CallApi {
  String get _lang => Get.locale?.languageCode ?? 'tk';

  String _buildUrl(String apiUrl) {
    final baseUrl = Api2.baseUrl.endsWith('/')
        ? Api2.baseUrl.substring(0, Api2.baseUrl.length - 1)
        : Api2.baseUrl;
    final path = apiUrl.startsWith('/') ? apiUrl : '/$apiUrl';
    return '$baseUrl$path';
  }

  Map<String, String> _buildHeaders({String? bearerToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': _lang,
    };
    final token = bearerToken ?? AuthStorage().token;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// There is no refresh token: a 401 means the session is gone for good, so
  /// the stored token is dropped and the customer is sent back to the phone
  /// step. Catalogue endpoints take the header optionally and never 401, so
  /// this only fires on genuinely protected calls.
  http.Response _guardSession(http.Response response) {
    if (response.statusCode == 401 && AuthStorage().token != null) {
      AuthStorage().clear();
      NavigationService.goToLogin();
    }
    return response;
  }

  Future<http.Response> getData(String apiUrl) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('GET $url  [lang=$_lang]');
    return _guardSession(
        await http.get(Uri.parse(url), headers: _buildHeaders()));
  }

  Future<http.Response> postData(
      Map<String, dynamic> data, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('POST $url  [lang=$_lang]');
    return _guardSession(await http.post(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(),
    ));
  }

  Future<http.Response> patchData(
      Map<String, dynamic> data, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('PATCH $url  [lang=$_lang]');
    return _guardSession(await http.patch(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(),
    ));
  }

  Future<http.Response> deleteData(String apiUrl) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('DELETE $url  [lang=$_lang]');
    return _guardSession(
        await http.delete(Uri.parse(url), headers: _buildHeaders()));
  }

  // FCM token — uses explicit token, not stored auth token
  Future<http.Response> postToken(
    Map<String, dynamic> data,
    String apiUrl,
    String token,
  ) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('FCM POST $url');
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(bearerToken: token),
    );
    AppLog.d('FCM response: ${response.statusCode}');
    return response;
  }

  /// PATCH with an explicit bearer token — used by the FCM sync, which can run
  /// before the stored token has been read back.
  Future<http.Response> patchToken(
    Map<String, dynamic> data,
    String apiUrl,
    String token,
  ) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('FCM PATCH $url');
    final response = await http.patch(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(bearerToken: token),
    );
    AppLog.d('FCM response: ${response.statusCode}');
    return response;
  }

  Future<http.Response> uploadFile(File file, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    AppLog.d('MULTIPART POST $url');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      final headers = _buildHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      AppLog.d('MULTIPART response: ${response.statusCode}');
      return response;
    } catch (e) {
      AppLog.d('MULTIPART error: $e');
      rethrow;
    }
  }
}
