import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications so the rest of the app stays
/// platform-agnostic. Web is a no-op (the package has no real web backend) —
/// every method logs a debug line so we can still see what *would* fire during
/// dev, but the in-app banners (showTopAlert) are the actual web feedback.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _notificationPermissionRequested = false;
  bool _exactAlarmPermissionRequested = false;
  bool get supported => !kIsWeb;

  // Stable ids so re-scheduling overwrites old reminders instead of stacking.
  static const int dailyMissionMorningId = 9001;
  static const int dailyMissionEveningId = 9002;

  /// Calendar event ids are derived from a stable hash of the event id so
  /// editing/deleting can find the matching scheduled notification.
  int calendarEventId(String eventId) =>
      0x4000_0000 | (eventId.hashCode & 0x3FFF_FFFF);

  Future<void> init() async {
    if (_initialised || !supported) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      debugPrint('NotificationService: timezone lookup failed: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: macos),
    );

    _initialised = true;
  }

  /// Requests Android notification and exact-alarm permissions once per app
  /// session. If exact alarms are unavailable, callers use an inexact mode
  /// instead of failing to save the user's calendar event or reminders.
  Future<AndroidScheduleMode> _androidScheduleMode({
    required bool requestExact,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    try {
      if (!_notificationPermissionRequested) {
        _notificationPermissionRequested = true;
        await android.requestNotificationsPermission();
      }

      // Daily mission reminders tolerate the small delay Android may apply to
      // inexact alarms. Reserve the intrusive exact-alarm settings prompt for
      // a timed Calendar event where the 30-minute reminder matters.
      if (!requestExact) return AndroidScheduleMode.inexactAllowWhileIdle;

      var canScheduleExact =
          await android.canScheduleExactNotifications() ?? true;
      if (!canScheduleExact && !_exactAlarmPermissionRequested) {
        _exactAlarmPermissionRequested = true;
        await android.requestExactAlarmsPermission();
        canScheduleExact =
            await android.canScheduleExactNotifications() ?? false;
      }
      return canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } on PlatformException catch (error) {
      debugPrint('NotificationService: permission request failed: $error');
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Schedules (or re-schedules) the two daily mission reminders. Idempotent —
  /// safe to call on every app launch.
  Future<void> scheduleDailyMissionReminders({
    int morningHour = 9,
    int eveningHour = 19,
  }) async {
    if (!supported) {
      debugPrint(
        '[notif] would schedule daily missions ($morningHour:00 / $eveningHour:00)',
      );
      return;
    }
    await init();
    await _scheduleDaily(
      id: dailyMissionMorningId,
      hour: morningHour,
      title: 'Today\'s missions are ready',
      body: 'Tap to see what your pet can earn today.',
    );
    await _scheduleDaily(
      id: dailyMissionEveningId,
      hour: eveningHour,
      title: 'Don\'t miss tonight\'s missions',
      body: 'A few are still open — quick taps to keep the streak.',
    );
  }

  /// Schedules a one-off reminder some time before [event]. Cancels any
  /// existing reminder with the same id first so re-saving an event is safe.
  Future<void> scheduleEventReminder({
    required String eventId,
    required DateTime when,
    required String title,
    String? body,
    Duration leadTime = const Duration(minutes: 30),
  }) async {
    if (!supported) {
      debugPrint(
        '[notif] would schedule event "$title" at $when (lead $leadTime)',
      );
      return;
    }
    await init();
    final androidScheduleMode = await _androidScheduleMode(requestExact: true);
    final notifId = calendarEventId(eventId);
    await _plugin.cancel(notifId);

    final fireAt = tz.TZDateTime.from(when, tz.local).subtract(leadTime);
    // No point scheduling in the past.
    if (fireAt.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      notifId,
      title,
      body ?? 'Tap to open the calendar.',
      fireAt,
      _details(channelId: 'calendar', channelName: 'Calendar reminders'),
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    if (!supported) return;
    await init();
    await _plugin.cancel(calendarEventId(eventId));
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    final androidScheduleMode = await _androidScheduleMode(requestExact: false);
    final now = tz.TZDateTime.now(tz.local);
    var fireAt = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!fireAt.isAfter(now)) fireAt = fireAt.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireAt,
      _details(channelId: 'missions', channelName: 'Daily missions'),
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
