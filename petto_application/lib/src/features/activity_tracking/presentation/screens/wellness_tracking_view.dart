import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/activity_tracking_controller.dart';
import '../../../missions/presentation/controllers/missions_controller.dart';
import 'live_walk_screen.dart';

/// Content of the "wellness" tab (map icon in the dock).
///
/// Phase 0 = Mode A only: an activity summary + a big "Start a Walk" CTA that
/// launches the live GPS session. Mode B (device) is shown as a coming-soon
/// teaser so the two-mode design is visible in the UI.
class WellnessTrackingView extends StatefulWidget {
  const WellnessTrackingView({super.key, this.petName});

  final String? petName;

  @override
  State<WellnessTrackingView> createState() => _WellnessTrackingViewState();
}

class _WellnessTrackingViewState extends State<WellnessTrackingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId = context.read<AuthController>().petId;
      context.read<ActivityTrackingController>().loadStats(petId: petId);
    });
  }

  void _startWalk() {
    final activityController = context.read<ActivityTrackingController>();
    final missionsController = context.read<MissionsController>();
    final petId = context.read<AuthController>().petId;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => LiveWalkScreen(petName: widget.petName),
        ))
        .then((_) {
      // Refresh activity stats + missions for THIS pet after the walk so the
      // backend's auto-completed walk mission shows up (not the seed pet's).
      activityController.loadStats(petId: petId);
      missionsController.loadAll(petId: petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTrackingController>(
      builder: (context, c, _) {
        final stats = c.stats;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
          children: [
            Text('Activity', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Track walks with ${widget.petName ?? 'your pet'} in real time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Totals
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCardDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _miniStat(context, stats.distanceText, 'Total distance'),
                      _divider(),
                      _miniStat(context, stats.durationText, 'Total time'),
                      _divider(),
                      _miniStat(
                        context,
                        '${stats.totalActivities}',
                        'Sessions',
                      ),
                    ],
                  ),
                  if (c.statsLoading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Start walk CTA (Mode A)
            _ModeCard(
              icon: Icons.directions_walk_rounded,
              iconColor: AppTheme.primaryColor,
              title: 'Start a Walk',
              subtitle:
                  'Live GPS tracking - distance, time and pace, just like a run app.',
              actionLabel: 'Start',
              onTap: _startWalk,
            ),
            const SizedBox(height: 14),

            // Mode B teaser (device)
            _ModeCard(
              icon: Icons.sensors_rounded,
              iconColor: AppTheme.secondaryColor,
              title: 'Live Pet Tracking',
              subtitle:
                  'Pair a device (e.g. Minew tag) for activity, rest detection and alerts.',
              actionLabel: 'Soon',
              enabled: false,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _miniStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(value,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor: enabled ? iconColor : AppTheme.mutedText,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
