import '../../../core/services/location_service.dart';
import '../data/services/ble_gps_service.dart';

/// One position sample from ANY tracking hardware (phone GPS, BLE collar...).
class TrackingSample {
  final double lat;
  final double lng;

  /// Speed in m/s; 0 when the device can't report speed.
  final double speedMps;
  final DateTime timestamp;
  final double? accuracyM;
  final int? batteryPercent;

  const TrackingSample({
    required this.lat,
    required this.lng,
    this.speedMps = 0,
    required this.timestamp,
    this.accuracyM,
    this.batteryPercent,
  });
}

/// Device-agnostic tracking source (SRS-F4-035/036: BLE collar with manual
/// phone-GPS fallback). [ActivityTrackingController] consumes this interface
/// only, so adding new hardware never touches the walk state machine.
abstract class TrackingSource {
  /// 'phone' | 'device' — matches the backend activity_logs.source enum.
  String get sourceType;

  /// Prepare the hardware. Returns null when ready, or a user-facing error
  /// message ("Please turn on Location/GPS...") when tracking cannot start.
  Future<String?> prepare();

  /// Best-effort immediate fix so the map can center before movement.
  Future<TrackingSample?> current();

  /// Continuous samples while a session is running.
  Stream<TrackingSample> samples();
}

/// Mode A: the phone's own GPS via geolocator (default source).
class PhoneGpsTrackingSource implements TrackingSource {
  final LocationService locationService;

  PhoneGpsTrackingSource({LocationService? locationService})
    : locationService = locationService ?? LocationService();

  @override
  String get sourceType => 'phone';

  @override
  Future<String?> prepare() async {
    final readiness = await locationService.ensureReady();
    switch (readiness) {
      case LocationReadiness.ready:
        return null;
      case LocationReadiness.serviceDisabled:
        return 'Please turn on Location/GPS before starting a walk.';
      case LocationReadiness.denied:
        return 'Location permission is required to record your walk.';
      case LocationReadiness.deniedForever:
        return 'Location access is disabled. Please enable it in app settings.';
    }
  }

  @override
  Future<TrackingSample?> current() async {
    final p = await locationService.currentPosition();
    if (p == null) return null;
    return TrackingSample(
      lat: p.latitude,
      lng: p.longitude,
      speedMps: p.speed.isFinite && p.speed > 0 ? p.speed : 0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<TrackingSample> samples() => locationService.positionStream().map(
    (p) => TrackingSample(
      lat: p.latitude,
      lng: p.longitude,
      speedMps: p.speed.isFinite && p.speed > 0 ? p.speed : 0,
      timestamp: DateTime.now(),
    ),
  );
}

/// Mode B: BLE/GPS collar (SRS-F4-035, Progress II).
///
/// BLE/GPS collar source backed by GATT notifications. It uses the Petto JSON
/// packet contract while allowing the service/characteristic UUIDs to be
/// replaced when the final hardware is selected.
class BleCollarTrackingSource implements TrackingSource {
  final int deviceId;
  final String remoteId;
  final BleGpsService service;
  final String serviceUuid;
  final String characteristicUuid;

  BleCollarTrackingSource({
    required this.deviceId,
    required this.remoteId,
    BleGpsService? service,
    this.serviceUuid = pettoTrackingServiceUuid,
    this.characteristicUuid = pettoTelemetryCharacteristicUuid,
  }) : service = service ?? BleGpsService();

  @override
  String get sourceType => 'device';

  @override
  Future<String?> prepare() async {
    try {
      await service.connect(
        remoteId,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      return null;
    } catch (error) {
      return 'Could not connect to the GPS collar: $error';
    }
  }

  @override
  Future<TrackingSample?> current() async {
    final packet = service.latest;
    return packet == null ? null : _sample(packet);
  }

  @override
  Stream<TrackingSample> samples() => service.packets.map(_sample);

  TrackingSample _sample(BleGpsPacket packet) => TrackingSample(
    lat: packet.lat,
    lng: packet.lng,
    speedMps: (packet.speedKmh ?? 0) / 3.6,
    timestamp: packet.recordedAt,
    accuracyM: packet.accuracyM,
    batteryPercent: packet.batteryPercent,
  );
}
