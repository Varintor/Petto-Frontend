import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/calendar_repository.dart';
import '../../domain/calendar_event.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({
    Iterable<CalendarEventData> seedEvents = const [],
    CalendarRepository? repository,
  }) : _seedEvents = List<CalendarEventData>.of(seedEvents),
       _events = List<CalendarEventData>.of(seedEvents),
       _repository = repository ?? CalendarRepositoryImpl();

  final List<CalendarEventData> _seedEvents;
  final List<CalendarEventData> _events;
  final CalendarRepository _repository;
  String? _storageKey;
  int? _petId;
  bool _useBackend = false;
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
    _petId = petId;
    _useBackend = userId != null;
    _events
      ..clear()
      ..addAll(_useBackend ? const [] : _seedEvents);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (generation != _loadGeneration) return;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final restored = decoded
              .whereType<Map>()
              .map(
                (entry) => CalendarEventData.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList();
          _events
            ..clear()
            ..addAll(restored);
        }
      } on FormatException {
        // Ignore a corrupt cache and continue to the authoritative backend.
      }
    }
    notifyListeners();

    if (!_useBackend) return;
    final remoteEvents = await _repository.listEvents(petId);
    if (generation != _loadGeneration) return;
    _events
      ..clear()
      ..addAll(remoteEvents);
    notifyListeners();
    await _persist();
  }

  Future<CalendarEventData> add(CalendarEventData event) async {
    final saved = _useBackend
        ? await _repository.createEvent(_requirePetId(), event)
        : event;
    _events.add(saved);
    notifyListeners();
    await _persist();
    return saved;
  }

  Future<void> remove(String eventId) async {
    if (_useBackend) {
      final parsedId = int.tryParse(eventId);
      if (parsedId == null) {
        throw StateError('A backend calendar event must have a numeric id.');
      }
      await _repository.deleteEvent(parsedId);
    }
    _events.removeWhere((event) => event.id == eventId);
    notifyListeners();
    await _persist();
  }

  int _requirePetId() {
    final petId = _petId;
    if (petId == null) throw StateError('Calendar has not been loaded.');
    return petId;
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
