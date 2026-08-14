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
}
