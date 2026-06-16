import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/activity_tracking_controller.dart';

/// Live OpenStreetMap view for the walk session.
///
/// Centers on the current GPS location and keeps following it in realtime,
/// drawing the route travelled so far as a polyline. Uses free OSM tiles, so no
/// Maps API key is required (swap [TileLayer] for `google_maps_flutter` later
/// if the proposal's Google Maps is needed).
class WalkMapView extends StatefulWidget {
  const WalkMapView({
    super.key,
    required this.points,
    required this.current,
    this.follow = true,
  });

  /// Route travelled so far (oldest → newest).
  final List<GeoPoint> points;

  /// Latest known location. Null until the first GPS fix arrives.
  final GeoPoint? current;

  /// Keep recentering the camera on [current] as it updates.
  final bool follow;

  @override
  State<WalkMapView> createState() => _WalkMapViewState();
}

class _WalkMapViewState extends State<WalkMapView> {
  final MapController _map = MapController();
  double _zoom = 17;
  bool _ready = false;

  LatLng? get _current => widget.current == null
      ? null
      : LatLng(widget.current!.lat, widget.current!.lng);

  @override
  void didUpdateWidget(covariant WalkMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _current;
    if (widget.follow && c != null && _ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _map.move(c, _zoom);
        } catch (_) {
          // Map not attached yet — initialCenter already handled it.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    if (current == null) return _locating();

    final route = [for (final p in widget.points) LatLng(p.lat, p.lng)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: current,
              initialZoom: _zoom,
              onMapReady: () => _ready = true,
              onPositionChanged: (camera, _) => _zoom = camera.zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
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
              MarkerLayer(
                markers: [
                  Marker(
                    point: current,
                    width: 30,
                    height: 30,
                    child: _youDot(),
                  ),
                ],
              ),
            ],
          ),
          // Recenter button (in case the user panned away).
          Positioned(
            right: 12,
            bottom: 12,
            child: _recenterButton(current),
          ),
        ],
      ),
    );
  }

  Widget _recenterButton(LatLng current) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          try {
            _map.move(current, _zoom);
          } catch (_) {}
        },
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(
            Icons.my_location_rounded,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _youDot() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _locating() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: Colors.white.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 14),
            Text('Locating you…'),
          ],
        ),
      ),
    );
  }
}
