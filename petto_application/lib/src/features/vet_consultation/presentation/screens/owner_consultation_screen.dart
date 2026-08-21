import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';
import '../controllers/consultation_controller.dart';
import '../widgets/appointment_card.dart';
import '../widgets/provider_map_view.dart';
import '../widgets/shared_health_card.dart';

/// Authenticated owner-side Feature 3 workspace. Guest presentation data stays
/// in the legacy home preview, while every action here uses the backend.
class OwnerConsultationScreen extends StatefulWidget {
  const OwnerConsultationScreen({
    super.key,
    required this.petId,
    required this.petName,
    this.latestAssessmentId,
    this.onAppointmentAccepted,
    this.loadMapTiles = true,
    this.locationService,
    this.realtimeAccessToken,
  });

  final int petId;
  final String petName;
  final int? latestAssessmentId;
  final Future<void> Function()? onAppointmentAccepted;
  final bool loadMapTiles;
  final LocationService? locationService;
  final String? realtimeAccessToken;

  @override
  State<OwnerConsultationScreen> createState() =>
      _OwnerConsultationScreenState();
}

class _OwnerConsultationScreenState extends State<OwnerConsultationScreen> {
  final _messageController = TextEditingController();
  final _conversationScrollController = ScrollController();
  Timer? _refreshTimer;
  int _pollTick = 0;
  int? _visibleConsultationId;
  int _visibleConversationItemCount = -1;
  bool _sending = false;
  bool _includeLatestAssessment = false;
  int? _respondingAppointmentId;
  bool _locating = false;
  bool _showMap = false;
  double? _userLatitude;
  double? _userLongitude;
  String? _locationHint;
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  @override
  void initState() {
    super.initState();
    _includeLatestAssessment = widget.latestAssessmentId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkspace());
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        final controller = context.read<ConsultationController>();
        _pollTick++;
        if (!controller.realtimeConnected || _pollTick % 10 == 0) {
          controller.refreshNewMessages();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant OwnerConsultationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petId != widget.petId) {
      context.read<ConsultationController>().closeActiveConsultation();
      _loadWorkspace();
    }
    if (oldWidget.latestAssessmentId != widget.latestAssessmentId &&
        widget.latestAssessmentId != null) {
      _includeLatestAssessment = true;
    }
  }

  Future<void> _loadWorkspace() =>
      context.read<ConsultationController>().loadOwnerWorkspace(widget.petId);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _conversationScrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scheduleScrollToLatest(int consultationId, int itemCount) {
    if (_visibleConsultationId == consultationId &&
        _visibleConversationItemCount == itemCount) {
      return;
    }
    _visibleConsultationId = consultationId;
    _visibleConversationItemCount = itemCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_conversationScrollController.hasClients) return;
      _conversationScrollController.animateTo(
        _conversationScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startConsultation(
    VetModel vet, {
    VeterinaryProviderModel? provider,
  }) async {
    await context.read<ConsultationController>().startConsultation(
      petId: widget.petId,
      vetId: vet.id,
      providerId: provider?.id,
      assessmentId: _includeLatestAssessment ? widget.latestAssessmentId : null,
      realtimeAccessToken: widget.realtimeAccessToken,
    );
  }

  Future<void> _openConsultation(ConsultationModel consultation) =>
      context.read<ConsultationController>().openConsultation(
        consultation,
        realtimeAccessToken: widget.realtimeAccessToken,
      );

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationHint = null;
    });
    try {
      final readiness = await _locationService.ensureReady();
      if (!mounted) return;
      if (readiness != LocationReadiness.ready) {
        setState(() {
          _locating = false;
          _locationHint = switch (readiness) {
            LocationReadiness.serviceDisabled =>
              'Turn on Location to sort nearby.',
            LocationReadiness.denied => 'Location permission was not granted.',
            LocationReadiness.deniedForever =>
              'Enable Location for Petto in device settings.',
            LocationReadiness.ready => null,
          };
        });
        return;
      }
      final position = await _locationService.currentPosition();
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locating = false;
          _locationHint = 'Current location is unavailable. Try again.';
        });
        return;
      }
      final controller = context.read<ConsultationController>();
      await controller.loadProviders(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _locating = false;
        if (controller.error == null) {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          _locationHint = 'Sorted by distance from your current location.';
        } else {
          _locationHint = 'Could not sort nearby providers. Try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationHint = 'Location is unavailable. Try again.';
      });
    }
  }

  Future<void> _openDirections(VeterinaryProviderModel provider) async {
    final query = provider.latitude != null && provider.longitude != null
        ? '${provider.latitude},${provider.longitude}'
        : provider.address ?? provider.name;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _chooseProviderVet(VeterinaryProviderModel provider) async {
    if (!provider.consultationEnabled) return;
    final controller = context.read<ConsultationController>();
    await controller.loadProviderVets(provider.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final vets = controller.providerVets;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('Choose an available Petto veterinarian'),
                const SizedBox(height: 14),
                if (vets.isEmpty)
                  const _EmptyCard(
                    message: 'No veterinarian is available for consultation.',
                  )
                else
                  for (final vet in vets)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.medical_services_rounded),
                      ),
                      title: Text(vet.name),
                      subtitle: Text(vet.specialty ?? 'Veterinarian'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _startConsultation(vet, provider: provider);
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProviderDetails(VeterinaryProviderModel provider) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _ProviderCard(
            provider: provider,
            onDirections: () {
              Navigator.of(sheetContext).pop();
              _openDirections(provider);
            },
            onConsult: provider.consultationEnabled
                ? () {
                    Navigator.of(sheetContext).pop();
                    _chooseProviderVet(provider);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final sent = await context.read<ConsultationController>().sendMessage(text);
    if (!mounted) return;
    if (sent) _messageController.clear();
    setState(() => _sending = false);
  }

  Future<void> _decideAppointment(
    AppointmentModel appointment,
    String decision,
  ) async {
    if (_respondingAppointmentId != null) return;
    setState(() => _respondingAppointmentId = appointment.id);
    final updated = await context
        .read<ConsultationController>()
        .decideAppointment(appointment.id, decision);
    if (!mounted) return;
    if (updated && decision == 'accepted') {
      try {
        await widget.onAppointmentAccepted?.call();
      } catch (_) {
        // The decision is already persisted. A transient Calendar refresh
        // failure will be recovered the next time the Calendar loads.
      }
    }
    if (!mounted) return;
    setState(() => _respondingAppointmentId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final active = controller.active;
        if (active != null && active.petId == widget.petId) {
          return _conversation(controller, active);
        }
        return _directory(controller);
      },
    );
  }

  Widget _directory(ConsultationController controller) {
    if (controller.loading &&
        controller.vets.isEmpty &&
        controller.consultations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadWorkspace,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 150),
        children: [
          const Text(
            'Veterinary Consultation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Persistent conversations for ${widget.petName}',
            style: const TextStyle(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: const Text('Use my location'),
            ),
          ),
          if (_locationHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _locationHint!,
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: controller.error!, onRetry: _loadWorkspace),
          ],
          if (widget.latestAssessmentId != null) ...[
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: _includeLatestAssessment,
              onChanged: (value) =>
                  setState(() => _includeLatestAssessment = value),
              title: const Text('Share latest AI health assessment'),
              subtitle: const Text(
                'The selected veterinarian receives the complete saved result.',
              ),
              secondary: const Icon(Icons.auto_awesome_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tileColor: AppTheme.primaryColor.withValues(alpha: 0.06),
            ),
          ],
          if (controller.consultations.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionLabel('Existing consultations'),
            const SizedBox(height: 10),
            for (final consultation in controller.consultations)
              _ConsultationCard(
                consultation: consultation,
                onTap: () => _openConsultation(consultation),
              ),
          ],
          const SizedBox(height: 22),
          const _SectionLabel('Nearby hospitals and clinics'),
          const SizedBox(height: 10),
          if (controller.providers.isNotEmpty) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_list_rounded),
                  label: Text('List'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.map_rounded),
                  label: Text('Map'),
                ),
              ],
              selected: {_showMap},
              onSelectionChanged: (selection) {
                setState(() => _showMap = selection.first);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (controller.providers.isEmpty && controller.vets.isEmpty)
            const _EmptyCard(
              message: 'No veterinary provider is listed right now.',
            )
          else if (_showMap && controller.providers.isNotEmpty)
            SizedBox(
              height: 430,
              child: ProviderMapView(
                providers: controller.providers,
                userLatitude: _userLatitude,
                userLongitude: _userLongitude,
                loadTiles: widget.loadMapTiles,
                onProviderTap: _showProviderDetails,
              ),
            )
          else if (controller.providers.isNotEmpty)
            for (final provider in controller.providers)
              _ProviderCard(
                provider: provider,
                onDirections: () => _openDirections(provider),
                onConsult: provider.consultationEnabled
                    ? () => _chooseProviderVet(provider)
                    : null,
              )
          else
            for (final vet in controller.vets)
              _VetCard(
                vet: vet,
                busy: controller.loading,
                onStart: () => _startConsultation(vet),
              ),
        ],
      ),
    );
  }

  Widget _conversation(
    ConsultationController controller,
    ConsultationModel consultation,
  ) {
    _scheduleScrollToLatest(
      consultation.id,
      controller.messages.length +
          controller.appointments.length +
          controller.sharedHealthCards.length,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to consultations',
                onPressed: controller.closeActiveConsultation,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.vetName ??
                          'Veterinarian #${consultation.vetId}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.petName} • ${consultation.status}',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                    Text(
                      controller.realtimeConnected
                          ? '● Realtime connected'
                          : '● Reconnecting • polling active',
                      key: const Key('owner-chat-connection-status'),
                      style: TextStyle(
                        color: controller.realtimeConnected
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Share Pet Health ID',
                onPressed: controller.sharingHealthCard
                    ? null
                    : () async {
                        final shared = await controller.shareHealthCard();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              shared
                                  ? 'Pet Health ID shared with this veterinarian.'
                                  : 'Could not share Pet Health ID.',
                            ),
                          ),
                        );
                      },
                icon: controller.sharingHealthCard
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.badge_rounded),
              ),
              IconButton(
                tooltip: 'Refresh messages',
                onPressed: controller.loading
                    ? null
                    : controller.refreshMessages,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              controller.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child:
              controller.loading &&
                  controller.messages.isEmpty &&
                  controller.appointments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.messages.isEmpty && controller.appointments.isEmpty
              ? const _EmptyCard(message: 'No messages yet. Say hello.')
              : ListView(
                  controller: _conversationScrollController,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    for (final sharedCard in controller.sharedHealthCards)
                      SharedHealthCardPanel(
                        card: sharedCard,
                        onRevoke: () =>
                            controller.revokeHealthCard(sharedCard.id),
                      ),
                    for (final appointment in controller.appointments)
                      ConsultationAppointmentCard(
                        appointment: appointment,
                        busy: _respondingAppointmentId == appointment.id,
                        onAccept: appointment.isPending
                            ? () => _decideAppointment(appointment, 'accepted')
                            : null,
                        onDecline: appointment.isPending
                            ? () => _decideAppointment(appointment, 'declined')
                            : null,
                      ),
                    for (final message in controller.messages)
                      _OwnerMessageBubble(message),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            // HomeScreen draws its persistent navigation bar above the active
            // feature view. Keep the composer above that bar so sending a
            // message remains possible on phones and the web demo.
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.onDirections,
    this.onConsult,
  });

  final VeterinaryProviderModel provider;
  final VoidCallback onDirections;
  final VoidCallback? onConsult;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (provider.distanceKm != null)
        '${provider.distanceKm!.toStringAsFixed(1)} km',
      if (provider.phone?.trim().isNotEmpty == true) provider.phone!,
      if (provider.todayHours != null) 'Today ${provider.todayHours}',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.local_hospital_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        provider.consultationEnabled
                            ? 'Available on Petto'
                            : 'Information only',
                        style: TextStyle(
                          color: provider.consultationEnabled
                              ? Colors.green
                              : AppTheme.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.address?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(provider.address!),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                details.join(' • '),
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onConsult,
                    icon: const Icon(Icons.forum_rounded),
                    label: Text(onConsult == null ? 'Unavailable' : 'Consult'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
  );
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.consultation, required this.onTap});
  final ConsultationModel consultation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.forum_rounded)),
      title: Text(
        consultation.vetName ?? 'Veterinarian #${consultation.vetId}',
      ),
      subtitle: Text(
        '${consultation.status} • ${consultation.providerName ?? 'Petto'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _VetCard extends StatelessWidget {
  const _VetCard({
    required this.vet,
    required this.busy,
    required this.onStart,
  });
  final VetModel vet;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: const Icon(Icons.medical_services_rounded),
      ),
      title: Text(
        vet.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        [vet.specialty, vet.clinicName].whereType<String>().join(' • '),
      ),
      trailing: FilledButton(
        onPressed: busy ? null : onStart,
        child: const Text('Consult'),
      ),
    ),
  );
}

class _OwnerMessageBubble extends StatelessWidget {
  const _OwnerMessageBubble(this.message);
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final mine = message.senderType == 'user';
    final status = message.readAt != null
        ? 'Read'
        : message.deliveredAt != null
        ? 'Delivered'
        : 'Sent';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAiBriefing)
              const Text(
                'AI briefing',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            Text(
              message.content ?? 'Shared attachment',
              style: TextStyle(color: mine ? Colors.white : null),
            ),
            const SizedBox(height: 4),
            Text(
              mine ? status : message.senderType.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(message, style: const TextStyle(color: AppTheme.mutedText)),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.red.withValues(alpha: 0.06),
    child: ListTile(
      leading: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
      title: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}
