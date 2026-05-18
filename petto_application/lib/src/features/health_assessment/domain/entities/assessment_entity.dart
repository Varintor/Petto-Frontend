class AssessmentEntity {
  final String id;
  final String petName;
  final String petType;
  final String? symptoms;
  final String? imageUrl;
  final String diagnosis;
  final double confidenceScore;
  final DateTime createdAt;

  AssessmentEntity({
    required this.id,
    required this.petName,
    required this.petType,
    this.symptoms,
    this.imageUrl,
    required this.diagnosis,
    required this.confidenceScore,
    required this.createdAt,
  });

  AssessmentEntity copyWith({
    String? id,
    String? petName,
    String? petType,
    String? symptoms,
    String? imageUrl,
    String? diagnosis,
    double? confidenceScore,
    DateTime? createdAt,
  }) {
    return AssessmentEntity(
      id: id ?? this.id,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      symptoms: symptoms ?? this.symptoms,
      imageUrl: imageUrl ?? this.imageUrl,
      diagnosis: diagnosis ?? this.diagnosis,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
