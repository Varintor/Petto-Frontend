import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../data/repositories/vaccination_repository.dart';
import '../../domain/entities/vaccination_entity.dart';

/// Vaccination Status Enum
enum VaccinationStatus {
  idle,
  loading,
  success,
  error,
}

/// Error Type Enum
enum ErrorType {
  networkError,
  serverError,
  validationError,
  unknown,
}

/// Vaccination Error Class
class VaccinationError {
  final String message;
  final ErrorType type;
  final String? technicalDetails;

  VaccinationError({
    required this.message,
    required this.type,
    this.technicalDetails,
  });

  @override
  String toString() => message;
}

/// Vaccination Controller
/// Uses Provider + ChangeNotifier to manage UI screen state
class VaccinationController extends ChangeNotifier {
  final VaccinationRepository repository;

  // ==================== State ====================
  VaccinationStatus _status = VaccinationStatus.idle;
  List<VaccinationEntity> _vaccinations = [];
  VaccinationError? _error;

  VaccinationController({required this.repository});

  // ==================== Getters ====================
  VaccinationStatus get status => _status;
  List<VaccinationEntity> get vaccinations => List.unmodifiable(_vaccinations);
  VaccinationError? get error => _error;

  bool get isLoading => _status == VaccinationStatus.loading;
  bool get isSuccess => _status == VaccinationStatus.success;
  bool get hasError => _status == VaccinationStatus.error;
  bool get isIdle => _status == VaccinationStatus.idle;

  // Backward compatibility getter
  String? get errorMessage => _error?.message;

  /// Get upcoming vaccinations (due within 30 days)
  List<VaccinationEntity> get upcomingVaccinations {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    return _vaccinations
        .where((v) =>
            v.nextDueDate != null &&
            v.nextDueDate!.isAfter(now) &&
            v.nextDueDate!.isBefore(thirtyDaysLater))
        .toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
  }

  /// Get overdue vaccinations
  List<VaccinationEntity> get overdueVaccinations {
    return _vaccinations.where((v) => v.isOverdue).toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
  }

  // ==================== Methods ====================

  /// Convert an Exception into a VaccinationError
  VaccinationError _parseError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          return VaccinationError(
            message: 'Cannot connect to server.\nPlease check your internet connection.',
            type: ErrorType.networkError,
            technicalDetails: error.error?.toString(),
          );

        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return VaccinationError(
            message: 'Connection timed out.\nPlease try again.',
            type: ErrorType.networkError,
            technicalDetails: error.message,
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          if (statusCode == 422) {
            return VaccinationError(
              message: 'Invalid data.\nPlease check your input.',
              type: ErrorType.validationError,
              technicalDetails: 'Response: ${error.response?.data}',
            );
          }
          return VaccinationError(
            message: 'Server ตอบกลับด้วยข้อผิดพลาด\nHTTP $statusCode',
            type: ErrorType.serverError,
            technicalDetails: 'Response: ${error.response?.data}',
          );

        default:
          return VaccinationError(
            message: 'เกิดข้อผิดพลาดทางเครือข่าย',
            type: ErrorType.unknown,
            technicalDetails: error.message,
          );
      }
    }

    return VaccinationError(
      message: error.toString(),
      type: ErrorType.unknown,
      technicalDetails: error.runtimeType.toString(),
    );
  }

  /// โหลดประวัติวัคซีนทั้งหมดของสัตว์เลี้ยง
  Future<void> loadVaccinations(int petId) async {
    _status = VaccinationStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _vaccinations = await repository.getPetVaccinations(petId);
      _status = VaccinationStatus.success;

      if (kDebugMode) {
        print('✅ Controller: Loaded ${_vaccinations.length} vaccinations');
        print('   Upcoming: ${upcomingVaccinations.length}');
        print('   Overdue: ${overdueVaccinations.length}');
      }

      notifyListeners();
    } catch (e) {
      _status = VaccinationStatus.error;
      _error = _parseError(e);

      if (kDebugMode) {
        print('❌ Controller: Failed to load vaccinations');
        print('   Error: ${_error!.message}');
      }

      notifyListeners();
    }
  }

  /// สร้างบันทึกวัคซีนใหม่
  Future<bool> createVaccination({
    required int petId,
    required String vaccineName,
    required DateTime dateAdministered,
    DateTime? nextDueDate,
    String? clinicName,
    String? notes,
  }) async {
    _status = VaccinationStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final newVaccination = await repository.createVaccination(
        petId: petId,
        vaccineName: vaccineName,
        dateAdministered: dateAdministered,
        nextDueDate: nextDueDate,
        clinicName: clinicName,
        notes: notes,
      );

      _vaccinations.add(newVaccination);
      _status = VaccinationStatus.success;

      if (kDebugMode) {
        print('✅ Controller: Vaccination created successfully!');
        print('   ID: ${newVaccination.id}');
        print('   Vaccine: ${newVaccination.vaccineName}');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = VaccinationStatus.error;
      _error = _parseError(e);

      if (kDebugMode) {
        print('❌ Controller: Failed to create vaccination');
        print('   Error: ${_error!.message}');
      }

      notifyListeners();
      return false;
    }
  }

  /// รีเซ็ต state
  void reset() {
    _status = VaccinationStatus.idle;
    _error = null;

    if (kDebugMode) {
      print('🔄 Controller: State reset');
    }

    notifyListeners();
  }
}
