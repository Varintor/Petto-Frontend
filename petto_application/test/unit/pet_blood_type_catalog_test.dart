import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/pet_management/domain/pet_blood_type_catalog.dart';

void main() {
  test('blood type suggestions are scoped to the selected species', () {
    expect(
      PetBloodTypeCatalog.suggestions('Dog', 'dea'),
      containsAll(<String>['DEA 1 Positive', 'DEA 1 Negative']),
    );
    expect(PetBloodTypeCatalog.suggestions('Dog', 'type a'), isEmpty);
    expect(
      PetBloodTypeCatalog.suggestions('Cat', 'type'),
      containsAll(<String>['Type A', 'Type B', 'Type AB']),
    );
    expect(PetBloodTypeCatalog.suggestions('Cat', 'dea'), isEmpty);
  });

  test('unknown is available without fabricating a blood type', () {
    expect(PetBloodTypeCatalog.forSpecies('Dog'), contains('Unknown'));
    expect(PetBloodTypeCatalog.forSpecies('Cat'), contains('Unknown'));
  });
}
