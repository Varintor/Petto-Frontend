import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/controllers/consultation_controller.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/screens/owner_consultation_screen.dart';

class _OwnerMessagingRepository implements ConsultationRepository {
  final vet = VetModel(
    id: 7,
    name: 'Dr. Test',
    specialty: 'General practice',
    isOnline: true,
  );
  final messages = <ChatMessageModel>[];
  String? sentClientMessageId;

  @override
  Future<List<VetModel>> listVets({bool onlineOnly = false}) async => [vet];

  @override
  Future<List<ConsultationModel>> listPetConsultations(int petId) async => [];

  @override
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? assessmentId,
    String? notes,
  }) async => ConsultationModel(
    id: 12,
    petId: petId,
    vetId: vetId,
    status: 'ACTIVE',
    assessmentId: assessmentId,
    petName: 'Milo',
    vetName: vet.name,
    createdAt: DateTime(2026, 8, 14),
  );

  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) async => messages.where((message) => message.id > (afterId ?? 0)).toList();

  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  }) async {
    sentClientMessageId = clientMessageId;
    final message = ChatMessageModel(
      id: 1,
      consultationId: consultationId,
      senderType: 'user',
      content: content,
      clientMessageId: clientMessageId,
      deliveredAt: DateTime(2026, 8, 14),
      createdAt: DateTime(2026, 8, 14),
    );
    messages.add(message);
    return message;
  }

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
  Future<ChatMessageModel> requestAiSummary(int consultationId) async {
    final message = ChatMessageModel(
      id: 99,
      consultationId: consultationId,
      senderType: 'ai',
      content: 'Assessment briefing',
      createdAt: DateTime(2026, 8, 14),
    );
    messages.add(message);
    return message;
  }

  @override
  Future<List<ConsultationModel>> listVetConsultations() async => [];
}

class _OwnerAppointmentRepository extends _OwnerMessagingRepository {
  AppointmentModel appointment = AppointmentModel(
    id: 91,
    consultationId: 12,
    petId: 5,
    proposedByVetId: 7,
    startsAt: DateTime(2026, 8, 20, 9),
    reason: 'Skin follow-up',
    status: 'proposed',
    createdAt: DateTime(2026, 8, 14),
    updatedAt: DateTime(2026, 8, 14),
  );

  @override
  Future<List<ConsultationModel>> listPetConsultations(int petId) async => [
    ConsultationModel(
      id: 12,
      petId: petId,
      vetId: vet.id,
      status: 'ACTIVE',
      petName: 'Milo',
      vetName: vet.name,
      createdAt: DateTime(2026, 8, 14),
    ),
  ];

  @override
  Future<List<AppointmentModel>> listAppointments(int consultationId) async => [
    appointment,
  ];

  @override
  Future<AppointmentModel> decideAppointment(
    int appointmentId,
    String decision,
  ) async {
    appointment = AppointmentModel(
      id: appointment.id,
      consultationId: appointment.consultationId,
      petId: appointment.petId,
      proposedByVetId: appointment.proposedByVetId,
      startsAt: appointment.startsAt,
      reason: appointment.reason,
      status: decision,
      respondedAt: DateTime(2026, 8, 14, 10),
      createdAt: appointment.createdAt,
      updatedAt: DateTime(2026, 8, 14, 10),
    );
    return appointment;
  }
}

void main() {
  testWidgets('owner starts a backend consultation and sends a message', (
    tester,
  ) async {
    final repository = _OwnerMessagingRepository();
    final controller = ConsultationController(repository: repository);

    await tester.pumpWidget(
      ChangeNotifierProvider<ConsultationController>.value(
        value: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: OwnerConsultationScreen(
              petId: 5,
              petName: 'Milo',
              latestAssessmentId: 88,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Dr. Test'), findsOneWidget);
    await tester.tap(find.text('Consult'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Assessment briefing'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Milo needs help.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.text('Milo needs help.'), findsOneWidget);
    expect(repository.sentClientMessageId, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('owner accepts a proposal and requests calendar refresh', (
    tester,
  ) async {
    final repository = _OwnerAppointmentRepository();
    final controller = ConsultationController(repository: repository);
    var calendarRefreshed = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<ConsultationController>.value(
        value: controller,
        child: MaterialApp(
          home: Scaffold(
            body: OwnerConsultationScreen(
              petId: 5,
              petName: 'Milo',
              onAppointmentAccepted: () async {
                calendarRefreshed = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(ListTile, 'Dr. Test').first);
    await tester.pump();
    await tester.pump();
    expect(find.text('Skin follow-up'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump();

    expect(calendarRefreshed, isTrue);
    expect(find.text('ACCEPTED'), findsOneWidget);
    expect(find.textContaining('Added to the pet Calendar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
