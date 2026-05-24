import '../../domain/entities/activity_entity.dart';

/// Maps the backend `ActivityResponse` JSON to the domain [ActivityEntity].
///
/// Backend JSON:
/// {
///   "id": 1, "pet_id": 1, "activity_type": "walking",
///   "duration_minutes": 12.5, "distance_meters": 800.0,
///   "is_mission_completed": false, "created_at": "2026-05-24T..."
/// }
class ActivityModel {
  final int id;
  final int petId;
  final String activityType;
  final double durationMinutes;
  final double distanceMeters;
  final bool isMissionCompleted;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.petId,
    required this.activityType,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.isMissionCompleted,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as int,
      petId: json['pet_id'] as int,
      activityType: json['activity_type'] as String,
      durationMinutes: (json['duration_minutes'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      isMissionCompleted: json['is_mission_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ActivityEntity toEntity() => ActivityEntity(
        id: id,
        petId: petId,
        activityType: activityType,
        durationMinutes: durationMinutes,
        distanceMeters: distanceMeters,
        isMissionCompleted: isMissionCompleted,
        createdAt: createdAt,
      );
}

/// Maps the backend `ActivityStatsResponse` JSON.
class ActivityStatsModel {
  final int totalActivities;
  final double totalDurationMinutes;
  final double totalDistanceMeters;
  final int completedMissions;

  ActivityStatsModel({
    required this.totalActivities,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
    required this.completedMissions,
  });

  factory ActivityStatsModel.fromJson(Map<String, dynamic> json) {
    return ActivityStatsModel(
      totalActivities: json['total_activities'] as int? ?? 0,
      totalDurationMinutes:
          (json['total_duration_minutes'] as num?)?.toDouble() ?? 0,
      totalDistanceMeters:
          (json['total_distance_meters'] as num?)?.toDouble() ?? 0,
      completedMissions: json['completed_missions'] as int? ?? 0,
    );
  }

  static ActivityStatsModel empty() => ActivityStatsModel(
        totalActivities: 0,
        totalDurationMinutes: 0,
        totalDistanceMeters: 0,
        completedMissions: 0,
      );

  String get distanceText {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toStringAsFixed(0)} m';
    }
    return '${(totalDistanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get durationText {
    final total = totalDurationMinutes.round();
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
