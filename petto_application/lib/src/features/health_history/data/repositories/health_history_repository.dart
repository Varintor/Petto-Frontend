import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/health_history_models.dart';
import '../models/public_pet_card_model.dart';

abstract class HealthHistoryRepository {
  Future<HealthCardModel> getHealthCard(int petId);
  Future<HealthProfileModel> updateHealthProfile(
    int petId, {
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  });
  Future<List<HistoryEntryModel>> getHistory(
    int petId, {
    Set<String>? types,
    DateTime? from,
    DateTime? to,
    int limit,
  });
  Future<HistoryDetailModel> getHistoryDetail(
    int petId,
    HistoryEntryModel entry,
  );
  Future<PublicPetCardModel?> getPublicCard(int petId);
  Future<PublicPetCardModel> savePublicCard(
    int petId, {
    required Set<String> visibleFields,
    String? contactMethod,
    String? emergencyNotes,
  });
  Future<PublicPetCardModel> rotatePublicCard(int petId);
  Future<PublicPetCardModel> revokePublicCard(int petId);
}

class HealthHistoryRepositoryImpl implements HealthHistoryRepository {
  final Dio dio;

  HealthHistoryRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<HealthCardModel> getHealthCard(int petId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/health-card',
    );
    return HealthCardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<HealthProfileModel> updateHealthProfile(
    int petId, {
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  }) async {
    final response = await dio.put(
      '${AppConfig.apiPrefix}/pets/$petId/health-profile',
      data: {
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
        'current_medications': currentMedications,
        'notes': notes,
      },
    );
    return HealthProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<HistoryEntryModel>> getHistory(
    int petId, {
    Set<String>? types,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    String d(DateTime v) => v.toIso8601String().split('T').first;
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/history',
      queryParameters: {
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        if (from != null) 'date_from': d(from),
        if (to != null) 'date_to': d(to),
        'limit': limit,
      },
    );
    return ((response.data as Map<String, dynamic>)['entries'] as List<dynamic>)
        .map((j) => HistoryEntryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HistoryDetailModel> getHistoryDetail(
    int petId,
    HistoryEntryModel entry,
  ) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/history/${entry.type}/${entry.refId}',
    );
    return HistoryDetailModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<PublicPetCardModel?> getPublicCard(int petId) async {
    try {
      final response = await dio.get(AppConfig.petPublicCardEndpoint(petId));
      return PublicPetCardModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<PublicPetCardModel> savePublicCard(
    int petId, {
    required Set<String> visibleFields,
    String? contactMethod,
    String? emergencyNotes,
  }) async {
    final response = await dio.put(
      AppConfig.petPublicCardEndpoint(petId),
      data: {
        'is_active': true,
        'visible_fields': visibleFields.toList()..sort(),
        'contact_method': contactMethod,
        'emergency_notes': emergencyNotes,
      },
    );
    return PublicPetCardModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<PublicPetCardModel> rotatePublicCard(int petId) async {
    final response = await dio.post(
      '${AppConfig.petPublicCardEndpoint(petId)}/rotate',
    );
    return PublicPetCardModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<PublicPetCardModel> revokePublicCard(int petId) async {
    final response = await dio.post(
      '${AppConfig.petPublicCardEndpoint(petId)}/revoke',
    );
    return PublicPetCardModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

/// Timeline state for the Health History screen. Same pattern as the other
/// controllers: null petId (guest / no pet yet) skips loading (SRS-F2-018).
