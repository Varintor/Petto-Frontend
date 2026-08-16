import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/auth/presentation/screens/password_recovery_screen.dart';

void main() {
  testWidgets('validates confirmation and updates the recovered password', (
    tester,
  ) async {
    String? updatedPassword;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryScreen(
          updatePassword: (password) async => updatedPassword = password,
          onComplete: () => completed = true,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('recovery-new-password')),
      'NewPassword123!',
    );
    await tester.enterText(
      find.byKey(const Key('recovery-confirm-password')),
      'different',
    );
    await tester.tap(find.byKey(const Key('recovery-submit')));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(updatedPassword, isNull);

    await tester.enterText(
      find.byKey(const Key('recovery-confirm-password')),
      'NewPassword123!',
    );
    await tester.tap(find.byKey(const Key('recovery-submit')));
    await tester.pumpAndSettle();

    expect(updatedPassword, 'NewPassword123!');
    expect(completed, isTrue);
  });
}
