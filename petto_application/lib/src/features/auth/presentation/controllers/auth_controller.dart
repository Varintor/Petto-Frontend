import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/token_storage.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final TokenStorage storage;

  AuthStatus _status = AuthStatus.loading;
  String? _token;
  int? _userId;
  int? _petId;
  String? _error;

  AuthController({required this.repository, TokenStorage? storage})
      : storage = storage ?? TokenStorage() {
    // Listen to Supabase auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        _token = session?.accessToken;
        if (session?.user != null) {
          _userId = _extractUserId(session!.user.id);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _token = null;
        _userId = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        _token = session?.accessToken;
      }
    });
  }

  AuthStatus get status => _status;
  String? get token => _token;
  int? get userId => _userId;
  int? get petId => _petId ?? AppConfig.defaultPetId;
  int? get rawPetId => _petId;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.unauthenticated && _token == null;

  /// Extract numeric user ID from Supabase UUID string
  int? _extractUserId(String uuid) {
    // Supabase uses UUID strings. We'll use a hash of the UUID
    // or you can use the user metadata if you store a numeric ID there
    return uuid.hashCode;
  }

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Supabase automatically restores the session
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      await repository.getMe('');
      _token = Supabase.instance.client.auth.currentSession?.accessToken;
      _userId = _extractUserId(currentUser.id);
      _petId = await storage.getPetId();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      await storage.clear();
      _token = null;
      _userId = null;
      _petId = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.register(email, password, name);
      _token = result.accessToken;
      _userId = _extractUserId(result.user.id);
      // Supabase handles token storage automatically
      await storage.saveUserId(_userId ?? 0);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Attempting login with: $email');
      final result = await repository.login(email, password);
      print('✅ Login successful!');
      print('   Access Token: ${result.accessToken.substring(0, 20)}...');
      print('   User ID: ${result.user.id}');

      _token = result.accessToken;
      _userId = _extractUserId(result.user.id);
      // Supabase handles token storage automatically
      await storage.saveUserId(_userId ?? 0);
      _petId = await storage.getPetId();
      _status = AuthStatus.authenticated;
      notifyListeners();

      print('✅ Auth state updated to: authenticated');
      print('   Current User: ${Supabase.instance.client.auth.currentUser?.email}');
      return true;
    } catch (e) {
      print('❌ Login failed: $e');
      _status = AuthStatus.error;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> setPetId(int id) async {
    _petId = id;
    await storage.savePetId(id);
    notifyListeners();
  }

  Future<void> enterGuestMode() async {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _userId = null;
    _petId = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    await storage.clear();
    _token = null;
    _userId = null;
    _petId = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    // Handle Supabase-specific errors
    if (e is AuthException) {
      if (e.message.contains('Invalid login credentials')) {
        return 'Invalid email or password';
      }
      if (e.message.contains('User already registered')) {
        return 'Email already registered';
      }
      if (e.message.contains('Email not confirmed')) {
        return 'Please confirm your email first';
      }
      return e.message;
    }
    if (e is Exception) {
      final message = e.toString();
      if (message.contains('Registration failed')) {
        return 'Registration failed. Please try again.';
      }
      if (message.contains('Login failed')) {
        return 'Login failed. Please check your credentials.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
