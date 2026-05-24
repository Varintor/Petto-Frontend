import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` for the Mode A (phone) walk tracking.
///
/// Keeps GPS concerns out of the controller: permission handling, a continuous
/// position stream, and a distance helper. No Google Maps dependency - the
/// route is drawn from raw lat/lng points by a CustomPainter.
class LocationService {
  /// Result of a permission/service check, so the UI can show the right hint.
  Future<LocationReadiness> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationReadiness.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationReadiness.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationReadiness.deniedForever;
    }
    return LocationReadiness.ready;
  }

  /// Continuous position updates while walking.
  ///
  /// [distanceFilter] is the minimum movement (metres) before a new event is
  /// emitted - filters out GPS jitter when standing still.
  Stream<Position> positionStream({int distanceFilter = 5}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );
    } catch (_) {
      return null;
    }
  }

  /// Distance in metres between two coordinates (Haversine via geolocator).
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Opens the OS location settings (e.g. when permanently denied).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

enum LocationReadiness {
  ready,
  serviceDisabled,
  denied,
  deniedForever,
}
