import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

class _StubAuthRepository implements AuthRepository {
  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) => throw UnimplementedError();
}

class _FakePasswordResetRepository implements PasswordResetRepository {
  String? requestedEmail;

  @override
  Future<String> requestReset(String email) async {
    requestedEmail = email;
    return 'If an account exists for this email, a reset link has been sent.';
  }
}

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 7; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('forgot password validates and sends a real repository request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final resetRepository = _FakePasswordResetRepository();
    final auth = AuthController(repository: _StubAuthRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          home: AuthOnboardingScreen(
            startAtLogin: true,
            passwordResetRepository: resetRepository,
          ),
        ),
      ),
    );
    await _advance(tester);

    await tester.tap(find.text('Forgot password?'));
    await _advance(tester);
    expect(find.text('Forgot password'), findsOneWidget);

    await tester.tap(find.text('SEND RESET LINK'));
    await _advance(tester);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(resetRepository.requestedEmail, isNull);
    await tester.pump(const Duration(seconds: 4));

    await tester.enterText(find.byType(TextField), 'Owner@Test.com');
    await tester.tap(find.text('SEND RESET LINK'));
    await _advance(tester);

    expect(resetRepository.requestedEmail, 'Owner@Test.com');
    expect(find.text('Login / Register'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
