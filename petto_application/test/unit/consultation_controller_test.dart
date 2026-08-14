import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'package:petto_application/src/features/vet_consultation/presentation/controllers/consultation_controller.dart';

class _FakeConsultationRepository implements ConsultationRepository {
  final consultation = ConsultationModel(
    id: 10,
    petId: 20,
    vetId: 30,
    status: 'ACTIVE',
    createdAt: DateTime(2026, 8, 13, 9),
  );
  final messages = <ChatMessageModel>[];
  bool markedRead = false;

  @override
  Future<List<ConsultationModel>> listVetConsultations() async => [
    consultation,
  ];

  @override
  Future<List<ChatMessageModel>> listMessages(int consultationId) async =>
      List.of(messages);

  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content,
  ) async {
    final message = ChatMessageModel(
      id: messages.length + 1,
      consultationId: consultationId,
      senderType: 'vet',
      content: content,
      createdAt: DateTime(2026, 8, 13, 10),
    );
    messages.add(message);
    return message;
  }

  @override
  Future<void> markMessagesRead(int consultationId) async {
    markedRead = true;
  }

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

class _ControlledOpenRepository extends _FakeConsultationRepository {
  final messagesCompleter = Completer<List<ChatMessageModel>>();
  final readCompleter = Completer<void>();
  bool messagesStarted = false;
  bool readStarted = false;

  @override
  Future<List<ChatMessageModel>> listMessages(int consultationId) {
    messagesStarted = true;
    return messagesCompleter.future;
  }

  @override
  Future<void> markMessagesRead(int consultationId) {
    readStarted = true;
    return readCompleter.future;
  }
}

void main() {
  test(
    'vet loads assigned consultation, opens it, and sends a reply',
    () async {
      final repository = _FakeConsultationRepository();
      final controller = ConsultationController(repository: repository);

      await controller.loadVetConsultations();
      expect(controller.consultations, hasLength(1));

      await controller.openConsultation(controller.consultations.single);
      expect(controller.active?.id, 10);
      expect(repository.markedRead, isTrue);

      final sent = await controller.sendMessage('Please send another photo.');
      expect(sent, isTrue);
      expect(controller.messages.single.senderType, 'vet');
      expect(controller.messages.single.content, 'Please send another photo.');
    },
  );

  test('message loading and read receipt start concurrently', () async {
    final repository = _ControlledOpenRepository();
    final controller = ConsultationController(repository: repository);

    final opening = controller.openConsultation(repository.consultation);
    await Future<void>.delayed(Duration.zero);

    expect(repository.messagesStarted, isTrue);
    expect(repository.readStarted, isTrue);
    expect(controller.active?.id, repository.consultation.id);
    expect(controller.loading, isTrue);

    repository.messagesCompleter.complete([]);
    repository.readCompleter.complete();
    await opening;

    expect(controller.loading, isFalse);
  });
}
