import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../models/mission_model.dart';

abstract class MissionsRepository {
  Future<List<MissionModel>> getTodayMissions(int petId);
  Future<List<MissionModel>> seedTodayMissions(int petId);
  Future<MissionModel> completeMission(int missionId, {bool isCompleted = true});
  Future<DashboardStatsModel> getDashboardStats(int petId);
}

class MissionsRepositoryImpl implements MissionsRepository {
  final Dio dio;

  MissionsRepositoryImpl({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectionTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
            ));

  @override
  Future<List<MissionModel>> getTodayMissions(int petId) async {
    try {
      final response =
          await dio.get(AppConfig.petTodayMissionsEndpoint(petId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => MissionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch missions: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<List<MissionModel>> seedTodayMissions(int petId) async {
    try {
      final response =
          await dio.post(AppConfig.petSeedTodayMissionsEndpoint(petId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => MissionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to seed missions: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<MissionModel> completeMission(int missionId,
      {bool isCompleted = true}) async {
    try {
      final response = await dio.put(
        AppConfig.completeMissionEndpoint(missionId),
        queryParameters: {'is_completed': isCompleted},
      );
      if (response.statusCode == 200) {
        return MissionModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to complete mission: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  @override
  Future<DashboardStatsModel> getDashboardStats(int petId) async {
    try {
      final response =
          await dio.get(AppConfig.petDashboardStatsEndpoint(petId));
      if (response.statusCode == 200) {
        return DashboardStatsModel.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch dashboard stats: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Cannot reach ${AppConfig.apiBaseUrl}. Is the backend running?';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout talking to the backend.';
      case DioExceptionType.badResponse:
        final detail = e.response?.data is Map
            ? (e.response?.data['detail'] ?? '')
            : '';
        return 'Server error ${e.response?.statusCode}: $detail';
      default:
        return 'Network error: ${e.message}';
    }
  }
}
