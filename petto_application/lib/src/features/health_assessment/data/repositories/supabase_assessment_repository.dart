import 'package:supabase_flutter/supabase_flutter.dart';

/// Health Assessment model for Supabase
class Assessment {
  final String id;
  final String petId;
  final String? imageUrl;
  final String? symptoms;
  final String? aiDiagnosis;
  final String? severityLevel;
  final DateTime createdAt;

  Assessment({
    required this.id,
    required this.petId,
    this.imageUrl,
    this.symptoms,
    this.aiDiagnosis,
    this.severityLevel,
    required this.createdAt,
  });

  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      id: map['id'] as String,
      petId: map['pet_id'] as String,
      imageUrl: map['image_url'] as String?,
      symptoms: map['symptoms'] as String?,
      aiDiagnosis: map['ai_diagnosis'] as String?,
      severityLevel: map['severity_level'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pet_id': petId,
      'image_url': imageUrl,
      'symptoms': symptoms,
      'ai_diagnosis': aiDiagnosis,
      'severity_level': severityLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Repository for health assessments using Supabase
class SupabaseAssessmentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new health assessment
  Future<Assessment> createAssessment({
    required String petId,
    String? imageUrl,
    String? symptoms,
    String? aiDiagnosis,
    String? severityLevel,
  }) async {
    final response = await _supabase.from('assessments').insert({
      'pet_id': petId,
      'image_url': imageUrl,
      'symptoms': symptoms,
      'ai_diagnosis': aiDiagnosis,
      'severity_level': severityLevel,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to create assessment');
    }

    return Assessment.fromMap(response.first);
  }

  /// Get all assessments for a specific pet
  Future<List<Assessment>> getPetAssessments(String petId) async {
    final response = await _supabase
        .from('assessments')
        .select()
        .eq('pet_id', petId)
        .order('created_at', ascending: false);

    return response.map((map) => Assessment.fromMap(map)).toList();
  }

  /// Get a single assessment by ID
  Future<Assessment> getAssessment(String assessmentId) async {
    final response = await _supabase
        .from('assessments')
        .select()
        .eq('id', assessmentId)
        .single();

    return Assessment.fromMap(response);
  }

  /// Get all assessments for current user (across all pets)
  Future<List<Assessment>> getUserAssessments() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // First get user's pets
    final petsResponse = await _supabase
        .from('pets')
        .select()
        .eq('user_id', userId);

    final petIds = petsResponse.map((p) => p['id'] as String).toList();

    if (petIds.isEmpty) return [];

    // Then get assessments for those pets
    final response = await _supabase
        .from('assessments')
        .select()
        .inFilter('pet_id', petIds as List<Object>)
        .order('created_at', ascending: false);

    return response.map((map) => Assessment.fromMap(map)).toList();
  }
}
