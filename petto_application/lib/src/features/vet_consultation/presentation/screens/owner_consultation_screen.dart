import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/navigation/petto_transitions.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../../../../core/widgets/top_alert.dart';
import '../../../health_assessment/presentation/controllers/health_assessment_controller.dart';
import '../../data/models/consultation_models.dart';
import '../controllers/consultation_controller.dart';
import '../widgets/appointment_card.dart';
import '../widgets/provider_map_view.dart';
import '../widgets/shared_assessment_card.dart';
import '../widgets/shared_health_card.dart';

const _assistantCreamSurface = Color(0xFFFFFAF5);
const _assistantRoseSurface = Color(0xFFF6E4E2);
const _assistantSageSurface = Color(0xFFEEF0E5);
const _assistantSageAccent = Color(0xFF6F7E5A);
const _assistantRoseAccent = Color(0xFFA5515A);
const _assistantGoldSurface = Color(0xFFF8EDCF);
const _assistantGoldAccent = Color(0xFFB18636);

String _friendlyTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

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
  bool _sharingAssessment = false;
  VetModel? _openingVet;
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
    if (mounted) setState(() => _openingVet = vet);
    try {
      await context.read<ConsultationController>().startConsultation(
        petId: widget.petId,
        vetId: vet.id,
        providerId: provider?.id,
        assessmentId: _includeLatestAssessment
            ? widget.latestAssessmentId
            : null,
        urgent: urgent,
        realtimeAccessToken: widget.realtimeAccessToken,
      );
    } finally {
      if (mounted) setState(() => _openingVet = null);
    }
  }

  Future<void> _openConsultation(ConsultationModel consultation) =>
      context.read<ConsultationController>().openConsultation(
        consultation,
        realtimeAccessToken: widget.realtimeAccessToken,
      );

  Future<int?> _latestAssessmentId() async {
    if (widget.latestAssessmentId != null) return widget.latestAssessmentId;

    final assessmentController = context.read<HealthAssessmentController>();
    var assessments = assessmentController.history
        .where((assessment) => assessment.petId == widget.petId)
        .toList();

    if (assessments.isEmpty && !assessmentController.isHistoryLoading) {
      await assessmentController.loadPetHistory(widget.petId, force: true);
      assessments = assessmentController.history
          .where((assessment) => assessment.petId == widget.petId)
          .toList();
    }

    if (assessments.isEmpty) {
      final current = assessmentController.currentAssessment;
      if (current != null && current.petId == widget.petId) return current.id;
      return null;
    }

    assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return assessments.first.id;
  }

  Future<void> _shareLatestAssessment(ConsultationController controller) async {
    if (_sharingAssessment) return;
    setState(() => _sharingAssessment = true);
    try {
      final assessmentId = await _latestAssessmentId();
      if (!mounted) return;

      if (assessmentId == null) {
        showTopAlert(
          context,
          'No assessment is available to share yet.',
          icon: Icons.info_outline_rounded,
        );
        return;
      }

      final alreadyShared = controller.sharedAssessments.any(
        (item) => item.assessmentId == assessmentId,
      );
      if (alreadyShared) {
        showTopAlert(
          context,
          'This assessment is already shared.',
          icon: Icons.done_all_rounded,
        );
        return;
      }

      final shared = await controller.shareAssessment(assessmentId);
      if (!mounted) return;
      showTopAlert(
        context,
        shared
            ? 'Assessment shared with this veterinarian.'
            : (controller.error ?? 'Could not share the assessment.'),
        icon: shared ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _sharingAssessment = false);
    }
  }

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
    await Navigator.of(context).push<void>(
      PettoPageRoute<void>(
        builder: (routeContext) => _VetDirectoryPage(
          provider: provider,
          vets: controller.providerVets,
          urgent: urgent,
          onVetSelected: (vet) {
            Navigator.of(routeContext).pop();
            _startConsultation(vet, provider: provider, urgent: urgent);
          },
        ),
      ),
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
        if (_openingVet != null) {
          return _OpeningChatView(vet: _openingVet!, petName: widget.petName);
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
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
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
              'Conversations',
              action: '${controller.consultations.length} active',
            ),
            const SizedBox(height: 12),
            _RecentConversationsCard(
              consultations: controller.consultations,
              onOpen: _openConsultation,
            ),
          ],
          const SizedBox(height: 24),
          _SectionLabel(
            'Care team',
            action: _showMap && controller.providers.isNotEmpty
                ? 'Map view'
                : 'Ready',
          ),
          const SizedBox(height: 12),
          if (controller.providers.isEmpty && controller.vets.isEmpty)
            const _EmptyCard(
              message: 'No veterinary provider is listed right now.',
            )
          else if (_showMap && controller.providers.isNotEmpty)
            Container(
              height: 430,
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _assistantCreamSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
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
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: _ChatHeaderCard(
            consultation: consultation,
            petName: widget.petName,
            realtimeConnected: controller.realtimeConnected,
            sharingHealthCard: controller.sharingHealthCard,
            onBack: controller.closeActiveConsultation,
            onRefresh: controller.loading ? null : controller.refreshMessages,
            sharingAssessment: _sharingAssessment,
            onShareAssessment: consultation.isClosed || _sharingAssessment
                ? null
                : () => _shareLatestAssessment(controller),
            onShareHealthCard:
                controller.sharingHealthCard || consultation.isClosed
                ? null
                : () async {
                    final shared = await controller.shareHealthCard();
                    if (!mounted) return;
                    showTopAlert(
                      context,
                      shared
                          ? 'Pet Health ID shared with this veterinarian.'
                          : (controller.error ??
                                'Could not share Pet Health ID.'),
                      icon: shared
                          ? Icons.health_and_safety_rounded
                          : Icons.info_outline_rounded,
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
                  ? _ChatEmptyState(petName: widget.petName)
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 132),
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
    const heroRed = Color(0xFF7B3034);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: heroRed,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SoftPulse(child: _HeroIcon()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care for $petName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFFFFAF5),
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find a clinic or continue a conversation.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: _assistantCreamSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Row(
              children: [
                _HeroStat(
                  label: 'Vets online',
                  value: '$onlineCount',
                  icon: Icons.medical_services_rounded,
                  surface: _assistantSageSurface,
                  accent: _assistantSageAccent,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
                _HeroStat(
                  label: 'Open chats',
                  value: '$consultationCount',
                  icon: Icons.forum_rounded,
                  surface: _assistantRoseSurface,
                  accent: _assistantRoseAccent,
                ),
              ],
            ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: const Icon(
        Icons.support_agent_rounded,
        color: Color(0xFF7B3034),
        size: 27,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.surface,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color surface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
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
    final mapEnabled = hasProviders && onToggleMap != null;
    final viewBackground = showMap
        ? _assistantSageSurface
        : _assistantGoldSurface;
    final viewForeground = showMap
        ? _assistantSageAccent
        : _assistantGoldAccent;
    const viewRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(26),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _assistantCreamSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: _assistantRoseSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Colors.white, width: 2.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: locating ? null : onUseLocation,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: locating
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locating ? 'LOCATING' : 'CARE NEAR YOU',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.mutedText,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              locating ? 'Finding location' : 'Nearby clinics',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
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
          const SizedBox(width: 8),
          Opacity(
            opacity: mapEnabled ? 1 : 0.42,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleMap,
                borderRadius: viewRadius,
                child: Ink(
                  width: 112,
                  height: 66,
                  decoration: BoxDecoration(
                    color: mapEnabled
                        ? viewBackground
                        : const Color(0xFFD8D0CB),
                    borderRadius: viewRadius,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          showMap ? Icons.view_list_rounded : Icons.map_rounded,
                          color: viewForeground,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIEW AS',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: viewForeground.withValues(alpha: 0.72),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            showMap ? 'List' : 'Map',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: viewForeground,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
      decoration: BoxDecoration(
        color: value ? _assistantRoseSurface : _assistantCreamSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
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

class _OpeningChatView extends StatelessWidget {
  const _OpeningChatView({required this.vet, required this.petName});

  final VetModel vet;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final initial = vet.name.trim().isEmpty
        ? 'V'
        : vet.name.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _assistantCreamSurface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _assistantRoseSurface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.secondaryText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Opening $petName’s chat…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _assistantRoseSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Getting the room ready',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VetDirectoryPage extends StatefulWidget {
  const _VetDirectoryPage({
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
  State<_VetDirectoryPage> createState() => _VetDirectoryPageState();
}

class _VetDirectoryPageState extends State<_VetDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.vets.where((vet) {
      final haystack =
          '${vet.name} ${vet.specialty ?? ''} '
                  '${vet.clinicName ?? ''}'
              .toLowerCase();
      return haystack.contains(_query.toLowerCase().trim());
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: AppTheme.backgroundColor,
        child: Stack(
          children: [
            const _SubtleDotBackground(),
            SafeArea(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose veterinarian',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pick a care team member for this chat.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
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
                  const SizedBox(height: 18),
                  _VetProviderSummary(
                    provider: widget.provider,
                    urgent: widget.urgent,
                  ),
                  const SizedBox(height: 14),
                  _VetSearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filtered.length} vets available',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          widget.urgent ? 'Urgent' : 'Care team',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const _EmptyCard(
                      message: 'No veterinarian matches this search.',
                    )
                  else
                    for (final vet in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VetChoiceTile(
                          vet: vet,
                          onTap: () => widget.onVetSelected(vet),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetProviderSummary extends StatelessWidget {
  const _VetProviderSummary({required this.provider, required this.urgent});

  final VeterinaryProviderModel provider;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final address = provider.address?.trim();
    final phone = provider.phone?.trim();
    final hours = provider.todayHours;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _assistantCreamSurface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppTheme.primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  provider.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: _assistantCreamSurface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoBadge(
                    icon: urgent
                        ? Icons.priority_high_rounded
                        : Icons.verified_rounded,
                    label: urgent ? 'Urgent queue' : 'Available now',
                    color: urgent ? _assistantRoseAccent : _assistantSageAccent,
                  ),
                ),
                if (hours != null) ...[
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: _InfoBadge(
                      icon: Icons.schedule_rounded,
                      label: 'Today $hours',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if ((address != null && address.isNotEmpty) ||
              (phone != null && phone.isNotEmpty)) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: _assistantCreamSurface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                children: [
                  if (address != null && address.isNotEmpty)
                    _ProviderSummaryDetail(
                      icon: Icons.location_on_rounded,
                      value: address,
                    ),
                  if (address != null &&
                      address.isNotEmpty &&
                      phone != null &&
                      phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      ),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    _ProviderSummaryDetail(
                      icon: Icons.phone_rounded,
                      value: phone,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VetSearchField extends StatelessWidget {
  const _VetSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _assistantCreamSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: AppTheme.primaryColor,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Search vets or specialty',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                if (controller.text.isEmpty) return const SizedBox(width: 2);
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                );
              },
            ),
          ],
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
    final specialty = vet.specialty?.trim().isNotEmpty == true
        ? vet.specialty!.trim()
        : 'Veterinarian';
    final clinic = vet.clinicName?.trim().isNotEmpty == true
        ? vet.clinicName!.trim()
        : 'Petto care network';
    final initial = vet.name.trim().isEmpty
        ? 'V'
        : vet.name.trim()[0].toUpperCase();
    return Material(
      color: const Color(0xFFFFFCF8),
      elevation: 1,
      shadowColor: const Color(0x18000000),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Colors.white, width: 3),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: vet.isOnline
                                ? AppTheme.successColor
                                : AppTheme.mutedText.withValues(alpha: 0.42),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppTheme.primaryColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clinic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderSummaryDetail extends StatelessWidget {
  const _ProviderSummaryDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _assistantRoseSurface,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderDetailLine extends StatelessWidget {
  const _ProviderDetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryText.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderMiniDetail extends StatelessWidget {
  const _ProviderMiniDetail({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final distance = provider.distanceKm == null
        ? null
        : '${provider.distanceKm!.toStringAsFixed(1)} km away';
    final phone = provider.phone?.trim().isNotEmpty == true
        ? provider.phone!.trim()
        : null;
    final hours = provider.todayHours == null
        ? null
        : 'Today ${provider.todayHours}';
    final enabled = provider.consultationEnabled;
    final headerForeground = enabled ? Colors.white : AppTheme.secondaryText;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Material(
          color: _assistantCreamSurface,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppTheme.primaryColor
                      : _assistantRoseSurface,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0xFF9A5054)
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: headerForeground,
                                  fontWeight: FontWeight.w900,
                                  height: 1.13,
                                ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _ProviderHeaderBadge(
                                icon: enabled
                                    ? Icons.bolt_rounded
                                    : Icons.info_outline_rounded,
                                label: enabled
                                    ? 'Consultations available'
                                    : 'Information only',
                                enabled: enabled,
                              ),
                              if (distance != null)
                                _ProviderHeaderBadge(
                                  icon: Icons.near_me_rounded,
                                  label: distance,
                                  enabled: enabled,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.address?.trim().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 13),
                        child: _ProviderDetailLine(
                          icon: Icons.location_on_rounded,
                          text: provider.address!.trim(),
                        ),
                      ),
                    if (phone != null || hours != null) ...[
                      Divider(
                        height: 1,
                        color: AppTheme.secondaryText.withValues(alpha: 0.10),
                      ),
                      const SizedBox(height: 7),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final details = <Widget>[
                            if (phone != null)
                              _ProviderMiniDetail(
                                icon: Icons.call_rounded,
                                label: 'Phone',
                                text: phone,
                                color: AppTheme.primaryColor,
                              ),
                            if (hours != null)
                              _ProviderMiniDetail(
                                icon: Icons.schedule_rounded,
                                label: 'Opening hours',
                                text: hours,
                                color: _assistantRoseAccent,
                              ),
                          ];
                          if (constraints.maxWidth < 430 &&
                              details.length == 2) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: details[0],
                                ),
                                Divider(
                                  height: 1,
                                  color: AppTheme.secondaryText.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: details[1],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              for (
                                var index = 0;
                                index < details.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 9),
                                Expanded(child: details[index]),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                    if (onUrgent != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        key: Key('urgent-help-provider-${provider.id}'),
                        onTap: onUrgent,
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: _assistantRoseAccent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sos_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request urgent help',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Start a priority chat',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
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
                            label: onConsult == null
                                ? 'Unavailable'
                                : 'Consult',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderHeaderBadge extends StatelessWidget {
  const _ProviderHeaderBadge({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : AppTheme.primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
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
          width: 6,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        if (action != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2.5),
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
    final vetName = consultation.vetName?.trim().isNotEmpty == true
        ? consultation.vetName!.trim()
        : 'Veterinarian ${consultation.vetId}';
    final providerName = consultation.providerName?.trim().isNotEmpty == true
        ? consultation.providerName!.trim()
        : 'Petto care team';
    final initial = vetName.characters.first.toUpperCase();
    final status = consultation.status.trim().isEmpty
        ? 'Active'
        : '${consultation.status[0].toUpperCase()}${consultation.status.substring(1)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF7E9EA),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vetName,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: consultation.priority == 'urgent'
                              ? AppTheme.dangerColor
                              : AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          providerName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentConversationsCard extends StatelessWidget {
  const _RecentConversationsCard({
    required this.consultations,
    required this.onOpen,
  });

  final List<ConsultationModel> consultations;
  final ValueChanged<ConsultationModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: _assistantCreamSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < consultations.length; index++) ...[
            _ConsultationCard(
              consultation: consultations[index],
              onTap: () => onOpen(consultations[index]),
            ),
            if (index != consultations.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
              ),
          ],
        ],
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
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.1),
          ),
        ),
      ],
    );
    final style = FilledButton.styleFrom(
      backgroundColor: outlined ? _assistantRoseSurface : AppTheme.primaryColor,
      foregroundColor: outlined ? AppTheme.secondaryText : Colors.white,
      disabledBackgroundColor: const Color(0xFFE9DEDE),
      disabledForegroundColor: const Color(0xFF8B686B),
      minimumSize: const Size(0, 52),
      elevation: 0,
      shadowColor: Colors.transparent,
      side: const BorderSide(color: Colors.white, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

class _ChatHeaderCard extends StatelessWidget {
  const _ChatHeaderCard({
    required this.consultation,
    required this.petName,
    required this.realtimeConnected,
    required this.sharingAssessment,
    required this.sharingHealthCard,
    required this.onBack,
    required this.onRefresh,
    required this.onShareAssessment,
    required this.onShareHealthCard,
  });

  final ConsultationModel consultation;
  final String petName;
  final bool realtimeConnected;
  final bool sharingAssessment;
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
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _assistantCreamSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 7),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    consultation.vetName ?? 'Petto Assistant',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
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
                        '$petName · $statusText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          const SizedBox(width: 4),
          _ChatShareMenuButton(
            sharingAssessment: sharingAssessment,
            sharingHealthCard: sharingHealthCard,
            onShareAssessment: onShareAssessment,
            onShareHealthCard: onShareHealthCard,
          ),
          const SizedBox(width: 3),
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

class _ChatShareMenuButton extends StatelessWidget {
  const _ChatShareMenuButton({
    required this.sharingAssessment,
    required this.sharingHealthCard,
    required this.onShareAssessment,
    required this.onShareHealthCard,
  });

  final bool sharingAssessment;
  final bool sharingHealthCard;
  final VoidCallback? onShareAssessment;
  final VoidCallback? onShareHealthCard;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Share options',
      color: _assistantCreamSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 224, maxWidth: 244),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white, width: 3),
      ),
      onSelected: (value) {
        if (value == 'assessment') onShareAssessment?.call();
        if (value == 'health') onShareHealthCard?.call();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'assessment',
          enabled: onShareAssessment != null,
          height: 58,
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
          child: _ShareMenuChoice(
            icon: sharingAssessment
                ? Icons.hourglass_top_rounded
                : Icons.auto_awesome_rounded,
            label: 'AI assessment',
            surface: _assistantGoldSurface,
            foreground: _assistantGoldAccent,
          ),
        ),
        PopupMenuItem<String>(
          value: 'health',
          enabled: onShareHealthCard != null,
          height: 58,
          padding: const EdgeInsets.fromLTRB(8, 3, 8, 7),
          child: _ShareMenuChoice(
            icon: sharingHealthCard
                ? Icons.hourglass_top_rounded
                : Icons.health_and_safety_rounded,
            label: 'Health ID',
            surface: _assistantSageSurface,
            foreground: _assistantSageAccent,
          ),
        ),
      ],
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _assistantGoldSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.ios_share_rounded,
          color: _assistantGoldAccent,
          size: 19,
        ),
      ),
    );
  }
}

class _ShareMenuChoice extends StatelessWidget {
  const _ShareMenuChoice({
    required this.icon,
    required this.label,
    required this.surface,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color surface;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: foreground, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: foreground, size: 17),
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
          width: 38,
          height: 38,
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
            size: 20,
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _assistantCreamSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _assistantRoseSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const SizedBox(width: 7),
          FilledButton(
            onPressed: sending ? null : onSend,
            style: FilledButton.styleFrom(
              minimumSize: const Size(42, 42),
              fixedSize: const Size(42, 42),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            child: sending
                ? const PettoButtonProgress(width: 19, height: 5)
                : const Icon(Icons.send_rounded, size: 19),
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
    final timeLabel = _friendlyTime(message.createdAt);
    final isAi = message.isAiBriefing;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: mine
                ? AppTheme.primaryColor
                : isAi
                ? AppTheme.creamSurfaceColor.withValues(alpha: 0.92)
                : AppTheme.surfaceColor.withValues(alpha: 0.98),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(mine ? 22 : 8),
              bottomRight: Radius.circular(mine ? 8 : 22),
            ),
            border: mine
                ? null
                : Border.all(
                    color: (isAi ? AppTheme.accentColor : AppTheme.primaryColor)
                        .withValues(alpha: 0.13),
                  ),
            boxShadow: [
              BoxShadow(
                color: (mine ? AppTheme.primaryColor : AppTheme.accentColor)
                    .withValues(alpha: mine ? 0.14 : 0.05),
                blurRadius: 16,
                spreadRadius: -10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.accentColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'AI briefing',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.content ?? 'Shared attachment',
                style: TextStyle(
                  color: mine ? Colors.white : AppTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.36,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: mine
                          ? Colors.white.withValues(alpha: 0.72)
                          : AppTheme.mutedText,
                    ),
                  ),
                  if (mine) ...[
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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

class _AssistantLoading extends StatelessWidget {
  const _AssistantLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: PettoPageSkeleton(itemCount: 3, compact: true),
    );
  }
}

class _SubtleDotBackground extends StatelessWidget {
  const _SubtleDotBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _SubtleDotPainter())),
    );
  }
}

class _SubtleDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const spacing = 40.0;
    for (double y = 18; y < size.height; y += spacing) {
      for (double x = 20; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 3.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
