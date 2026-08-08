import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/assessment_entity.dart';
import '../models/assessment_model.dart';

const int _maxAssessmentImageBytes = 10 * 1024 * 1024;
const Set<String> _supportedImageTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

String _extensionForMime(String mimeType) => switch (mimeType) {
  'image/png' => '.png',
  'image/webp' => '.webp',
  _ => '.jpg',
};

String _validatedMimeType(String? path, List<int> headerBytes) {
  final mimeType = lookupMimeType(
    path ?? 'assessment',
    headerBytes: headerBytes,
  );
  if (mimeType == null || !_supportedImageTypes.contains(mimeType)) {
    throw Exception('Please choose a valid JPEG, PNG, or WebP image.');
  }
  return mimeType;
}

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

  // NOTE: ApiClient.dio attaches the Bearer token and never hard-codes a
  // multipart Content-Type — Dio sets the correct multipart boundary
  // automatically for FormData.
  HealthAssessmentRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

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
    // No seed-pet fallback (SRS-F2-018): an assessment must always be written
    // against the caller's real pet, never a shared default.
    if (petId == null) {
      throw Exception(
        'Please sign in and add a pet before running an AI check.',
      );
    }

    try {
      final formData = FormData.fromMap({
        // Backend Form fields: pet_id (int), symptom_description (str).
        'pet_id': petId,
        'symptom_description': (symptoms == null || symptoms.trim().isEmpty)
            ? 'No additional symptoms described'
            : symptoms.trim(),
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (imageData is Uint8List || imageData is List<int>) {
        final bytes = imageData is Uint8List
            ? imageData
            : Uint8List.fromList(imageData as List<int>);
        if (bytes.length > _maxAssessmentImageBytes) {
          throw Exception('The image must be 10 MB or smaller.');
        }
        final mimeType = _validatedMimeType(
          null,
          bytes.take(math.min(16, bytes.length)).toList(),
        );
        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              bytes,
              filename: 'pet_$timestamp${_extensionForMime(mimeType)}',
              contentType: MediaType.parse(mimeType),
            ),
          ),
        );
      } else if (imageData is File) {
        final length = await imageData.length();
        if (length > _maxAssessmentImageBytes) {
          throw Exception('The image must be 10 MB or smaller.');
        }
        final header = await imageData
            .openRead(0, math.min(16, length))
            .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
        final mimeType = _validatedMimeType(imageData.path, header);
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageData.path,
              filename: 'pet_$timestamp${_extensionForMime(mimeType)}',
              contentType: MediaType.parse(mimeType),
            ),
          ),
        );
      } else {
        throw Exception('The selected image could not be read.');
      }

      final response = await dio.post(
        AppConfig.assessmentsEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AssessmentModel.fromJson(
          response.data,
        ).toEntity(petName: petName, petType: petType);
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
            .map(
              (json) => AssessmentModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
            )
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
            .map(
              (json) => AssessmentModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
            )
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
