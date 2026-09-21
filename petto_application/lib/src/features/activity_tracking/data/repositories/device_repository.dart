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
  final double? lastSpeedKmh;
  final double? lastAccuracyM;
  final DateTime? lastMovedAt;
  final String motionState;

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
    this.lastSpeedKmh,
    this.lastAccuracyM,
    this.lastMovedAt,
    this.motionState = 'unknown',
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
    lastSpeedKmh: (json['last_speed_kmh'] as num?)?.toDouble(),
    lastAccuracyM: (json['last_accuracy_m'] as num?)?.toDouble(),
    lastMovedAt: json['last_moved_at'] == null
        ? null
        : DateTime.tryParse(json['last_moved_at'] as String),
    motionState: json['motion_state'] as String? ?? 'unknown',
  );
}

class DeviceAlertModel {
  const DeviceAlertModel({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.message,
    required this.detectedAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });
  final int id, deviceId;
  final String type, severity, message;
  final DateTime detectedAt;
  final DateTime? acknowledgedAt, resolvedAt;
  factory DeviceAlertModel.fromJson(Map<String, dynamic> json) =>
      DeviceAlertModel(
        id: json['id'] as int,
        deviceId: json['device_id'] as int,
        type: json['alert_type'] as String,
        severity: json['severity'] as String,
        message: json['message'] as String,
        detectedAt: DateTime.parse(json['detected_at'] as String),
        acknowledgedAt: json['acknowledged_at'] == null
            ? null
            : DateTime.parse(json['acknowledged_at'] as String),
        resolvedAt: json['resolved_at'] == null
            ? null
            : DateTime.parse(json['resolved_at'] as String),
      );
}

class DeviceTelemetryPointModel {
  const DeviceTelemetryPointModel({
    required this.id,
    required this.deviceId,
    required this.lat,
    required this.lng,
    required this.motionState,
    required this.recordedAt,
    this.speedKmh,
    this.accuracyM,
  });

  final int id;
  final int deviceId;
  final double lat;
  final double lng;
  final double? speedKmh;
  final double? accuracyM;
  final String motionState;
  final DateTime recordedAt;

  factory DeviceTelemetryPointModel.fromJson(Map<String, dynamic> json) =>
      DeviceTelemetryPointModel(
        id: json['id'] as int,
        deviceId: json['device_id'] as int,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
        accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
        motionState: json['motion_state'] as String? ?? 'unknown',
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}

class MotionSummaryModel {
  const MotionSummaryModel({
    required this.sampleCount,
    required this.movingMinutes,
    required this.stationaryMinutes,
    required this.distanceMeters,
    required this.averageSpeedKmh,
    required this.maximumSpeedKmh,
    required this.trend,
    required this.windowHours,
  });

  final int sampleCount;
  final double movingMinutes;
  final double stationaryMinutes;
  final double distanceMeters;
  final double averageSpeedKmh;
  final double maximumSpeedKmh;
  final String trend;
  final int windowHours;

  factory MotionSummaryModel.fromJson(Map<String, dynamic> json) =>
      MotionSummaryModel(
        sampleCount: json['sample_count'] as int? ?? 0,
        movingMinutes: (json['moving_minutes'] as num? ?? 0).toDouble(),
        stationaryMinutes: (json['stationary_minutes'] as num? ?? 0).toDouble(),
        distanceMeters: (json['distance_meters'] as num? ?? 0).toDouble(),
        averageSpeedKmh: (json['average_speed_kmh'] as num? ?? 0).toDouble(),
        maximumSpeedKmh: (json['maximum_speed_kmh'] as num? ?? 0).toDouble(),
        trend: json['trend'] as String? ?? 'insufficient_data',
        windowHours: json['window_hours'] as int? ?? 24,
      );

  static const empty = MotionSummaryModel(
    sampleCount: 0,
    movingMinutes: 0,
    stationaryMinutes: 0,
    distanceMeters: 0,
    averageSpeedKmh: 0,
    maximumSpeedKmh: 0,
    trend: 'insufficient_data',
    windowHours: 24,
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
  Future<List<DeviceAlertModel>> listAlerts(int petId);
  Future<DeviceAlertModel> acknowledgeAlert(int alertId);
  Future<List<DeviceTelemetryPointModel>> telemetryHistory(
    int deviceId, {
    int minutes = 60,
  });
  Future<MotionSummaryModel> motionSummary(int deviceId, {int hours = 24});
  Future<TelemetryResultModel> ingestTelemetry({
    required int deviceId,
    required List<Map<String, dynamic>> samples,
    int? batteryPercent,
    double? sessionDurationMinutes,
    double? sessionDistanceMeters,
    String? sessionId,
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
  Future<List<DeviceAlertModel>> listAlerts(int petId) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/device-alerts',
    );
    return (response.data as List)
        .map(
          (e) => DeviceAlertModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<DeviceAlertModel> acknowledgeAlert(int alertId) async {
    final response = await dio.post(
      '${AppConfig.apiPrefix}/device-alerts/$alertId/acknowledge',
    );
    return DeviceAlertModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<DeviceTelemetryPointModel>> telemetryHistory(
    int deviceId, {
    int minutes = 60,
  }) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/devices/$deviceId/telemetry-history',
      queryParameters: {'minutes': minutes},
    );
    return (response.data as List<dynamic>)
        .map(
          (json) => DeviceTelemetryPointModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  @override
  Future<MotionSummaryModel> motionSummary(
    int deviceId, {
    int hours = 24,
  }) async {
    final response = await dio.get(
      '${AppConfig.apiPrefix}/devices/$deviceId/motion-summary',
      queryParameters: {'hours': hours},
    );
    return MotionSummaryModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<TelemetryResultModel> ingestTelemetry({
    required int deviceId,
    required List<Map<String, dynamic>> samples,
    int? batteryPercent,
    double? sessionDurationMinutes,
    double? sessionDistanceMeters,
    String? sessionId,
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
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return TelemetryResultModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
