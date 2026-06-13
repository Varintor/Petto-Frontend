part of 'home_screen.dart';

enum _View {
  dashboard,
  missions,
  calendar,
  wellness,
  consult,
  profile,
  wardrobe,
  history,
}

enum _VetFilter { all, online }

class _PetData {
  const _PetData({
    required this.name,
    required this.species,
    required this.breed,
    required this.ageLabel,
    required this.weightLabel,
    required this.status,
  });

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
    required this.day,
    required this.color,
    required this.icon,
  });

  final String id;
  final String title;
  final String timeLabel;
  final String type;
  final bool completed;
  final int day;
  final Color color;
  final IconData icon;
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
