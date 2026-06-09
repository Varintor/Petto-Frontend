/// Domain entity for a pet profile (Feature 1 - Pet Profile Management).
///
/// Mirrors the backend `pet_profiles` table / PetResponse schema. Kept free of
/// any Flutter/JSON concerns so the UI and (future) repository can share it.
class PetEntity {
  final int? id;
  final String name;
  final String? species; // "dog", "cat", ...
  final String? breed;
  final String? gender; // "male" / "female"
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? avatarUri;

  const PetEntity({
    this.id,
    required this.name,
    this.species,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.weightKg,
    this.avatarUri,
  });

  /// Rough age label from [dateOfBirth] for display ("2 ปี 3 เดือน").
  String get ageLabel {
    if (dateOfBirth == null) return 'ไม่ระบุอายุ';
    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    var months = now.month - dateOfBirth!.month;
    if (now.day < dateOfBirth!.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years <= 0) return '$months เดือน';
    return months == 0 ? '$years ปี' : '$years ปี $months เดือน';
  }

  PetEntity copyWith({
    int? id,
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weightKg,
    String? avatarUri,
  }) {
    return PetEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weightKg: weightKg ?? this.weightKg,
      avatarUri: avatarUri ?? this.avatarUri,
    );
  }
}
