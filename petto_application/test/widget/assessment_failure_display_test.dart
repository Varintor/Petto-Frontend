import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/health_assessment/domain/entities/assessment_entity.dart';
import 'package:petto_application/src/features/health_assessment/presentation/widgets/result_display_widget.dart';

void main() {
  testWidgets('failed AI result shows retry and no fabricated risk', (
    tester,
  ) async {
    final assessment = AssessmentEntity(
      id: 1,
      petId: 2,
      symptoms: 'Limping',
      riskLevel: '',
      aiResponse: '',
      status: 'failed',
      errorCode: 'AI_TIMEOUT',
      createdAt: DateTime(2026, 8, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultDisplayWidget(assessment: assessment, onReset: () {}),
        ),
      ),
    );

    expect(find.text('Analysis failed'), findsOneWidget);
    expect(find.textContaining('No risk level was assigned'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.textContaining('Moderate Risk'), findsNothing);
  });
}
