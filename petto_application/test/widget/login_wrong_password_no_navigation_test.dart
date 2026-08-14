// Regression test for the "wrong password bounces to the welcome screen" bug.
//
// The login form is rendered by AuthGate for the unauthenticated state. If
// AuthController.login flips the broadcast status to loading/error, AuthGate
// rebuilds and replaces the form (splash -> intro/"welcome" screen), and the
// error is never shown. This test drives the real AuthGate path and asserts a
// failed login keeps the user on the login screen with the error shown.
//
// NOTE: the onboarding UI has an infinitely-repeating button-icon animation, so
// `pumpAndSettle` can never settle here — the test uses fixed-duration pumps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/auth/presentation/screens/auth_gate.dart';
import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/controllers/consultation_controller.dart';

/// Rejects login the way the real repository does on a 401 wrong password.
class _RejectingAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) async {
    // Mimic real network latency so any status flip to `loading` actually gets
    // painted (that is what tore the form down and bounced to the intro).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw Exception('Invalid email or password');
  }

  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) => throw UnimplementedError();
}

class _VeterinarianAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) async => AuthResult(
    accessToken: 'vet-token',
    user: AuthUser(
      id: 2,
      email: email,
      name: 'Dr. Petto Demo',
      role: AccountRole.veterinarian,
    ),
  );

  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) => throw UnimplementedError();
}

class _EmptyConsultationRepository implements ConsultationRepository {
  @override
  Future<List<ConsultationModel>> listVetConsultations() async => [];
  @override
  Future<void> markMessagesRead(int consultationId) async {}
  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) async => [];
  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  }) => throw UnimplementedError();
  @override
  Future<void> shareAssessment(int consultationId, int assessmentId) =>
      throw UnimplementedError();
  @override
  Future<List<AppointmentModel>> listAppointments(int consultationId) async =>
      [];
  @override
  Future<AppointmentModel> proposeAppointment(
    int consultationId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) => throw UnimplementedError();
  @override
  Future<AppointmentModel> decideAppointment(
    int appointmentId,
    String decision,
  ) => throw UnimplementedError();
  @override
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? assessmentId,
    String? notes,
  }) => throw UnimplementedError();
  @override
  Future<List<ConsultationModel>> listPetConsultations(int petId) async => [];
  @override
  Future<List<VetModel>> listVets({bool onlineOnly = false}) async => [];
  @override
  Future<ChatMessageModel> requestAiSummary(int consultationId) =>
      throw UnimplementedError();
}

Future<void> _advance(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('verified veterinarian login routes to the Vet portal', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthController(repository: _VeterinarianAuthRepository());
    final consultation = ConsultationController(
      repository: _EmptyConsultationRepository(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<ConsultationController>.value(
            value: consultation,
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await _advance(tester, 12);

    await tester.tap(find.text('GET STARTED'));
    await _advance(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'staging.vet.demo@petto.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'PettoVet#2026!',
    );
    await tester.tap(find.text('LOGIN'));
    await _advance(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('No pets yet'), findsNothing);
  });

  testWidgets(
    'wrong password stays on the login screen (does not bounce to welcome)',
    (WidgetTester tester) async {
      // No stored token -> AuthGate settles to the unauthenticated onboarding.
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1170, 3200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ignore transient test-font "RenderFlex overflowed" errors.
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
          child: const MaterialApp(home: AuthGate()),
        ),
      );
      // Let tryAutoLogin resolve and the intro reveal settle.
      await _advance(tester, 12);

      // Intro ("welcome") screen -> login gateway.
      expect(find.text('GET STARTED'), findsOneWidget);
      await tester.tap(find.text('GET STARTED'));
      await _advance(tester);
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
      await tester.pump(const Duration(milliseconds: 200)); // alert fade-in

      // Regression guard: we did NOT bounce to the intro/welcome screen...
      expect(find.text('GET STARTED'), findsNothing);
      // ...we are still on the login screen, with the error shown.
      expect(find.text('Login / Register'), findsOneWidget);
      expect(find.text('Wrong password'), findsOneWidget);

      // Flush the top-alert auto-dismiss timer.
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
