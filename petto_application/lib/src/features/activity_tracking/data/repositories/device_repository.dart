import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';

/// Paired tracking device (BLE/GPS collar) as returned by the backend.
/// Only the LATEST position is kept server-side (live-map pin) — the raw
/// route is never persisted (proposal privacy rule).
class DeviceModel {
  final int id;
  final int petId;
  final String name;
  final String deviceType; // ble_collar
  final String identifier; // MAC / serial
  final bool isActive;
  final int? batteryPercent;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastSeenAt;

  DeviceModel({
    required this.id,
    required this.petId,
    required this.name,
    required this.deviceType,
    required this.identifier,
    required this.isActive,
    this.batteryPercent,
    this.lastLat,
    this.lastLng,
    this.lastSeenAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
    id: json['id'] as int,
    petId: json['pet_id'] as int,
    name: json['name'] as String,
    deviceType: json['device_type'] as String? ?? 'ble_collar',
    identifier: json['identifier'] as String,
    isActive: json['is_active'] as bool? ?? true,
    batteryPercent: json['battery_percent'] as int?,
    lastLat: (json['last_lat'] as num?)?.toDouble(),
    lastLng: (json['last_lng'] as num?)?.toDouble(),
    lastSeenAt: json['last_seen_at'] != null
        ? DateTime.tryParse(json['last_seen_at'] as String)
        : null,
  );
}

/// Pairing + live-position API for Mode B tracking (SRS-F4-035..038).
/// The actual BLE scan/GATT link (flutter_blue_plus) is the Progress II work
/// item; this repository already speaks the backend contract it will feed.
class TelemetryResultModel {
  const TelemetryResultModel({
    required this.device,
    required this.anomalies,
    required this.activityLogged,
  });

  final DeviceModel device;
  final List<String> anomalies;
  final bool activityLogged;

  factory TelemetryResultModel.fromJson(Map<String, dynamic> json) =>
      TelemetryResultModel(
        device: DeviceModel.fromJson(
          Map<String, dynamic>.from(json['device'] as Map),
        ),
        anomalies: (json['anomalies'] as List<dynamic>? ?? const [])
            .map((item) => (item as Map)['message'] as String? ?? 'Alert')
            .toList(),
        activityLogged: json['activity_logged'] as bool? ?? false,
      );
}

abstract class DeviceRepository {
  Future<List<DeviceModel>> listDevices(int petId);
  Future<DeviceModel> pairDevice({
    required int petId,
    required String name,
    required String identifier,
  });
  Future<void> unpairDevice(int deviceId);
  Future<TelemetryResultModel> ingestTelemetry({
    required int deviceId,
    required List<Map<String, dynamic>> samples,
    int? batteryPercent,
    double? sessionDurationMinutes,
    double? sessionDistanceMeters,
  });
}

class DeviceRepositoryImpl implements DeviceRepository {
  final Dio dio;

  DeviceRepositoryImpl({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<List<DeviceModel>> listDevices(int petId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/devices',
    );
    return (response.data as List<dynamic>)
        .map((j) => DeviceModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DeviceModel> pairDevice({
    required int petId,
    required String name,
    required String identifier,
  }) async {
    final response = await dio.post(
      '${AppConfig.apiPrefix}/pets/$petId/devices',
      data: {'name': name, 'identifier': identifier},
    );
    return DeviceModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> unpairDevice(int deviceId) async {
    await dio.delete('${AppConfig.apiPrefix}/devices/$deviceId');
  }

  @override
  Future<TelemetryResultModel> ingestTelemetry({
    required int deviceId,
    required List<Map<String, dynamic>> samples,
    int? batteryPercent,
    double? sessionDurationMinutes,
    double? sessionDistanceMeters,
  }) async {
    final response = await dio.post(
      '${AppConfig.apiPrefix}/devices/$deviceId/telemetry',
      data: {
        'samples': samples,
        if (batteryPercent != null) 'battery_percent': batteryPercent,
        if (sessionDurationMinutes != null)
          'session_duration_minutes': sessionDurationMinutes,
        if (sessionDistanceMeters != null)
          'session_distance_meters': sessionDistanceMeters,
      },
    );
    return TelemetryResultModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
