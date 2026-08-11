import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthUser role mapping', () {
    test('maps an explicit veterinarian role', () {
      final user = AuthUser.fromJson({
        'id': 7,
        'email': 'sarah@clinic.test',
        'role': 'veterinarian',
      });

      expect(user.role, AccountRole.veterinarian);
    });

    test('supports a role inside user metadata', () {
      final user = AuthUser.fromJson({
        'id': 8,
        'email': 'mike@clinic.test',
        'user_metadata': {'role': 'clinician'},
      });

      expect(user.role, AccountRole.veterinarian);
    });

    test('keeps ordinary accounts in the owner app', () {
      final user = AuthUser.fromJson({'id': 9, 'email': 'owner@petto.test'});

      expect(user.role, AccountRole.owner);
    });

    test('allows a vet-prefixed account to preview the vet workspace', () {
      final user = AuthUser.fromJson({
        'id': 10,
        'email': 'vet.demo@petto.test',
      });

      expect(user.role, AccountRole.veterinarian);
    });
  });

  test(
    'mock vet credentials authenticate without calling the backend',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _FailingAuthRepository();
      final controller = AuthController(repository: repository);

      final success = await controller.login(
        AuthController.mockVetEmail,
        AuthController.mockVetPassword,
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isVeterinarian, isTrue);
      expect(controller.currentUser?.name, 'Dr. Sarah');
      expect(repository.loginCalls, 0);
    },
  );

  test('mock vet domain accounts do not call the backend', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FailingAuthRepository();
    final controller = AuthController(repository: repository);

    final success = await controller.login(
      '  sarah@vet.petto ',
      'PettoVet123 ',
    );

    expect(success, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.isVeterinarian, isTrue);
    expect(controller.currentUser?.email, 'sarah@vet.petto');
    expect(repository.loginCalls, 0);
  });

  test(
    'mock vet domain with wrong password shows auth error locally',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _FailingAuthRepository();
      final controller = AuthController(repository: repository);

      final success = await controller.login('doctor@vet.petto', 'wrong');

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.error, 'Invalid email or password.');
      expect(repository.loginCalls, 0);
    },
  );
}

class _FailingAuthRepository implements AuthRepository {
  int loginCalls = 0;

  @override
  Future<AuthResult> login(String email, String password) {
    loginCalls += 1;
    throw UnimplementedError();
  }

  @override
  Future<bool> checkEmailAvailability(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) => throw UnimplementedError();
}
