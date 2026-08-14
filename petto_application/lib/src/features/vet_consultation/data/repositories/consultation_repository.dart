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
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? assessmentId,
    String? notes,
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
  Future<ConsultationModel> createConsultation({
    required int petId,
    required int vetId,
    int? assessmentId,
    String? notes,
  }) async {
    final response = await dio.post(
      _base,
      data: {
        'pet_id': petId,
        'vet_id': vetId,
        if (assessmentId != null) 'assessment_id': assessmentId,
        if (notes != null) 'notes': notes,
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
  Future<ChatMessageModel> requestAiSummary(int consultationId) async {
    final response = await dio.post('$_base/$consultationId/ai-summary');
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }
}
