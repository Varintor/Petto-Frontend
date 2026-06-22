// UTC-09: MissionModel.fromJson mapping, nullables, and icon resolution.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/missions/data/models/mission_model.dart';

void main() {
  group('UTC-09 MissionModel.fromJson', () {
    test('UTC-09-TC-01: maps a full mission JSON', () {
      final json = {
        'id': 12,
        'pet_id': 5,
        'mission_date': '2026-06-18',
        'title': 'Walk for 15 minutes',
        'mission_type': 'walk',
        'target_value': 15,
        'unit': 'minutes',
        'reward': '50 Treats',
        'is_completed': true,
        'completed_at': '2026-06-18T09:30:00',
        'created_at': '2026-06-18T00:00:00',
      };

      final m = MissionModel.fromJson(json);

      expect(m.id, 12);
      expect(m.petId, 5);
      expect(m.title, 'Walk for 15 minutes');
      expect(m.targetValue, isA<double>());
      expect(m.targetValue, 15.0);
      expect(m.isCompleted, true);
      expect(m.completedAt, isNotNull);
      expect(m.createdAt, DateTime.parse('2026-06-18T00:00:00'));
    });

    test('UTC-09-TC-02: handles missing/nullable fields', () {
      final json = {
        'id': 1,
        'pet_id': 5,
        'mission_date': '2026-06-18',
        'title': 'Fresh water refill',
        'mission_type': 'water',
        'created_at': '2026-06-18T00:00:00',
      };

      final m = MissionModel.fromJson(json);

      expect(m.isCompleted, false); // defaults
      expect(m.targetValue, isNull);
      expect(m.unit, isNull);
      expect(m.completedAt, isNull);
      expect(m.rewardDisplay, '0 Treats');
    });

    test('UTC-09-TC-03: maps mission_type to an icon', () {
      MissionModel build(String type) => MissionModel.fromJson({
            'id': 1,
            'pet_id': 5,
            'mission_date': '2026-06-18',
            'title': 't',
            'mission_type': type,
            'created_at': '2026-06-18T00:00:00',
          });

      expect(build('walk').icon, Icons.pets_rounded);
      expect(build('water').icon, Icons.water_drop_rounded);
      expect(build('xyz-unknown').icon, Icons.flag_rounded); // fallback
    });
  });
}
