import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiBackendClient {
  AiBackendClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _httpClient;
  final String _baseUrl;

  static const _env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static bool get isDevEnv => _env != 'prod';

  static String _resolveBaseUrl() {
    const devUrl = String.fromEnvironment(
      'AI_BACKEND_BASE_URL_DEV',
      defaultValue: 'http://localhost:8080',
    );
    const prodUrl = String.fromEnvironment(
      'AI_BACKEND_BASE_URL_PROD',
      defaultValue: 'https://replace-with-cloud-run-url',
    );
    final raw = _env == 'prod' ? prodUrl : devUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Future<void> debugPing() async {
    if (!kDebugMode || !isDevEnv) return;
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/healthz'));
      debugPrint('[AI] healthz ${response.statusCode}: ${response.body}');
    } catch (error) {
      debugPrint('[AI] healthz failed: $error');
    }
  }

  Future<Map<String, dynamic>> classifyFinance({
    required String text,
    String locale = 'es-ES',
  }) {
    return _post(
      '/v1/ai/finance/classify',
      {
        'text': text,
        'locale': locale,
      },
    );
  }

  Future<Map<String, dynamic>> caloriesFromPhoto({
    required String imageBase64,
    String mimeType = 'image/jpeg',
    String locale = 'es-ES',
  }) {
    return _post(
      '/v1/ai/food/calories_from_photo',
      {
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'locale': locale,
      },
    );
  }

  Future<Map<String, dynamic>> receiptScan({
    required String imageBase64,
    String mimeType = 'image/jpeg',
    String locale = 'es-ES',
  }) {
    return _post(
      '/v1/ai/finance/receipt_scan',
      {
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'locale': locale,
      },
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final headers = await _buildHeaders();
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> decoded =
        (jsonDecode(response.body) as Map).cast<String, dynamic>();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw AiBackendException(
      message: decoded['error']?.toString() ?? 'ai_backend_error',
      statusCode: response.statusCode,
      details: decoded,
    );
  }

  Future<Map<String, String>> _buildHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AiBackendException(
        message: 'user_not_authenticated',
        statusCode: 401,
      );
    }

    final idToken = await user.getIdToken(true);

    String? appCheckToken;
    try {
      appCheckToken = await FirebaseAppCheck.instance.getToken(false);
    } catch (_) {}

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    if (appCheckToken != null && appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }

    return headers;
  }
}

class AiBackendException implements Exception {
  const AiBackendException({
    required this.message,
    required this.statusCode,
    this.details,
  });

  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;

  @override
  String toString() =>
      'AiBackendException(message: $message, statusCode: $statusCode)';
}
