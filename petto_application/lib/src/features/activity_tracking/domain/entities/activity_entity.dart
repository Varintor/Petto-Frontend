/// Domain entity for a completed activity (Feature 4 - Mode A walk).
///
/// Mirrors the backend `ActivityResponse` (app/routers/activities.py). Per the
/// project's privacy policy, only aggregate data is persisted - the raw GPS
/// route stays on the device during the walk and is not uploaded in Phase 0.
class ActivityEntity {
  final int id;
  final int petId;
  final String activityType; // "walking" | "running" | "playing"
  final double durationMinutes;
  final double distanceMeters;
  final bool isMissionCompleted;
  final DateTime createdAt;

  const ActivityEntity({
    required this.id,
    required this.petId,
    required this.activityType,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.isMissionCompleted,
    required this.createdAt,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get durationText {
    final total = durationMinutes.round();
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Average speed in km/h.
  double get averageSpeedKmh {
    if (durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60.0;
    final km = distanceMeters / 1000.0;
    return km / hours;
  }

  String get activityTypeThai {
    switch (activityType.toLowerCase()) {
      case 'walking':
        return 'เดินเล่น';
      case 'running':
        return 'วิ่งเล่น';
      case 'playing':
        return 'เล่นสนุก';
      default:
        return activityType;
    }
  }
}
