// UTC-10: DashboardStatsModel.fromJson mapping, default fallbacks, getters.
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/missions/data/models/mission_model.dart';

void main() {
  group('UTC-10 DashboardStatsModel.fromJson', () {
    test('UTC-10-TC-01: maps a full stats JSON', () {
      final json = {
        'health_score': 95,
        'activities_this_month': 42,
        'total_duration_minutes': 1200.5,
        'total_distance_meters': 15000.0,
        'vaccination_status': 'up_to_date',
        'next_vaccination_date': '2026-12-01T00:00:00',
        'missions_completed_this_week': 7,
        'mission_streak': 14,
        'recent_risk_level': 'Low Risk',
      };

      final s = DashboardStatsModel.fromJson(json);

      expect(s.healthScore, 95);
      expect(s.activitiesThisMonth, 42);
      expect(s.missionsCompletedThisWeek, 7);
      expect(s.missionStreak, 14);
      expect(s.vaccinationStatus, 'up_to_date');
      expect(s.recentRiskLevel, 'Low Risk');
      expect(s.nextVaccinationDate, DateTime.parse('2026-12-01T00:00:00'));
    });

    test('UTC-10-TC-02: missing keys use safe defaults', () {
      final s = DashboardStatsModel.fromJson(<String, dynamic>{});

      expect(s.healthScore, 0);
      expect(s.activitiesThisMonth, 0);
      expect(s.vaccinationStatus, 'no_records');
      expect(s.recentRiskLevel, isNull);
      expect(s.nextVaccinationDate, isNull);
    });

    test('UTC-10-TC-03: derived percentage getters', () {
      final s = DashboardStatsModel.fromJson({
        'health_score': 80,
        'total_duration_minutes': 75,
      });

      expect(s.happinessPercent, 80);
      expect(s.energyPercent, 50); // 75 / 150 * 100
    });
  });
}
