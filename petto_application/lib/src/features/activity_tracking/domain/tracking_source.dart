import '../../../core/services/location_service.dart';

/// One position sample from ANY tracking hardware (phone GPS, BLE collar...).
class TrackingSample {
  final double lat;
  final double lng;

  /// Speed in m/s; 0 when the device can't report speed.
  final double speedMps;
  final DateTime timestamp;

  const TrackingSample({
    required this.lat,
    required this.lng,
    this.speedMps = 0,
    required this.timestamp,
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
/// Structure-only stub: pairing metadata lives on the backend (devices table,
/// /pets/{id}/devices) and collar telemetry is ingested server-side via
/// /devices/{id}/telemetry. Live BLE streaming into the app (flutter_blue_plus
/// scan -> GATT notifications -> TrackingSample) is the Progress II work item.
class BleCollarTrackingSource implements TrackingSource {
  final int deviceId;

  BleCollarTrackingSource({required this.deviceId});

  @override
  String get sourceType => 'device';

  @override
  Future<String?> prepare() async =>
      'No GPS/BLE device detected. Please ensure your pet\'s collar is paired.';

  @override
  Future<TrackingSample?> current() async => null;

  @override
  Stream<TrackingSample> samples() => const Stream.empty();
}
