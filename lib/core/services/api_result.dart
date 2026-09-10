import 'dart:convert';

import 'package:http/http.dart' as http;

/// Helpers for the Atlas API envelope.
///
/// Successful responses are wrapped by a global interceptor:
/// `{ statusCode, message, data }` — the payload always lives under `data`.
/// Errors are NOT wrapped: they come back in the raw NestJS shape, where
/// `message` is a String for thrown exceptions and a List<String> for
/// request-validation failures.
class ApiResult {
  const ApiResult._();

  /// POST handlers answer 201, GET/PATCH answer 200 — never compare to 200.
  static bool isSuccess(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  /// Decodes the body, tolerating an empty or non-JSON payload.
  static dynamic decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  /// Unwraps `body["data"]`, falling back to the body itself when the
  /// envelope is missing.
  static dynamic unwrap(http.Response response) {
    final body = decode(response);
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// Extracts a displayable error message, handling both `message` shapes.
  static String errorMessage(http.Response response, String fallback) {
    final body = decode(response);
    if (body is Map && body['message'] != null) {
      final message = body['message'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }
}
