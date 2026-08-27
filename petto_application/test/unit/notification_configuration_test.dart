import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/core/services/notification_service.dart';

void main() {
  group('Notification platform configuration', () {
    test('Android declares scheduled reminder permissions and receivers', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
      expect(manifest, contains('ScheduledNotificationReceiver'));
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });

    test('calendar reminder ids are stable and separated from daily ids', () {
      final service = NotificationService.instance;
      final first = service.calendarEventId('calendar-event-42');

      expect(service.calendarEventId('calendar-event-42'), first);
      expect(
        first,
        isNot(
          anyOf(
            NotificationService.dailyMissionMorningId,
            NotificationService.dailyMissionEveningId,
          ),
        ),
      );
    });
  });
}
