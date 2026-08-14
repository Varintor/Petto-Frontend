import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _petIdKey = 'pet_id';
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  Future<void> saveToken(String token) async {
    final prefs = await _preferences;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _preferences;
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
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
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_petIdKey);
  }
}
