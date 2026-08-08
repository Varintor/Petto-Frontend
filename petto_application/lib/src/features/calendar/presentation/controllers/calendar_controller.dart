import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calendar_event.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({Iterable<CalendarEventData> seedEvents = const []})
    : _seedEvents = List<CalendarEventData>.of(seedEvents),
      _events = List<CalendarEventData>.of(seedEvents);

  final List<CalendarEventData> _seedEvents;
  final List<CalendarEventData> _events;
  String? _storageKey;
  int _loadGeneration = 0;

  List<CalendarEventData> get events => List.unmodifiable(_events);

  static String storageKey({required int? userId, required int petId}) {
    final owner = userId == null ? 'guest' : 'u$userId';
    return 'petto.calendar.events.v2.$owner.p$petId';
  }

  Future<void> load({required int? userId, required int petId}) async {
    final generation = ++_loadGeneration;
    final key = storageKey(userId: userId, petId: petId);
    _storageKey = key;
    _events
      ..clear()
      ..addAll(_seedEvents);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (generation != _loadGeneration) return;
    if (raw == null) {
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = decoded
          .whereType<Map>()
          .map(
            (entry) =>
                CalendarEventData.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
      _events
        ..clear()
        ..addAll(restored);
      notifyListeners();
    } on FormatException {
      // Preserve the current in-memory state if a local record is corrupt.
    }
  }

  Future<void> add(CalendarEventData event) async {
    _events.add(event);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final key = _storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(_events.map((event) => event.toJson()).toList()),
    );
  }
}
