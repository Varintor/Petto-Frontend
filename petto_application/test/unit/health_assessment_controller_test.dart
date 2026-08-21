import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/health_assessment/data/repositories/health_assessment_repository.dart';
import 'package:petto_application/src/features/health_assessment/domain/entities/assessment_entity.dart';
import 'package:petto_application/src/features/health_assessment/presentation/controllers/health_assessment_controller.dart';

class _HistoryRepository implements HealthAssessmentRepository {
  final pending = Completer<List<AssessmentEntity>>();
  int historyCalls = 0;

  @override
  Future<List<AssessmentEntity>> getPetAssessmentHistory(int petId) {
    historyCalls += 1;
    return pending.future;
  }

  @override
  Future<List<AssessmentEntity>> getAssessmentHistory() async => [];

  @override
  Future<AssessmentEntity> submitAssessment({
    required String petName,
    required String petType,
    String? symptoms,
    dynamic imageData,
    int? petId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test(
    'empty pet history is loaded once across repeated rebuild requests',
    () async {
      final repository = _HistoryRepository();
      final controller = HealthAssessmentController(repository: repository);

      final first = controller.loadPetHistory(8);
      await controller.loadPetHistory(8);
      expect(controller.isHistoryLoading, isTrue);
      expect(repository.historyCalls, 1);

      repository.pending.complete([]);
      await first;
      await controller.loadPetHistory(8);

      expect(controller.isHistoryLoading, isFalse);
      expect(controller.history, isEmpty);
      expect(repository.historyCalls, 1);
    },
  );
}
