import 'package:flutter/material.dart';

/// Uses only compile-time Material icon constants so Flutter can tree-shake
/// the icon font in release builds. Persist the semantic event type rather
/// than framework-specific icon code points.
IconData calendarIconForType(String type) => switch (type) {
  'medication' => Icons.medication_rounded,
  'vet' => Icons.medical_services_rounded,
  'grooming' => Icons.content_cut_rounded,
  'walk' || 'exercise' => Icons.directions_walk_rounded,
  _ => Icons.event_available_rounded,
};

class CalendarEventData {
  const CalendarEventData({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.type,
    required this.completed,
    required this.date,
    required this.color,
    required this.icon,
    this.startsAt,
  });

  final String id;
  final String title;
  final String timeLabel;
  final String type;
  final bool completed;
  final DateTime date;
  final DateTime? startsAt;
  final Color color;
  final IconData icon;

  int get day => date.day;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'time_label': timeLabel,
    'type': type,
    'completed': completed,
    'date': date.toIso8601String(),
    'starts_at': startsAt?.toIso8601String(),
    'color': color.toARGB32(),
  };

  static CalendarEventData fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'care';
    return CalendarEventData(
      id: json['id'] as String,
      title: json['title'] as String,
      timeLabel: json['time_label'] as String? ?? 'All day',
      type: type,
      completed: json['completed'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      color: Color(json['color'] as int? ?? 0xFF7B3034),
      icon: calendarIconForType(type),
    );
  }
}
