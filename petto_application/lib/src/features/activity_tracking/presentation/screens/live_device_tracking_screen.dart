import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/petto_transitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../controllers/device_tracking_controller.dart';

class LiveDeviceTrackingScreen extends StatelessWidget {
  const LiveDeviceTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeviceTrackingController>();
    final device = controller.activeDevice;
    if (controller.loading && device == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: PettoPageSkeleton(itemCount: 2),
      );
    }
    if (controller.error != null && device == null)
      return Scaffold(
        appBar: AppBar(title: const Text('Live tracking')),
        body: Center(
          child: FilledButton(onPressed: () {}, child: const Text('Retry')),
        ),
      );
    if (device == null || device.lastLat == null || device.lastLng == null)
      return const Scaffold(
        body: Center(child: Text('No live device location yet')),
      );
    final point = LatLng(device.lastLat!, device.lastLng!);
    return Scaffold(
      appBar: AppBar(title: const Text('Live pet tracking')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 16),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petto.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 52,
                      height: 52,
                      child: const Icon(
                        Icons.pets,
                        size: 42,
                        color: Colors.deepPurple,
                      ),
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
                        color: Colors.blue.withValues(alpha: .15),
                        borderColor: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${device.motionState.toUpperCase()} · Last seen ${device.lastSeenAt?.toLocal() ?? '--'}',
                ),
                Text(
                  'Speed ${device.lastSpeedKmh?.toStringAsFixed(1) ?? '--'} km/h · Battery ${device.batteryPercent ?? '--'}%',
                ),
                const SizedBox(height: 8),
                for (final alert in controller.deviceAlerts)
                  ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(alert.message),
                    subtitle: Text(alert.type),
                    trailing: alert.acknowledgedAt == null
                        ? TextButton(
                            onPressed: () => controller.acknowledge(alert.id),
                            child: const Text('Acknowledge'),
                          )
                        : const Icon(Icons.check),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          PettoPageRoute(builder: (_) => const LiveDeviceTrackingScreen()),
        ),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
