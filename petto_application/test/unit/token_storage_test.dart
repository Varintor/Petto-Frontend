import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petto_application/src/core/services/token_storage.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates a legacy plaintext token into secure storage', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'legacy-jwt'});
    final storage = TokenStorage();

    expect(await storage.getToken(), 'legacy-jwt');
    expect(
      await const FlutterSecureStorage().read(key: 'auth_token'),
      'legacy-jwt',
    );
    expect(
      (await SharedPreferences.getInstance()).containsKey('auth_token'),
      false,
    );
  });

  test('new tokens are never copied to SharedPreferences', () async {
    final storage = TokenStorage();

    await storage.saveToken('secure-jwt');

    expect(await storage.getToken(), 'secure-jwt');
    expect(
      (await SharedPreferences.getInstance()).containsKey('auth_token'),
      false,
    );
  });
}
