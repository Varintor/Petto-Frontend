/// Domain entity for a vaccination record.
///
/// Mirrors the backend `VaccinationResponse` schema.
class VaccinationEntity {
  final int id;
  final int petId;
  final String vaccineName;
  final DateTime dateAdministered;
  final DateTime? nextDueDate;
  final String? clinicName;
  final String? notes;
  final DateTime createdAt;

  VaccinationEntity({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.dateAdministered,
    this.nextDueDate,
    this.clinicName,
    this.notes,
    required this.createdAt,
  });

  /// Check if vaccination is overdue
  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  /// Check if vaccination is due soon (within 7 days)
  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final daysUntilDue = nextDueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }

  /// Check if vaccination is up to date
  bool get isUpToDate {
    if (nextDueDate == null) return true;
    return DateTime.now().isBefore(nextDueDate!);
  }

  /// Get status text in Thai
  String get statusText {
    if (isOverdue) return 'เกินกำหนด';
    if (isDueSoon) return 'ใกล้ถึงกำหนด';
    if (isUpToDate) return 'ถูกต้อง';
    return 'ไม่ระบุ';
  }

  /// Get status color
  String getStatusColor() {
    if (isOverdue) return 'red';
    if (isDueSoon) return 'orange';
    return 'green';
  }

  /// Get formatted date administered
  String get dateAdministeredText {
    return '${dateAdministered.day}/${dateAdministered.month}/${dateAdministered.year}';
  }

  /// Get formatted next due date
  String get nextDueDateText {
    if (nextDueDate == null) return 'ไม่ระบุ';
    return '${nextDueDate!.day}/${nextDueDate!.month}/${nextDueDate!.year}';
  }

  /// Get days until next due date
  int? get daysUntilDue {
    if (nextDueDate == null) return null;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  VaccinationEntity copyWith({
    int? id,
    int? petId,
    String? vaccineName,
    DateTime? dateAdministered,
    DateTime? nextDueDate,
    String? clinicName,
    String? notes,
    DateTime? createdAt,
  }) {
    return VaccinationEntity(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      vaccineName: vaccineName ?? this.vaccineName,
      dateAdministered: dateAdministered ?? this.dateAdministered,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      clinicName: clinicName ?? this.clinicName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
