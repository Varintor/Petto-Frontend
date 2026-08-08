// Widget test: password-strength validation on the "Create account" screen.
//
// Test case: the tester enters the password "pass". The system shows the
// password-strength warning and blocks submission (stays on the Create account
// screen instead of advancing into the pet-onboarding steps).
//
// NOTE: the onboarding UI has an infinitely-repeating button-icon animation, so
// `pumpAndSettle` can never settle here — the test drives the flow with
// fixed-duration pumps instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

/// Minimal fake — a weak password is rejected before the flow ever reaches the
/// network, so none of these are actually called, but the interface must be
/// satisfied to construct an [AuthController].
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> register(String email, String password, String name,
          {Map<String, dynamic>? pet}) =>
      throw UnimplementedError();
}

/// Advances a few frames to let screen transitions (~80ms) complete, without
/// waiting on the never-ending icon animation.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets(
    'entering password "pass" shows the strength warning and blocks submission',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // The onboarding uses tight rows with heavy letter-spacing. Under the
      // test font (which renders every glyph much wider than a real font) these
      // rows report transient "RenderFlex overflowed" errors during the
      // cross-fade transitions. They are a test-font artifact, not the behavior
      // under test, so ignore them while keeping every other error fatal.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      final auth = AuthController(repository: _FakeAuthRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const MaterialApp(
            home: AuthOnboardingScreen(startAtLogin: true),
          ),
        ),
      );
      await _advance(tester);

      // Gateway -> "Create account" screen.
      await tester.tap(find.text('REGISTER'));
      await _advance(tester);
      expect(find.text('Create account'), findsOneWidget);

      // Valid email + matching but too-short password.
      await tester.enterText(
        find.widgetWithText(TextField, 'Email address'),
        'tester@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'pass',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        'pass',
      );
      await _advance(tester);

      await tester.tap(find.text('CONTINUE'));
      await tester.pump(); // insert the top-alert overlay
      await tester.pump(const Duration(milliseconds: 200)); // fade-in

      // The strength warning is shown...
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      // ...and submission is blocked: still on Create account, never advanced
      // to the first pet-onboarding step.
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Welcome!'), findsNothing);

      // Let the top-alert auto-dismiss timer fire so no timers stay pending.
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
