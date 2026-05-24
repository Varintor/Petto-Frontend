import '../../domain/entities/assessment_entity.dart';

/// Data model that maps the backend `AssessmentResponse` JSON
/// (app/schemas.py) to/from the domain [AssessmentEntity].
///
/// Backend JSON shape:
/// {
///   "id": 1,
///   "pet_id": 1,
///   "symptom_description": "....",
///   "image_uri": "https://....",
///   "risk_level": "Low Risk",        // enum value
///   "ai_raw_response": "....",
///   "created_at": "2026-05-24T..."
/// }
class AssessmentModel {
  final int id;
  final int petId;
  final String? symptomDescription;
  final String? imageUri;
  final String riskLevel;
  final String? aiRawResponse;
  final DateTime createdAt;

  AssessmentModel({
    required this.id,
    required this.petId,
    this.symptomDescription,
    this.imageUri,
    required this.riskLevel,
    this.aiRawResponse,
    required this.createdAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as int,
      petId: json['pet_id'] as int,
      symptomDescription: json['symptom_description'] as String?,
      imageUri: json['image_uri'] as String?,
      riskLevel: (json['risk_level'] ?? 'Moderate Risk').toString(),
      aiRawResponse: json['ai_raw_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to a domain entity. [petName] / [petType] are supplied by the
  /// caller because the backend does not echo them back in the response.
  AssessmentEntity toEntity({String petName = '', String petType = ''}) {
    return AssessmentEntity(
      id: id,
      petId: petId,
      petName: petName,
      petType: petType,
      symptoms: symptomDescription,
      imageUri: imageUri,
      riskLevel: riskLevel,
      aiResponse: aiRawResponse ?? '',
      createdAt: createdAt,
    );
  }
}
