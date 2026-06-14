import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/top_alert.dart';
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
      showTopAlert(context, 'Walk saved successfully.');
      c.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      showTopAlert(
        context,
        c.error ?? 'Could not save walk.',
        icon: Icons.info_outline_rounded,
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
            decoration: const BoxDecoration(
              gradient: AppTheme.appBackgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Walk complete',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.inferredActivityType == 'running'
                          ? 'Nice pace - that was a run!'
                          : 'Great job staying active.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RouteTraceView(
                        points: c.points,
                        showCurrent: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _summaryGrid(context, c),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => _discard(context, c),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.secondaryText,
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Discard'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () => _save(context, c),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
      (
        'Avg speed',
        '${c.averageSpeedKmh.toStringAsFixed(1)} km/h',
        Icons.speed_rounded,
      ),
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
        Row(
          children: [
            _tile(context, tiles[0]),
            const SizedBox(width: 12),
            _tile(context, tiles[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _tile(context, tiles[2]),
            const SizedBox(width: 12),
            _tile(context, tiles[3]),
          ],
        ),
        if (c.missionCompleted) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mission complete: walked 15+ minutes!',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
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
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.10),
          borderWidth: 1.3,
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
