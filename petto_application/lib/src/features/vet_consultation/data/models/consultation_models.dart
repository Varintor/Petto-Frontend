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
  final String? petName;
  final String? petSpecies;
  final String? ownerName;
  final String? vetName;
  final String? providerName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultationModel({
    required this.id,
    required this.petId,
    required this.vetId,
    required this.status,
    this.assessmentId,
    this.notes,
    this.petName,
    this.petSpecies,
    this.ownerName,
    this.vetName,
    this.providerName,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) =>
      ConsultationModel(
        id: json['id'] as int,
        petId: json['pet_id'] as int,
        vetId: json['vet_id'] as int,
        status: json['status'] as String? ?? 'Pending',
        assessmentId: json['assessment_id'] as int?,
        notes: json['notes'] as String?,
        petName: json['pet_name'] as String?,
        petSpecies: json['pet_species'] as String?,
        ownerName: json['owner_name'] as String?,
        vetName: json['vet_name'] as String?,
        providerName: json['provider_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );
}

class ChatMessageModel {
  final int id;
  final int consultationId;
  final String senderType; // user | vet | ai
  final String? content;
  final String? attachmentUri;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? clientMessageId;

  ChatMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderType,
    this.content,
    this.attachmentUri,
    required this.createdAt,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.clientMessageId,
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
        isRead: json['is_read'] as bool? ?? false,
        deliveredAt: json['delivered_at'] == null
            ? null
            : DateTime.parse(json['delivered_at'] as String),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
        clientMessageId: json['client_message_id'] as String?,
      );
}

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.consultationId,
    required this.petId,
    required this.proposedByVetId,
    required this.startsAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.providerId,
    this.endsAt,
    this.reason,
    this.respondedAt,
  });

  final int id;
  final int consultationId;
  final int petId;
  final int? providerId;
  final int proposedByVetId;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? reason;
  final String status;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'proposed';
  bool get isAccepted => status == 'accepted';

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      AppointmentModel(
        id: json['id'] as int,
        consultationId: json['consultation_id'] as int,
        petId: json['pet_id'] as int,
        providerId: json['provider_id'] as int?,
        proposedByVetId: json['proposed_by_vet_id'] as int,
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: json['ends_at'] == null
            ? null
            : DateTime.parse(json['ends_at'] as String).toLocal(),
        reason: json['reason'] as String?,
        status: json['status'] as String,
        respondedAt: json['responded_at'] == null
            ? null
            : DateTime.parse(json['responded_at'] as String).toLocal(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      );
}
