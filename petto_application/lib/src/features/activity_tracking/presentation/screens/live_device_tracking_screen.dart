import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/device_tracking_controller.dart';

class LiveDeviceTrackingScreen extends StatefulWidget {
  const LiveDeviceTrackingScreen({super.key});

  @override
  State<LiveDeviceTrackingScreen> createState() =>
      _LiveDeviceTrackingScreenState();
}

class _LiveDeviceTrackingScreenState extends State<LiveDeviceTrackingScreen> {
  final MapController _map = MapController();
  bool _follow = true;
  bool _mapReady = false;
  double _zoom = 16;
  LatLng? _lastPoint;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeviceTrackingController>();
    final device = controller.activeDevice;
    if (controller.loading && device == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (controller.error != null && device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live tracking')),
        body: Center(
          child: FilledButton.icon(
            onPressed: controller.retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }
    if (device == null || device.lastLat == null || device.lastLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live pet tracking')),
        body: const Center(
          child: Text('Waiting for the first GPS location from the collar.'),
        ),
      );
    }

    final point = LatLng(device.lastLat!, device.lastLng!);
    final route = controller.history
        .map((sample) => LatLng(sample.lat, sample.lng))
        .toList();
    if (_follow && _mapReady && _lastPoint != point) {
      _lastPoint = point;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.move(point, _zoom);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live pet tracking'),
        actions: [
          IconButton(
            tooltip: _follow ? 'Stop following' : 'Follow pet',
            onPressed: () => setState(() => _follow = !_follow),
            icon: Icon(_follow ? Icons.gps_fixed : Icons.gps_not_fixed),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: point,
                initialZoom: _zoom,
                onMapReady: () => _mapReady = true,
                onPositionChanged: (camera, hasGesture) {
                  _zoom = camera.zoom;
                  if (hasGesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petto.app',
                ),
                if (route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route,
                        strokeWidth: 5,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                if (device.lastAccuracyM != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: point,
                        radius: device.lastAccuracyM!,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: .12),
                        borderColor: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: const [BoxShadow(blurRadius: 8)],
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _TrackingPanel(controller: controller),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _follow = true);
          _map.move(point, _zoom);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({required this.controller});
  final DeviceTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.activeDevice!;
    final summary = controller.summary;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: _motionIcon(device.motionState),
                  label: device.motionState.toUpperCase(),
                ),
                _StatusChip(
                  icon: Icons.speed,
                  label:
                      '${device.lastSpeedKmh?.toStringAsFixed(1) ?? '--'} km/h',
                ),
                _StatusChip(
                  icon: Icons.battery_5_bar,
                  label: '${device.batteryPercent ?? '--'}%',
                ),
                _StatusChip(
                  icon: controller.bleConnected
                      ? Icons.bluetooth_connected
                      : Icons.cloud_done,
                  label: controller.bleConnected ? 'BLE LIVE' : 'CLOUD LIVE',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Last seen ${_lastSeen(device.lastSeenAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TrendValue(
                    value: '${summary.movingMinutes.toStringAsFixed(0)} min',
                    label: 'Moving',
                  ),
                ),
                Expanded(
                  child: _TrendValue(
                    value:
                        '${summary.stationaryMinutes.toStringAsFixed(0)} min',
                    label: 'Stationary',
                  ),
                ),
                Expanded(
                  child: _TrendValue(
                    value: _trendLabel(summary.trend),
                    label: '24h trend',
                  ),
                ),
              ],
            ),
            if (controller.deviceAlerts.isNotEmpty) ...[
              const Divider(height: 20),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.deviceAlerts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final alert = controller.deviceAlerts[index];
                    return ActionChip(
                      avatar: const Icon(Icons.warning_amber, size: 18),
                      label: Text(alert.message),
                      onPressed: alert.acknowledgedAt == null
                          ? () => controller.acknowledge(alert.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _motionIcon(String state) => switch (state) {
    'moving' => Icons.directions_run,
    'stationary' => Icons.pause_circle,
    'offline' => Icons.cloud_off,
    _ => Icons.help_outline,
  };

  static String _lastSeen(DateTime? value) {
    if (value == null) return 'never';
    final delta = DateTime.now().difference(value.toLocal());
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    return '${delta.inHours} h ago';
  }

  static String _trendLabel(String trend) => switch (trend) {
    'mostly_moving' => 'Active',
    'mostly_stationary' => 'Resting',
    'mixed' => 'Mixed',
    _ => 'Learning',
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _TrendValue extends StatelessWidget {
  const _TrendValue({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
