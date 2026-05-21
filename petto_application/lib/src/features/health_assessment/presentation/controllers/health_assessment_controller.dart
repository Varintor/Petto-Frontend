import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../data/repositories/health_assessment_repository.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../../../core/config/app_config.dart';

/// Assessment Status Enum - สถานะของการประเมิน
enum AssessmentStatus {
  idle,       // ยังไม่ได้ทำอะไร
  loading,    // กำลังส่งข้อมูล / รอ AI ประมวลผล
  success,    // สำเร็จ
  error,      // เกิดข้อผิดพลาด
}

/// Error Type Enum - ประเภทของข้อผิดพลาด
enum ErrorType {
  networkUnavailable,    // ไม่มีเน็ต
  connectionFailed,      // เชื่อมต่อไม่ได้
  connectionTimeout,     // Timeout ตอนเชื่อมต่อ
  sendTimeout,           // Timeout ตอนส่ง
  receiveTimeout,        // Timeout ตอนรับ (AI ประมวลผลนาน)
  serverError,           // Server ตอบ 4xx/5xx
  unknown,               // ไม่ทราบสาเหตุ
}

/// Assessment Error Class - ข้อมูล error แบบละเอียด
class AssessmentError {
  final String message;
  final ErrorType type;
  final String? technicalDetails;
  final int? statusCode;

