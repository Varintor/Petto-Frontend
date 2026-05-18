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
  });

  Future<List<AssessmentEntity>> getAssessmentHistory();
}

class HealthAssessmentRepositoryImpl implements HealthAssessmentRepository {
  final Dio dio;

  HealthAssessmentRepositoryImpl({Dio? dio})
      : dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectionTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          sendTimeout: AppConfig.sendTimeout,
          // Enable detailed logging for debugging
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ))..interceptors.add(LogInterceptor(
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
  }) async {
    try {
      final formData = FormData.fromMap({
        'pet_name': petName,
        'pet_type': petType,
        if (symptoms != null) 'symptoms': symptoms,
      });

      // Handle image differently for web vs mobile
      if (imageData != null) {
        if (kIsWeb) {
          // Web: imageData is List<int> or Uint8List
          if (imageData is Uint8List) {
            formData.files.add(MapEntry(
              'image',
              MultipartFile.fromBytes(
                imageData,
                filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            ));
          } else if (imageData is List<int>) {
            formData.files.add(MapEntry(
              'image',
              MultipartFile.fromBytes(
                imageData,
                filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            ));
          }
        } else {
          // Mobile: imageData is File
          if (imageData is File) {
            formData.files.add(MapEntry(
              'image',
              await MultipartFile.fromFile(
                imageData.path,
                filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            ));
          }
        }
      }

      final response = await dio.post(
        AppConfig.healthAssessmentEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = (sent / total * 100).toStringAsFixed(0);
            print('Upload progress: $progress%');
          }
        },
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final model = AssessmentModel.fromJson(response.data);
        return model.toEntity();
      } else {
        throw Exception('Failed to submit assessment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout (60s). Backend may be down or IP unreachable.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Receive timeout (60s). AI processing may be taking too long.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Send timeout (60s). Image upload may be too large.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Connection error: Cannot reach ${AppConfig.apiBaseUrl}. Check if backend is running and IP is correct.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'Server error: ${e.response?.statusCode} - ${e.response?.statusMessage}';
      }

      throw Exception('$errorMessage\nDetails: ${e.message}');
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }

  @override
  Future<List<AssessmentEntity>> getAssessmentHistory() async {
    try {
      final response = await dio.get(AppConfig.healthAssessmentEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData
            .map((json) => AssessmentModel.fromJson(json).toEntity())
            .toList();
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to ${AppConfig.apiBaseUrl}';
      }

      throw Exception('$errorMessage\nDetails: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching assessment history: $e');
    }
  }
}
