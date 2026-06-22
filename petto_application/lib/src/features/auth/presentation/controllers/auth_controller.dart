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
  bool _justLoggedOut = false;

  /// Handlers invoked when [logout] runs, so other controllers can clear
  /// per-account in-memory state (stats, missions) before the new account
  /// loads. Registered from [main.dart] at provider wiring time.
  final List<VoidCallback> _logoutHandlers = [];

  AuthController({required this.repository, TokenStorage? storage})
    : storage = storage ?? TokenStorage();

  AuthStatus get status => _status;
  String? get token => _token;
  int? get userId => _userId;

  /// Falls back to the seed pet ONLY for authenticated users who haven't
  /// created a pet yet. Never returns the mock pet for unauthenticated/guest
  /// sessions — after logout, this returns null and tracking controllers
  /// must wait for a real pet before loading stats.
  int? get petId => _status == AuthStatus.authenticated
      ? (_petId ?? AppConfig.defaultPetId)
      : null;
  int? get rawPetId => _petId;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.unauthenticated && _token == null;

  /// True after the user explicitly hits "Log out". Cleared once they log
  /// back in or the consumer (AuthGate) acknowledges it. Lets the onboarding
  /// screen open straight at the login form instead of the marketing intro.
  bool get justLoggedOut => _justLoggedOut;

  /// Idempotent — safe to call from [ChangeNotifierProxyProvider.update],
  /// which fires every time this controller notifies.
  void addLogoutHandler(VoidCallback handler) {
    if (_logoutHandlers.contains(handler)) return;
    _logoutHandlers.add(handler);
  }

  void removeLogoutHandler(VoidCallback handler) =>
      _logoutHandlers.remove(handler);

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
    _justLoggedOut = false;
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
    _justLoggedOut = false;
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
    _justLoggedOut = true;
    // Wipe per-account state in sibling controllers (activity, missions, ...)
    // so the next account that signs in doesn't inherit the previous account's
    // cached stats. Each handler is best-effort.
    for (final handler in List<VoidCallback>.from(_logoutHandlers)) {
      try {
        handler();
      } catch (_) {}
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by [AuthGate] once it has navigated to the login form so the
  /// flag doesn't keep forcing the login screen on subsequent rebuilds.
  void acknowledgeLogout() {
    if (!_justLoggedOut) return;
    _justLoggedOut = false;
  }

  String _parseError(dynamic e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }
}
