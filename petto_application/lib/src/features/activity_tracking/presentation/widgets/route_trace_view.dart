import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/activity_tracking_controller.dart';

/// Draws the walked route from raw lat/lng points using a CustomPainter.
///
/// Deliberately avoids google_maps_flutter so Phase 0 works with zero API-key
/// setup. Points are normalised into the available canvas with a small padding.
class RouteTraceView extends StatelessWidget {
  const RouteTraceView({
    super.key,
    required this.points,
    this.showCurrent = true,
  });

  final List<GeoPoint> points;
  final bool showCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6F4), Color(0xFFF7FBFA)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppTheme.subtleShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: points.length < 2
          ? _EmptyTrace(hasFix: points.isNotEmpty)
          : CustomPaint(
              painter: _RoutePainter(points, showCurrent: showCurrent),
              size: Size.infinite,
            ),
    );
  }
}

class _EmptyTrace extends StatelessWidget {
  const _EmptyTrace({required this.hasFix});
  final bool hasFix;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFix ? Icons.my_location_rounded : Icons.gps_not_fixed_rounded,
            size: 40,
            color: AppTheme.secondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            hasFix ? 'Got your location...' : 'Waiting for GPS signal...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, {this.showCurrent = true});

  final List<GeoPoint> points;
  final bool showCurrent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minLat = points.first.lat, maxLat = points.first.lat;
    double minLng = points.first.lng, maxLng = points.first.lng;
    for (final p in points) {
      minLat = p.lat < minLat ? p.lat : minLat;
      maxLat = p.lat > maxLat ? p.lat : maxLat;
      minLng = p.lng < minLng ? p.lng : minLng;
      maxLng = p.lng > maxLng ? p.lng : maxLng;
    }

    const pad = 28.0;
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();
    final safeSpanLat = spanLat < 1e-6 ? 1e-6 : spanLat;
    final safeSpanLng = spanLng < 1e-6 ? 1e-6 : spanLng;

    // Keep aspect ratio roughly square so short walks don't look distorted.
    final usableW = size.width - pad * 2;
    final usableH = size.height - pad * 2;
    final scale = (usableW / safeSpanLng) < (usableH / safeSpanLat)
        ? usableW / safeSpanLng
        : usableH / safeSpanLat;

    final drawnW = safeSpanLng * scale;
    final drawnH = safeSpanLat * scale;
    final offsetX = (size.width - drawnW) / 2;
    final offsetY = (size.height - drawnH) / 2;

    Offset project(GeoPoint p) {
      final x = offsetX + (p.lng - minLng) * scale;
      // Flip Y: latitude increases northwards (upwards on screen).
      final y = offsetY + (maxLat - p.lat) * scale;
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(project(points.first).dx, project(points.first).dy);
    for (var i = 1; i < points.length; i++) {
      final o = project(points[i]);
      path.lineTo(o.dx, o.dy);
    }

    // Soft shadow under the line.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Main line.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Start marker.
    final start = project(points.first);
    canvas.drawCircle(start, 7, Paint()..color = AppTheme.secondaryColor);
    canvas.drawCircle(start, 3.5, Paint()..color = Colors.white);

    // Current/end marker.
    if (showCurrent) {
      final end = project(points.last);
      canvas.drawCircle(
        end,
        10,
        Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.25),
      );
      canvas.drawCircle(end, 6, Paint()..color = AppTheme.primaryColor);
      canvas.drawCircle(end, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points.length != points.length;
}
