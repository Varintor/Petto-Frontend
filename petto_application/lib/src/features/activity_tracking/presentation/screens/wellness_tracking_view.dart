import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/petto_transitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/activity_tracking_controller.dart';
import '../controllers/device_tracking_controller.dart';
import '../../../missions/presentation/controllers/missions_controller.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/services/ble_gps_service.dart';
import 'live_walk_screen.dart';
import 'live_device_tracking_screen.dart';

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
      // Use rawPetId so an authenticated user without a pet doesn't fall
      // back to the seed pet (Milo) and see his mock walking stats.
      final auth = context.read<AuthController>();
      final petId = auth.isGuest ? auth.petId : auth.rawPetId;
      if (petId == null) {
        context.read<ActivityTrackingController>().clearForAccount();
        return;
      }
      context.read<ActivityTrackingController>().loadStats(petId: petId);
      context.read<DeviceTrackingController>().load(petId);
    });
  }

  void _startWalk() {
    final activityController = context.read<ActivityTrackingController>();
    final missionsController = context.read<MissionsController>();
    final auth = context.read<AuthController>();
    final petId = auth.isGuest ? auth.petId : auth.rawPetId;
    Navigator.of(context)
        .push(
          PettoPageRoute(
            builder: (_) => LiveWalkScreen(petName: widget.petName),
          ),
        )
        .then((_) {
          // Refresh activity stats + missions for THIS pet after the walk so the
          // backend's auto-completed walk mission shows up (not the seed pet's).
          if (petId == null) return;
          activityController.loadStats(petId: petId);
          missionsController.loadAll(petId: petId);
        });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthController>();
    final petId = auth.isGuest ? auth.petId : auth.rawPetId;
    if (petId == null) return;
    await Future.wait([
      context.read<ActivityTrackingController>().loadStats(petId: petId),
      context.read<DeviceTrackingController>().load(petId),
    ]);
  }

  Future<void> _scanAndConnectBle(int petId) async {
    final controller = context.read<DeviceTrackingController>();
    await controller.scanBleDevices();
    if (!mounted || controller.bleCandidates.isEmpty) return;
    final candidate = await showModalBottomSheet<BleDeviceCandidate>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Choose GPS collar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final item in controller.bleCandidates)
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(item.name),
                subtitle: Text('${item.id} · signal ${item.rssi} dBm'),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (candidate == null || !mounted) return;
    final connected = await controller.connectBle(petId, candidate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? '${candidate.name} connected. Waiting for GPS data.'
              : 'Could not connect to ${candidate.name}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTrackingController>(
      builder: (context, c, _) {
        final stats = c.stats;
        final deviceController = context.watch<DeviceTrackingController>();
        final auth = context.read<AuthController>();
        final petId = auth.isGuest ? auth.petId : auth.rawPetId;
        final device = deviceController.activeDevice;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 140),
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: c.statsLoading || deviceController.loading
                      ? null
                      : _refresh,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: AppTheme.glassCardDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                borderColor: Colors.white,
                borderWidth: 3,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.blushSurfaceColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.directions_walk_rounded,
                          color: AppTheme.primaryColor,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Walk Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.blushSurfaceColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    const PettoSkeletonBox(height: 6, radius: 999),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            _ModeCard(
              icon: Icons.directions_walk_rounded,
              backgroundColor: AppTheme.surfaceColor,
              iconColor: Colors.white,
              iconBackgroundColor: AppTheme.primaryColor,
              title: 'Start a Walk',
              subtitle: 'Live GPS for distance, time and pace.',
              actionLabel: 'Start',
              actionIcon: Icons.arrow_forward_rounded,
              onTap: _startWalk,
            ),
            const SizedBox(height: 14),

            _ModeCard(
              icon: Icons.sensors_rounded,
              backgroundColor: AppTheme.surfaceColor,
              iconColor: Colors.white,
              iconBackgroundColor: AppTheme.secondaryColor,
              title: 'Live Pet Tracking',
              subtitle: device == null
                  ? 'Pair a collar for activity, rest detection and alerts.'
                  : deviceController.bleConnected
                  ? 'Collar connected. Live GPS updates every 2 seconds.'
                  : 'Cloud tracking is ready. Open the live map.',
              actionLabel: device == null ? 'Scan' : 'Open',
              actionIcon: Icons.arrow_forward_rounded,
              enabled: petId != null && !deviceController.loading,
              onTap: () async {
                if (petId == null) return;
                if (device != null) {
                  Navigator.of(context).push(
                    PettoPageRoute(
                      builder: (_) => const LiveDeviceTrackingScreen(),
                    ),
                  );
                  return;
                }
                await _scanAndConnectBle(petId);
              },
            ),
            if (device == null && petId != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _SimulatorButton(
                  busy: deviceController.loading,
                  onPressed: () async {
                    final paired = await deviceController.pairDemo(petId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          paired
                              ? 'Simulator paired.'
                              : 'Could not pair the simulator.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (deviceController.loading) ...[
              const SizedBox(height: 10),
              const _TrackerLoadingIndicator(),
            ],
            if (deviceController.error != null) ...[
              const SizedBox(height: 10),
              Text(
                deviceController.error!,
                style: const TextStyle(color: AppTheme.dangerColor),
              ),
            ],
            if (device != null) ...[
              const SizedBox(height: 12),
              _DeviceStatusCard(
                device: device,
                alerts: deviceController.alerts,
                busy: deviceController.loading,
                onSimulate: () => deviceController.simulateTelemetry(),
                onSimulateAlert: () =>
                    deviceController.simulateTelemetry(anomaly: true),
                onUnpair: deviceController.unpair,
                onViewMap: () => Navigator.of(context).push(
                  PettoPageRoute(
                    builder: (_) => const LiveDeviceTrackingScreen(),
                  ),
                ),
              ),
            ],
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
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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

class _SimulatorButton extends StatelessWidget {
  const _SimulatorButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
          decoration: BoxDecoration(
            color: AppTheme.blushSurfaceColor.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  size: 15,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                busy ? 'Preparing demo…' : 'Use demo tracker',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                busy ? Icons.more_horiz_rounded : Icons.arrow_forward_rounded,
                size: 15,
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrackerLoadingIndicator extends StatelessWidget {
  const _TrackerLoadingIndicator();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: AppTheme.glassCardDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(20),
      borderColor: Colors.white,
      borderWidth: 2,
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.blushSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
              backgroundColor: AppTheme.roseSurfaceColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Updating tracker…',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Syncing the latest device status',
                style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.sync_rounded,
          size: 20,
          color: AppTheme.secondaryColor,
        ),
      ],
    ),
  );
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({
    required this.device,
    required this.alerts,
    required this.busy,
    required this.onSimulate,
    required this.onSimulateAlert,
    required this.onUnpair,
    required this.onViewMap,
  });

  final DeviceModel device;
  final List<String> alerts;
  final bool busy;
  final Future<bool> Function() onSimulate;
  final Future<bool> Function() onSimulateAlert;
  final Future<bool> Function() onUnpair;
  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: AppTheme.glassCardDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(28),
      borderColor: Colors.white,
      borderWidth: 3,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.blushSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sensors_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        device.identifier.startsWith('PETTO-DEMO-')
                            ? 'SIMULATED DEVICE'
                            : 'GPS COLLAR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.battery_5_bar_rounded,
                    size: 18,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${device.batteryPercent ?? '--'}%',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          device.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device.lastLat == null
                    ? 'Waiting for the first GPS sample'
                    : 'Location ready · ${device.lastLat!.toStringAsFixed(5)}, ${device.lastLng!.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final alert in alerts)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.blushSurfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppTheme.dangerColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(
                        color: AppTheme.dangerColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onSimulate,
            icon: const Icon(Icons.route_rounded),
            label: const Text('Simulate walk'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: device.lastLat == null ? null : onViewMap,
                icon: const Icon(Icons.map_rounded, size: 19),
                label: const Text('Live map'),
                style: _secondaryActionStyle(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onSimulateAlert,
                icon: const Icon(Icons.warning_amber_rounded, size: 19),
                label: const Text('Test alert'),
                style: _secondaryActionStyle(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppTheme.blushSurfaceColor.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 19,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Routes stay private and are removed after 7 days.',
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                ),
              ),
              TextButton(
                onPressed: busy ? null : onUnpair,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Unpair'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  ButtonStyle _secondaryActionStyle() => OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    backgroundColor: AppTheme.blushSurfaceColor.withValues(alpha: 0.48),
    foregroundColor: AppTheme.primaryColor,
    side: const BorderSide(color: Colors.white, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        decoration: AppTheme.glassCardDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(26),
          borderColor: Colors.white,
          borderWidth: 3,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: enabled ? onTap : null,
              iconAlignment: IconAlignment.end,
              icon: Icon(actionIcon, size: 18),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
