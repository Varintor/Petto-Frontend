import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const _authRetryKey = 'petto_auth_retry';
  static Future<String?>? _refreshInFlight;
  static StreamSubscription<AuthState>? _authSubscription;

  static final Dio dio = _build();

  /// Keeps the REST token store and Realtime authorization synchronized with
  /// Supabase's automatic access-token rotation.
  static void initializeAuthSync() {
    if (_authSubscription != null) return;
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            final session = state.session;
            if (session != null) unawaited(_persistSession(session));
          }, onError: (_, _) {});
    } catch (_) {
      // Widget tests may use ApiClient without initializing Supabase.
    }
  }

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
            final token = await _latestAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final canRetry =
              error.response?.statusCode == 401 &&
              request.extra[_authRetryKey] != true &&
              request.data is! FormData;
          if (!canRetry) {
            handler.next(error);
            return;
          }

          try {
            final token = await _refreshAccessTokenOnce();
            if (token == null || token.isEmpty) {
              handler.next(error);
              return;
            }
            request.extra[_authRetryKey] = true;
            request.headers['Authorization'] = 'Bearer $token';
            handler.resolve(await dio.fetch<dynamic>(request));
          } catch (_) {
            // Preserve the original 401. The UI can now present a concise
            // session-expired message instead of exposing Dio internals.
            handler.next(error);
          }
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

  static Future<String?> _latestAccessToken() async {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {
      // Fall through to secure storage when Supabase is unavailable in tests.
    }
    return _storage.getToken();
  }

  static Future<String?> _refreshAccessTokenOnce() {
    final running = _refreshInFlight;
    if (running != null) return running;

    late final Future<String?> operation;
    operation = _refreshAccessToken().whenComplete(() {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    });
    _refreshInFlight = operation;
    return operation;
  }

  static Future<String?> _refreshAccessToken() async {
    final client = Supabase.instance.client;
    AuthResponse response;
    if (client.auth.currentSession != null) {
      response = await client.auth.refreshSession();
    } else {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      response = await client.auth.setSession(refreshToken);
    }
    final session = response.session;
    if (session == null) return null;
    await _persistSession(session);
    return session.accessToken;
  }

  static Future<void> _persistSession(Session session) async {
    try {
      await _storage.saveToken(session.accessToken);
      final refreshToken = session.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(refreshToken);
      }
    } catch (_) {
      // The fresh in-memory Supabase session remains usable for this run.
    }
    try {
      await Supabase.instance.client.realtime.setAuth(session.accessToken);
    } catch (_) {
      // Realtime reconnect/fallback handles temporary channel failures.
    }
  }

  static String describeError(Object error) {
    if (error is! DioException) {
      return 'Something went wrong. Please try again.';
    }
    final response = error.response;
    if (response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    final data = response?.data;
    final detail = data is Map ? data['detail'] : null;
    if (detail is String && detail.trim().isNotEmpty) return detail;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server is taking longer than expected. Please retry.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please check your connection.';
      default:
        return 'Could not complete the request. Please retry.';
    }
  }
}
