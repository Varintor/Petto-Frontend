import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/assessment_entity.dart';
import '../models/assessment_model.dart';

/// Abstract Repository สำหรับ Health Assessment
abstract class HealthAssessmentRepository {
  Future<AssessmentEntity> submitAssessment({
    required int petId,
    required String symptomDescription,
    File? imageFile,
    Uint8List? imageBytes,
  });

  Future<List<AssessmentEntity>> getAssessmentHistory();

  Future<Map<String, dynamic>> checkConnection();
}

/// Repository Implementation สำหรับเชื่อมต่อกับ Railway FastAPI Backend
///
/// Railway Production URL: https://petto-backend-production.up.railway.app
///
/// Parameters ที่ส่งไป Backend:
/// - pet_id (int): ID ของสัตว์เลี้ยง
/// - symptom_description (String): รายละเอียดอาการ
/// - image (File): ไฟล์รูปภาพ (optional)
class HealthAssessmentRepositoryImpl implements HealthAssessmentRepository {
  final Dio dio;

  HealthAssessmentRepositoryImpl({Dio? dio})
      : dio = dio ?? _createDioInstance();

  /// สร้าง Dio Instance พร้อมการตั้งค่าครบถ้วนสำหรับ Railway
  static Dio _createDioInstance() {
    final dio = Dio(BaseOptions(
      // Base URL จาก AppConfig (Railway Production)
      baseUrl: AppConfig.apiBaseUrl,

      // Timeout Settings (60 วินาทีสำหรับ AI Gemini processing บน Cloud)
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),

      // Headers สำหรับ Railway (HTTPS + CORS)
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        // ไม่ต้องใส่ Content-Type ที่นี่ เพราะ Dio จะใส่ให้อัตโนมีติเมื่อใช้ FormData
      },

      // รองรับ response codes
      validateStatus: (status) {
        return status != null && status >= 200 && status < 300;
      },
    ));

    // Interceptor: Logging
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: false, // ไม่ log binary data
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) {
        if (kDebugMode) print(obj);
      },
    ));

    // Interceptor: Retry กรณี timeout (AI ประมวลผลนาน)
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          if (kDebugMode) {
            print('🔄 Timeout occurred (AI processing), retrying...');
          }

          try {
            final opts = Options(
              method: error.requestOptions.method,
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
            );

            final response = await dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: opts,
            );

            if (kDebugMode) {
              print('✅ Retry successful!');
            }

            return handler.resolve(response);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Retry failed: $e');
            }
          }
        }

        return handler.next(error);
      },
    ));

    return dio;
  }

  @override
  Future<AssessmentEntity> submitAssessment({
    required int petId,
    required String symptomDescription,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      // ============================================================
      // สร้าง FormData ตามที่ Backend Railway ต้องการ
      // ============================================================
      final formData = FormData.fromMap({
        'pet_id': petId,                           // ← int: Pet ID
        'symptom_description': symptomDescription,  // ← String: อาการ
      });

      // ============================================================
      // แนบไฟล์รูปภาพ (ถ้ามี)
      // ============================================================
      if (imageFile != null || imageBytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        if (kIsWeb) {
          // Web: ใช้ bytes (Uint8List)
          final bytes = imageBytes ?? await imageFile?.readAsBytes();
          if (bytes != null) {
            formData.files.add(MapEntry(
              'image',  // ← Key ตามที่ Backend ต้องการ
              MultipartFile.fromBytes(
                bytes,
                filename: 'pet_image_$timestamp.jpg',
              ),
            ));
          }
        } else {
          // Mobile: ใช้ File
          if (imageFile != null) {
            formData.files.add(MapEntry(
              'image',  // ← Key ตามที่ Backend ต้องการ
              await MultipartFile.fromFile(
                imageFile.path,
                filename: 'pet_image_$timestamp.jpg',
              ),
            ));
          }
        }
      }

      // ============================================================
      // Debug Log ก่อนส่ง
      // ============================================================
      if (kDebugMode) {
        print('');
        print('═══════════════════════════════════════════════════════════════');
        print('📤 Railway API - Submit Assessment');
        print('═══════════════════════════════════════════════════════════════');
        print('Environment: ${AppConfig.currentEnvironment}');
        print('URL: ${AppConfig.fullAssessmentsUrl}');
        print('');
        print('Parameters:');
        print('  • pet_id: $petId');
        print('  • symptom_description: $symptomDescription');
        print('  • image: ${imageFile != null || imageBytes != null ? "Yes" : "No"}');
        print('');
        print('Timeout: 60s (for Gemini AI processing)');
        print('═══════════════════════════════════════════════════════════════');
        print('');
      }

      // ============================================================
      // ส่ง Request ไปยัง Railway
      // ============================================================
      final response = await dio.post(
        AppConfig.assessmentsEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1 && kDebugMode) {
            final progress = (sent / total * 100).toStringAsFixed(0);
            print('⬆️  Upload Progress: $progress% ($sent/${total} bytes)');
          }
        },
        onReceiveProgress: (received, total) {
          if (total != -1 && kDebugMode) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('⬇️  Download Progress: $progress%');
          }
        },
      );

      // ============================================================
      // รับ Response และ Parse JSON
      // ============================================================
      if (kDebugMode) {
        print('');
        print('✅ Response received!');
        print('   Status: ${response.statusCode}');
        print('   Data: ${response.data}');
        print('');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final model = AssessmentModel.fromJson(response.data);
        return model.toEntity();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<List<AssessmentEntity>> getAssessmentHistory() async {
    try {
      if (kDebugMode) {
        print('📥 Fetching assessment history from Railway...');
      }

      final response = await dio.get(AppConfig.assessmentsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        return jsonData
            .map((json) => AssessmentModel.fromJson(json).toEntity())
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching assessment history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> checkConnection() async {
    try {
      if (kDebugMode) {
        print('🔍 Checking Railway connection...');
      }

      final response = await dio.get(AppConfig.healthCheckEndpoint);

      if (kDebugMode) {
        print('✅ Railway is connected!');
        print('   Response: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Railway connection failed: $e');
      }
      rethrow;
    }
  }
}
