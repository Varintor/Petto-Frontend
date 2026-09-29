import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/pet_management/domain/pet_breed_catalog.dart';

void main() {
  test('breed suggestions are scoped to the selected species', () {
    expect(
      PetBreedCatalog.suggestions('Dog', 'thai'),
      contains('Thai Ridgeback'),
    );
    expect(PetBreedCatalog.suggestions('Dog', 'siamese'), isEmpty);
    expect(PetBreedCatalog.suggestions('Cat', 'siam'), contains('Siamese'));
    expect(PetBreedCatalog.suggestions('Cat', 'ridge'), isEmpty);
  });

  test('empty query includes mixed and unknown options', () {
    final suggestions = PetBreedCatalog.suggestions('Dog', '').toList();
    expect(suggestions, containsAll(<String>['Mixed breed', 'Unknown']));
  });
}
