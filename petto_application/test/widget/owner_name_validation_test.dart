// Widget test: display-name validation on the registration flow.
//
// Test case: the tester submits the "YOUR NAME" step (register step 1) with the
// name left empty. The system must keep the user on that step and surface
// "Enter a display name".
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

/// Minimal fake so the register flow can reach the owner step without touching
/// the network. Only [checkEmailAvailability] is exercised by this test.
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

/// Advances a few frames to let screen transitions (~80ms) and awaited async
/// work complete, without waiting on the never-ending icon animation.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets(
    'submitting the owner step with an empty name shows "Enter a display name"',
    (WidgetTester tester) async {
      // Give the onboarding UI a tall phone canvas.
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

      // Fill valid credentials so the account step lets us continue on to the
      // pet-onboarding steps (owner name is the first of those).
      await tester.enterText(
        find.widgetWithText(TextField, 'Email address'),
        'tester@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        'secret123',
      );
      await _advance(tester);

      await tester.tap(find.text('CONTINUE'));
      await _advance(tester);

      // We should now be on the owner "YOUR NAME" step.
      expect(find.text('Welcome!'), findsOneWidget);

      // Submit with the display name left empty.
      await tester.tap(find.text('NEXT'));
      await tester.pump(); // insert the top-alert overlay
      await tester.pump(const Duration(milliseconds: 200)); // fade-in

      // Validation message is shown...
      expect(find.text('Enter a display name'), findsOneWidget);
      // ...and the flow did not advance past the owner step.
      expect(find.text('Welcome!'), findsOneWidget);

      // Let the top-alert auto-dismiss timer fire so no timers stay pending.
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
