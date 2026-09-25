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
                    const PettoSkeletonBox(height: 6, radius: 999),
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

            // Mode B supports a physical BLE/GPS collar and retains the
            // labelled simulator for development without hardware.
            _ModeCard(
              icon: Icons.sensors_rounded,
              iconColor: AppTheme.secondaryColor,
              title: 'Live Pet Tracking',
              subtitle: device == null
                  ? 'Scan for a BLE/GPS collar, or use the simulator for development.'
                  : deviceController.bleConnected
                  ? 'BLE collar connected. GPS packets upload every 2 seconds.'
                  : 'Cloud tracking is ready. Open the live map to follow location.',
              actionLabel: device == null ? 'Scan BLE' : 'Connected',
              enabled: petId != null && !deviceController.loading,
              onTap: () async {
                if (petId == null || device != null) return;
                await _scanAndConnectBle(petId);
              },
            ),
            if (device == null && petId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: deviceController.loading
                      ? null
                      : () async {
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
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Use simulator instead'),
                ),
              ),
            if (deviceController.loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  device.identifier.startsWith('PETTO-DEMO-')
                      ? 'SIMULATED DEVICE'
                      : 'BLE/GPS COLLAR',
                ),
              ),
              const Spacer(),
              Text('${device.batteryPercent ?? '--'}% battery'),
            ],
          ),
          Text(device.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            device.lastLat == null
                ? 'Waiting for the first GPS sample'
                : 'Last location ${device.lastLat!.toStringAsFixed(5)}, ${device.lastLng!.toStringAsFixed(5)}',
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final alert in alerts)
              Text(
                '⚠ $alert',
                style: const TextStyle(
                  color: AppTheme.dangerColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onSimulate,
                icon: const Icon(Icons.route_rounded),
                label: const Text('Simulate walk'),
              ),
              OutlinedButton.icon(
                onPressed: device.lastLat == null ? null : onViewMap,
                icon: const Icon(Icons.map),
                label: const Text('View Live Map'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onSimulateAlert,
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Simulate alert'),
              ),
              TextButton(
                onPressed: busy ? null : onUnpair,
                child: const Text('Unpair'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Precise route points are retained for 7 days, owner-only, then removed. Activity aggregates remain in Health History.',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
        ],
      ),
    ),
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
