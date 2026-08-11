import 'package:flutter/foundation.dart';

import '../../../../core/services/token_storage.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

/// Holds the authenticated session. Identity comes from the FastAPI backend
/// (`/api/v1/auth/*`), which wraps Supabase Auth and returns a Supabase JWT
/// plus the backend's bigint user id. The JWT is sent as a Bearer token on
/// authenticated calls (e.g. creating a pet).
class AuthController extends ChangeNotifier {
  static const mockVetEmail = 'doctor@vet.petto';
  static const mockVetPassword = 'PettoVet123';
  static const _mockVetToken = 'mock-vet-session';
  static const _mockVetUserId = -100;

  final AuthRepository repository;
  final TokenStorage storage;

  AuthStatus _status = AuthStatus.loading;
  String? _token;
  int? _userId;
  int? _petId;
  AuthUser? _currentUser;
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
  AuthUser? get currentUser => _currentUser;
  AccountRole get accountRole => _currentUser?.role ?? AccountRole.owner;
  bool get isVeterinarian => accountRole == AccountRole.veterinarian;

  /// The signed-in user's active pet id, or null when there is none yet
  /// (guest session, fresh account before the first pet). No seed-pet
  /// fallback: SRS-F2-018 forbids keying any feature off a default pet id —
  /// that fallback is exactly what once leaked one user's data to everyone.
  /// Callers must skip loading until a real pet id exists.
  int? get petId => _status == AuthStatus.authenticated ? _petId : null;
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

      if (token == _mockVetToken) {
        _token = token;
        _userId = _mockVetUserId;
        _currentUser = _buildMockVetUser();
        _petId = null;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }

      // Validate the stored token against the backend.
      final user = await repository.getMe(token);
      _token = token;
      _userId = user.id;
      _currentUser = user;
      _petId = await storage.getPetId();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      await storage.clear();
      _token = null;
      _userId = null;
      _currentUser = null;
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
    // Do NOT broadcast a `loading`/`error` status here. The login form is
    // rendered by AuthGate for the `unauthenticated` state, so flipping the
    // status mid-attempt makes AuthGate rebuild — tearing the form down (a brief
    // splash, then the intro/"welcome" screen) and dropping the typed
    // credentials and the inline error. Stay unauthenticated throughout; only a
    // successful sign-in changes the status (via _applySession -> authenticated).
    // The caller surfaces failures inline from the returned bool + [error].
    _error = null;
    final normalizedEmail = _normalizeMockEmail(email);
    final normalizedPassword = password.trim();

    if (_isMockVetEmail(normalizedEmail)) {
      if (normalizedPassword != mockVetPassword) {
        _status = AuthStatus.unauthenticated;
        _error = 'Invalid email or password.';
        notifyListeners();
        return false;
      }
      await _applySession(
        AuthResult(
          accessToken: _mockVetToken,
          user: _buildMockVetUser(normalizedEmail),
        ),
      );
      return true;
    }

    try {
      final result = await repository.login(email, password);
      await _applySession(result);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    }
  }

  Future<void> _applySession(AuthResult result) async {
    _token = result.accessToken;
    _userId = result.user.id;
    _currentUser = result.user;
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
    _currentUser = result.user;
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
    _currentUser = null;
    _petId = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.clear();
    _token = null;
    _userId = null;
    _currentUser = null;
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

  static bool _isMockVetEmail(String email) =>
      email == mockVetEmail || email.endsWith('@vet.petto');

  static String _normalizeMockEmail(String email) {
    return email
        .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF]+'), '')
        .toLowerCase();
  }

  static AuthUser _buildMockVetUser([String? email]) {
    return AuthUser(
      id: _mockVetUserId,
      email: email ?? mockVetEmail,
      name: 'Dr. Sarah',
      role: AccountRole.veterinarian,
    );
  }
}
