class PublicPetCardModel {
  const PublicPetCardModel({
    required this.id,
    required this.petId,
    required this.isActive,
    required this.visibleFields,
    this.contactMethod,
    this.emergencyNotes,
    this.revokedAt,
    this.token,
  });

  final int id;
  final int petId;
  final bool isActive;
  final Set<String> visibleFields;
  final String? contactMethod;
  final String? emergencyNotes;
  final DateTime? revokedAt;

  /// The backend intentionally returns the bearer token only when a card is
  /// created or rotated. It is never returned by the settings read endpoint.
  final String? token;

  factory PublicPetCardModel.fromJson(Map<String, dynamic> json) =>
      PublicPetCardModel(
        id: json['id'] as int,
        petId: json['pet_id'] as int,
        isActive: json['is_active'] as bool? ?? false,
        visibleFields: ((json['visible_fields'] as List<dynamic>?) ?? const [])
            .map((item) => item.toString())
            .toSet(),
        contactMethod: json['contact_method'] as String?,
        emergencyNotes: json['emergency_notes'] as String?,
        revokedAt: json['revoked_at'] == null
            ? null
            : DateTime.parse(json['revoked_at'] as String),
        token: json['token'] as String?,
      );
}
