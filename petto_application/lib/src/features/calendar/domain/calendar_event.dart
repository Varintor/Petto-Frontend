import 'package:flutter/material.dart';

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
    'icon': icon.codePoint,
    'icon_family': icon.fontFamily,
  };

  static CalendarEventData fromJson(Map<String, dynamic> json) {
    final iconCodePoint =
        json['icon'] as int? ?? Icons.event_available_rounded.codePoint;
    final iconFamily = json['icon_family'] as String? ?? 'MaterialIcons';
    return CalendarEventData(
      id: json['id'] as String,
      title: json['title'] as String,
      timeLabel: json['time_label'] as String? ?? 'All day',
      type: json['type'] as String? ?? 'care',
      completed: json['completed'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      color: Color(json['color'] as int? ?? 0xFF7B3034),
      icon: IconData(iconCodePoint, fontFamily: iconFamily),
    );
  }
}
