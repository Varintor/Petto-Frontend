import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/features/activity_tracking/data/services/ble_gps_service.dart';

void main() {
  test('parses the Petto BLE GPS JSON packet', () {
    final packet = BleGpsPacket.parse(
      utf8.encode(
        '{"lat":18.796,"lng":98.961,"speed_kmh":4.2,'
        '"accuracy_m":7.5,"battery":82,'
        '"recorded_at":"2026-09-21T10:00:00Z"}',
      ),
    );

    expect(packet.lat, 18.796);
    expect(packet.lng, 98.961);
    expect(packet.speedKmh, 4.2);
    expect(packet.accuracyM, 7.5);
    expect(packet.batteryPercent, 82);
    expect(packet.recordedAt, DateTime.utc(2026, 9, 21, 10));
  });

  test('rejects a BLE packet with invalid coordinates', () {
    expect(
      () => BleGpsPacket.parse(utf8.encode('{"lat":181,"lng":98}')),
      throwsFormatException,
    );
  });
}
