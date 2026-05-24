/// Domain entity for a health assessment.
///
/// Mirrors the backend `AssessmentResponse` (app/schemas.py) plus a couple of
/// display-only fields ([petName] / [petType]) that the backend does not return
/// but the UI already knows from the submitted form.
class AssessmentEntity {
  final int id;
  final int petId;

  /// Display-only, taken from the submitted form (backend stores pet_id only).
  final String petName;
  final String petType;

  /// Backend `symptom_description`.
  final String? symptoms;

  /// Backend `image_uri` (public Supabase URL).
  final String? imageUri;

  /// Backend `risk_level` enum value: "Low Risk" | "Moderate Risk" | "High Risk".
  final String riskLevel;

  /// Backend `ai_raw_response` - the full triage text from Gemini.
  final String aiResponse;

  final DateTime createdAt;

  const AssessmentEntity({
    required this.id,
    required this.petId,
    this.petName = '',
    this.petType = '',
    this.symptoms,
    this.imageUri,
    required this.riskLevel,
    required this.aiResponse,
    required this.createdAt,
  });

  /// Normalised risk bucket: "low" | "moderate" | "high".
  String get riskBucket {
    final value = riskLevel.toLowerCase();
    if (value.contains('high')) return 'high';
    if (value.contains('low')) return 'low';
    return 'moderate';
  }

  AssessmentEntity copyWith({
    int? id,
    int? petId,
    String? petName,
    String? petType,
    String? symptoms,
    String? imageUri,
    String? riskLevel,
    String? aiResponse,
    DateTime? createdAt,
  }) {
    return AssessmentEntity(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      symptoms: symptoms ?? this.symptoms,
      imageUri: imageUri ?? this.imageUri,
      riskLevel: riskLevel ?? this.riskLevel,
      aiResponse: aiResponse ?? this.aiResponse,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
