part of 'home_screen.dart';

enum _View {
  dashboard,
  missions,
  calendar,
  wellness,
  consult,
  notifications,
  profile,
  wardrobe,
  history,
}

enum _VetFilter { all, online }

class _PetData {
  const _PetData({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageLabel,
    required this.weightLabel,
    required this.status,
  });

  final int id;
  final String name;
  final String species;
  final String breed;
  final String ageLabel;
  final String weightLabel;
  final String status;
}

class _PetAppearanceData {
  const _PetAppearanceData({
    required this.species,
    required this.colorHex,
    required this.eyeType,
    required this.mouthType,
    required this.pattern,
    required this.equipped,
  });

  final String species;
  final String colorHex;
  final String eyeType;
  final String mouthType;
  final String pattern;
  final Set<String> equipped;
}

class _MissionData {
  const _MissionData({
    required this.id,
    required this.title,
    required this.reward,
    required this.icon,
  });

  final String id;
  final String title;
  final String reward;
  final IconData icon;
}

class _NotificationData {
  const _NotificationData({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.tint,
    this.unread = false,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color tint;
  final bool unread;
}

class _JourneyNodeData {
  const _JourneyNodeData({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    required this.alignment,
    required this.completed,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final String tag;
  final IconData icon;
  final Alignment alignment;
  final bool completed;
  final bool unlocked;
}

class _CalendarEventData {
  const _CalendarEventData({
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

  /// Full calendar date (year/month/day) the event lands on. Replaces the
  /// previous `day: int` field — events can now span months/years and the
  /// month-grid filter compares whole dates.
  final DateTime date;

  /// Optional precise start time. When present, [scheduleEventReminder] will
  /// fire an OS notification 30 min before. When null the event is "all day"
  /// and only the [timeLabel] is shown.
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

  static _CalendarEventData fromJson(Map<String, dynamic> json) {
    final iconCodePoint = json['icon'] as int? ?? Icons.event_available_rounded.codePoint;
    final iconFamily = json['icon_family'] as String? ?? 'MaterialIcons';
    return _CalendarEventData(
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

class _CalendarPlanStyle {
  const _CalendarPlanStyle({
    required this.label,
    required this.defaultTitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String defaultTitle;
  final IconData icon;
  final Color color;
}

class _VetChatMessageData {
  const _VetChatMessageData({
    required this.fromVet,
    required this.timeLabel,
    required this.text,
    this.title,
    this.icon,
    this.tint,
  });

  final bool fromVet;
  final String timeLabel;
  final String text;
  final String? title;
  final IconData? icon;
  final Color? tint;
}

class _VetData {
  const _VetData({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.online,
  });

  final String id;
  final String name;
  final String specialty;
  final String rating;
  final bool online;
}

class _HistoryData {
  const _HistoryData({
    required this.date,
    required this.title,
    required this.result,
    required this.urgency,
  });

  final String date;
  final String title;
  final String result;
  final String urgency;
}

class _AccessoryData {
  const _AccessoryData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unlocked,
  });

  final String id;
  final String name;
  final String emoji;
  final bool unlocked;
}
