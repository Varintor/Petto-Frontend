import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/vet_consultation/data/models/consultation_models.dart';
import 'package:petto_application/src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'package:petto_application/src/features/vet_consultation/data/services/consultation_realtime_service.dart';
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
  final clientMessageIds = <String>[];
  bool markedRead = false;
  bool failNextSend = false;
  int listMessagesCalls = 0;
  final appointments = <AppointmentModel>[];
  final sharedAssessments = <SharedAssessmentModel>[];

  @override
  Future<List<ConsultationModel>> listVetConsultations() async => [
    consultation,
  ];

  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) async {
    listMessagesCalls += 1;
    return List.of(messages);
  }

  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  }) async {
    clientMessageIds.add(clientMessageId);
    if (failNextSend) {
      failNextSend = false;
      throw Exception('connection lost');
    }
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
  Future<void> shareAssessment(int consultationId, int assessmentId) async {
    sharedAssessments.add(
      SharedAssessmentModel(
        id: 80,
        consultationId: consultationId,
        assessmentId: assessmentId,
        symptomDescription: 'Lethargic',
        status: 'failed',
        errorCode: 'AI_TIMEOUT',
        sharedAt: DateTime(2026, 8, 14),
        createdAt: DateTime(2026, 8, 13),
      ),
    );
  }

  @override
  Future<List<SharedAssessmentModel>> listSharedAssessments(
    int consultationId,
  ) async => List.of(sharedAssessments);

  @override
  Future<void> revokeAssessment(int consultationId, int assessmentId) async {
    sharedAssessments.removeWhere((item) => item.assessmentId == assessmentId);
  }

  @override
  Future<List<AppointmentModel>> listAppointments(int consultationId) async =>
      List.of(appointments);

  @override
  Future<AppointmentModel> proposeAppointment(
    int consultationId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    final appointment = AppointmentModel(
      id: 50,
      consultationId: consultationId,
      petId: consultation.petId,
      proposedByVetId: consultation.vetId,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
      status: 'proposed',
      createdAt: DateTime(2026, 8, 14),
      updatedAt: DateTime(2026, 8, 14),
    );
    appointments.add(appointment);
    return appointment;
  }

  @override
  Future<AppointmentModel> decideAppointment(
    int appointmentId,
    String decision,
  ) async {
    final previous = appointments.singleWhere(
      (item) => item.id == appointmentId,
    );
    final updated = AppointmentModel(
      id: previous.id,
      consultationId: previous.consultationId,
      petId: previous.petId,
      proposedByVetId: previous.proposedByVetId,
      startsAt: previous.startsAt,
      endsAt: previous.endsAt,
      reason: previous.reason,
      status: decision,
      respondedAt: DateTime(2026, 8, 14, 11),
      createdAt: previous.createdAt,
      updatedAt: DateTime(2026, 8, 14, 11),
    );
    appointments
      ..clear()
      ..add(updated);
    return updated;
  }

  @override
  Future<AppointmentModel> updateAppointment(
    int appointmentId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    final previous = appointments.singleWhere(
      (item) => item.id == appointmentId,
    );
    final updated = AppointmentModel(
      id: previous.id,
      consultationId: previous.consultationId,
      petId: previous.petId,
      proposedByVetId: previous.proposedByVetId,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
      status: previous.status,
      respondedAt: previous.respondedAt,
      createdAt: previous.createdAt,
      updatedAt: DateTime(2026, 8, 15),
    );
    appointments
      ..clear()
      ..add(updated);
    return updated;
  }

  @override
  Future<AppointmentModel> cancelAppointment(int appointmentId) async {
    final previous = appointments.singleWhere(
      (item) => item.id == appointmentId,
    );
    final updated = AppointmentModel(
      id: previous.id,
      consultationId: previous.consultationId,
      petId: previous.petId,
      proposedByVetId: previous.proposedByVetId,
      startsAt: previous.startsAt,
      endsAt: previous.endsAt,
      reason: previous.reason,
      status: 'cancelled',
      respondedAt: previous.respondedAt,
      createdAt: previous.createdAt,
      updatedAt: DateTime(2026, 8, 16),
    );
    appointments
      ..clear()
      ..add(updated);
    return updated;
  }

  @override
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? providerId,
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

class _ControlledOpenRepository extends _FakeConsultationRepository {
  final messagesCompleter = Completer<List<ChatMessageModel>>();
  final readCompleter = Completer<void>();
  bool messagesStarted = false;
  bool readStarted = false;

  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) {
    messagesStarted = true;
    return messagesCompleter.future;
  }

  @override
  Future<void> markMessagesRead(int consultationId) {
    readStarted = true;
    return readCompleter.future;
  }
}

class _FakeHealthCardSharingRepository implements HealthCardSharingRepository {
  final cards = <SharedHealthCardModel>[];

