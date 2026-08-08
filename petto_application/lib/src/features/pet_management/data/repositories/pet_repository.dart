import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';

/// Pet as returned by the FastAPI backend (`pet_profiles`, bigint ids).
class Pet {
  final int id;
  final int userId;
  final String name;
  final String? species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? bloodType;
  final String? avatarUri;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    this.species,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.weightKg,
    this.bloodType,
    this.avatarUri,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      species: json['species'] as String?,
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bloodType: json['blood_type'] as String?,
      avatarUri: json['avatar_uri'] as String?,
    );
  }
}

/// Pet management against the FastAPI backend. Creating a pet is authenticated
/// (the backend derives the owner from the Bearer token); listing is by user id.
class PetRepository {
  final Dio dio;

  PetRepository({Dio? dio}) : dio = dio ?? ApiClient.dio;

  /// POST /api/v1/pets — owner taken from the Bearer token by the backend.
  Future<Pet> createPet({
    required String token,
    required String name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weightKg,
    String? bloodType,
  }) async {
    try {
      final response = await dio.post(
        AppConfig.petsEndpoint,
        data: {
          'name': name,
          'species': species,
          'breed': breed,
          'gender': gender,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'weight_kg': weightKg,
          if (bloodType != null && bloodType.isNotEmpty)
            'blood_type': bloodType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Pet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  /// PUT /api/v1/pets/{petId} — update an existing pet profile.
  Future<Pet> updatePet({
    required String token,
    required int petId,
    required String name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weightKg,
    String? bloodType,
  }) async {
    try {
      final response = await dio.put(
        AppConfig.petEndpoint(petId),
        data: {
          'name': name,
          'species': species,
          'breed': breed,
          'gender': gender,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'weight_kg': weightKg,
          if (bloodType != null && bloodType.isNotEmpty)
            'blood_type': bloodType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Pet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  /// GET /api/v1/users/{userId}/pets
  Future<List<Pet>> getUserPets(int userId) async {
    try {
      final response = await dio.get(AppConfig.userPetsEndpoint(userId));
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Pet.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  String _describeDioError(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is String && detail.isNotEmpty) {
        return 'Server error ${e.response?.statusCode}: $detail';
      }
      return 'Server error ${e.response?.statusCode}.';
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please check your connection.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      default:
        return 'Network error. Please try again.';
    }
  }
}
