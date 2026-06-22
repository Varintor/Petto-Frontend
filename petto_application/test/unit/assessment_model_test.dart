// UTC-11: AssessmentModel.fromJson + toEntity mapping.
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/health_assessment/data/models/assessment_model.dart';

void main() {
  group('UTC-11 AssessmentModel', () {
    test('UTC-11-TC-01: maps assessment JSON', () {
      final json = {
        'id': 201,
        'pet_id': 5,
        'symptom_description': 'Lethargic, loss of appetite',
        'image_uri': 'https://images.test/symptom.jpg',
        'risk_level': 'High Risk',
        'ai_raw_response': 'See a vet within 24 hours.',
        'created_at': '2026-06-17T14:20:00',
      };

      final m = AssessmentModel.fromJson(json);

      expect(m.id, 201);
      expect(m.petId, 5);
      expect(m.riskLevel, 'High Risk');
      expect(m.symptomDescription, 'Lethargic, loss of appetite');
      expect(m.createdAt, DateTime.parse('2026-06-17T14:20:00'));
    });

    test('UTC-11-TC-02: missing risk_level falls back to "Moderate Risk"', () {
      final m = AssessmentModel.fromJson({
        'id': 1,
        'pet_id': 5,
        'symptom_description': 'x',
        'created_at': '2026-06-17T14:20:00',
      });

      expect(m.riskLevel, 'Moderate Risk');
    });

    test('UTC-11-TC-03: toEntity injects pet name/type', () {
      final m = AssessmentModel.fromJson({
        'id': 1,
        'pet_id': 5,
        'symptom_description': 'x',
        'risk_level': 'Low Risk',
        'created_at': '2026-06-17T14:20:00',
      });

      final e = m.toEntity(petName: 'Buddy', petType: 'Dog');

      expect(e.petName, 'Buddy');
      expect(e.petType, 'Dog');
      expect(e.aiResponse, ''); // aiRawResponse was null -> ''
      expect(e.riskLevel, 'Low Risk');
    });
  });
}
