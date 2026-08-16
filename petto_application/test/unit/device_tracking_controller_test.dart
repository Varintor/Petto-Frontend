import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/activity_tracking/data/repositories/device_repository.dart';
import 'package:petto_application/src/features/activity_tracking/presentation/controllers/device_tracking_controller.dart';

class _FakeDeviceRepository implements DeviceRepository {
  DeviceModel? device;

  DeviceModel _device({int battery = 100, double? lat, double? lng}) =>
      DeviceModel(
        id: 4,
        petId: 9,
        name: 'Petto Demo GPS Collar',
        deviceType: 'ble_collar',
        identifier: 'PETTO-DEMO-9',
        isActive: true,
        batteryPercent: battery,
        lastLat: lat,
        lastLng: lng,
        lastSeenAt: lat == null ? null : DateTime(2026, 8, 16),
      );

  @override
  Future<List<DeviceModel>> listDevices(int petId) async => [
    if (device != null) device!,
  ];

  @override
  Future<DeviceModel> pairDevice({
    required int petId,
    required String name,
    required String identifier,
  }) async => device = _device();

  @override
  Future<TelemetryResultModel> ingestTelemetry({
    required int deviceId,
    required List<Map<String, dynamic>> samples,
    int? batteryPercent,
    double? sessionDurationMinutes,
    double? sessionDistanceMeters,
  }) async {
    final abnormal = (samples.first['speed_kmh'] as num) > 35;
    device = _device(
      battery: batteryPercent ?? 100,
      lat: (samples.last['lat'] as num).toDouble(),
      lng: (samples.last['lng'] as num).toDouble(),
    );
    return TelemetryResultModel(
      device: device!,
      anomalies: abnormal ? const ['Abnormal speed detected'] : const [],
      activityLogged: sessionDurationMinutes != null,
    );
  }

  @override
  Future<void> unpairDevice(int deviceId) async => device = null;
}

void main() {
  test(
    'simulated collar exercises pair, GPS, alert, and unpair flow',
    () async {
      final repository = _FakeDeviceRepository();
      final controller = DeviceTrackingController(repository: repository);

      expect(await controller.pairDemo(9), isTrue);
      expect(controller.activeDevice?.identifier, 'PETTO-DEMO-9');

      expect(await controller.simulateTelemetry(), isTrue);
      expect(controller.activeDevice?.lastLat, closeTo(18.79682, 0.00001));
      expect(controller.activeDevice?.batteryPercent, 82);
      expect(controller.alerts, isEmpty);

      expect(await controller.simulateTelemetry(anomaly: true), isTrue);
      expect(controller.alerts, ['Abnormal speed detected']);
      expect(controller.activeDevice?.batteryPercent, 18);

      expect(await controller.unpair(), isTrue);
      expect(controller.devices, isEmpty);
    },
  );
}
