import 'package:supabase_flutter/supabase_flutter.dart';

/// Pet model for Supabase
class Pet {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    required this.gender,
    this.dateOfBirth,
    this.weightKg,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String?,
      gender: map['gender'] as String,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      weightKg: map['weight_kg'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'weight_kg': weightKg,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Repository for pet management using Supabase
class SupabasePetRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new pet
  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    required String gender,
    DateTime? dateOfBirth,
    double? weightKg,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.from('pets').insert({
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'weight_kg': weightKg,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to create pet');
    }

    return Pet.fromMap(response.first);
  }

  /// Get all pets for current user
  Future<List<Pet>> getUserPets() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((map) => Pet.fromMap(map)).toList();
  }

  /// Get a single pet by ID
  Future<Pet> getPet(String petId) async {
    final response = await _supabase
        .from('pets')
        .select()
        .eq('id', petId)
        .single();

    return Pet.fromMap(response);
  }

  /// Update pet information
  Future<Pet> updatePet({
    required String petId,
    String? name,
    String? breed,
    double? weightKg,
  }) async {
    final response = await _supabase
        .from('pets')
        .update({
          'name': name,
          'breed': breed,
          'weight_kg': weightKg,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', petId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to update pet');
    }

    return Pet.fromMap(response.first);
  }

  /// Delete a pet
  Future<void> deletePet(String petId) async {
    await _supabase.from('pets').delete().eq('id', petId);
  }
}
