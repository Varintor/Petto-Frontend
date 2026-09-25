// Feature 5 API models for the Pet Health Card and unified history.

class HistoryEntryModel {
  final String type; // assessment | activity | vaccination | mission
  final int refId;
  final DateTime timestamp;
  final String title;
  final String? summary;
  final String? riskLevel; // assessments only
  final String? status;
  final String? errorCode;

  HistoryEntryModel({
    required this.type,
    required this.refId,
    required this.timestamp,
    required this.title,
    this.summary,
    this.riskLevel,
    this.status,
    this.errorCode,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      HistoryEntryModel(
        type: json['type'] as String,
        refId: json['ref_id'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        title: json['title'] as String,
        summary: json['summary'] as String?,
        riskLevel: json['risk_level'] as String?,
        status: json['status'] as String?,
        errorCode: json['error_code'] as String?,
      );
}

class HistoryDetailModel {
  const HistoryDetailModel({
    required this.type,
    required this.refId,
    required this.fields,
  });

  final String type;
  final int refId;
  final Map<String, dynamic> fields;

  factory HistoryDetailModel.fromJson(Map<String, dynamic> json) =>
      HistoryDetailModel(
        type: json['type'] as String,
        refId: json['ref_id'] as int,
        fields: Map<String, dynamic>.from(json['fields'] as Map),
      );
}

class HealthCardModel {
  const HealthCardModel({
    required this.petId,
    required this.name,
    this.species,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.weightKg,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.notes,
    this.latestAssessment,
    this.latestVaccination,
    this.recentActivity,
    this.profileUpdatedAt,
    this.generatedAt,
  });

  final int petId;
  final String name;
  final String? species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? notes;
  final HistoryEntryModel? latestAssessment;
  final HistoryEntryModel? latestVaccination;
  final HistoryEntryModel? recentActivity;
  final DateTime? profileUpdatedAt;
  final DateTime? generatedAt;

  factory HealthCardModel.fromJson(Map<String, dynamic> json) =>
      HealthCardModel(
        petId: json['pet_id'] as int,
        name: json['name'] as String,
        species: json['species'] as String?,
        breed: json['breed'] as String?,
        gender: json['gender'] as String?,
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        bloodType: json['blood_type'] as String?,
        allergies: List<String>.from(json['allergies'] as List? ?? const []),
        chronicConditions: List<String>.from(
          json['chronic_conditions'] as List? ?? const [],
        ),
        currentMedications: List<String>.from(
          json['current_medications'] as List? ?? const [],
        ),
        notes: json['notes'] as String?,
        latestAssessment: json['latest_assessment'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['latest_assessment'] as Map),
              ),
        latestVaccination: json['latest_vaccination'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['latest_vaccination'] as Map),
              ),
        recentActivity: json['recent_activity'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['recent_activity'] as Map),
              ),
        profileUpdatedAt: json['profile_updated_at'] == null
            ? null
            : DateTime.parse(json['profile_updated_at'] as String),
        generatedAt: json['generated_at'] == null
            ? null
            : DateTime.parse(json['generated_at'] as String),
      );
}

class HealthProfileModel {
  const HealthProfileModel({
    required this.petId,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.notes,
    this.updatedAt,
  });

  final int petId;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? notes;
  final DateTime? updatedAt;

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) =>
      HealthProfileModel(
        petId: json['pet_id'] as int,
        allergies: List<String>.from(json['allergies'] as List? ?? const []),
        chronicConditions: List<String>.from(
          json['chronic_conditions'] as List? ?? const [],
        ),
        currentMedications: List<String>.from(
          json['current_medications'] as List? ?? const [],
        ),
        notes: json['notes'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );
}
