/// Offline breed suggestions used to assist data entry.
///
/// This is not an allow-list: owners may still enter a breed that is not
/// listed, or select Mixed breed / Unknown.
class PetBreedCatalog {
  const PetBreedCatalog._();

  static const List<String> dogBreeds = [
    'Mixed breed',
    'Unknown',
    'Beagle',
    'Border Collie',
    'Chihuahua',
    'Dachshund',
    'French Bulldog',
    'German Shepherd',
    'Golden Retriever',
    'Labrador Retriever',
    'Pomeranian',
    'Poodle',
    'Pug',
    'Shih Tzu',
    'Siberian Husky',
    'Thai Bangkaew',
    'Thai Ridgeback',
    'Yorkshire Terrier',
  ];

  static const List<String> catBreeds = [
    'Mixed breed',
    'Unknown',
    'American Shorthair',
    'Bengal',
    'British Shorthair',
    'Domestic Longhair',
    'Domestic Shorthair',
    'Maine Coon',
    'Munchkin',
    'Persian',
    'Ragdoll',
    'Russian Blue',
    'Scottish Fold',
    'Siamese',
    'Sphynx',
  ];

  static List<String> forSpecies(String species) {
    return species.toLowerCase() == 'cat' ? catBreeds : dogBreeds;
  }

  static Iterable<String> suggestions(String species, String query) {
    final normalized = query.trim().toLowerCase();
    final breeds = forSpecies(species);
    if (normalized.isEmpty) return breeds.take(8);
    return breeds.where((breed) => breed.toLowerCase().contains(normalized));
  }
}
