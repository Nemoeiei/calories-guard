import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/constants.dart';

/// Centralized HTTP client that:
/// - Adds Supabase auth token to every request
/// - Handles 401 → triggers logout
/// - Adds timeout (30s default)
/// - Provides typed JSON helpers
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  static const Duration _defaultTimeout = Duration(seconds: 30);

  String get _baseUrl => AppConstants.baseUrl;

  /// Get the current Supabase access token, or null if not signed in.
  String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  /// Callback invoked when a 401 response is received.
  /// Set this in your app (e.g., in main.dart) to navigate to login.
  void Function()? onUnauthorized;

  Future<http.Response> _handleResponse(Future<http.Response> request) async {
    try {
      final response = await request.timeout(_defaultTimeout);
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      return response;
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    }
  }

  // --- HTTP Methods ---

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    return _handleResponse(http.get(uri, headers: _headers(extra: extraHeaders)));
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) {
    final uri = Uri.parse('$_baseUrl$path');
    return _handleResponse(
      http.post(uri, headers: _headers(extra: extraHeaders), body: jsonEncode(body)),
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) {
    final uri = Uri.parse('$_baseUrl$path');
    return _handleResponse(
      http.put(uri, headers: _headers(extra: extraHeaders), body: jsonEncode(body)),
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) {
    final uri = Uri.parse('$_baseUrl$path');
    return _handleResponse(
      http.patch(uri, headers: _headers(extra: extraHeaders), body: jsonEncode(body)),
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? extraHeaders,
  }) {
    final uri = Uri.parse('$_baseUrl$path');
    return _handleResponse(
      http.delete(uri, headers: _headers(extra: extraHeaders)),
    );
  }

  /// Upload a file via multipart POST.
  Future<http.StreamedResponse> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
    String? fileName,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final token = _accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      filePath,
      filename: fileName,
    ));

    return request.send().timeout(_defaultTimeout);
  }
}
