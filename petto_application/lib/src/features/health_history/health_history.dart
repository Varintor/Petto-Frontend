import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

/// Feature 5: Health History Review — one unified reverse-chronological
/// timeline (assessments, activities, vaccinations, completed missions) from
/// GET /api/v1/pets/{petId}/history.
class HistoryEntryModel {
  final String type; // assessment | activity | vaccination | mission
  final int refId;
  final DateTime timestamp;
  final String title;
  final String? summary;
  final String? riskLevel; // assessments only
  final String? status;
  final String? errorCode;

  HistoryEntryModel({
    required this.type,
    required this.refId,
    required this.timestamp,
    required this.title,
    this.summary,
    this.riskLevel,
    this.status,
    this.errorCode,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      HistoryEntryModel(
        type: json['type'] as String,
        refId: json['ref_id'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        title: json['title'] as String,
        summary: json['summary'] as String?,
        riskLevel: json['risk_level'] as String?,
        status: json['status'] as String?,
        errorCode: json['error_code'] as String?,
      );
}

class HealthCardModel {
  const HealthCardModel({
    required this.petId,
    required this.name,
    this.species,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.weightKg,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.notes,
    this.latestAssessment,
    this.latestVaccination,
    this.recentActivity,
    this.generatedAt,
  });

  final int petId;
  final String name;
  final String? species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? notes;
  final HistoryEntryModel? latestAssessment;
  final HistoryEntryModel? latestVaccination;
  final HistoryEntryModel? recentActivity;
  final DateTime? generatedAt;

  factory HealthCardModel.fromJson(Map<String, dynamic> json) =>
      HealthCardModel(
        petId: json['pet_id'] as int,
        name: json['name'] as String,
        species: json['species'] as String?,
        breed: json['breed'] as String?,
        gender: json['gender'] as String?,
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        bloodType: json['blood_type'] as String?,
        allergies: List<String>.from(json['allergies'] as List? ?? const []),
        chronicConditions: List<String>.from(
          json['chronic_conditions'] as List? ?? const [],
        ),
        currentMedications: List<String>.from(
          json['current_medications'] as List? ?? const [],
        ),
        notes: json['notes'] as String?,
        latestAssessment: json['latest_assessment'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['latest_assessment'] as Map),
              ),
        latestVaccination: json['latest_vaccination'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['latest_vaccination'] as Map),
              ),
        recentActivity: json['recent_activity'] == null
            ? null
            : HistoryEntryModel.fromJson(
                Map<String, dynamic>.from(json['recent_activity'] as Map),
              ),
        generatedAt: json['generated_at'] == null
            ? null
            : DateTime.parse(json['generated_at'] as String),
      );
}

class HealthProfileModel {
  const HealthProfileModel({
    required this.petId,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.notes,
    this.updatedAt,
  });

  final int petId;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? notes;
  final DateTime? updatedAt;

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) =>
      HealthProfileModel(
        petId: json['pet_id'] as int,
        allergies: List<String>.from(json['allergies'] as List? ?? const []),
        chronicConditions: List<String>.from(
          json['chronic_conditions'] as List? ?? const [],
        ),
        currentMedications: List<String>.from(
          json['current_medications'] as List? ?? const [],
        ),
        notes: json['notes'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );
}

abstract class HealthHistoryRepository {
  Future<HealthCardModel> getHealthCard(int petId);
  Future<HealthProfileModel> updateHealthProfile(
    int petId, {
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  });
  Future<List<HistoryEntryModel>> getHistory(
    int petId, {
    Set<String>? types,
    DateTime? from,
    DateTime? to,
    int limit,
  });
}

class HealthHistoryRepositoryImpl implements HealthHistoryRepository {
  final Dio dio;

  HealthHistoryRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<HealthCardModel> getHealthCard(int petId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/health-card',
    );
    return HealthCardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<HealthProfileModel> updateHealthProfile(
    int petId, {
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  }) async {
    final response = await dio.put(
      '${AppConfig.apiPrefix}/pets/$petId/health-profile',
      data: {
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
        'current_medications': currentMedications,
        'notes': notes,
      },
    );
    return HealthProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<HistoryEntryModel>> getHistory(
    int petId, {
    Set<String>? types,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    String d(DateTime v) => v.toIso8601String().split('T').first;
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/history',
      queryParameters: {
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        if (from != null) 'date_from': d(from),
        if (to != null) 'date_to': d(to),
        'limit': limit,
      },
    );
    return ((response.data as Map<String, dynamic>)['entries'] as List<dynamic>)
        .map((j) => HistoryEntryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

/// Timeline state for the Health History screen. Same pattern as the other
/// controllers: null petId (guest / no pet yet) skips loading (SRS-F2-018).
class HealthHistoryController extends ChangeNotifier {
  final HealthHistoryRepository repository;

  HealthHistoryController({HealthHistoryRepository? repository})
    : repository = repository ?? HealthHistoryRepositoryImpl();

  int? _petId;
  List<HistoryEntryModel> _entries = [];
  HealthCardModel? _card;
  Set<String> _typeFilter = {};
  bool _loading = false;
  bool _savingProfile = false;
  String? _error;

  List<HistoryEntryModel> get entries => _entries;
  HealthCardModel? get card => _card;
  int? get loadedPetId => _petId;
  Set<String> get typeFilter => _typeFilter;
  bool get loading => _loading;
  bool get savingProfile => _savingProfile;
  String? get error => _error;

  Future<void> load({int? petId, Set<String>? types}) async {
    final id = petId ?? _petId;
    if (id == null) {
      _entries = [];
      notifyListeners();
      return;
    }
    _petId = id;
    if (types != null) _typeFilter = types;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        repository.getHistory(id, types: _typeFilter),
        repository.getHealthCard(id),
      ]);
      if (_petId != id) return;
      _entries = results[0] as List<HistoryEntryModel>;
      _card = results[1] as HealthCardModel;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  }) async {
    final id = _petId;
    if (id == null || _savingProfile) return false;
    _savingProfile = true;
    _error = null;
    notifyListeners();
    try {
      await repository.updateHealthProfile(
        id,
        allergies: allergies,
        chronicConditions: chronicConditions,
        currentMedications: currentMedications,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );
      _card = await repository.getHealthCard(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _savingProfile = false;
      notifyListeners();
    }
  }

  void clearForAccount() {
    _petId = null;
    _entries = [];
    _card = null;
    _typeFilter = {};
    _loading = false;
    _savingProfile = false;
    _error = null;
    notifyListeners();
  }
}
