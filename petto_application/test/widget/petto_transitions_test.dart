import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/core/navigation/petto_transitions.dart';
import 'package:petto_application/src/core/theme/app_theme.dart';

void main() {
  test('Petto routes use the shared short transition timing', () {
    final route = PettoPageRoute<void>(builder: (_) => const SizedBox.shrink());

    expect(route.transitionDuration, AppTheme.pageTransitionDuration);
    expect(
      route.reverseTransitionDuration,
      AppTheme.pageTransitionReverseDuration,
    );
    expect(route.opaque, isTrue);
  });

  testWidgets('section switching never paints the outgoing page', (
    tester,
  ) async {
    final key = GlobalKey<_SwitcherHarnessState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: _SwitcherHarness(key: key),
      ),
    );
    expect(find.text('FIRST PAGE'), findsOneWidget);

    key.currentState!.showSecondPage();
    await tester.pump();

    expect(find.text('SECOND PAGE'), findsOneWidget);
    expect(find.text('FIRST PAGE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _SwitcherHarness extends StatefulWidget {
  const _SwitcherHarness({super.key});

  @override
  State<_SwitcherHarness> createState() => _SwitcherHarnessState();
}

class _SwitcherHarnessState extends State<_SwitcherHarness> {
  bool _showSecond = false;

  void showSecondPage() => setState(() => _showSecond = true);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppTheme.motionNormal,
      layoutBuilder: PettoTransitions.currentChildOnly,
      transitionBuilder: PettoTransitions.buildSectionTransition,
      child: ColoredBox(
        key: ValueKey(_showSecond),
        color: _showSecond ? Colors.white : Colors.black,
        child: Center(child: Text(_showSecond ? 'SECOND PAGE' : 'FIRST PAGE')),
      ),
    );
  }
}