  @override
  Future<List<SharedHealthCardModel>> listSharedHealthCards(
    int consultationId,
  ) async => List.of(cards);

  @override
  Future<SharedHealthCardModel> shareHealthCard(int consultationId) async {
    final card = SharedHealthCardModel(
      id: 70,
      consultationId: consultationId,
      petId: 20,
      snapshot: const {
        'name': 'Milo',
        'allergies': ['Chicken'],
        'chronic_conditions': <String>[],
        'current_medications': <String>[],
      },
      sharedAt: DateTime(2026, 8, 16),
    );
    cards.add(card);
    return card;
  }

  @override
  Future<void> revokeHealthCard(int consultationId, int sharedCardId) async {
    cards.removeWhere((item) => item.id == sharedCardId);
  }
}

class _FakeRealtimeGateway implements ConsultationRealtimeGateway {
  Future<void> Function(Map<String, dynamic> record)? onMessageChanged;
  void Function(bool connected)? onConnectionChanged;
  int? consultationId;
  String? accessToken;
  bool stopped = false;

  @override
  Future<void> watch({
    required int consultationId,
    required String accessToken,
    required Future<void> Function(Map<String, dynamic> record)
    onMessageChanged,
    required void Function(bool connected) onConnectionChanged,
  }) async {
    this.consultationId = consultationId;
    this.accessToken = accessToken;
    this.onMessageChanged = onMessageChanged;
    this.onConnectionChanged = onConnectionChanged;
    onConnectionChanged(true);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  void emitConnection(bool connected) {
    onConnectionChanged?.call(connected);
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

  test('read receipt does not block opening a consultation', () async {
    final repository = _ControlledOpenRepository();
    final controller = ConsultationController(repository: repository);

    final opening = controller.openConsultation(repository.consultation);
    await Future<void>.delayed(Duration.zero);

    expect(repository.messagesStarted, isTrue);
    expect(repository.readStarted, isTrue);
    expect(controller.active?.id, repository.consultation.id);
    expect(controller.loading, isTrue);

    repository.messagesCompleter.complete([]);
    await opening;

    expect(controller.loading, isFalse);
    expect(repository.readCompleter.isCompleted, isFalse);
    repository.readCompleter.complete();
  });

  test('a failed message retry reuses its client message id', () async {
    final repository = _FakeConsultationRepository()..failNextSend = true;
    final controller = ConsultationController(repository: repository);
    await controller.openConsultation(repository.consultation);

    expect(await controller.sendMessage('Please review this.'), isFalse);
    expect(await controller.sendMessage('Please review this.'), isTrue);

    expect(repository.clientMessageIds, hasLength(2));
    expect(repository.clientMessageIds[1], repository.clientMessageIds[0]);
  });

  test(
    'appointment proposal and owner decision update conversation state',
    () async {
      final repository = _FakeConsultationRepository();
      final controller = ConsultationController(repository: repository);
      await controller.openConsultation(repository.consultation);

      final proposed = await controller.proposeAppointment(
        startsAt: DateTime(2026, 8, 20, 9),
        reason: 'Skin follow-up',
      );
      expect(proposed, isTrue);
      expect(controller.appointments.single.status, 'proposed');

      final accepted = await controller.decideAppointment(50, 'accepted');
      expect(accepted, isTrue);
      expect(controller.appointments.single.status, 'accepted');

      final newTime = DateTime(2026, 8, 22, 13, 30);
      expect(
        await controller.updateAppointment(
          50,
          startsAt: newTime,
          reason: 'Rescheduled skin follow-up',
        ),
        isTrue,
      );
      expect(controller.appointments.single.startsAt, newTime);
      expect(controller.appointments.single.status, 'accepted');

      expect(await controller.cancelAppointment(50), isTrue);
      expect(controller.appointments.single.status, 'cancelled');
    },
  );

  test(
    'owner can share and revoke a health-card snapshot in a consultation',
    () async {
      final repository = _FakeConsultationRepository();
      final sharing = _FakeHealthCardSharingRepository();
      final controller = ConsultationController(
        repository: repository,
        healthCardRepository: sharing,
      );
      await controller.openConsultation(repository.consultation);

      expect(await controller.shareHealthCard(), isTrue);
      expect(controller.sharedHealthCards.single.petName, 'Milo');
      expect(controller.sharedHealthCards.single.allergies, ['Chicken']);

      expect(await controller.revokeHealthCard(70), isTrue);
      expect(controller.sharedHealthCards, isEmpty);
    },
  );

  test('owner can share and revoke an assessment with failure state', () async {
    final repository = _FakeConsultationRepository();
    final controller = ConsultationController(repository: repository);
    await controller.openConsultation(repository.consultation);

    expect(await controller.shareAssessment(91), isTrue);
    expect(controller.sharedAssessments.single.failed, isTrue);
    expect(controller.sharedAssessments.single.riskLevel, isNull);
    expect(controller.sharedAssessments.single.errorCode, 'AI_TIMEOUT');

    expect(await controller.revokeAssessment(91), isTrue);
    expect(controller.sharedAssessments, isEmpty);
  });

  test('realtime reconnect reconciles messages exactly once', () async {
    final repository = _FakeConsultationRepository();
    final realtime = _FakeRealtimeGateway();
    final controller = ConsultationController(
      repository: repository,
      realtimeGateway: realtime,
    );
    await controller.openConsultation(
      repository.consultation,
      realtimeAccessToken: 'supabase-access-token',
    );

    expect(repository.listMessagesCalls, 1);
    realtime.emitConnection(false);
    realtime.emitConnection(true);
    await Future<void>.delayed(Duration.zero);

    expect(controller.realtimeConnected, isTrue);
    expect(repository.listMessagesCalls, 2);

    realtime.emitConnection(true);
    await Future<void>.delayed(Duration.zero);
    expect(repository.listMessagesCalls, 2);
  });

  test(
    'realtime event applies a message without an extra REST request',
    () async {
      final repository = _FakeConsultationRepository();
      final realtime = _FakeRealtimeGateway();
      final controller = ConsultationController(
        repository: repository,
        realtimeGateway: realtime,
      );

      await controller.openConsultation(
        repository.consultation,
        realtimeAccessToken: 'supabase-access-token',
      );
      expect(controller.realtimeConnected, isTrue);
      expect(realtime.consultationId, repository.consultation.id);

      final realtimeMessage = ChatMessageModel(
        id: 99,
        consultationId: repository.consultation.id,
        senderType: 'user',
        content: 'Realtime message',
        createdAt: DateTime(2026, 8, 16),
        clientMessageId: 'realtime-99',
      );
      repository.messages.add(realtimeMessage);
      await realtime.onMessageChanged!({
        'id': 99,
        'consultation_id': repository.consultation.id,
        'sender_type': 'user',
        'content': 'Realtime message',
        'attachment_uri': null,
        'created_at': DateTime(2026, 8, 16).toIso8601String(),
        'is_read': false,
        'delivered_at': null,
        'read_at': null,
        'client_message_id': 'realtime-99',
      });

      expect(controller.messages.single.id, 99);
      expect(repository.markedRead, isTrue);
      expect(repository.listMessagesCalls, 1);
    },
  );

  test(
    'duplicate realtime row replaces the message instead of appending',
    () async {
      final repository = _FakeConsultationRepository();
      final realtime = _FakeRealtimeGateway();
      final controller = ConsultationController(
        repository: repository,
        realtimeGateway: realtime,
      );
      await controller.openConsultation(
        repository.consultation,
        realtimeAccessToken: 'supabase-access-token',
      );

      final record = <String, dynamic>{
        'id': 100,
        'consultation_id': repository.consultation.id,
        'sender_type': 'vet',
        'content': 'Initial content',
        'attachment_uri': null,
        'created_at': DateTime(2026, 8, 16, 11).toIso8601String(),
        'is_read': false,
        'delivered_at': null,
        'read_at': null,
        'client_message_id': 'realtime-100',
      };
      repository.messages.add(ChatMessageModel.fromJson(record));
      await realtime.onMessageChanged!(record);
      repository.messages[0] = ChatMessageModel.fromJson({
        ...record,
        'is_read': true,
      });
      await realtime.onMessageChanged!({...record, 'is_read': true});

      expect(controller.messages, hasLength(1));
      expect(controller.messages.single.id, 100);
      expect(controller.messages.single.isRead, isTrue);
    },
  );

  test(
    'realtime row is visible immediately without waiting for REST',
    () async {
      final repository = _FakeConsultationRepository();
      final realtime = _FakeRealtimeGateway();
      final controller = ConsultationController(
        repository: repository,
        realtimeGateway: realtime,
      );
      await controller.openConsultation(
        repository.consultation,
        realtimeAccessToken: 'supabase-access-token',
      );

      final record = <String, dynamic>{
        'id': 101,
        'consultation_id': repository.consultation.id,
        'sender_type': 'user',
        'content': 'Visible immediately',
        'attachment_uri': null,
        'created_at': DateTime(2026, 8, 16, 11, 5).toIso8601String(),
        'is_read': false,
        'delivered_at': null,
        'read_at': null,
        'client_message_id': 'realtime-101',
      };
      await realtime.onMessageChanged!(record);

      expect(controller.messages.single.content, 'Visible immediately');
      expect(repository.listMessagesCalls, 1);
    },
  );
}
