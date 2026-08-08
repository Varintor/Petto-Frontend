// Widget tests for Add Pet form validation:
//   - empty name  -> "Name is required", submission blocked
//   - weight "-3" -> "Invalid weight", submission blocked
//
// NOTE: the pet avatar has an infinitely-repeating animation, so `pumpAndSettle`
// can never settle here — the test uses fixed-duration pumps, and flushes the
// avatar's one-shot timer and the SnackBar auto-dismiss timer at the end.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/pet_management/presentation/screens/pet_form_screen.dart';

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Ignore transient test-font "RenderFlex overflowed" errors and give the form a
/// tall canvas. Returns the teardown for the error handler.
void _setUpSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

void main() {
  testWidgets('empty name shows "Name is required" and blocks submission', (
    WidgetTester tester,
  ) async {
    _setUpSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: PetFormScreen()));
    await _advance(tester);
    expect(find.text('Add Pet'), findsOneWidget); // header

    // Submit with the name left empty.
    await tester.ensureVisible(find.text('ADD PET'));
    await tester.tap(find.text('ADD PET'));
    await _advance(tester);

    expect(find.text('Name is required'), findsOneWidget);
    // Still on the form — submission was blocked (screen did not pop).
    expect(find.text('Add Pet'), findsOneWidget);

    // Flush the avatar's 950ms timer and the SnackBar auto-dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('weight "-3" shows "Invalid weight" and blocks submission', (
    WidgetTester tester,
  ) async {
    _setUpSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: PetFormScreen()));
    await _advance(tester);

    // Provide a valid name so validation reaches the weight check.
    await tester.enterText(find.widgetWithText(TextField, 'Pet name'), 'Milo');
    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (kg)'),
      '-3',
    );
    await _advance(tester);

    await tester.ensureVisible(find.text('ADD PET'));
    await tester.tap(find.text('ADD PET'));
    await _advance(tester);

    expect(find.text('Invalid weight'), findsOneWidget);
    // Still on the form — submission was blocked.
    expect(find.text('Add Pet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });
}
