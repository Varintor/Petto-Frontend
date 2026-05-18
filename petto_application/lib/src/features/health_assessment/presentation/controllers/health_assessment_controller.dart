import 'package:flutter/foundation.dart';
import '../../data/repositories/health_assessment_repository.dart';
import '../../domain/entities/assessment_entity.dart';

enum AssessmentStatus { idle, loading, success, error }

class HealthAssessmentController extends ChangeNotifier {
  final HealthAssessmentRepository repository;

  AssessmentStatus _status = AssessmentStatus.idle;
  AssessmentEntity? _currentAssessment;
  List<AssessmentEntity> _history = [];
  String? _errorMessage;

  HealthAssessmentController({required this.repository});

  // Getters
  AssessmentStatus get status => _status;
  AssessmentEntity? get currentAssessment => _currentAssessment;
  List<AssessmentEntity> get history => List.unmodifiable(_history);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AssessmentStatus.loading;
  bool get hasError => _status == AssessmentStatus.error;

  // Submit Assessment
  Future<void> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData,
  }) async {
    _status = AssessmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAssessment = await repository.submitAssessment(
        petName: petName,
        petType: petType,
        symptoms: symptoms,
        imageData: imageData,
      );
      _status = AssessmentStatus.success;
    } catch (e) {
      _status = AssessmentStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Load History
  Future<void> loadHistory() async {
    _status = AssessmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await repository.getAssessmentHistory();
      _status = AssessmentStatus.success;
    } catch (e) {
      _status = AssessmentStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Reset State
  void reset() {
    _status = AssessmentStatus.idle;
    _currentAssessment = null;
    _errorMessage = null;
    notifyListeners();
  }
}
