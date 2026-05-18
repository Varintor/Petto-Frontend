import '../../domain/entities/assessment_entity.dart';

class AssessmentModel {
  final String id;
  final String petName;
  final String petType;
  final String? symptoms;
  final String? imageUrl;
  final String diagnosis;
  final double confidenceScore;
  final DateTime createdAt;

  AssessmentModel({
    required this.id,
    required this.petName,
    required this.petType,
    this.symptoms,
    this.imageUrl,
    required this.diagnosis,
    required this.confidenceScore,
    required this.createdAt,
  });

  // From JSON
  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as String,
      petName: json['pet_name'] as String,
      petType: json['pet_type'] as String,
      symptoms: json['symptoms'] as String?,
      imageUrl: json['image_url'] as String?,
      diagnosis: json['diagnosis'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_name': petName,
      'pet_type': petType,
      'symptoms': symptoms,
      'image_url': imageUrl,
      'diagnosis': diagnosis,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // To Entity
  AssessmentEntity toEntity() {
    return AssessmentEntity(
      id: id,
      petName: petName,
      petType: petType,
      symptoms: symptoms,
      imageUrl: imageUrl,
      diagnosis: diagnosis,
      confidenceScore: confidenceScore,
      createdAt: createdAt,
    );
  }

  // From Entity
  factory AssessmentModel.fromEntity(AssessmentEntity entity) {
    return AssessmentModel(
      id: entity.id,
      petName: entity.petName,
      petType: entity.petType,
      symptoms: entity.symptoms,
      imageUrl: entity.imageUrl,
      diagnosis: entity.diagnosis,
      confidenceScore: entity.confidenceScore,
      createdAt: entity.createdAt,
    );
  }
}
