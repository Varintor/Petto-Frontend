/// Assessment Entity - ตรงกับ JSON Response จาก FastAPI Backend
///
/// Real JSON Structure:
/// {
///   "id": 16,
///   "pet_id": 1,
///   "symptom_description": "stringaw daw d",
///   "image_uri": "https://...",
///   "risk_level": "Moderate Risk",
///   "ai_raw_response": "ข้อความยาวๆ จาก AI...",
///   "created_at": "2026-05-17T18:30:35.123569"
/// }

class AssessmentEntity {
  final int id;
  final int petId;
  final String symptomDescription;
  final String? imageUri;
  final String riskLevel;
  final String aiRawResponse;
  final DateTime createdAt;

  AssessmentEntity({
    required this.id,
    required this.petId,
    required this.symptomDescription,
    this.imageUri,
    required this.riskLevel,
    required this.aiRawResponse,
    required this.createdAt,
  });

  AssessmentEntity copyWith({
    int? id,
    int? petId,
    String? symptomDescription,
    String? imageUri,
    String? riskLevel,
    String? aiRawResponse,
    DateTime? createdAt,
  }) {
    return AssessmentEntity(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      symptomDescription: symptomDescription ?? this.symptomDescription,
      imageUri: imageUri ?? this.imageUri,
      riskLevel: riskLevel ?? this.riskLevel,
      aiRawResponse: aiRawResponse ?? this.aiRawResponse,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods for Risk Level
  bool get isHighRisk => riskLevel.toLowerCase().contains('high');
  bool get isModerateRisk => riskLevel.toLowerCase().contains('moderate');
  bool get isLowRisk => riskLevel.toLowerCase().contains('low');

  String get riskCategory {
    if (isHighRisk) return 'high';
    if (isModerateRisk) return 'moderate';
    if (isLowRisk) return 'low';
    return 'unknown';
  }

  // Extract diagnosis from AI response (first paragraph or first line)
  String get diagnosis {
    final lines = aiRawResponse.split('\n');
    if (lines.isNotEmpty) {
      return lines.first.trim();
    }
    return aiRawResponse;
  }

  // Extract recommendations from AI response (lines after diagnosis)
  List<String> get recommendations {
    final lines = aiRawResponse.split('\n');
    if (lines.length > 1) {
      return lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
    }
    return [];
  }
}
