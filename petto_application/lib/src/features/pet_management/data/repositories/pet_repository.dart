import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';

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
      avatarUri: json['avatar_uri'] as String?,
    );
  }
}

/// Pet management against the FastAPI backend. Creating a pet is authenticated
/// (the backend derives the owner from the Bearer token); listing is by user id.
class PetRepository {
  final Dio dio;

  PetRepository({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectionTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
            ));

  /// POST /api/v1/pets — owner taken from the Bearer token by the backend.
  Future<Pet> createPet({
    required String token,
    required String name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weightKg,
  }) async {
    try {
      final response = await dio.post(
        AppConfig.petsEndpoint,
        data: {
          'name': name,
          'species': species,
          'breed': breed,
          'gender': gender,
          'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
          'weight_kg': weightKg,
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
      if (detail is String && detail.isNotEmpty) return detail;
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
