import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';
import '../controllers/consultation_controller.dart';
import '../widgets/appointment_card.dart';
import '../widgets/provider_map_view.dart';
import '../widgets/shared_assessment_card.dart';
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
    bool urgent = false,
  }) async {
    await context.read<ConsultationController>().startConsultation(
      petId: widget.petId,
      vetId: vet.id,
      providerId: provider?.id,
      assessmentId: _includeLatestAssessment ? widget.latestAssessmentId : null,
      urgent: urgent,
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

  Future<void> _chooseProviderVet(
    VeterinaryProviderModel provider, {
    bool urgent = false,
  }) async {
    if (!provider.consultationEnabled) return;
    final controller = context.read<ConsultationController>();
    await controller.loadProviderVets(provider.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (sheetContext) {
        final vets = controller.providerVets;
        return _VetPickerSheet(
          provider: provider,
          vets: vets,
          urgent: urgent,
          onVetSelected: (vet) {
            Navigator.of(sheetContext).pop();
            _startConsultation(vet, provider: provider, urgent: urgent);
          },
        );
      },
    );
  }

  Future<void> _requestUrgentHelp(VeterinaryProviderModel provider) async {
    if (!provider.consultationEnabled) return;
    final acknowledged = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.sos_rounded, color: Colors.redAccent),
        title: const Text('Request Urgent Help?'),
        content: const Text(
          'Petto will open a high-priority chat with an available verified '
          'veterinarian. This is not an emergency dispatch service and a '
          'response time is not guaranteed. For immediate danger, contact or '
          'travel to the nearest veterinary hospital directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const Key('acknowledge-urgent-help'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('I understand'),
          ),
        ],
      ),
    );
    if (acknowledged != true || !mounted) return;
    await _chooseProviderVet(provider, urgent: true);
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
            onUrgent: provider.consultationEnabled
                ? () {
                    Navigator.of(sheetContext).pop();
                    _requestUrgentHelp(provider);
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

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    if (_respondingAppointmentId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'The appointment will also be removed from the pet Calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _respondingAppointmentId = appointment.id);
    final updated = await context
        .read<ConsultationController>()
        .cancelAppointment(appointment.id);
    if (updated) {
      try {
        await widget.onAppointmentAccepted?.call();
      } catch (_) {
        // The cancellation is persisted; Calendar refresh can recover later.
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
      return const Center(child: _AssistantLoading());
    }
    return RefreshIndicator(
      onRefresh: _loadWorkspace,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 150),
        children: [
          _AssistantHero(
            petName: widget.petName,
            consultationCount: controller.consultations.length,
            onlineCount: controller.vets.where((vet) => vet.isOnline).length,
          ),
          const SizedBox(height: 16),
          _AssistantQuickActions(
            locating: _locating,
            showMap: _showMap,
            hasProviders: controller.providers.isNotEmpty,
            onUseLocation: _useCurrentLocation,
            onToggleMap: controller.providers.isEmpty
                ? null
                : () => setState(() => _showMap = !_showMap),
          ),
          if (_locationHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _SoftNotice(text: _locationHint!),
            ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: controller.error!, onRetry: _loadWorkspace),
          ],
          if (widget.latestAssessmentId != null) ...[
            const SizedBox(height: 14),
            _ShareAssessmentCard(
              value: _includeLatestAssessment,
              onChanged: (value) =>
                  setState(() => _includeLatestAssessment = value),
            ),
          ],
          if (controller.consultations.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionLabel(
              'Recent conversations',
              action: '${controller.consultations.length} active',
            ),
            const SizedBox(height: 10),
            for (final consultation in controller.consultations)
              _ConsultationCard(
                consultation: consultation,
                onTap: () => _openConsultation(consultation),
              ),
          ],
          const SizedBox(height: 24),
          _SectionLabel(
            'Care team',
            action: _showMap && controller.providers.isNotEmpty
                ? 'Map view'
                : 'Ready',
          ),
          const SizedBox(height: 10),
          if (controller.providers.isEmpty && controller.vets.isEmpty)
            const _EmptyCard(
              message: 'No veterinary provider is listed right now.',
            )
          else if (_showMap && controller.providers.isNotEmpty)
            Container(
              height: 430,
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              decoration: AppTheme.glassCardDecoration(
                borderRadius: BorderRadius.circular(34),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: ProviderMapView(
                  providers: controller.providers,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                  loadTiles: widget.loadMapTiles,
                  onProviderTap: _showProviderDetails,
                ),
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
                onUrgent: provider.consultationEnabled
                    ? () => _requestUrgentHelp(provider)
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
    final hasConversationContent =
        controller.messages.isNotEmpty ||
        controller.appointments.isNotEmpty ||
        controller.sharedAssessments.isNotEmpty ||
        controller.sharedHealthCards.isNotEmpty;

    _scheduleScrollToLatest(
      consultation.id,
      controller.messages.length +
          controller.appointments.length +
          controller.sharedAssessments.length +
          controller.sharedHealthCards.length,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
          child: _ChatHeaderCard(
            consultation: consultation,
            petName: widget.petName,
            realtimeConnected: controller.realtimeConnected,
            sharingHealthCard: controller.sharingHealthCard,
            onBack: controller.closeActiveConsultation,
            onRefresh: controller.loading ? null : controller.refreshMessages,
            onShareAssessment:
                widget.latestAssessmentId == null || consultation.isClosed
                ? null
                : () async {
                    final shared = await controller.shareAssessment(
                      widget.latestAssessmentId!,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          shared
                              ? 'Assessment shared with this veterinarian.'
                              : 'Could not share the assessment.',
                        ),
                      ),
                    );
                  },
            onShareHealthCard:
                controller.sharingHealthCard || consultation.isClosed
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
          ),
        ),
        KeyedSubtree(
          key: const Key('owner-chat-connection-status'),
          child: const SizedBox.shrink(),
        ),
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _SoftNotice(
              text: controller.error!,
              icon: Icons.error_outline_rounded,
              tint: AppTheme.dangerColor,
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: _ChatSurface(
              child: controller.loading && !hasConversationContent
                  ? const Center(
                      child: _AssistantLoading(label: 'Opening chat'),
                    )
                  : !hasConversationContent
                  ? _ChatEmptyState(petName: widget.petName)
                  : ListView(
                      controller: _conversationScrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      children: [
                        for (final assessment in controller.sharedAssessments)
                          SharedAssessmentPanel(
                            assessment: assessment,
                            onRevoke: () => controller.revokeAssessment(
                              assessment.assessmentId,
                            ),
                          ),
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
                                ? () => _decideAppointment(
                                    appointment,
                                    'accepted',
                                  )
                                : null,
                            onDecline: appointment.isPending
                                ? () => _decideAppointment(
                                    appointment,
                                    'declined',
                                  )
                                : null,
                            onCancel: appointment.isAccepted
                                ? () => _cancelAppointment(appointment)
                                : null,
                          ),
                        for (final message in controller.messages)
                          _OwnerMessageBubble(message),
                      ],
                    ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            child: consultation.isClosed
                ? const _ClosedConsultationComposer()
                : _MessageComposer(
                    controller: _messageController,
                    sending: _sending,
                    onSend: _sendMessage,
                  ),
          ),
        ),
      ],
    );
  }
}

