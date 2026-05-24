import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/activity_tracking_controller.dart';
import '../widgets/route_trace_view.dart';

/// Post-walk review for Mode A. Shows the route + totals and lets the user save
/// the session (aggregate only) or discard it.
class WalkSummaryScreen extends StatelessWidget {
  const WalkSummaryScreen({super.key});

  Future<void> _save(BuildContext context, ActivityTrackingController c) async {
    final ok = await c.save();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการเดินเรียบร้อยแล้ว 🐾')),
      );
      c.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(c.error ?? 'บันทึกไม่สำเร็จ')),
      );
    }
  }

  void _discard(BuildContext context, ActivityTrackingController c) {
    c.reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTrackingController>(
      builder: (context, c, _) {
        final saving = c.state == WalkState.saving;
        return Scaffold(
          body: Container(
            decoration:
                const BoxDecoration(gradient: AppTheme.appBackgroundGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Walk complete 🎉',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      c.inferredActivityType == 'running'
                          ? 'Nice pace - that was a run!'
                          : 'Great job staying active.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RouteTraceView(points: c.points, showCurrent: false),
                    ),
                    const SizedBox(height: 16),
                    _summaryGrid(context, c),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                saving ? null : () => _discard(context, c),
                            child: const Text('Discard'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton(
                            onPressed: saving ? null : () => _save(context, c),
                            child: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Walk'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryGrid(BuildContext context, ActivityTrackingController c) {
    final tiles = [
      ('Distance', '${c.distanceKmText} km', Icons.straighten_rounded),
      ('Duration', c.elapsedText, Icons.timer_outlined),
      ('Avg speed', '${c.averageSpeedKmh.toStringAsFixed(1)} km/h',
          Icons.speed_rounded),
      (
        'Type',
        c.inferredActivityType == 'running' ? 'Running' : 'Walking',
        c.inferredActivityType == 'running'
            ? Icons.directions_run_rounded
            : Icons.directions_walk_rounded,
      ),
    ];

    return Column(
      children: [
        Row(children: [
          _tile(context, tiles[0]),
          const SizedBox(width: 12),
          _tile(context, tiles[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _tile(context, tiles[2]),
          const SizedBox(width: 12),
          _tile(context, tiles[3]),
        ]),
        if (c.missionCompleted) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppTheme.successColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mission complete: walked 15+ minutes!',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.successColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, (String, String, IconData) data) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.$3, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 10),
            Text(data.$2, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(data.$1, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
