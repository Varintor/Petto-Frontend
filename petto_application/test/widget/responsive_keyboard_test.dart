import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/auth/presentation/screens/password_recovery_screen.dart';
import 'package:petto_application/src/features/health_assessment/data/repositories/health_assessment_repository.dart';
import 'package:petto_application/src/features/health_assessment/domain/entities/assessment_entity.dart';
import 'package:petto_application/src/features/health_assessment/presentation/controllers/health_assessment_controller.dart';
import 'package:petto_application/src/features/health_assessment/presentation/screens/health_assessment_screen.dart';
import 'package:petto_application/src/features/pet_management/domain/entities/pet_entity.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/pet_form_screen.dart';
import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/widgets/shared_assessment_card.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/widgets/shared_health_card.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) => throw UnimplementedError();
}

class _FakeAssessmentRepository implements HealthAssessmentRepository {
  @override
  Future<List<AssessmentEntity>> getAssessmentHistory() async => [];

  @override
  Future<List<AssessmentEntity>> getPetAssessmentHistory(int petId) async => [];

  @override
  Future<AssessmentEntity> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData,
    int? petId,
  }) => throw UnimplementedError();
}

void _useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _showPhoneKeyboard(WidgetTester tester, Finder field) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.tap(field);
  await tester.showKeyboard(field);
  tester.view.viewInsets = const FakeViewPadding(bottom: 280);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('login stays usable on a small phone with keyboard open', (
    tester,
  ) async {
    _useSmallPhone(tester);
    final auth = AuthController(repository: _FakeAuthRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: const MaterialApp(
          home: AuthOnboardingScreen(startAtLogin: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final email = find.widgetWithText(TextField, 'Email address');
    await _showPhoneKeyboard(tester, email);

    expect(email, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('add pet fields do not overflow above the phone keyboard', (
    tester,
  ) async {
    _useSmallPhone(tester);
    await tester.pumpWidget(const MaterialApp(home: PetFormScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final weight = find.widgetWithText(TextField, 'Weight (kg)');
    await _showPhoneKeyboard(tester, weight);

    expect(weight, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('birthday year stays on one line on a small phone', (
    tester,
  ) async {
    _useSmallPhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PetFormScreen(
          initial: PetEntity(
            name: 'Milo',
            species: 'dog',
            dateOfBirth: DateTime(2025, 1, 1),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byTooltip('Clear birthday'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('2025'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('password recovery remains scrollable with keyboard open', (
    tester,
  ) async {
    _useSmallPhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryScreen(
          onComplete: () {},
          updatePassword: (_) async {},
        ),
      ),
    );
    await tester.pump();

    final confirmation = find.byKey(const Key('recovery-confirm-password'));
    await _showPhoneKeyboard(tester, confirmation);

    expect(confirmation, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'health assessment keeps the focused form close to the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => HealthAssessmentController(
            repository: _FakeAssessmentRepository(),
          ),
          child: const MaterialApp(
            home: HealthAssessmentScreen(
              showHero: false,
              compactMode: true,
              availablePets: [
                HealthAssessmentPetOption(
                  id: 'milo',
                  petId: 1,
                  name: 'Milo',
                  species: 'dog',
                  breed: 'Mixed breed',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final symptoms = find.widgetWithText(
        TextField,
        'e.g. Redness on the ear, scratching a lot...',
      );
      await tester.scrollUntilVisible(
        symptoms,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(symptoms);
      await tester.showKeyboard(symptoms);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final keyboardTop =
          tester.view.physicalSize.height / tester.view.devicePixelRatio - 320;
      final actionButton = find.ancestor(
        of: find.text('Start AI Analysis'),
        matching: find.byType(FilledButton),
      );
      final actionBottom = tester.getBottomRight(actionButton).dy;
      expect(actionBottom, lessThan(keyboardTop));
      expect(keyboardTop - actionBottom, inInclusiveRange(24, 52));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared chat cards fit a narrow screen with larger text', (
    tester,
  ) async {
    _useSmallPhone(tester);
    final assessment = SharedAssessmentModel(
      id: 1,
      consultationId: 2,
      assessmentId: 3,
      symptomDescription: 'Persistent skin irritation and loss of appetite',
      status: 'completed',
      sharedAt: DateTime(2026, 9, 30),
      createdAt: DateTime(2026, 9, 30),
      riskLevel: 'Moderate Risk',
      aiRawResponse: 'Observe symptoms and arrange a follow-up.',
    );
    final healthCard = SharedHealthCardModel(
      id: 1,
      consultationId: 2,
      petId: 3,
      sharedAt: DateTime(2026, 9, 30),
      snapshot: const {
        'name': 'Alexander the Companion',
        'species': 'Cat',
        'breed': 'Domestic Long Hair Mixed Breed',
        'blood_type': 'Not set',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              SharedAssessmentPanel(assessment: assessment, onRevoke: () {}),
              SharedHealthCardPanel(card: healthCard, onRevoke: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
