import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Default Petto prototype GATT contract. A future collar can keep this
/// protocol or provide different UUIDs through [connect].
const pettoTrackingServiceUuid = 'f0a00001-0451-4000-b000-000000000001';
const pettoTelemetryCharacteristicUuid = 'f0a00002-0451-4000-b000-000000000001';

class BleDeviceCandidate {
  const BleDeviceCandidate({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;
}

class BleGpsPacket {
  const BleGpsPacket({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speedKmh,
    this.accuracyM,
    this.batteryPercent,
  });

  final double lat;
  final double lng;
  final double? speedKmh;
  final double? accuracyM;
  final int? batteryPercent;
  final DateTime recordedAt;

  Map<String, dynamic> toTelemetryJson() => {
    'lat': lat,
    'lng': lng,
    if (speedKmh != null) 'speed_kmh': speedKmh,
    if (accuracyM != null) 'accuracy_m': accuracyM,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };

  /// Petto prototype packets are UTF-8 JSON notifications:
  /// {"lat":18.79,"lng":98.96,"speed_kmh":4.2,"accuracy_m":8,
  ///  "battery":80,"recorded_at":"2026-09-21T10:00:00Z"}
  static BleGpsPacket parse(List<int> bytes) {
    final value = jsonDecode(utf8.decode(bytes).trim());
    if (value is! Map) throw const FormatException('BLE packet is not JSON');
    final json = Map<String, dynamic>.from(value);
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      throw const FormatException('BLE packet has invalid coordinates');
    }
    final recordedAt = json['recorded_at'] == null
        ? DateTime.now().toUtc()
        : DateTime.parse(json['recorded_at'] as String).toUtc();
    return BleGpsPacket(
      lat: lat,
      lng: lng,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      batteryPercent: (json['battery'] as num?)?.round(),
      recordedAt: recordedAt,
    );
  }
}

/// Owns the native BLE lifecycle: scan -> connect -> service discovery ->
/// GATT notifications. Backend persistence stays in DeviceRepository.
class BleGpsService {
  final StreamController<BleGpsPacket> _packets =
      StreamController<BleGpsPacket>.broadcast();
  StreamSubscription<List<int>>? _valueSubscription;
  BluetoothDevice? _device;
  BleGpsPacket? _latest;

  Stream<BleGpsPacket> get packets => _packets.stream;
  BleGpsPacket? get latest => _latest;
  bool get connected => _device?.isConnected ?? false;

  Future<String?> ensureReady() async {
    if (!await FlutterBluePlus.isSupported) {
      return 'Bluetooth Low Energy is not supported on this device.';
    }
    final state = await FlutterBluePlus.adapterState
        .where((value) => value != BluetoothAdapterState.unknown)
        .first;
    if (state != BluetoothAdapterState.on) {
      return 'Turn on Bluetooth and allow Nearby Devices access.';
    }
    return null;
  }

  Future<List<BleDeviceCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final readiness = await ensureReady();
    if (readiness != null) throw StateError(readiness);
    final found = <String, BleDeviceCandidate>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName.trim().isNotEmpty
            ? result.advertisementData.advName.trim()
            : result.device.platformName.trim();
        found[result.device.remoteId.str] = BleDeviceCandidate(
          id: result.device.remoteId.str,
          name: name.isEmpty
              ? 'BLE device ${result.device.remoteId.str}'
              : name,
          rssi: result.rssi,
        );
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((value) => !value).first;
    } finally {
      await subscription.cancel();
    }
    final devices = found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return devices;
  }

  Future<void> connect(
    String remoteId, {
    String serviceUuid = pettoTrackingServiceUuid,
    String characteristicUuid = pettoTelemetryCharacteristicUuid,
  }) async {
    await disconnect();
    final readiness = await ensureReady();
    if (readiness != null) throw StateError(readiness);
    final device = BluetoothDevice.fromId(remoteId);
    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 15),
    );
    final services = await device.discoverServices();
    BluetoothCharacteristic? telemetry;
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() != serviceUuid.toLowerCase()) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            characteristicUuid.toLowerCase()) {
          telemetry = characteristic;
          break;
        }
      }
    }
    if (telemetry == null ||
        (!telemetry.properties.notify && !telemetry.properties.indicate)) {
      await device.disconnect();
      throw StateError('The device does not expose the Petto GPS service.');
    }
    _device = device;
    _valueSubscription = telemetry.onValueReceived.listen((bytes) {
      try {
        final packet = BleGpsPacket.parse(bytes);
        _latest = packet;
        _packets.add(packet);
      } on FormatException catch (error) {
        _packets.addError(error);
      }
    });
    device.cancelWhenDisconnected(_valueSubscription!);
    await telemetry.setNotifyValue(true);
  }

  Future<void> disconnect() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;
    final device = _device;
    _device = null;
    if (device != null && device.isConnected) await device.disconnect();
  }

  Future<void> dispose() async {
    await disconnect();
    await _packets.close();
  }
}
