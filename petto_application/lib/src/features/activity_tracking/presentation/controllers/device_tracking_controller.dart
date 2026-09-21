import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/device_repository.dart';
import '../../data/services/ble_gps_service.dart';
import '../../data/services/device_realtime_service.dart';

class DeviceTrackingController extends ChangeNotifier {
  DeviceTrackingController({
    required this.repository,
    DeviceRealtimeService? realtime,
    BleGpsService? ble,
  }) : realtime = realtime ?? DeviceRealtimeService(),
       ble = ble ?? BleGpsService();

  final DeviceRepository repository;
  final DeviceRealtimeService realtime;
  final BleGpsService ble;
  int? _petId;
  List<DeviceModel> _devices = [];
  bool _loading = false;
  String? _error;
  List<String> _alerts = [];
  List<DeviceAlertModel> _deviceAlerts = [];
  List<DeviceTelemetryPointModel> _history = [];
  MotionSummaryModel _summary = MotionSummaryModel.empty;
  List<BleDeviceCandidate> _bleCandidates = [];
  StreamSubscription<BleGpsPacket>? _bleSubscription;
  Timer? _uploadTimer;
  Timer? _summaryRefreshTimer;
  final List<BleGpsPacket> _pendingPackets = [];
  bool _scanning = false;
  bool _uploadingTelemetry = false;
  String? _connectedBleId;

  List<DeviceModel> get devices => List.unmodifiable(_devices);
  bool get loading => _loading;
  String? get error => _error;
  List<String> get alerts => List.unmodifiable(_alerts);
  List<DeviceAlertModel> get deviceAlerts => List.unmodifiable(_deviceAlerts);
  List<DeviceTelemetryPointModel> get history => List.unmodifiable(_history);
  MotionSummaryModel get summary => _summary;
  List<BleDeviceCandidate> get bleCandidates =>
      List.unmodifiable(_bleCandidates);
  bool get scanning => _scanning;
  bool get bleConnected => _connectedBleId != null && ble.connected;
  DeviceModel? get activeDevice => _devices.isEmpty ? null : _devices.first;

  Future<void> retry() async {
    final petId = _petId;
    if (petId != null) await load(petId);
  }

