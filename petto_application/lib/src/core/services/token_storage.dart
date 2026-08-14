import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _petIdKey = 'pet_id';
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage;

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    // Remove the legacy plaintext copy after the secure write succeeds.
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    // One-time migration for sessions created before secure storage was
    // introduced. Never delete the old value until the secure write succeeds.
    final prefs = await _preferences;
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;
    await _secureStorage.write(key: _tokenKey, value: legacyToken);
    await prefs.remove(_tokenKey);
    return legacyToken;
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
  }

  Future<void> saveUserId(int userId) async {
    final prefs = await _preferences;
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getInt(_userIdKey);
  }

  Future<void> savePetId(int petId) async {
    final prefs = await _preferences;
    await prefs.setInt(_petIdKey, petId);
  }

  Future<int?> getPetId() async {
    final prefs = await _preferences;
    return prefs.getInt(_petIdKey);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_petIdKey);
  }
}
