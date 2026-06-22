// UTC-12: VaccinationModel mapping, create-request body, entity round-trip.
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/vaccinations/data/models/vaccination_model.dart';

void main() {
  group('UTC-12 VaccinationModel', () {
    test('UTC-12-TC-01: maps vaccination JSON', () {
      final m = VaccinationModel.fromJson({
        'id': 1,
        'pet_id': 5,
        'vaccine_name': 'Rabies',
        'date_administered': '2026-06-18',
        'next_due_date': '2027-06-18',
        'clinic_name': 'Pet Hospital',
        'notes': 'Annual booster',
        'created_at': '2026-06-18T10:30:00',
      });

      expect(m.vaccineName, 'Rabies');
      expect(m.dateAdministered, DateTime.parse('2026-06-18'));
      expect(m.nextDueDate, DateTime.parse('2027-06-18'));
      expect(m.clinicName, 'Pet Hospital');
    });

    test('UTC-12-TC-02: builds a create-request body (omits null notes)', () {
      final m = VaccinationModel(
        id: 0,
        petId: 5,
        vaccineName: 'Rabies',
        dateAdministered: DateTime.parse('2026-06-18'),
        nextDueDate: DateTime.parse('2027-06-18'),
        notes: null,
        createdAt: DateTime.parse('2026-06-18T10:30:00'),
      );

      final body = m.toCreateRequestBody();

      expect(body['pet_id'], 5);
      expect(body['vaccine_name'], 'Rabies');
      expect(body['date_administered'], '2026-06-18'); // YYYY-MM-DD
      expect(body.containsKey('notes'), isFalse); // null omitted
    });

    test('UTC-12-TC-03: entity round-trip preserves key fields', () {
      final m = VaccinationModel(
        id: 1,
        petId: 5,
        vaccineName: 'Rabies',
        dateAdministered: DateTime.parse('2026-06-18'),
        nextDueDate: DateTime.parse('2027-06-18'),
        clinicName: 'Pet Hospital',
        notes: 'note',
        createdAt: DateTime.parse('2026-06-18T10:30:00'),
      );

      final back = VaccinationModel.fromEntity(m.toEntity());

      expect(back.id, m.id);
      expect(back.petId, m.petId);
      expect(back.vaccineName, m.vaccineName);
      expect(back.dateAdministered, m.dateAdministered);
      expect(back.nextDueDate, m.nextDueDate);
    });
  });
}
