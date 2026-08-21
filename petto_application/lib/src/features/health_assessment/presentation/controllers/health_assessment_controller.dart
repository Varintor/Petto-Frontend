import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../data/repositories/health_assessment_repository.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../../../core/config/app_config.dart';

enum AssessmentStatus { idle, loading, success, error }

enum ErrorType {
  networkUnavailable,
  connectionFailed,
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  serverError,
  unknown,
}

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

class HealthAssessmentController extends ChangeNotifier {
  final HealthAssessmentRepository repository;

  AssessmentStatus _status = AssessmentStatus.idle;
  AssessmentEntity? _currentAssessment;
  List<AssessmentEntity> _history = [];
  AssessmentError? _error;
  bool _historyLoading = false;
  int? _historyPetId;

  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;

  HealthAssessmentController({required this.repository});

  AssessmentStatus get status => _status;
  AssessmentEntity? get currentAssessment => _currentAssessment;
  List<AssessmentEntity> get history => List.unmodifiable(_history);
  AssessmentError? get error => _error;

  String? get errorMessage => _error?.message;

  bool get isLoading => _status == AssessmentStatus.loading;
  bool get isHistoryLoading => _historyLoading;
  bool get isSuccess => _status == AssessmentStatus.success;
  bool get hasError => _status == AssessmentStatus.error;
  bool get isIdle => _status == AssessmentStatus.idle;

  double get uploadProgress => _uploadProgress;
  double get downloadProgress => _downloadProgress;

  AssessmentError _parseError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return AssessmentError(
            message:
                'Connection timed out (60s).\nPlease check the server is running.',
            type: ErrorType.connectionTimeout,
            technicalDetails: error.message,
          );

        case DioExceptionType.sendTimeout:
          return AssessmentError(
            message: 'Upload timed out (60s).\nThe image may be too large.',
            type: ErrorType.sendTimeout,
            technicalDetails: error.message,
          );

        case DioExceptionType.receiveTimeout:
          return AssessmentError(
            message:
                'AI processing is taking longer than expected.\nPlease wait or try again later.',
            type: ErrorType.receiveTimeout,
            technicalDetails: 'Gemini AI processing timeout',
          );

        case DioExceptionType.connectionError:
          return AssessmentError(
            message:
                'Cannot reach the server.\n'
                'URL: ${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/assessments\n\n'
                'Please check:\n'
                '- Is the server running?\n'
                '- Internet connection',
            type: ErrorType.connectionFailed,
            technicalDetails: error.error?.toString(),
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          return AssessmentError(
            message: 'Server responded with an error.\nHTTP $statusCode',
            type: ErrorType.serverError,
            statusCode: statusCode,
            technicalDetails: 'Response: ${error.response?.data}',
          );

        default:
          return AssessmentError(
            message: 'A network error occurred.',
            type: ErrorType.unknown,
            technicalDetails: error.message,
          );
      }
    }

    return AssessmentError(
      message: error.toString(),
      type: ErrorType.unknown,
      technicalDetails: error.runtimeType.toString(),
    );
  }

  Future<void> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData,
    int? petId,
  }) async {
    _status = AssessmentStatus.loading;
    _error = null;
    _uploadProgress = 0.0;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      _currentAssessment = await repository.submitAssessment(
        petName: petName,
        petType: petType,
        symptoms: symptoms,
        imageData: imageData,
        petId: petId,
      );

      _status = AssessmentStatus.success;
      _uploadProgress = 1.0;
      _downloadProgress = 1.0;

      notifyListeners();
    } catch (e) {
      _status = AssessmentStatus.error;
      _error = _parseError(e);
      notifyListeners();
    }
  }

  Future<void> loadPetHistory(int petId, {bool force = false}) async {
    // Home can rebuild many times while an empty history is displayed. Keep
    // one in-flight request and remember that an empty result was loaded so a
    // rebuild cannot create an unbounded request loop. Explicit refresh uses
    // force=true.
    if (!force && _historyPetId == petId) return;
    _historyLoading = true;
    _historyPetId = petId;
    _error = null;
    notifyListeners();

    try {
      final history = await repository.getPetAssessmentHistory(petId);
      if (_historyPetId == petId) _history = history;
    } catch (e) {
      if (_historyPetId == petId) _error = _parseError(e);
    } finally {
      if (_historyPetId == petId) {
        _historyLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadHistory() async {
    _status = AssessmentStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _history = await repository.getAssessmentHistory();
      _status = AssessmentStatus.success;
      notifyListeners();
    } catch (e) {
      _status = AssessmentStatus.error;
      _error = _parseError(e);
      notifyListeners();
    }
  }

  void reset() {
    _status = AssessmentStatus.idle;
    _currentAssessment = null;
    _error = null;
    _uploadProgress = 0.0;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  void updateUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void updateDownloadProgress(double progress) {
    _downloadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }
}
