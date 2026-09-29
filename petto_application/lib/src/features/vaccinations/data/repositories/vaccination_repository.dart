import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/vaccination_entity.dart';
import '../models/vaccination_model.dart';

/// Abstract Repository for Vaccination
abstract class VaccinationRepository {
  Future<VaccinationEntity> createVaccination({
    required int petId,
    required String vaccineName,
    required DateTime dateAdministered,
    DateTime? nextDueDate,
    String? clinicName,
    String? notes,
  });

  Future<List<VaccinationEntity>> getPetVaccinations(int petId);
}

/// Repository Implementation for Vaccination
class VaccinationRepositoryImpl implements VaccinationRepository {
  final Dio dio;

  VaccinationRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<VaccinationEntity> createVaccination({
    required int petId,
    required String vaccineName,
    required DateTime dateAdministered,
    DateTime? nextDueDate,
    String? clinicName,
    String? notes,
  }) async {
    try {
      final model = VaccinationModel(
        id: 0, // Will be assigned by backend
        petId: petId,
        vaccineName: vaccineName,
        dateAdministered: dateAdministered,
        nextDueDate: nextDueDate,
        clinicName: clinicName,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final response = await dio.post(
        '/api/v1/vaccinations',
        data: model.toCreateRequestBody(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VaccinationModel.fromJson(response.data).toEntity();
      }
      throw Exception('Failed to create vaccination: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error creating vaccination: $e');
    }
  }

  @override
  Future<List<VaccinationEntity>> getPetVaccinations(int petId) async {
    try {
      final response = await dio.get('/api/v1/pets/$petId/vaccinations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) => VaccinationModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
            )
            .toList();
      }
      throw Exception('Failed to fetch vaccinations: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error fetching vaccinations: $e');
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Cannot reach ${AppConfig.apiBaseUrl}. Check the backend is running.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout talking to the backend.';
      case DioExceptionType.badResponse:
        final detail = e.response?.data is Map
            ? (e.response?.data['detail'] ?? '')
            : '';
        return 'Server error ${e.response?.statusCode}: $detail';
      default:
        return 'Network error: ${e.message}';
    }
  }
}
