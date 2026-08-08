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

  HistoryEntryModel({
    required this.type,
    required this.refId,
    required this.timestamp,
    required this.title,
    this.summary,
    this.riskLevel,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      HistoryEntryModel(
        type: json['type'] as String,
        refId: json['ref_id'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        title: json['title'] as String,
        summary: json['summary'] as String?,
        riskLevel: json['risk_level'] as String?,
      );
}

abstract class HealthHistoryRepository {
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
  Set<String> _typeFilter = {};
  bool _loading = false;
  String? _error;

  List<HistoryEntryModel> get entries => _entries;
  Set<String> get typeFilter => _typeFilter;
  bool get loading => _loading;
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
      _entries = await repository.getHistory(id, types: _typeFilter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearForAccount() {
    _petId = null;
    _entries = [];
    _typeFilter = {};
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
