import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/pet_management/domain/pet_age_formatter.dart';

void main() {
  test('age is derived from birthday instead of stored separately', () {
    final now = DateTime(2026, 9, 29);

    expect(
      PetAgeFormatter.english(DateTime(2024, 6, 10), now: now),
      '2 years 3 months',
    );
    expect(
      PetAgeFormatter.english(DateTime(2026, 4, 29), now: now),
      '5 months',
    );
    expect(PetAgeFormatter.english(null, now: now), 'Not set');
  });
}