class _AssistantHero extends StatelessWidget {
  const _AssistantHero({
    required this.petName,
    required this.consultationCount,
    required this.onlineCount,
  });

  final String petName;
  final int consultationCount;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: _SoftCircle(
              size: 82,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 58,
            bottom: -16,
            child: _SoftCircle(
              size: 34,
              color: AppTheme.accentColor.withValues(alpha: 0.22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _SoftPulse(child: _HeroIcon()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistant',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Care support for $petName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Online vets',
                      value: '$onlineCount',
                      icon: Icons.support_agent_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStat(
                      label: 'Chats',
                      value: '$consultationCount',
                      icon: Icons.forum_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.health_and_safety_rounded,
        color: AppTheme.primaryColor,
        size: 28,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantQuickActions extends StatelessWidget {
  const _AssistantQuickActions({
    required this.locating,
    required this.showMap,
    required this.hasProviders,
    required this.onUseLocation,
    required this.onToggleMap,
  });

  final bool locating;
  final bool showMap;
  final bool hasProviders;
  final VoidCallback onUseLocation;
  final VoidCallback? onToggleMap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 360;
        final locationPill = _MiniActionPill(
          icon: Icons.my_location_rounded,
          label: locating ? 'Locating' : 'Use my location',
          tint: AppTheme.primaryColor,
          busy: locating,
          onTap: locating ? null : onUseLocation,
        );
        final mapPill = _MiniActionPill(
          icon: showMap ? Icons.view_list_rounded : Icons.map_rounded,
          label: showMap ? 'List' : 'Map',
          tint: AppTheme.accentColor,
          muted: !hasProviders,
          onTap: onToggleMap,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [locationPill, const SizedBox(height: 10), mapPill],
          );
        }
        return Row(
          children: [
            Expanded(child: locationPill),
            const SizedBox(width: 10),
            Expanded(child: mapPill),
          ],
        );
      },
    );
  }
}

class _MiniActionPill extends StatelessWidget {
  const _MiniActionPill({
    required this.icon,
    required this.label,
    required this.tint,
    this.onTap,
    this.busy = false,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback? onTap;
  final bool busy;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !muted;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        backgroundColor: active
            ? AppTheme.surfaceColor.withValues(alpha: 0.98)
            : AppTheme.surfaceColor.withValues(alpha: 0.68),
        side: BorderSide(color: tint.withValues(alpha: active ? 0.18 : 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: active ? 0.12 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tint,
                      ),
                    )
                  : Icon(icon, color: tint, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? AppTheme.secondaryText : AppTheme.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareAssessmentCard extends StatelessWidget {
  const _ShareAssessmentCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.motionNormal,
      curve: AppTheme.motionCurve,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: AppTheme.glassCardDecoration(
        color: value
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.surfaceColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        borderColor: AppTheme.primaryColor.withValues(
          alpha: value ? 0.22 : 0.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: value ? Colors.white : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share latest AI check',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Send the saved result as context.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.22),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  const _SoftNotice({
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.tint = AppTheme.primaryColor,
  });

  final String text;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText.withValues(alpha: 0.76),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SoftPulse extends StatefulWidget {
  const _SoftPulse({required this.child});

  final Widget child;

  @override
  State<_SoftPulse> createState() => _SoftPulseState();
}

class _SoftPulseState extends State<_SoftPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(
      begin: 0.985,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward().then((_) {
      if (!mounted) return;
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class _VetPickerSheet extends StatelessWidget {
  const _VetPickerSheet({
    required this.provider,
    required this.vets,
    required this.urgent,
    required this.onVetSelected,
  });

  final VeterinaryProviderModel provider;
  final List<VetModel> vets;
  final bool urgent;
  final ValueChanged<VetModel> onVetSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 14),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppTheme.secondaryText,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                urgent
                                    ? 'Choose a veterinarian for Urgent Help'
                                    : 'Choose an available Petto veterinarian',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (vets.isEmpty)
                      const _EmptyCard(
                        message:
                            'No veterinarian is available for consultation.',
                      )
                    else
                      for (final vet in vets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VetChoiceTile(
                            vet: vet,
                            onTap: () => onVetSelected(vet),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VetChoiceTile extends StatelessWidget {
  const _VetChoiceTile({required this.vet, required this.onTap});

  final VetModel vet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(24),
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        hasShadow: false,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          vet.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          vet.specialty ?? 'Veterinarian',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.onDirections,
    this.onConsult,
    this.onUrgent,
  });

  final VeterinaryProviderModel provider;
  final VoidCallback onDirections;
  final VoidCallback? onConsult;
  final VoidCallback? onUrgent;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (provider.distanceKm != null)
        '${provider.distanceKm!.toStringAsFixed(1)} km',
      if (provider.phone?.trim().isNotEmpty == true) provider.phone!,
      if (provider.todayHours != null) 'Today ${provider.todayHours}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: provider.consultationEnabled
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: provider.consultationEnabled
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        provider.consultationEnabled
                            ? 'Available on Petto'
                            : 'Information only',
                        style: TextStyle(
                          color: provider.consultationEnabled
                              ? AppTheme.successColor
                              : AppTheme.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onUrgent != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _CompactActionButton(
                  key: Key('urgent-help-provider-${provider.id}'),
                  onPressed: onUrgent,
                  icon: const Icon(Icons.sos_rounded),
                  label: 'Request Urgent Help',
                  outlined: true,
                ),
              ),
            ],
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
                  child: _CompactActionButton(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_rounded),
                    label: 'Directions',
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactActionButton(
                    onPressed: onConsult,
                    icon: const Icon(Icons.forum_rounded),
                    label: onConsult == null ? 'Unavailable' : 'Consult',
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
  const _SectionLabel(this.text, {this.action});
  final String text;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              action!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.consultation, required this.onTap});
  final ConsultationModel consultation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassCardDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                consultation.priority == 'urgent'
                    ? Icons.sos_rounded
                    : Icons.forum_rounded,
                color: consultation.priority == 'urgent'
                    ? Colors.redAccent
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consultation.vetName ??
                        'Veterinarian #${consultation.vetId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${consultation.priority == 'urgent' ? 'URGENT • ' : ''}'
                    '${consultation.status} • ${consultation.providerName ?? 'Petto'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final details = [
      vet.specialty,
      vet.clinicName,
    ].whereType<String>().join(' • ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        onTap: busy ? null : onStart,
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: vet.isOnline
                      ? AppTheme.successColor
                      : AppTheme.mutedText.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          vet.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          details.isEmpty ? 'Petto veterinarian' : details,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: SizedBox(
          width: 104,
          child: _CompactActionButton(
            onPressed: busy ? null : onStart,
            icon: const Icon(Icons.chat_bubble_rounded),
            label: 'Consult',
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme.merge(data: const IconThemeData(size: 17), child: icon),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
    final style = outlined
        ? OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          )
        : FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );
    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

class _ChatHeaderCard extends StatelessWidget {
  const _ChatHeaderCard({
    required this.consultation,
    required this.petName,
    required this.realtimeConnected,
    required this.sharingHealthCard,
    required this.onBack,
    required this.onRefresh,
    required this.onShareAssessment,
    required this.onShareHealthCard,
  });

  final ConsultationModel consultation;
  final String petName;
  final bool realtimeConnected;
  final bool sharingHealthCard;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onShareAssessment;
  final VoidCallback? onShareHealthCard;

  @override
  Widget build(BuildContext context) {
    final statusText = realtimeConnected ? 'Online now' : 'Manual refresh';
    final statusColor = realtimeConnected
        ? AppTheme.successColor
        : AppTheme.accentColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        hasShadow: false,
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.vetName ?? 'Petto Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
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
                    Expanded(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.mutedText,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _RoundIconButton(
            icon: Icons.auto_awesome_rounded,
            onTap: onShareAssessment,
            tooltip: 'Share selected assessment',
          ),
          const SizedBox(width: 6),
          _RoundIconButton(
            icon: sharingHealthCard
                ? Icons.hourglass_top_rounded
                : Icons.health_and_safety_rounded,
            onTap: onShareHealthCard,
            tooltip: 'Share health card',
          ),
          const SizedBox(width: 6),
          _RoundIconButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : AppTheme.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(
                alpha: enabled ? 0.12 : 0.06,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? AppTheme.primaryColor : AppTheme.mutedText,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ClosedConsultationComposer extends StatelessWidget {
  const _ClosedConsultationComposer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'This consultation is closed. Messages are read-only.',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: sending ? null : onSend,
            style: FilledButton.styleFrom(
              minimumSize: const Size(46, 46),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ChatSurface extends StatelessWidget {
  const _ChatSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.035),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: _SoftCircle(
              size: 42,
              color: AppTheme.primaryColor.withValues(alpha: 0.026),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.075),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Semantics(
              label: 'No messages yet. Say hello.',
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_unread_chat_alt_rounded,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a calm chat',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ask about $petName or share symptoms.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w700,
                                height: 1.28,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: mine
              ? AppTheme.primaryColor
              : AppTheme.surfaceColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(mine ? 22 : 8),
            bottomRight: Radius.circular(mine ? 8 : 22),
          ),
          border: mine
              ? null
              : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          boxShadow: mine
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAiBriefing)
              Text(
                'AI briefing',
                style: TextStyle(
                  color: mine ? Colors.white : AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            Text(
              message.content ?? 'Shared attachment',
              style: TextStyle(
                color: mine ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mine ? status : message.senderType.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
    decoration: AppTheme.glassCardDecoration(
      color: AppTheme.surfaceColor.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(28),
      borderColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      hasShadow: false,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.forum_outlined, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: AppTheme.glassCardDecoration(
      color: AppTheme.dangerColor.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(24),
      borderColor: AppTheme.dangerColor.withValues(alpha: 0.14),
      hasShadow: false,
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.dangerColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _AssistantLoading extends StatefulWidget {
  const _AssistantLoading({this.label = 'Finding the right care'});

  final String label;

  @override
  State<_AssistantLoading> createState() => _AssistantLoadingState();
}

class _AssistantLoadingState extends State<_AssistantLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _float = Tween<double>(
      begin: -3,
      end: 3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward().then((_) {
      if (!mounted) return;
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: LinearProgressIndicator(
              minHeight: 5,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
