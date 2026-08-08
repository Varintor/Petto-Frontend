// Widget test: submitting login with empty email and password shows the
// required-field messages (one per empty field) and marks both fields red.
//
// NOTE: the onboarding UI has an infinitely-repeating button-icon animation, so
// `pumpAndSettle` can never settle here — the test uses fixed-duration pumps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/core/theme/app_theme.dart';
import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

/// Empty-field submission returns before any repository call, so nothing here is
/// actually invoked — the stub just satisfies the interface.
class _StubAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> register(String email, String password, String name,
          {Map<String, dynamic>? pet}) =>
      throw UnimplementedError();
}

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets(
    'empty email and password on submit shows required-field messages',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ignore transient test-font "RenderFlex overflowed" errors.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      final auth = AuthController(repository: _StubAuthRepository());
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const MaterialApp(
            home: AuthOnboardingScreen(startAtLogin: true),
          ),
        ),
      );
      await _advance(tester);

      expect(find.text('Login / Register'), findsOneWidget);

      // Submit with both fields left empty.
      await tester.tap(find.text('LOGIN'));
      await _advance(tester);

      // Both required-field messages are shown.
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Both fields are shown in the red error state. On the gateway the email
      // field is first and the password field second.
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields[1].obscureText, isTrue); // sanity: 2nd is the password
      for (final field in fields) {
        final border = field.decoration!.enabledBorder as OutlineInputBorder;
        expect(border.borderSide.color, AppTheme.dangerColor);
      }

      // Typing into a field clears just that field's message.
      await tester.enterText(find.byType(TextField).at(0), 'tester@example.com');
      await _advance(tester);
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsOneWidget);
    },
  );
}
