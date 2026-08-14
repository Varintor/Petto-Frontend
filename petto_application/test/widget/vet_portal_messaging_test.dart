import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/controllers/consultation_controller.dart';
import 'package:petto_application/src/features/vet_portal/presentation/screens/vet_portal_screen.dart';

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<bool> checkEmailAvailability(String email) =>
      throw UnimplementedError();
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

class _MessagingRepository implements ConsultationRepository {
  final consultation = ConsultationModel(
    id: 1,
    petId: 9,
    vetId: 5,
    status: 'ACTIVE',
    notes: 'Skin follow-up',
    petName: 'Milo',
    petSpecies: 'cat',
    ownerName: 'Warit',
    createdAt: DateTime(2026, 8, 13, 9),
  );

  @override
  Future<List<ConsultationModel>> listVetConsultations() async => [
    consultation,
  ];
  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) async => [
    ChatMessageModel(
      id: 1,
      consultationId: consultationId,
      senderType: 'user',
      content: 'Milo is still scratching.',
      createdAt: DateTime(2026, 8, 13, 9, 30),
    ),
  ];
  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  }) async => ChatMessageModel(
    id: 2,
    consultationId: consultationId,
    senderType: 'vet',
    content: content,
    createdAt: DateTime(2026, 8, 13, 9, 35),
  );
  @override
  Future<void> markMessagesRead(int consultationId) async {}
  @override
  Future<void> shareAssessment(int consultationId, int assessmentId) async {}
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
  Future<List<ConsultationModel>> listPetConsultations(int petId) =>
      throw UnimplementedError();
  @override
  Future<List<VetModel>> listVets({bool onlineOnly = false}) =>
      throw UnimplementedError();
  @override
  Future<ChatMessageModel> requestAiSummary(int consultationId) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('vet opens assigned thread and sends a backend reply', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthController(repository: _UnusedAuthRepository());
    final consultation = ConsultationController(
      repository: _MessagingRepository(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<ConsultationController>.value(
            value: consultation,
          ),
        ],
        child: const MaterialApp(home: VetPortalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Messages'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Milo'), findsWidgets);

    await tester.tap(find.widgetWithText(ListTile, 'Milo'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Milo is still scratching.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Please send a new photo.');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Please send a new photo.'), findsOneWidget);
  });
}
