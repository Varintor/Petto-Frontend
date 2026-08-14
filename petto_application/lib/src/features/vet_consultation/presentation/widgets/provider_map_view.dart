import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';

class ProviderMapView extends StatelessWidget {
  const ProviderMapView({
    super.key,
    required this.providers,
    required this.onProviderTap,
    this.userLatitude,
    this.userLongitude,
    this.loadTiles = true,
  });

  final List<VeterinaryProviderModel> providers;
  final ValueChanged<VeterinaryProviderModel> onProviderTap;
  final double? userLatitude;
  final double? userLongitude;
  final bool loadTiles;

  List<VeterinaryProviderModel> get _locatedProviders => providers
      .where(
        (provider) => provider.latitude != null && provider.longitude != null,
      )
      .toList(growable: false);

  LatLng get _initialCenter {
    if (userLatitude != null && userLongitude != null) {
      return LatLng(userLatitude!, userLongitude!);
    }
    final located = _locatedProviders;
    if (located.isEmpty) return const LatLng(18.7883, 98.9853);
    final latitude =
        located.fold<double>(0, (sum, provider) => sum + provider.latitude!) /
        located.length;
    final longitude =
        located.fold<double>(0, (sum, provider) => sum + provider.longitude!) /
        located.length;
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final located = _locatedProviders;
    if (located.isEmpty) {
      return const Center(child: Text('No provider location is available.'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: userLatitude == null ? 10.5 : 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (loadTiles)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petto.app',
                ),
              MarkerLayer(
                markers: [
                  for (final provider in located)
                    Marker(
                      point: LatLng(provider.latitude!, provider.longitude!),
                      width: 52,
                      height: 52,
                      child: Semantics(
                        button: true,
                        label: provider.name,
                        child: GestureDetector(
                          onTap: () => onProviderTap(provider),
                          child: _ProviderMarker(
                            consultationEnabled: provider.consultationEnabled,
                          ),
                        ),
                      ),
                    ),
                  if (userLatitude != null && userLongitude != null)
                    Marker(
                      point: LatLng(userLatitude!, userLongitude!),
                      width: 28,
                      height: 28,
                      child: const _UserMarker(),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderMarker extends StatelessWidget {
  const _ProviderMarker({required this.consultationEnabled});

  final bool consultationEnabled;

  @override
  Widget build(BuildContext context) {
    final color = consultationEnabled ? AppTheme.primaryColor : Colors.blueGrey;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 7, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
    );
  }
}
