import '../../domain/entities/assessment_entity.dart';

/// Assessment Model - แปลง JSON จาก FastAPI Backend เป็น Dart Object
///
/// JSON Response Structure:
/// {
///   "id": 16,
///   "pet_id": 1,
///   "symptom_description": "stringaw daw d",
///   "image_uri": "https://...",
///   "risk_level": "Moderate Risk",
///   "ai_raw_response": "ข้อความยาวๆ จาก AI...",
///   "created_at": "2026-05-17T18:30:35.123569"
/// }
class AssessmentModel {
  final int id;
  final int petId;
  final String symptomDescription;
  final String? imageUri;
  final String riskLevel;
  final String aiRawResponse;
  final DateTime createdAt;

  AssessmentModel({
    required this.id,
    required this.petId,
    required this.symptomDescription,
    this.imageUri,
    required this.riskLevel,
    required this.aiRawResponse,
    required this.createdAt,
  });

  /// Parse JSON จาก FastAPI Backend (snake_case → camelCase)
  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'] as int? ?? 0,
      petId: json['pet_id'] as int? ?? 0,
      symptomDescription: json['symptom_description'] as String? ?? '',
      imageUri: json['image_uri'] as String?,
      riskLevel: json['risk_level'] as String? ?? 'Unknown Risk',
      aiRawResponse: json['ai_raw_response'] as String? ?? 'Unable to analyze',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON (camelCase → snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'symptom_description': symptomDescription,
      if (imageUri != null) 'image_uri': imageUri,
      'risk_level': riskLevel,
      'ai_raw_response': aiRawResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to Entity
  AssessmentEntity toEntity() {
    return AssessmentEntity(
      id: id,
      petId: petId,
      symptomDescription: symptomDescription,
      imageUri: imageUri,
      riskLevel: riskLevel,
      aiRawResponse: aiRawResponse,
      createdAt: createdAt,
    );
  }

  /// Create from Entity
  factory AssessmentModel.fromEntity(AssessmentEntity entity) {
    return AssessmentModel(
      id: entity.id,
      petId: entity.petId,
      symptomDescription: entity.symptomDescription,
      imageUri: entity.imageUri,
      riskLevel: entity.riskLevel,
      aiRawResponse: entity.aiRawResponse,
      createdAt: entity.createdAt,
    );
  }

  // ===== Risk Level Helper Methods =====

  /// แปลง Risk Level เป็น Emoji + ชื่อ
  String getRiskLabel() {
    final level = riskLevel.toLowerCase();
    if (level.contains('high')) {
      return '🔴 $riskLevel';
    } else if (level.contains('moderate')) {
      return '🟡 $riskLevel';
    } else if (level.contains('low')) {
      return '🟢 $riskLevel';
    }
    return '⚪ $riskLevel';
  }

  /// สีสำหรับ UI (แบบ Material Color name)
  String getRiskColorName() {
    final level = riskLevel.toLowerCase();
    if (level.contains('high')) return 'red';
    if (level.contains('moderate')) return 'orange';
    if (level.contains('low')) return 'green';
    return 'grey';
  }

  /// Severity score (0-1) สำหรับ Progress Bar
  double getRiskScore() {
    final level = riskLevel.toLowerCase();
    if (level.contains('high') || level.contains('critical') || level.contains('severe')) {
      return 0.9;
    } else if (level.contains('moderate') || level.contains('medium')) {
      return 0.6;
    } else if (level.contains('low') || level.contains('minor')) {
      return 0.3;
    }
    return 0.5; // Default/Unknown
  }

  /// ดึงเฉพาะส่วนสำคัญจาก AI Response
  String getShortDiagnosis() {
    final lines = aiRawResponse.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('•') && !trimmed.startsWith('-')) {
        return trimmed.length > 100 ? '${trimmed.substring(0, 100)}...' : trimmed;
      }
    }
    return aiRawResponse.length > 100
        ? '${aiRawResponse.substring(0, 100)}...'
        : aiRawResponse;
  }

  /// ดึงรายการคำแนะนำจาก AI Response
  List<String> extractRecommendations() {
    final recommendations = <String>[];
    final lines = aiRawResponse.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      // หา bullet points หรือ ขึ้นบรรทัดใหม่ที่เป็นคำแนะนำ
      if (trimmed.startsWith('•') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('1.') ||
          trimmed.startsWith('2.') ||
          trimmed.startsWith('3.')) {
        recommendations.add(trimmed.replaceFirst(RegExp(r'^[•\-*]\s*'), '').replaceFirst(RegExp(r'^\d+\.\s*'), ''));
      }
    }

    return recommendations.isEmpty ? ['Consult a veterinarian for detailed advice'] : recommendations;
  }
}
