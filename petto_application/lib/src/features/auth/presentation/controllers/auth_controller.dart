import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

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
  AuthUser? _currentUser;
  String? _error;
  bool _justLoggedOut = false;
  StreamSubscription<AuthState>? _supabaseAuthSubscription;

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
  bool get isVeterinarian => _currentUser?.role == AccountRole.veterinarian;

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
      final storedToken = await storage.getToken();
      if (storedToken == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      var token = storedToken;

      String? refreshToken;
      try {
        refreshToken = await storage.getRefreshToken();
      } catch (_) {
        // Older/custom TokenStorage implementations may not expose refresh
        // tokens yet. The existing access-token validation remains valid.
      }
      if (refreshToken != null) {
        try {
          final response = await Supabase.instance.client.auth.setSession(
            refreshToken,
          );
          final refreshed = response.session;
          if (refreshed != null) {
            token = refreshed.accessToken;
            await storage.saveToken(token);
            final rotatedRefreshToken = refreshed.refreshToken;
            if (rotatedRefreshToken != null) {
              await storage.saveRefreshToken(rotatedRefreshToken);
            }
            _watchSupabaseTokenRefresh();
          }
        } catch (_) {
          // The access token below may still be valid. /me remains the final
          // authority and clears storage if both credentials are expired.
        }
      }

      // Token validation and the local pet lookup are independent. Start both
      // together so app restoration takes the duration of the slower task,
      // rather than the sum of both tasks.
      final results = await Future.wait<Object?>([
        Future<AuthUser>.sync(() => repository.getMe(token)),
        Future<int?>.sync(storage.getPetId),
      ]);
      final user = results[0] as AuthUser;
      _token = token;
      _userId = user.id;
      _currentUser = user;
      _petId = results[1] as int?;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      // Session restoration must never leave AuthGate spinning forever when
      // browser storage or a platform plugin is unavailable. Clearing stale
      // credentials is best-effort; the unauthenticated state is authoritative.
      try {
        await storage.clear();
      } catch (_) {
        // A storage cleanup failure must not block the login screen.
      }
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
    var accessToken = result.accessToken;
    var refreshToken = result.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final response = await Supabase.instance.client.auth.setSession(
          refreshToken,
        );
        final session = response.session;
        if (session != null) {
          accessToken = session.accessToken;
          refreshToken = session.refreshToken;
          _watchSupabaseTokenRefresh();
        }
      } catch (_) {
        // The backend-issued access token is still usable; Realtime falls back
        // to polling if the local Supabase session cannot be established.
      }
    }
    _token = accessToken;
    _userId = result.user.id;
    _currentUser = result.user;
    final results = await Future.wait<Object?>([
      storage.saveToken(_token ?? ''),
      if (refreshToken != null && refreshToken.isNotEmpty)
        storage.saveRefreshToken(refreshToken),
      storage.saveUserId(_userId ?? 0),
      storage.getPetId(),
    ]);
    _petId = results[2] as int?;
    _justLoggedOut = false;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> applyCompletedRegistration(
    AuthResult result, {
    required int petId,
  }) async {
    var accessToken = result.accessToken;
    var refreshToken = result.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final response = await Supabase.instance.client.auth.setSession(
          refreshToken,
        );
        final session = response.session;
        if (session != null) {
          accessToken = session.accessToken;
          refreshToken = session.refreshToken;
          _watchSupabaseTokenRefresh();
        }
      } catch (_) {}
    }
    _token = accessToken;
    _userId = result.user.id;
    _currentUser = result.user;
    _petId = petId;
    await Future.wait<void>([
      storage.saveToken(_token ?? ''),
      if (refreshToken != null && refreshToken.isNotEmpty)
        storage.saveRefreshToken(refreshToken),
      storage.saveUserId(_userId ?? 0),
      storage.savePetId(petId),
    ]);
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
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
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

  void _watchSupabaseTokenRefresh() {
    if (_supabaseAuthSubscription != null) return;
    _supabaseAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
          final session = state.session;
          if (_status != AuthStatus.authenticated || session == null) return;
          _token = session.accessToken;
          unawaited(
            Future.wait<void>([
              storage.saveToken(session.accessToken),
              if (session.refreshToken != null)
                storage.saveRefreshToken(session.refreshToken!),
            ]),
          );
        });
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }
}
