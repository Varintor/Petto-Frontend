import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/activity_entity.dart';
import '../models/activity_model.dart';

/// Repository for Feature 4 - Mode A (phone walk tracking).
abstract class ActivityRepository {
  Future<ActivityEntity> createActivity({
    required int petId,
    required String activityType,
    required double durationMinutes,
    required double distanceMeters,
    bool isMissionCompleted,
  });

  Future<List<ActivityEntity>> getPetActivities(int petId);
  Future<ActivityStatsModel> getStats(int petId);
}

class ActivityRepositoryImpl implements ActivityRepository {
  final Dio dio;

  ActivityRepositoryImpl({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectionTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
            ));

  @override
  Future<ActivityEntity> createActivity({
    required int petId,
    required String activityType,
    required double durationMinutes,
    required double distanceMeters,
    bool isMissionCompleted = false,
  }) async {
    try {
      // Backend POST /api/v1/activities expects a JSON body (ActivityCreate).
      final response = await dio.post(
        AppConfig.activitiesEndpoint,
        data: {
          'pet_id': petId,
          'activity_type': activityType,
          'duration_minutes': durationMinutes,
          'distance_meters': distanceMeters,
          'is_mission_completed': isMissionCompleted,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ActivityModel.fromJson(response.data).toEntity();
      }
      throw Exception('Failed to save activity: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error saving activity: $e');
    }
  }

  @override
  Future<List<ActivityEntity>> getPetActivities(int petId) async {
    try {
      final response = await dio.get(AppConfig.petActivitiesEndpoint(petId));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) =>
                ActivityModel.fromJson(json as Map<String, dynamic>).toEntity())
            .toList();
      }
      throw Exception('Failed to fetch activities: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  @override
  Future<ActivityStatsModel> getStats(int petId) async {
    try {
      final response = await dio.get(AppConfig.petActivityStatsEndpoint(petId));
      if (response.statusCode == 200) {
        return ActivityStatsModel.fromJson(response.data);
      }
      throw Exception('Failed to fetch stats: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_describeDioError(e));
    } catch (e) {
      throw Exception('Error fetching stats: $e');
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
