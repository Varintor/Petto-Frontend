import '../../domain/entities/vaccination_entity.dart';

/// Data model that maps the backend `VaccinationResponse` JSON
/// to/from the domain [VaccinationEntity].
///
/// Backend JSON shape:
/// {
///   "id": 1,
///   "pet_id": 1,
///   "vaccine_name": "Rabies",
///   "date_administered": "2024-01-15",
///   "next_due_date": "2025-01-15",
///   "clinic_name": "Pet Hospital",
///   "notes": "Annual booster",
///   "created_at": "2024-01-15T10:30:00"
/// }
class VaccinationModel {
  final int id;
  final int petId;
  final String vaccineName;
  final DateTime dateAdministered;
  final DateTime? nextDueDate;
  final String? clinicName;
  final String? notes;
  final DateTime createdAt;

  VaccinationModel({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.dateAdministered,
    this.nextDueDate,
    this.clinicName,
    this.notes,
    required this.createdAt,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] as int,
      petId: json['pet_id'] as int,
      vaccineName: json['vaccine_name'] as String,
      dateAdministered: DateTime.parse(json['date_administered'] as String),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      clinicName: json['clinic_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'vaccine_name': vaccineName,
      'date_administered': dateAdministered.toIso8601String().split('T')[0],
      'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
      'clinic_name': clinicName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  VaccinationEntity toEntity() {
    return VaccinationEntity(
      id: id,
      petId: petId,
      vaccineName: vaccineName,
      dateAdministered: dateAdministered,
      nextDueDate: nextDueDate,
      clinicName: clinicName,
      notes: notes,
      createdAt: createdAt,
    );
  }

  /// Create from entity
  factory VaccinationModel.fromEntity(VaccinationEntity entity) {
    return VaccinationModel(
      id: entity.id,
      petId: entity.petId,
      vaccineName: entity.vaccineName,
      dateAdministered: entity.dateAdministered,
      nextDueDate: entity.nextDueDate,
      clinicName: entity.clinicName,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  /// Create request body for POST /api/v1/vaccinations
  Map<String, dynamic> toCreateRequestBody() {
    return {
      'pet_id': petId,
      'vaccine_name': vaccineName,
      'date_administered': dateAdministered.toIso8601String().split('T')[0],
      if (nextDueDate != null)
        'next_due_date': nextDueDate!.toIso8601String().split('T')[0],
      if (clinicName != null) 'clinic_name': clinicName,
      if (notes != null) 'notes': notes,
    };
  }
}
