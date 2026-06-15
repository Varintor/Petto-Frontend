import 'package:flutter/material.dart';

class MissionModel {
  final int id;
  final int petId;
  final String missionDate;
  final String title;
  final String missionType;
  final double? targetValue;
  final String? unit;
  final String? reward;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  MissionModel({
    required this.id,
    required this.petId,
    required this.missionDate,
    required this.title,
    required this.missionType,
    this.targetValue,
    this.unit,
    this.reward,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as int,
      petId: json['pet_id'] as int,
      missionDate: json['mission_date'] as String,
      title: json['title'] as String,
      missionType: json['mission_type'] as String,
      targetValue: (json['target_value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      reward: json['reward'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  IconData get icon {
    switch (missionType) {
      case 'walk':
        return Icons.pets_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'ai_check':
        return Icons.search_rounded;
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'play':
        return Icons.sports_esports_rounded;
      case 'photo':
        return Icons.photo_camera_rounded;
      case 'dental_check':
        return Icons.mood_rounded;
      case 'nail_check':
        return Icons.cut_rounded;
      case 'ear_check':
        return Icons.hearing_rounded;
      case 'weight_log':
        return Icons.monitor_weight_rounded;
      case 'bonding':
        return Icons.favorite_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'feeding_check':
        return Icons.restaurant_rounded;
      case 'eye_nose_check':
        return Icons.visibility_rounded;
      case 'social':
        return Icons.groups_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  String get rewardDisplay => reward ?? '0 Treats';
}

class DashboardStatsModel {
  final int healthScore;
  final int activitiesThisMonth;
  final double totalDurationMinutes;
  final double totalDistanceMeters;
  final String vaccinationStatus;
  final DateTime? nextVaccinationDate;
  final int missionsCompletedThisWeek;
  final int missionStreak;
  final String? recentRiskLevel;

  DashboardStatsModel({
    required this.healthScore,
    required this.activitiesThisMonth,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
    required this.vaccinationStatus,
    this.nextVaccinationDate,
    required this.missionsCompletedThisWeek,
    required this.missionStreak,
    this.recentRiskLevel,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      healthScore: json['health_score'] as int? ?? 0,
      activitiesThisMonth: json['activities_this_month'] as int? ?? 0,
      totalDurationMinutes:
          (json['total_duration_minutes'] as num?)?.toDouble() ?? 0,
      totalDistanceMeters:
          (json['total_distance_meters'] as num?)?.toDouble() ?? 0,
      vaccinationStatus: json['vaccination_status'] as String? ?? 'no_records',
      nextVaccinationDate: json['next_vaccination_date'] != null
          ? DateTime.parse(json['next_vaccination_date'] as String)
          : null,
      missionsCompletedThisWeek:
          json['missions_completed_this_week'] as int? ?? 0,
      missionStreak: json['mission_streak'] as int? ?? 0,
      recentRiskLevel: json['recent_risk_level'] as String?,
    );
  }

  static DashboardStatsModel empty() => DashboardStatsModel(
        healthScore: 0,
        activitiesThisMonth: 0,
        totalDurationMinutes: 0,
        totalDistanceMeters: 0,
        vaccinationStatus: 'no_records',
        missionsCompletedThisWeek: 0,
        missionStreak: 0,
      );

  int get happinessPercent => healthScore.clamp(0, 100);

  int get energyPercent {
    final target = 150.0;
    return ((totalDurationMinutes / target) * 100).round().clamp(0, 100);
  }
}
