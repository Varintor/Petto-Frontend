import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petto_application/src/features/calendar/domain/calendar_event.dart';
import 'package:petto_application/src/features/calendar/data/calendar_repository.dart';
import 'package:petto_application/src/features/calendar/presentation/controllers/calendar_controller.dart';

class _FakeCalendarRepository implements CalendarRepository {
  _FakeCalendarRepository(this.remoteEvents);

  final List<CalendarEventData> remoteEvents;
  int? listedPetId;
  int? createdPetId;
  int? deletedEventId;

  @override
  Future<List<CalendarEventData>> listEvents(int petId) async {
    listedPetId = petId;
    return List.of(remoteEvents);
  }

  @override
  Future<CalendarEventData> createEvent(
    int petId,
    CalendarEventData event,
  ) async {
    createdPetId = petId;
    return CalendarEventData(
      id: '42',
      title: event.title,
      timeLabel: event.timeLabel,
      type: event.type,
      completed: event.completed,
      date: event.date,
      startsAt: event.startsAt,
      color: event.color,
      icon: event.icon,
    );
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    deletedEventId = eventId;
  }
}

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
    await first.load(userId: null, petId: 11);
    await first.add(event('custom'));

    final sameScope = CalendarController(seedEvents: [event('seed')]);
    await sameScope.load(userId: null, petId: 11);
    expect(sameScope.events.map((item) => item.id), ['seed', 'custom']);

    final otherPet = CalendarController(seedEvents: [event('seed')]);
    await otherPet.load(userId: null, petId: 12);
    expect(otherPet.events.map((item) => item.id), ['seed']);
  });

  test('remove updates persisted state', () async {
    final controller = CalendarController(seedEvents: [event('seed')]);
    await controller.load(userId: null, petId: 11);
    await controller.remove('seed');

    final restored = CalendarController(seedEvents: [event('seed')]);
    await restored.load(userId: null, petId: 11);
    expect(restored.events, isEmpty);
  });

  test(
    'authenticated calendar replaces cache and writes through backend',
    () async {
      final repository = _FakeCalendarRepository([event('10')]);
      final controller = CalendarController(
        seedEvents: [event('demo')],
        repository: repository,
      );

      await controller.load(userId: 7, petId: 11);
      expect(repository.listedPetId, 11);
      expect(controller.events.map((item) => item.id), ['10']);

      final saved = await controller.add(event('temporary'));
      expect(repository.createdPetId, 11);
      expect(saved.id, '42');
      expect(controller.events.map((item) => item.id), ['10', '42']);

      await controller.remove('42');
      expect(repository.deletedEventId, 42);
      expect(controller.events.map((item) => item.id), ['10']);
    },
  );

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
