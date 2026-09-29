class PetBloodTypeCatalog {
  const PetBloodTypeCatalog._();

  static const List<String> _dogTypes = <String>[
    'DEA 1 Positive',
    'DEA 1 Negative',
    'Unknown',
  ];

  static const List<String> _catTypes = <String>[
    'Type A',
    'Type B',
    'Type AB',
    'Unknown',
  ];

  static List<String> forSpecies(String species) {
    return switch (species.toLowerCase()) {
      'dog' => _dogTypes,
      'cat' => _catTypes,
      _ => const <String>['Unknown'],
    };
  }

  static Iterable<String> suggestions(String species, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final types = forSpecies(species);
    if (normalizedQuery.isEmpty) return types;
    return types.where((type) => type.toLowerCase().contains(normalizedQuery));
  }
}
