import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/consultation_models.dart';

/// Feature 3: Veterinary Consultation with AI Assistance.
///
/// Talks to the FastAPI consultation endpoints (Bearer token attached by
/// [ApiClient]). Replaces the local-only mock chat in home_consult_screen_part
/// once the UI is rewired (Progress II).
abstract class ConsultationRepository {
  Future<List<VetModel>> listVets({bool onlineOnly});
  Future<List<VeterinaryProviderModel>> listProviders({
    double? latitude,
    double? longitude,
  });
  Future<List<VetModel>> listProviderVets(int providerId);
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? providerId,
    int? assessmentId,
    String? subject,
    String? notes,
    String priority,
    bool urgentHelpAcknowledged,
  });
  Future<List<ConsultationModel>> listPetConsultations(int petId);
  Future<List<ConsultationModel>> listVetConsultations();
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  });
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  });
  Future<void> markMessagesRead(int consultationId);
  Future<void> shareAssessment(int consultationId, int assessmentId);
  Future<List<SharedAssessmentModel>> listSharedAssessments(int consultationId);
  Future<void> revokeAssessment(int consultationId, int assessmentId);
  Future<List<AppointmentModel>> listAppointments(int consultationId);
  Future<AppointmentModel> proposeAppointment(
    int consultationId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  });
  Future<AppointmentModel> decideAppointment(
    int appointmentId,
    String decision,
  );
  Future<AppointmentModel> updateAppointment(
    int appointmentId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  });
  Future<AppointmentModel> cancelAppointment(int appointmentId);

  /// Posts a server-generated AI briefing (pet profile + latest assessment +
  /// activity totals + vaccination status) into the chat as sender 'ai'.
  Future<ChatMessageModel> requestAiSummary(int consultationId);
}

class ConsultationRepositoryImpl implements ConsultationRepository {
  final Dio dio;
  static const String _base = '${AppConfig.apiPrefix}/consultations';

  ConsultationRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<List<VetModel>> listVets({bool onlineOnly = false}) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/veterinarians',
      queryParameters: {'online_only': onlineOnly},
    );
    return (response.data as List<dynamic>)
        .map((j) => VetModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VeterinaryProviderModel>> listProviders({
    double? latitude,
    double? longitude,
  }) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/veterinary-providers',
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => VeterinaryProviderModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<List<VetModel>> listProviderVets(int providerId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/veterinary-providers/$providerId/veterinarians',
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => VetModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

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
  }) async {
    final response = await dio.post(
      _base,
      data: {
        'pet_id': petId,
        'vet_id': vetId,
        if (providerId != null) 'provider_id': providerId,
        if (assessmentId != null) 'assessment_id': assessmentId,
        if (subject != null) 'subject': subject,
        if (notes != null) 'notes': notes,
        'priority': priority,
        if (priority == 'urgent')
          'urgent_help_acknowledged': urgentHelpAcknowledged,
      },
    );
    return ConsultationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ConsultationModel>> listPetConsultations(int petId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/consultations',
    );
    return (response.data as List<dynamic>)
        .map((j) => ConsultationModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConsultationModel>> listVetConsultations() async {
    final response = await dio.get('${AppConfig.apiPrefix}/vet/consultations');
    return (response.data as List<dynamic>)
        .map((j) => ConsultationModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChatMessageModel>> listMessages(
    int consultationId, {
    int? afterId,
  }) async {
    final response = await dio.get(
      '$_base/$consultationId/messages',
      queryParameters: {if (afterId != null) 'after_id': afterId},
    );
    return (response.data as List<dynamic>)
        .map((j) => ChatMessageModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessageModel> sendMessage(
    int consultationId,
    String content, {
    required String clientMessageId,
  }) async {
    final response = await dio.post(
      '$_base/$consultationId/messages',
      data: {'content': content, 'client_message_id': clientMessageId},
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> markMessagesRead(int consultationId) async {
    await dio.post('$_base/$consultationId/messages/read');
  }

  @override
  Future<void> shareAssessment(int consultationId, int assessmentId) async {
    await dio.post(
      '$_base/$consultationId/shared-assessments',
      data: {'assessment_id': assessmentId},
    );
  }

  @override
  Future<List<SharedAssessmentModel>> listSharedAssessments(
    int consultationId,
  ) async {
    final response = await dio.get('$_base/$consultationId/shared-assessments');
    return (response.data as List<dynamic>)
        .map(
          (item) => SharedAssessmentModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> revokeAssessment(int consultationId, int assessmentId) async {
    await dio.delete('$_base/$consultationId/shared-assessments/$assessmentId');
  }

  @override
  Future<List<AppointmentModel>> listAppointments(int consultationId) async {
    final response = await dio.get('$_base/$consultationId/appointments');
    return (response.data as List<dynamic>)
        .map(
          (item) =>
              AppointmentModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<AppointmentModel> proposeAppointment(
    int consultationId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    final response = await dio.post(
      '$_base/$consultationId/appointments',
      data: {
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AppointmentModel> decideAppointment(
    int appointmentId,
    String decision,
  ) async {
    final response = await dio.put(
      '${AppConfig.apiPrefix}/appointments/$appointmentId/decision',
      data: {'decision': decision},
    );
    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AppointmentModel> updateAppointment(
    int appointmentId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    final response = await dio.put(
      '${AppConfig.apiPrefix}/appointments/$appointmentId',
      data: {
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'reason': reason?.trim(),
      },
    );
    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AppointmentModel> cancelAppointment(int appointmentId) async {
    final response = await dio.put(
      '${AppConfig.apiPrefix}/appointments/$appointmentId/cancel',
    );
    return AppointmentModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<ChatMessageModel> requestAiSummary(int consultationId) async {
    final response = await dio.post('$_base/$consultationId/ai-summary');
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }
}

abstract class HealthCardSharingRepository {
  Future<List<SharedHealthCardModel>> listSharedHealthCards(int consultationId);
  Future<SharedHealthCardModel> shareHealthCard(int consultationId);
  Future<void> revokeHealthCard(int consultationId, int sharedCardId);
}

class HealthCardSharingRepositoryImpl implements HealthCardSharingRepository {
  HealthCardSharingRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  final Dio dio;
  static const String _base = '${AppConfig.apiPrefix}/consultations';

  @override
  Future<List<SharedHealthCardModel>> listSharedHealthCards(
    int consultationId,
  ) async {
    final response = await dio.get(
      '$_base/$consultationId/shared-health-cards',
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => SharedHealthCardModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<SharedHealthCardModel> shareHealthCard(int consultationId) async {
    final response = await dio.post(
      '$_base/$consultationId/shared-health-cards',
    );
    return SharedHealthCardModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> revokeHealthCard(int consultationId, int sharedCardId) async {
    await dio.delete(
      '$_base/$consultationId/shared-health-cards/$sharedCardId',
    );
  }
}
