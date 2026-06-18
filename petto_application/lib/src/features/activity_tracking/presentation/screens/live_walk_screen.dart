import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/activity_tracking_controller.dart';
import '../widgets/walk_map_view.dart';
import 'walk_summary_screen.dart';

/// Live "Nike Run"-style walk session for Mode A (no device).
///
/// Auto-starts GPS tracking on open, shows the live route + stats, and lets the
/// user pause/resume/stop. Stopping moves to [WalkSummaryScreen] for review.
class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({super.key, this.petName});

  final String? petName;

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ActivityTrackingController>();
      if (!c.isActive) c.start();
    });
  }

  Future<bool> _confirmDiscard(ActivityTrackingController c) async {
    if (!c.isActive) return true;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppTheme.secondaryText.withValues(alpha: 0.38),
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppTheme.motionNormal,
        curve: AppTheme.motionCurveSoft,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: Transform.scale(
                scale: 0.975 + (0.025 * value),
                child: child,
              ),
            ),
          );
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.blushSurfaceColor.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Discard walk?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This walk will not be saved.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppTheme.secondaryText,
                          backgroundColor: AppTheme.creamSurfaceColor
                              .withValues(alpha: 0.72),
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep walking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Discard'),
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
    if (result == true) c.reset();
    return result ?? false;
  }

  void _goToSummary(ActivityTrackingController c) {
    c.finish();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppTheme.motionNormal,
        reverseTransitionDuration: AppTheme.motionFast,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const WalkSummaryScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppTheme.motionCurveSoft,
            reverseCurve: AppTheme.motionReverseCurve,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.002),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTrackingController>(
      builder: (context, c, _) {
        return PopScope(
          canPop: !c.isActive,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) {
              final navigator = Navigator.of(context);
              final ok = await _confirmDiscard(c);
              if (ok && mounted) navigator.pop();
            }
          },
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBackgroundGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(context, c),
                      const SizedBox(height: 12),
                      Expanded(
                        child: c.state == WalkState.error
                            ? _errorView(context, c)
                            : WalkMapView(
                                points: c.points,
                                current: c.currentPoint,
                              ),
                      ),
                      const SizedBox(height: 16),
                      _statsRow(context, c),
                      const SizedBox(height: 18),
                      _controls(context, c),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, ActivityTrackingController c) {
    final statusLabel = switch (c.state) {
      WalkState.tracking => 'Recording',
      WalkState.paused => 'Paused',
      WalkState.error => 'GPS issue',
      _ => 'Getting ready',
    };
    final statusColor = c.state == WalkState.paused
        ? AppTheme.accentColor
        : c.state == WalkState.error
        ? AppTheme.dangerColor
        : AppTheme.successColor;

    return Row(
      children: [
        IconButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final ok = await _confirmDiscard(c);
            if (ok && mounted) navigator.pop();
          },
          icon: const Icon(Icons.close_rounded),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.petName == null ? 'Walk' : 'Walk with ${widget.petName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _statsRow(BuildContext context, ActivityTrackingController c) {
    return Row(
      children: [
        _statTile(context, c.distanceKmText, 'km', Icons.straighten_rounded),
        const SizedBox(width: 12),
        _statTile(context, c.elapsedText, 'time', Icons.timer_outlined),
        const SizedBox(width: 12),
        _statTile(
          context,
          c.currentSpeedKmh.toStringAsFixed(1),
          'km/h',
          Icons.speed_rounded,
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, ActivityTrackingController c) {
    if (c.state == WalkState.error) {
      return FilledButton.icon(
        onPressed: () => c.start(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      );
    }

    final isPaused = c.state == WalkState.paused;
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                fixedSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: BorderSide(
                  color: AppTheme.warmSurfaceColor.withValues(alpha: 0.78),
                  width: 1.4,
                ),
              ),
              onPressed: isPaused ? c.resume : c.pause,
              icon: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
              label: Text(isPaused ? 'Resume' : 'Pause'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                minimumSize: const Size.fromHeight(58),
                fixedSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _goToSummary(c),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, ActivityTrackingController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: AppTheme.dangerColor,
            ),
            const SizedBox(height: 16),
            Text(
              c.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
