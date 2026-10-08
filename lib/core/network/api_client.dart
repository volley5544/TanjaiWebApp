import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

/// Result of one API call — the web equivalent of FlutterFlow's
/// `ApiCallResponse`.
///
/// Same contract the ported pages rely on: [statusCode] is the HTTP status, or
/// **-1** when no response arrived (network error, CORS, timeout); [json] is the
/// decoded body or null when it isn't JSON.
class ApiResponse {
  const ApiResponse(this.statusCode, this.json);

  final int statusCode;
  final dynamic json;

  bool get isHttpOk => statusCode == 200;

  /// The insurance APIs' envelope: `{code, message, results: {data, total}}`.
  int? get code => _asInt(_field('code'));
  String? get message => _field('message')?.toString();

  dynamic _field(String key) => json is Map ? (json as Map)[key] : null;

  static int? _asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
}

/// Thin JSON-over-POST client. Every call is POST with a JSON body, matching
/// the mobile app's `ApiManager`; differences are deliberate hardening:
///
/// * bodies are built with `jsonEncode` (the FlutterFlow templates
///   interpolated raw strings, so a `"` in user input broke the JSON);
/// * a hard timeout ([AppEnvironment.apiTimeout]);
/// * nothing about the request or response is logged in release builds.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static final ApiClient instance = ApiClient();

  final http.Client _client;

  Future<ApiResponse> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json; charset=utf-8', ...headers},
            body: jsonEncode(body),
          )
          .timeout(AppEnvironment.current.apiTimeout);
      dynamic decoded;
      try {
        // Decode bytes as UTF-8 regardless of the response charset (Thai text).
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        decoded = null;
      }
      return ApiResponse(res.statusCode, decoded);
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] $url failed: $e');
      return const ApiResponse(-1, null);
    }
  }
}
