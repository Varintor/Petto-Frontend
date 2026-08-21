import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../config/app_config.dart';
import '../services/token_storage.dart';

/// Shared Dio for every backend repository.
///
/// The backend now requires a Bearer token on all pet-scoped endpoints
/// (missions, activities, assessments, stats, vaccinations, pets), so the
/// interceptor attaches the stored session token to every request instead of
/// each repository threading it through by hand. Requests without a stored
/// token (guest mode, login/register) go out without the header and the
/// backend answers 401/403 — callers treat that as "sign in first".
class ApiClient {
  ApiClient._();

  static final TokenStorage _storage = TokenStorage();

  static final Dio dio = _build();

  /// Wake a sleeping staging backend while the user is still on Welcome/Auth.
  ///
  /// Railway Serverless may cold-start after an idle period. This best-effort
  /// request uses a standalone client so it never waits for secure token
  /// storage and never delays the first frame.
  static Future<void> warmUp() async {
    try {
      await Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'Accept': 'application/json'},
        ),
      ).get('/health');
    } catch (_) {
      // A normal authenticated request will retry through the regular UI.
    }
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path == AppConfig.assessmentsEndpoint &&
              options.method == 'POST') {
            options.receiveTimeout = AppConfig.aiReceiveTimeout;
          }
          // Explicit per-call Authorization (e.g. right after register, before
          // the token is persisted) wins over the stored one.
          if (!options.headers.containsKey('Authorization')) {
            final token = await _storage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

    // Verbose wire logging is debug-only: response bodies carry health data
    // and the request header now carries the session token.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    return dio;
  }
}
