// Widget test: login with a wrong password surfaces the backend's
// "Invalid email or password" message on the login screen.
//
// The backend returns HTTP 401 with detail "Invalid email or password" for a
// wrong password (Petto-Backend/app/auth.py), and the app's AuthRepositoryImpl
// surfaces that detail verbatim. This test fakes the repository to throw the
// same error the real one would, and asserts the login screen shows it and does
// not navigate away.
//
// NOTE: the onboarding UI has an infinitely-repeating button-icon animation, so
// `pumpAndSettle` can never settle here — the test drives the flow with
// fixed-duration pumps instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/core/theme/app_theme.dart';
import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

/// Fake repository that rejects login exactly the way the real one does when the
/// backend answers 401 for a wrong password: `Exception('<backend detail>')`.
class _RejectingAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) async =>
      throw Exception('Invalid email or password');

  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> register(String email, String password, String name,
          {Map<String, dynamic>? pet}) =>
      throw UnimplementedError();
}

/// Advances a few frames to let screen transitions and awaited async work
/// complete, without waiting on the never-ending icon animation.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets(
    'wrong password shows "Invalid email or password" and stays on login',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ignore transient "RenderFlex overflowed" errors from the test font's
      // over-wide glyphs during transitions; keep every other error fatal.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      final auth = AuthController(repository: _RejectingAuthRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const MaterialApp(
            home: AuthOnboardingScreen(startAtLogin: true),
          ),
        ),
      );
      await _advance(tester);

      // On the login/register gateway.
      expect(find.text('Login / Register'), findsOneWidget);

      // Valid email, wrong password.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email address'),
        'tester@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrong-password',
      );
      await _advance(tester);

      await tester.tap(find.text('LOGIN'));
      await _advance(tester); // run the (failing) login future
      await tester.pump(); // insert the top-alert overlay
      await tester.pump(const Duration(milliseconds: 200)); // fade-in

      // The banner message is shown...
      expect(find.text('Invalid email or password'), findsOneWidget);
      // ...and the user is still on the login screen (not navigated to Home).
      expect(find.text('Login / Register'), findsOneWidget);

      // The password field shows the inline "Wrong password" hint...
      expect(find.text('Wrong password'), findsOneWidget);
      // ...and its border turns red (danger colour). The password field is the
      // second field on the gateway (after the email field).
      final passwordFinder = find.byType(TextField).at(1);
      final passwordField = tester.widget<TextField>(passwordFinder);
      expect(passwordField.obscureText, isTrue); // sanity: this is the password
      final border = passwordField.decoration!.enabledBorder as OutlineInputBorder;
      expect(border.borderSide.color, AppTheme.dangerColor);

      // Editing the password clears the error state.
      await tester.enterText(passwordFinder, 'wrong-password2');
      await _advance(tester);
      expect(find.text('Wrong password'), findsNothing);

      // Let the top-alert auto-dismiss timer fire so no timers stay pending.
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
