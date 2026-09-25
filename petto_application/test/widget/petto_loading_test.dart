import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/core/theme/app_theme.dart';
import 'package:petto_application/src/core/widgets/petto_loading.dart';

void main() {
  Future<void> pumpAtSize(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('page skeleton fits a narrow mobile viewport', (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 568),
      child: const PettoPageSkeleton(itemCount: 3),
    );

    expect(find.byType(PettoSkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI progress remains readable without overflowing', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      size: const Size(280, 480),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: PettoInlineProgress(
            title: 'Reading your pet photo',
            subtitle: 'Petto AI is checking the details with care.',
          ),
        ),
      ),
    );

    expect(find.text('Reading your pet photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat skeleton fits a compact conversation area', (tester) async {
    await pumpAtSize(
      tester,
      size: const Size(320, 360),
      child: const PettoChatSkeleton(),
    );

    expect(find.byType(PettoSkeletonBox), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
