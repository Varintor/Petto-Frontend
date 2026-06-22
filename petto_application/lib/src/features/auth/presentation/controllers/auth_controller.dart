import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/token_storage.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

/// Holds the authenticated session. Identity comes from the FastAPI backend
/// (`/api/v1/auth/*`), which wraps Supabase Auth and returns a Supabase JWT
/// plus the backend's bigint user id. The JWT is sent as a Bearer token on
/// authenticated calls (e.g. creating a pet).
class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final TokenStorage storage;

  AuthStatus _status = AuthStatus.loading;
  String? _token;
  int? _userId;
  int? _petId;
  String? _error;

  AuthController({required this.repository, TokenStorage? storage})
    : storage = storage ?? TokenStorage();

  AuthStatus get status => _status;
  String? get token => _token;
  int? get userId => _userId;

  /// Falls back to the seed pet so feature endpoints keyed by pet id still work
  /// before the user has created their own pet.
  int? get petId => _petId ?? AppConfig.defaultPetId;
  int? get rawPetId => _petId;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.unauthenticated && _token == null;

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await storage.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Validate the stored token against the backend.
      final user = await repository.getMe(token);
      _token = token;
      _userId = user.id;
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
      await _applySession(result);
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
      final result = await repository.login(email, password);
      await _applySession(result);
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> _applySession(AuthResult result) async {
    _token = result.accessToken;
    _userId = result.user.id;
    await storage.saveToken(_token ?? '');
    await storage.saveUserId(_userId ?? 0);
    _petId = await storage.getPetId();
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> applyCompletedRegistration(
    AuthResult result, {
    required int petId,
  }) async {
    _token = result.accessToken;
    _userId = result.user.id;
    _petId = petId;
    await storage.saveToken(_token ?? '');
    await storage.saveUserId(_userId ?? 0);
    await storage.savePetId(petId);
    _status = AuthStatus.authenticated;
    notifyListeners();
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
    await storage.clear();
    _token = null;
    _userId = null;
    _petId = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }
}
