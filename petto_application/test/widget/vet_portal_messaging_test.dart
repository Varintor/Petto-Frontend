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
  final List<String> sentMessages = [];

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
  }) async {
    sentMessages.add(content);
    return ChatMessageModel(
      id: sentMessages.length + 1,
      consultationId: consultationId,
      senderType: 'vet',
      content: content,
      createdAt: DateTime(2026, 8, 13, 9, 35),
    );
  }

  @override
  Future<void> markMessagesRead(int consultationId) async {}
  @override
  Future<void> shareAssessment(int consultationId, int assessmentId) async {}
  @override
  Future<List<SharedAssessmentModel>> listSharedAssessments(
    int consultationId,
  ) async => [];
  @override
  Future<void> revokeAssessment(int consultationId, int assessmentId) async {}
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
  Future<AppointmentModel> updateAppointment(
    int appointmentId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) => throw UnimplementedError();
  @override
  Future<AppointmentModel> cancelAppointment(int appointmentId) =>
      throw UnimplementedError();
  @override
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? providerId,
    int? assessmentId,
    String? subject,
    String? notes,
    String priority = 'normal',
    bool urgentHelpAcknowledged = false,
  }) => throw UnimplementedError();
  @override
  Future<List<ConsultationModel>> listPetConsultations(int petId) =>
      throw UnimplementedError();
  @override
  Future<List<VetModel>> listVets({bool onlineOnly = false}) =>
      throw UnimplementedError();
  @override
  Future<List<VeterinaryProviderModel>> listProviders({
    double? latitude,
    double? longitude,
  }) async => [];
  @override
  Future<List<VetModel>> listProviderVets(int providerId) async => [];
  @override
  Future<ChatMessageModel> requestAiSummary(int consultationId) =>
      throw UnimplementedError();
}

class _HealthCardRepository implements HealthCardSharingRepository {
  _HealthCardRepository({required this.cards});

  final List<SharedHealthCardModel> cards;

  @override
  Future<List<SharedHealthCardModel>> listSharedHealthCards(
    int consultationId,
  ) async => cards
      .where((card) => card.consultationId == consultationId)
      .toList(growable: false);

  @override
  Future<void> revokeHealthCard(int consultationId, int sharedCardId) async {}

  @override
  Future<SharedHealthCardModel> shareHealthCard(int consultationId) =>
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

    await tester.tap(find.byKey(const Key('vet-consultation-1')).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Milo is still scratching.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('vet-request-health-card')));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      "Please share Milo's Pet Health Card so I can review the latest health information.",
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining("share Milo's Pet Health Card"), findsOneWidget);

    await tester.tap(find.byKey(const Key('vet-quick-reply-photo')));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Please send a clear photo of the affected area.',
    );

    await tester.enterText(find.byType(TextField), 'Please send a new photo.');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Please send a new photo.'), findsOneWidget);
  });

  testWidgets('patients shows an owner-shared Health Card read-only', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthController(repository: _UnusedAuthRepository());
    final consultationRepository = _MessagingRepository();
    final sharedCard = SharedHealthCardModel(
      id: 31,
      consultationId: 1,
      petId: 9,
      snapshot: {
        'name': 'Milo',
        'species': 'Cat',
        'breed': 'Domestic Shorthair',
        'blood_type': 'A',
        'allergies': ['Chicken'],
        'chronic_conditions': ['Dermatitis'],
        'current_medications': ['Topical cream'],
        'latest_vaccination': {'title': 'Rabies'},
      },
      sharedAt: DateTime(2026, 8, 13, 10),
    );
    final consultation = ConsultationController(
      repository: consultationRepository,
      healthCardRepository: _HealthCardRepository(cards: [sharedCard]),
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

    await tester.tap(find.text('Patients').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('vet-patient-health-card')), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(find.text('Dermatitis'), findsOneWidget);
    expect(find.text('Topical cream'), findsOneWidget);
    expect(find.text('Rabies'), findsOneWidget);
    expect(find.text('Request Health Card'), findsNothing);
  });

  testWidgets('patients can request a Health Card when it is not shared', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthController(repository: _UnusedAuthRepository());
    final consultationRepository = _MessagingRepository();
    final consultation = ConsultationController(
      repository: consultationRepository,
      healthCardRepository: _HealthCardRepository(cards: []),
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

    await tester.tap(find.text('Patients').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pet Health Card not shared'), findsOneWidget);

    await tester.tap(find.byKey(const Key('vet-patient-request-health-card')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(consultationRepository.sentMessages, [
      "Please share Milo's Pet Health Card so I can review the latest health information.",
    ]);
    expect(find.text('Health Card request sent to Warit.'), findsOneWidget);
  });
}
