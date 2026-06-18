import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/assessment_entity.dart';
import '../models/assessment_model.dart';

abstract class HealthAssessmentRepository {
  Future<AssessmentEntity> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData, // File for mobile, Uint8List for web
    int? petId,
  });

  Future<List<AssessmentEntity>> getAssessmentHistory();

  Future<List<AssessmentEntity>> getPetAssessmentHistory(int petId);
}

class HealthAssessmentRepositoryImpl implements HealthAssessmentRepository {
  final Dio dio;

  HealthAssessmentRepositoryImpl({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectionTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              // NOTE: do NOT hard-code a multipart Content-Type here. Dio sets
              // the correct multipart boundary automatically for FormData, and
              // forcing it would corrupt both uploads and plain GET requests.
              headers: {'Accept': 'application/json'},
            ))
          ..interceptors.add(LogInterceptor(
            request: true,
            requestHeader: true,
            requestBody: true,
            responseHeader: false,
            responseBody: true,
            error: true,
          ));

  @override
  Future<AssessmentEntity> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData,
    int? petId,
  }) async {
    // The backend requires an image (image: UploadFile = File(...)). Fail fast
    // with a friendly message instead of letting it 400 server-side.
    if (imageData == null) {
      throw Exception('Please add a pet photo before starting the analysis');
    }

    try {
      final formData = FormData.fromMap({
        // Backend Form fields: pet_id (int), symptom_description (str).
        // Use the caller's real pet id; fall back to the seed pet only when
        // none was provided (guest/mock mode) so we never silently write a
        // real user's assessment onto the seed pet (Milo).
        'pet_id': petId ?? AppConfig.defaultPetId,
        'symptom_description': (symptoms == null || symptoms.trim().isEmpty)
            ? 'No additional symptoms described'
            : symptoms.trim(),
      });

      final filename = 'pet_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) {
        if (imageData is Uint8List) {
          formData.files.add(MapEntry(
            'image',
            MultipartFile.fromBytes(imageData, filename: filename),
          ));
        } else if (imageData is List<int>) {
          formData.files.add(MapEntry(
            'image',
            MultipartFile.fromBytes(imageData, filename: filename),
          ));
        }
      } else if (imageData is File) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageData.path, filename: filename),
        ));
      }

      final response = await dio.post(
        AppConfig.assessmentsEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AssessmentModel.fromJson(response.data)
            .toEntity(petName: petName, petType: petType);
      }
      throw Exception('Failed to submit assessment: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }

  @override
  Future<List<AssessmentEntity>> getAssessmentHistory() async {
    try {
      final response = await dio.get(AppConfig.assessmentsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData
            .map((json) =>
                AssessmentModel.fromJson(json as Map<String, dynamic>).toEntity())
            .toList();
      }
      throw Exception('Failed to fetch history: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error fetching assessment history: $e');
    }
  }

  @override
  Future<List<AssessmentEntity>> getPetAssessmentHistory(int petId) async {
    try {
      final response = await dio.get(AppConfig.petAssessmentsEndpoint(petId));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData
            .map((json) =>
                AssessmentModel.fromJson(json as Map<String, dynamic>).toEntity())
            .toList();
      }
      throw Exception('Failed to fetch pet history: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error fetching pet assessment history: $e');
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Backend may be down or unreachable.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. AI processing may be taking too long.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. The image upload may be too large.';
      case DioExceptionType.connectionError:
        return 'Cannot reach ${AppConfig.apiBaseUrl}. '
            'Check the backend is running and the IP/URL is correct.';
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