  AssessmentError({
    required this.message,
    required this.type,
    this.technicalDetails,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Health Assessment Controller
/// ใช้ Provider + ChangeNotifier จัดการสถานะของหน้าจอ UI
class HealthAssessmentController extends ChangeNotifier {
  final HealthAssessmentRepository repository;

  // ==================== State ====================
  AssessmentStatus _status = AssessmentStatus.idle;
  AssessmentEntity? _currentAssessment;
  List<AssessmentEntity> _history = [];
  AssessmentError? _error;

  // Upload Progress
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;

  HealthAssessmentController({required this.repository});

  // ==================== Getters ====================
  AssessmentStatus get status => _status;
  AssessmentEntity? get currentAssessment => _currentAssessment;
  List<AssessmentEntity> get history => List.unmodifiable(_history);
  AssessmentError? get error => _error;

  bool get isLoading => _status == AssessmentStatus.loading;
  bool get isSuccess => _status == AssessmentStatus.success;
  bool get hasError => _status == AssessmentStatus.error;
  bool get isIdle => _status == AssessmentStatus.idle;

  double get uploadProgress => _uploadProgress;
  double get downloadProgress => _downloadProgress;

  // ==================== Methods ====================

  /// แปลง DioException เป็น AssessmentError
  AssessmentError _parseError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return AssessmentError(
          message: 'หมดเวลาเชื่อมต่อ (60 วินาที)\n'
              'กรุณาตรวจสอบว่า Railway Server ทำงานอยู่',
          type: ErrorType.connectionTimeout,
          technicalDetails: error.message,
        );

      case DioExceptionType.sendTimeout:
        return AssessmentError(
          message: 'หมดเวลาส่งข้อมูล (60 วินาที)\n'
              'รูปภาพอาจมีขนาดใหญ่เกินไป',
          type: ErrorType.sendTimeout,
          technicalDetails: error.message,
        );

      case DioExceptionType.receiveTimeout:
        return AssessmentError(
          message: 'AI กำลังประมวลผล... (ใช้เวลานานกว่าปกติ)\n'
              'กรุณารอสักครู่ หรือลองใหม่ภายหลัง',
          type: ErrorType.receiveTimeout,
          technicalDetails: 'Gemini AI processing timeout',
        );

      case DioExceptionType.connectionError:
        return AssessmentError(
          message: 'ไม่สามารถเชื่อมต่อกับ Railway Server ได้\n'
              'URL: ${AppConfig.fullAssessmentsUrl}\n\n'
              'สิ่งที่ควรตรวจสอบ:\n'
              '• Server ทำงานอยู่หรือไม่?\n'
              '• เช็ค internet connection',
          type: ErrorType.connectionFailed,
          technicalDetails: error.error?.toString(),
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return AssessmentError(
          message: 'Server ตอบกลับด้วยข้อผิดพลาด\n'
              'HTTP $statusCode',
          type: ErrorType.serverError,
          statusCode: statusCode,
          technicalDetails: 'Response: ${error.response?.data}',
        );

      default:
        return AssessmentError(
          message: 'เกิดข้อผิดพลาดทางเครือข่าย',
          type: ErrorType.unknown,
          technicalDetails: error.message,
        );
    }
  }

  /// ส่ง Assessment ไปยัง Railway API
  ///
  /// Parameters:
  /// - [petId]: ID ของสัตว์เลี้ยง
  /// - [symptomDescription]: รายละเอียดอาการ
  /// - [imageFile]: ไฟล์รูปภาพ (Mobile)
  /// - [imageBytes]: ข้อมูลรูปภาพ (Web)
  Future<void> submitAssessment({
    required int petId,
    required String symptomDescription,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    // เริ่ม state ใหม่
    _status = AssessmentStatus.loading;
    _error = null;
    _uploadProgress = 0.0;
    _downloadProgress = 0.0;
    notifyListeners();

    if (kDebugMode) {
      print('🎯 Controller: Starting assessment submission');
      print('   Pet ID: $petId');
      print('   Symptoms: $symptomDescription');
      print('   Has Image: ${imageFile != null || imageBytes != null}');
    }

    try {
      // เรียก Repository
      _currentAssessment = await repository.submitAssessment(
        petId: petId,
        symptomDescription: symptomDescription,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      // สำเร็จ
      _status = AssessmentStatus.success;
      _uploadProgress = 1.0;
      _downloadProgress = 1.0;

      if (kDebugMode) {
        print('✅ Controller: Assessment submitted successfully!');
        print('   ID: ${_currentAssessment!.id}');
        print('   Risk Level: ${_currentAssessment!.riskLevel}');
        print('   Diagnosis: ${_currentAssessment!.diagnosis}');
      }

      notifyListeners();
    } on DioException catch (e) {
      // DioException - แปลงเป็น AssessmentError
      _status = AssessmentStatus.error;
      _error = _parseError(e);

      if (kDebugMode) {
        print('❌ Controller: DioException occurred');
        print('   Error Type: ${_error!.type}');
        print('   Message: ${_error!.message}');
        if (_error!.technicalDetails != null) {
          print('   Technical: ${_error!.technicalDetails}');
        }
      }

      notifyListeners();
    } catch (e) {
      // Generic Exception
      _status = AssessmentStatus.error;
      _error = AssessmentError(
        message: e.toString(),
        type: ErrorType.unknown,
        technicalDetails: e.runtimeType.toString(),
      );

      if (kDebugMode) {
        print('❌ Controller: Unexpected error');
        print('   Error: $e');
      }

      notifyListeners();
    }
  }

  /// โหลดประวัติการประเมินทั้งหมด
  Future<void> loadHistory() async {
    _status = AssessmentStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _history = await repository.getAssessmentHistory();
      _status = AssessmentStatus.success;

      if (kDebugMode) {
        print('✅ Controller: Loaded ${_history.length} assessments');
      }

      notifyListeners();
    } on DioException catch (e) {
      _status = AssessmentStatus.error;
      _error = _parseError(e);

      if (kDebugMode) {
        print('❌ Controller: Failed to load history');
      }

      notifyListeners();
    } catch (e) {
      _status = AssessmentStatus.error;
      _error = AssessmentError(
        message: 'Failed to load history: $e',
        type: ErrorType.unknown,
      );

      notifyListeners();
    }
  }

  /// ตรวจสอบการเชื่อมต่อกับ Railway
  Future<bool> checkConnection() async {
    try {
      await repository.checkConnection();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Controller: Connection check failed - $e');
      }
      return false;
    }
  }

  /// รีเซ็ต state กลับเป็นค่าเริ่มต้น
  void reset() {
    _status = AssessmentStatus.idle;
    _currentAssessment = null;
    _error = null;
    _uploadProgress = 0.0;
    _downloadProgress = 0.0;

    if (kDebugMode) {
      print('🔄 Controller: State reset');
    }

    notifyListeners();
  }

  /// อัปเดต upload progress
  void updateUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// อัปเดต download progress
  void updateDownloadProgress(double progress) {
    _downloadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }
}