  Future<void> load(int petId) async {
    _petId = petId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final devices = await repository.listDevices(petId);
      final details = await _details(petId, devices);
      if (_petId == petId) {
        _devices = devices;
        _deviceAlerts = details.$1;
        _history = details.$2;
        _summary = details.$3;
      }
      if (_petId == petId) await _subscribe(petId, devices);
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _reconcile(int petId) async {
    if (_petId != petId) return;
    final devices = await repository.listDevices(petId);
    final details = await _details(petId, devices);
    if (_petId != petId) return;
    _devices = devices;
    _deviceAlerts = details.$1;
    _history = details.$2;
    _summary = details.$3;
    notifyListeners();
  }

  Future<
    (
      List<DeviceAlertModel>,
      List<DeviceTelemetryPointModel>,
      MotionSummaryModel,
    )
  >
  _details(int petId, List<DeviceModel> devices) async {
    if (devices.isEmpty) {
      return (
        await repository.listAlerts(petId),
        const <DeviceTelemetryPointModel>[],
        MotionSummaryModel.empty,
      );
    }
    final id = devices.first.id;
    final result = await Future.wait<dynamic>([
      repository.listAlerts(petId),
      repository.telemetryHistory(id),
      repository.motionSummary(id),
    ]);
    return (
      result[0] as List<DeviceAlertModel>,
      result[1] as List<DeviceTelemetryPointModel>,
      result[2] as MotionSummaryModel,
    );
  }

  Future<void> _subscribe(int petId, List<DeviceModel> devices) =>
      realtime.subscribe(
        petId: petId,
        deviceIds: devices.map((device) => device.id).toList(),
        reconcile: () => _reconcile(petId),
        onDevice: _applyRealtimeDevice,
        onAlert: _applyRealtimeAlert,
        onTelemetry: _applyRealtimeTelemetry,
      );

  void _applyRealtimeDevice(Map<String, dynamic> json) {
    final device = DeviceModel.fromJson(json);
    _devices = [device, ..._devices.where((item) => item.id != device.id)];
    notifyListeners();
  }

  void _applyRealtimeAlert(Map<String, dynamic> json) {
    final alert = DeviceAlertModel.fromJson(json);
    _deviceAlerts = [
      alert,
      ..._deviceAlerts.where((item) => item.id != alert.id),
    ];
    notifyListeners();
  }

  void _applyRealtimeTelemetry(Map<String, dynamic> json) {
    final point = DeviceTelemetryPointModel.fromJson(json);
    _history = [..._history.where((item) => item.id != point.id), point];
    if (_history.length > 300) {
      _history = _history.sublist(_history.length - 300);
    }
    _summaryRefreshTimer?.cancel();
    _summaryRefreshTimer = Timer(const Duration(seconds: 2), () async {
      if (_petId == null || activeDevice == null) return;
      try {
        _summary = await repository.motionSummary(activeDevice!.id);
        notifyListeners();
      } catch (_) {
        // Keep the last valid summary; live location can continue independently.
      }
    });
    notifyListeners();
  }

  Future<void> scanBleDevices() async {
    if (_scanning) return;
    _scanning = true;
    _error = null;
    notifyListeners();
    try {
      _bleCandidates = await ble.scan();
      if (_bleCandidates.isEmpty) {
        _error = 'No BLE devices found. Ensure the collar is advertising.';
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectBle(int petId, BleDeviceCandidate candidate) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _bleSubscription?.cancel();
      _bleSubscription = ble.packets.listen(
        _queueBlePacket,
        onError: (Object error) {
          _error = 'Invalid collar telemetry: $error';
          notifyListeners();
        },
      );
      await ble.connect(candidate.id);
      DeviceModel? paired;
      for (final item in _devices) {
        if (item.identifier == candidate.id) {
          paired = item;
          break;
        }
      }
      final stored =
          paired ??
          await repository.pairDevice(
            petId: petId,
            name: candidate.name,
            identifier: candidate.id,
          );
      _petId = petId;
      _connectedBleId = candidate.id;
      _devices = [stored, ..._devices.where((item) => item.id != stored.id)];
      try {
        await _subscribe(petId, _devices);
      } catch (_) {
        // Pairing remains usable when Realtime is temporarily unavailable;
        // the live screen can still reconcile through explicit reloads.
      }
      return true;
    } catch (error) {
      await ble.disconnect();
      _connectedBleId = null;
      _error = error.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _queueBlePacket(BleGpsPacket packet) {
    _pendingPackets.add(packet);
    _uploadTimer ??= Timer(const Duration(seconds: 2), _flushBlePackets);
  }

  Future<void> _flushBlePackets() async {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    final device = activeDevice;
    if (device == null || _pendingPackets.isEmpty || _uploadingTelemetry) {
      return;
    }
    final batch = List<BleGpsPacket>.from(_pendingPackets);
    _pendingPackets.clear();
    _uploadingTelemetry = true;
    try {
      final result = await repository.ingestTelemetry(
        deviceId: device.id,
        samples: batch.map((packet) => packet.toTelemetryJson()).toList(),
        batteryPercent: batch.last.batteryPercent,
      );
      _devices = [
        result.device,
        ..._devices.where((item) => item.id != result.device.id),
      ];
      _alerts = result.anomalies;
    } catch (error) {
      _pendingPackets.insertAll(0, batch);
      _error = 'Could not upload collar telemetry: $error';
    } finally {
      _uploadingTelemetry = false;
      if (_pendingPackets.isNotEmpty) {
        _uploadTimer = Timer(const Duration(seconds: 2), _flushBlePackets);
      }
      notifyListeners();
    }
  }

  Future<void> disconnectBle() async {
    await _flushBlePackets();
    await _bleSubscription?.cancel();
    _bleSubscription = null;
    await ble.disconnect();
    _connectedBleId = null;
    notifyListeners();
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
      try {
        await _subscribe(petId, _devices);
      } catch (_) {
        // The backend pairing succeeded; don't roll it back solely because
        // the optional Realtime channel could not join.
      }
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
          if (anomaly) {'lat': 18.797200, 'lng': 98.962500, 'speed_kmh': 61.0},
        ],
        batteryPercent: anomaly ? 18 : 82,
        sessionDurationMinutes: anomaly ? null : 18,
        sessionDistanceMeters: anomaly ? null : 1100,
        sessionId: anomaly
            ? null
            : 'demo-${device.id}-${DateTime.now().millisecondsSinceEpoch}',
      );
      _devices = [
        result.device,
        ..._devices.where((item) => item.id != result.device.id),
      ];
      _alerts = result.anomalies;
      if (_petId != null) _deviceAlerts = await repository.listAlerts(_petId!);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledge(int alertId) async {
    final updated = await repository.acknowledgeAlert(alertId);
    final index = _deviceAlerts.indexWhere((a) => a.id == alertId);
    if (index >= 0) _deviceAlerts[index] = updated;
    notifyListeners();
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
      _history = [];
      _summary = MotionSummaryModel.empty;
      await disconnectBle();
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
    realtime.close();
    disconnectBle();
    _petId = null;
    _devices = [];
    _alerts = [];
    _deviceAlerts = [];
    _history = [];
    _summary = MotionSummaryModel.empty;
    _bleCandidates = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _summaryRefreshTimer?.cancel();
    realtime.close();
    _bleSubscription?.cancel();
    ble.dispose();
    super.dispose();
  }
}
