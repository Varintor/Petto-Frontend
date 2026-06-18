import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';

/// User returned by the Petto FastAPI backend (`public.users`, bigint id).
class AuthUser {
  final int id;
  final String email;
  final String? name;
  final String? avatarUri;

  AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUri,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUri: json['avatar_uri'] as String?,
    );
  }
}

/// Result of authentication (register/login): a Supabase JWT issued by the
/// backend plus the resolved backend user.
class AuthResult {
  final String accessToken;
  final AuthUser user;

  AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String? ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

abstract class AuthRepository {
  Future<AuthResult> register(String email, String password, String name);
  Future<AuthResult> login(String email, String password);
  Future<AuthUser> getMe(String token);
  Future<bool> checkEmailAvailability(String email);
}

/// Talks to the FastAPI backend (`/api/v1/auth/*`). The backend wraps Supabase
/// Auth and maps the Supabase user to a `public.users` row, so the rest of the
/// app keys off the backend's bigint user id.
class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;

  AuthRepositoryImpl({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectionTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
            ));

  @override
  Future<AuthResult> register(String email, String password, String name) async {
    try {
      final response = await dio.post(
        AppConfig.registerEndpoint,
        data: {'email': email, 'password': password, 'name': name},
      );
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await dio.post(
        AppConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<AuthUser> getMe(String token) async {
    try {
      final response = await dio.get(
        AppConfig.meEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await dio.get(
        AppConfig.checkEmailEndpoint,
        queryParameters: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      return data['available'] as bool? ?? true;
    } on DioException catch (e) {
      // On error, assume available (don't block registration)
      return true;
    }
  }

  String _describeDioError(DioException e) {
    // FastAPI returns errors as {"detail": "..."}.
    if (e.type == DioExceptionType.badResponse) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is String && detail.isNotEmpty) return detail;
      return 'Server error ${e.response?.statusCode}.';
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please check your connection.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      default:
        return 'Network error. Please try again.';
    }
  }
}
