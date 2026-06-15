import 'package:supabase_flutter/supabase_flutter.dart';

/// User model from Supabase Auth
class AuthUser {
  final String id;
  final String email;
  final String? name;

  AuthUser({required this.id, required this.email, this.name});

  factory AuthUser.fromUser(User user) {
    final metadata = user.userMetadata;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      name: metadata?['name'] as String?,
    );
  }
}

/// Result of authentication (login/register)
class AuthResult {
  final String accessToken;
  final AuthUser user;

  AuthResult({required this.accessToken, required this.user});
}

abstract class AuthRepository {
  Future<AuthResult> register(String email, String password, String name);
  Future<AuthResult> login(String email, String password);
  Future<AuthUser> getMe(String token);
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<AuthResult> register(String email, String password, String name) async {
    try {
      print('📝 Register attempt: email=$email, name=$name');
      print('📝 Password length: ${password.length}');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        print('❌ Registration failed: user is null');
        throw Exception('Registration failed. Please try again.');
      }

      final accessToken = response.session?.accessToken ?? '';
      print('✅ Registration successful for: ${response.user!.email}');
      return AuthResult(
        accessToken: accessToken,
        user: AuthUser.fromUser(response.user!),
      );
    } on AuthException catch (e) {
      print('❌ Supabase Auth Error: ${e.message}');
      print('   Status: ${e.statusCode}');
      rethrow;
    }
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      print('🔐 Login attempt: email=$email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ Login failed: user is null');
        throw Exception('Login failed. Please check your credentials.');
      }

      final accessToken = response.session?.accessToken ?? '';
      print('✅ Login successful for: ${response.user!.email}');
      return AuthResult(
        accessToken: accessToken,
        user: AuthUser.fromUser(response.user!),
      );
    } on AuthException catch (e) {
      print('❌ Supabase Auth Error: ${e.message}');
      print('   Status: ${e.statusCode}');
      rethrow;
    }
  }

  @override
  Future<AuthUser> getMe(String token) async {
    // Supabase automatically manages the current session
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('No authenticated user found.');
    }

    return AuthUser.fromUser(currentUser);
  }
}
