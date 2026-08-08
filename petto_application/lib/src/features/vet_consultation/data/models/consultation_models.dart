/// Feature 3 wire models (snake_case JSON from the FastAPI backend).
class VetModel {
  final int id;
  final String name;
  final String? clinicName;
  final String? specialty;
  final String? avatarUri;
  final bool isOnline;

  VetModel({
    required this.id,
    required this.name,
    this.clinicName,
    this.specialty,
    this.avatarUri,
    required this.isOnline,
  });

  factory VetModel.fromJson(Map<String, dynamic> json) => VetModel(
        id: json['id'] as int,
        name: json['name'] as String,
        clinicName: json['clinic_name'] as String?,
        specialty: json['specialty'] as String?,
        avatarUri: json['avatar_uri'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
      );
}

class ConsultationModel {
  final int id;
  final int petId;
  final int vetId;
  final String status; // Pending | Active | Completed | Cancelled
  final int? assessmentId;
  final String? notes;
  final DateTime createdAt;

  ConsultationModel({
    required this.id,
    required this.petId,
    required this.vetId,
    required this.status,
    this.assessmentId,
    this.notes,
    required this.createdAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) =>
      ConsultationModel(
        id: json['id'] as int,
        petId: json['pet_id'] as int,
        vetId: json['vet_id'] as int,
        status: json['status'] as String? ?? 'Pending',
        assessmentId: json['assessment_id'] as int?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ChatMessageModel {
  final int id;
  final int consultationId;
  final String senderType; // user | vet | ai
  final String? content;
  final String? attachmentUri;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderType,
    this.content,
    this.attachmentUri,
    required this.createdAt,
  });

  bool get isFromVet => senderType == 'vet';
  bool get isAiBriefing => senderType == 'ai';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as int,
        consultationId: json['consultation_id'] as int,
        senderType: json['sender_type'] as String? ?? 'user',
        content: json['content'] as String?,
        attachmentUri: json['attachment_uri'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
