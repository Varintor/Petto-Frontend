import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEventData>> listEvents(int petId);

  Future<CalendarEventData> createEvent(int petId, CalendarEventData event);

  Future<void> deleteEvent(int eventId);
}

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  @override
  Future<List<CalendarEventData>> listEvents(int petId) async {
    final response = await _dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/calendar-events',
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => CalendarEventData.fromApiJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<CalendarEventData> createEvent(
    int petId,
    CalendarEventData event,
  ) async {
    final response = await _dio.post(
      '${AppConfig.apiPrefix}/pets/$petId/calendar-events',
      data: {
        'title': event.title,
        'event_type': event.type == 'exercise' ? 'walk' : event.type,
        'event_date': _dateOnly(event.date),
        if (event.startsAt != null)
          'starts_at': event.startsAt!.toUtc().toIso8601String(),
        'reminder_minutes': event.startsAt == null ? null : 30,
      },
    );
    return CalendarEventData.fromApiJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    await _dio.delete('${AppConfig.apiPrefix}/calendar-events/$eventId');
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
