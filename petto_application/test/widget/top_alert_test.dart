import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/core/widgets/top_alert.dart';

void main() {
  testWidgets('top alert animates in and out above the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showTopAlert(
                  context,
                  'Profile updated.',
                  duration: const Duration(milliseconds: 400),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('Profile updated.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('Profile updated.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Profile updated.'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Profile updated.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new alert waits for the current exit animation', (
    tester,
  ) async {
    late BuildContext alertContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              alertContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    showTopAlert(
      alertContext,
      'First alert',
      duration: const Duration(seconds: 3),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    showTopAlert(alertContext, 'Second alert');
    await tester.pump();

    expect(find.text('First alert'), findsOneWidget);
    expect(find.text('Second alert'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('First alert'), findsNothing);
    expect(find.text('Second alert'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
