// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:atlas/core/services/api_2.dart';
import 'package:atlas/core/services/auth_storage.dart';

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

  Future<http.Response> getData(String apiUrl) async {
    final url = _buildUrl(apiUrl);
    print('GET $url  [lang=$_lang]');
    return http.get(Uri.parse(url), headers: _buildHeaders());
  }

  Future<http.Response> postData(
      Map<String, dynamic> data, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    print('POST $url  [lang=$_lang]');
    return http.post(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(),
    );
  }

  Future<http.Response> patchData(
      Map<String, dynamic> data, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    print('PATCH $url  [lang=$_lang]');
    return http.patch(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(),
    );
  }

  Future<http.Response> deleteData(String apiUrl) async {
    final url = _buildUrl(apiUrl);
    print('DELETE $url  [lang=$_lang]');
    return http.delete(Uri.parse(url), headers: _buildHeaders());
  }

  // FCM token — uses explicit token, not stored auth token
  Future<http.Response> postToken(
    Map<String, dynamic> data,
    String apiUrl,
    String token,
  ) async {
    final url = _buildUrl(apiUrl);
    print('FCM POST $url');
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(data),
      headers: _buildHeaders(bearerToken: token),
    );
    print('FCM response: ${response.statusCode}');
    return response;
  }

  Future<http.Response> uploadFile(File file, String apiUrl) async {
    final url = _buildUrl(apiUrl);
    print('MULTIPART POST $url');
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
      print('MULTIPART response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('MULTIPART error: $e');
      rethrow;
    }
  }
}
