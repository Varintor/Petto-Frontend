import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petto_application/src/features/calendar/domain/calendar_event.dart';
import 'package:petto_application/src/features/calendar/presentation/controllers/calendar_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  CalendarEventData event(String id) => CalendarEventData(
    id: id,
    title: 'Vet visit',
    timeLabel: '09:00 AM',
    type: 'vet',
    completed: false,
    date: DateTime(2026, 8, 8),
    startsAt: DateTime(2026, 8, 8, 9),
    color: Colors.red,
    icon: Icons.medical_services,
  );

  test('persists events per user and pet without cross-pet bleed', () async {
    final first = CalendarController(seedEvents: [event('seed')]);
    await first.load(userId: 7, petId: 11);
    await first.add(event('custom'));

    final sameScope = CalendarController(seedEvents: [event('seed')]);
    await sameScope.load(userId: 7, petId: 11);
    expect(sameScope.events.map((item) => item.id), ['seed', 'custom']);

    final otherPet = CalendarController(seedEvents: [event('seed')]);
    await otherPet.load(userId: 7, petId: 12);
    expect(otherPet.events.map((item) => item.id), ['seed']);
  });

  test('remove updates persisted state', () async {
    final controller = CalendarController(seedEvents: [event('seed')]);
    await controller.load(userId: 7, petId: 11);
    await controller.remove('seed');

    final restored = CalendarController(seedEvents: [event('seed')]);
    await restored.load(userId: 7, petId: 11);
    expect(restored.events, isEmpty);
  });

  test('restores a constant icon from the semantic event type', () {
    final restored = CalendarEventData.fromJson({
      ...event('legacy').toJson(),
      // Older records may still contain these fields. They are deliberately
      // ignored so release builds never construct IconData dynamically.
      'icon': 12345,
      'icon_family': 'MaterialIcons',
    });

    expect(restored.icon, Icons.medical_services_rounded);
    expect(restored.toJson(), isNot(contains('icon')));
    expect(restored.toJson(), isNot(contains('icon_family')));
  });
}
