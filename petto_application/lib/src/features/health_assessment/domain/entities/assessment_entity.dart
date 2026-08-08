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

  /// Backend processing outcome: `completed` or `failed`.
  final String status;

  /// Stable retry/diagnostic category. Never contains a raw upstream error.
  final String? errorCode;

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
    this.status = 'completed',
    this.errorCode,
    required this.createdAt,
  });

  /// Normalised risk bucket: "low" | "moderate" | "high".
  String get riskBucket {
    if (status == 'failed') return 'failed';
    final value = riskLevel.toLowerCase();
    if (value.contains('high')) return 'high';
    if (value.contains('low')) return 'low';
    if (value.contains('moderate')) return 'moderate';
    return 'unknown';
  }

  bool get isFailed => status == 'failed';

  AssessmentEntity copyWith({
    int? id,
    int? petId,
    String? petName,
    String? petType,
    String? symptoms,
    String? imageUri,
    String? riskLevel,
    String? aiResponse,
    String? status,
    String? errorCode,
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
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
