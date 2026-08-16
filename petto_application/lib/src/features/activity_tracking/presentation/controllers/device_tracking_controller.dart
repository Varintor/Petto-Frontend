import 'package:flutter/foundation.dart';

import '../../data/repositories/device_repository.dart';

class DeviceTrackingController extends ChangeNotifier {
  DeviceTrackingController({required this.repository});

  final DeviceRepository repository;
  int? _petId;
  List<DeviceModel> _devices = [];
  bool _loading = false;
  String? _error;
  List<String> _alerts = [];

  List<DeviceModel> get devices => List.unmodifiable(_devices);
  bool get loading => _loading;
  String? get error => _error;
  List<String> get alerts => List.unmodifiable(_alerts);
  DeviceModel? get activeDevice => _devices.isEmpty ? null : _devices.first;

  Future<void> load(int petId) async {
    _petId = petId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final devices = await repository.listDevices(petId);
      if (_petId == petId) _devices = devices;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> pairDemo(int petId) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final device = await repository.pairDevice(
        petId: petId,
        name: 'Petto Demo GPS Collar',
        identifier: 'PETTO-DEMO-$petId',
      );
      _petId = petId;
      _devices = [device, ..._devices.where((item) => item.id != device.id)];
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> simulateTelemetry({bool anomaly = false}) async {
    final device = activeDevice;
    if (device == null || _loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await repository.ingestTelemetry(
        deviceId: device.id,
        samples: [
          {
            'lat': 18.796263,
            'lng': 98.961291,
            'speed_kmh': anomaly ? 60.0 : 4.2,
          },
          {
            'lat': 18.796820,
            'lng': 98.962010,
            'speed_kmh': anomaly ? 62.0 : 5.1,
          },
        ],
        batteryPercent: anomaly ? 18 : 82,
        sessionDurationMinutes: anomaly ? null : 18,
        sessionDistanceMeters: anomaly ? null : 1100,
      );
      _devices = [
        result.device,
        ..._devices.where((item) => item.id != result.device.id),
      ];
      _alerts = result.anomalies;
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> unpair() async {
    final device = activeDevice;
    if (device == null || _loading) return false;
    _loading = true;
    notifyListeners();
    try {
      await repository.unpairDevice(device.id);
      _devices = _devices.where((item) => item.id != device.id).toList();
      _alerts = [];
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearForAccount() {
    _petId = null;
    _devices = [];
    _alerts = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
